import { useState, useRef, useCallback } from 'react'
import {
  Box,
  Typography,
  IconButton,
  Avatar,
  Alert,
  CircularProgress,
  Paper,
  Stack,
  Fade,
} from '@mui/material'
import {
  CloudUpload as UploadIcon,
  Delete as DeleteIcon,
  Image as ImageIcon,
  PhotoCamera as CameraIcon,
} from '@mui/icons-material'
import { validateImageFile, ALLOWED_EXTENSIONS } from '@/types/clinic'

interface ImageUploadProps {
  currentImageUrl?: string
  onImageUpload: (file: File) => void
  onImageDelete?: () => void
  loading?: boolean
  error?: string
  disabled?: boolean
  label?: string
  helperText?: string
  maxSize?: string
  acceptedFormats?: string
  showPreview?: boolean
  variant?: 'standard' | 'avatar' | 'banner'
  size?: 'small' | 'medium' | 'large'
}

export default function ImageUpload({
  currentImageUrl,
  onImageUpload,
  onImageDelete,
  loading = false,
  error,
  disabled = false,
  label = 'Imagem da Clínica',
  helperText,
  maxSize = '5MB',
  acceptedFormats = 'JPEG, PNG, WebP',
  showPreview = true,
  variant = 'standard',
  size = 'medium'
}: ImageUploadProps) {
  const [dragActive, setDragActive] = useState(false)
  const [preview, setPreview] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Size configurations
  const sizeConfig = {
    small: { width: 80, height: 80, uploadArea: 120 },
    medium: { width: 120, height: 120, uploadArea: 160 },
    large: { width: 160, height: 160, uploadArea: 200 }
  }

  const currentSize = sizeConfig[size]
  const displayImageUrl = preview || currentImageUrl
  const hasImage = Boolean(displayImageUrl)

  const handleFileChange = useCallback((file: File | null) => {
    if (!file) return

    const validation = validateImageFile(file)
    if (!validation.isValid) {
      // Error será tratado pelo componente pai
      return
    }

    // Create preview
    const reader = new FileReader()
    reader.onloadend = () => {
      setPreview(reader.result as string)
    }
    reader.readAsDataURL(file)

    // Call parent handler
    onImageUpload(file)
  }, [onImageUpload])

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    handleFileChange(file || null)
  }

  const handleDrop = useCallback((event: React.DragEvent) => {
    event.preventDefault()
    setDragActive(false)
    
    if (disabled || loading) return

    const file = event.dataTransfer.files[0]
    handleFileChange(file)
  }, [disabled, loading, handleFileChange])

  const handleDragOver = useCallback((event: React.DragEvent) => {
    event.preventDefault()
    if (!disabled && !loading) {
      setDragActive(true)
    }
  }, [disabled, loading])

  const handleDragLeave = useCallback((event: React.DragEvent) => {
    event.preventDefault()
    setDragActive(false)
  }, [])

  const handleDelete = () => {
    setPreview(null)
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
    onImageDelete?.()
  }

  const handleUploadClick = () => {
    if (!disabled && !loading) {
      fileInputRef.current?.click()
    }
  }

  if (variant === 'avatar') {
    return (
      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
        <Box sx={{ position: 'relative' }}>
          <Avatar
            src={displayImageUrl}
            sx={{ 
              width: currentSize.width, 
              height: currentSize.height,
              bgcolor: 'grey.100',
              border: dragActive ? '2px dashed primary.main' : '2px solid transparent',
              transition: 'all 0.2s ease-in-out',
              cursor: disabled || loading ? 'default' : 'pointer'
            }}
            onClick={handleUploadClick}
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
          >
            {!hasImage && <CameraIcon sx={{ fontSize: 32, color: 'grey.400' }} />}
          </Avatar>

          {loading && (
            <Box
              sx={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                bgcolor: 'rgba(255, 255, 255, 0.8)',
                borderRadius: '50%',
              }}
            >
              <CircularProgress size={24} />
            </Box>
          )}

          {hasImage && !loading && (
            <IconButton
              onClick={handleDelete}
              disabled={disabled}
              size="small"
              sx={{
                position: 'absolute',
                top: -8,
                right: -8,
                bgcolor: 'error.main',
                color: 'white',
                '&:hover': {
                  bgcolor: 'error.dark',
                },
              }}
            >
              <DeleteIcon fontSize="small" />
            </IconButton>
          )}
        </Box>

        <input
          ref={fileInputRef}
          type="file"
          accept={ALLOWED_EXTENSIONS.map(ext => `.${ext}`).join(',')}
          onChange={handleInputChange}
          style={{ display: 'none' }}
          disabled={disabled}
        />

        {error && (
          <Alert severity="error" sx={{ width: '100%', maxWidth: 300 }}>
            {error}
          </Alert>
        )}
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant="subtitle2" fontWeight={600} gutterBottom>
        {label}
      </Typography>

      <Paper
        variant="outlined"
        sx={{
          position: 'relative',
          borderRadius: 2,
          overflow: 'hidden',
          transition: 'all 0.2s ease-in-out',
          border: dragActive ? '2px dashed primary.main' : undefined,
          bgcolor: dragActive ? 'primary.50' : 'grey.50',
          cursor: disabled || loading ? 'default' : 'pointer',
          opacity: disabled ? 0.6 : 1,
        }}
        onClick={handleUploadClick}
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
      >
        {hasImage && showPreview ? (
          <Box sx={{ position: 'relative', width: '100%', minHeight: currentSize.uploadArea }}>
            <img
              src={displayImageUrl}
              alt="Preview"
              style={{
                width: '100%',
                height: currentSize.uploadArea,
                objectFit: 'cover',
                display: 'block',
              }}
            />
            
            {!loading && (
              <Fade in={true}>
                <Box
                  sx={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    bgcolor: 'rgba(0, 0, 0, 0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    opacity: 0,
                    transition: 'opacity 0.2s ease-in-out',
                    '&:hover': {
                      opacity: 1,
                    },
                  }}
                >
                  <Stack direction="row" spacing={1}>
                    <IconButton
                      onClick={(e) => {
                        e.stopPropagation()
                        handleUploadClick()
                      }}
                      disabled={disabled}
                      sx={{ color: 'white' }}
                    >
                      <UploadIcon />
                    </IconButton>
                    <IconButton
                      onClick={(e) => {
                        e.stopPropagation()
                        handleDelete()
                      }}
                      disabled={disabled}
                      sx={{ color: 'white' }}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </Stack>
                </Box>
              </Fade>
            )}
          </Box>
        ) : (
          <Box
            sx={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              py: 4,
              px: 2,
              minHeight: currentSize.uploadArea,
              textAlign: 'center',
            }}
          >
            <ImageIcon
              sx={{
                fontSize: 48,
                color: dragActive ? 'primary.main' : 'grey.400',
                mb: 2,
              }}
            />
            <Typography
              variant="body1"
              fontWeight={500}
              color={dragActive ? 'primary.main' : 'text.primary'}
              gutterBottom
            >
              {dragActive ? 'Solte a imagem aqui' : 'Clique ou arraste uma imagem'}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {acceptedFormats} • Máx {maxSize}
            </Typography>
          </Box>
        )}

        {loading && (
          <Box
            sx={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              bgcolor: 'rgba(255, 255, 255, 0.8)',
            }}
          >
            <CircularProgress />
          </Box>
        )}
      </Paper>

      <input
        ref={fileInputRef}
        type="file"
        accept={ALLOWED_EXTENSIONS.map(ext => `.${ext}`).join(',')}
        onChange={handleInputChange}
        style={{ display: 'none' }}
        disabled={disabled}
      />

      {(helperText || error) && (
        <Box sx={{ mt: 1 }}>
          {error ? (
            <Alert severity="error" sx={{ mt: 1 }}>
              {error}
            </Alert>
          ) : (
            helperText && (
              <Typography variant="caption" color="text.secondary">
                {helperText}
              </Typography>
            )
          )}
        </Box>
      )}
    </Box>
  )
}