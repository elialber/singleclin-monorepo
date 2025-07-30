import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts'
import { Paper, Typography, Box, Grid } from '@mui/material'
import { ServiceReportData } from '../../types'

interface ServiceChartProps {
  data: ServiceReportData
}

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82CA9D']

export default function ServiceChart({ data }: ServiceChartProps) {
  const topServicesData = data.topServices.slice(0, 10).map((service) => ({
    name: service.serviceName,
    usage: service.usageCount,
    credits: service.totalCreditsUsed,
    marketShare: service.marketShare,
  }))

  const distributionData = Object.entries(data.distribution.categoryPercentages).map(
    ([category, percentage]) => ({
      name: category,
      value: percentage,
    })
  )

  const CustomTooltip = ({ active, payload, label }: { active?: boolean; payload?: Array<{ name: string; value: number; color: string }>; label?: string }) => {
    if (active && payload && payload.length) {
      return (
        <Box sx={{ bgcolor: 'background.paper', p: 1, border: 1, borderColor: 'divider' }}>
          <Typography variant="body2">{label}</Typography>
          {payload.map((entry, index: number) => (
            <Typography key={index} variant="body2" color={entry.color}>
              {entry.name}: {entry.value}
            </Typography>
          ))}
        </Box>
      )
    }
    return null
  }

  return (
    <Grid container spacing={3}>
      <Grid item xs={12} lg={8}>
        <Paper sx={{ p: 3, height: '100%' }}>
          <Typography variant="h6" gutterBottom>
            Top 10 Serviços Mais Utilizados
          </Typography>
          <Box sx={{ width: '100%', height: 400 }}>
            <ResponsiveContainer>
              <BarChart data={topServicesData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
                <YAxis yAxisId="left" orientation="left" />
                <YAxis yAxisId="right" orientation="right" />
                <Tooltip content={<CustomTooltip />} />
                <Legend />
                <Bar
                  yAxisId="left"
                  dataKey="usage"
                  name="Uso"
                  fill="#8884d8"
                />
                <Bar
                  yAxisId="right"
                  dataKey="credits"
                  name="Créditos"
                  fill="#82ca9d"
                />
              </BarChart>
            </ResponsiveContainer>
          </Box>
        </Paper>
      </Grid>

      <Grid item xs={12} lg={4}>
        <Paper sx={{ p: 3, height: '100%' }}>
          <Typography variant="h6" gutterBottom>
            Distribuição por Categoria
          </Typography>
          <Box sx={{ width: '100%', height: 400 }}>
            <ResponsiveContainer>
              <PieChart>
                <Pie
                  data={distributionData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={(entry) => `${entry.name}: ${entry.value.toFixed(1)}%`}
                  outerRadius={120}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {distributionData.map((_entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Box>
        </Paper>
      </Grid>

      {data.insights.recommendations.length > 0 && (
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Insights e Recomendações
            </Typography>
            <Box component="ul" sx={{ pl: 2 }}>
              {data.insights.recommendations.map((rec, index) => (
                <Typography key={index} component="li" variant="body2" sx={{ mb: 1 }}>
                  {rec}
                </Typography>
              ))}
            </Box>
          </Paper>
        </Grid>
      )}
    </Grid>
  )
}