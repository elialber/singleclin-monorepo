import { useNavigate, useParams } from 'react-router-dom'
import { Box, Typography, Button, CircularProgress, Alert } from '@mui/material'
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material'
import { usePlan } from '@/hooks/usePlans'
import PlanFormDialog from '@/components/PlanFormDialog'
import { useState } from 'react'

export default function PlanForm() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const isEditing = Boolean(id)
  
  // Fetch plan data if editing
  const { data: plan, isLoading, error } = usePlan(id || '', !!id)
  
  const [formOpen, setFormOpen] = useState(false)

  const handleBackToList = () => {
    navigate('/plans')
  }

  const handleFormClose = () => {
    navigate('/plans')
  }

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress size={40} />
      </Box>
    )
  }

  if (error && isEditing) {
    return (
      <Box>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={handleBackToList}
          sx={{ mb: 2 }}
        >
          Voltar
        </Button>

        <Alert severity="error" sx={{ mt: 2 }}>
          Erro ao carregar o plano: {error.message}
          <Button size="small" onClick={() => window.location.reload()} sx={{ ml: 1 }}>
            Tentar novamente
          </Button>
        </Alert>
      </Box>
    )
  }

  return (
    <Box>
      <Button
        startIcon={<ArrowBackIcon />}
        onClick={handleBackToList}
        sx={{ mb: 2 }}
      >
        Voltar
      </Button>

      <Typography variant="h4" fontWeight={600} gutterBottom>
        {isEditing ? `Editar Plano: ${plan?.name || 'Carregando...'}` : 'Novo Plano'}
      </Typography>

      <PlanFormDialog
        open={true}
        onClose={handleFormClose}
        plan={isEditing ? plan || null : null}
      />
    </Box>
  )
}