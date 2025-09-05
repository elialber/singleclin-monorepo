import React from 'react'
import { Box, Paper, Container } from '@mui/material'
import { ClinicStepper } from '../core/ClinicStepper'
import { ClinicFormData } from '../../../../types/stepper'

/**
 * Exemplo de uso do Step 1: Informações Básicas
 * 
 * Demonstra todas as funcionalidades implementadas:
 * - Validação em tempo real
 * - Máscaras CNPJ e telefone
 * - Auto-complete de nomes
 * - Verificação de duplicatas
 * - Tooltips explicativos
 * - Feedback visual
 */
export function Step1BasicInfoExample() {
  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Form submitted with data:', formData)
    
    // Simular processamento
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    alert(`Clínica "${formData.basicInfo.name}" cadastrada com sucesso!`)
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
          title="Exemplo: Step 1 - Informações Básicas"
        />
      </Paper>
    </Container>
  )
}

/**
 * Exemplo com dados pré-preenchidos (modo edição)
 */
export function Step1EditExample() {
  const initialData: Partial<ClinicFormData> = {
    basicInfo: {
      name: 'Clínica Exemplo Editada',
      type: 1, // ClinicType.Origin
      cnpj: '12.345.678/0001-90',
      phone: '(11) 99999-8888',
      email: 'contato@clinicaexemplo.com.br',
      isActive: true
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
          title="Exemplo: Editar Clínica"
        />
      </Paper>
    </Container>
  )
}

export default Step1BasicInfoExample