import React, { useEffect, useState, useCallback } from 'react'
import {
  Box,
  Grid,
  Typography,
  Alert,
  Chip,
  CircularProgress,
  Paper,
  Button,
  Card,
  CardContent,
  CardActions,
  IconButton,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Badge,
  LinearProgress,
  Tooltip,
  Switch,
  FormControlLabel,
  Menu,
  MenuItem,
  Fab
} from '@mui/material'
import {
  CheckCircle,
  Warning,
  CloudUpload,
  Delete,
  Star,
  StarBorder,
  Edit,
  Visibility,
  DragHandle,
  Cancel,
  Refresh,
  PhotoCamera,
  Collections,
  Help,
  MoreVert,
  SelectAll,
  Deselect
} from '@mui/icons-material'
import { useClinicStepper } from '../hooks/useClinicStepper'
import { useImageUpload, ProcessedImage } from '../hooks/useImageUpload'
import { StepComponentProps, ImageData } from '../../../../types/stepper'
import { formatFileSize } from '../../../../utils/imageValidation'

// Função para converter ProcessedImage para ImageData
function mapProcessedImageToImageData(processedImage: ProcessedImage): ImageData {
  return {
    id: processedImage.id,
    file: processedImage.file,
    url: processedImage.url || processedImage.preview,
    altText: processedImage.altText,
    displayOrder: processedImage.displayOrder,
    isFeatured: processedImage.isFeatured,
    uploadStatus: processedImage.uploadProgress?.status === 'success' ? 'success' :
                 processedImage.uploadProgress?.status === 'error' ? 'error' :
                 processedImage.uploadProgress?.status === 'pending' ? 'pending' : 'uploading',
    uploadProgress: processedImage.uploadProgress?.progress || 0,
    error: undefined // ProcessedImage não tem error field
  }
}

// Função para converter ImageData para ProcessedImage
function mapImageDataToProcessedImage(imageData: ImageData): ProcessedImage {
  return {
    id: imageData.id,
    file: imageData.file,
    preview: imageData.url || '',
    dimensions: {
      width: 800, // Default values since ImageData doesn't have dimensions
      height: 600
    },
    sizeBytes: imageData.file?.size || 0,
    type: imageData.file?.type || 'image/jpeg',
    isFeatured: imageData.isFeatured,
    altText: imageData.altText || '',
    displayOrder: imageData.displayOrder,
    url: imageData.url,
    isExisting: !!imageData.url && !imageData.file,
    uploadProgress: {
      id: imageData.id,
      file: imageData.file || new File([], 'dummy'),
      progress: imageData.uploadProgress,
      status: imageData.uploadStatus === 'success' ? 'success' :
             imageData.uploadStatus === 'error' ? 'error' :
             imageData.uploadStatus === 'uploading' ? 'pending' : 'pending'
    }
  }
}

/**
 * Step 4: Upload Múltiplo de Imagens
 * 
 * Interface completa para upload, organização e gerenciamento de imagens
 * Suporta edição de imagens existentes em modo de edição
 */
function Step4ImageUpload({ onNext, onPrev, isValid, isDirty }: StepComponentProps) {
  const { formData, updateFormData, validateStep } = useClinicStepper()
  const [selectedImages, setSelectedImages] = useState<Set<string>>(new Set())
  const [previewImage, setPreviewImage] = useState<ProcessedImage | null>(null)
  const [editingAltText, setEditingAltText] = useState<ProcessedImage | null>(null)
  const [batchMenuAnchor, setBatchMenuAnchor] = useState<HTMLElement | null>(null)
  const [autoUpload, setAutoUpload] = useState(true)

  // Hook de upload de imagens
  const [uploadState, uploadActions] = useImageUpload({
    config: {
      maxFiles: 10, // Permite até 10 imagens (todas serão enviadas ao backend)
      autoUpload,
      enableReordering: true
    },
    initialImages: (formData.images || []).map(mapImageDataToProcessedImage),
    onImagesChange: (images) => {
      const imageData = images.map(mapProcessedImageToImageData)
      updateFormData('images', imageData)
    },
    onError: (errors) => {
      console.error('Image upload errors:', errors)
    }
  })

  const { 
    images, 
    isProcessing, 
    isUploading, 
    uploadProgress, 
    errors, 
    stats 
  } = uploadState

  const {
    addFiles,
    removeImage,
    removeAllImages,
    setFeaturedImage,
    updateAltText,
    startUpload,
    cancelUpload,
    retryUpload,
    validateImages
  } = uploadActions

  // Estado local da validação (step é opcional, inicia como válido)
  const [formValid, setFormValid] = useState(true)

  // Validar step quando imagens mudarem
  useEffect(() => {
    // Step é opcional - sempre válido se não houver erros
    // Se tiver imagens, deve ter uma principal
    const isStepValid = errors.length === 0 && 
                       (images.length === 0 || images.some(img => img.isFeatured))
    
    setFormValid(isStepValid)
  }, [images, errors])

  // As mudanças nas imagens são sincronizadas automaticamente via onImagesChange callback

  // Atualizar validação global do stepper quando formValid muda
  useEffect(() => {
    validateStep(2)
  }, [formValid]) // Remove validateStep das dependências para evitar loop infinito

  // Handlers para seleção
  const handleImageSelect = (id: string, selected: boolean) => {
    setSelectedImages(prev => {
      const newSet = new Set(prev)
      if (selected) {
        newSet.add(id)
      } else {
        newSet.delete(id)
      }
      return newSet
    })
  }

  const handleSelectAll = () => {
    if (selectedImages.size === images.length) {
      setSelectedImages(new Set())
    } else {
      setSelectedImages(new Set(images.map(img => img.id)))
    }
  }

  const handleBatchDelete = () => {
    selectedImages.forEach(id => removeImage(id))
    setSelectedImages(new Set())
    setBatchMenuAnchor(null)
  }

  // Handler para arquivos
  const handleFileInput = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || [])
    if (files.length > 0) {
      addFiles(files)
    }
    event.target.value = '' // Reset input
  }

  // Preview modal
  const handlePreviewClose = () => {
    setPreviewImage(null)
  }

  // Alt text editing
  const handleAltTextSave = () => {
    if (editingAltText) {
      setEditingAltText(null)
    }
  }

  const handleAltTextChange = (altText: string) => {
    if (editingAltText) {
      updateAltText(editingAltText.id, altText)
      setEditingAltText({ ...editingAltText, altText })
    }
  }

  // Drag and drop handlers
  const onDragStart = (e: React.DragEvent, index: number) => {
    e.dataTransfer.setData('text/plain', index.toString())
  }

  const onDragOver = (e: React.DragEvent) => {
    e.preventDefault()
  }

  const onDrop = (e: React.DragEvent, dropIndex: number) => {
    e.preventDefault()
    const dragIndex = parseInt(e.dataTransfer.getData('text/plain'))
    
    if (dragIndex !== dropIndex) {
      // Implementar reordenação via uploadActions.moveImage
      console.log(`Move image from ${dragIndex} to ${dropIndex}`)
    }
  }


  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          📸 Upload de Imagens
          {formValid && <CheckCircle color="success" />}
          {!formValid && images.length === 0 && <Warning color="warning" />}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Adicione até 10 imagens da clínica (opcional). A primeira imagem será definida como principal automaticamente.
        </Typography>
      </Box>

      {/* Upload Stats */}
      {stats.totalFiles > 0 && (
        <Card sx={{ mb: 3, bgcolor: 'grey.50' }}>
          <CardContent sx={{ py: 2 }}>
            <Grid container spacing={2} alignItems="center">
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  {stats.totalFiles} imagem(ns) • {formatFileSize(stats.totalSize)}
                </Typography>
                {stats.uploadedCount > 0 && (
                  <Typography variant="body2" color="success.main">
                    {stats.uploadedCount} enviada(s) com sucesso
                  </Typography>
                )}
                {stats.failedCount > 0 && (
                  <Typography variant="body2" color="error.main">
                    {stats.failedCount} com falha
                  </Typography>
                )}
              </Grid>
              <Grid item xs={12} sm={6}>
                {isUploading && (
                  <Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="body2">Enviando...</Typography>
                      <Typography variant="body2">{stats.overallProgress}%</Typography>
                    </Box>
                    <LinearProgress variant="determinate" value={stats.overallProgress} />
                  </Box>
                )}
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      )}

      {/* Upload Zone */}
      <Card sx={{ mb: 3, border: '2px dashed', borderColor: 'primary.main', bgcolor: 'primary.50' }}>
        <CardContent sx={{ textAlign: 'center', py: 4 }}>
          {isProcessing ? (
            <Box>
              <CircularProgress sx={{ mb: 2 }} />
              <Typography variant="body1">Processando imagens...</Typography>
            </Box>
          ) : (
            <Box>
              <CloudUpload sx={{ fontSize: 48, color: 'primary.main', mb: 2 }} />
              <Typography variant="h6" gutterBottom>
                Arraste imagens aqui ou clique para selecionar
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                Formatos: JPEG, PNG, WebP • Máximo: 5MB por imagem
              </Typography>
              
              <Box sx={{ display: 'flex', gap: 2, justifyContent: 'center', flexWrap: 'wrap' }}>
                <Button
                  variant="contained"
                  startIcon={<PhotoCamera />}
                  component="label"
                >
                  Selecionar Imagens
                  <input
                    type="file"
                    hidden
                    multiple
                    accept="image/jpeg,image/jpg,image/png,image/webp"
                    onChange={handleFileInput}
                  />
                </Button>
                
                <FormControlLabel
                  control={
                    <Switch
                      checked={autoUpload}
                      onChange={(e) => setAutoUpload(e.target.checked)}
                    />
                  }
                  label="Upload automático"
                />
              </Box>
            </Box>
          )}
        </CardContent>
      </Card>

      {/* Batch Operations */}
      {images.length > 0 && (
        <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
            <Button
              size="small"
              startIcon={selectedImages.size === images.length ? <Deselect /> : <SelectAll />}
              onClick={handleSelectAll}
            >
              {selectedImages.size === images.length ? 'Desmarcar todas' : 'Selecionar todas'}
            </Button>
            
            {selectedImages.size > 0 && (
              <>
                <Chip 
                  label={`${selectedImages.size} selecionada(s)`} 
                  size="small" 
                  color="primary" 
                />
                <IconButton
                  size="small"
                  onClick={(e) => setBatchMenuAnchor(e.currentTarget)}
                >
                  <MoreVert />
                </IconButton>
              </>
            )}
          </Box>
          
          <Box sx={{ display: 'flex', gap: 1 }}>
            {!autoUpload && stats.totalFiles > 0 && (
              <Button
                variant="outlined"
                size="small"
                startIcon={<CloudUpload />}
                onClick={startUpload}
                disabled={isUploading}
              >
                Enviar Todas
              </Button>
            )}
            
            {stats.failedCount > 0 && (
              <Button
                variant="outlined"
                size="small"
                startIcon={<Refresh />}
                onClick={() => retryUpload()}
              >
                Tentar Novamente
              </Button>
            )}
            
            {images.length > 0 && (
              <Button
                variant="outlined"
                size="small"
                color="error"
                startIcon={<Delete />}
                onClick={removeAllImages}
              >
                Remover Todas
              </Button>
            )}
          </Box>
        </Box>
      )}

      {/* Images Grid */}
      {images.length > 0 && (
        <Grid container spacing={2} sx={{ mb: 3 }}>
          {images.map((image, index) => {
            const uploadProgressItem = uploadProgress.find(p => p.file === image.file)
            const isSelected = selectedImages.has(image.id)
            
            return (
              <Grid item xs={12} sm={6} md={4} key={image.id}>
                <Card 
                  sx={{ 
                    position: 'relative',
                    border: isSelected ? '2px solid' : '1px solid',
                    borderColor: isSelected ? 'primary.main' : 'divider',
                    cursor: 'pointer'
                  }}
                  draggable
                  onDragStart={(e) => onDragStart(e, index)}
                  onDragOver={onDragOver}
                  onDrop={(e) => onDrop(e, index)}
                  onClick={() => handleImageSelect(image.id, !isSelected)}
                >
                  {/* Featured Badge */}
                  {image.isFeatured && (
                    <Chip
                      icon={<Star />}
                      label="Principal"
                      size="small"
                      color="warning"
                      sx={{ position: 'absolute', top: 8, left: 8, zIndex: 1 }}
                    />
                  )}
                  
                  {/* Selection Checkbox */}
                  <Box
                    sx={{
                      position: 'absolute',
                      top: 8,
                      right: 8,
                      zIndex: 1,
                      width: 24,
                      height: 24,
                      borderRadius: '50%',
                      bgcolor: isSelected ? 'primary.main' : 'rgba(255,255,255,0.8)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      border: '2px solid',
                      borderColor: isSelected ? 'primary.main' : 'grey.400'
                    }}
                  >
                    {isSelected && <CheckCircle sx={{ color: 'white', fontSize: 16 }} />}
                  </Box>

                  {/* Image */}
                  <Box
                    sx={{
                      height: 200,
                      backgroundImage: `url(${image.preview})`,
                      backgroundSize: 'cover',
                      backgroundPosition: 'center',
                      position: 'relative'
                    }}
                  >
                    {/* Upload Progress */}
                    {uploadProgressItem && uploadProgressItem.status === 'uploading' && (
                      <Box
                        sx={{
                          position: 'absolute',
                          bottom: 0,
                          left: 0,
                          right: 0,
                          bgcolor: 'rgba(0,0,0,0.7)',
                          color: 'white',
                          p: 1
                        }}
                      >
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                          <Typography variant="caption">Enviando...</Typography>
                          <Typography variant="caption">{uploadProgressItem.progress}%</Typography>
                        </Box>
                        <LinearProgress 
                          variant="determinate" 
                          value={uploadProgressItem.progress}
                          sx={{ bgcolor: 'rgba(255,255,255,0.3)' }}
                        />
                      </Box>
                    )}
                    
                    {/* Error Overlay */}
                    {uploadProgressItem && uploadProgressItem.status === 'error' && (
                      <Box
                        sx={{
                          position: 'absolute',
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          bgcolor: 'rgba(244,67,54,0.8)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: 'white'
                        }}
                      >
                        <Box sx={{ textAlign: 'center' }}>
                          <Warning sx={{ fontSize: 32, mb: 1 }} />
                          <Typography variant="caption">Erro no upload</Typography>
                        </Box>
                      </Box>
                    )}
                  </Box>

                  {/* Image Info */}
                  <CardContent sx={{ pb: 1 }}>
                    <Typography variant="body2" noWrap>
                      {image.file?.name || 'Imagem existente'}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {image.dimensions.width}×{image.dimensions.height} • {formatFileSize(image.sizeBytes)}
                    </Typography>
                  </CardContent>

                  {/* Actions */}
                  <CardActions sx={{ pt: 0 }}>
                    <Tooltip title="Visualizar">
                      <IconButton 
                        size="small" 
                        onClick={(e) => {
                          e.stopPropagation()
                          setPreviewImage(image)
                        }}
                      >
                        <Visibility />
                      </IconButton>
                    </Tooltip>
                    
                    <Tooltip title={image.isFeatured ? "Imagem principal" : "Definir como principal"}>
                      <IconButton 
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation()
                          setFeaturedImage(image.id)
                        }}
                      >
                        {image.isFeatured ? <Star color="warning" /> : <StarBorder />}
                      </IconButton>
                    </Tooltip>
                    
                    <Tooltip title="Editar descrição">
                      <IconButton 
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation()
                          setEditingAltText(image)
                        }}
                      >
                        <Edit />
                      </IconButton>
                    </Tooltip>
                    
                    <Tooltip title="Remover">
                      <IconButton 
                        size="small" 
                        color="error"
                        onClick={(e) => {
                          e.stopPropagation()
                          removeImage(image.id)
                        }}
                      >
                        <Delete />
                      </IconButton>
                    </Tooltip>
                    
                    {uploadProgressItem && uploadProgressItem.status === 'error' && (
                      <Tooltip title="Tentar novamente">
                        <IconButton 
                          size="small" 
                          color="primary"
                          onClick={(e) => {
                            e.stopPropagation()
                            retryUpload(image.id)
                          }}
                        >
                          <Refresh />
                        </IconButton>
                      </Tooltip>
                    )}
                  </CardActions>
                </Card>
              </Grid>
            )
          })}
        </Grid>
      )}

      {/* Empty State */}
      {images.length === 0 && !isProcessing && (
        <Paper sx={{ p: 6, textAlign: 'center', bgcolor: 'grey.50' }}>
          <Collections sx={{ fontSize: 64, color: 'grey.400', mb: 2 }} />
          <Typography variant="h6" color="text.secondary" gutterBottom>
            Nenhuma imagem adicionada
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Adicione imagens da clínica para continuar
          </Typography>
        </Paper>
      )}

      {/* Errors */}
      {errors.length > 0 && (
        <Alert severity="error" sx={{ mb: 3 }}>
          <Typography variant="subtitle2" gutterBottom>
            Problemas encontrados:
          </Typography>
          <ul style={{ margin: 0, paddingLeft: 20 }}>
            {errors.map((error, index) => (
              <li key={index}>{error}</li>
            ))}
          </ul>
        </Alert>
      )}

      {/* Status */}
      <Box sx={{ mt: 4 }}>
        {images.length > 0 && formValid && (
          <Alert severity="success" sx={{ mb: 2 }}>
            ✅ {images.length === 1 ? 'Imagem configurada' : `${images.length} imagens configuradas`}! Você pode prosseguir para a revisão final.
            {images.length > 1 && (
              <span> (Apenas a imagem principal será salva)</span>
            )}
          </Alert>
        )}
        
        {images.length === 0 && (
          <Alert severity="info" sx={{ mb: 2 }}>
            ℹ️ Upload de imagens é opcional. Você pode prosseguir sem adicionar imagens ou adicionar algumas para enriquecer o perfil da clínica.
          </Alert>
        )}

        {/* Aviso sobre limitação atual */}
        {images.length > 1 && (
          <Alert severity="warning" sx={{ mb: 2 }}>
            ⚠️ <strong>Atenção:</strong> Você selecionou {images.length} imagens, mas o sistema atualmente salva apenas uma imagem por clínica. 
            Apenas a imagem marcada como <strong>principal</strong> (ou a primeira) será enviada ao servidor.
          </Alert>
        )}
        
        {images.length <= 1 && (
          <Alert severity="info" sx={{ mb: 2 }}>
            💡 <strong>Dica:</strong> Você pode adicionar até 10 imagens, mas apenas uma será salva no servidor no momento. 
            Marque a imagem desejada como <strong>principal</strong> usando o ícone da estrela.
          </Alert>
        )}

        {/* Indicadores de status */}
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Chip
            label="Imagens"
            color={images.length > 0 ? 'success' : 'default'}
            size="small"
            icon={images.length > 0 ? <CheckCircle /> : undefined}
          />
          <Chip
            label="Principal"
            color={images.some(img => img.isFeatured) ? 'success' : 'default'}
            size="small"
            icon={images.some(img => img.isFeatured) ? <CheckCircle /> : undefined}
          />
          {stats.uploadedCount > 0 && (
            <Chip
              label={`${stats.uploadedCount} Enviada(s)`}
              color="success"
              size="small"
              icon={<CheckCircle />}
            />
          )}
        </Box>
      </Box>

      {/* Batch Actions Menu */}
      <Menu
        anchorEl={batchMenuAnchor}
        open={Boolean(batchMenuAnchor)}
        onClose={() => setBatchMenuAnchor(null)}
      >
        <MenuItem onClick={handleBatchDelete}>
          <Delete sx={{ mr: 1 }} /> Remover selecionadas
        </MenuItem>
      </Menu>

      {/* Preview Dialog */}
      <Dialog
        open={Boolean(previewImage)}
        onClose={handlePreviewClose}
        maxWidth="md"
        fullWidth
      >
        {previewImage && (
          <>
            <DialogTitle>
              {previewImage.file?.name || 'Imagem existente'}
              {previewImage.isFeatured && (
                <Chip
                  icon={<Star />}
                  label="Principal"
                  size="small"
                  color="warning"
                  sx={{ ml: 1 }}
                />
              )}
            </DialogTitle>
            <DialogContent>
              <Box
                component="img"
                src={previewImage.preview}
                alt={previewImage.altText || previewImage.file?.name || 'Imagem existente'}
                sx={{ width: '100%', height: 'auto', maxHeight: '70vh', objectFit: 'contain' }}
              />
              <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                Dimensões: {previewImage.dimensions.width}×{previewImage.dimensions.height}px • 
                Tamanho: {formatFileSize(previewImage.sizeBytes)}
              </Typography>
            </DialogContent>
            <DialogActions>
              <Button onClick={handlePreviewClose}>Fechar</Button>
              <Button
                onClick={() => setFeaturedImage(previewImage.id)}
                startIcon={<Star />}
                disabled={previewImage.isFeatured}
              >
                {previewImage.isFeatured ? 'É Principal' : 'Definir como Principal'}
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Alt Text Edit Dialog */}
      <Dialog
        open={Boolean(editingAltText)}
        onClose={() => setEditingAltText(null)}
        maxWidth="sm"
        fullWidth
      >
        {editingAltText && (
          <>
            <DialogTitle>
              Descrição da Imagem
            </DialogTitle>
            <DialogContent>
              <Box
                component="img"
                src={editingAltText.preview}
                alt={editingAltText.altText || editingAltText.file?.name || 'Imagem existente'}
                sx={{ width: '100%', height: 120, objectFit: 'cover', borderRadius: 1, mb: 2 }}
              />
              <TextField
                fullWidth
                label="Descrição alternativa"
                multiline
                rows={3}
                value={editingAltText.altText}
                onChange={(e) => handleAltTextChange(e.target.value)}
                placeholder="Descreva o conteúdo da imagem para acessibilidade..."
                helperText="Descrição usada para leitores de tela e SEO"
              />
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setEditingAltText(null)}>Cancelar</Button>
              <Button onClick={handleAltTextSave} variant="contained">Salvar</Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </Box>
  )
}

export default Step4ImageUpload