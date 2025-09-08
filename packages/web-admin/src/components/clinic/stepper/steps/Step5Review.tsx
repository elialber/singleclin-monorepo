import React, { useState, useCallback } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  CardActions,
  Grid,
  Chip,
  Button,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Divider,
  Alert,
  Paper,
  Avatar,
  Badge,
  Tooltip,
  Collapse,
  LinearProgress,
  Stack
} from '@mui/material'
import {
  CheckCircle,
  Warning,
  Error,
  Edit,
  Visibility,
  Star,
  LocationOn,
  Business,
  Email,
  Phone,
  Language,
  ExpandMore,
  ExpandLess,
  ArrowBack,
  Send,
  Info,
  Map as MapIcon,
  Collections,
  Verified
} from '@mui/icons-material'
import { useClinicStepper } from '../hooks/useClinicStepper'
import { StepComponentProps, ClinicFormData } from '../../../../types/stepper'
import { ClinicType } from '../../../../types/clinic'
import { BRAZILIAN_STATES } from '../../../../types/stepper'
import { formatFileSize } from '../../../../utils/imageValidation'

/**
 * Step 5: Revisão Final
 * 
 * Resumo completo de todos os dados com edição inline e validação final
 */
function Step5Review({ onNext, onPrev, isValid, isDirty }: StepComponentProps) {
  const { 
    formData, 
    updateFormData, 
    goToStep, 
    validateStep, 
    submitForm,
    state
  } = useClinicStepper()

  // Estados locais
  const [editingField, setEditingField] = useState<string | null>(null)
  const [tempValue, setTempValue] = useState<string>('')
  const [expandedSections, setExpandedSections] = useState<Set<string>>(
    new Set(['basic', 'address', 'images'])
  )
  const [showValidationDetails, setShowValidationDetails] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Obter rótulos e valores formatados
  const getClinicTypeLabel = (type: ClinicType): string => {
    const labels = {
      [ClinicType.Regular]: 'Regular',
      [ClinicType.Origin]: 'Origem',
      [ClinicType.Partner]: 'Parceira',
      [ClinicType.Administrative]: 'Administrativa'
    }
    return labels[type] || 'Desconhecido'
  }

  const getStateLabel = (stateCode: string): string => {
    const state = BRAZILIAN_STATES.find(s => s.value === stateCode)
    return state ? state.label : stateCode
  }

  const getLocationSourceLabel = (source: string): string => {
    const labels = {
      user: 'Marcação manual',
      geocode: 'Endereço (geocoding)',
      gps: 'GPS do dispositivo'
    }
    return labels[source as keyof typeof labels] || source
  }

  // Validação de steps
  const stepValidation = {
    basicInfo: state.isValid[0],
    address: state.isValid[1], 
    images: state.isValid[2]
  }

  const allStepsValid = Object.values(stepValidation).every(v => v)
  const featuredImage = formData.images.find(img => img.isFeatured)
  const totalImagesSize = formData.images.reduce((sum, img) => sum + (img.file?.size || 0), 0)

  // Handlers para edição inline
  const handleEditField = (field: string, currentValue: string) => {
    setEditingField(field)
    setTempValue(currentValue)
  }

  const handleSaveField = useCallback(async (field: string) => {
    if (!tempValue.trim()) {
      setEditingField(null)
      return
    }

    const [section, fieldName] = field.split('.')
    
    try {
      // Atualizar dados
      if (section === 'basicInfo') {
        updateFormData('basicInfo', { [fieldName]: tempValue.trim() })
      } else if (section === 'address') {
        updateFormData('address', { [fieldName]: tempValue.trim() })
      }

      // Revalidar step correspondente
      if (section === 'basicInfo') {
        await validateStep(0)
      } else if (section === 'address') {
        await validateStep(1)
      }

    } catch (error) {
      console.error('Erro ao salvar campo:', error)
    }

    setEditingField(null)
    setTempValue('')
  }, [tempValue, updateFormData, validateStep])

  const handleCancelEdit = () => {
    setEditingField(null)
    setTempValue('')
  }

  // Toggle de seções expandidas
  const toggleSection = (section: string) => {
    setExpandedSections(prev => {
      const newSet = new Set(prev)
      if (newSet.has(section)) {
        newSet.delete(section)
      } else {
        newSet.add(section)
      }
      return newSet
    })
  }

  // Navegação para steps específicos
  const goToStepHandler = (stepIndex: number) => {
    goToStep(stepIndex)
  }

  // Submit final
  const handleFinalSubmit = async () => {
    if (!allStepsValid) {
      setShowValidationDetails(true)
      return
    }

    setIsSubmitting(true)
    try {
      await submitForm()
    } catch (error) {
      console.error('Erro no submit:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  // Renderizar campo editável
  const renderEditableField = (
    field: string,
    label: string,
    value: string,
    multiline: boolean = false
  ) => {
    const isEditing = editingField === field

    if (isEditing) {
      return (
        <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-start' }}>
          <TextField
            fullWidth
            size="small"
            value={tempValue}
            onChange={(e) => setTempValue(e.target.value)}
            multiline={multiline}
            rows={multiline ? 2 : 1}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !multiline) {
                handleSaveField(field)
              } else if (e.key === 'Escape') {
                handleCancelEdit()
              }
            }}
            autoFocus
          />
          <IconButton size="small" color="primary" onClick={() => handleSaveField(field)}>
            <CheckCircle />
          </IconButton>
          <IconButton size="small" onClick={handleCancelEdit}>
            <Error />
          </IconButton>
        </Box>
      )
    }

    return (
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <Typography variant="body2" sx={{ flex: 1 }}>
          <strong>{label}:</strong> {value}
        </Typography>
        <IconButton size="small" onClick={() => handleEditField(field, value)}>
          <Edit />
        </IconButton>
      </Box>
    )
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          ✅ Revisão Final
          {allStepsValid && <Verified color="success" />}
          {!allStepsValid && <Warning color="warning" />}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Revise todas as informações antes de finalizar o cadastro. Você pode editar campos diretamente ou voltar aos steps anteriores.
        </Typography>
      </Box>

      {/* Validação Geral */}
      <Card sx={{ mb: 3, bgcolor: allStepsValid ? 'success.50' : 'warning.50' }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
            {allStepsValid ? (
              <CheckCircle color="success" sx={{ fontSize: 32 }} />
            ) : (
              <Warning color="warning" sx={{ fontSize: 32 }} />
            )}
            <Box>
              <Typography variant="h6">
                {allStepsValid ? 'Cadastro Válido' : 'Verificação Necessária'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {allStepsValid 
                  ? 'Todos os dados estão corretos e o cadastro pode ser finalizado'
                  : 'Alguns campos precisam ser corrigidos antes de prosseguir'
                }
              </Typography>
            </Box>
          </Box>

          {/* Indicadores de Steps */}
          <Grid container spacing={2}>
            <Grid item xs={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Chip 
                  icon={stepValidation.basicInfo ? <CheckCircle /> : <Warning />}
                  label="Informações Básicas"
                  color={stepValidation.basicInfo ? 'success' : 'warning'}
                  size="small"
                  onClick={() => goToStepHandler(0)}
                  sx={{ cursor: 'pointer' }}
                />
              </Box>
            </Grid>
            <Grid item xs={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Chip 
                  icon={stepValidation.address ? <CheckCircle /> : <Warning />}
                  label="Endereço"
                  color={stepValidation.address ? 'success' : 'warning'}
                  size="small"
                  onClick={() => goToStepHandler(1)}
                  sx={{ cursor: 'pointer' }}
                />
              </Box>
            </Grid>
            <Grid item xs={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Chip 
                  icon={stepValidation.images ? <CheckCircle /> : <Warning />}
                  label="Imagens"
                  color={stepValidation.images ? 'success' : 'warning'}
                  size="small"
                  onClick={() => goToStepHandler(2)}
                  sx={{ cursor: 'pointer' }}
                />
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      <Grid container spacing={3}>
        {/* Informações Básicas */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardActions sx={{ justifyContent: 'space-between', pb: 0 }}>
              <Typography variant="h6" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Business color="primary" />
                Informações Básicas
              </Typography>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <IconButton 
                  size="small" 
                  onClick={() => toggleSection('basic')}
                >
                  {expandedSections.has('basic') ? <ExpandLess /> : <ExpandMore />}
                </IconButton>
                <Button 
                  size="small"
                  startIcon={<ArrowBack />}
                  onClick={() => goToStepHandler(0)}
                >
                  Editar
                </Button>
              </Box>
            </CardActions>
            
            <Collapse in={expandedSections.has('basic')}>
              <CardContent sx={{ pt: 1 }}>
                <Stack spacing={2}>
                  {renderEditableField('basicInfo.name', 'Nome', formData.basicInfo.name)}
                  
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      <strong>Tipo:</strong> {getClinicTypeLabel(formData.basicInfo.type)}
                    </Typography>
                    <Chip
                      label={getClinicTypeLabel(formData.basicInfo.type)}
                      color="primary"
                      size="small"
                    />
                  </Box>

                  {formData.basicInfo.cnpj && renderEditableField('basicInfo.cnpj', 'CNPJ', formData.basicInfo.cnpj)}
                  {formData.basicInfo.phone && renderEditableField('basicInfo.phone', 'Telefone', formData.basicInfo.phone)}
                  {formData.basicInfo.email && renderEditableField('basicInfo.email', 'Email', formData.basicInfo.email)}

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Typography variant="body2">
                      <strong>Status:</strong> {formData.basicInfo.isActive ? 'Ativa' : 'Inativa'}
                    </Typography>
                    <Chip
                      label={formData.basicInfo.isActive ? 'Ativa' : 'Inativa'}
                      color={formData.basicInfo.isActive ? 'success' : 'default'}
                      size="small"
                    />
                  </Box>
                </Stack>
              </CardContent>
            </Collapse>
          </Card>
        </Grid>

        {/* Endereço e Localização */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardActions sx={{ justifyContent: 'space-between', pb: 0 }}>
              <Typography variant="h6" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <LocationOn color="primary" />
                Endereço e Localização
              </Typography>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <IconButton 
                  size="small" 
                  onClick={() => toggleSection('address')}
                >
                  {expandedSections.has('address') ? <ExpandLess /> : <ExpandMore />}
                </IconButton>
                <Button 
                  size="small"
                  startIcon={<ArrowBack />}
                  onClick={() => goToStepHandler(1)}
                >
                  Editar
                </Button>
              </Box>
            </CardActions>
            
            <Collapse in={expandedSections.has('address')}>
              <CardContent sx={{ pt: 1 }}>
                <Stack spacing={2}>
                  {renderEditableField('address.cep', 'CEP', formData.address.cep)}
                  {renderEditableField('address.street', 'Endereço', formData.address.street)}
                  
                  <Grid container spacing={1}>
                    <Grid item xs={6}>
                      {renderEditableField('address.number', 'Número', formData.address.number)}
                    </Grid>
                    <Grid item xs={6}>
                      {formData.address.complement && renderEditableField('address.complement', 'Complemento', formData.address.complement)}
                    </Grid>
                  </Grid>

                  {renderEditableField('address.neighborhood', 'Bairro', formData.address.neighborhood)}
                  
                  <Grid container spacing={1}>
                    <Grid item xs={8}>
                      {renderEditableField('address.city', 'Cidade', formData.address.city)}
                    </Grid>
                    <Grid item xs={4}>
                      <Typography variant="body2">
                        <strong>Estado:</strong> {getStateLabel(formData.address.state)}
                      </Typography>
                    </Grid>
                  </Grid>

                  {/* Coordenadas */}
                  <Divider />
                  <Box sx={{ bgcolor: 'grey.50', p: 2, borderRadius: 1 }}>
                    <Typography variant="subtitle2" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <MapIcon fontSize="small" />
                      Coordenadas GPS
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Lat: {formData.location.latitude.toFixed(6)}, Lng: {formData.location.longitude.toFixed(6)}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      Fonte: {getLocationSourceLabel(formData.location.source)}
                      {formData.location.accuracy > 0 && ` • Precisão: ${formData.location.accuracy.toFixed(0)}m`}
                    </Typography>
                  </Box>
                </Stack>
              </CardContent>
            </Collapse>
          </Card>
        </Grid>

        {/* Imagens */}
        <Grid item xs={12}>
          <Card>
            <CardActions sx={{ justifyContent: 'space-between', pb: 0 }}>
              <Typography variant="h6" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Collections color="primary" />
                Imagens ({formData.images.length})
                {totalImagesSize > 0 && (
                  <Chip
                    label={formatFileSize(totalImagesSize)}
                    size="small"
                    variant="outlined"
                  />
                )}
              </Typography>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <IconButton 
                  size="small" 
                  onClick={() => toggleSection('images')}
                >
                  {expandedSections.has('images') ? <ExpandLess /> : <ExpandMore />}
                </IconButton>
                <Button 
                  size="small"
                  startIcon={<ArrowBack />}
                  onClick={() => goToStepHandler(2)}
                >
                  Editar
                </Button>
              </Box>
            </CardActions>
            
            <Collapse in={expandedSections.has('images')}>
              <CardContent sx={{ pt: 1 }}>
                {formData.images.length === 0 ? (
                  <Alert severity="info">
                    Nenhuma imagem adicionada. <Button onClick={() => goToStepHandler(2)}>Adicionar imagens</Button>
                  </Alert>
                ) : (
                  <>
                    {/* Imagem Principal */}
                    {featuredImage && (
                      <Box sx={{ mb: 3 }}>
                        <Typography variant="subtitle2" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Star color="warning" />
                          Imagem Principal
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                          <Avatar
                            src={featuredImage.preview || featuredImage.url}
                            sx={{ width: 80, height: 80, borderRadius: 2 }}
                            variant="rounded"
                          >
                            <Collections />
                          </Avatar>
                          <Box sx={{ flex: 1 }}>
                            <Typography variant="body2">
                              {featuredImage.file?.name || `Imagem ${featuredImage.displayOrder + 1}`}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {featuredImage.altText || 'Sem descrição'}
                            </Typography>
                            {featuredImage.file && (
                              <Typography variant="caption" color="text.secondary" display="block">
                                {formatFileSize(featuredImage.file.size)}
                              </Typography>
                            )}
                          </Box>
                        </Box>
                      </Box>
                    )}

                    {/* Grid de Todas as Imagens */}
                    <Typography variant="subtitle2" gutterBottom>
                      Todas as Imagens
                    </Typography>
                    <Grid container spacing={1}>
                      {formData.images.map((image, index) => (
                        <Grid item xs={6} sm={4} md={3} key={image.id}>
                          <Box sx={{ position: 'relative' }}>
                            {image.isFeatured && (
                              <Star
                                sx={{
                                  position: 'absolute',
                                  top: 4,
                                  right: 4,
                                  color: 'warning.main',
                                  bgcolor: 'white',
                                  borderRadius: '50%',
                                  fontSize: 16,
                                  zIndex: 1
                                }}
                              />
                            )}
                            <Avatar
                              src={image.preview || image.url}
                              sx={{ 
                                width: '100%', 
                                height: 80, 
                                borderRadius: 1,
                                cursor: 'pointer'
                              }}
                              variant="rounded"
                            >
                              <Collections />
                            </Avatar>
                          </Box>
                        </Grid>
                      ))}
                    </Grid>

                    {/* Estatísticas */}
                    <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                      <Grid container spacing={2}>
                        <Grid item xs={6} sm={3}>
                          <Typography variant="caption" color="text.secondary">
                            Total de Imagens
                          </Typography>
                          <Typography variant="h6">
                            {formData.images.length}
                          </Typography>
                        </Grid>
                        <Grid item xs={6} sm={3}>
                          <Typography variant="caption" color="text.secondary">
                            Tamanho Total
                          </Typography>
                          <Typography variant="h6">
                            {formatFileSize(totalImagesSize)}
                          </Typography>
                        </Grid>
                        <Grid item xs={6} sm={3}>
                          <Typography variant="caption" color="text.secondary">
                            Enviadas
                          </Typography>
                          <Typography variant="h6">
                            {formData.images.filter(img => img.uploadStatus === 'success').length}
                          </Typography>
                        </Grid>
                        <Grid item xs={6} sm={3}>
                          <Typography variant="caption" color="text.secondary">
                            Com Descrição
                          </Typography>
                          <Typography variant="h6">
                            {formData.images.filter(img => img.altText).length}
                          </Typography>
                        </Grid>
                      </Grid>
                    </Box>
                  </>
                )}
              </CardContent>
            </Collapse>
          </Card>
        </Grid>
      </Grid>

      {/* Ações Finais */}
      <Box sx={{ mt: 4 }}>
        {!allStepsValid && (
          <Alert severity="warning" sx={{ mb: 3 }}>
            <Typography variant="subtitle2" gutterBottom>
              Verificações necessárias:
            </Typography>
            <List dense>
              {!stepValidation.basicInfo && (
                <ListItem>
                  <ListItemText primary="Informações básicas incompletas" />
                  <ListItemSecondaryAction>
                    <Button size="small" onClick={() => goToStepHandler(0)}>
                      Corrigir
                    </Button>
                  </ListItemSecondaryAction>
                </ListItem>
              )}
              {!stepValidation.address && (
                <ListItem>
                  <ListItemText primary="Endereço e localização incompletos" />
                  <ListItemSecondaryAction>
                    <Button size="small" onClick={() => goToStepHandler(1)}>
                      Corrigir
                    </Button>
                  </ListItemSecondaryAction>
                </ListItem>
              )}
              {!stepValidation.images && (
                <ListItem>
                  <ListItemText primary="Imagens não configuradas adequadamente" />
                  <ListItemSecondaryAction>
                    <Button size="small" onClick={() => goToStepHandler(2)}>
                      Corrigir
                    </Button>
                  </ListItemSecondaryAction>
                </ListItem>
              )}
            </List>
          </Alert>
        )}

        {allStepsValid && (
          <Alert severity="success" sx={{ mb: 3 }}>
            ✅ Todos os dados estão corretos! O cadastro da clínica pode ser finalizado.
          </Alert>
        )}

        {/* Botão de Submit */}
        <Box sx={{ textAlign: 'center' }}>
          <Button
            variant="contained"
            size="large"
            startIcon={isSubmitting ? <LinearProgress /> : <Send />}
            onClick={handleFinalSubmit}
            disabled={!allStepsValid || isSubmitting}
            sx={{ minWidth: 200 }}
          >
            {isSubmitting ? 'Finalizando...' : 'Finalizar Cadastro'}
          </Button>
        </Box>

        {/* Progress durante submit */}
        {isSubmitting && (
          <Box sx={{ mt: 2 }}>
            <LinearProgress />
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block', textAlign: 'center' }}>
              Processando cadastro da clínica...
            </Typography>
          </Box>
        )}
      </Box>

      {/* Dialog de Detalhes de Validação */}
      <Dialog
        open={showValidationDetails}
        onClose={() => setShowValidationDetails(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Detalhes da Validação</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" gutterBottom>
            Os seguintes itens precisam ser corrigidos antes de finalizar:
          </Typography>
          
          <List>
            {!stepValidation.basicInfo && (
              <ListItem>
                <ListItemText 
                  primary="Informações Básicas"
                  secondary="Campos obrigatórios não preenchidos ou com formato inválido"
                />
                <ListItemSecondaryAction>
                  <Button onClick={() => { goToStepHandler(0); setShowValidationDetails(false) }}>
                    Ir para Step 1
                  </Button>
                </ListItemSecondaryAction>
              </ListItem>
            )}
            {!stepValidation.address && (
              <ListItem>
                <ListItemText 
                  primary="Endereço"
                  secondary="Endereço incompleto ou coordenadas não definidas"
                />
                <ListItemSecondaryAction>
                  <Button onClick={() => { goToStepHandler(1); setShowValidationDetails(false) }}>
                    Ir para Step 2
                  </Button>
                </ListItemSecondaryAction>
              </ListItem>
            )}
            {!stepValidation.images && (
              <ListItem>
                <ListItemText 
                  primary="Imagens"
                  secondary="Nenhuma imagem principal definida ou uploads com erro"
                />
                <ListItemSecondaryAction>
                  <Button onClick={() => { goToStepHandler(2); setShowValidationDetails(false) }}>
                    Ir para Step 3
                  </Button>
                </ListItemSecondaryAction>
              </ListItem>
            )}
          </List>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowValidationDetails(false)}>
            Entendido
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default Step5Review