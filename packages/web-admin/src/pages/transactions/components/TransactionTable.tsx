import { useState } from 'react'
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
} from '@mui/icons-material'
import { Transaction, SortField, SortOrder } from '@/types/transaction'
import { format, parseISO } from 'date-fns'
import { ptBR } from 'date-fns/locale'

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

export default function TransactionTable({
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
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const [selectedTransaction, setSelectedTransaction] = useState<Transaction | null>(null)
  const [expandedRows, setExpandedRows] = useState<Set<string>>(new Set())

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, transaction: Transaction) => {
    event.stopPropagation()
    setAnchorEl(event.currentTarget)
    setSelectedTransaction(transaction)
  }

  const handleMenuClose = () => {
    setAnchorEl(null)
    setSelectedTransaction(null)
  }

  const handleAction = (action: () => void) => {
    action()
    handleMenuClose()
  }

  const handleSort = (field: SortField) => {
    if (!onSort) return
    
    const newOrder: SortOrder = 
      sortBy === field && sortOrder === 'asc' ? 'desc' : 'asc'
    onSort(field, newOrder)
  }

  const handleSelectAll = (checked: boolean) => {
    if (!onSelectionChange) return
    
    if (checked) {
      onSelectionChange(transactions.map(t => t.id))
    } else {
      onSelectionChange([])
    }
  }

  const handleSelectRow = (id: string, checked: boolean) => {
    if (!onSelectionChange) return
    
    if (checked) {
      onSelectionChange([...selectedIds, id])
    } else {
      onSelectionChange(selectedIds.filter(selectedId => selectedId !== id))
    }
  }

  const toggleRowExpansion = (id: string) => {
    const newExpanded = new Set(expandedRows)
    if (newExpanded.has(id)) {
      newExpanded.delete(id)
    } else {
      newExpanded.add(id)
    }
    setExpandedRows(newExpanded)
  }

  const getStatusColor = (status: Transaction['status']) => {
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
  }

  const getStatusLabel = (status: Transaction['status']) => {
    const labels = {
      Validated: 'Validada',
      Pending: 'Pendente',
      Cancelled: 'Cancelada',
      Expired: 'Expirada',
    }
    return labels[status] || status
  }

  const formatDate = (dateString: string) => {
    try {
      return format(parseISO(dateString), 'dd/MM/yyyy HH:mm', { locale: ptBR })
    } catch {
      return dateString
    }
  }

  const formatDateShort = (dateString: string) => {
    try {
      return format(parseISO(dateString), 'dd/MM/yy', { locale: ptBR })
    } catch {
      return dateString
    }
  }

  const canEdit = (transaction: Transaction) => 
    transaction.status === 'Pending' || transaction.status === 'Validated'
  
  const canCancel = (transaction: Transaction) => 
    transaction.status === 'Pending' || transaction.status === 'Validated'

  const isAllSelected = transactions.length > 0 && selectedIds.length === transactions.length
  const isIndeterminate = selectedIds.length > 0 && selectedIds.length < transactions.length

  if (loading) {
    return (
      <Paper>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                {Array.from({ length: 8 }).map((_, index) => (
                  <TableCell key={index}>
                    <Box sx={{ height: 24, bgcolor: 'grey.200', borderRadius: 1 }} />
                  </TableCell>
                ))}
              </TableRow>
            </TableHead>
            <TableBody>
              {Array.from({ length: 5 }).map((_, index) => (
                <TableRow key={index}>
                  {Array.from({ length: 8 }).map((_, cellIndex) => (
                    <TableCell key={cellIndex}>
                      <Box sx={{ height: 20, bgcolor: 'grey.100', borderRadius: 1 }} />
                    </TableCell>
                  ))}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>
    )
  }

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
        <Table>
          <TableHead>
            <TableRow>
              {onSelectionChange && (
                <TableCell padding="checkbox">
                  <Checkbox
                    indeterminate={isIndeterminate}
                    checked={isAllSelected}
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
              
              <TableCell align="center">Ações</TableCell>
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
                  
                  <TableCell>
                    <IconButton size="small">
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
}