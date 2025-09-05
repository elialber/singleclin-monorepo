import React from 'react'
import {
  Box,
  useTheme,
  useMediaQuery,
  Drawer,
  IconButton,
  AppBar,
  Toolbar,
  Typography,
  LinearProgress
} from '@mui/material'
import {
  Menu as MenuIcon,
  Close as CloseIcon
} from '@mui/icons-material'
import { StepperIndicator } from './StepperIndicator'
import { DraftIndicator } from './DraftIndicator'

export interface ResponsiveStepperLayoutProps {
  children: React.ReactNode
  
  // Stepper props
  stepInfos: Array<{
    label: string
    description: string
    isCompleted: boolean
    hasErrors: boolean
  }>
  currentStep: number
  progress: {
    current: number
    total: number
    percentage: number
  }
  
  // Header props
  title: string
  subtitle?: string
  
  // Draft props (optional)
  draftProps?: {
    hasUnsavedChanges: boolean
    isAutoSaving: boolean
    lastSavedAt: Date | null
    currentDraftId: string | null
    draftsCount: number
    onSaveManually: () => Promise<void>
    onOpenDraftsModal: () => void
    enableAutoSave?: boolean
  }
}

export function ResponsiveStepperLayout({
  children,
  stepInfos,
  currentStep,
  progress,
  title,
  subtitle,
  draftProps
}: ResponsiveStepperLayoutProps) {
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('md'))
  const isTablet = useMediaQuery(theme.breakpoints.down('lg'))
  
  const [mobileDrawerOpen, setMobileDrawerOpen] = React.useState(false)

  const handleDrawerToggle = () => {
    setMobileDrawerOpen(!mobileDrawerOpen)
  }

  // Conteúdo do sidebar (stepper indicator)
  const sidebarContent = (
    <Box sx={{ p: 2, width: 280 }}>
      <Typography variant="h6" gutterBottom>
        Progresso
      </Typography>
      <StepperIndicator
        steps={stepInfos}
        currentStep={currentStep}
        orientation="vertical"
      />
    </Box>
  )

  // Layout Desktop (sidebar fixa)
  if (!isMobile) {
    return (
      <Box sx={{ display: 'flex', minHeight: '100vh' }}>
        {/* Sidebar Desktop */}
        <Box
          sx={{
            width: 280,
            flexShrink: 0,
            bgcolor: 'grey.50',
            borderRight: 1,
            borderColor: 'divider'
          }}
        >
          <Box sx={{ position: 'sticky', top: 0 }}>
            {sidebarContent}
          </Box>
        </Box>

        {/* Main Content */}
        <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          {/* Header */}
          <Box
            sx={{
              bgcolor: 'primary.main',
              color: 'primary.contrastText',
              py: 3,
              px: 3
            }}
          >
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <Box sx={{ flex: 1 }}>
                <Typography variant="h4" component="h1" gutterBottom>
                  {title}
                </Typography>
                {subtitle && (
                  <Typography variant="body1" sx={{ opacity: 0.9 }}>
                    {subtitle}
                  </Typography>
                )}
              </Box>
              
              {/* Draft indicator no header desktop */}
              {draftProps && (
                <DraftIndicator {...draftProps} />
              )}
            </Box>
            
            {/* Progress bar */}
            <Box sx={{ mt: 2 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography variant="body2">
                  Step {progress.current} de {progress.total}
                </Typography>
                <Typography variant="body2">
                  {progress.percentage}% completo
                </Typography>
              </Box>
              <LinearProgress
                variant="determinate"
                value={progress.percentage}
                sx={{
                  height: 8,
                  borderRadius: 4,
                  bgcolor: 'rgba(255,255,255,0.2)',
                  '& .MuiLinearProgress-bar': {
                    borderRadius: 4
                  }
                }}
              />
            </Box>
          </Box>

          {/* Content Area */}
          <Box sx={{ flex: 1, p: 3, bgcolor: 'grey.50' }}>
            {children}
          </Box>
        </Box>
      </Box>
    )
  }

  // Layout Mobile/Tablet (com drawer)
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      {/* AppBar Mobile */}
      <AppBar position="sticky">
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="abrir menu"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2 }}
          >
            <MenuIcon />
          </IconButton>
          
          <Box sx={{ flex: 1 }}>
            <Typography variant="h6" noWrap component="div">
              {title}
            </Typography>
            <Typography variant="caption" sx={{ opacity: 0.8 }}>
              Step {progress.current} de {progress.total} • {progress.percentage}%
            </Typography>
          </Box>

          {/* Draft indicator mobile */}
          {draftProps && (
            <DraftIndicator {...draftProps} />
          )}
        </Toolbar>
        
        {/* Progress bar mobile */}
        <LinearProgress
          variant="determinate"
          value={progress.percentage}
          sx={{ height: 4 }}
        />
      </AppBar>

      {/* Mobile Drawer */}
      <Drawer
        variant="temporary"
        anchor="left"
        open={mobileDrawerOpen}
        onClose={handleDrawerToggle}
        ModalProps={{ keepMounted: true }}
        sx={{
          display: { xs: 'block', md: 'none' },
          '& .MuiDrawer-paper': { 
            boxSizing: 'border-box', 
            width: 280 
          }
        }}
      >
        <Box sx={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'space-between',
          p: 2,
          borderBottom: 1,
          borderColor: 'divider'
        }}>
          <Typography variant="h6">
            Navegação
          </Typography>
          <IconButton onClick={handleDrawerToggle}>
            <CloseIcon />
          </IconButton>
        </Box>
        {sidebarContent}
      </Drawer>

      {/* Content Area Mobile */}
      <Box sx={{ 
        flex: 1, 
        p: { xs: 2, sm: 3 }, 
        bgcolor: 'grey.50',
        pt: { xs: 2, sm: 3 } 
      }}>
        {/* Stepper horizontal compacto para tablet */}
        {isTablet && !isMobile && (
          <Box sx={{ mb: 3, bgcolor: 'white', p: 2, borderRadius: 1, boxShadow: 1 }}>
            <StepperIndicator
              steps={stepInfos}
              currentStep={currentStep}
              orientation="horizontal"
              compact
            />
          </Box>
        )}
        
        {children}
      </Box>
    </Box>
  )
}

export default ResponsiveStepperLayout