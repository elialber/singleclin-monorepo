import { useState, useEffect } from 'react'
import { 
  Grid, 
  Paper, 
  Box, 
  Typography, 
  Card, 
  CardContent,
  List,
  ListItem,
  ListItemText,
  Alert,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material'
import {
  People as PeopleIcon,
  LocalHospital as LocalHospitalIcon,
  Receipt as ReceiptIcon,
  TrendingUp as TrendingUpIcon,
  MedicalServices as MedicalServicesIcon,
  AttachMoney as AttachMoneyIcon,
} from '@mui/icons-material'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
} from 'recharts'
import { DashboardMetrics, ChartData } from '@/types/transaction'
import { dashboardService } from '@/services/dashboard.service'
import { useNotification } from '@/contexts/NotificationContext'
import MetricCard from '@/components/MetricCard'
import ChartSkeleton from '@/components/ChartSkeleton'

const COLORS = ['#1976d2', '#dc004e', '#ed6c02', '#2e7d32', '#9c27b0', '#f57c00']

export default function Dashboard() {
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null)
  const [chartData, setChartData] = useState<ChartData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [period, setPeriod] = useState<'week' | 'month' | 'year'>('month')
  
  const { showError } = useNotification()

  useEffect(() => {
    loadDashboardData()
  }, [period])

  const loadDashboardData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const [metricsData, chartsData] = await Promise.all([
        dashboardService.getMetrics(),
        dashboardService.getChartData(period)
      ])
      
      setMetrics(metricsData)
      setChartData(chartsData)
    } catch (err: any) {
      console.error('Error loading dashboard data:', err)
      setError('Erro ao carregar dados do dashboard')
      showError('Erro ao carregar dados do dashboard')
    } finally {
      setLoading(false)
    }
  }

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value)
  }

  const formatNumber = (value: number) => {
    return new Intl.NumberFormat('pt-BR').format(value)
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h4" fontWeight={600} gutterBottom>
            Dashboard
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Bem-vindo ao painel administrativo do SingleClin
          </Typography>
        </Box>
        <FormControl sx={{ minWidth: 120 }}>
          <InputLabel>Período</InputLabel>
          <Select
            value={period}
            onChange={(e) => setPeriod(e.target.value as any)}
            label="Período"
          >
            <MenuItem value="week">Semana</MenuItem>
            <MenuItem value="month">Mês</MenuItem>
            <MenuItem value="year">Ano</MenuItem>
          </Select>
        </FormControl>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Metrics Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Total de Pacientes"
            value={metrics ? formatNumber(metrics.totalPatients) : ''}
            icon={<PeopleIcon />}
            loading={loading}
            color="primary"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Total de Transações"
            value={metrics ? formatNumber(metrics.totalTransactions) : ''}
            subtitle={metrics ? `${formatNumber(metrics.transactionsThisMonth)} este mês` : ''}
            icon={<ReceiptIcon />}
            loading={loading}
            color="info"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Receita Total"
            value={metrics ? formatCurrency(metrics.totalRevenue) : ''}
            subtitle={metrics ? `${formatCurrency(metrics.revenueThisMonth)} este mês` : ''}
            icon={<AttachMoneyIcon />}
            loading={loading}
            color="success"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <MetricCard
            title="Planos Ativos"
            value={metrics ? formatNumber(metrics.activePlans) : ''}
            subtitle={metrics?.mostUsedPlan ? `Mais usado: ${metrics.mostUsedPlan.name}` : ''}
            icon={<MedicalServicesIcon />}
            loading={loading}
            color="warning"
          />
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={8}>
          {loading ? (
            <ChartSkeleton title="Transações por Dia" height={350} />
          ) : (
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Transações por Dia
                </Typography>
                <Box sx={{ height: 350 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={chartData?.transactionsByDay || []}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis 
                        dataKey="date" 
                        tickFormatter={(value) => new Date(value).toLocaleDateString('pt-BR', { 
                          month: 'short', 
                          day: 'numeric' 
                        })}
                      />
                      <YAxis />
                      <Tooltip 
                        labelFormatter={(value) => new Date(value).toLocaleDateString('pt-BR')}
                        formatter={[
                          (value: number, name: string) => [
                            name === 'count' ? formatNumber(value) : formatCurrency(value),
                            name === 'count' ? 'Transações' : 'Valor'
                          ]
                        ]}
                      />
                      <Line 
                        type="monotone" 
                        dataKey="count" 
                        stroke="#1976d2" 
                        strokeWidth={2}
                        dot={{ fill: '#1976d2' }}
                      />
                      <Line 
                        type="monotone" 
                        dataKey="amount" 
                        stroke="#2e7d32" 
                        strokeWidth={2}
                        dot={{ fill: '#2e7d32' }}
                        yAxisId="right"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </Box>
              </CardContent>
            </Card>
          )}
        </Grid>
        
        <Grid item xs={12} md={4}>
          {loading ? (
            <ChartSkeleton title="Distribuição por Plano" height={350} />
          ) : (
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Distribuição por Plano
                </Typography>
                <Box sx={{ height: 350 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={chartData?.transactionsByPlan || []}
                        cx="50%"
                        cy="50%"
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="count"
                        label={({ planName, percentage }) => `${planName} (${percentage}%)`}
                      >
                        {chartData?.transactionsByPlan?.map((_, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(value: number) => [formatNumber(value), 'Transações']} />
                    </PieChart>
                  </ResponsiveContainer>
                </Box>
              </CardContent>
            </Card>
          )}
        </Grid>
      </Grid>

      {/* Top Clinics */}
      <Grid container spacing={3}>
        <Grid item xs={12}>
          {loading ? (
            <ChartSkeleton title="Top 10 Clínicas" height={400} />
          ) : (
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Top 10 Clínicas
                </Typography>
                <Box sx={{ height: 400 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart 
                      data={chartData?.topClinics?.slice(0, 10) || []}
                      margin={{ top: 20, right: 30, left: 20, bottom: 60 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis 
                        dataKey="clinicName" 
                        angle={-45}
                        textAnchor="end"
                        height={100}
                        interval={0}
                      />
                      <YAxis />
                      <Tooltip 
                        formatter={[
                          (value: number, name: string) => [
                            name === 'count' ? formatNumber(value) : formatCurrency(value),
                            name === 'count' ? 'Transações' : 'Receita'
                          ]
                        ]}
                      />
                      <Bar dataKey="count" fill="#1976d2" name="count" />
                      <Bar dataKey="amount" fill="#2e7d32" name="amount" />
                    </BarChart>
                  </ResponsiveContainer>
                </Box>
              </CardContent>
            </Card>
          )}
        </Grid>
      </Grid>
    </Box>
  )
}