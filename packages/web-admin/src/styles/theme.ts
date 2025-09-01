import { createTheme } from '@mui/material/styles'
import { ptBR } from '@mui/material/locale'

// SingleClin Brand Color Palette
const singleclinColors = {
  primary: '#005156', // Azul-Esverdeado (Pantone 7476 C)
  primaryLight: '#006B71', // Lighter version for hover states
  primaryDark: '#003A3D', // Darker version for pressed states
  black: '#000000', // Preto
  white: '#FFFFFF', // Branco
  lightGrey: '#E6E6E6', // Cinza Claro
  // Additional complementary colors for better UX
  darkGrey: '#333333',
  mediumGrey: '#666666',
}

export const theme = createTheme(
  {
    breakpoints: {
      values: {
        xs: 0,      // Mobile portrait
        sm: 600,    // Mobile landscape / Small tablet
        md: 900,    // Tablet
        lg: 1200,   // Desktop
        xl: 1536,   // Large desktop
      },
    },
    palette: {
      mode: 'light',
      primary: {
        main: singleclinColors.primary, // #005156
        light: singleclinColors.primaryLight, // #006B71
        dark: singleclinColors.primaryDark, // #003A3D
        contrastText: singleclinColors.white,
      },
      secondary: {
        main: singleclinColors.lightGrey, // #E6E6E6
        light: '#F0F0F0',
        dark: '#CCCCCC',
        contrastText: singleclinColors.black,
      },
      error: {
        main: '#d32f2f',
      },
      warning: {
        main: '#ed6c02',
      },
      info: {
        main: singleclinColors.primary, // Using brand color for info
      },
      success: {
        main: '#2e7d32',
      },
      background: {
        default: singleclinColors.white, // #FFFFFF
        paper: singleclinColors.white, // #FFFFFF
      },
      text: {
        primary: singleclinColors.black, // #000000
        secondary: singleclinColors.mediumGrey, // #666666
      },
      divider: singleclinColors.lightGrey, // #E6E6E6
    },
    typography: {
      fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
      h1: {
        fontSize: '2.5rem',
        fontWeight: 600,
      },
      h2: {
        fontSize: '2rem',
        fontWeight: 600,
      },
      h3: {
        fontSize: '1.75rem',
        fontWeight: 600,
      },
      h4: {
        fontSize: '1.5rem',
        fontWeight: 600,
      },
      h5: {
        fontSize: '1.25rem',
        fontWeight: 600,
      },
      h6: {
        fontSize: '1rem',
        fontWeight: 600,
      },
      button: {
        textTransform: 'none',
      },
    },
    shape: {
      borderRadius: 8,
    },
    components: {
      MuiCard: {
        styleOverrides: {
          root: {
            boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
            border: `1px solid ${singleclinColors.lightGrey}`,
            borderRadius: 12,
            '&:hover': {
              boxShadow: `0 4px 16px rgba(0, 81, 86, 0.12)`,
            },
          },
        },
      },
      MuiDrawer: {
        styleOverrides: {
          paper: {
            borderRight: 'none',
            boxShadow: '2px 0 8px rgba(0,0,0,0.08)',
            background: `linear-gradient(180deg, ${singleclinColors.white} 0%, ${singleclinColors.lightGrey}20 100%)`,
          },
        },
      },
      MuiAppBar: {
        styleOverrides: {
          root: {
            background: `linear-gradient(135deg, ${singleclinColors.primary} 0%, ${singleclinColors.black} 100%)`,
            boxShadow: '0 2px 8px rgba(0, 81, 86, 0.2)',
          },
        },
      },
      MuiPaper: {
        styleOverrides: {
          root: {
            backgroundImage: 'none',
          },
          elevation1: {
            boxShadow: '0 1px 4px rgba(0, 81, 86, 0.08)',
          },
          elevation2: {
            boxShadow: '0 2px 8px rgba(0, 81, 86, 0.12)',
          },
          elevation4: {
            boxShadow: '0 4px 16px rgba(0, 81, 86, 0.16)',
          },
        },
      },
      MuiChip: {
        styleOverrides: {
          root: {
            borderRadius: 8,
          },
          colorPrimary: {
            background: `linear-gradient(135deg, ${singleclinColors.primary}20 0%, ${singleclinColors.primary}10 100%)`,
            color: singleclinColors.primary,
            border: `1px solid ${singleclinColors.primary}40`,
          },
        },
      },
      MuiLinearProgress: {
        styleOverrides: {
          root: {
            borderRadius: 4,
            backgroundColor: singleclinColors.lightGrey,
          },
          bar: {
            background: `linear-gradient(90deg, ${singleclinColors.primary} 0%, ${singleclinColors.primaryLight} 100%)`,
          },
        },
      },
      // Mobile-first responsive components
      MuiContainer: {
        styleOverrides: {
          root: {
            paddingLeft: '16px',
            paddingRight: '16px',
            '@media (min-width: 600px)': {
              paddingLeft: '24px',
              paddingRight: '24px',
            },
          },
        },
      },
      MuiIconButton: {
        styleOverrides: {
          root: {
            // Ensure touch targets are at least 44px for mobile
            '@media (max-width: 599px)': {
              minHeight: '44px',
              minWidth: '44px',
            },
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: {
            borderRadius: 8,
            textTransform: 'none',
            // Ensure touch targets are at least 44px for mobile
            '@media (max-width: 599px)': {
              minHeight: '44px',
              fontSize: '0.875rem',
            },
          },
          containedPrimary: {
            background: `linear-gradient(135deg, ${singleclinColors.primary} 0%, ${singleclinColors.primaryDark} 100%)`,
            '&:hover': {
              background: `linear-gradient(135deg, ${singleclinColors.primaryLight} 0%, ${singleclinColors.primary} 100%)`,
              boxShadow: `0 4px 12px rgba(0, 81, 86, 0.3)`,
            },
          },
          outlinedPrimary: {
            borderColor: singleclinColors.primary,
            color: singleclinColors.primary,
            '&:hover': {
              borderColor: singleclinColors.primaryLight,
              backgroundColor: `${singleclinColors.primary}08`,
            },
          },
        },
      },
      MuiTableContainer: {
        styleOverrides: {
          root: {
            '@media (max-width: 899px)': {
              // Add horizontal scrolling for tables on mobile/tablet
              overflowX: 'auto',
            },
          },
        },
      },
      MuiTable: {
        styleOverrides: {
          root: {
            '@media (max-width: 899px)': {
              minWidth: '700px', // Ensure table doesn't collapse too much
            },
          },
        },
      },
    },
  },
  ptBR,
)