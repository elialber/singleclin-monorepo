/**
 * Utilitários para integração com Google Maps
 */

export interface GoogleMapsConfig {
  apiKey: string
  language?: string
  region?: string
  libraries?: string[]
}

export interface MapCenter {
  lat: number
  lng: number
}

export interface MapBounds {
  north: number
  south: number
  east: number
  west: number
}

export interface GeocodeResult {
  address: string
  latitude: number
  longitude: number
  formattedAddress: string
  addressComponents: {
    streetNumber?: string
    route?: string
    neighborhood?: string
    city?: string
    state?: string
    postalCode?: string
    country?: string
  }
}

/**
 * Configuração padrão do Google Maps para o Brasil
 */
export const DEFAULT_MAPS_CONFIG: GoogleMapsConfig = {
  apiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '',
  language: 'pt-BR',
  region: 'BR',
  libraries: ['places', 'geometry']
}

/**
 * Centro padrão do Brasil (Brasília)
 */
export const BRAZIL_CENTER: MapCenter = {
  lat: -15.7942,
  lng: -47.8822
}

/**
 * Limites geográficos do Brasil
 */
export const BRAZIL_BOUNDS: MapBounds = {
  north: 5.2700,
  south: -33.7683,
  east: -28.8477,
  west: -73.9828
}

/**
 * Interface para opções de geocoding
 */
export interface GeocodeOptions {
  address?: string
  latlng?: google.maps.LatLng | google.maps.LatLngLiteral
  region?: string
  language?: string
  bounds?: google.maps.LatLngBounds
}

/**
 * Classe para gerenciar operações do Google Maps
 */
export class GoogleMapsService {
  private geocoder: google.maps.Geocoder | null = null
  
  constructor(private config: GoogleMapsConfig = DEFAULT_MAPS_CONFIG) {}
  
  /**
   * Inicializa o serviço de geocoding
   */
  private async initGeocoder(): Promise<google.maps.Geocoder> {
    if (this.geocoder) {
      return this.geocoder
    }
    
    // Verificar se o Google Maps já está carregado
    if (typeof google === 'undefined' || !google.maps) {
      throw new Error('Google Maps API não está carregada')
    }
    
    this.geocoder = new google.maps.Geocoder()
    return this.geocoder
  }
  
  /**
   * Geocoding: Converter endereço em coordenadas
   */
  async geocodeAddress(address: string): Promise<GeocodeResult | null> {
    try {
      const geocoder = await this.initGeocoder()
      
      const request: google.maps.GeocoderRequest = {
        address,
        region: this.config.region || 'BR',
        language: this.config.language || 'pt-BR'
      }
      
      return new Promise((resolve, reject) => {
        geocoder.geocode(request, (results, status) => {
          if (status === google.maps.GeocoderStatus.OK && results && results[0]) {
            const result = results[0]
            const location = result.geometry.location
            
            const geocodeResult: GeocodeResult = {
              address,
              latitude: location.lat(),
              longitude: location.lng(),
              formattedAddress: result.formatted_address,
              addressComponents: this.parseAddressComponents(result.address_components || [])
            }
            
            resolve(geocodeResult)
          } else {
            resolve(null)
          }
        })
      })
    } catch (error) {
      console.error('Erro no geocoding:', error)
      return null
    }
  }
  
  /**
   * Reverse Geocoding: Converter coordenadas em endereço
   */
  async reverseGeocode(lat: number, lng: number): Promise<GeocodeResult | null> {
    try {
      const geocoder = await this.initGeocoder()
      
      const request: google.maps.GeocoderRequest = {
        location: { lat, lng },
        language: this.config.language || 'pt-BR'
      }
      
      return new Promise((resolve, reject) => {
        geocoder.geocode(request, (results, status) => {
          if (status === google.maps.GeocoderStatus.OK && results && results[0]) {
            const result = results[0]
            
            const geocodeResult: GeocodeResult = {
              address: result.formatted_address,
              latitude: lat,
              longitude: lng,
              formattedAddress: result.formatted_address,
              addressComponents: this.parseAddressComponents(result.address_components || [])
            }
            
            resolve(geocodeResult)
          } else {
            resolve(null)
          }
        })
      })
    } catch (error) {
      console.error('Erro no reverse geocoding:', error)
      return null
    }
  }
  
  /**
   * Parse dos componentes de endereço do Google Maps
   */
  private parseAddressComponents(components: google.maps.GeocoderAddressComponent[]) {
    const parsed: GeocodeResult['addressComponents'] = {}
    
    components.forEach(component => {
      const types = component.types
      
      if (types.includes('street_number')) {
        parsed.streetNumber = component.long_name
      } else if (types.includes('route')) {
        parsed.route = component.long_name
      } else if (types.includes('sublocality') || types.includes('neighborhood')) {
        parsed.neighborhood = component.long_name
      } else if (types.includes('administrative_area_level_2') || types.includes('locality')) {
        parsed.city = component.long_name
      } else if (types.includes('administrative_area_level_1')) {
        parsed.state = component.short_name
      } else if (types.includes('postal_code')) {
        parsed.postalCode = component.long_name
      } else if (types.includes('country')) {
        parsed.country = component.long_name
      }
    })
    
    return parsed
  }
  
  /**
   * Calcular distância entre dois pontos
   */
  calculateDistance(
    point1: { lat: number; lng: number },
    point2: { lat: number; lng: number }
  ): number {
    if (typeof google === 'undefined' || !google.maps || !google.maps.geometry) {
      // Fallback para cálculo de distância usando fórmula de Haversine
      return this.haversineDistance(point1, point2)
    }
    
    const latLng1 = new google.maps.LatLng(point1.lat, point1.lng)
    const latLng2 = new google.maps.LatLng(point2.lat, point2.lng)
    
    return google.maps.geometry.spherical.computeDistanceBetween(latLng1, latLng2)
  }
  
  /**
   * Cálculo de distância usando fórmula de Haversine (fallback)
   */
  private haversineDistance(
    point1: { lat: number; lng: number },
    point2: { lat: number; lng: number }
  ): number {
    const R = 6371000 // Raio da Terra em metros
    const dLat = this.toRadians(point2.lat - point1.lat)
    const dLng = this.toRadians(point2.lng - point1.lng)
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(point1.lat)) * Math.cos(this.toRadians(point2.lat)) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2)
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    
    return R * c
  }
  
  /**
   * Converter graus para radianos
   */
  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180)
  }
}

/**
 * Instância padrão do serviço Google Maps
 */
export const mapsService = new GoogleMapsService()

/**
 * Hook para verificar se o Google Maps está carregado
 */
export function useGoogleMapsLoaded(): boolean {
  return typeof google !== 'undefined' && !!google.maps
}

/**
 * Utilitário para carregar Google Maps API dinamicamente
 */
export function loadGoogleMapsAPI(config: GoogleMapsConfig = DEFAULT_MAPS_CONFIG): Promise<void> {
  return new Promise((resolve, reject) => {
    // Verificar se já está carregado
    if (typeof google !== 'undefined' && google.maps) {
      resolve()
      return
    }
    
    // Verificar se já existe um script sendo carregado
    const existingScript = document.querySelector('script[src*="maps.googleapis.com"]')
    if (existingScript) {
      existingScript.addEventListener('load', () => resolve())
      existingScript.addEventListener('error', reject)
      return
    }
    
    if (!config.apiKey) {
      reject(new Error('Google Maps API key não configurada'))
      return
    }
    
    // Criar callback global
    const callbackName = 'initGoogleMaps'
    ;(window as any)[callbackName] = () => {
      delete (window as any)[callbackName]
      resolve()
    }
    
    // Criar script
    const script = document.createElement('script')
    const libraries = config.libraries?.join(',') || 'places,geometry'
    
    script.src = `https://maps.googleapis.com/maps/api/js?key=${config.apiKey}&libraries=${libraries}&language=${config.language || 'pt-BR'}&region=${config.region || 'BR'}&callback=${callbackName}`
    script.async = true
    script.defer = true
    script.onerror = reject
    
    document.head.appendChild(script)
  })
}

/**
 * Utilitários para trabalhar com bounds
 */
export class BoundsUtils {
  /**
   * Criar bounds do Google Maps
   */
  static createBounds(bounds: MapBounds): google.maps.LatLngBounds {
    return new google.maps.LatLngBounds(
      new google.maps.LatLng(bounds.south, bounds.west),
      new google.maps.LatLng(bounds.north, bounds.east)
    )
  }
  
  /**
   * Verificar se um ponto está dentro dos bounds
   */
  static isPointInBounds(
    point: { lat: number; lng: number },
    bounds: MapBounds
  ): boolean {
    return point.lat >= bounds.south &&
           point.lat <= bounds.north &&
           point.lng >= bounds.west &&
           point.lng <= bounds.east
  }
  
  /**
   * Expandir bounds para incluir um ponto
   */
  static extendBounds(bounds: MapBounds, point: { lat: number; lng: number }): MapBounds {
    return {
      north: Math.max(bounds.north, point.lat),
      south: Math.min(bounds.south, point.lat),
      east: Math.max(bounds.east, point.lng),
      west: Math.min(bounds.west, point.lng)
    }
  }
}