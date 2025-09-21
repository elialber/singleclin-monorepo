using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;
using SingleClin.API.DTOs.Transaction;
using SingleClin.API.Repositories;

namespace SingleClin.API.Services;

/// <summary>
/// Service for transaction business logic operations
/// </summary>
public class TransactionService : ITransactionService
{
    private readonly ITransactionRepository _transactionRepository;
    private readonly IExportService _exportService;
    private readonly AppDbContext _context;
    private readonly ILogger<TransactionService> _logger;

    public TransactionService(
        ITransactionRepository transactionRepository,
        IExportService exportService,
        AppDbContext context,
        ILogger<TransactionService> logger)
    {
        _transactionRepository = transactionRepository;
        _exportService = exportService;
        _context = context;
        _logger = logger;
    }

    public async Task<TransactionListResponseDto> GetTransactionsAsync(TransactionFilterDto filter)
    {
        try
        {
            _logger.LogInformation("Getting transactions with filters: {@Filter}", filter);

            // Validate and normalize filter parameters
            ValidateFilter(filter);

            return await _transactionRepository.GetTransactionsAsync(filter);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetTransactionsAsync with filter: {@Filter}", filter);
            throw;
        }
    }

    public async Task<TransactionResponseDto?> GetTransactionByIdAsync(Guid id)
    {
        try
        {
            _logger.LogInformation("Getting transaction by ID: {TransactionId}", id);

            var transaction = await _transactionRepository.GetTransactionByIdAsync(id);
            if (transaction == null)
                return null;

            return MapToResponseDto(transaction);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetTransactionByIdAsync for ID: {TransactionId}", id);
            throw;
        }
    }

    public async Task<TransactionResponseDto?> UpdateTransactionAsync(Guid id, TransactionUpdateDto updateDto)
    {
        try
        {
            _logger.LogInformation("Updating transaction {TransactionId} with data: {@UpdateDto}", id, updateDto);

            var transaction = await _transactionRepository.GetTransactionByIdAsync(id);
            if (transaction == null)
                return null;

            // Validate that transaction can be updated
            if (transaction.Status == TransactionStatus.Cancelled)
            {
                throw new InvalidOperationException("Cannot update a cancelled transaction");
            }

            // Apply updates
            if (!string.IsNullOrEmpty(updateDto.ServiceDescription))
                transaction.ServiceDescription = updateDto.ServiceDescription;

            if (!string.IsNullOrEmpty(updateDto.ServiceType))
                transaction.ServiceType = updateDto.ServiceType;

            if (!string.IsNullOrEmpty(updateDto.ValidationNotes))
                transaction.ValidationNotes = updateDto.ValidationNotes;

            if (updateDto.Amount.HasValue)
                transaction.Amount = updateDto.Amount.Value;

            var updatedTransaction = await _transactionRepository.UpdateTransactionAsync(transaction);

            _logger.LogInformation("Transaction {TransactionId} updated successfully", id);
            return MapToResponseDto(updatedTransaction);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateTransactionAsync for ID: {TransactionId}", id);
            throw;
        }
    }

    public async Task<TransactionResponseDto?> CancelTransactionAsync(Guid id, TransactionCancelDto cancelDto, string cancelledBy)
    {
        try
        {
            _logger.LogInformation("Cancelling transaction {TransactionId} by user {CancelledBy} with reason: {Reason}",
                id, cancelledBy, cancelDto.CancellationReason);

            var transaction = await _transactionRepository.GetTransactionByIdAsync(id);
            if (transaction == null)
                return null;

            // Validate that transaction can be cancelled
            if (!await _transactionRepository.CanCancelTransactionAsync(id))
            {
                throw new InvalidOperationException("Transaction cannot be cancelled in its current status");
            }

            // Update transaction status and details
            transaction.Status = TransactionStatus.Cancelled;
            transaction.CancellationReason = cancelDto.CancellationReason;
            transaction.CancellationDate = DateTime.UtcNow;
            transaction.ValidationNotes = $"{transaction.ValidationNotes ?? ""}\nCancelled by: {cancelledBy}";
            if (!string.IsNullOrEmpty(cancelDto.Notes))
            {
                transaction.ValidationNotes += $"\nNotes: {cancelDto.Notes}";
            }

            // Refund credits if requested
            if (cancelDto.RefundCredits)
            {
                await RefundCreditsToUserPlan(transaction);
            }

            var updatedTransaction = await _transactionRepository.UpdateTransactionAsync(transaction);

            _logger.LogInformation("Transaction {TransactionId} cancelled successfully, credits refunded: {RefundCredits}",
                id, cancelDto.RefundCredits);

            return MapToResponseDto(updatedTransaction);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CancelTransactionAsync for ID: {TransactionId}", id);
            throw;
        }
    }

    public async Task<DashboardMetricsDto> GetDashboardMetricsAsync(DateTime? startDate, DateTime? endDate)
    {
        try
        {
            _logger.LogInformation("Getting dashboard metrics from {StartDate} to {EndDate}", startDate, endDate);

            return await _transactionRepository.GetDashboardMetricsAsync(startDate, endDate);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetDashboardMetricsAsync");
            throw;
        }
    }

    public async Task<(byte[] FileBytes, string FileName, string ContentType)> ExportTransactionsAsync(TransactionFilterDto filter, string format)
    {
        try
        {
            _logger.LogInformation("Exporting transactions in {Format} format with filters: {@Filter}", format, filter);

            // Validate export format
            var validFormats = new[] { "excel", "csv", "pdf" };
            if (!validFormats.Contains(format.ToLower()))
            {
                throw new ArgumentException($"Invalid export format: {format}. Valid formats are: {string.Join(", ", validFormats)}");
            }

            // Get all transactions for export (without pagination)
            var exportFilter = new TransactionFilterDto
            {
                Search = filter.Search,
                PatientId = filter.PatientId,
                ClinicId = filter.ClinicId,
                PlanId = filter.PlanId,
                Status = filter.Status,
                StartDate = filter.StartDate,
                EndDate = filter.EndDate,
                ValidationStartDate = filter.ValidationStartDate,
                ValidationEndDate = filter.ValidationEndDate,
                MinAmount = filter.MinAmount,
                MaxAmount = filter.MaxAmount,
                MinCredits = filter.MinCredits,
                MaxCredits = filter.MaxCredits,
                ServiceType = filter.ServiceType,
                IncludeCancelled = filter.IncludeCancelled,
                SortBy = filter.SortBy,
                SortOrder = filter.SortOrder,
                Page = 1,
                Limit = int.MaxValue // Get all records
            };

            var transactions = await _transactionRepository.GetTransactionsForExportAsync(exportFilter);

            // Generate timestamp for filename
            var timestamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
            var fileName = $"transactions_export_{timestamp}";

            // Para agora, vou retornar um placeholder até implementarmos a integração correta com ExportService
            // TODO: Implementar integração correta com ExportService usando ReportResponse e ExportRequest
            var data = System.Text.Json.JsonSerializer.Serialize(transactions);
            var bytes = System.Text.Encoding.UTF8.GetBytes(data);

            return format.ToLower() switch
            {
                "excel" => (bytes, $"{fileName}.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
                "csv" => (bytes, $"{fileName}.csv", "text/csv"),
                "pdf" => (bytes, $"{fileName}.pdf", "application/pdf"),
                _ => throw new ArgumentException($"Unsupported export format: {format}")
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in ExportTransactionsAsync with format: {Format}", format);
            throw;
        }
    }

    public async Task<TransactionListResponseDto> GetClinicTransactionsAsync(Guid clinicId, int page, int pageSize)
    {
        try
        {
            _logger.LogInformation("Getting transactions for clinic {ClinicId}, page {Page}, size {PageSize}", clinicId, page, pageSize);

            return await _transactionRepository.GetClinicTransactionsAsync(clinicId, page, pageSize);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetClinicTransactionsAsync for clinic: {ClinicId}", clinicId);
            throw;
        }
    }

    public async Task<TransactionListResponseDto> GetPatientTransactionsAsync(Guid patientId, int page, int pageSize)
    {
        try
        {
            _logger.LogInformation("Getting transactions for patient {PatientId}, page {Page}, size {PageSize}", patientId, page, pageSize);

            return await _transactionRepository.GetPatientTransactionsAsync(patientId, page, pageSize);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetPatientTransactionsAsync for patient: {PatientId}", patientId);
            throw;
        }
    }

    public async Task<bool> CanCancelTransactionAsync(Guid id)
    {
        try
        {
            return await _transactionRepository.CanCancelTransactionAsync(id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CanCancelTransactionAsync for ID: {TransactionId}", id);
            throw;
        }
    }

    public async Task<object> GetTransactionStatisticsAsync(DateTime startDate, DateTime endDate)
    {
        try
        {
            _logger.LogInformation("Getting transaction statistics from {StartDate} to {EndDate}", startDate, endDate);

            return await _transactionRepository.GetTransactionStatisticsAsync(startDate, endDate);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetTransactionStatisticsAsync");
            throw;
        }
    }

    private void ValidateFilter(TransactionFilterDto filter)
    {
        // Normalize page and limit
        filter.Page = Math.Max(1, filter.Page);
        filter.Limit = Math.Max(1, Math.Min(100, filter.Limit)); // Max 100 per page

        // Validate date ranges
        if (filter.StartDate.HasValue && filter.EndDate.HasValue && filter.StartDate > filter.EndDate)
        {
            throw new ArgumentException("Start date cannot be after end date");
        }

        if (filter.ValidationStartDate.HasValue && filter.ValidationEndDate.HasValue &&
            filter.ValidationStartDate > filter.ValidationEndDate)
        {
            throw new ArgumentException("Validation start date cannot be after validation end date");
        }

        // Validate amount ranges
        if (filter.MinAmount.HasValue && filter.MaxAmount.HasValue && filter.MinAmount > filter.MaxAmount)
        {
            throw new ArgumentException("Minimum amount cannot be greater than maximum amount");
        }

        // Validate credits ranges
        if (filter.MinCredits.HasValue && filter.MaxCredits.HasValue && filter.MinCredits > filter.MaxCredits)
        {
            throw new ArgumentException("Minimum credits cannot be greater than maximum credits");
        }

        // Normalize sort parameters
        if (string.IsNullOrWhiteSpace(filter.SortBy))
            filter.SortBy = "CreatedAt";

        if (string.IsNullOrWhiteSpace(filter.SortOrder))
            filter.SortOrder = "desc";

        filter.SortOrder = filter.SortOrder.ToLower() == "asc" ? "asc" : "desc";
    }

    private async Task RefundCreditsToUserPlan(Transaction transaction)
    {
        try
        {
            _logger.LogInformation("Refunding {Credits} credits to UserPlan {UserPlanId} for cancelled transaction {TransactionId}",
                transaction.CreditsUsed, transaction.UserPlanId, transaction.Id);

            // Find the user plan that was debited
            var userPlan = await _context.UserPlans
                .FirstOrDefaultAsync(up => up.Id == transaction.UserPlanId);

            if (userPlan == null)
            {
                _logger.LogError("UserPlan {UserPlanId} not found for credit refund", transaction.UserPlanId);
                return;
            }

            // Validate that the plan is still active
            if (!userPlan.IsActive)
            {
                _logger.LogWarning("Cannot refund credits to inactive UserPlan {UserPlanId}", transaction.UserPlanId);
                return;
            }

            // Refund the credits
            userPlan.CreditsRemaining += transaction.CreditsUsed;
            userPlan.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Successfully refunded {Credits} credits to UserPlan {UserPlanId}. New remaining credits: {NewBalance}",
                transaction.CreditsUsed, transaction.UserPlanId, userPlan.CreditsRemaining);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error refunding credits to UserPlan {UserPlanId} for transaction {TransactionId}",
                transaction.UserPlanId, transaction.Id);
            throw;
        }
    }

    public async Task<(bool Success, TransactionResponseDto? Transaction, IEnumerable<string> Errors)> RefundAppointmentCreditsAsync(Guid transactionId, string reason)
    {
        try
        {
            _logger.LogInformation("Refunding appointment credits for transaction {TransactionId} with reason: {Reason}",
                transactionId, reason);

            var transaction = await _transactionRepository.GetTransactionByIdAsync(transactionId);
            if (transaction == null)
            {
                return (false, null, new[] { "Transaction not found" });
            }

            // Validate that transaction is completed and not already cancelled
            if (transaction.Status != TransactionStatus.Validated)
            {
                return (false, null, new[] { "Only completed transactions can be refunded" });
            }

            // Refund credits to user plan
            await RefundCreditsToUserPlan(transaction);

            // Update transaction status
            transaction.Status = TransactionStatus.Cancelled;
            transaction.CancellationReason = reason;
            transaction.CancellationDate = DateTime.UtcNow;
            transaction.ValidationNotes = $"{transaction.ValidationNotes ?? ""}\nRefunded for appointment cancellation: {reason}";

            var updatedTransaction = await _transactionRepository.UpdateTransactionAsync(transaction);

            _logger.LogInformation("Credits refunded successfully for transaction {TransactionId}", transactionId);

            return (true, MapToResponseDto(updatedTransaction), Array.Empty<string>());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error refunding appointment credits for transaction {TransactionId}", transactionId);
            return (false, null, new[] { "An error occurred while refunding credits" });
        }
    }

    private TransactionResponseDto MapToResponseDto(Transaction transaction)
    {
        return new TransactionResponseDto
        {
            Id = transaction.Id,
            Code = transaction.Code,
            PatientId = transaction.UserPlan.UserId,
            PatientName = $"{transaction.UserPlan.User.FirstName} {transaction.UserPlan.User.LastName}".Trim(),
            PatientEmail = transaction.UserPlan.User.Email,
            ClinicId = transaction.ClinicId,
            ClinicName = transaction.Clinic.Name,
            PlanId = transaction.UserPlan.PlanId,
            PlanName = transaction.UserPlan.Plan.Name,
            UserPlanId = transaction.UserPlanId,
            Status = transaction.Status,
            CreditsUsed = transaction.CreditsUsed,
            ServiceDescription = transaction.ServiceDescription,
            ServiceType = transaction.ServiceType,
            Amount = transaction.Amount,
            CreatedAt = transaction.CreatedAt,
            ValidationDate = transaction.ValidationDate,
            ValidatedBy = transaction.ValidatedBy,
            ValidationNotes = transaction.ValidationNotes,
            CancellationDate = transaction.CancellationDate,
            CancellationReason = transaction.CancellationReason,
            Latitude = transaction.Latitude,
            Longitude = transaction.Longitude,
            IpAddress = transaction.IpAddress,
            UserAgent = transaction.UserAgent,
            QRToken = transaction.QRToken,
            UpdatedAt = transaction.UpdatedAt
        };
    }
}