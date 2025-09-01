import React from 'react'
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  IconButton,
  Stack,
  Grid,
  Chip,
} from '@mui/material'
import {
  Phone as PhoneIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
  TouchApp as TouchIcon,
} from '@mui/icons-material'
import { useResponsive, useMobileOptimizations } from '@/hooks/useResponsive'

/**
 * Test component to verify mobile responsiveness
 * This component can be imported to test mobile optimizations
 */
export const MobileTestComponent: React.FC = () => {
  const {
    isMobile,
    isTablet,
    isDesktop,
    isTouchDevice,
    getResponsiveValue,
    getGridColumns,
    getSpacing,
    getTypographyVariant,
    getTouchTargetProps
  } = useResponsive()
  
  const {
    getMobileCardStyles,
    getMobileButtonStyles,
    shouldUseCardLayout
  } = useMobileOptimizations()
  
  const currentDevice = isMobile ? 'Mobile' : isTablet ? 'Tablet' : 'Desktop'
  const deviceIcon = isMobile ? <PhoneIcon /> : isTablet ? <TabletIcon /> : <ComputerIcon />
  
  const responsiveSpacing = getSpacing(1, 2, 3)
  const responsiveColumns = getGridColumns(1, 2, 4)
  
  return (
    <Box sx={{ p: responsiveSpacing }}>
      <Stack spacing={responsiveSpacing}>
        {/* Device Detection Header */}
        <Card elevation={2}>
          <CardContent>
            <Stack direction="row" alignItems="center" spacing={2}>
              {deviceIcon}
              <Box>
                <Typography 
                  variant={getTypographyVariant('h6', 'h5')} 
                  fontWeight={600}
                >
                  Current Device: {currentDevice}
                </Typography>
                <Stack direction="row" spacing={1} mt={1}>
                  <Chip 
                    size="small" 
                    label={`Touch: ${isTouchDevice ? 'Yes' : 'No'}`} 
                    color={isTouchDevice ? 'success' : 'default'}
                  />
                  <Chip 
                    size="small" 
                    label={`Layout: ${shouldUseCardLayout() ? 'Card' : 'Table'}`} 
                    color="primary"
                  />
                </Stack>
              </Box>
            </Stack>
          </CardContent>
        </Card>
        
        {/* Responsive Grid Test */}
        <Typography variant="h6">
          Responsive Grid ({responsiveColumns} columns)
        </Typography>
        
        <Grid container spacing={responsiveSpacing}>
          {Array.from({ length: 4 }, (_, i) => (
            <Grid item xs={12 / responsiveColumns} key={i}>
              <Card sx={getMobileCardStyles()}>
                <CardContent sx={{ textAlign: 'center' }}>
                  <Typography variant="body2">
                    Card {i + 1}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {getResponsiveValue({
                      xs: 'Mobile view',
                      sm: 'Tablet view',
                      md: 'Desktop view'
                    })}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}\n        </Grid>
        
        {/* Touch Target Test */}
        <Typography variant="h6">
          Touch Targets Test
        </Typography>
        
        <Stack direction="row" spacing={2} flexWrap="wrap">
          <Button 
            variant="contained" 
            sx={getMobileButtonStyles()}
          >
            Primary Button
          </Button>
          
          <Button 
            variant="outlined" 
            sx={getMobileButtonStyles()}
          >
            Secondary Button
          </Button>
          
          <IconButton 
            {...getTouchTargetProps()}
            color="primary"
          >
            <TouchIcon />
          </IconButton>
        </Stack>
        
        {/* Typography Test */}
        <Typography variant="h6">
          Responsive Typography
        </Typography>
        
        <Stack spacing={1}>
          <Typography 
            variant={getResponsiveValue({
              xs: 'h6',
              sm: 'h5', 
              md: 'h4'
            })}
          >
            Responsive Header
          </Typography>
          
          <Typography 
            variant={getResponsiveValue({
              xs: 'body2',
              sm: 'body1',
              md: 'body1'
            })}
            color="text.secondary"
          >
            This text adapts to screen size: smaller on mobile, larger on desktop.
            Touch interaction is {isTouchDevice ? 'enabled' : 'disabled'}.
          </Typography>
        </Stack>
        
        {/* Breakpoint Info */}
        <Card variant="outlined">
          <CardContent>
            <Typography variant="subtitle2" gutterBottom>
              Breakpoint Information
            </Typography>
            <Typography variant="body2" color="text.secondary">
              • Mobile (xs-sm): 0px - 899px<br/>
              • Tablet (md): 900px - 1199px<br/>
              • Desktop (lg+): 1200px+<br/>
              • Touch targets: {isTouchDevice ? '44px minimum' : 'Default size'}
            </Typography>
          </CardContent>
        </Card>
      </Stack>
    </Box>
  )
}