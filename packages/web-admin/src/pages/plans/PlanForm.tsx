import { useNavigate } from 'react-router-dom'
import { Box, Typography, Paper, Button } from '@mui/material'
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material'

export default function PlanForm() {
  const navigate = useNavigate()

  return (
    <Box>
      <Button
        startIcon={<ArrowBackIcon />}
        onClick={() => navigate('/plans')}
        sx={{ mb: 2 }}
      >
        Voltar
      </Button>

      <Typography variant="h4" fontWeight={600} gutterBottom>
        Novo Plano
      </Typography>

      <Paper sx={{ p: 3, mt: 3 }}>
        <Typography variant="body1" color="text.secondary">
          Formulário de criação/edição de plano será implementado aqui
        </Typography>
      </Paper>
    </Box>
  )
}