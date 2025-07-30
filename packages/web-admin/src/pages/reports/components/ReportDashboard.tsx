import { Box, CircularProgress, Alert, Typography } from '@mui/material'
import { ReportType, ReportResponse } from '../types'
import UsageChart from './charts/UsageChart'
import ServiceChart from './charts/ServiceChart'
import PlanUtilizationChart from './charts/PlanUtilizationChart'

interface ReportDashboardProps {
  reportType: ReportType
  reportData: ReportResponse<any> | null
  loading: boolean
  error: string | null
  period: 'daily' | 'weekly' | 'monthly'
}

export default function ReportDashboard({
  reportType,
  reportData,
  loading,
  error,
  period,
}: ReportDashboardProps) {
  if (loading) {
    return (
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          minHeight: 400,
        }}
      >
        <CircularProgress />
      </Box>
    )
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 3 }}>
        {error}
      </Alert>
    )
  }

  if (!reportData) {
    return (
      <Box sx={{ textAlign: 'center', py: 8 }}>
        <Typography variant="h6" color="text.secondary">
          Selecione os filtros e clique em "Gerar Relatório" para visualizar os dados
        </Typography>
      </Box>
    )
  }

  const renderChart = () => {
    switch (reportType) {
      case ReportType.UsageByPeriod:
        return <UsageChart data={reportData.data} period={period} />

      case ReportType.TopServices:
        return <ServiceChart data={reportData.data} />

      case ReportType.PlanUtilization:
        return <PlanUtilizationChart data={reportData.data} />

      case ReportType.ClinicRanking:
      case ReportType.PatientActivity:
      case ReportType.FinancialSummary:
      case ReportType.TransactionAnalysis:
        return (
          <Alert severity="info">
            Visualização para {reportData.title} será implementada em breve.
          </Alert>
        )

      default:
        return null
    }
  }

  return (
    <Box>
      {reportData.fromCache && (
        <Alert severity="info" sx={{ mb: 2 }}>
          Dados servidos do cache. Expiram em:{' '}
          {new Date(reportData.cacheExpiresAt || '').toLocaleString('pt-BR')}
        </Alert>
      )}

      <Box sx={{ mb: 2 }}>
        <Typography variant="h5">{reportData.title}</Typography>
        <Typography variant="body2" color="text.secondary">
          {reportData.description}
        </Typography>
        <Typography variant="caption" color="text.secondary">
          Gerado em: {new Date(reportData.generatedAt).toLocaleString('pt-BR')} | Tempo de
          execução: {reportData.executionTimeMs}ms
        </Typography>
      </Box>

      {renderChart()}
    </Box>
  )
}