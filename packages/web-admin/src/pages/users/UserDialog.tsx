import { useState, useEffect } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  CircularProgress,
  Box,
} from '@mui/material'
import { User } from '@/types/user'
import { userService, CreateUserDto, UpdateUserDto } from '@/services/user.service'
import { useNotification } from '@/hooks/useNotification'
import UserForm from './UserForm'
import { clinicService } from '@/services/clinic.service'

interface UserDialogProps {
  open: boolean
  user?: User | null
  onClose: (shouldReload?: boolean) => void
}

export default function UserDialog({ open, user, onClose }: UserDialogProps) {
  const { showNotification } = useNotification()
  const [loading, setLoading] = useState(false)
  const [clinics, setClinics] = useState<Array<{ id: string; name: string }>>([])

  useEffect(() => {
    if (open) {
      loadClinics()
    }
  }, [open])

  const loadClinics = async () => {
    try {
      const response = await clinicService.getClinics({ limit: 100 })
      setClinics(response.data.map(c => ({ id: c.id, name: c.name })))
    } catch (error) {
      console.error('Error loading clinics:', error)
    }
  }

  const handleSubmit = async (data: any) => {
    try {
      setLoading(true)

      if (user) {
        // Update existing user
        const updateData: UpdateUserDto = {
          firstName: data.firstName,
          lastName: data.lastName,
          phoneNumber: data.phoneNumber,
          role: data.role,
          clinicId: data.clinicId || undefined,
          isActive: data.isActive,
        }
        
        await userService.updateUser(user.id, updateData)
        showNotification('Usuário atualizado com sucesso', 'success')
      } else {
        // Create new user
        const createData: CreateUserDto = {
          email: data.email,
          firstName: data.firstName,
          lastName: data.lastName,
          role: data.role,
          phoneNumber: data.phoneNumber,
          clinicId: data.clinicId || undefined,
          password: data.password,
        }
        
        await userService.createUser(createData)
        showNotification('Usuário criado com sucesso', 'success')
      }

      onClose(true)
    } catch (error: any) {
      const message = error.response?.data?.message || 'Erro ao salvar usuário'
      showNotification(message, 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleClose = () => {
    if (!loading) {
      onClose(false)
    }
  }

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
      disableEscapeKeyDown={loading}
    >
      <DialogTitle>
        {user ? 'Editar Usuário' : 'Novo Usuário'}
      </DialogTitle>
      <DialogContent>
        <Box sx={{ pt: 2 }}>
          <UserForm
            user={user}
            onSubmit={handleSubmit}
            clinics={clinics}
          />
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={loading}>
          Cancelar
        </Button>
        <Button
          variant="contained"
          onClick={() => {
            const form = document.querySelector('form')
            form?.requestSubmit()
          }}
          disabled={loading}
        >
          {loading ? (
            <CircularProgress size={24} />
          ) : user ? (
            'Salvar'
          ) : (
            'Criar'
          )}
        </Button>
      </DialogActions>
    </Dialog>
  )
}