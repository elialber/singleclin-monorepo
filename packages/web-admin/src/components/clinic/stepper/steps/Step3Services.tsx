import React, { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  FormControl,
  FormControlLabel,
  Checkbox,
  Grid,
  Card,
  CardContent,
  CardHeader,
  Chip,
  Switch,
  FormGroup,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Divider,
  Alert,
  Button,
  TextField,
  IconButton,
  Tooltip
} from '@mui/material'
import {
  ExpandMore,
  CheckCircle,
  RadioButtonUnchecked,
  SelectAll,
  Clear,
  Info as InfoIcon
} from '@mui/icons-material'
import { useClinicStepper } from '../hooks/useClinicStepper'
import { StepComponentProps } from '../../../../types/stepper'
import { PREDEFINED_SERVICES, SelectedService } from '../../../../types/stepper'

/**
 * Step 3: Serviços da Clínica
 * 
 * Permite selecionar os serviços oferecidos pela clínica a partir de uma lista predefinida
 */
function Step3Services({ onNext, onPrev, isValid, isDirty }: StepComponentProps) {
  const { formData, updateFormData, setStepError, clearStepErrors } = useClinicStepper()
  
  // Estado local para os serviços
  const [services, setServices] = useState<SelectedService[]>(() => {
    // Se já tem serviços no formData, usar eles, senão usar os predefinidos
    if (formData.services?.selectedServices && formData.services.selectedServices.length > 0) {
      return formData.services.selectedServices
    }
    return PREDEFINED_SERVICES.map(service => ({ ...service }))
  })
  
  const [expandedCategories, setExpandedCategories] = useState<{[key: string]: boolean}>({})
  const [showOnlySelected, setShowOnlySelected] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')

  // Agrupar serviços por categoria
  const servicesByCategory = services.reduce((acc, service) => {
    if (!acc[service.category]) {
      acc[service.category] = []
    }
    acc[service.category].push(service)
    return acc
  }, {} as {[key: string]: SelectedService[]})

  // Filtrar serviços baseado no search e se deve mostrar apenas selecionados
  const filteredServicesByCategory = Object.entries(servicesByCategory).reduce((acc, [category, categoryServices]) => {
    const filtered = categoryServices.filter(service => {
      const matchesSearch = service.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           service.category.toLowerCase().includes(searchTerm.toLowerCase())
      const matchesFilter = !showOnlySelected || service.isSelected
      return matchesSearch && matchesFilter
    })
    
    if (filtered.length > 0) {
      acc[category] = filtered
    }
    
    return acc
  }, {} as {[key: string]: SelectedService[]})

  // Estatísticas
  const totalServices = services.length
  const selectedServices = services.filter(s => s.isSelected)
  const totalSelectedServices = selectedServices.length
  const totalCredits = selectedServices.reduce((sum, service) => sum + service.credits, 0)

  useEffect(() => {
    // Expandir todas as categorias que têm pelo menos um serviço selecionado
    const newExpanded: {[key: string]: boolean} = {}
    Object.keys(filteredServicesByCategory).forEach(category => {
      const hasSelected = filteredServicesByCategory[category].some(s => s.isSelected)
      newExpanded[category] = hasSelected || Object.keys(filteredServicesByCategory).length <= 3
    })
    setExpandedCategories(newExpanded)
  }, [])

  // Atualizar formData sempre que os serviços mudarem
  useEffect(() => {
    updateFormData('services', {
      selectedServices: services
    })
    
    // Validação: pelo menos um serviço deve estar selecionado
    const selectedCount = services.filter(s => s.isSelected).length
    if (selectedCount === 0) {
      setStepError(2, 'services', ['Selecione pelo menos um serviço'])
    } else {
      clearStepErrors(2)
    }
    
    console.log('Step3Services: Selected services count:', selectedCount)
  }, [services, updateFormData, setStepError, clearStepErrors])

  const handleServiceToggle = (serviceId: string) => {
    setServices(prev => prev.map(service => 
      service.id === serviceId 
        ? { ...service, isSelected: !service.isSelected }
        : service
    ))
  }

  const handleCategoryToggle = (category: string, selectAll: boolean) => {
    setServices(prev => prev.map(service =>
      service.category === category
        ? { ...service, isSelected: selectAll }
        : service
    ))
  }

  const handleSelectAll = () => {
    setServices(prev => prev.map(service => ({ ...service, isSelected: true })))
  }

  const handleDeselectAll = () => {
    setServices(prev => prev.map(service => ({ ...service, isSelected: false })))
  }

  const toggleCategoryExpansion = (category: string) => {
    setExpandedCategories(prev => ({
      ...prev,
      [category]: !prev[category]
    }))
  }

  const getCategoryStats = (category: string) => {
    const categoryServices = filteredServicesByCategory[category] || []
    const selectedCount = categoryServices.filter(s => s.isSelected).length
    const totalCount = categoryServices.length
    return { selected: selectedCount, total: totalCount }
  }

  return (
    <Box sx={{ maxWidth: '100%', mx: 'auto', py: 2 }}>
      {/* Header */}
      <Box sx={{ mb: 4, textAlign: 'center' }}>
        <Typography variant="h4" gutterBottom>
          Serviços da Clínica
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Selecione os serviços que sua clínica oferece. Todos os serviços estão marcados por padrão, 
          desmarque aqueles que não são oferecidos.
        </Typography>
      </Box>

      {/* Estatísticas e controles */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={3} alignItems="center">
            <Grid item xs={12} sm={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h6" color="primary">
                  {totalSelectedServices}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Serviços Selecionados
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h6" color="secondary">
                  {totalCredits}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Total de Créditos (SG)
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={4}>
              <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
                <Button
                  size="small"
                  variant="outlined"
                  startIcon={<SelectAll />}
                  onClick={handleSelectAll}
                >
                  Marcar Todos
                </Button>
                <Button
                  size="small"
                  variant="outlined"
                  startIcon={<Clear />}
                  onClick={handleDeselectAll}
                >
                  Desmarcar Todos
                </Button>
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Filtros */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
        <TextField
          size="small"
          placeholder="Buscar serviços..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          sx={{ flex: 1, minWidth: 200 }}
        />
        <FormControlLabel
          control={
            <Switch
              checked={showOnlySelected}
              onChange={(e) => setShowOnlySelected(e.target.checked)}
              color="primary"
            />
          }
          label="Mostrar apenas selecionados"
        />
      </Box>

      {/* Serviços por categoria */}
      <Box sx={{ space: 2 }}>
        {Object.entries(filteredServicesByCategory).map(([category, categoryServices]) => {
          const stats = getCategoryStats(category)
          const isExpanded = expandedCategories[category]
          
          return (
            <Accordion
              key={category}
              expanded={isExpanded}
              onChange={() => toggleCategoryExpansion(category)}
              sx={{ mb: 1 }}
            >
              <AccordionSummary expandIcon={<ExpandMore />}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, width: '100%', mr: 2 }}>
                  <Typography variant="h6" sx={{ flex: 1 }}>
                    {category}
                  </Typography>
                  <Chip
                    label={`${stats.selected}/${stats.total}`}
                    color={stats.selected === stats.total ? 'success' : stats.selected === 0 ? 'default' : 'warning'}
                    size="small"
                  />
                  <Box sx={{ display: 'flex', gap: 0.5 }}>
                    <Tooltip title="Marcar todos da categoria">
                      <IconButton
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleCategoryToggle(category, true)
                        }}
                      >
                        <CheckCircle fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Desmarcar todos da categoria">
                      <IconButton
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleCategoryToggle(category, false)
                        }}
                      >
                        <RadioButtonUnchecked fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </Box>
                </Box>
              </AccordionSummary>
              <AccordionDetails>
                <FormGroup>
                  <Grid container spacing={1}>
                    {categoryServices.map((service) => (
                      <Grid item xs={12} sm={6} md={4} key={service.id}>
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={service.isSelected}
                              onChange={() => handleServiceToggle(service.id)}
                              color="primary"
                            />
                          }
                          label={
                            <Box>
                              <Typography variant="body2" fontWeight={service.isSelected ? 600 : 400}>
                                {service.name}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {service.credits} SG
                              </Typography>
                            </Box>
                          }
                        />
                      </Grid>
                    ))}
                  </Grid>
                </FormGroup>
              </AccordionDetails>
            </Accordion>
          )
        })}
      </Box>

      {/* Informações adicionais */}
      {totalSelectedServices === 0 && (
        <Alert severity="warning" sx={{ mt: 2 }}>
          <Typography variant="body2">
            Você deve selecionar pelo menos um serviço para continuar.
          </Typography>
        </Alert>
      )}
      
      {totalSelectedServices > 0 && (
        <Alert severity="info" sx={{ mt: 2 }}>
          <Typography variant="body2">
            <strong>{totalSelectedServices} serviços selecionados</strong> totalizando <strong>{totalCredits} SG</strong>.
            Os créditos SG (SingleClin) são utilizados pelos pacientes para pagar pelos serviços.
          </Typography>
        </Alert>
      )}
    </Box>
  )
}

export default Step3Services