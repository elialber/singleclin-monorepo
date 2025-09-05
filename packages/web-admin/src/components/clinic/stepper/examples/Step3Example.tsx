import React from 'react'
import { Box, Paper, Container } from '@mui/material'
import { ClinicStepper } from '../core/ClinicStepper'
import { ClinicFormData } from '../../../../types/stepper'

/**
 * Exemplo de uso do Step 3: Upload Múltiplo de Imagens
 * 
 * Demonstra todas as funcionalidades implementadas:
 * - Drag & drop de múltiplas imagens
 * - Validação de tipos, tamanhos e dimensões
 * - Preview com thumbnails responsivos
 * - Upload simultâneo com progress bars individuais
 * - Definição de imagem principal
 * - Edição de alt text para acessibilidade
 * - Batch operations (seleção múltipla)
 * - Retry automático em caso de falha
 * - Grid reordenável por drag & drop
 */
export function Step3ImageUploadExample() {
  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Form submitted with data:', formData)
    
    // Simular processamento
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    const imageCount = formData.images.length
    const featuredImage = formData.images.find(img => img.isFeatured)
    
    alert(`Upload completo!\n${imageCount} imagem(ns) adicionada(s)\nImagem principal: ${featuredImage?.altText || 'Sem descrição'}`)
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
          title="Exemplo: Step 3 - Upload de Imagens"
        />
      </Paper>
    </Container>
  )
}

/**
 * Exemplo com dados pré-preenchidos incluindo imagens
 */
export function Step3EditExample() {
  const initialData: Partial<ClinicFormData> = {
    basicInfo: {
      name: 'Clínica Imagem Plus',
      type: 1, // ClinicType.Origin
      cnpj: '11.222.333/0001-81',
      phone: '(11) 3333-4444',
      email: 'contato@clinicaimagem.com.br',
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
    },
    images: [
      {
        id: 'img_1',
        url: 'https://picsum.photos/800/600?random=1',
        altText: 'Fachada principal da clínica',
        displayOrder: 0,
        isFeatured: true,
        uploadStatus: 'success',
        uploadProgress: 100
      },
      {
        id: 'img_2',
        url: 'https://picsum.photos/800/600?random=2',
        altText: 'Recepção com área de espera',
        displayOrder: 1,
        isFeatured: false,
        uploadStatus: 'success',
        uploadProgress: 100
      },
      {
        id: 'img_3',
        url: 'https://picsum.photos/800/600?random=3',
        altText: 'Consultório médico equipado',
        displayOrder: 2,
        isFeatured: false,
        uploadStatus: 'success',
        uploadProgress: 100
      }
    ]
  }

  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Updated clinic data:', formData)
    alert('Clínica e imagens atualizadas com sucesso!')
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Paper sx={{ p: 4 }}>
        <ClinicStepper
          initialData={initialData}
          onSubmit={handleSubmit}
          title="Exemplo: Editar Imagens da Clínica"
        />
      </Paper>
    </Container>
  )
}

/**
 * Exemplo focado no upload de imagens (começar direto no step 3)
 */
export function Step3DirectExample() {
  const initialData: Partial<ClinicFormData> = {
    basicInfo: {
      name: 'Clínica Exemplo',
      type: 0, // ClinicType.Regular
      cnpj: '12.345.678/0001-90',
      phone: '(11) 99999-8888',
      email: 'contato@clinica.com.br',
      isActive: true
    },
    address: {
      cep: '01234-567',
      street: 'Rua das Imagens',
      number: '123',
      neighborhood: 'Centro',
      city: 'São Paulo',
      state: 'SP'
    },
    location: {
      latitude: -23.550520,
      longitude: -46.633308,
      accuracy: 0,
      source: 'user'
    }
  }

  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Image focused form data:', formData)
    
    const imageStats = {
      total: formData.images.length,
      uploaded: formData.images.filter(img => img.uploadStatus === 'success').length,
      failed: formData.images.filter(img => img.uploadStatus === 'error').length,
      featured: formData.images.find(img => img.isFeatured)?.altText || 'Nenhuma'
    }
    
    alert(`Imagens configuradas:\n` +
          `Total: ${imageStats.total}\n` +
          `Enviadas: ${imageStats.uploaded}\n` +
          `Com falha: ${imageStats.failed}\n` +
          `Principal: ${imageStats.featured}`)
  }

  const handleStepChange = (stepIndex: number) => {
    console.log('Current step:', stepIndex)
    
    // Log específico para step de imagens
    if (stepIndex === 2) {
      console.log('Entered image upload step')
    }
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Paper sx={{ p: 4 }}>
        <ClinicStepper
          initialData={initialData}
          onSubmit={handleSubmit}
          onStepChange={handleStepChange}
          title="Exemplo: Foco no Upload de Imagens"
        />
      </Paper>
    </Container>
  )
}

/**
 * Exemplo para testar casos de erro no upload
 */
export function Step3ErrorHandlingExample() {
  const initialData: Partial<ClinicFormData> = {
    basicInfo: {
      name: 'Clínica Teste Erros',
      type: 2, // ClinicType.Partner
      cnpj: '98.765.432/0001-10',
      phone: '(21) 8888-7777',
      email: 'teste@clinica.com.br',
      isActive: true
    },
    address: {
      cep: '20040-020',
      street: 'Rua dos Testes',
      number: '456',
      neighborhood: 'Centro',
      city: 'Rio de Janeiro',
      state: 'RJ'
    },
    images: [
      // Imagem com erro simulado
      {
        id: 'img_error_1',
        url: '',
        altText: 'Imagem com falha no upload',
        displayOrder: 0,
        isFeatured: true,
        uploadStatus: 'error',
        uploadProgress: 0,
        error: 'Falha na conexão com o servidor'
      },
      // Imagem em upload
      {
        id: 'img_uploading_1',
        url: '',
        altText: 'Imagem sendo enviada',
        displayOrder: 1,
        isFeatured: false,
        uploadStatus: 'uploading',
        uploadProgress: 65
      }
    ]
  }

  const handleSubmit = async (formData: ClinicFormData) => {
    console.log('Error handling test data:', formData)
    
    // Verificar se há erros
    const hasErrors = formData.images.some(img => img.uploadStatus === 'error')
    const isUploading = formData.images.some(img => img.uploadStatus === 'uploading')
    
    if (hasErrors) {
      alert('⚠️ Existem imagens com erro. Corrija antes de prosseguir.')
      return
    }
    
    if (isUploading) {
      alert('⏳ Aguarde o upload de todas as imagens.')
      return
    }
    
    alert('✅ Todos os uploads foram concluídos com sucesso!')
  }

  const handleError = (error: Error) => {
    console.error('Upload error example:', error)
    // Em um caso real, você poderia exibir uma notificação toast
    alert(`Erro capturado: ${error.message}`)
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Paper sx={{ p: 4 }}>
        <ClinicStepper
          initialData={initialData}
          onSubmit={handleSubmit}
          onError={handleError}
          title="Exemplo: Tratamento de Erros no Upload"
        />
      </Paper>
    </Container>
  )
}

export default Step3ImageUploadExample