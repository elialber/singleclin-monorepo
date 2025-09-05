import React from 'react'
import { Box, Paper, Container } from '@mui/material'
import { ClinicStepper } from '../core/ClinicStepper'
import { ClinicFormData } from '../../../../types/stepper'

/**
 * Exemplo de uso do Step 2: Endereço e Localização
 * 
 * Demonstra todas as funcionalidades implementadas:
 * - Validação de CEP com ViaCEP API
 * - Preenchimento automático dos campos
 * - Google Maps com marcador arrastável
 * - Geocoding e reverse geocoding
 * - Obtenção de localização atual (GPS)
 * - Validação em tempo real
 */
export function Step2AddressLocationExample() {
  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Form submitted with data:', formData)
    
    // Simular processamento
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    const address = `${formData.address.street}, ${formData.address.number}${formData.address.complement ? `, ${formData.address.complement}` : ''}, ${formData.address.neighborhood}, ${formData.address.city} - ${formData.address.state}`
    const location = `${formData.location.latitude}, ${formData.location.longitude}`
    
    alert(`Endereço: "${address}"\nLocalização: ${location}\nCadastro realizado com sucesso!`)
  }

  const handleStepChange = (stepIndex: number) => {
    console.log('Step changed to:', stepIndex)
  }

  const handleError = (error: Error) => {
    console.error('Stepper error:', error)
    alert(`Erro: ${error.message}`)
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Paper sx={{ p: 4 }}>
        <ClinicStepper
          onSubmit={handleSubmit}
          onStepChange={handleStepChange}
          onError={handleError}
          title="Exemplo: Step 2 - Endereço e Localização"
        />
      </Paper>
    </Container>
  )
}

/**
 * Exemplo com dados pré-preenchidos (modo edição)
 */
export function Step2EditExample() {
  const initialData: Partial<ClinicFormData> = {
    basicInfo: {
      name: 'Clínica São Paulo Centro',
      type: 1, // ClinicType.Origin
      cnpj: '11.222.333/0001-81',
      phone: '(11) 3333-4444',
      email: 'contato@clinicasp.com.br',
      isActive: true
    },
    address: {
      cep: '01310-100',
      street: 'Avenida Paulista',
      number: '1578',
      complement: 'Conjunto 1405',
      neighborhood: 'Bela Vista',
      city: 'São Paulo',
      state: 'SP'
    },
    location: {
      latitude: -23.561684,
      longitude: -46.655981,
      accuracy: 0,
      source: 'geocode'
    }
  }

  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Updated clinic data:', formData)
    alert('Clínica atualizada com sucesso!')
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Paper sx={{ p: 4 }}>
        <ClinicStepper
          initialData={initialData}
          onSubmit={handleSubmit}
          title="Exemplo: Editar Endereço da Clínica"
        />
      </Paper>
    </Container>
  )
}

/**
 * Exemplo focado apenas no Step 2 (começar direto no endereço)
 */
export function Step2DirectExample() {
  const initialData: Partial<ClinicFormData> = {
    basicInfo: {
      name: 'Clínica Exemplo',
      type: 0, // ClinicType.Regular
      cnpj: '12.345.678/0001-90',
      phone: '(11) 99999-8888',
      email: 'contato@clinica.com.br',
      isActive: true
    }
  }

  // Forçar início no step 2
  React.useEffect(() => {
    // Em uma implementação real, você poderia usar um parâmetro initialStep
    // ou controlar o step atual via props/contexto
  }, [])

  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Address focused form data:', formData)
    alert('Endereço configurado com sucesso!')
  }

  const handleStepChange = (stepIndex: number) => {
    console.log('Current step:', stepIndex)
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Paper sx={{ p: 4 }}>
        <ClinicStepper
          initialData={initialData}
          onSubmit={handleSubmit}
          onStepChange={handleStepChange}
          title="Exemplo: Configuração de Endereço"
        />
      </Paper>
    </Container>
  )
}

export default Step2AddressLocationExample