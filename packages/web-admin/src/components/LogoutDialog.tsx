import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Avatar,
} from '@mui/material'
import { ExitToApp } from '@mui/icons-material'
import { useAuth } from "@/hooks/useAuth"

interface LogoutDialogProps {
  open: boolean
  onClose: () => void
}

export default function LogoutDialog({ open, onClose }: LogoutDialogProps) {
  const { logout, user } = useAuth()

  const handleLogout = async () => {
    try {
      await logout()
    } catch (error) {
      console.error('Logout error:', error)
      // Logout function handles the error internally
    }
    onClose()
  }

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2 }
      }}
    >
      <DialogTitle sx={{ textAlign: 'center', pb: 1 }}>
        <Box display="flex" flexDirection="column" alignItems="center" gap={2}>
          <Avatar sx={{ bgcolor: 'warning.main', width: 56, height: 56 }}>
            <ExitToApp />
          </Avatar>
          <Typography variant="h6" component="div">
            Confirmar Logout
          </Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent sx={{ textAlign: 'center', pt: 1 }}>
        <Typography variant="body1" color="text.secondary" gutterBottom>
          Tem certeza de que deseja sair do sistema?
        </Typography>
        
        {user && (
          <Box mt={2} p={2} bgcolor="grey.50" borderRadius={1}>
            <Typography variant="body2" color="text.secondary">
              Usuário conectado:
            </Typography>
            <Typography variant="body1" fontWeight="medium">
              {user.fullName}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {user.email}
            </Typography>
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 3, gap: 1 }}>
        <Button 
          onClick={onClose} 
          variant="outlined"
          color="primary"
          fullWidth
        >
          Cancelar
        </Button>
        <Button 
          onClick={handleLogout}
          variant="contained"
          color="warning"
          fullWidth
          startIcon={<ExitToApp />}
        >
          Sair
        </Button>
      </DialogActions>
    </Dialog>
  )
}