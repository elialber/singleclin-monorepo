import { Card, CardContent, Typography, Box, Skeleton } from '@mui/material'

interface ChartSkeletonProps {
  title: string
  height?: number
}

export default function ChartSkeleton({ title, height = 300 }: ChartSkeletonProps) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          {title}
        </Typography>
        <Box sx={{ height: height, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Skeleton variant="rectangular" width="100%" height="100%" />
        </Box>
      </CardContent>
    </Card>
  )
}