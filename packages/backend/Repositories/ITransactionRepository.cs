using SingleClin.API.Data.Models;
using SingleClin.API.DTOs.Transaction;

namespace SingleClin.API.Repositories;

/// <summary>
/// Interface for transaction data access operations
/// </summary>
public interface ITransactionRepository
{
    /// <summary>
    /// Get paginated list of transactions with filtering
    /// </summary>
    /// <param name="filter">Filter parameters</param>
    /// <returns>Paginated transaction list</returns>
    Task<TransactionListResponseDto> GetTransactionsAsync(TransactionFilterDto filter);
    
    /// <summary>
    /// Get transaction by ID with related data
    /// </summary>
    /// <param name="id">Transaction ID</param>
    /// <returns>Transaction with related entities</returns>
    Task<Transaction?> GetTransactionByIdAsync(Guid id);
    
    /// <summary>
    /// Create a new transaction
    /// </summary>
    /// <param name="transaction">Transaction entity to create</param>
    /// <returns>Created transaction</returns>
    Task<Transaction> CreateTransactionAsync(Transaction transaction);
    
    /// <summary>
    /// Update an existing transaction
    /// </summary>
    /// <param name="transaction">Transaction entity to update</param>
    /// <returns>Updated transaction</returns>
    Task<Transaction> UpdateTransactionAsync(Transaction transaction);
    
    /// <summary>
    /// Get transactions for a specific clinic
    /// </summary>
    /// <param name="clinicId">Clinic ID</param>
    /// <param name="page">Page number</param>
    /// <param name="pageSize">Page size</param>
    /// <returns>Paginated clinic transactions</returns>
    Task<TransactionListResponseDto> GetClinicTransactionsAsync(Guid clinicId, int page, int pageSize);
    
    /// <summary>
    /// Get transactions for a specific patient
    /// </summary>
    /// <param name="patientId">Patient (User) ID</param>
    /// <param name="page">Page number</param>
    /// <param name="pageSize">Page size</param>
    /// <returns>Paginated patient transactions</returns>
    Task<TransactionListResponseDto> GetPatientTransactionsAsync(Guid patientId, int page, int pageSize);
    
    /// <summary>
    /// Get dashboard metrics
    /// </summary>
    /// <param name="startDate">Start date filter (optional)</param>
    /// <param name="endDate">End date filter (optional)</param>
    /// <returns>Dashboard metrics</returns>
    Task<DashboardMetricsDto> GetDashboardMetricsAsync(DateTime? startDate, DateTime? endDate);
    
    /// <summary>
    /// Get transactions for export
    /// </summary>
    /// <param name="filter">Filter parameters</param>
    /// <returns>All matching transactions for export</returns>
    Task<List<Transaction>> GetTransactionsForExportAsync(TransactionFilterDto filter);
    
    /// <summary>
    /// Check if transaction can be cancelled
    /// </summary>
    /// <param name="transactionId">Transaction ID</param>
    /// <returns>True if can be cancelled</returns>
    Task<bool> CanCancelTransactionAsync(Guid transactionId);
    
    /// <summary>
    /// Get transaction statistics for a date range
    /// </summary>
    /// <param name="startDate">Start date</param>
    /// <param name="endDate">End date</param>
    /// <returns>Statistics object</returns>
    Task<object> GetTransactionStatisticsAsync(DateTime startDate, DateTime endDate);
}