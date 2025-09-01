import { useState, useMemo, useCallback, memo } from 'react'
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TableSortLabel,
  Paper,
  Chip,
  IconButton,
  Tooltip,
  Menu,
  MenuItem,
  Typography,
  Box,
  Stack,
  Checkbox,
  Toolbar,
  Button,
  Collapse,
  Card,
  CardContent,
  CardActions,
  useTheme,
  useMediaQuery,
  Grid,
  Divider,
  Avatar,
} from '@mui/material'
import {
  MoreVert as MoreVertIcon,
  Edit as EditIcon,
  Cancel as CancelIcon,
  Visibility as VisibilityIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  LocationOn as LocationIcon,
  Schedule as ScheduleIcon,
  Business as BusinessIcon,
} from '@mui/icons-material'
import { Transaction, SortField, SortOrder } from '@/types/transaction'
import { format, parseISO } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import { TransactionTableSkeleton } from '@/components/SkeletonLoader'

interface TransactionTableProps {
  transactions: Transaction[]
  loading?: boolean
  onView?: (transaction: Transaction) => void
  onEdit?: (transaction: Transaction) => void
  onCancel?: (transaction: Transaction) => void
  onSort?: (field: SortField, order: SortOrder) => void
  sortBy?: string
  sortOrder?: SortOrder
  selectedIds?: string[]
  onSelectionChange?: (ids: string[]) => void
  onBulkAction?: (action: string, ids: string[]) => void
}

const TransactionTable = memo(function TransactionTable({
  transactions,
  loading = false,
  onView,
  onEdit,
  onCancel,
  onSort,
  sortBy,
  sortOrder,
  selectedIds = [],
  onSelectionChange,
  onBulkAction,
}: TransactionTableProps) {
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('md'))
  const isTablet = useMediaQuery(theme.breakpoints.between('sm', 'md'))
  
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const [selectedTransaction, setSelectedTransaction] = useState<Transaction | null>(null)
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set())

  const handleMenuClick = useCallback((event: React.MouseEvent<HTMLElement>, transaction: Transaction) => {
    event.stopPropagation()
    setAnchorEl(event.currentTarget)
    setSelectedTransaction(transaction)
  }, [])

  const handleMenuClose = useCallback(() => {
    setAnchorEl(null)
    setSelectedTransaction(null)
  }, [])

  const handleAction = useCallback((action: () => void) => {
    action()
    handleMenuClose()
  }, [handleMenuClose])

  const handleSort = useCallback((field: SortField) => {
    if (!onSort) return
    
    const newOrder: SortOrder = 
      sortBy === field && sortOrder === 'asc' ? 'desc' : 'asc'
    onSort(field, newOrder)
  }, [onSort, sortBy, sortOrder])

  const handleSelectAll = useCallback((checked: boolean) => {
    if (!onSelectionChange) return
    
    if (checked) {
      onSelectionChange(transactions.map(t => t.id))
    } else {
      onSelectionChange([])
    }
  }, [onSelectionChange, transactions])

  const handleSelectRow = useCallback((id: string, checked: boolean) => {
    if (!onSelectionChange) return
    
    if (checked) {
      onSelectionChange([...selectedIds, id])
    } else {
      onSelectionChange(selectedIds.filter(selectedId => selectedId !== id))
    }
  }, [onSelectionChange, selectedIds])

  const toggleRowExpansion = useCallback((id: string) => {
    const newExpanded = new Set(expandedRows)
    if (newExpanded.has(id)) {
      newExpanded.delete(id)
    } else {
      newExpanded.add(id)
    }
    setExpandedRows(newExpanded)
  }, [expandedRows])

  const getStatusColor = useCallback((status: Transaction['status']) => {
    switch (status) {
      case 'Validated':
        return 'success'
      case 'Pending':
        return 'warning'
      case 'Cancelled':
        return 'error'
      case 'Expired':
        return 'default'
      default:
        return 'default'
    }
  }, [])

  const getStatusLabel = useCallback((status: Transaction['status']) => {
    const labels = {
      Validated: 'Validada',
      Pending: 'Pendente',
      Cancelled: 'Cancelada',
      Expired: 'Expirada',
    }
    return labels[status] || status
  }, [])

  const formatDate = useCallback((dateString: string) => {
    try {
      return format(parseISO(dateString), 'dd/MM/yyyy HH:mm', { locale: ptBR })
    } catch {
      return dateString
    }
  }, [])

  const formatDateShort = useCallback((dateString: string) => {
    try {
      return format(parseISO(dateString), 'dd/MM/yy', { locale: ptBR })
    } catch {
      return dateString
    }
  }, [])

  const canEdit = useCallback((transaction: Transaction) => 
    transaction.status === 'Pending' || transaction.status === 'Validated', [])
  
  const canCancel = useCallback((transaction: Transaction) => 
    transaction.status === 'Pending' || transaction.status === 'Validated', [])

  // Memoize expensive selection calculations
  const selectionState = useMemo(() => ({
    isAllSelected: transactions.length > 0 && selectedIds.length === transactions.length,
    isIndeterminate: selectedIds.length > 0 && selectedIds.length < transactions.length
  }), [transactions.length, selectedIds.length])

  // Mobile Card Component
  const TransactionCard = memo(({ transaction }: { transaction: Transaction }) => {
    const isSelected = selectedIds.includes(transaction.id)
    const isExpanded = expandedRows.has(transaction.id)
    
    return (
      <Card 
        elevation={1}
        sx={{ 
          mb: 2,
          cursor: 'pointer',
          transition: 'all 0.2s ease',
          '&:hover': { 
            elevation: 3,
            transform: 'translateY(-1px)'
          },
          border: isSelected ? `2px solid ${theme.palette.primary.main}` : 'none'
        }}
        onClick={() => toggleRowExpansion(transaction.id)}
      >
        <CardContent sx={{ pb: 1 }}>
          {/* Header Row */}
          <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={2}>
            <Box flex={1}>
              <Stack direction="row" alignItems="center" spacing={1} mb={1}>
                {onSelectionChange && (
                  <Checkbox
                    size="small"
                    checked={isSelected}
                    onChange={(e) => {
                      e.stopPropagation()
                      handleSelectRow(transaction.id, e.target.checked)
                    }}
                    sx={{ p: 0, mr: 1 }}
                  />
                )}
                <Typography variant="h6" component="div" fontWeight={600}>
                  {transaction.code}
                </Typography>
                <Chip
                  label={getStatusLabel(transaction.status)}
                  color={getStatusColor(transaction.status)}
                  size="small"
                />
              </Stack>
              
              <Typography variant="body2" color="text.secondary" gutterBottom>
                {transaction.patientName}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {transaction.patientEmail}
              </Typography>
            </Box>
            
            <Stack alignItems="flex-end" spacing={0.5}>
              <Typography variant="h6" fontWeight={600} color="success.main">
                R$ {transaction.amount.toFixed(2)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {transaction.creditsUsed} créditos
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {formatDateShort(transaction.createdAt)}
              </Typography>
            </Stack>
          </Stack>
          
          {/* Clinic Info */}
          <Stack direction="row" alignItems="center" spacing={1} mb={1}>
            <Avatar sx={{ width: 24, height: 24, bgcolor: 'primary.light' }}>
              <BusinessIcon sx={{ fontSize: 14 }} />
            </Avatar>
            <Typography variant="body2">
              {transaction.clinicName}
            </Typography>
          </Stack>
          
          {/* Expand Button */}
          <Stack direction="row" justifyContent="space-between" alignItems="center">
            <Button
              size="small"
              startIcon={isExpanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
              onClick={(e) => {
                e.stopPropagation()
                toggleRowExpansion(transaction.id)
              }}
            >
              {isExpanded ? 'Menos detalhes' : 'Mais detalhes'}
            </Button>
          </Stack>
          
          {/* Expanded Details */}
          <Collapse in={isExpanded} timeout="auto">
            <Box mt={2} pt={2} borderTop={1} borderColor="divider">
              <Stack spacing={1.5}>
                <Box>
                  <Typography variant="caption" color="text.secondary" display="block">
                    Plano
                  </Typography>
                  <Typography variant="body2" fontWeight={500}>
                    {transaction.planName}
                  </Typography>
                </Box>
                
                <Box>
                  <Typography variant="caption" color="text.secondary" display="block">
                    Serviço
                  </Typography>
                  <Typography variant="body2">
                    {transaction.serviceDescription}
                  </Typography>
                  {transaction.serviceType && (
                    <Typography variant="caption" color="text.secondary">
                      Tipo: {transaction.serviceType}
                    </Typography>
                  )}
                </Box>
                
                <Stack direction="row" spacing={2} flexWrap="wrap">
                  <Box>
                    <Typography variant="caption" color="text.secondary" display="block">
                      Criada em
                    </Typography>
                    <Typography variant="body2">
                      {formatDate(transaction.createdAt)}
                    </Typography>
                  </Box>
                  
                  {transaction.validationDate && (
                    <Box>
                      <Typography variant="caption" color="text.secondary" display="block">
                        Validada em
                      </Typography>
                      <Typography variant="body2">
                        {formatDate(transaction.validationDate)}
                      </Typography>
                    </Box>
                  )}
                </Stack>
                
                {transaction.validatedBy && (
                  <Box>
                    <Typography variant="caption" color="text.secondary" display="block">
                      Validada por
                    </Typography>
                    <Typography variant="body2">
                      {transaction.validatedBy}
                    </Typography>
                  </Box>
                )}
                
                {transaction.validationNotes && (
                  <Box>
                    <Typography variant="caption" color="text.secondary" display="block">
                      Observações
                    </Typography>
                    <Typography variant="body2">
                      {transaction.validationNotes}
                    </Typography>
                  </Box>
                )}
                
                {transaction.cancellationDate && (
                  <Box>
                    <Typography variant="caption" color="error.main" display="block">
                      Cancelada em
                    </Typography>
                    <Typography variant="body2" color="error.main">
                      {formatDate(transaction.cancellationDate)}
                    </Typography>
                    {transaction.cancellationReason && (
                      <Typography variant="body2" color="error.main">
                        Motivo: {transaction.cancellationReason}
                      </Typography>
                    )}
                  </Box>
                )}
                
                {transaction.latitude && transaction.longitude && (
                  <Box>
                    <Typography variant="caption" color="text.secondary" display="block">
                      Localização
                    </Typography>
                    <Typography variant="body2" sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                      <LocationIcon fontSize="small" />
                      {transaction.latitude.toFixed(6)}, {transaction.longitude.toFixed(6)}
                    </Typography>
                  </Box>
                )}
              </Stack>
            </Box>
          </Collapse>
        </CardContent>
        
        {/* Action Buttons */}
        <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
          <Box />
          <Stack direction="row" spacing={1}>
            {onView && (
              <IconButton 
                size="small" 
                onClick={(e) => {
                  e.stopPropagation()
                  onView(transaction)
                }}
                sx={{ 
                  bgcolor: 'action.hover',
                  '&:hover': { bgcolor: 'action.selected' }
                }}
              >
                <VisibilityIcon fontSize="small" />
              </IconButton>
            )}
            {onEdit && canEdit(transaction) && (
              <IconButton 
                size="small" 
                onClick={(e) => {
                  e.stopPropagation()
                  onEdit(transaction)
                }}
                sx={{ 
                  bgcolor: 'primary.light',
                  color: 'primary.contrastText',
                  '&:hover': { bgcolor: 'primary.main' }
                }}
              >
                <EditIcon fontSize="small" />
              </IconButton>
            )}
            {onCancel && canCancel(transaction) && (
              <IconButton 
                size="small" 
                onClick={(e) => {
                  e.stopPropagation()
                  onCancel(transaction)
                }}
                sx={{ 
                  bgcolor: 'error.light',
                  color: 'error.contrastText',
                  '&:hover': { bgcolor: 'error.main' }
                }}
              >
                <CancelIcon fontSize="small" />
              </IconButton>
            )}
          </Stack>
        </CardActions>
      </Card>
    )
  }, [])
  
  if (loading) {
    return <TransactionTableSkeleton rows={10} />
  }

  // Mobile Card List View
  if (isMobile) {
    return (
      <Box>
        {/* Bulk Actions Toolbar for Mobile */}
        {selectedIds.length > 0 && onBulkAction && (
          <Card elevation={2} sx={{ mb: 2, bgcolor: 'primary.light' }}>
            <CardContent sx={{ '&:last-child': { pb: 2 } }}>
              <Stack spacing={2}>
                <Typography variant="subtitle1" color="primary.contrastText">
                  {selectedIds.length} transação(ões) selecionada(s)
                </Typography>
                
                <Stack direction="row" spacing={1} flexWrap="wrap">
                  <Button
                    variant="contained"
                    color="inherit"
                    size="small"
                    sx={{ minWidth: 'auto', flexShrink: 0 }}
                    onClick={() => onBulkAction('export', selectedIds)}
                  >
                    Exportar
                  </Button>
                  
                  <Button
                    variant="outlined"
                    color="inherit"
                    size="small"
                    sx={{ minWidth: 'auto', flexShrink: 0 }}
                    onClick={() => onBulkAction('cancel', selectedIds)}
                  >
                    Cancelar
                  </Button>
                </Stack>
              </Stack>
            </CardContent>
          </Card>
        )}
        
        {/* Select All Option for Mobile */}
        {onSelectionChange && transactions.length > 0 && (
          <Card elevation={1} sx={{ mb: 2 }}>
            <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
              <Stack direction="row" alignItems="center" spacing={1}>
                <Checkbox
                  indeterminate={selectionState.isIndeterminate}
                  checked={selectionState.isAllSelected}
                  onChange={(e) => handleSelectAll(e.target.checked)}
                />
                <Typography variant="body2">
                  Selecionar todas ({transactions.length} transações)
                </Typography>
              </Stack>
            </CardContent>
          </Card>
        )}
        
        {/* Transaction Cards */}
        {transactions.map((transaction) => (
          <TransactionCard key={transaction.id} transaction={transaction} />
        ))}
      </Box>
    )
  }
  
  // Desktop Table View
  return (
    <Paper>
      {/* Bulk Actions Toolbar */}
      {selectedIds.length > 0 && onBulkAction && (
        <Toolbar sx={{ bgcolor: 'primary.light', color: 'primary.contrastText' }}>
          <Typography variant="subtitle1" sx={{ flex: '1 1 100%' }}>
            {selectedIds.length} transação(ões) selecionada(s)
          </Typography>
          
          <Stack direction="row" spacing={1}>
            <Button
              size="small"
              color="inherit"
              onClick={() => onBulkAction('export', selectedIds)}
            >
              Exportar Selecionadas
            </Button>
            
            <Button
              size="small"
              color="inherit"
              onClick={() => onBulkAction('cancel', selectedIds)}
            >
              Cancelar Selecionadas
            </Button>
          </Stack>
        </Toolbar>
      )}

      <TableContainer>
        <Table stickyHeader={isTablet}>
          <TableHead>
            <TableRow>
              {onSelectionChange && (
                <TableCell padding="checkbox">
                  <Checkbox
                    indeterminate={selectionState.isIndeterminate}
                    checked={selectionState.isAllSelected}
                    onChange={(e) => handleSelectAll(e.target.checked)}
                  />
                </TableCell>
              )}
              
              <TableCell />
              
              <TableCell>
                <TableSortLabel
                  active={sortBy === 'code'}
                  direction={sortBy === 'code' ? sortOrder : 'asc'}
                  onClick={() => handleSort('code')}
                >
                  Código
                </TableSortLabel>
              </TableCell>
              
              <TableCell>
                <TableSortLabel
                  active={sortBy === 'patientname'}
                  direction={sortBy === 'patientname' ? sortOrder : 'asc'}
                  onClick={() => handleSort('patientname')}
                >
                  Paciente
                </TableSortLabel>
              </TableCell>
              
              <TableCell>
                <TableSortLabel
                  active={sortBy === 'clinicname'}
                  direction={sortBy === 'clinicname' ? sortOrder : 'asc'}
                  onClick={() => handleSort('clinicname')}
                >
                  Clínica
                </TableSortLabel>
              </TableCell>
              
              <TableCell>
                <TableSortLabel
                  active={sortBy === 'status'}
                  direction={sortBy === 'status' ? sortOrder : 'asc'}
                  onClick={() => handleSort('status')}
                >
                  Status
                </TableSortLabel>
              </TableCell>
              
              <TableCell align="right">
                <TableSortLabel
                  active={sortBy === 'amount'}
                  direction={sortBy === 'amount' ? sortOrder : 'asc'}
                  onClick={() => handleSort('amount')}
                >
                  Valor
                </TableSortLabel>
              </TableCell>
              
              <TableCell align="right">
                <TableSortLabel
                  active={sortBy === 'creditsused'}
                  direction={sortBy === 'creditsused' ? sortOrder : 'asc'}
                  onClick={() => handleSort('creditsused')}
                >
                  Créditos
                </TableSortLabel>
              </TableCell>
              
              <TableCell>
                <TableSortLabel
                  active={sortBy === 'createdat'}
                  direction={sortBy === 'createdat' ? sortOrder : 'asc'}
                  onClick={() => handleSort('createdat')}
                >
                  Data
                </TableSortLabel>
              </TableCell>
              
              <TableCell align="center" sx={{ minWidth: { sm: 120 } }}>Ações</TableCell>
            </TableRow>
          </TableHead>
          
          <TableBody>
            {transactions.map((transaction) => (
              <>
                <TableRow 
                  key={transaction.id}
                  hover
                  sx={{ 
                    cursor: 'pointer',
                    '&:hover': { bgcolor: 'action.hover' }
                  }}
                  onClick={() => toggleRowExpansion(transaction.id)}
                >
                  {onSelectionChange && (
                    <TableCell padding="checkbox" onClick={(e) => e.stopPropagation()}>
                      <Checkbox
                        checked={selectedIds.includes(transaction.id)}
                        onChange={(e) => handleSelectRow(transaction.id, e.target.checked)}
                      />
                    </TableCell>
                  )}
                  
                  <TableCell sx={{ width: 48 }}>
                    <IconButton 
                      size="small"
                      sx={{ 
                        minHeight: 44, 
                        minWidth: 44,
                        '&:hover': { bgcolor: 'action.hover' }
                      }}
                    >
                      {expandedRows.has(transaction.id) ? (
                        <ExpandLessIcon />
                      ) : (
                        <ExpandMoreIcon />
                      )}
                    </IconButton>
                  </TableCell>
                  
                  <TableCell>
                    <Typography variant="body2" fontWeight={500}>
                      {transaction.code}
                    </Typography>
                  </TableCell>
                  
                  <TableCell>
                    <Typography variant="body2">
                      {transaction.patientName}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {transaction.patientEmail}
                    </Typography>
                  </TableCell>
                  
                  <TableCell>
                    <Typography variant="body2">
                      {transaction.clinicName}
                    </Typography>
                  </TableCell>
                  
                  <TableCell>
                    <Chip
                      label={getStatusLabel(transaction.status)}
                      color={getStatusColor(transaction.status)}
                      size="small"
                    />
                  </TableCell>
                  
                  <TableCell align="right">
                    <Typography variant="body2" fontWeight={500}>
                      R$ {transaction.amount.toFixed(2)}
                    </Typography>
                  </TableCell>
                  
                  <TableCell align="right">
                    <Typography variant="body2">
                      {transaction.creditsUsed}
                    </Typography>
                  </TableCell>
                  
                  <TableCell>
                    <Typography variant="body2">
                      {formatDateShort(transaction.createdAt)}
                    </Typography>
                  </TableCell>
                  
                  <TableCell align="center" onClick={(e) => e.stopPropagation()}>
                    <IconButton
                      size="small"
                      onClick={(e) => handleMenuClick(e, transaction)}
                      sx={{ 
                        minHeight: 44, 
                        minWidth: 44,
                        '&:hover': { bgcolor: 'action.hover' }
                      }}
                    >
                      <MoreVertIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>

                {/* Expanded Row Details */}
                <TableRow>
                  <TableCell colSpan={onSelectionChange ? 10 : 9} sx={{ py: 0 }}>
                    <Collapse in={expandedRows.has(transaction.id)} timeout="auto">
                      <Box sx={{ p: 2, bgcolor: 'grey.50' }}>
                        <Typography variant="subtitle2" gutterBottom>
                          Detalhes da Transação
                        </Typography>
                        
                        <Stack spacing={1}>
                          <Typography variant="body2">
                            <strong>Plano:</strong> {transaction.planName}
                          </Typography>
                          
                          <Typography variant="body2">
                            <strong>Serviço:</strong> {transaction.serviceDescription}
                          </Typography>
                          
                          {transaction.serviceType && (
                            <Typography variant="body2">
                              <strong>Tipo:</strong> {transaction.serviceType}
                            </Typography>
                          )}

                          <Stack direction="row" spacing={3}>
                            <Typography variant="body2">
                              <Schedule fontSize="small" sx={{ mr: 0.5, verticalAlign: 'middle' }} />
                              Criada: {formatDate(transaction.createdAt)}
                            </Typography>
                            
                            {transaction.validationDate && (
                              <Typography variant="body2">
                                Validada: {formatDate(transaction.validationDate)}
                              </Typography>
                            )}
                          </Stack>

                          {transaction.validatedBy && (
                            <Typography variant="body2">
                              <strong>Validada por:</strong> {transaction.validatedBy}
                            </Typography>
                          )}

                          {transaction.validationNotes && (
                            <Typography variant="body2">
                              <strong>Observações:</strong> {transaction.validationNotes}
                            </Typography>
                          )}

                          {transaction.cancellationDate && (
                            <Typography variant="body2" color="error">
                              <strong>Cancelada em:</strong> {formatDate(transaction.cancellationDate)}
                            </Typography>
                          )}

                          {transaction.cancellationReason && (
                            <Typography variant="body2" color="error">
                              <strong>Motivo:</strong> {transaction.cancellationReason}
                            </Typography>
                          )}

                          {transaction.latitude && transaction.longitude && (
                            <Typography variant="body2">
                              <LocationIcon fontSize="small" sx={{ mr: 0.5, verticalAlign: 'middle' }} />
                              Localização: {transaction.latitude.toFixed(6)}, {transaction.longitude.toFixed(6)}
                            </Typography>
                          )}
                        </Stack>
                      </Box>
                    </Collapse>
                  </TableCell>
                </TableRow>
              </>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Actions Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        {onView && selectedTransaction && (
          <MenuItem onClick={() => handleAction(() => onView!(selectedTransaction))}>
            <VisibilityIcon fontSize="small" sx={{ mr: 1 }} />
            Ver Detalhes
          </MenuItem>
        )}
        
        {onEdit && selectedTransaction && canEdit(selectedTransaction) && (
          <MenuItem onClick={() => handleAction(() => onEdit!(selectedTransaction))}>
            <EditIcon fontSize="small" sx={{ mr: 1 }} />
            Editar
          </MenuItem>
        )}
        
        {onCancel && selectedTransaction && canCancel(selectedTransaction) && (
          <MenuItem onClick={() => handleAction(() => onCancel!(selectedTransaction))}>
            <CancelIcon fontSize="small" sx={{ mr: 1, color: 'error.main' }} />
            <Typography color="error.main">Cancelar</Typography>
          </MenuItem>
        )}
      </Menu>
    </Paper>
  )
})

export default TransactionTable