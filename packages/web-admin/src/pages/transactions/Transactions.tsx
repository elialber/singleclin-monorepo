import { useState, useMemo } from 'react'
import {
  Box,
  Typography,
  Stack,
  Grid,
  Fade,
  Container,
  Paper,
  Button,
  IconButton,
  Tooltip,
  Chip,
  Tabs,
  Tab,
} from '@mui/material'
import {
  Download as DownloadIcon,
  Refresh as RefreshIcon,
  TableView as TableViewIcon,
  ViewModule as ViewModuleIcon,
  List as ListIcon,
  Dashboard as DashboardIcon,
  Assessment as AssessmentIcon,
} from '@mui/icons-material'
import { useTransactions, useExportTransactions, useInvalidateTransactions, useTransactionMetrics } from '@/hooks/useTransactions'
import { TransactionFilters, Transaction } from '@/types/transaction'
import { useNotification } from '@/hooks/useNotification'
import { useDebounce } from '@/hooks/useDebounce'
import TransactionTable from './components/TransactionTable'
import TransactionCard from './components/TransactionCard'
import TransactionDashboard from './components/TransactionDashboard'
import TransactionDetailsModal from './components/TransactionDetailsModal'
import TransactionCancelModal from './components/TransactionCancelModal'
import TransactionReportsModal from './components/TransactionReportsModal'
import TransactionErrorBoundary from '@/components/TransactionErrorBoundary'
import ErrorAlert from '@/components/ErrorAlert'
import { handleTransactionError } from '@/utils/transactionErrorHandler'

function TransactionsComponent() {
  const { showSuccess, showError } = useNotification()
  const { invalidateAll } = useInvalidateTransactions()
  
  // View and pagination state
  const [viewMode, setViewMode] = useState<'table' | 'cards'>('table')
  const [currentTab, setCurrentTab] = useState<'transactions' | 'dashboard'>('transactions')
  const [page, setPage] = useState(1)
  const [limit] = useState(20)
  const [selectedIds, setSelectedIds] = useState<string[]>([])
  
  // Modal state
  const [detailsModalOpen, setDetailsModalOpen] = useState(false)
  const [cancelModalOpen, setCancelModalOpen] = useState(false)
  const [reportsModalOpen, setReportsModalOpen] = useState(false)
  const [selectedTransaction, setSelectedTransaction] = useState<Transaction | null>(null)
  
  // Filters state - all advanced filters from backend
  const [filters, setFilters] = useState<TransactionFilters>({
    search: '',
    status: undefined,
    startDate: undefined,
    endDate: undefined,
    validationStartDate: undefined,
    validationEndDate: undefined,
    minAmount: undefined,
    maxAmount: undefined,
    minCredits: undefined,
    maxCredits: undefined,
    serviceType: undefined,
    includeCancelled: false,
    sortBy: 'createdat',
    sortOrder: 'desc',
  })

  // Debounce search for better UX
  const debouncedSearch = useDebounce(filters.search, 500)
  
  // Main query with all filters
  const queryParams = useMemo(() => ({
    ...filters,
    search: debouncedSearch,
    page,
    limit,
  }), [filters, debouncedSearch, page, limit])
  
  const { data, isLoading, error } = useTransactions(queryParams)
  const { data: metricsData, isLoading: metricsLoading } = useTransactionMetrics()
  const exportMutation = useExportTransactions()

  // Filter change handlers
  const handleFiltersChange = (newFilters: Partial<TransactionFilters>) => {
    setFilters(prev => ({ ...prev, ...newFilters }))
    setPage(1) // Reset to first page when filters change
  }

  const handleSortChange = (sortBy: string, sortOrder: 'asc' | 'desc') => {
    setFilters(prev => ({ ...prev, sortBy: sortBy as any, sortOrder }))
    setPage(1)
  }

  const handlePageChange = (newPage: number) => {
    setPage(newPage)
  }

  const handleRefresh = () => {
    invalidateAll()
    showSuccess('Dados atualizados!')
  }

  const handleExport = async (format: 'xlsx' | 'csv' | 'pdf' = 'xlsx') => {
    try {
      await exportMutation.mutateAsync({ 
        params: { ...filters, search: debouncedSearch }, 
        format 
      })
    } catch (error) {
      showError('Erro ao exportar transações')
    }
  }

  // Transaction action handlers
  const handleViewTransaction = (transaction: Transaction) => {
    setSelectedTransaction(transaction)
    setDetailsModalOpen(true)
  }

  const handleEditTransaction = (transaction: Transaction) => {
    setSelectedTransaction(transaction)
    setDetailsModalOpen(true)
  }

  const handleCancelTransaction = (transaction: Transaction) => {
    setSelectedTransaction(transaction)
    setCancelModalOpen(true)
  }

  // Modal handlers
  const handleCloseDetailsModal = () => {
    setDetailsModalOpen(false)
    setSelectedTransaction(null)
  }

  const handleCloseCancelModal = () => {
    setCancelModalOpen(false)
    setSelectedTransaction(null)
  }

  const handleOpenReportsModal = () => {
    setReportsModalOpen(true)
  }

  const handleCloseReportsModal = () => {
    setReportsModalOpen(false)
  }

  const handleBulkAction = (action: string, ids: string[]) => {
    showSuccess(`Executando ação ${action} para ${ids.length} transação(ões)`)
    // TODO: Implement bulk actions
  }

  // Calculate summary statistics
  const summaryStats = useMemo(() => {
    if (!data?.data) return null
    
    const transactions = data.data
    const totalAmount = transactions.reduce((sum, t) => sum + t.amount, 0)
    const totalCredits = transactions.reduce((sum, t) => sum + t.creditsUsed, 0)
    
    const statusCounts = transactions.reduce((acc, t) => {
      acc[t.status] = (acc[t.status] || 0) + 1
      return acc
    }, {} as Record<string, number>)

    return {
      total: data.total,
      totalAmount,
      totalCredits,
      statusCounts,
      avgAmount: transactions.length > 0 ? totalAmount / transactions.length : 0,
      avgCredits: transactions.length > 0 ? totalCredits / transactions.length : 0,
    }
  }, [data])

  const renderQuickStats = () => (
    <Paper sx={{ p: 3, mb: 3 }}>
      <Typography variant="h6" gutterBottom>
        Resumo {data?.total && `(${data.total} transações)`}
      </Typography>
      
      {summaryStats && (
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={3}>
            <Box>
              <Typography variant="body2" color="textSecondary">
                Valor Total
              </Typography>
              <Typography variant="h6" color="primary">
                R$ {summaryStats.totalAmount.toFixed(2)}
              </Typography>
            </Box>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Box>
              <Typography variant="body2" color="textSecondary">
                Créditos Usados
              </Typography>
              <Typography variant="h6" color="secondary">
                {summaryStats.totalCredits}
              </Typography>
            </Box>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Box>
              <Typography variant="body2" color="textSecondary">
                Valor Médio
              </Typography>
              <Typography variant="h6">
                R$ {summaryStats.avgAmount.toFixed(2)}
              </Typography>
            </Box>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Box>
              <Typography variant="body2" color="textSecondary">
                Status
              </Typography>
              <Stack direction="row" spacing={1} flexWrap="wrap">
                {Object.entries(summaryStats.statusCounts).map(([status, count]) => (
                  <Chip
                    key={status}
                    label={`${status}: ${count}`}
                    size="small"
                    color={
                      status === 'Validated' ? 'success' :
                      status === 'Pending' ? 'warning' :
                      status === 'Cancelled' ? 'error' : 'default'
                    }
                  />
                ))}
              </Stack>
            </Box>
          </Grid>
        </Grid>
      )}
    </Paper>
  )

  const renderFilters = () => (
    <Paper sx={{ p: 3, mb: 3 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Filtros Avançados</Typography>
        
        <Stack direction="row" spacing={1}>
          <Tooltip title="Atualizar dados">
            <IconButton onClick={handleRefresh} disabled={isLoading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          
          <Tooltip title="Exportar Rápido (Excel)">
            <IconButton 
              onClick={() => handleExport('xlsx')} 
              disabled={exportMutation.isPending}
            >
              <DownloadIcon />
            </IconButton>
          </Tooltip>

          <Tooltip title="Relatórios Avançados">
            <IconButton 
              onClick={handleOpenReportsModal}
              color="secondary"
            >
              <AssessmentIcon />
            </IconButton>
          </Tooltip>
          
          <Tooltip title={viewMode === 'table' ? 'Visualizar Cards' : 'Visualizar Tabela'}>
            <IconButton onClick={() => setViewMode(viewMode === 'table' ? 'cards' : 'table')}>
              {viewMode === 'table' ? <ViewModuleIcon /> : <TableViewIcon />}
            </IconButton>
          </Tooltip>
        </Stack>
      </Stack>

      <Grid container spacing={2}>
        {/* Search */}
        <Grid item xs={12} md={6}>
          <Box>
            <Typography variant="body2" gutterBottom>
              Buscar (código, paciente, clínica)
            </Typography>
            <input
              type="text"
              value={filters.search || ''}
              onChange={(e) => handleFiltersChange({ search: e.target.value })}
              placeholder="Buscar transações..."
              style={{
                width: '100%',
                padding: '8px 12px',
                border: '1px solid #ddd',
                borderRadius: '4px',
              }}
            />
          </Box>
        </Grid>

        {/* Status */}
        <Grid item xs={12} md={3}>
          <Box>
            <Typography variant="body2" gutterBottom>
              Status
            </Typography>
            <select
              value={filters.status || ''}
              onChange={(e) => handleFiltersChange({ 
                status: e.target.value || undefined 
              })}
              style={{
                width: '100%',
                padding: '8px 12px',
                border: '1px solid #ddd',
                borderRadius: '4px',
              }}
            >
              <option value="">Todos</option>
              <option value="Pending">Pendente</option>
              <option value="Validated">Validada</option>
              <option value="Cancelled">Cancelada</option>
              <option value="Expired">Expirada</option>
            </select>
          </Box>
        </Grid>

        {/* Include Cancelled */}
        <Grid item xs={12} md={3}>
          <Box>
            <Typography variant="body2" gutterBottom>
              Incluir Canceladas
            </Typography>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <input
                type="checkbox"
                checked={filters.includeCancelled || false}
                onChange={(e) => handleFiltersChange({ includeCancelled: e.target.checked })}
              />
              Mostrar canceladas
            </label>
          </Box>
        </Grid>

        {/* Date Range */}
        <Grid item xs={12} md={6}>
          <Stack direction="row" spacing={2}>
            <Box flex={1}>
              <Typography variant="body2" gutterBottom>
                Data Início
              </Typography>
              <input
                type="date"
                value={filters.startDate || ''}
                onChange={(e) => handleFiltersChange({ startDate: e.target.value || undefined })}
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                }}
              />
            </Box>
            <Box flex={1}>
              <Typography variant="body2" gutterBottom>
                Data Fim
              </Typography>
              <input
                type="date"
                value={filters.endDate || ''}
                onChange={(e) => handleFiltersChange({ endDate: e.target.value || undefined })}
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                }}
              />
            </Box>
          </Stack>
        </Grid>

        {/* Amount Range */}
        <Grid item xs={12} md={6}>
          <Stack direction="row" spacing={2}>
            <Box flex={1}>
              <Typography variant="body2" gutterBottom>
                Valor Mínimo
              </Typography>
              <input
                type="number"
                step="0.01"
                value={filters.minAmount || ''}
                onChange={(e) => handleFiltersChange({ 
                  minAmount: e.target.value ? parseFloat(e.target.value) : undefined 
                })}
                placeholder="0.00"
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                }}
              />
            </Box>
            <Box flex={1}>
              <Typography variant="body2" gutterBottom>
                Valor Máximo
              </Typography>
              <input
                type="number"
                step="0.01"
                value={filters.maxAmount || ''}
                onChange={(e) => handleFiltersChange({ 
                  maxAmount: e.target.value ? parseFloat(e.target.value) : undefined 
                })}
                placeholder="999.99"
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                }}
              />
            </Box>
          </Stack>
        </Grid>

        {/* Quick Actions */}
        <Grid item xs={12}>
          <Stack direction="row" spacing={1} flexWrap="wrap">
            <Button
              variant="outlined"
              size="small"
              onClick={() => handleFiltersChange({
                startDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                endDate: new Date().toISOString().split('T')[0]
              })}
            >
              Últimos 7 dias
            </Button>
            <Button
              variant="outlined"
              size="small"
              onClick={() => handleFiltersChange({
                startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                endDate: new Date().toISOString().split('T')[0]
              })}
            >
              Últimos 30 dias
            </Button>
            <Button
              variant="outlined"
              size="small"
              onClick={() => handleFiltersChange({ status: 'Pending' })}
            >
              Apenas Pendentes
            </Button>
            <Button
              variant="outlined"
              size="small"
              onClick={() => setFilters({
                search: '',
                status: undefined,
                startDate: undefined,
                endDate: undefined,
                validationStartDate: undefined,
                validationEndDate: undefined,
                minAmount: undefined,
                maxAmount: undefined,
                minCredits: undefined,
                maxCredits: undefined,
                serviceType: undefined,
                includeCancelled: false,
                sortBy: 'createdat',
                sortOrder: 'desc',
              })}
            >
              Limpar Filtros
            </Button>
          </Stack>
        </Grid>
      </Grid>
    </Paper>
  )

  const renderContent = () => {
    if (error) {
      const transactionError = handleTransactionError(error, 'Carregamento de transações')
      
      return (
        <Box sx={{ mb: 3 }}>
          <ErrorAlert
            error={transactionError}
            onRetry={() => {
              if (transactionError.isRetryable) {
                window.location.reload()
              }
            }}
            showDetails={true}
            showSuggestions={true}
          />
        </Box>
      )
    }

    if (!isLoading && !data?.data?.length) {
      return (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h6" color="textSecondary" gutterBottom>
            Nenhuma transação encontrada
          </Typography>
          <Typography variant="body2" color="textSecondary">
            Tente ajustar os filtros ou verificar se existem transações no período selecionado
          </Typography>
        </Paper>
      )
    }

    // Render based on view mode
    if (viewMode === 'table') {
      return (
        <TransactionTable
          transactions={data?.data || []}
          loading={isLoading}
          onView={handleViewTransaction}
          onEdit={handleEditTransaction}
          onCancel={handleCancelTransaction}
          onSort={handleSortChange}
          sortBy={filters.sortBy}
          sortOrder={filters.sortOrder}
          selectedIds={selectedIds}
          onSelectionChange={setSelectedIds}
          onBulkAction={handleBulkAction}
        />
      )
    } else {
      return (
        <Box>
          <Grid container spacing={3}>
            {isLoading ? (
              // Loading skeleton for cards
              Array.from(new Array(limit)).map((_, index) => (
                <Grid item xs={12} sm={6} md={4} lg={3} key={index}>
                  <Box 
                    sx={{ 
                      height: 400, 
                      bgcolor: 'grey.100', 
                      borderRadius: 2,
                      animation: 'pulse 1.5s ease-in-out infinite'
                    }} 
                  />
                </Grid>
              ))
            ) : (
              data?.data.map((transaction) => (
                <Grid item xs={12} sm={6} md={4} lg={3} key={transaction.id}>
                  <TransactionCard
                    transaction={transaction}
                    onView={handleViewTransaction}
                    onEdit={handleEditTransaction}
                    onCancel={handleCancelTransaction}
                  />
                </Grid>
              ))
            )}
          </Grid>

          {/* Pagination for Cards View */}
          {!isLoading && data && data.totalPages > 1 && (
            <Stack direction="row" justifyContent="center" alignItems="center" spacing={2} mt={4}>
              <Button
                disabled={page <= 1}
                onClick={() => handlePageChange(page - 1)}
              >
                Anterior
              </Button>
              
              <Typography variant="body2">
                Página {page} de {data.totalPages} ({data.total} transações)
              </Typography>
              
              <Button
                disabled={page >= data.totalPages}
                onClick={() => handlePageChange(page + 1)}
              >
                Próxima
              </Button>
            </Stack>
          )}
        </Box>
      )
    }
  }

  return (
    <Container maxWidth="xl">
      <Fade in timeout={600}>
        <Box>
          {/* Page Header */}
          <Stack direction="row" justifyContent="space-between" alignItems="center" mb={4}>
            <Box>
              <Typography variant="h4" component="h1" fontWeight={700} gutterBottom>
                Transações de Créditos
              </Typography>
              <Typography variant="body1" color="textSecondary">
                Monitore e gerencie todas as transações de créditos entre pacientes e clínicas
              </Typography>
            </Box>
          </Stack>

          {/* Navigation Tabs */}
          <Paper sx={{ mb: 3 }}>
            <Tabs
              value={currentTab}
              onChange={(_, newValue) => setCurrentTab(newValue)}
              sx={{ px: 2 }}
            >
              <Tab 
                label="Transações" 
                value="transactions"
                icon={<ListIcon />}
              />
              <Tab 
                label="Dashboard" 
                value="dashboard"
                icon={<DashboardIcon />}
              />
            </Tabs>
          </Paper>

          {/* Tab Content */}
          {currentTab === 'dashboard' ? (
            <TransactionDashboard
              metrics={metricsData}
              loading={metricsLoading}
              onRefresh={() => {
                invalidateAll()
                showSuccess('Dados do dashboard atualizados!')
              }}
            />
          ) : (
            <>
              {/* Quick Summary Statistics */}
              {renderQuickStats()}

              {/* Advanced Filters */}
              {renderFilters()}

              {/* Main Content */}
              {renderContent()}
            </>
          )}
        </Box>
      </Fade>

      {/* Transaction Details Modal */}
      <TransactionDetailsModal
        open={detailsModalOpen}
        transaction={selectedTransaction}
        onClose={handleCloseDetailsModal}
        onEdit={handleEditTransaction}
        onCancel={handleCancelTransaction}
      />

      {/* Transaction Cancel Modal */}
      <TransactionCancelModal
        open={cancelModalOpen}
        transaction={selectedTransaction}
        onClose={handleCloseCancelModal}
      />

      {/* Transaction Reports Modal */}
      <TransactionReportsModal
        open={reportsModalOpen}
        onClose={handleCloseReportsModal}
        currentFilters={filters}
      />
    </Container>
  )
}

// Export with error boundary
export default function Transactions() {
  return (
    <TransactionErrorBoundary>
      <TransactionsComponent />
    </TransactionErrorBoundary>
  )
}