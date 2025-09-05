import React from 'react'
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Divider,
  Chip
} from '@mui/material'
import {
  Preview as PreviewIcon,
  Edit as EditIcon,
  CheckCircle as CheckIcon
} from '@mui/icons-material'
import { ClinicStepper } from '../core/ClinicStepper'
import { ClinicFormData, ClinicType } from '../../../../types/stepper'

/**
 * Exemplo de uso do Step 4 - Revisão Final
 * 
 * Demonstra:
 * - Revisão completa dos dados de todas as etapas
 * - Edição inline de campos
 * - Navegação para steps específicos
 * - Validação final antes do envio
 * - Estados visuais e feedback
 */

// Dados de exemplo pré-preenchidos para demonstração
const mockFormData: Partial<ClinicFormData> = {
  basicInfo: {
    name: 'Clínica Exemplo São Paulo',
    type: ClinicType.Regular,
    cnpj: '11.222.333/0001-81',
    phone: '(11) 99999-9999',
    email: 'contato@clinicaexemplo.com.br',
    isActive: true
  },
  address: {
    cep: '01310-100',
    street: 'Avenida Paulista',
    number: '1000',
    complement: 'Sala 1001',
    neighborhood: 'Bela Vista',
    city: 'São Paulo',
    state: 'SP',
    coordinates: {
      lat: -23.5612908,
      lng: -46.6563236
    }
  },
  images: [
    {
      id: '1',
      file: new File([''], 'fachada.jpg', { type: 'image/jpeg' }),
      url: 'https://via.placeholder.com/800x600/1976d2/ffffff?text=Fachada+da+Cl%C3%ADnica',
      altText: 'Fachada da Clínica Exemplo',
      isFeatured: true,
      uploadProgress: 100,
      uploadStatus: 'completed'
    },
    {
      id: '2',
      file: new File([''], 'recepcao.jpg', { type: 'image/jpeg' }),
      url: 'https://via.placeholder.com/800x600/4caf50/ffffff?text=Recep%C3%A7%C3%A3o',
      altText: 'Área de recepção',
      isFeatured: false,
      uploadProgress: 100,
      uploadStatus: 'completed'
    },
    {
      id: '3',
      file: new File([''], 'consultorio.jpg', { type: 'image/jpeg' }),
      url: 'https://via.placeholder.com/800x600/ff9800/ffffff?text=Consult%C3%B3rio',
      altText: 'Consultório médico',
      isFeatured: false,
      uploadProgress: 100,
      uploadStatus: 'completed'
    }
  ]
}

export function Step4Example() {
  const [showStepper, setShowStepper] = React.useState(false)
  const [exampleMode, setExampleMode] = React.useState<'empty' | 'partial' | 'complete'>('complete')

  const handleSubmit = async (data: ClinicFormData) => {
    console.log('📋 Dados finais para envio:', data)
    
    // Simular envio
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    alert('✅ Clínica cadastrada com sucesso!')
    setShowStepper(false)
  }

  const getInitialData = () => {
    switch (exampleMode) {
      case 'empty':
        return {}
      case 'partial':
        return {
          basicInfo: mockFormData.basicInfo
        }
      case 'complete':
        return mockFormData
      default:
        return {}
    }
  }

  if (showStepper) {
    return (
      <ClinicStepper
        initialData={getInitialData()}
        onSubmit={handleSubmit}
        title={`Exemplo Step 4 - Modo ${exampleMode.charAt(0).toUpperCase() + exampleMode.slice(1)}`}
      />
    )
  }

  return (
    <Box sx={{ maxWidth: 1200, mx: 'auto', p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Step 4 - Revisão Final
        </Typography>
        <Typography variant="body1" color="text.secondary" paragraph>
          Demonstração do step final do cadastro de clínica com revisão completa dos dados,
          edição inline e validação final antes do envio.
        </Typography>
      </Box>

      {/* Funcionalidades */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <CheckIcon color="primary" />
            Funcionalidades Implementadas
          </Typography>
          
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 2 }}>
            <Chip icon={<PreviewIcon />} label="Revisão visual completa" variant="outlined" />
            <Chip icon={<EditIcon />} label="Edição inline de campos" variant="outlined" />
            <Chip label="Seções expandíveis/recolhíveis" variant="outlined" />
            <Chip label="Navegação para steps específicos" variant="outlined" />
            <Chip label="Validação final cross-etapas" variant="outlined" />
            <Chip label="Estados visuais de progresso" variant="outlined" />
            <Chip label="Resumo de imagens com preview" variant="outlined" />
            <Chip label="Indicadores de campos obrigatórios" variant="outlined" />
          </Box>
        </CardContent>
      </Card>

      {/* Cenários de teste */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Cenários de Demonstração
          </Typography>
          
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
            <Box>
              <Typography variant="subtitle2" gutterBottom>
                1. Formulário Vazio
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Inicie do zero e navegue pelos steps até chegar na revisão final.
                Teste as validações e campos obrigatórios.
              </Typography>
              <Button
                variant="outlined"
                onClick={() => {
                  setExampleMode('empty')
                  setShowStepper(true)
                }}
              >
                Testar Formulário Vazio
              </Button>
            </Box>

            <Divider />

            <Box>
              <Typography variant="subtitle2" gutterBottom>
                2. Dados Parciais
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Comece com informações básicas preenchidas e complete os demais steps.
                Teste a persistência de dados entre navegações.
              </Typography>
              <Button
                variant="outlined"
                onClick={() => {
                  setExampleMode('partial')
                  setShowStepper(true)
                }}
              >
                Testar Dados Parciais
              </Button>
            </Box>

            <Divider />

            <Box>
              <Typography variant="subtitle2" gutterBottom>
                3. Formulário Completo
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Vá diretamente para a revisão final com todos os dados preenchidos.
                Teste as funcionalidades de edição inline e navegação entre steps.
              </Typography>
              <Button
                variant="contained"
                onClick={() => {
                  setExampleMode('complete')
                  setShowStepper(true)
                }}
              >
                Testar Formulário Completo
              </Button>
            </Box>
          </Box>
        </CardContent>
      </Card>

      {/* Casos de teste específicos */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Casos de Teste para Step 4
          </Typography>
          
          <Box component="ol" sx={{ pl: 2 }}>
            <Box component="li" sx={{ mb: 1 }}>
              <Typography variant="body2">
                <strong>Edição Inline:</strong> Clique nos ícones de edição ao lado dos campos
                para editá-los diretamente na revisão final
              </Typography>
            </Box>
            
            <Box component="li" sx={{ mb: 1 }}>
              <Typography variant="body2">
                <strong>Navegação para Steps:</strong> Use os botões "Editar" em cada seção
                para voltar ao step correspondente
              </Typography>
            </Box>
            
            <Box component="li" sx={{ mb: 1 }}>
              <Typography variant="body2">
                <strong>Seções Expandíveis:</strong> Clique nos headers das seções para
                expandir/recolher o conteúdo
              </Typography>
            </Box>
            
            <Box component="li" sx={{ mb: 1 }}>
              <Typography variant="body2">
                <strong>Validação Final:</strong> Teste tentativas de envio com dados
                incompletos para ver as validações
              </Typography>
            </Box>
            
            <Box component="li" sx={{ mb: 1 }}>
              <Typography variant="body2">
                <strong>Preview de Imagens:</strong> Teste o grid de imagens, imagem principal
                e textos alternativos
              </Typography>
            </Box>
          </Box>
        </CardContent>
      </Card>
    </Box>
  )
}

export default Step4Example