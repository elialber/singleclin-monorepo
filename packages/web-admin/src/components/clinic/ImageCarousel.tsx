import React, { useState, useRef } from 'react'
import {
  Box,
  IconButton,
  Paper,
  Typography,
  Dialog,
  DialogContent,
  DialogTitle,
  DialogActions,
  Button,
  Stack,
  Fade,
  Tooltip
} from '@mui/material'
import {
  ChevronLeft as ChevronLeftIcon,
  ChevronRight as ChevronRightIcon,
  Fullscreen as FullscreenIcon,
  Close as CloseIcon,
  Image as ImageIcon
} from '@mui/icons-material'

export interface ClinicImage {
  url: string
  altText?: string
  title?: string
}

interface ImageCarouselProps {
  images: ClinicImage[]
  clinicName?: string
  height?: number | string
  width?: number | string
  borderRadius?: number
  showControls?: boolean
  autoPlay?: boolean
  autoPlayInterval?: number
  allowFullscreen?: boolean
  fallbackMessage?: string
}

export function ImageCarousel({
  images,
  clinicName,
  height = 200,
  width = 300,
  borderRadius = 8,
  showControls = true,
  autoPlay = false,
  autoPlayInterval = 3000,
  allowFullscreen = true,
  fallbackMessage = 'Nenhuma imagem disponível'
}: ImageCarouselProps) {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [fullscreenOpen, setFullscreenOpen] = useState(false)
  const [imageError, setImageError] = useState<boolean[]>([])
  const intervalRef = useRef<NodeJS.Timeout>()

  // Filter out broken images
  const validImages = images.filter((_, index) => !imageError[index])
  const hasImages = validImages.length > 0

  // Auto-play functionality
  React.useEffect(() => {
    if (autoPlay && hasImages && validImages.length > 1) {
      intervalRef.current = setInterval(() => {
        setCurrentIndex(prev => (prev + 1) % validImages.length)
      }, autoPlayInterval)

      return () => {
        if (intervalRef.current) {
          clearInterval(intervalRef.current)
        }
      }
    }
  }, [autoPlay, validImages.length, autoPlayInterval, hasImages])

  // Navigation handlers
  const goToPrevious = () => {
    if (hasImages) {
      setCurrentIndex(prev => (prev - 1 + validImages.length) % validImages.length)
    }
  }

  const goToNext = () => {
    if (hasImages) {
      setCurrentIndex(prev => (prev + 1) % validImages.length)
    }
  }

  const goToSlide = (index: number) => {
    if (hasImages && index >= 0 && index < validImages.length) {
      setCurrentIndex(index)
    }
  }

  // Error handling
  const handleImageError = (index: number) => {
    setImageError(prev => {
      const newErrors = [...prev]
      newErrors[index] = true
      return newErrors
    })
  }

  // Fullscreen handlers
  const openFullscreen = () => {
    if (hasImages && allowFullscreen) {
      setFullscreenOpen(true)
    }
  }

  const closeFullscreen = () => {
    setFullscreenOpen(false)
  }

  // If no valid images, show fallback
  if (!hasImages) {
    return (
      <Paper
        sx={{
          height,
          width,
          borderRadius: `${borderRadius}px`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          bgcolor: 'grey.100',
          border: '2px dashed',
          borderColor: 'grey.300'
        }}
      >
        <Stack alignItems="center" spacing={1}>
          <ImageIcon sx={{ fontSize: 40, color: 'grey.400' }} />
          <Typography variant="body2" color="text.secondary" align="center">
            {fallbackMessage}
          </Typography>
        </Stack>
      </Paper>
    )
  }

  const currentImage = validImages[currentIndex]

  return (
    <>
      {/* Main Carousel */}
      <Box
        sx={{
          position: 'relative',
          height,
          width,
          borderRadius: `${borderRadius}px`,
          overflow: 'hidden',
          cursor: allowFullscreen ? 'pointer' : 'default',
          '&:hover .carousel-controls': {
            opacity: 1
          }
        }}
        onClick={allowFullscreen ? openFullscreen : undefined}
      >
        {/* Main Image */}
        <Box
          component="img"
          src={currentImage.url}
          alt={currentImage.altText || `Imagem ${currentIndex + 1} da ${clinicName}`}
          onError={() => handleImageError(currentIndex)}
          sx={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            transition: 'opacity 0.3s ease-in-out'
          }}
        />

        {/* Controls Overlay */}
        {showControls && validImages.length > 1 && (
          <Fade in timeout={300}>
            <Box
              className="carousel-controls"
              sx={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                bgcolor: 'rgba(0,0,0,0.3)',
                opacity: 0,
                transition: 'opacity 0.3s ease-in-out',
                pointerEvents: 'none',
                '& > *': {
                  pointerEvents: 'all'
                }
              }}
            >
              {/* Previous Button */}
              <Tooltip title="Imagem anterior">
                <IconButton
                  onClick={(e) => {
                    e.stopPropagation()
                    goToPrevious()
                  }}
                  sx={{
                    ml: 1,
                    bgcolor: 'rgba(255,255,255,0.8)',
                    color: 'grey.800',
                    '&:hover': {
                      bgcolor: 'white'
                    }
                  }}
                >
                  <ChevronLeftIcon />
                </IconButton>
              </Tooltip>

              {/* Next Button */}
              <Tooltip title="Próxima imagem">
                <IconButton
                  onClick={(e) => {
                    e.stopPropagation()
                    goToNext()
                  }}
                  sx={{
                    mr: 1,
                    bgcolor: 'rgba(255,255,255,0.8)',
                    color: 'grey.800',
                    '&:hover': {
                      bgcolor: 'white'
                    }
                  }}
                >
                  <ChevronRightIcon />
                </IconButton>
              </Tooltip>
            </Box>
          </Fade>
        )}

        {/* Fullscreen Button */}
        {allowFullscreen && (
          <IconButton
            onClick={(e) => {
              e.stopPropagation()
              openFullscreen()
            }}
            sx={{
              position: 'absolute',
              top: 8,
              right: 8,
              bgcolor: 'rgba(0,0,0,0.6)',
              color: 'white',
              opacity: 0,
              transition: 'opacity 0.3s ease-in-out',
              '.carousel-container:hover &': {
                opacity: 1
              },
              '&:hover': {
                bgcolor: 'rgba(0,0,0,0.8)'
              }
            }}
            size="small"
          >
            <FullscreenIcon fontSize="small" />
          </IconButton>
        )}

        {/* Image Counter */}
        {validImages.length > 1 && (
          <Paper
            sx={{
              position: 'absolute',
              bottom: 8,
              left: '50%',
              transform: 'translateX(-50%)',
              px: 1,
              py: 0.5,
              bgcolor: 'rgba(0,0,0,0.7)',
              color: 'white'
            }}
          >
            <Typography variant="caption">
              {currentIndex + 1} / {validImages.length}
            </Typography>
          </Paper>
        )}

        {/* Dots Indicator */}
        {validImages.length > 1 && validImages.length <= 5 && (
          <Box
            sx={{
              position: 'absolute',
              bottom: 8,
              right: 8,
              display: 'flex',
              gap: 0.5
            }}
          >
            {validImages.map((_, index) => (
              <Box
                key={index}
                onClick={(e) => {
                  e.stopPropagation()
                  goToSlide(index)
                }}
                sx={{
                  width: 8,
                  height: 8,
                  borderRadius: '50%',
                  bgcolor: index === currentIndex ? 'white' : 'rgba(255,255,255,0.5)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease-in-out',
                  '&:hover': {
                    bgcolor: 'white',
                    transform: 'scale(1.2)'
                  }
                }}
              />
            ))}
          </Box>
        )}
      </Box>

      {/* Fullscreen Dialog */}
      {allowFullscreen && (
        <Dialog
          open={fullscreenOpen}
          onClose={closeFullscreen}
          maxWidth={false}
          fullWidth
          PaperProps={{
            sx: {
              bgcolor: 'rgba(0,0,0,0.9)',
              maxHeight: '95vh',
              maxWidth: '95vw',
              m: 2
            }
          }}
        >
          <DialogTitle
            sx={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              color: 'white',
              py: 1
            }}
          >
            <Typography variant="h6">
              {clinicName ? `${clinicName} - Imagem ${currentIndex + 1}` : `Imagem ${currentIndex + 1}`}
            </Typography>
            <IconButton onClick={closeFullscreen} sx={{ color: 'white' }}>
              <CloseIcon />
            </IconButton>
          </DialogTitle>

          <DialogContent sx={{ p: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Box
              sx={{
                position: 'relative',
                maxHeight: 'calc(95vh - 80px)',
                maxWidth: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              <Box
                component="img"
                src={currentImage.url}
                alt={currentImage.altText || `Imagem ${currentIndex + 1} da ${clinicName}`}
                sx={{
                  maxWidth: '100%',
                  maxHeight: '100%',
                  objectFit: 'contain'
                }}
              />

              {/* Fullscreen Navigation */}
              {validImages.length > 1 && (
                <>
                  <IconButton
                    onClick={goToPrevious}
                    sx={{
                      position: 'absolute',
                      left: 16,
                      bgcolor: 'rgba(255,255,255,0.1)',
                      color: 'white',
                      '&:hover': {
                        bgcolor: 'rgba(255,255,255,0.2)'
                      }
                    }}
                  >
                    <ChevronLeftIcon />
                  </IconButton>

                  <IconButton
                    onClick={goToNext}
                    sx={{
                      position: 'absolute',
                      right: 16,
                      bgcolor: 'rgba(255,255,255,0.1)',
                      color: 'white',
                      '&:hover': {
                        bgcolor: 'rgba(255,255,255,0.2)'
                      }
                    }}
                  >
                    <ChevronRightIcon />
                  </IconButton>
                </>
              )}
            </Box>
          </DialogContent>

          <DialogActions sx={{ justifyContent: 'center', color: 'white', py: 1 }}>
            {validImages.length > 1 && (
              <Stack direction="row" spacing={1} alignItems="center">
                {validImages.map((_, index) => (
                  <Box
                    key={index}
                    onClick={() => goToSlide(index)}
                    sx={{
                      width: 10,
                      height: 10,
                      borderRadius: '50%',
                      bgcolor: index === currentIndex ? 'white' : 'rgba(255,255,255,0.3)',
                      cursor: 'pointer',
                      transition: 'all 0.2s ease-in-out',
                      '&:hover': {
                        bgcolor: 'white',
                        transform: 'scale(1.3)'
                      }
                    }}
                  />
                ))}
              </Stack>
            )}
          </DialogActions>
        </Dialog>
      )}
    </>
  )
}

export default ImageCarousel