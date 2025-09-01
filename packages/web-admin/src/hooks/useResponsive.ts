import { useTheme, useMediaQuery, Breakpoint } from '@mui/material'
import { useMemo } from 'react'

/**
 * Custom hook for responsive design utilities
 * Provides mobile-first approach helpers for consistent responsive behavior
 */
export const useResponsive = () => {
  const theme = useTheme()
  
  // Standard breakpoint queries
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'))
  const isTablet = useMediaQuery(theme.breakpoints.between('sm', 'md'))
  const isDesktop = useMediaQuery(theme.breakpoints.up('md'))
  const isLargeDesktop = useMediaQuery(theme.breakpoints.up('lg'))
  
  // Specific size queries
  const isXs = useMediaQuery(theme.breakpoints.only('xs'))
  const isSm = useMediaQuery(theme.breakpoints.only('sm'))
  const isMd = useMediaQuery(theme.breakpoints.only('md'))
  const isLg = useMediaQuery(theme.breakpoints.only('lg'))
  const isXl = useMediaQuery(theme.breakpoints.only('xl'))
  
  // Orientation queries
  const isPortrait = useMediaQuery('(orientation: portrait)')
  const isLandscape = useMediaQuery('(orientation: landscape)')
  
  // Device type detection
  const isTouchDevice = useMemo(() => {
    return 'ontouchstart' in window || navigator.maxTouchPoints > 0
  }, [])
  
  // Helper functions
  const breakpointUp = (breakpoint: Breakpoint) => {
    return useMediaQuery(theme.breakpoints.up(breakpoint))
  }
  
  const breakpointDown = (breakpoint: Breakpoint) => {
    return useMediaQuery(theme.breakpoints.down(breakpoint))
  }
  
  const breakpointBetween = (start: Breakpoint, end: Breakpoint) => {
    return useMediaQuery(theme.breakpoints.between(start, end))
  }
  
  // Responsive value selector
  const getResponsiveValue = <T>(values: {
    xs?: T
    sm?: T
    md?: T
    lg?: T
    xl?: T
  }): T | undefined => {
    if (isXl && values.xl !== undefined) return values.xl
    if (isLg && values.lg !== undefined) return values.lg
    if (isMd && values.md !== undefined) return values.md
    if (isSm && values.sm !== undefined) return values.sm
    if (isXs && values.xs !== undefined) return values.xs
    
    // Fallback to largest available value
    return values.xl ?? values.lg ?? values.md ?? values.sm ?? values.xs
  }
  
  // Grid columns helper for responsive layouts
  const getGridColumns = (
    mobile: number = 1,
    tablet: number = 2, 
    desktop: number = 4
  ) => {
    if (isMobile) return mobile
    if (isTablet) return tablet
    return desktop
  }
  
  // Spacing helper for responsive layouts
  const getSpacing = (
    mobile: number = 2,
    tablet: number = 3,
    desktop: number = 4
  ) => {
    if (isMobile) return mobile
    if (isTablet) return tablet
    return desktop
  }
  
  // Typography variant helper
  const getTypographyVariant = (
    mobileVariant: string,
    desktopVariant: string
  ) => {
    return isMobile ? mobileVariant : desktopVariant
  }
  
  // Icon size helper
  const getIconSize = (
    mobile: 'small' | 'medium' | 'large' = 'small',
    desktop: 'small' | 'medium' | 'large' = 'medium'
  ) => {
    return isMobile ? mobile : desktop
  }
  
  // Touch target helper (ensures minimum 44px touch targets)
  const getTouchTargetProps = () => ({
    sx: isTouchDevice ? {
      minHeight: '44px',
      minWidth: '44px',
      '& .MuiSvgIcon-root': {
        fontSize: isMobile ? '1rem' : '1.25rem'
      }
    } : {}
  })
  
  return {
    // Breakpoint booleans
    isMobile,
    isTablet,
    isDesktop,
    isLargeDesktop,
    isXs,
    isSm,
    isMd,
    isLg,
    isXl,
    
    // Orientation
    isPortrait,
    isLandscape,
    
    // Device type
    isTouchDevice,
    
    // Helper functions
    breakpointUp,
    breakpointDown,
    breakpointBetween,
    getResponsiveValue,
    getGridColumns,
    getSpacing,
    getTypographyVariant,
    getIconSize,
    getTouchTargetProps,
    
    // Theme reference
    theme
  }
}

/**
 * Hook for mobile-specific optimizations
 */
export const useMobileOptimizations = () => {
  const { isMobile, isTablet, isTouchDevice } = useResponsive()
  
  // Common mobile styles
  const getMobileCardStyles = () => ({
    mb: 2,
    cursor: 'pointer',
    transition: 'all 0.2s ease',
    '&:hover': {
      elevation: 3,
      transform: isTouchDevice ? 'none' : 'translateY(-1px)'
    },
    '&:active': isTouchDevice ? {
      transform: 'scale(0.98)'
    } : {}
  })
  
  // Mobile-optimized button styles
  const getMobileButtonStyles = () => ({
    minHeight: isTouchDevice ? '44px' : 'auto',
    minWidth: isTouchDevice ? '44px' : 'auto',
    fontSize: isMobile ? '0.875rem' : 'inherit'
  })
  
  // Mobile table alternative
  const shouldUseCardLayout = () => isMobile || isTablet
  
  // Mobile form styles
  const getMobileFormStyles = () => ({
    '& .MuiTextField-root': {
      mb: 2,
      '& .MuiInputBase-root': {
        minHeight: isTouchDevice ? '44px' : 'auto'
      }
    }
  })
  
  return {
    isMobile,
    isTablet,
    isTouchDevice,
    getMobileCardStyles,
    getMobileButtonStyles,
    shouldUseCardLayout,
    getMobileFormStyles
  }
}