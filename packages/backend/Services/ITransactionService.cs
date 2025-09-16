using SingleClin.API.DTOs.Transaction;

namespace SingleClin.API.Services;

/// <summary>
/// Interface for transaction business logic operations
/// </summary>
public interface ITransactionService
{
    /// <summary>
    /// Get paginated list of transactions with filtering
    /// </summary>
    /// <param name="filter">Filter parameters</param>
    /// <returns>Paginated transaction list</returns>
    Task<TransactionListResponseDto> GetTransactionsAsync(TransactionFilterDto filter);

    /// <summary>
    /// Get transaction by ID
    /// </summary>
    /// <param name="id">Transaction ID</param>
    /// <returns>Transaction response DTO</returns>
    Task<TransactionResponseDto?> GetTransactionByIdAsync(Guid id);

    /// <summary>
    /// Update transaction details
    /// </summary>
    /// <param name="id">Transaction ID</param>
    /// <param name="updateDto">Update data</param>
    /// <returns>Updated transaction</returns>
    Task<TransactionResponseDto?> UpdateTransactionAsync(Guid id, TransactionUpdateDto updateDto);

    /// <summary>
    /// Cancel transaction and optionally refund credits
    /// </summary>
    /// <param name="id">Transaction ID</param>
    /// <param name="cancelDto">Cancellation data</param>
    /// <param name="cancelledBy">User ID who cancelled</param>
    /// <returns>Cancelled transaction</returns>
    Task<TransactionResponseDto?> CancelTransactionAsync(Guid id, TransactionCancelDto cancelDto, string cancelledBy);

    /// <summary>
    /// Get dashboard metrics
    /// </summary>
    /// <param name="startDate">Start date filter (optional)</param>
    /// <param name="endDate">End date filter (optional)</param>
    /// <returns>Dashboard metrics</returns>
    Task<DashboardMetricsDto> GetDashboardMetricsAsync(DateTime? startDate, DateTime? endDate);

    /// <summary>
    /// Export transactions to various formats
    /// </summary>
    /// <param name="filter">Filter parameters</param>
    /// <param name="format">Export format (excel, csv, pdf)</param>
    /// <returns>File bytes, filename and content type</returns>
    Task<(byte[] FileBytes, string FileName, string ContentType)> ExportTransactionsAsync(TransactionFilterDto filter, string format);

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
    /// Validate if transaction can be cancelled
    /// </summary>
    /// <param name="id">Transaction ID</param>
    /// <returns>True if can be cancelled</returns>
    Task<bool> CanCancelTransactionAsync(Guid id);

    /// <summary>
    /// Get transaction statistics for a date range
    /// </summary>
    /// <param name="startDate">Start date</param>
    /// <param name="endDate">End date</param>
    /// <returns>Statistics object</returns>
    Task<object> GetTransactionStatisticsAsync(DateTime startDate, DateTime endDate);
}