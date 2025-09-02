import { useMemo, useCallback, memo } from 'react'
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Stack,
  Chip,
  Avatar,
  LinearProgress,
  Divider,
  Paper,
  IconButton,
  Tooltip,
  useTheme,
  useMediaQuery,
  Container,
} from '@mui/material'
import {
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  AttachMoney as AttachMoneyIcon,
  CreditCard as CreditCardIcon,
  Business as BusinessIcon,
  Person as PersonIcon,
  Assessment as AssessmentIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material'
import { DashboardMetrics } from '@/types/transaction'
import { format, parseISO, subMonths } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import { DashboardMetricsSkeleton } from '@/components/SkeletonLoader'

interface TransactionDashboardProps {
  metrics?: DashboardMetrics
  loading?: boolean
  onRefresh?: () => void
}

const TransactionDashboard = memo(function TransactionDashboard({
  metrics,
  loading = false,
  onRefresh,
}: TransactionDashboardProps) {
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'))
  const isTablet = useMediaQuery(theme.breakpoints.down('md'))
  // Mock data for development when metrics are not available
  const mockMetrics: DashboardMetrics = useMemo(() => ({
    totalTransactions: 1247,
    totalRevenue: 186750.50,
    transactionsThisMonth: 89,
    revenueThisMonth: 12450.00,
    activePatients: 456,
    activeClinics: 23,
    activePlans: 12,
    averageTransactionAmount: 149.80,
    averageCreditsPerTransaction: 2.3,
    mostUsedPlan: {
      id: '1',
      name: 'Plano Básico',
      transactionCount: 456,
      totalRevenue: 68400.00,
    },
    topClinic: {
      id: '1', 
      name: 'Clínica Saúde Total',
      transactionCount: 234,
      totalRevenue: 35100.00,
    },
    statusDistribution: [
      { status: 'Validated', count: 1089, percentage: 87.3 },
      { status: 'Pending', count: 89, percentage: 7.1 },
      { status: 'Cancelled', count: 45, percentage: 3.6 },
      { status: 'Expired', count: 24, percentage: 1.9 },
    ],
    monthlyTrends: [
      { month: '2024-03', transactionCount: 78, revenue: 11670.00, creditsUsed: 179 },
      { month: '2024-04', transactionCount: 92, revenue: 13800.00, creditsUsed: 211 },
      { month: '2024-05', transactionCount: 105, revenue: 15750.00, creditsUsed: 241 },
      { month: '2024-06', transactionCount: 89, revenue: 13350.00, creditsUsed: 205 },
      { month: '2024-07', transactionCount: 134, revenue: 20100.00, creditsUsed: 308 },
      { month: '2024-08', transactionCount: 156, revenue: 23400.00, creditsUsed: 358 },
    ]
  }), [])

  const displayMetrics = metrics || mockMetrics

  // Calculate trends and growth
  const monthlyGrowth = useMemo(() => {
    if (!displayMetrics.monthlyTrends || displayMetrics.monthlyTrends.length < 2) {
      return { revenue: 0, transactions: 0, credits: 0 }
    }
    
    const trends = displayMetrics.monthlyTrends
    const current = trends[trends.length - 1]
    const previous = trends[trends.length - 2]
    
    return {
      revenue: ((current.revenue - previous.revenue) / previous.revenue) * 100,
      transactions: ((current.transactionCount - previous.transactionCount) / previous.transactionCount) * 100,
      credits: ((current.creditsUsed - previous.creditsUsed) / previous.creditsUsed) * 100,
    }
  }, [displayMetrics.monthlyTrends])

  const MetricCard = useMemo(() => memo(({ 
    title, 
    value, 
    subtitle, 
    icon, 
    color = 'primary',
    trend,
    loading: cardLoading = false 
  }: {
    title: string
    value: string | number
    subtitle?: string
    icon: React.ReactNode
    color?: 'primary' | 'secondary' | 'success' | 'warning' | 'error'
    trend?: number
    loading?: boolean
  }) => (
    <Card 
      elevation={2} 
      sx={{ 
        height: '100%',
        transition: 'all 0.2s ease',
        '&:hover': {
          transform: 'translateY(-2px)',
          boxShadow: theme.shadows[4]
        }
      }}
    >
      <CardContent sx={{ p: isMobile ? 2 : 3 }}>
        <Stack 
          direction={isMobile ? "column" : "row"} 
          alignItems={isMobile ? "center" : "flex-start"} 
          justifyContent="space-between"
          spacing={isMobile ? 1 : 0}
          textAlign={isMobile ? "center" : "left"}
        >
          <Box>
            <Typography 
              variant={isMobile ? "caption" : "body2"} 
              color="text.secondary" 
              gutterBottom
              sx={{ fontSize: isMobile ? '0.75rem' : undefined }}
            >
              {title}
            </Typography>
            {cardLoading ? (
              <Box sx={{ width: 120, height: 32, bgcolor: 'grey.200', borderRadius: 1 }} />
            ) : (
              <Typography 
                variant={isMobile ? "h5" : "h4"} 
                fontWeight={700} 
                color={`${color}.main`} 
                gutterBottom
                sx={{ 
                  fontSize: isMobile ? '1.5rem' : undefined,
                  wordBreak: 'break-word'
                }}
              >
                {value}
              </Typography>
            )}
            {subtitle && (
              <Typography 
                variant={isMobile ? "caption" : "body2"} 
                color="text.secondary"
                sx={{ fontSize: isMobile ? '0.7rem' : undefined }}
              >
                {subtitle}
              </Typography>
            )}
          </Box>
          
          <Avatar sx={{ 
            bgcolor: `${color}.light`, 
            color: `${color}.main`,
            width: isMobile ? 32 : 40,
            height: isMobile ? 32 : 40,
            '& .MuiSvgIcon-root': {
              fontSize: isMobile ? '1rem' : '1.25rem'
            }
          }}>
            {icon}
          </Avatar>
        </Stack>
        
        {trend !== undefined && (
          <Stack 
            direction="row" 
            alignItems="center" 
            justifyContent={isMobile ? "center" : "flex-start"}
            spacing={0.5} 
            mt={2}
          >
            {trend >= 0 ? (
              <TrendingUpIcon fontSize="small" color="success" />
            ) : (
              <TrendingDownIcon fontSize="small" color="error" />
            )}
            <Typography 
              variant="caption" 
              color={trend >= 0 ? 'success.main' : 'error.main'}
              fontWeight={500}
              sx={{ fontSize: isMobile ? '0.65rem' : undefined }}
            >
              {Math.abs(trend).toFixed(1)}% vs mês anterior
            </Typography>
          </Stack>
        )}
      </CardContent>
    </Card>
  )), [])

  const StatusChart = useCallback(() => (
    <Card elevation={2}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Distribuição por Status
        </Typography>
        
        <Stack spacing={2}>
          {displayMetrics.statusDistribution.map((status) => (
            <Box key={status.status}>
              <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
                <Typography variant="body2">
                  {status.status === 'Validated' ? 'Validadas' :
                   status.status === 'Pending' ? 'Pendentes' :
                   status.status === 'Cancelled' ? 'Canceladas' : 'Expiradas'}
                </Typography>
                <Typography variant="body2" fontWeight={500}>
                  {status.count} ({status.percentage.toFixed(1)}%)
                </Typography>
              </Stack>
              
              <LinearProgress
                variant="determinate"
                value={status.percentage}
                sx={{
                  height: 8,
                  borderRadius: 4,
                  bgcolor: 'grey.200',
                  '& .MuiLinearProgress-bar': {
                    bgcolor: 
                      status.status === 'Validated' ? 'success.main' :
                      status.status === 'Pending' ? 'warning.main' :
                      status.status === 'Cancelled' ? 'error.main' : 'grey.500',
                    borderRadius: 4,
                  }
                }}
              />
            </Box>
          ))}
        </Stack>
      </CardContent>
    </Card>
  ), [displayMetrics.statusDistribution])

  const TrendsChart = useCallback(() => (
    <Card elevation={2}>
      <CardContent sx={{ p: isMobile ? 2 : 3 }}>
        <Stack 
          direction={isMobile ? "column" : "row"} 
          justifyContent="space-between" 
          alignItems={isMobile ? "flex-start" : "center"} 
          spacing={isMobile ? 1 : 0}
          mb={2}
        >
          <Typography variant="h6">
            Tendências (6 meses)
          </Typography>
          
          {onRefresh && (
            <Tooltip title="Atualizar dados">
              <IconButton size="small" onClick={onRefresh} disabled={loading}>
                <RefreshIcon />
              </IconButton>
            </Tooltip>
          )}
        </Stack>
        
        {loading ? (
          <Box sx={{ height: 200, bgcolor: 'grey.100', borderRadius: 1 }} />
        ) : (
          <Box>
            {/* Simple bar chart representation */}
            <Stack spacing={2}>
              {displayMetrics.monthlyTrends.slice(-6).map((month, index) => {
                const maxRevenue = Math.max(...displayMetrics.monthlyTrends.map(m => m.revenue))
                const percentage = (month.revenue / maxRevenue) * 100
                
                return (
                  <Box key={month.month}>
                    <Stack direction="row" justifyContent="space-between" alignItems="center" mb={0.5}>
                      <Typography variant="body2">
                        {format(parseISO(`${month.month}-01`), 'MMM yyyy', { locale: ptBR })}
                      </Typography>
                      <Typography variant="body2" fontWeight={500}>
                        R$ {month.revenue.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
                      </Typography>
                    </Stack>
                    
                    <LinearProgress
                      variant="determinate"
                      value={percentage}
                      sx={{
                        height: 6,
                        borderRadius: 3,
                        bgcolor: 'grey.200',
                        '& .MuiLinearProgress-bar': {
                          bgcolor: 'primary.main',
                          borderRadius: 3,
                        }
                      }}
                    />
                    
                    <Typography variant="caption" color="text.secondary">
                      {month.transactionCount} transações • {month.creditsUsed} créditos
                    </Typography>
                  </Box>
                )
              })}
            </Stack>
          </Box>
        )}
      </CardContent>
    </Card>
  ), [displayMetrics.monthlyTrends, loading, onRefresh])

  const TopPerformers = useCallback(() => (
    <Card elevation={2}>
      <CardContent sx={{ p: isMobile ? 2 : 3 }}>
        <Typography variant="h6" gutterBottom>
          Top Performers
        </Typography>
        
        <Stack spacing={2}>
          {/* Most Used Plan */}
          <Box>
            <Typography variant="subtitle2" color="primary" gutterBottom>
              Plano Mais Usado
            </Typography>
            <Paper sx={{ 
              p: isMobile ? 1.5 : 2, 
              bgcolor: 'primary.light', 
              color: 'primary.contrastText',
              borderRadius: 2
            }}>
              <Typography variant="body1" fontWeight={600}>
                {displayMetrics.mostUsedPlan?.name}
              </Typography>
              <Typography variant="body2">
                {displayMetrics.mostUsedPlan?.transactionCount} transações
              </Typography>
              <Typography variant="body2">
                R$ {displayMetrics.mostUsedPlan?.totalRevenue.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
              </Typography>
            </Paper>
          </Box>

          <Divider />

          {/* Top Clinic */}
          <Box>
            <Typography variant="subtitle2" color="secondary" gutterBottom>
              Clínica Top
            </Typography>
            <Paper sx={{ 
              p: isMobile ? 1.5 : 2, 
              bgcolor: 'secondary.light', 
              color: 'secondary.contrastText',
              borderRadius: 2
            }}>
              <Typography variant="body1" fontWeight={600}>
                {displayMetrics.topClinic?.name}
              </Typography>
              <Typography variant="body2">
                {displayMetrics.topClinic?.transactionCount} transações
              </Typography>
              <Typography variant="body2">
                R$ {displayMetrics.topClinic?.totalRevenue.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
              </Typography>
            </Paper>
          </Box>
        </Stack>
      </CardContent>
    </Card>
  ), [displayMetrics.mostUsedPlan, displayMetrics.topClinic])

  if (loading) {
    return (
      <Box>
        <Typography variant="h5" gutterBottom>
          Dashboard de Métricas
        </Typography>
        <DashboardMetricsSkeleton />
      </Box>
    )
  }

  return (
    <Container maxWidth={false} disableGutters={isMobile} sx={{ p: isMobile ? 1 : 0 }}>
      <Stack 
        direction={isMobile ? "column" : "row"} 
        justifyContent="space-between" 
        alignItems={isMobile ? "flex-start" : "center"} 
        spacing={isMobile ? 2 : 0}
        mb={3}
      >
        <Typography 
          variant={isMobile ? "h6" : "h5"} 
          fontWeight={600}
          sx={{ fontSize: isMobile ? '1.25rem' : undefined }}
        >
          Dashboard de Métricas
        </Typography>
        
        <Stack direction="row" spacing={1} flexWrap="wrap">
          <Chip 
            icon={<AssessmentIcon />}
            label={`${displayMetrics.totalTransactions} transações`}
            color="primary"
            variant="outlined"
          />
          {!metrics && (
            <Chip 
              label="Dados simulados"
              color="warning"
              size="small"
            />
          )}
        </Stack>
      </Stack>

      <Grid container spacing={isMobile ? 2 : 3}>
        {/* Main Metrics - Mobile: 1 per row, Tablet: 2 per row, Desktop: 4 per row */}
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Receita Total"
            value={`R$ ${displayMetrics.totalRevenue.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`}
            subtitle="Todos os tempos"
            icon={<AttachMoneyIcon />}
            color="success"
            trend={monthlyGrowth.revenue}
            loading={loading}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Transações"
            value={displayMetrics.totalTransactions.toLocaleString('pt-BR')}
            subtitle={`${displayMetrics.transactionsThisMonth} este mês`}
            icon={<CreditCardIcon />}
            color="primary"
            trend={monthlyGrowth.transactions}
            loading={loading}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Pacientes Ativos"
            value={displayMetrics.activePatients.toLocaleString('pt-BR')}
            subtitle="Com transações"
            icon={<PersonIcon />}
            color="secondary"
            loading={loading}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Clínicas Ativas"
            value={displayMetrics.activeClinics.toLocaleString('pt-BR')}
            subtitle={`${displayMetrics.activePlans} planos ativos`}
            icon={<BusinessIcon />}
            color="warning"
            loading={loading}
          />
        </Grid>

        {/* Additional Metrics - Mobile: 1 per row, Tablet: 2 per row, Desktop: 4 per row */}
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Valor Médio"
            value={`R$ ${displayMetrics.averageTransactionAmount.toFixed(2)}`}
            subtitle="Por transação"
            icon={<AttachMoneyIcon />}
            color="success"
            loading={loading}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Créditos Médios"
            value={displayMetrics.averageCreditsPerTransaction.toFixed(1)}
            subtitle="Por transação"
            icon={<CreditCardIcon />}
            color="primary"
            loading={loading}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Receita Mensal"
            value={`R$ ${displayMetrics.revenueThisMonth.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`}
            subtitle="Mês atual"
            icon={<TrendingUpIcon />}
            color="success"
            trend={monthlyGrowth.revenue}
            loading={loading}
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Taxa de Sucesso"
            value={`${displayMetrics.statusDistribution.find(s => s.status === 'Validated')?.percentage.toFixed(1) || 0}%`}
            subtitle="Transações validadas"
            icon={<AssessmentIcon />}
            color="success"
            loading={loading}
          />
        </Grid>

        {/* Charts Row - Mobile: Full width, Desktop: 8/12 */}
        <Grid item xs={12} md={8}>
          <TrendsChart />
        </Grid>

        {/* Status Chart - Mobile: Full width, Desktop: 4/12 */}
        <Grid item xs={12} md={4}>
          <StatusChart />
        </Grid>

        {/* Top Performers */}
        <Grid item xs={12}>
          <TopPerformers />
        </Grid>
      </Grid>
    </Container>
  )
})

export default TransactionDashboard