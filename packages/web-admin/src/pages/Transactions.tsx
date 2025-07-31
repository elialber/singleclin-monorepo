import { useState, useEffect, useCallback } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Tooltip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  CircularProgress,
  Alert,
  Skeleton,
} from '@mui/material'
import {
  Search as SearchIcon,
  FilterList as FilterListIcon,
  Clear as ClearIcon,
  FileDownload as FileDownloadIcon,
  Visibility as VisibilityIcon,
  Receipt as ReceiptIcon,
} from '@mui/icons-material'
// Removed date-fns import due to compatibility issues
import { Transaction, TransactionFilters } from '@/types/transaction'
import { transactionService } from '@/services/transaction.service'
import { useNotification } from "@/hooks/useNotification"
import { useDebounce } from '@/hooks/useDebounce'

const TRANSACTION_STATUS = [
  { value: 'Pending', label: 'Pendente', color: 'warning' as const },
  { value: 'Validated', label: 'Validada', color: 'success' as const },
  { value: 'Cancelled', label: 'Cancelada', color: 'error' as const },
]

export default function Transactions() {
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [exporting, setExporting] = useState(false)
  
  // Pagination
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(25)
  const [total, setTotal] = useState(0)
  
  // Filters
  const [filters, setFilters] = useState<TransactionFilters>({})
  const [tempFilters, setTempFilters] = useState<TransactionFilters>({})
  const [showFilters, setShowFilters] = useState(false)
  
  // Transaction details modal
  const [selectedTransaction, setSelectedTransaction] = useState<Transaction | null>(null)
  const [detailsOpen, setDetailsOpen] = useState(false)
  
  const { showSuccess, showError } = useNotification()
  
  // Debounce search to reduce API calls
  const debouncedFilters = useDebounce(filters, 500)

  // Define loadTransactions before using it
  const loadTransactions = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      
      const response = await transactionService.getTransactions({
        ...debouncedFilters,
        page: page + 1, // API is 1-based
        limit: rowsPerPage,
      })
      
      setTransactions(response.data)
      setTotal(response.total)
    } catch (err: unknown) {
      console.error('Error loading transactions:', err)
      setError('Erro ao carregar transações')
      showError('Erro ao carregar transações')
    } finally {
      setLoading(false)
    }
  }, [debouncedFilters, page, rowsPerPage, showError])

  useEffect(() => {
    loadTransactions()
  }, [debouncedFilters, page, rowsPerPage, loadTransactions])

  const handleFilterChange = (field: keyof TransactionFilters, value: string | Date | null) => {
    setTempFilters(prev => ({
      ...prev,
      [field]: value || undefined,
    }))
  }

  const applyFilters = () => {
    setFilters(tempFilters)
    setPage(0) // Reset to first page
    setShowFilters(false)
  }

  const clearFilters = () => {
    const emptyFilters = {}
    setTempFilters(emptyFilters)
    setFilters(emptyFilters)
    setPage(0)
    setShowFilters(false)
  }

  const handleExport = async (format: 'csv' | 'excel') => {
    try {
      setExporting(true)
      
      const blob = await transactionService.exportTransactions(filters, format)
      
      // Create download link
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      const extension = format === 'csv' ? 'csv' : 'xlsx'
      link.download = `transacoes_${extension}_${new Date().toISOString().split('T')[0]}.${extension}`
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)
      
      showSuccess(`Transações exportadas em ${format.toUpperCase()}`)
    } catch (err: unknown) {
      console.error('Error exporting transactions:', err)
      showError('Erro ao exportar transações')
    } finally {
      setExporting(false)
    }
  }

  const handleChangePage = (_: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value)
  }

  const formatDateString = (dateString: string) => {
    return new Date(dateString).toLocaleString('pt-BR')
  }

  const getStatusChip = (status: string) => {
    const statusConfig = TRANSACTION_STATUS.find(s => s.value === status)
    return (
      <Chip
        label={statusConfig?.label || status}
        color={statusConfig?.color || 'default'}
        size="small"
      />
    )
  }

  const activeFiltersCount = Object.values(filters).filter(value => 
    value !== undefined && value !== ''
  ).length

  return (
    <Box>
        {/* Header */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
          <Box>
            <Typography variant="h4" fontWeight={600} gutterBottom>
              Transações
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Histórico de transações e movimentações de créditos
            </Typography>
          </Box>
          
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              startIcon={<FilterListIcon />}
              onClick={() => setShowFilters(true)}
              color={activeFiltersCount > 0 ? 'primary' : 'inherit'}
            >
              Filtros
              {activeFiltersCount > 0 && (
                <Chip 
                  label={activeFiltersCount} 
                  size="small" 
                  sx={{ ml: 1, height: 20 }}
                />
              )}
            </Button>
            
            <Button
              variant="outlined"
              startIcon={exporting ? <CircularProgress size={16} /> : <FileDownloadIcon />}
              onClick={() => handleExport('csv')}
              disabled={exporting}
            >
              CSV
            </Button>
            
            <Button
              variant="contained"
              startIcon={exporting ? <CircularProgress size={16} /> : <FileDownloadIcon />}
              onClick={() => handleExport('excel')}
              disabled={exporting}
            >
              Excel
            </Button>
          </Box>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 3 }}>
            {error}
          </Alert>
        )}

        {/* Transactions Table */}
        <Card>
          <CardContent sx={{ p: 0 }}>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Data</TableCell>
                    <TableCell>Paciente</TableCell>
                    <TableCell>Clínica</TableCell>
                    <TableCell>Plano</TableCell>
                    <TableCell align="center">Créditos</TableCell>
                    <TableCell align="right">Valor</TableCell>
                    <TableCell align="center">Status</TableCell>
                    <TableCell align="center">Ações</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {loading ? (
                    // Loading skeleton
                    Array.from({ length: rowsPerPage }).map((_, index) => (
                      <TableRow key={index}>
                        {Array.from({ length: 8 }).map((_, cellIndex) => (
                          <TableCell key={cellIndex}>
                            <Skeleton variant="text" />
                          </TableCell>
                        ))}
                      </TableRow>
                    ))
                  ) : transactions.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} align="center" sx={{ py: 8 }}>
                        <ReceiptIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
                        <Typography variant="h6" color="text.secondary">
                          Nenhuma transação encontrada
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {activeFiltersCount > 0 
                            ? 'Tente ajustar os filtros para ver mais resultados'
                            : 'As transações aparecerão aqui quando forem criadas'
                          }
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    transactions.map((transaction) => (
                      <TableRow key={transaction.id} hover>
                        <TableCell>
                          {formatDateString(transaction.transactionDate)}
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" fontWeight={500}>
                            {transaction.patientName}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {transaction.clinicName}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {transaction.planName}
                          </Typography>
                        </TableCell>
                        <TableCell align="center">
                          <Chip 
                            label={transaction.creditsUsed} 
                            size="small" 
                            variant="outlined"
                          />
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" fontWeight={600}>
                            {formatCurrency(transaction.amount)}
                          </Typography>
                        </TableCell>
                        <TableCell align="center">
                          {getStatusChip(transaction.status)}
                        </TableCell>
                        <TableCell align="center">
                          <Tooltip title="Ver detalhes">
                            <IconButton
                              size="small"
                              onClick={() => {
                                setSelectedTransaction(transaction)
                                setDetailsOpen(true)
                              }}
                            >
                              <VisibilityIcon />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
            
            <TablePagination
              rowsPerPageOptions={[10, 25, 50, 100]}
              component="div"
              count={total}
              rowsPerPage={rowsPerPage}
              page={page}
              onPageChange={handleChangePage}
              onRowsPerPageChange={handleChangeRowsPerPage}
              labelRowsPerPage="Linhas por página:"
              labelDisplayedRows={({ from, to, count }) => 
                `${from}-${to} de ${count !== -1 ? count : `mais de ${to}`}`
              }
            />
          </CardContent>
        </Card>

        {/* Filters Dialog */}
        <Dialog 
          open={showFilters} 
          onClose={() => setShowFilters(false)} 
          maxWidth="md" 
          fullWidth
        >
          <DialogTitle>
            Filtrar Transações
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nome do Paciente"
                  value={tempFilters.patientName || ''}
                  onChange={(e) => handleFilterChange('patientName', e.target.value)}
                  InputProps={{
                    startAdornment: <SearchIcon sx={{ color: 'text.secondary', mr: 1 }} />,
                  }}
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nome da Clínica"
                  value={tempFilters.clinicName || ''}
                  onChange={(e) => handleFilterChange('clinicName', e.target.value)}
                  InputProps={{
                    startAdornment: <SearchIcon sx={{ color: 'text.secondary', mr: 1 }} />,
                  }}
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nome do Plano"
                  value={tempFilters.planName || ''}
                  onChange={(e) => handleFilterChange('planName', e.target.value)}
                  InputProps={{
                    startAdornment: <SearchIcon sx={{ color: 'text.secondary', mr: 1 }} />,
                  }}
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Status</InputLabel>
                  <Select
                    value={tempFilters.status || ''}
                    onChange={(e) => handleFilterChange('status', e.target.value)}
                    label="Status"
                  >
                    <MenuItem value="">Todos</MenuItem>
                    {TRANSACTION_STATUS.map((status) => (
                      <MenuItem key={status.value} value={status.value}>
                        {status.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Data Inicial"
                  type="date"
                  value={tempFilters.startDate || ''}
                  onChange={(e) => handleFilterChange('startDate', e.target.value)}
                  InputLabelProps={{
                    shrink: true,
                  }}
                />
              </Grid>
              
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Data Final"
                  type="date"
                  value={tempFilters.endDate || ''}
                  onChange={(e) => handleFilterChange('endDate', e.target.value)}
                  InputLabelProps={{
                    shrink: true,
                  }}
                />
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setShowFilters(false)}>
              Cancelar
            </Button>
            <Button onClick={clearFilters} startIcon={<ClearIcon />}>
              Limpar
            </Button>
            <Button onClick={applyFilters} variant="contained">
              Aplicar Filtros
            </Button>
          </DialogActions>
        </Dialog>

        {/* Transaction Details Dialog */}
        <Dialog
          open={detailsOpen}
          onClose={() => setDetailsOpen(false)}
          maxWidth="sm"
          fullWidth
        >
          <DialogTitle>
            Detalhes da Transação
          </DialogTitle>
          <DialogContent>
            {selectedTransaction && (
              <Grid container spacing={2} sx={{ mt: 1 }}>
                <Grid item xs={12}>
                  <Typography variant="subtitle2" color="text.secondary">
                    ID da Transação
                  </Typography>
                  <Typography variant="body1" fontFamily="monospace">
                    {selectedTransaction.id}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Data
                  </Typography>
                  <Typography variant="body1">
                    {formatDateString(selectedTransaction.transactionDate)}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Status
                  </Typography>
                  <Box sx={{ mt: 0.5 }}>
                    {getStatusChip(selectedTransaction.status)}
                  </Box>
                </Grid>
                
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Paciente
                  </Typography>
                  <Typography variant="body1">
                    {selectedTransaction.patientName}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Clínica
                  </Typography>
                  <Typography variant="body1">
                    {selectedTransaction.clinicName}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Plano
                  </Typography>
                  <Typography variant="body1">
                    {selectedTransaction.planName}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Créditos Utilizados
                  </Typography>
                  <Typography variant="body1">
                    {selectedTransaction.creditsUsed}
                  </Typography>
                </Grid>
                
                <Grid item xs={12}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Valor da Transação
                  </Typography>
                  <Typography variant="h6" color="primary.main" fontWeight={600}>
                    {formatCurrency(selectedTransaction.amount)}
                  </Typography>
                </Grid>
                
                {selectedTransaction.description && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Descrição
                    </Typography>
                    <Typography variant="body1">
                      {selectedTransaction.description}
                    </Typography>
                  </Grid>
                )}
                
                {selectedTransaction.qrCodeId && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2" color="text.secondary">
                      ID do QR Code
                    </Typography>
                    <Typography variant="body1" fontFamily="monospace">
                      {selectedTransaction.qrCodeId}
                    </Typography>
                  </Grid>
                )}
              </Grid>
            )}
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setDetailsOpen(false)}>
              Fechar
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
  )
}