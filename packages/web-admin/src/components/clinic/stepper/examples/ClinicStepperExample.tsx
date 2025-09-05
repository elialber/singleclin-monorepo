import React from 'react'
import { ClinicStepper } from '../core/ClinicStepper'
import { ClinicFormData } from '../../../../types/stepper'
import { ClinicType } from '../../../../types/clinic'

/**
 * Exemplo de uso do ClinicStepper
 * 
 * Este componente demonstra como usar o stepper de cadastro de clínica
 */
export function ClinicStepperExample() {
  // Dados iniciais (opcional - para edição)
  const initialData: Partial<ClinicFormData> = {
    basicInfo: {
      name: 'Clínica Exemplo',
      type: ClinicType.Regular,
      isActive: true,
      cnpj: '',
      phone: '',
      email: ''
    }
  }

  // Handler para submissão do formulário
  const handleSubmit = async (formData: ClinicFormData) => {
    try {
      console.log('Submitting form data:', formData)
      
      // Aqui você faria a chamada para a API
      // const response = await clinicService.createClinic(formData)
      
      // Simular delay
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      alert('Clínica cadastrada com sucesso!')
    } catch (error) {
      console.error('Error submitting form:', error)
      throw error
    }
  }

  // Handler para mudança de step
  const handleStepChange = (stepIndex: number) => {
    console.log('Current step:', stepIndex)
  }

  // Handler para erros
  const handleError = (error: Error) => {
    console.error('Stepper error:', error)
    alert(`Erro: ${error.message}`)
  }

  // Handler para cancelar
  const handleCancel = () => {
    if (confirm('Tem certeza de que deseja cancelar o cadastro?')) {
      console.log('Cancelled')
      // Navegar para lista de clínicas ou dashboard
    }
  }

  return (
    <div>
      <ClinicStepper
        initialData={initialData}
        onSubmit={handleSubmit}
        onStepChange={handleStepChange}
        onError={handleError}
        onCancel={handleCancel}
        title="Cadastrar Nova Clínica"
        compact={false}
        disableAutoSave={false}
      />
    </div>
  )
}

/**
 * Exemplo de uso em modo compacto (para modal)
 */
export function ClinicStepperCompactExample() {
  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Compact stepper submission:', formData)
  }

  return (
    <ClinicStepper
      onSubmit={handleSubmit}
      title="Cadastro Rápido"
      compact={true}
      disableAutoSave={true}
    />
  )
}

export default ClinicStepperExample