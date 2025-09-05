import React, { useEffect, useState, useCallback, useRef } from 'react'
import {
  Box,
  Grid,
  TextField,
  Typography,
  Alert,
  Chip,
  CircularProgress,
  Paper,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Card,
  CardContent,
  Divider,
  Tooltip,
  IconButton
} from '@mui/material'
import {
  CheckCircle,
  Warning,
  LocationOn,
  MyLocation,
  Map as MapIcon,
  Search,
  Refresh,
  Help
} from '@mui/icons-material'
import { useClinicStepper } from '../hooks/useClinicStepper'
import { useInputValidation, useMaskedInput } from '../hooks/useInputValidation'
import { StepComponentProps } from '../../../../types/stepper'
import { BRAZILIAN_STATES } from '../../../../types/stepper'
import {
  validateCEP,
  validateAddress,
  validateAddressNumber,
  validateComplement,
  validateNeighborhood,
  validateCity,
  validateState,
  validateCoordinates,
  formatCEP,
  getAddressByCEP,
  ViaCEPResponse,
  GeolocationCoordinates
} from '../../../../utils/validation'
import { 
  mapsService,
  loadGoogleMapsAPI,
  useGoogleMapsLoaded,
  BRAZIL_CENTER,
  GeocodeResult
} from '../../../../utils/maps'

/**
 * Step 2: Endereço e Localização
 * 
 * Formulário com CEP, integração com ViaCEP, Google Maps com marcador arrastável
 */
function Step2AddressLocation({ onNext, onPrev, isValid, isDirty }: StepComponentProps) {
  const { formData, updateFormData, setStepError, clearStepErrors, validateStep } = useClinicStepper()
  const [formValid, setFormValid] = useState(false)
  const [isCEPLoading, setIsCEPLoading] = useState(false)
  const [cepLoadSuccess, setCepLoadSuccess] = useState(false)
  const [mapLoaded, setMapLoaded] = useState(false)
  const [currentLocation, setCurrentLocation] = useState<GeolocationCoordinates | null>(null)
  
  // Refs para o mapa
  const mapRef = useRef<HTMLDivElement>(null)
  const mapInstanceRef = useRef<google.maps.Map | null>(null)
  const markerRef = useRef<google.maps.Marker | null>(null)
  const isGoogleMapsLoaded = useGoogleMapsLoaded()

  // Campo CEP com máscara e validação
  const cepField = useMaskedInput({
    validator: validateCEP,
    formatter: formatCEP,
    maxLength: 9, // XXXXX-XXX
    debounceMs: 300,
    initialValue: formData.address.cep || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(1, 'cep', errors)
      } else {
        clearStepErrors(1)
      }
    }
  })

  // Campo Endereço
  const addressField = useInputValidation({
    validator: (value) => validateAddress(value, true),
    initialValue: formData.address.street || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(1, 'street', errors)
      }
    }
  })

  // Campo Número
  const numberField = useInputValidation({
    validator: (value) => validateAddressNumber(value, true),
    initialValue: formData.address.number || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(1, 'number', errors)
      }
    }
  })

  // Campo Complemento (opcional)
  const complementField = useInputValidation({
    validator: validateComplement,
    initialValue: formData.address.complement || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(1, 'complement', errors)
      }
    }
  })

  // Campo Bairro
  const neighborhoodField = useInputValidation({
    validator: (value) => validateNeighborhood(value, true),
    initialValue: formData.address.neighborhood || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(1, 'neighborhood', errors)
      }
    }
  })

  // Campo Cidade
  const cityField = useInputValidation({
    validator: (value) => validateCity(value, true),
    initialValue: formData.address.city || '',
    onValidationChange: (isValid, errors) => {
      if (errors.length > 0) {
        setStepError(1, 'city', errors)
      }
    }
  })

  // Estado selecionado
  const [selectedState, setSelectedState] = useState(formData.address.state || '')
  const [lastSearchedCep, setLastSearchedCep] = useState('')

  // Buscar endereço por CEP
  const handleCEPLookup = useCallback(async (cep: string) => {
    if (!cep || cep.length < 9) return // XXXXX-XXX
    if (lastSearchedCep === cep) return // Evitar busca repetida

    try {
      setIsCEPLoading(true)
      setCepLoadSuccess(false)
      setLastSearchedCep(cep)

      const addressData = await getAddressByCEP(cep)
      
      if (addressData) {
        // Preencher campos com dados do ViaCEP
        addressField.setValue(addressData.logradouro || '')
        neighborhoodField.setValue(addressData.bairro || '')
        cityField.setValue(addressData.localidade || '')
        setSelectedState(addressData.uf || '')
        
        // Se complemento do CEP existe, preencher
        if (addressData.complemento) {
          complementField.setValue(addressData.complemento)
        }

        setCepLoadSuccess(true)

        // Tentar fazer geocoding do endereço completo
        if (addressData.logradouro && addressData.localidade) {
          const fullAddress = `${addressData.logradouro}, ${addressData.localidade}, ${addressData.uf}, Brasil`
          const geocodeResult = await mapsService.geocodeAddress(fullAddress)
          
          if (geocodeResult) {
            updateLocationOnMap(geocodeResult.latitude, geocodeResult.longitude)
          }
        }
      }
    } catch (error) {
      console.error('Erro ao buscar CEP:', error)
      setStepError(1, 'cep', [(error as Error).message])
    } finally {
      setIsCEPLoading(false)
    }
  }, [addressField, neighborhoodField, cityField, complementField, setStepError, lastSearchedCep])

  // Atualizar dados do formulário quando os campos mudam
  useEffect(() => {
    updateFormData('address', {
      cep: cepField.value,
      street: addressField.value,
      number: numberField.value,
      complement: complementField.value || undefined,
      neighborhood: neighborhoodField.value,
      city: cityField.value,
      state: selectedState
    })
  }, [
    cepField.value,
    addressField.value,
    numberField.value,
    complementField.value,
    neighborhoodField.value,
    cityField.value,
    selectedState,
    updateFormData
  ])

  // Validar formulário
  useEffect(() => {
    const isFormValid = 
      cepField.isValid && 
      addressField.isValid && 
      numberField.isValid &&
      complementField.isValid &&
      neighborhoodField.isValid &&
      cityField.isValid &&
      selectedState.length > 0 &&
      cepField.value.length === 9 && // XXXXX-XXX
      addressField.value.trim().length >= 5 &&
      numberField.value.trim().length > 0 &&
      neighborhoodField.value.trim().length >= 2 &&
      cityField.value.trim().length >= 2

    setFormValid(isFormValid)
  }, [
    cepField.isValid,
    cepField.value,
    addressField.isValid,
    addressField.value,
    numberField.isValid,
    numberField.value,
    complementField.isValid,
    neighborhoodField.isValid,
    neighborhoodField.value,
    cityField.isValid,
    cityField.value,
    selectedState
  ])

  // Atualizar validação global do stepper quando o formulário local muda
  useEffect(() => {
    validateStep(1)
  }, [formValid, validateStep])

  // Buscar CEP quando o campo estiver completo
  useEffect(() => {
    if (cepField.value.length === 9 && cepField.isValid) {
      handleCEPLookup(cepField.value)
    }
  }, [cepField.value, cepField.isValid]) // Removido handleCEPLookup das dependências

  // Inicializar Google Maps
  useEffect(() => {
    const initMaps = async () => {
      try {
        await loadGoogleMapsAPI()
        setMapLoaded(true)
      } catch (error) {
        console.error('Erro ao carregar Google Maps:', error)
      }
    }

    if (!isGoogleMapsLoaded) {
      initMaps()
    } else {
      setMapLoaded(true)
    }
  }, [isGoogleMapsLoaded])

  // Inicializar mapa quando carregado
  useEffect(() => {
    if (mapLoaded && mapRef.current && !mapInstanceRef.current) {
      initializeMap()
    }
  }, [mapLoaded])

  // Inicializar o mapa
  const initializeMap = useCallback(() => {
    if (!mapRef.current || mapInstanceRef.current) return

    const initialLocation = formData.location.latitude && formData.location.longitude 
      ? { lat: formData.location.latitude, lng: formData.location.longitude }
      : BRAZIL_CENTER

    // Criar mapa
    const map = new google.maps.Map(mapRef.current, {
      center: initialLocation,
      zoom: formData.location.latitude && formData.location.longitude ? 15 : 6,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      streetViewControl: false,
      mapTypeControl: true,
      fullscreenControl: true,
      zoomControl: true
    })

    // Criar marcador arrastável
    const marker = new google.maps.Marker({
      position: initialLocation,
      map,
      draggable: true,
      title: 'Localização da Clínica',
      animation: google.maps.Animation.DROP
    })

    // Listener para arrastar marcador
    marker.addListener('dragend', () => {
      const position = marker.getPosition()
      if (position) {
        const lat = position.lat()
        const lng = position.lng()
        updateLocationData(lat, lng, 'user')
        
        // Fazer reverse geocoding
        performReverseGeocode(lat, lng)
      }
    })

    // Listener para clique no mapa
    map.addListener('click', (e: google.maps.MapMouseEvent) => {
      if (e.latLng) {
        const lat = e.latLng.lat()
        const lng = e.latLng.lng()
        
        marker.setPosition({ lat, lng })
        updateLocationData(lat, lng, 'user')
        
        // Fazer reverse geocoding
        performReverseGeocode(lat, lng)
      }
    })

    mapInstanceRef.current = map
    markerRef.current = marker
  }, [formData.location])

  // Atualizar localização no mapa
  const updateLocationOnMap = useCallback((lat: number, lng: number) => {
    if (mapInstanceRef.current && markerRef.current) {
      const position = { lat, lng }
      
      mapInstanceRef.current.setCenter(position)
      mapInstanceRef.current.setZoom(15)
      markerRef.current.setPosition(position)
      
      updateLocationData(lat, lng, 'geocode')
    }
  }, [])

  // Atualizar dados de localização
  const updateLocationData = useCallback((lat: number, lng: number, source: 'user' | 'geocode' | 'gps') => {
    updateFormData('location', {
      latitude: lat,
      longitude: lng,
      accuracy: source === 'gps' ? currentLocation?.accuracy || 0 : 0,
      source
    })
  }, [updateFormData, currentLocation])

  // Realizar reverse geocoding
  const performReverseGeocode = useCallback(async (lat: number, lng: number) => {
    try {
      const result = await mapsService.reverseGeocode(lat, lng)
      
      if (result && result.addressComponents) {
        const components = result.addressComponents
        
        // Preencher campos se estiverem vazios
        if (!addressField.value && components.route) {
          addressField.setValue(components.route)
        }
        
        if (!numberField.value && components.streetNumber) {
          numberField.setValue(components.streetNumber)
        }
        
        if (!neighborhoodField.value && components.neighborhood) {
          neighborhoodField.setValue(components.neighborhood)
        }
        
        if (!cityField.value && components.city) {
          cityField.setValue(components.city)
        }
        
        if (!selectedState && components.state) {
          setSelectedState(components.state)
        }
        
        if (!cepField.value && components.postalCode) {
          cepField.setValue(formatCEP(components.postalCode))
        }
      }
    } catch (error) {
      console.error('Erro no reverse geocoding:', error)
    }
  }, [addressField, numberField, neighborhoodField, cityField, selectedState, cepField])

  // Obter localização atual do usuário
  const getCurrentLocation = useCallback(() => {
    if (!navigator.geolocation) {
      alert('Geolocalização não é suportada neste navegador')
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude, accuracy } = position.coords
        
        setCurrentLocation({ latitude, longitude, accuracy })
        updateLocationOnMap(latitude, longitude)
        updateLocationData(latitude, longitude, 'gps')
        
        // Fazer reverse geocoding
        performReverseGeocode(latitude, longitude)
      },
      (error) => {
        console.error('Erro ao obter localização:', error)
        alert('Erro ao obter localização atual')
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 300000 // 5 minutos
      }
    )
  }, [updateLocationOnMap, updateLocationData, performReverseGeocode])

  // Fazer geocoding do endereço atual
  const geocodeCurrentAddress = useCallback(async () => {
    if (!addressField.value || !cityField.value || !selectedState) {
      return
    }

    try {
      const fullAddress = `${addressField.value}${numberField.value ? `, ${numberField.value}` : ''}, ${neighborhoodField.value ? `${neighborhoodField.value}, ` : ''}${cityField.value}, ${selectedState}, Brasil`
      
      const result = await mapsService.geocodeAddress(fullAddress)
      
      if (result) {
        updateLocationOnMap(result.latitude, result.longitude)
      } else {
        alert('Não foi possível encontrar as coordenadas para este endereço')
      }
    } catch (error) {
      console.error('Erro no geocoding:', error)
      alert('Erro ao buscar coordenadas do endereço')
    }
  }, [addressField.value, numberField.value, neighborhoodField.value, cityField.value, selectedState, updateLocationOnMap])

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          🏠 Endereço e Localização
          {formValid && <CheckCircle color="success" />}
          {!formValid && cepField.touched && <Warning color="warning" />}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Informe o endereço completo e confirme a localização no mapa. O CEP será usado para preencher automaticamente os campos.
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Formulário de Endereço */}
        <Grid item xs={12} md={6}>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <LocationOn /> Dados do Endereço
              </Typography>
              
              <Grid container spacing={2}>
                {/* CEP */}
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="CEP"
                    required
                    value={cepField.value}
                    onChange={(e) => cepField.setValue(e.target.value)}
                    onBlur={cepField.onBlur}
                    error={cepField.showErrors}
                    helperText={cepField.showErrors ? cepField.errors[0] : 'Formato: XXXXX-XXX'}
                    placeholder="00000-000"
                    InputProps={{
                      endAdornment: (
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          {isCEPLoading && <CircularProgress color="inherit" size={20} />}
                          {cepLoadSuccess && !isCEPLoading && <CheckCircle color="success" />}
                        </Box>
                      )
                    }}
                  />
                </Grid>

                {/* Endereço */}
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Endereço"
                    required
                    value={addressField.value}
                    onChange={(e) => addressField.setValue(e.target.value)}
                    onBlur={addressField.onBlur}
                    error={addressField.showErrors}
                    helperText={addressField.showErrors ? addressField.errors[0] : 'Rua, avenida, etc.'}
                    placeholder="Rua das Flores"
                  />
                </Grid>

                {/* Número e Complemento */}
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Número"
                    required
                    value={numberField.value}
                    onChange={(e) => numberField.setValue(e.target.value)}
                    onBlur={numberField.onBlur}
                    error={numberField.showErrors}
                    helperText={numberField.showErrors ? numberField.errors[0] : 'Número do imóvel'}
                    placeholder="123"
                  />
                </Grid>

                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Complemento"
                    value={complementField.value}
                    onChange={(e) => complementField.setValue(e.target.value)}
                    onBlur={complementField.onBlur}
                    error={complementField.showErrors}
                    helperText={complementField.showErrors ? complementField.errors[0] : 'Opcional (Apto, Sala, etc.)'}
                    placeholder="Sala 101"
                  />
                </Grid>

                {/* Bairro */}
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Bairro"
                    required
                    value={neighborhoodField.value}
                    onChange={(e) => neighborhoodField.setValue(e.target.value)}
                    onBlur={neighborhoodField.onBlur}
                    error={neighborhoodField.showErrors}
                    helperText={neighborhoodField.showErrors ? neighborhoodField.errors[0] : 'Bairro da clínica'}
                    placeholder="Centro"
                  />
                </Grid>

                {/* Cidade e Estado */}
                <Grid item xs={8}>
                  <TextField
                    fullWidth
                    label="Cidade"
                    required
                    value={cityField.value}
                    onChange={(e) => cityField.setValue(e.target.value)}
                    onBlur={cityField.onBlur}
                    error={cityField.showErrors}
                    helperText={cityField.showErrors ? cityField.errors[0] : 'Cidade da clínica'}
                    placeholder="São Paulo"
                  />
                </Grid>

                <Grid item xs={4}>
                  <FormControl fullWidth required>
                    <InputLabel>Estado</InputLabel>
                    <Select
                      value={selectedState}
                      label="Estado"
                      onChange={(e) => setSelectedState(e.target.value)}
                    >
                      {BRAZILIAN_STATES.map((state) => (
                        <MenuItem key={state.code} value={state.code}>
                          {state.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
              </Grid>

              {/* Ações de Endereço */}
              <Box sx={{ mt: 2, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<Search />}
                  onClick={geocodeCurrentAddress}
                  disabled={!addressField.value || !cityField.value || !selectedState}
                >
                  Buscar no Mapa
                </Button>
                
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<MyLocation />}
                  onClick={getCurrentLocation}
                >
                  Minha Localização
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Mapa */}
        <Grid item xs={12} md={6}>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <MapIcon /> Localização no Mapa
                <Tooltip title="Arraste o marcador ou clique no mapa para definir a localização exata">
                  <IconButton size="small">
                    <Help fontSize="small" />
                  </IconButton>
                </Tooltip>
              </Typography>
              
              {!mapLoaded ? (
                <Box sx={{ 
                  height: 400, 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center',
                  bgcolor: 'grey.100',
                  borderRadius: 1
                }}>
                  <CircularProgress />
                  <Typography sx={{ ml: 2 }}>Carregando mapa...</Typography>
                </Box>
              ) : (
                <Box
                  ref={mapRef}
                  sx={{ 
                    height: 400, 
                    width: '100%', 
                    borderRadius: 1,
                    border: '1px solid',
                    borderColor: 'divider'
                  }}
                />
              )}
              
              {/* Informações da localização */}
              {formData.location.latitude && formData.location.longitude && (
                <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                  <Typography variant="caption" color="text.secondary" display="block">
                    Coordenadas: {formData.location.latitude.toFixed(6)}, {formData.location.longitude.toFixed(6)}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" display="block">
                    Fonte: {formData.location.source === 'user' ? 'Marcação manual' : 
                            formData.location.source === 'geocode' ? 'Geocoding' : 'GPS'}
                  </Typography>
                  {formData.location.accuracy > 0 && (
                    <Typography variant="caption" color="text.secondary" display="block">
                      Precisão: {formData.location.accuracy.toFixed(0)}m
                    </Typography>
                  )}
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Status do formulário */}
      <Box sx={{ mt: 4 }}>
        {formValid && (
          <Alert severity="success" sx={{ mb: 2 }}>
            ✅ Endereço e localização válidos! Você pode prosseguir para o próximo step.
          </Alert>
        )}
        
        {!formValid && cepField.touched && (
          <Alert severity="warning" sx={{ mb: 2 }}>
            ⚠️ Preencha todos os campos obrigatórios e confirme a localização no mapa.
          </Alert>
        )}

        {/* Indicadores de campos */}
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Chip
            label="CEP"
            color={cepField.isValid && cepField.value.length === 9 ? 'success' : 'default'}
            size="small"
            icon={cepField.isValid && cepField.value.length === 9 ? <CheckCircle /> : undefined}
          />
          <Chip
            label="Endereço"
            color={addressField.isValid && addressField.value.length >= 5 ? 'success' : 'default'}
            size="small"
            icon={addressField.isValid && addressField.value.length >= 5 ? <CheckCircle /> : undefined}
          />
          <Chip
            label="Número"
            color={numberField.isValid && numberField.value.length > 0 ? 'success' : 'default'}
            size="small"
            icon={numberField.isValid && numberField.value.length > 0 ? <CheckCircle /> : undefined}
          />
          <Chip
            label="Bairro"
            color={neighborhoodField.isValid && neighborhoodField.value.length >= 2 ? 'success' : 'default'}
            size="small"
            icon={neighborhoodField.isValid && neighborhoodField.value.length >= 2 ? <CheckCircle /> : undefined}
          />
          <Chip
            label="Cidade"
            color={cityField.isValid && cityField.value.length >= 2 ? 'success' : 'default'}
            size="small"
            icon={cityField.isValid && cityField.value.length >= 2 ? <CheckCircle /> : undefined}
          />
          <Chip
            label="Estado"
            color={selectedState.length > 0 ? 'success' : 'default'}
            size="small"
            icon={selectedState.length > 0 ? <CheckCircle /> : undefined}
          />
          <Chip
            label="Mapa"
            color={formData.location.latitude && formData.location.longitude ? 'success' : 'default'}
            size="small"
            icon={formData.location.latitude && formData.location.longitude ? <CheckCircle /> : undefined}
          />
        </Box>
      </Box>
    </Box>
  )
}

export default Step2AddressLocation