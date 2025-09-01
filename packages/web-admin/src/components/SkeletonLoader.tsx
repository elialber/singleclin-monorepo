import { 
  Box, 
  Skeleton, 
  Stack, 
  Card, 
  CardContent, 
  Grid, 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableRow, 
  Paper 
} from '@mui/material'

// Generic skeleton loader
interface SkeletonLoaderProps {
  variant?: 'text' | 'rectangular' | 'circular'
  width?: string | number
  height?: string | number
  animation?: 'pulse' | 'wave' | false
}

export function SkeletonLoader({ 
  variant = 'text', 
  width, 
  height, 
  animation = 'wave' 
}: SkeletonLoaderProps) {
  return (
    <Skeleton 
      variant={variant} 
      width={width} 
      height={height} 
      animation={animation}
      sx={{ 
        borderRadius: variant === 'rectangular' ? 1 : undefined,
        '&::after': {
          animationDuration: '1.2s'
        }
      }} 
    />
  )
}

// Transaction Table Skeleton
export function TransactionTableSkeleton({ rows = 10 }: { rows?: number }) {
  return (
    <Paper sx={{ overflow: 'hidden' }}>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell><SkeletonLoader width="20px" /></TableCell>
            <TableCell><SkeletonLoader width="120px" /></TableCell>
            <TableCell><SkeletonLoader width="150px" /></TableCell>
            <TableCell><SkeletonLoader width="120px" /></TableCell>
            <TableCell><SkeletonLoader width="100px" /></TableCell>
            <TableCell><SkeletonLoader width="80px" /></TableCell>
            <TableCell><SkeletonLoader width="80px" /></TableCell>
            <TableCell><SkeletonLoader width="100px" /></TableCell>
            <TableCell><SkeletonLoader width="40px" /></TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {Array.from({ length: rows }).map((_, index) => (
            <TableRow key={index}>
              <TableCell><SkeletonLoader variant="circular" width={24} height={24} /></TableCell>
              <TableCell><SkeletonLoader width="100px" /></TableCell>
              <TableCell><SkeletonLoader width="140px" /></TableCell>
              <TableCell><SkeletonLoader width="110px" /></TableCell>
              <TableCell><SkeletonLoader width="80px" /></TableCell>
              <TableCell><SkeletonLoader width="60px" /></TableCell>
              <TableCell><SkeletonLoader width="70px" /></TableCell>
              <TableCell><SkeletonLoader width="90px" /></TableCell>
              <TableCell>
                <SkeletonLoader variant="circular" width={32} height={32} />
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Paper>
  )
}

// Transaction Card Skeleton
export function TransactionCardSkeleton() {
  return (
    <Card sx={{ height: 400, position: 'relative', overflow: 'hidden' }}>
      {/* Header gradient skeleton */}
      <Box 
        sx={{ 
          height: 80, 
          background: 'linear-gradient(135deg, #f5f5f5 0%, #e0e0e0 100%)',
          p: 2,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start'
        }}
      >
        <Box>
          <SkeletonLoader width="120px" height={24} />
          <SkeletonLoader width="80px" height={16} sx={{ mt: 0.5 }} />
        </Box>
        <SkeletonLoader variant="rectangular" width={80} height={28} />
      </Box>

      <CardContent>
        <Stack spacing={2}>
          {/* Patient info */}
          <Box>
            <SkeletonLoader width="100px" height={16} />
            <SkeletonLoader width="160px" height={20} sx={{ mt: 0.5 }} />
            <SkeletonLoader width="140px" height={14} sx={{ mt: 0.5 }} />
          </Box>

          {/* Service info */}
          <Box>
            <SkeletonLoader width="80px" height={16} />
            <SkeletonLoader width="200px" height={18} sx={{ mt: 0.5 }} />
          </Box>

          {/* Financial info */}
          <Grid container spacing={2}>
            <Grid item xs={6}>
              <SkeletonLoader width="60px" height={14} />
              <SkeletonLoader width="80px" height={24} sx={{ mt: 0.5 }} />
            </Grid>
            <Grid item xs={6}>
              <SkeletonLoader width="50px" height={14} />
              <SkeletonLoader width="40px" height={24} sx={{ mt: 0.5 }} />
            </Grid>
          </Grid>

          {/* Date */}
          <Box>
            <SkeletonLoader width="100px" height={14} />
          </Box>

          {/* Action buttons */}
          <Stack direction="row" spacing={1} justifyContent="flex-end">
            <SkeletonLoader variant="rectangular" width={80} height={32} />
            <SkeletonLoader variant="rectangular" width={80} height={32} />
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  )
}

// Dashboard Metrics Skeleton
export function DashboardMetricsSkeleton() {
  return (
    <Grid container spacing={3}>
      {/* Main metrics */}
      {Array.from({ length: 8 }).map((_, index) => (
        <Grid item xs={12} sm={6} md={3} key={index}>
          <Card sx={{ height: 140 }}>
            <CardContent>
              <Stack direction="row" alignItems="flex-start" justifyContent="space-between">
                <Box>
                  <SkeletonLoader width="120px" height={16} />
                  <SkeletonLoader width="100px" height={32} sx={{ my: 1 }} />
                  <SkeletonLoader width="80px" height={14} />
                </Box>
                <SkeletonLoader variant="circular" width={56} height={56} />
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      ))}

      {/* Charts row */}
      <Grid item xs={12} md={8}>
        <Card sx={{ height: 300 }}>
          <CardContent>
            <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
              <SkeletonLoader width="150px" height={24} />
              <SkeletonLoader variant="circular" width={32} height={32} />
            </Stack>
            <SkeletonLoader variant="rectangular" width="100%" height={240} />
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={12} md={4}>
        <Card sx={{ height: 300 }}>
          <CardContent>
            <SkeletonLoader width="180px" height={24} sx={{ mb: 2 }} />
            <Stack spacing={2}>
              {Array.from({ length: 4 }).map((_, index) => (
                <Box key={index}>
                  <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
                    <SkeletonLoader width="80px" height={16} />
                    <SkeletonLoader width="60px" height={16} />
                  </Stack>
                  <SkeletonLoader variant="rectangular" width="100%" height={8} />
                </Box>
              ))}
            </Stack>
          </CardContent>
        </Card>
      </Grid>

      {/* Top performers */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <SkeletonLoader width="140px" height={24} sx={{ mb: 2 }} />
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <SkeletonLoader width="120px" height={18} sx={{ mb: 1 }} />
                <Box sx={{ p: 2, bgcolor: 'grey.100', borderRadius: 1 }}>
                  <SkeletonLoader width="160px" height={20} />
                  <SkeletonLoader width="120px" height={16} sx={{ mt: 0.5 }} />
                  <SkeletonLoader width="100px" height={16} sx={{ mt: 0.5 }} />
                </Box>
              </Grid>
              <Grid item xs={12} md={6}>
                <SkeletonLoader width="120px" height={18} sx={{ mb: 1 }} />
                <Box sx={{ p: 2, bgcolor: 'grey.100', borderRadius: 1 }}>
                  <SkeletonLoader width="160px" height={20} />
                  <SkeletonLoader width="120px" height={16} sx={{ mt: 0.5 }} />
                  <SkeletonLoader width="100px" height={16} sx={{ mt: 0.5 }} />
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  )
}

// Filters Skeleton
export function FiltersSkeletonLoader() {
  return (
    <Paper sx={{ p: 3, mb: 3 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <SkeletonLoader width="160px" height={24} />
        <Stack direction="row" spacing={1}>
          <SkeletonLoader variant="circular" width={40} height={40} />
          <SkeletonLoader variant="circular" width={40} height={40} />
          <SkeletonLoader variant="circular" width={40} height={40} />
        </Stack>
      </Stack>

      <Grid container spacing={2}>
        <Grid item xs={12} md={6}>
          <SkeletonLoader width="200px" height={16} sx={{ mb: 1 }} />
          <SkeletonLoader variant="rectangular" width="100%" height={40} />
        </Grid>
        <Grid item xs={12} md={3}>
          <SkeletonLoader width="80px" height={16} sx={{ mb: 1 }} />
          <SkeletonLoader variant="rectangular" width="100%" height={40} />
        </Grid>
        <Grid item xs={12} md={3}>
          <SkeletonLoader width="120px" height={16} sx={{ mb: 1 }} />
          <SkeletonLoader variant="rectangular" width="100%" height={40} />
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Stack direction="row" spacing={2}>
            <Box flex={1}>
              <SkeletonLoader width="100px" height={16} sx={{ mb: 1 }} />
              <SkeletonLoader variant="rectangular" width="100%" height={40} />
            </Box>
            <Box flex={1}>
              <SkeletonLoader width="80px" height={16} sx={{ mb: 1 }} />
              <SkeletonLoader variant="rectangular" width="100%" height={40} />
            </Box>
          </Stack>
        </Grid>

        <Grid item xs={12} md={6}>
          <Stack direction="row" spacing={2}>
            <Box flex={1}>
              <SkeletonLoader width="100px" height={16} sx={{ mb: 1 }} />
              <SkeletonLoader variant="rectangular" width="100%" height={40} />
            </Box>
            <Box flex={1}>
              <SkeletonLoader width="100px" height={16} sx={{ mb: 1 }} />
              <SkeletonLoader variant="rectangular" width="100%" height={40} />
            </Box>
          </Stack>
        </Grid>

        <Grid item xs={12}>
          <Stack direction="row" spacing={1} flexWrap="wrap">
            {Array.from({ length: 4 }).map((_, index) => (
              <SkeletonLoader key={index} variant="rectangular" width={120} height={32} />
            ))}
          </Stack>
        </Grid>
      </Grid>
    </Paper>
  )
}

// Modal Loading Skeleton
export function ModalLoadingSkeleton() {
  return (
    <Box sx={{ p: 3 }}>
      <Stack spacing={3}>
        {/* Header */}
        <Stack direction="row" alignItems="center" spacing={2}>
          <SkeletonLoader variant="circular" width={40} height={40} />
          <Box>
            <SkeletonLoader width="200px" height={24} />
            <SkeletonLoader width="120px" height={16} sx={{ mt: 0.5 }} />
          </Box>
        </Stack>

        {/* Content sections */}
        <Stack spacing={2}>
          {Array.from({ length: 3 }).map((_, sectionIndex) => (
            <Card key={sectionIndex} variant="outlined">
              <CardContent>
                <SkeletonLoader width="150px" height={20} sx={{ mb: 2 }} />
                <Grid container spacing={2}>
                  {Array.from({ length: 4 }).map((_, itemIndex) => (
                    <Grid item xs={12} sm={6} key={itemIndex}>
                      <SkeletonLoader width="80px" height={14} sx={{ mb: 1 }} />
                      <SkeletonLoader width="140px" height={18} />
                    </Grid>
                  ))}
                </Grid>
              </CardContent>
            </Card>
          ))}
        </Stack>

        {/* Actions */}
        <Stack direction="row" spacing={1} justifyContent="flex-end">
          <SkeletonLoader variant="rectangular" width={80} height={36} />
          <SkeletonLoader variant="rectangular" width={120} height={36} />
        </Stack>
      </Stack>
    </Box>
  )
}

// Page Loading Overlay
export function PageLoadingOverlay() {
  return (
    <Box
      sx={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        bgcolor: 'rgba(255, 255, 255, 0.8)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 9999,
        backdropFilter: 'blur(2px)'
      }}
    >
      <Stack alignItems="center" spacing={2}>
        <SkeletonLoader variant="circular" width={64} height={64} />
        <SkeletonLoader width="180px" height={20} />
        <SkeletonLoader width="240px" height={16} />
      </Stack>
    </Box>
  )
}