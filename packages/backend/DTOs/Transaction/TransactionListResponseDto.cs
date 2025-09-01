namespace SingleClin.API.DTOs.Transaction;

/// <summary>
/// Response DTO for paginated transaction list
/// </summary>
public class TransactionListResponseDto
{
    /// <summary>
    /// List of transactions
    /// </summary>
    public List<TransactionResponseDto> Data { get; set; } = new();
    
    /// <summary>
    /// Total number of transactions (all pages)
    /// </summary>
    public int Total { get; set; }
    
    /// <summary>
    /// Current page number
    /// </summary>
    public int Page { get; set; }
    
    /// <summary>
    /// Number of items per page
    /// </summary>
    public int Limit { get; set; }
    
    /// <summary>
    /// Total number of pages
    /// </summary>
    public int TotalPages { get; set; }
    
    /// <summary>
    /// Whether there is a next page
    /// </summary>
    public bool HasNextPage { get; set; }
    
    /// <summary>
    /// Whether there is a previous page
    /// </summary>
    public bool HasPreviousPage { get; set; }
}