import { useState } from 'react';
import { Button, CircularProgress, Typography, Box } from '@mui/material';
import { PrivacyTip as PrivacyIcon } from '@mui/icons-material';
import { FirebaseError } from 'firebase/app';
import { useAuth } from '@/hooks/useAuth';
import { useNotification } from '@/hooks/useNotification';

// Google logo SVG component with official colors
const GoogleLogo = () => (
  <svg width="20" height="20" viewBox="0 0 48 48">
    <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
    <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
    <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
    <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
    <path fill="none" d="M0 0h48v48H0z"/>
  </svg>
);

export function GoogleLoginButton() {
  const [isLoading, setIsLoading] = useState(false);
  const { loginWithGoogle } = useAuth();
  const { showError, showSuccess } = useNotification();

  const handleGoogleLogin = async () => {
    try {
      setIsLoading(true);
      // Use popup method for Google login
      await loginWithGoogle();
      showSuccess('Login com Google realizado com sucesso!');
    } catch (err: unknown) {
      console.error('Google login error:', err);

      let message = 'Erro ao fazer login com Google. Tente novamente.';

      if (err instanceof FirebaseError) {
        if (err.code === 'auth/popup-blocked') {
          message = 'Por favor, permita popups para fazer login com Google';
        } else if (err.code === 'auth/cancelled-popup-request') {
          message = 'Login cancelado';
        } else if (err.code === 'auth/popup-closed-by-user') {
          message = 'Popup fechado antes de concluir o login';
        } else if (err.code === 'auth/operation-not-allowed') {
          message = 'Login com Google não está habilitado. Entre em contato com o suporte.';
        } else if (err.message) {
          message = err.message;
        }
      } else if (err instanceof Error && err.message) {
        message = err.message;
      }
      
      showError(message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Box>
      <Button
        fullWidth
        variant="outlined"
        onClick={handleGoogleLogin}
        disabled={isLoading}
        startIcon={
          isLoading ? (
            <CircularProgress size={20} color="inherit" />
          ) : (
            <GoogleLogo />
          )
        }
        sx={{
          py: 1.5,
          borderRadius: 2,
          fontWeight: 500,
          textTransform: 'none',
          borderColor: '#dadce0',
          backgroundColor: '#fff',
          color: '#3c4043',
          position: 'relative',
          overflow: 'hidden',
          transition: 'all 0.3s ease',
          '&:hover:not(:disabled)': {
            backgroundColor: '#f8f9fa',
            borderColor: '#dadce0',
            boxShadow: '0 1px 2px 0 rgba(60,64,67,0.3), 0 1px 3px 1px rgba(60,64,67,0.15)',
          },
          '&:active': {
            backgroundColor: '#e8eaed',
            boxShadow: '0 1px 2px 0 rgba(60,64,67,0.3), 0 2px 6px 2px rgba(60,64,67,0.15)',
          },
          '&.Mui-disabled': {
            backgroundColor: '#f8f9fa',
            borderColor: '#dadce0',
            color: 'rgba(60,64,67,0.38)',
          },
        }}
      >
        {isLoading ? (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography variant="inherit">Conectando com Google...</Typography>
          </Box>
        ) : (
          'Entrar com Google'
        )}
      </Button>
      
      {/* Privacy note */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mt: 1.5 }}>
        <PrivacyIcon sx={{ fontSize: 12, color: 'text.secondary', mr: 0.5 }} />
        <Typography 
          variant="caption" 
          color="text.secondary" 
          sx={{ 
            fontSize: '0.7rem',
            textAlign: 'center',
            maxWidth: 280,
            lineHeight: 1.3,
          }}
        >
          Suas informações do Google são utilizadas apenas para autenticação segura
        </Typography>
      </Box>
    </Box>
  );
}