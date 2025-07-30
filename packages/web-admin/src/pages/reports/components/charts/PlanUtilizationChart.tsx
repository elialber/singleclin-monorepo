import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
} from 'recharts'
import { Paper, Typography, Box, Grid, Chip } from '@mui/material'
import { PlanUtilizationData } from '../../types'

interface PlanUtilizationChartProps {
  data: PlanUtilizationData
}

export default function PlanUtilizationChart({ data }: PlanUtilizationChartProps) {
  const plansData = data.plans.map((plan) => ({
    name: plan.planName,
    utilizationRate: plan.usage.utilizationRate * 100,
    efficiency: plan.efficiency.creditEfficiency,
    renewalRate: plan.efficiency.renewalRate,
    roi: plan.efficiency.roi,
  }))

  const efficiencyData = data.plans.map((plan) => ({
    plan: plan.planName,
    'Taxa de Utilização': plan.usage.utilizationRate * 100,
    'Eficiência de Créditos': plan.efficiency.creditEfficiency,
    'Taxa de Renovação': plan.efficiency.renewalRate,
    'ROI': plan.efficiency.roi,
  }))

  return (
    <Grid container spacing={3}>
      <Grid item xs={12}>
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Resumo de Utilização
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6} md={3}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h4" color="primary">
                  {(data.summary.overallUtilizationRate * 100).toFixed(1)}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Taxa Geral de Utilização
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h4" color="error">
                  {data.summary.totalCreditsWasted.toFixed(0)}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Créditos Desperdiçados
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h5" color="success.main">
                  {data.summary.mostEfficientPlan}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Plano Mais Eficiente
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h5" color="warning.main">
                  {data.summary.leastEfficientPlan}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Plano Menos Eficiente
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </Paper>
      </Grid>

      <Grid item xs={12} lg={7}>
        <Paper sx={{ p: 3, height: '100%' }}>
          <Typography variant="h6" gutterBottom>
            Métricas de Utilização por Plano
          </Typography>
          <Box sx={{ width: '100%', height: 400 }}>
            <ResponsiveContainer>
              <BarChart data={plansData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="utilizationRate" name="Taxa de Utilização (%)" fill="#8884d8" />
                <Bar dataKey="efficiency" name="Eficiência (%)" fill="#82ca9d" />
                <Bar dataKey="renewalRate" name="Taxa de Renovação (%)" fill="#ffc658" />
              </BarChart>
            </ResponsiveContainer>
          </Box>
        </Paper>
      </Grid>

      <Grid item xs={12} lg={5}>
        <Paper sx={{ p: 3, height: '100%' }}>
          <Typography variant="h6" gutterBottom>
            Análise de Eficiência
          </Typography>
          <Box sx={{ width: '100%', height: 400 }}>
            <ResponsiveContainer>
              <RadarChart data={efficiencyData}>
                <PolarGrid />
                <PolarAngleAxis dataKey="plan" />
                <PolarRadiusAxis angle={90} domain={[0, 100]} />
                <Radar
                  name="Taxa de Utilização"
                  dataKey="Taxa de Utilização"
                  stroke="#8884d8"
                  fill="#8884d8"
                  fillOpacity={0.6}
                />
                <Radar
                  name="Eficiência de Créditos"
                  dataKey="Eficiência de Créditos"
                  stroke="#82ca9d"
                  fill="#82ca9d"
                  fillOpacity={0.6}
                />
                <Legend />
              </RadarChart>
            </ResponsiveContainer>
          </Box>
        </Paper>
      </Grid>

      {data.patterns.length > 0 && (
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Padrões Identificados
            </Typography>
            <Grid container spacing={2}>
              {data.patterns.map((pattern, index) => (
                <Grid item xs={12} md={6} key={index}>
                  <Box sx={{ p: 2, border: 1, borderColor: 'divider', borderRadius: 1 }}>
                    <Typography variant="subtitle1" fontWeight="bold">
                      {pattern.patternName}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                      {pattern.description}
                    </Typography>
                    <Box sx={{ mb: 1 }}>
                      <Chip
                        label={`${pattern.affectedUsers} usuários afetados`}
                        size="small"
                        color="warning"
                      />
                    </Box>
                    <Typography variant="body2" color="primary">
                      💡 {pattern.recommendation}
                    </Typography>
                  </Box>
                </Grid>
              ))}
            </Grid>
          </Paper>
        </Grid>
      )}
    </Grid>
  )
}