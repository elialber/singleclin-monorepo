import React from 'react'
import {
  Box,
  Paper,
  MenuItem,
  Button,
  Grid,
  FormControl,
  InputLabel,
  Select,
  SelectChangeEvent,
  Chip,
  OutlinedInput,
} from '@mui/material'
import { DatePicker } from '@mui/x-date-pickers/DatePicker'
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider'
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns'
import { ptBR } from 'date-fns/locale'
import { ReportType, ReportPeriod } from '../types'

interface ReportFiltersProps {
  filters: {
    reportType: ReportType
    period: ReportPeriod
    startDate: Date | null
    endDate: Date | null
    clinicIds: string[]
    planIds: string[]
    serviceTypes: string[]
  }
  onFiltersChange: (filters: any) => void
  onGenerateReport: () => void
  onExportReport: (format: 'excel' | 'pdf') => void
  loading?: boolean
  clinics?: Array<{ id: string; name: string }>
  plans?: Array<{ id: string; name: string }>
  services?: string[]
}

const reportTypes = [
  { value: ReportType.UsageByPeriod, label: 'Uso por Período' },
  { value: ReportType.ClinicRanking, label: 'Ranking de Clínicas' },
  { value: ReportType.TopServices, label: 'Top Serviços' },
  { value: ReportType.PlanUtilization, label: 'Utilização de Planos' },
  { value: ReportType.PatientActivity, label: 'Atividade de Pacientes' },
  { value: ReportType.FinancialSummary, label: 'Resumo Financeiro' },
  { value: ReportType.TransactionAnalysis, label: 'Análise de Transações' },
]

const periods = [
  { value: ReportPeriod.Daily, label: 'Diário' },
  { value: ReportPeriod.Weekly, label: 'Semanal' },
  { value: ReportPeriod.Monthly, label: 'Mensal' },
  { value: ReportPeriod.Quarterly, label: 'Trimestral' },
  { value: ReportPeriod.Yearly, label: 'Anual' },
]

export default function ReportFilters({
  filters,
  onFiltersChange,
  onGenerateReport,
  onExportReport,
  loading = false,
  clinics = [],
  plans = [],
  services = [],
}: ReportFiltersProps) {
  const handleChange = (field: string) => (
    event: React.ChangeEvent<HTMLInputElement> | SelectChangeEvent<any>
  ) => {
    onFiltersChange({
      ...filters,
      [field]: event.target.value,
    })
  }

  const handleDateChange = (field: string) => (date: Date | null) => {
    onFiltersChange({
      ...filters,
      [field]: date,
    })
  }

  const handleMultiSelectChange = (field: string) => (
    event: SelectChangeEvent<string[]>
  ) => {
    const value = event.target.value
    onFiltersChange({
      ...filters,
      [field]: typeof value === 'string' ? value.split(',') : value,
    })
  }

  return (
    <Paper sx={{ p: 3, mb: 3 }}>
      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <FormControl fullWidth>
            <InputLabel>Tipo de Relatório</InputLabel>
            <Select
              value={filters.reportType}
              onChange={handleChange('reportType')}
              label="Tipo de Relatório"
            >
              {reportTypes.map((type) => (
                <MenuItem key={type.value} value={type.value}>
                  {type.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Grid>

        <Grid item xs={12} md={4}>
          <FormControl fullWidth>
            <InputLabel>Período</InputLabel>
            <Select
              value={filters.period}
              onChange={handleChange('period')}
              label="Período"
            >
              {periods.map((period) => (
                <MenuItem key={period.value} value={period.value}>
                  {period.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Grid>

        <Grid item xs={12} md={4}>
          <LocalizationProvider dateAdapter={AdapterDateFns} adapterLocale={ptBR}>
            <DatePicker
              label="Data Início"
              value={filters.startDate}
              onChange={handleDateChange('startDate')}
              slotProps={{ textField: { fullWidth: true } }}
            />
          </LocalizationProvider>
        </Grid>

        <Grid item xs={12} md={4}>
          <LocalizationProvider dateAdapter={AdapterDateFns} adapterLocale={ptBR}>
            <DatePicker
              label="Data Fim"
              value={filters.endDate}
              onChange={handleDateChange('endDate')}
              slotProps={{ textField: { fullWidth: true } }}
            />
          </LocalizationProvider>
        </Grid>

        {filters.reportType !== ReportType.ClinicRanking && (
          <Grid item xs={12} md={4}>
            <FormControl fullWidth>
              <InputLabel>Clínicas</InputLabel>
              <Select
                multiple
                value={filters.clinicIds}
                onChange={handleMultiSelectChange('clinicIds')}
                input={<OutlinedInput label="Clínicas" />}
                renderValue={(selected) => (
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                    {selected.map((value) => {
                      const clinic = clinics.find((c) => c.id === value)
                      return <Chip key={value} label={clinic?.name || value} size="small" />
                    })}
                  </Box>
                )}
              >
                {clinics.map((clinic) => (
                  <MenuItem key={clinic.id} value={clinic.id}>
                    {clinic.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
        )}

        {(filters.reportType === ReportType.PlanUtilization ||
          filters.reportType === ReportType.PatientActivity) && (
          <Grid item xs={12} md={4}>
            <FormControl fullWidth>
              <InputLabel>Planos</InputLabel>
              <Select
                multiple
                value={filters.planIds}
                onChange={handleMultiSelectChange('planIds')}
                input={<OutlinedInput label="Planos" />}
                renderValue={(selected) => (
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                    {selected.map((value) => {
                      const plan = plans.find((p) => p.id === value)
                      return <Chip key={value} label={plan?.name || value} size="small" />
                    })}
                  </Box>
                )}
              >
                {plans.map((plan) => (
                  <MenuItem key={plan.id} value={plan.id}>
                    {plan.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
        )}

        {filters.reportType === ReportType.TopServices && (
          <Grid item xs={12} md={4}>
            <FormControl fullWidth>
              <InputLabel>Tipos de Serviço</InputLabel>
              <Select
                multiple
                value={filters.serviceTypes}
                onChange={handleMultiSelectChange('serviceTypes')}
                input={<OutlinedInput label="Tipos de Serviço" />}
                renderValue={(selected) => (
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                    {selected.map((value) => (
                      <Chip key={value} label={value} size="small" />
                    ))}
                  </Box>
                )}
              >
                {services.map((service) => (
                  <MenuItem key={service} value={service}>
                    {service}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
        )}

        <Grid item xs={12}>
          <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
            <Button
              variant="contained"
              onClick={onGenerateReport}
              disabled={loading || !filters.startDate || !filters.endDate}
            >
              Gerar Relatório
            </Button>
            <Button
              variant="outlined"
              onClick={() => onExportReport('excel')}
              disabled={loading}
            >
              Exportar Excel
            </Button>
            <Button
              variant="outlined"
              onClick={() => onExportReport('pdf')}
              disabled={loading}
            >
              Exportar PDF
            </Button>
          </Box>
        </Grid>
      </Grid>
    </Paper>
  )
}