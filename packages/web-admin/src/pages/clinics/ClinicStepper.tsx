import { useNavigate, useParams } from 'react-router-dom'
import { Box, Container, IconButton, Typography, CircularProgress, Alert } from '@mui/material'
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material'
import { ClinicStepper } from '@/components/clinic/stepper/core/ClinicStepper'
import { ClinicFormData, PREDEFINED_SERVICES, ImageData } from '@/types/stepper'
import { CreateClinicRequest, UpdateClinicRequest, Clinic, ClinicType } from '@/types/clinic'
import { useNotification } from '@/contexts/NotificationContextDefinition'
import { clinicService } from '@/services/clinic.service'
import { useQuery } from '@tanstack/react-query'
import { useMemo } from 'react'

export default function ClinicStepperPage() {
  const navigate = useNavigate()
  const { id: clinicId } = useParams<{ id: string }>()
  const { showNotification } = useNotification()
  
  const isEditMode = Boolean(clinicId)
  
  // Carregar dados da clínica para edição
  const { data: clinic, isLoading: isLoadingClinic, error: clinicError } = useQuery({
    queryKey: ['clinic', clinicId],
    queryFn: () => clinicService.getClinic(clinicId!),
    enabled: isEditMode,
    retry: 2
  })

  // Função para tentar extrair componentes do endereço
  const parseAddressString = (fullAddress: string) => {
    console.log('📍 Parseando endereço completo:', fullAddress)
    
    if (!fullAddress || fullAddress.trim() === '') {
      return {
        cep: '',
        street: '',
        number: '',
        complement: '',
        neighborhood: '',
        city: '',
        state: ''
      }
    }
    
    // Tentar extrair informações do endereço baseado em padrões comuns
    // Exemplo: "Rua das Flores, 123, Apt 45, Centro, São Paulo, SP, 12345-678"
    
    const parts = fullAddress.split(', ').map(p => p.trim()).filter(p => p)
    console.log('📍 Partes do endereço:', parts)
    
    // Padrão básico: tentar identificar CEP (formato brasileiro: XXXXX-XXX ou XXXXXXXX)
    const cepPattern = /\d{5}-?\d{3}/
    let cep = ''
    let remainingParts = [...parts]
    
    // Procurar CEP nos últimos elementos (mais comum)
    for (let i = parts.length - 1; i >= 0; i--) {
      if (cepPattern.test(parts[i])) {
        cep = parts[i].replace(/(\d{5})(\d{3})/, '$1-$2') // Adicionar hífen se não tiver
        remainingParts.splice(i, 1)
        break
      }
    }
    
    // Tentar identificar estados brasileiros comuns
    const brazilianStates = [
      'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 
      'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 
      'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
    ]
    
    let state = ''
    // Procurar estado nos últimos elementos
    for (let i = remainingParts.length - 1; i >= 0; i--) {
      if (brazilianStates.includes(remainingParts[i].toUpperCase())) {
        state = remainingParts[i].toUpperCase()
        remainingParts.splice(i, 1)
        break
      }
    }
    
    // Estratégia de distribuição baseada na quantidade de partes restantes
    let result = {
      cep,
      street: '',
      number: '',
      complement: '',
      neighborhood: '',
      city: '',
      state
    }
    
    if (remainingParts.length === 0) {
      // Só tínhamos CEP e/ou estado
      result.street = fullAddress
    } else if (remainingParts.length === 1) {
      // Só uma parte - provavelmente o endereço completo
      result.street = remainingParts[0]
    } else if (remainingParts.length === 2) {
      // Duas partes - assumir rua e cidade
      result.street = remainingParts[0]
      result.city = remainingParts[1]
    } else if (remainingParts.length === 3) {
      // Três partes - rua, bairro, cidade
      result.street = remainingParts[0]
      result.neighborhood = remainingParts[1]
      result.city = remainingParts[2]
    } else if (remainingParts.length === 4) {
      // Quatro partes - rua, número, bairro, cidade
      result.street = remainingParts[0]
      result.number = remainingParts[1]
      result.neighborhood = remainingParts[2]
      result.city = remainingParts[3]
    } else if (remainingParts.length >= 5) {
      // Cinco ou mais partes - distribuir de forma mais inteligente
      result.street = remainingParts[0]
      result.number = remainingParts[1]
      
      // Se tem 6 ou mais, o terceiro pode ser complemento
      if (remainingParts.length >= 6) {
        result.complement = remainingParts[2]
        result.neighborhood = remainingParts[remainingParts.length - 2]
        result.city = remainingParts[remainingParts.length - 1]
      } else {
        result.neighborhood = remainingParts[2]
        result.city = remainingParts[3]
      }
    }
    
    console.log('📍 Resultado do parsing:', result)
    return result
  }

  // Mapear dados da clínica para o formato do formulário
  const initialFormData = useMemo((): Partial<ClinicFormData> | undefined => {
    if (!isEditMode || !clinic) return undefined

    console.log('🔄 Mapeando dados da clínica para edição:', clinic)
    console.log('🖼️ Dados de imagem da clínica:', {
      imageUrl: clinic.imageUrl,
      hasImage: clinic.hasImage
    })
    
    // Tentar extrair componentes do endereço
    const addressComponents = parseAddressString(clinic.address)
    console.log('📍 Componentes do endereço extraídos:', addressComponents)
    
    const formData = {
      basicInfo: {
        name: clinic.name,
        type: clinic.type,
        cnpj: clinic.cnpj || undefined,
        phone: clinic.phoneNumber || undefined,
        email: clinic.email || undefined,
        isActive: clinic.isActive
      },
      address: addressComponents,
      location: {
        latitude: clinic.latitude || 0,
        longitude: clinic.longitude || 0,
        accuracy: 0,
        source: 'user' as const
      },
      services: {
        selectedServices: PREDEFINED_SERVICES.map(service => ({ ...service }))
      },
      images: (() => {
        let mappedImages: ImageData[] = []
        
        // Usar o novo array de imagens se disponível
        if (clinic.images && clinic.images.length > 0) {
          mappedImages = clinic.images.map((img, index) => ({
            id: `existing-${img.id}`,
            file: undefined, // Imagens existentes não têm arquivo
            url: img.imageUrl,
            preview: img.imageUrl,
            altText: img.altText || `Imagem da clínica ${clinic.name}`,
            displayOrder: img.displayOrder || index,
            isFeatured: img.isFeatured,
            isExisting: true,
            dimensions: {
              width: img.width || 800,
              height: img.height || 600
            },
            sizeBytes: img.size || 0,
            type: img.contentType || 'image/jpeg',
            uploadStatus: 'success' as const,
            uploadProgress: 100
          }))
        } 
        // Fallback para o campo antigo imageUrl se não tiver imagens no array
        else if (clinic.imageUrl) {
          mappedImages = [{
            id: 'existing-legacy-image',
            file: undefined, // Imagens existentes não têm arquivo
            url: clinic.imageUrl,
            preview: clinic.imageUrl,
            altText: `Imagem da clínica ${clinic.name}`,
            displayOrder: 0,
            isFeatured: true,
            isExisting: true,
            dimensions: {
              width: 800,
              height: 600
            },
            sizeBytes: 0,
            type: 'image/jpeg',
            uploadStatus: 'success' as const,
            uploadProgress: 100
          }]
        }
        
        console.log('🖼️ Imagens mapeadas para o formulário:', mappedImages)
        console.log('📊 Total de imagens existentes:', mappedImages.length)
        return mappedImages
      })(),
      metadata: {
        createdAt: new Date(),
        updatedAt: new Date(),
        completedSteps: [],
        timeSpentPerStep: [],
        totalTime: 0
      }
    }
    
    console.log('📋 Dados iniciais do formulário gerados:', formData)
    return formData
  }, [isEditMode, clinic])

  const mapFormDataToRequest = (data: ClinicFormData): CreateClinicRequest & { latitude?: number; longitude?: number } => {
    // Montar endereço completo
    const addressParts = [
      data.address.street,
      data.address.number,
      data.address.complement,
      data.address.neighborhood,
      data.address.city,
      data.address.state,
      data.address.cep
    ].filter(Boolean)
    
    const fullAddress = addressParts.join(', ')

    const request: any = {
      name: data.basicInfo.name,
      type: data.basicInfo.type,
      address: fullAddress,
      phoneNumber: data.basicInfo.phone || undefined,
      email: data.basicInfo.email || undefined,
      cnpj: data.basicInfo.cnpj || undefined,
      isActive: data.basicInfo.isActive
    }

    // Adicionar coordenadas se disponíveis
    if (data.location && data.location.latitude && data.location.longitude) {
      request.latitude = data.location.latitude
      request.longitude = data.location.longitude
    }

    return request
  }

  const handleSubmit = async (data: ClinicFormData) => {
    try {
      console.log('📋 Dados da clínica para envio:', data)
      
      // Mapear dados do formulário para o formato da API
      const requestData = mapFormDataToRequest(data)
      console.log('🔄 Dados mapeados para API:', requestData)
      
      let resultClinic: Clinic
      
      if (isEditMode && clinicId) {
        // Editar clínica existente
        console.log('✏️ Atualizando clínica existente:', clinicId)
        resultClinic = await clinicService.updateClinic(clinicId, requestData as UpdateClinicRequest)
        console.log('✅ Clínica atualizada com sucesso:', resultClinic)
      } else {
        // Criar nova clínica
        console.log('➕ Criando nova clínica')
        resultClinic = await clinicService.createClinic(requestData)
        console.log('✅ Clínica criada com sucesso:', resultClinic)
      }
      
      // Fazer upload de múltiplas imagens se existirem (backend agora suporta até 10 imagens por clínica)
      if (data.images && data.images.length > 0) {
        // Filtrar apenas imagens com arquivo (novas imagens)
        const imagesToUpload = data.images.filter(img => img.file)
        
        if (imagesToUpload.length > 0) {
          console.log('📸 Fazendo upload de', imagesToUpload.length, 'imagens:', imagesToUpload.map(img => img.file?.name))
          
          // Encontrar índice da imagem principal
          const featuredImageIndex = imagesToUpload.findIndex(img => img.isFeatured)
          
          const uploadResult = await clinicService.uploadMultipleImages(resultClinic.id, {
            images: imagesToUpload.map(img => img.file!),
            altTexts: imagesToUpload.map(img => img.altText || `Imagem da clínica ${resultClinic.name}`),
            descriptions: imagesToUpload.map(img => `Imagem da clínica ${resultClinic.name}`),
            displayOrders: imagesToUpload.map((_, index) => index),
            featuredImageIndex: featuredImageIndex >= 0 ? featuredImageIndex : 0
          })
          
          if (!uploadResult.success) {
            console.warn('⚠️ Falhas no upload de imagens:', uploadResult.errorMessages)
            const action = isEditMode ? 'atualizada' : 'criada'
            showNotification(
              `Clínica ${action}, mas ${uploadResult.failureCount} imagem(ns) falharam no upload. Erros: ${uploadResult.errorMessages.join(', ')}`, 
              'warning'
            )
          } else {
            console.log(`✅ ${uploadResult.successCount} imagens enviadas com sucesso`)
            if (uploadResult.successCount > 0) {
              showNotification(`${uploadResult.successCount} imagens enviadas com sucesso!`, 'success')
            }
          }
        }
      }
      
      const successMessage = isEditMode ? 'Clínica atualizada com sucesso!' : 'Clínica cadastrada com sucesso!'
      showNotification(successMessage, 'success')
      
      // Redirecionar para lista de clínicas após sucesso
      navigate('/clinics')
      
    } catch (error: any) {
      console.error('❌ Erro ao cadastrar clínica:', error)
      
      // Extrair mensagem de erro mais específica
      let errorMessage = error?.response?.data?.message || 
                        error?.message || 
                        'Erro desconhecido ao cadastrar clínica'
      
      // Tratar erro específico de clínica Origin
      if (error?.response?.data?.errors?.Type?.includes('Origin clinics require special authorization')) {
        errorMessage = 'Clínicas do tipo "Origem" requerem autorização especial e não podem ser criadas por este formulário. Entre em contato com a administração do sistema.'
      }
      
      // Tratar outros erros de validação
      if (error?.response?.data?.errors && typeof error.response.data.errors === 'object') {
        const validationErrors = Object.values(error.response.data.errors).flat()
        errorMessage = validationErrors.join('; ')
      }
      
      const action = isEditMode ? 'atualizar' : 'cadastrar'
      showNotification(`Erro ao ${action} clínica: ${errorMessage}`, 'error')
      throw error
    }
  }

  const handleCancel = () => {
    navigate('/clinics')
  }

  const handleError = (error: Error) => {
    console.error('Erro no stepper:', error)
    showNotification('Erro interno. Tente novamente.', 'error')
  }

  const handleStepChange = (stepIndex: number) => {
    console.log('📍 Navegou para o step:', stepIndex)
  }

  // Loading state enquanto carrega dados da clínica
  if (isEditMode && isLoadingClinic) {
    return (
      <Box sx={{ minHeight: '100vh', bgcolor: 'grey.50', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Box sx={{ textAlign: 'center' }}>
          <CircularProgress size={40} sx={{ mb: 2 }} />
          <Typography variant="body1" color="text.secondary">
            Carregando dados da clínica...
          </Typography>
        </Box>
      </Box>
    )
  }

  // Error state se falhou ao carregar dados da clínica
  if (isEditMode && clinicError) {
    return (
      <Box sx={{ minHeight: '100vh', bgcolor: 'grey.50', p: 3 }}>
        <Container maxWidth="lg">
          <Alert severity="error" sx={{ mb: 2 }}>
            Erro ao carregar dados da clínica: {clinicError.message}
          </Alert>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <IconButton onClick={() => navigate('/clinics')}>
              <ArrowBackIcon />
            </IconButton>
            <Typography variant="h5">
              Erro ao carregar clínica
            </Typography>
          </Box>
        </Container>
      </Box>
    )
  }

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'grey.50' }}>
      {/* Header com botão voltar */}
      <Box sx={{ 
        bgcolor: 'white', 
        borderBottom: 1, 
        borderColor: 'divider',
        py: 2
      }}>
        <Container maxWidth="lg">
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <IconButton 
              onClick={handleCancel}
              sx={{ 
                bgcolor: 'grey.100',
                '&:hover': { bgcolor: 'grey.200' }
              }}
            >
              <ArrowBackIcon />
            </IconButton>
            <Box>
              <Typography variant="h5" fontWeight={600}>
                {isEditMode ? `Editar Clínica: ${clinic?.name || 'Carregando...'}` : 'Cadastro de Nova Clínica'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {isEditMode 
                  ? 'Atualize as informações da clínica em 4 etapas simples' 
                  : 'Complete as informações da clínica em 4 etapas simples'
                }
              </Typography>
            </Box>
          </Box>
        </Container>
      </Box>

      {/* Stepper Component */}
      <ClinicStepper
        initialData={initialFormData}
        onSubmit={handleSubmit}
        onCancel={handleCancel}
        onError={handleError}
        onStepChange={handleStepChange}
        title={isEditMode ? 'Edição de Clínica' : 'Cadastro de Clínica'}
      />
    </Box>
  )
}