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
import { Warning } from '@mui/icons-material'

interface ConfirmDialogProps {
  open: boolean
  onClose: () => void
  onConfirm: () => void
  title: string
  message: string
  confirmText?: string
  cancelText?: string
  loading?: boolean
}

export default function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Confirmar',
  cancelText = 'Cancelar',
  loading = false,
}: ConfirmDialogProps) {
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
            <Warning />
          </Avatar>
          <Typography variant="h6" component="div">
            {title}
          </Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent sx={{ textAlign: 'center', pt: 1 }}>
        <Typography variant="body1" color="text.secondary">
          {message}
        </Typography>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 3, gap: 1 }}>
        <Button 
          onClick={onClose} 
          variant="outlined"
          color="primary"
          fullWidth
          disabled={loading}
        >
          {cancelText}
        </Button>
        <Button 
          onClick={onConfirm}
          variant="contained"
          color="warning"
          fullWidth
          disabled={loading}
        >
          {confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  )
}