import { useState } from 'react'
import { useFormValidation, ValidationRules } from '@/hooks/useFormValidation'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Stack,
  Card,
  CardContent,
  Grid,
  FormControl,
  FormLabel,
  RadioGroup,
  FormControlLabel,
  Radio,
  Checkbox,
  TextField,
  Chip,
  Alert,
  Divider,
  LinearProgress,
} from '@mui/material'
import {
  Assessment as AssessmentIcon,
  Download as DownloadIcon,
  PictureAsPdf as PictureAsPdfIcon,
  TableChart as TableChartIcon,
  Description as DescriptionIcon,
  Close as CloseIcon,
  DateRange as DateRangeIcon,
  TrendingUp as TrendingUpIcon,
  Business as BusinessIcon,
  Person as PersonIcon,
} from '@mui/icons-material'
import { LoadingButton } from '@mui/lab'
import { TransactionFilters } from '@/types/transaction'
import { useExportTransactions } from '@/hooks/useTransactions'
import { useNotification } from '@/hooks/useNotification'

interface TransactionReportsModalProps {
  open: boolean
  onClose: () => void
  currentFilters?: TransactionFilters
}

interface ReportOptions {
  format: 'xlsx' | 'csv' | 'pdf'
  includeFields: string[]
  dateRange: 'current' | 'last7days' | 'last30days' | 'last3months' | 'custom'
  customStartDate?: string
  customEndDate?: string
  groupBy?: 'none' | 'clinic' | 'patient' | 'status' | 'month'
  includeSummary: boolean
  includeCharts: boolean // Only for PDF
}

const availableFields = [
  { key: 'code', label: 'Código da Transação', default: true },
  { key: 'patientName', label: 'Nome do Paciente', default: true },
  { key: 'patientEmail', label: 'Email do Paciente', default: false },
  { key: 'clinicName', label: 'Nome da Clínica', default: true },
  { key: 'planName', label: 'Nome do Plano', default: true },
  { key: 'status', label: 'Status', default: true },
  { key: 'amount', label: 'Valor', default: true },
  { key: 'creditsUsed', label: 'Créditos Utilizados', default: true },
  { key: 'serviceDescription', label: 'Descrição do Serviço', default: true },
  { key: 'serviceType', label: 'Tipo de Serviço', default: false },
  { key: 'createdAt', label: 'Data de Criação', default: true },
  { key: 'validationDate', label: 'Data de Validação', default: false },
  { key: 'validatedBy', label: 'Validado Por', default: false },
  { key: 'validationNotes', label: 'Notas de Validação', default: false },
  { key: 'cancellationDate', label: 'Data de Cancelamento', default: false },
  { key: 'cancellationReason', label: 'Motivo do Cancelamento', default: false },
  { key: 'location', label: 'Localização', default: false },
  { key: 'ipAddress', label: 'Endereço IP', default: false },
  { key: 'userAgent', label: 'User Agent', default: false },
]

export default function TransactionReportsModal({
  open,
  onClose,
  currentFilters = {},
}: TransactionReportsModalProps) {
  const exportMutation = useExportTransactions()
  const { showSuccess, showError, showInfo } = useNotification()

  const [reportOptions, setReportOptions] = useState<ReportOptions>({
    format: 'xlsx',
    includeFields: availableFields.filter(f => f.default).map(f => f.key),
    dateRange: 'current',
    customStartDate: '',
    customEndDate: '',
    groupBy: 'none',
    includeSummary: true,
    includeCharts: false,
  })

  // Form validation for custom date fields
  const dateForm = useFormValidation(
    {
      customStartDate: reportOptions.customStartDate,
      customEndDate: reportOptions.customEndDate,
    },
    {
      customStartDate: {
        custom: (value: string) => {
          if (reportOptions.dateRange === 'custom' && !value) {
            return 'Data de início é obrigatória para período personalizado'
          }
          if (value && reportOptions.customEndDate && new Date(value) >= new Date(reportOptions.customEndDate)) {
            return 'Data de início deve ser anterior à data final'
          }
          return null
        }
      },
      customEndDate: {
        custom: (value: string) => {
          if (reportOptions.dateRange === 'custom' && !value) {
            return 'Data final é obrigatória para período personalizado'
          }
          if (value && reportOptions.customStartDate && new Date(value) <= new Date(reportOptions.customStartDate)) {
            return 'Data final deve ser posterior à data inicial'
          }
          return null
        }
      }
    },
    {
      validateOnChange: true,
      validateOnBlur: true,
      debounceMs: 300
    }
  )

  const handleClose = () => {
    onClose()
  }

  const handleFieldToggle = (fieldKey: string) => {
    setReportOptions(prev => ({
      ...prev,
      includeFields: prev.includeFields.includes(fieldKey)
        ? prev.includeFields.filter(f => f !== fieldKey)
        : [...prev.includeFields, fieldKey]
    }))
  }

  const handleSelectAllFields = () => {
    setReportOptions(prev => ({
      ...prev,
      includeFields: availableFields.map(f => f.key)
    }))
  }

  const handleSelectDefaultFields = () => {
    setReportOptions(prev => ({
      ...prev,
      includeFields: availableFields.filter(f => f.default).map(f => f.key)
    }))
  }

  const buildFiltersForReport = (): TransactionFilters => {
    const filters = { ...currentFilters }
    
    // Apply date range
    const now = new Date()
    switch (reportOptions.dateRange) {
      case 'last7days':
        filters.startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
        filters.endDate = now.toISOString().split('T')[0]
        break
      case 'last30days':
        filters.startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
        filters.endDate = now.toISOString().split('T')[0]
        break
      case 'last3months':
        filters.startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
        filters.endDate = now.toISOString().split('T')[0]
        break
      case 'custom':
        if (reportOptions.customStartDate) filters.startDate = reportOptions.customStartDate
        if (reportOptions.customEndDate) filters.endDate = reportOptions.customEndDate
        break
      // 'current' uses existing filters
    }

    return filters
  }

  const handleGenerateReport = async () => {
    try {
      const filters = buildFiltersForReport()
      
      // Show info notification about generation starting
      showInfo(
        'Gerando relatório...',
        `Processando relatório em formato ${reportOptions.format.toUpperCase()} com ${reportOptions.includeFields.length} campos.`,
        {
          duration: 3000
        }
      )
      
      await exportMutation.mutateAsync({
        params: filters,
        format: reportOptions.format,
      })
      
      showSuccess(
        'Relatório gerado com sucesso!',
        `O arquivo foi baixado em formato ${reportOptions.format.toUpperCase()}. Verifique sua pasta de downloads.`,
        {
          title: 'Download Completo',
          duration: 8000,
          action: {
            label: 'Gerar Novo',
            onClick: () => {
              // Keep modal open for another report
            }
          }
        }
      )
      
      handleClose()
    } catch (error) {
      showError(
        'Erro ao gerar relatório',
        error instanceof Error ? error.message : 'Não foi possível gerar o relatório. Tente novamente.',
        {
          duration: 8000,
          action: {
            label: 'Tentar Novamente',
            onClick: () => handleGenerateReport()
          }
        }
      )
    }
  }

  const getReportPreviewInfo = () => {
    const filters = buildFiltersForReport()
    const fieldsCount = reportOptions.includeFields.length
    
    let dateRangeText = 'Período atual dos filtros'
    switch (reportOptions.dateRange) {
      case 'last7days': dateRangeText = 'Últimos 7 dias'; break
      case 'last30days': dateRangeText = 'Últimos 30 dias'; break
      case 'last3months': dateRangeText = 'Últimos 3 meses'; break
      case 'custom': 
        dateRangeText = `${reportOptions.customStartDate || 'Início'} até ${reportOptions.customEndDate || 'Hoje'}`
        break
    }

    return {
      fieldsCount,
      dateRangeText,
      hasFilters: Object.keys(filters).some(key => filters[key as keyof TransactionFilters] !== undefined && filters[key as keyof TransactionFilters] !== ''),
    }
  }

  const previewInfo = getReportPreviewInfo()

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 2, minHeight: '70vh' }
      }}
    >
      <DialogTitle>
        <Stack direction="row" alignItems="center" justifyContent="space-between">
          <Stack direction="row" alignItems="center" spacing={2}>
            <AssessmentIcon color="primary" />
            <Box>
              <Typography variant="h6" fontWeight={600}>
                Relatórios e Exportação
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Configure e exporte relatórios personalizados das transações
              </Typography>
            </Box>
          </Stack>
          
          <Button onClick={handleClose} startIcon={<CloseIcon />}>
            Fechar
          </Button>
        </Stack>
      </DialogTitle>

      <DialogContent dividers sx={{ p: 0 }}>
        <Box sx={{ p: 3 }}>
          <Grid container spacing={3}>
            {/* Format Selection */}
            <Grid item xs={12} md={4}>
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Formato do Relatório
                  </Typography>
                  
                  <FormControl component="fieldset">
                    <RadioGroup
                      value={reportOptions.format}
                      onChange={(e) => setReportOptions(prev => ({ 
                        ...prev, 
                        format: e.target.value as 'xlsx' | 'csv' | 'pdf',
                        includeCharts: e.target.value === 'pdf' ? prev.includeCharts : false
                      }))}
                    >
                      <FormControlLabel
                        value="xlsx"
                        control={<Radio />}
                        label={
                          <Stack direction="row" alignItems="center" spacing={1}>
                            <TableChartIcon color="success" />
                            <Box>
                              <Typography variant="body2">Excel (.xlsx)</Typography>
                              <Typography variant="caption" color="text.secondary">
                                Planilha com formatação
                              </Typography>
                            </Box>
                          </Stack>
                        }
                      />
                      <FormControlLabel
                        value="csv"
                        control={<Radio />}
                        label={
                          <Stack direction="row" alignItems="center" spacing={1}>
                            <DescriptionIcon color="info" />
                            <Box>
                              <Typography variant="body2">CSV (.csv)</Typography>
                              <Typography variant="caption" color="text.secondary">
                                Arquivo de texto separado por vírgula
                              </Typography>
                            </Box>
                          </Stack>
                        }
                      />
                      <FormControlLabel
                        value="pdf"
                        control={<Radio />}
                        label={
                          <Stack direction="row" alignItems="center" spacing={1}>
                            <PictureAsPdfIcon color="error" />
                            <Box>
                              <Typography variant="body2">PDF (.pdf)</Typography>
                              <Typography variant="caption" color="text.secondary">
                                Documento formatado para impressão
                              </Typography>
                            </Box>
                          </Stack>
                        }
                      />
                    </RadioGroup>
                  </FormControl>

                  {reportOptions.format === 'pdf' && (
                    <Box mt={2}>
                      <FormControlLabel
                        control={
                          <Checkbox
                            checked={reportOptions.includeCharts}
                            onChange={(e) => setReportOptions(prev => ({ 
                              ...prev, 
                              includeCharts: e.target.checked 
                            }))}
                          />
                        }
                        label="Incluir gráficos e estatísticas"
                      />
                    </Box>
                  )}
                </CardContent>
              </Card>
            </Grid>

            {/* Date Range Selection */}
            <Grid item xs={12} md={8}>
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Período dos Dados
                  </Typography>

                  <FormControl component="fieldset" sx={{ mb: 2 }}>
                    <RadioGroup
                      value={reportOptions.dateRange}
                      onChange={(e) => setReportOptions(prev => ({ 
                        ...prev, 
                        dateRange: e.target.value as ReportOptions['dateRange']
                      }))}
                    >
                      <Grid container spacing={1}>
                        <Grid item xs={12} sm={6}>
                          <FormControlLabel
                            value="current"
                            control={<Radio />}
                            label="Filtros atuais da página"
                          />
                          <FormControlLabel
                            value="last7days"
                            control={<Radio />}
                            label="Últimos 7 dias"
                          />
                        </Grid>
                        <Grid item xs={12} sm={6}>
                          <FormControlLabel
                            value="last30days"
                            control={<Radio />}
                            label="Últimos 30 dias"
                          />
                          <FormControlLabel
                            value="last3months"
                            control={<Radio />}
                            label="Últimos 3 meses"
                          />
                        </Grid>
                        <Grid item xs={12}>
                          <FormControlLabel
                            value="custom"
                            control={<Radio />}
                            label="Período personalizado"
                          />
                        </Grid>
                      </Grid>
                    </RadioGroup>
                  </FormControl>

                  {reportOptions.dateRange === 'custom' && (
                    <Stack direction="row" spacing={2}>
                      <TextField
                        label="Data Início"
                        type="date"
                        value={reportOptions.customStartDate || ''}
                        onChange={(e) => {
                          setReportOptions(prev => ({ 
                            ...prev, 
                            customStartDate: e.target.value 
                          }))
                          dateForm.setValue('customStartDate', e.target.value)
                        }}
                        onBlur={() => dateForm.setFieldTouched('customStartDate')}
                        error={dateForm.touched.customStartDate && !!dateForm.errors.customStartDate}
                        helperText={dateForm.touched.customStartDate ? dateForm.errors.customStartDate : 'Selecione a data de início do período'}
                        InputLabelProps={{ shrink: true }}
                        fullWidth
                      />
                      <TextField
                        label="Data Fim"
                        type="date"
                        value={reportOptions.customEndDate || ''}
                        onChange={(e) => {
                          setReportOptions(prev => ({ 
                            ...prev, 
                            customEndDate: e.target.value 
                          }))
                          dateForm.setValue('customEndDate', e.target.value)
                        }}
                        onBlur={() => dateForm.setFieldTouched('customEndDate')}
                        error={dateForm.touched.customEndDate && !!dateForm.errors.customEndDate}
                        helperText={dateForm.touched.customEndDate ? dateForm.errors.customEndDate : 'Selecione a data final do período'}
                        InputLabelProps={{ shrink: true }}
                        fullWidth
                      />
                    </Stack>
                  )}
                </CardContent>
              </Card>
            </Grid>

            {/* Fields Selection */}
            <Grid item xs={12}>
              <Card variant="outlined">
                <CardContent>
                  <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
                    <Typography variant="h6">
                      Campos do Relatório ({reportOptions.includeFields.length} selecionados)
                    </Typography>
                    
                    <Stack direction="row" spacing={1}>
                      <Button
                        size="small"
                        variant="outlined"
                        onClick={handleSelectDefaultFields}
                      >
                        Campos Padrão
                      </Button>
                      <Button
                        size="small"
                        variant="outlined"
                        onClick={handleSelectAllFields}
                      >
                        Selecionar Todos
                      </Button>
                    </Stack>
                  </Stack>

                  <Grid container spacing={1}>
                    {availableFields.map((field) => (
                      <Grid item xs={12} sm={6} md={4} key={field.key}>
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={reportOptions.includeFields.includes(field.key)}
                              onChange={() => handleFieldToggle(field.key)}
                            />
                          }
                          label={
                            <Box>
                              <Typography variant="body2">
                                {field.label}
                              </Typography>
                              {field.default && (
                                <Chip label="Padrão" size="small" color="primary" sx={{ ml: 1 }} />
                              )}
                            </Box>
                          }
                        />
                      </Grid>
                    ))}
                  </Grid>
                </CardContent>
              </Card>
            </Grid>

            {/* Additional Options */}
            <Grid item xs={12}>
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Opções Adicionais
                  </Typography>

                  <Stack spacing={2}>
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={reportOptions.includeSummary}
                          onChange={(e) => setReportOptions(prev => ({ 
                            ...prev, 
                            includeSummary: e.target.checked 
                          }))}
                        />
                      }
                      label="Incluir resumo estatístico"
                    />

                    <FormControl component="fieldset">
                      <FormLabel component="legend">Agrupar dados por:</FormLabel>
                      <RadioGroup
                        row
                        value={reportOptions.groupBy}
                        onChange={(e) => setReportOptions(prev => ({ 
                          ...prev, 
                          groupBy: e.target.value as ReportOptions['groupBy']
                        }))}
                      >
                        <FormControlLabel value="none" control={<Radio />} label="Sem agrupamento" />
                        <FormControlLabel value="clinic" control={<Radio />} label="Clínica" />
                        <FormControlLabel value="patient" control={<Radio />} label="Paciente" />
                        <FormControlLabel value="status" control={<Radio />} label="Status" />
                        <FormControlLabel value="month" control={<Radio />} label="Mês" />
                      </RadioGroup>
                    </FormControl>
                  </Stack>
                </CardContent>
              </Card>
            </Grid>

            {/* Preview Information */}
            <Grid item xs={12}>
              <Alert severity="info" sx={{ mb: 2 }}>
                <Typography variant="subtitle2" gutterBottom>
                  Prévia do Relatório
                </Typography>
                <Stack spacing={1}>
                  <Typography variant="body2">
                    📄 <strong>Formato:</strong> {reportOptions.format.toUpperCase()}
                  </Typography>
                  <Typography variant="body2">
                    📅 <strong>Período:</strong> {previewInfo.dateRangeText}
                  </Typography>
                  <Typography variant="body2">
                    📊 <strong>Campos:</strong> {previewInfo.fieldsCount} campos selecionados
                  </Typography>
                  {previewInfo.hasFilters && (
                    <Typography variant="body2">
                      🔍 <strong>Filtros:</strong> Relatório será aplicado com os filtros configurados
                    </Typography>
                  )}
                  {reportOptions.includeSummary && (
                    <Typography variant="body2">
                      📈 <strong>Resumo:</strong> Estatísticas serão incluídas
                    </Typography>
                  )}
                  {reportOptions.groupBy !== 'none' && (
                    <Typography variant="body2">
                      📋 <strong>Agrupamento:</strong> Dados agrupados por {reportOptions.groupBy}
                    </Typography>
                  )}
                </Stack>
              </Alert>
            </Grid>
          </Grid>
        </Box>
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={handleClose} disabled={exportMutation.isPending}>
          Cancelar
        </Button>
        
        <LoadingButton
          onClick={handleGenerateReport}
          loading={exportMutation.isPending}
          variant="contained"
          startIcon={<DownloadIcon />}
          disabled={
            reportOptions.includeFields.length === 0 ||
            (reportOptions.dateRange === 'custom' && !dateForm.isValid)
          }
          loadingPosition="start"
        >
          {exportMutation.isPending ? 'Gerando Relatório...' : 'Gerar Relatório'}
        </LoadingButton>
      </DialogActions>

      {exportMutation.isPending && (
        <LinearProgress sx={{ position: 'absolute', bottom: 0, left: 0, right: 0 }} />
      )}
    </Dialog>
  )
}