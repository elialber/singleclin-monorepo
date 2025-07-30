import { useQuery } from '@tanstack/react-query'
import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000'

interface Clinic {
  id: string
  name: string
  type: string
}

interface Plan {
  id: string
  name: string
  credits: number
  price: number
}

export function useReportMetadata() {
  const clinicsQuery = useQuery({
    queryKey: ['clinics'],
    queryFn: async () => {
      const response = await axios.get(`${API_URL}/api/clinics`)
      return response.data.data as Clinic[]
    },
  })

  const plansQuery = useQuery({
    queryKey: ['plans'],
    queryFn: async () => {
      const response = await axios.get(`${API_URL}/api/plans`)
      return response.data.data as Plan[]
    },
  })

  // Mock service types for now
  const serviceTypes = [
    'Consulta Médica',
    'Exame de Sangue',
    'Raio-X',
    'Ultrassonografia',
    'Tomografia',
    'Ressonância Magnética',
    'Fisioterapia',
    'Psicologia',
    'Nutrição',
    'Odontologia',
  ]

  return {
    clinics: clinicsQuery.data || [],
    plans: plansQuery.data || [],
    serviceTypes,
    loading: clinicsQuery.isLoading || plansQuery.isLoading,
  }
}