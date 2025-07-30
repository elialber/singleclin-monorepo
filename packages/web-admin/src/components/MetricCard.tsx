import { Card, CardContent, Typography, Box, Skeleton } from '@mui/material'
import { ReactNode } from 'react'

interface MetricCardProps {
  title: string
  value: string | number
  subtitle?: string
  icon: ReactNode
  loading?: boolean
  color?: 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info'
  trend?: {
    value: number
    label: string
    isPositive: boolean
  }
}

export default function MetricCard({
  title,
  value,
  subtitle,
  icon,
  loading = false,
  color = 'primary',
  trend,
}: MetricCardProps) {
  if (loading) {
    return (
      <Card sx={{ height: '100%' }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
            <Skeleton variant="text" width="60%" height={24} />
            <Skeleton variant="circular" width={40} height={40} />
          </Box>
          <Skeleton variant="text" width="40%" height={32} />
          <Skeleton variant="text" width="80%" height={20} />
        </CardContent>
      </Card>
    )
  }

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Typography variant="h6" color="text.secondary" gutterBottom>
            {title}
          </Typography>
          <Box 
            sx={{ 
              color: `${color}.main`,
              display: 'flex',
              alignItems: 'center',
              fontSize: '2rem'
            }}
          >
            {icon}
          </Box>
        </Box>
        
        <Typography variant="h4" component="div" gutterBottom fontWeight={600}>
          {value}
        </Typography>
        
        {subtitle && (
          <Typography variant="body2" color="text.secondary">
            {subtitle}
          </Typography>
        )}
        
        {trend && (
          <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
            <Typography 
              variant="body2" 
              color={trend.isPositive ? 'success.main' : 'error.main'}
              sx={{ fontWeight: 600 }}
            >
              {trend.isPositive ? '+' : ''}{trend.value}%
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>
              {trend.label}
            </Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  )
}