import {
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  Area,
  AreaChart,
} from 'recharts'
import { Paper, Typography, Box } from '@mui/material'
import { format } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import { UsageReportData } from '../../types'

interface UsageChartProps {
  data: UsageReportData
  period: 'daily' | 'weekly' | 'monthly'
}

export default function UsageChart({ data, period }: UsageChartProps) {
  const chartData = data[`${period}Usage`] || []

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    switch (period) {
      case 'daily':
        return format(date, 'dd/MM', { locale: ptBR })
      case 'weekly':
        return format(date, "'Sem' w", { locale: ptBR })
      case 'monthly':
        return format(date, 'MMM/yy', { locale: ptBR })
      default:
        return dateStr
    }
  }

  const formattedData = chartData.map((item) => ({
    ...item,
    date: formatDate(item.date),
  }))

  return (
    <Paper sx={{ p: 3, height: '100%' }}>
      <Typography variant="h6" gutterBottom>
        Uso ao Longo do Tempo
      </Typography>
      <Box sx={{ width: '100%', height: 400 }}>
        <ResponsiveContainer>
          <AreaChart data={formattedData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis yAxisId="left" orientation="left" />
            <YAxis yAxisId="right" orientation="right" />
            <Tooltip />
            <Legend />
            <Area
              yAxisId="left"
              type="monotone"
              dataKey="transactionCount"
              name="Transações"
              stroke="#8884d8"
              fill="#8884d8"
              fillOpacity={0.6}
            />
            <Area
              yAxisId="right"
              type="monotone"
              dataKey="creditsUsed"
              name="Créditos Usados"
              stroke="#82ca9d"
              fill="#82ca9d"
              fillOpacity={0.6}
            />
            <Line
              yAxisId="left"
              type="monotone"
              dataKey="uniquePatients"
              name="Pacientes Únicos"
              stroke="#ff7300"
              strokeWidth={2}
            />
          </AreaChart>
        </ResponsiveContainer>
      </Box>
    </Paper>
  )
}