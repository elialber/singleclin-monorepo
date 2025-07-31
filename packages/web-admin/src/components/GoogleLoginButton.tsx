import { useState } from 'react';
import { Button, CircularProgress } from '@mui/material';
import { Google as GoogleIcon } from '@mui/icons-material';
import { useAuth } from '@/hooks/useAuth';
import { useNotification } from '@/hooks/useNotification';
import { signInWithGoogleRedirect } from '@/services/firebaseAuthRedirect';

export function GoogleLoginButton() {
  const [isLoading, setIsLoading] = useState(false);
  const { showError, showSuccess } = useNotification();

  const handleGoogleLogin = async () => {
    try {
      setIsLoading(true);
      // Using redirect method which is more reliable
      showSuccess('Redirecionando para o Google...');
      await signInWithGoogleRedirect();
      // The actual login will be handled when the user returns from Google
    } catch (err: any) {
      console.error('Google login error:', err);
      
      let message = 'Erro ao fazer login com Google. Tente novamente.';
      
      if (err.code === 'auth/popup-blocked') {
        message = 'Por favor, permita popups para fazer login com Google';
      } else if (err.code === 'auth/operation-not-allowed') {
        message = 'Login com Google não está habilitado. Entre em contato com o suporte.';
      } else if (err.message) {
        message = err.message;
      }
      
      showError(message);
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
      {isLoading ? 'Redirecionando...' : 'Entrar com Google'}
    </Button>
  );
}