import { useState } from 'react';
import { Button, CircularProgress } from '@mui/material';
import { Google as GoogleIcon } from '@mui/icons-material';
import { useAuth } from '@/hooks/useAuth';
import { useNotification } from '@/hooks/useNotification';

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
    } catch (err: any) {
      console.error('Google login error:', err);
      
      let message = 'Erro ao fazer login com Google. Tente novamente.';
      
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
      
      showError(message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Button
      fullWidth
      variant="outlined"
      onClick={handleGoogleLogin}
      disabled={isLoading}
      startIcon={isLoading ? <CircularProgress size={20} /> : <GoogleIcon />}
      sx={{ mb: 2, py: 1.5 }}
    >
      {isLoading ? 'Conectando...' : 'Entrar com Google'}
    </Button>
  );
}