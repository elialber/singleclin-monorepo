import { Container, Typography, Box } from '@mui/material'
import ReportFilters from './components/ReportFilters'
import ReportDashboard from './components/ReportDashboard'
import { useReports } from './hooks/useReports'
import { useReportMetadata } from './hooks/useReportMetadata'
import { ReportPeriod } from './types'

export default function Reports() {
  const {
    filters,
    setFilters,
    reportData,
    loading,
    error,
    generateReport,
    exportReport,
  } = useReports()

  const { clinics, plans, serviceTypes, loading: metadataLoading } = useReportMetadata()

  const getPeriodForChart = (): 'daily' | 'weekly' | 'monthly' => {
    switch (filters.period) {
      case ReportPeriod.Daily:
        return 'daily'
      case ReportPeriod.Weekly:
        return 'weekly'
      case ReportPeriod.Monthly:
      case ReportPeriod.Quarterly:
      case ReportPeriod.Yearly:
      default:
        return 'monthly'
    }
  }

  return (
    <Container maxWidth="xl">
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Relatórios e Analytics
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Visualize relatórios detalhados e análises do sistema com gráficos interativos
        </Typography>
      </Box>

      <ReportFilters
        filters={filters}
        onFiltersChange={setFilters}
        onGenerateReport={generateReport}
        onExportReport={exportReport}
        loading={loading || metadataLoading}
        clinics={clinics}
        plans={plans}
        services={serviceTypes}
      />

      <ReportDashboard
        reportType={filters.reportType}
        reportData={reportData}
        loading={loading}
        error={error}
        period={getPeriodForChart()}
      />
    </Container>
  )
}