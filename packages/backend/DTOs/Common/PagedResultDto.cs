namespace SingleClin.API.DTOs.Common;

/// <summary>
/// Generic paginated result data transfer object
/// </summary>
/// <typeparam name="T">Type of items in the result</typeparam>
public class PagedResultDto<T>
{
    /// <summary>
    /// List of items in current page
    /// </summary>
    public IEnumerable<T> Items { get; set; } = new List<T>();

    /// <summary>
    /// Current page number (1-based)
    /// </summary>
    public int PageNumber { get; set; }

    /// <summary>
    /// Number of items per page
    /// </summary>
    public int PageSize { get; set; }

    /// <summary>
    /// Total number of items across all pages
    /// </summary>
    public int TotalCount { get; set; }

    /// <summary>
    /// Total number of pages
    /// </summary>
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);

    /// <summary>
    /// Whether there is a previous page
    /// </summary>
    public bool HasPreviousPage => PageNumber > 1;

    /// <summary>
    /// Whether there is a next page
    /// </summary>
    public bool HasNextPage => PageNumber < TotalPages;

    /// <summary>
    /// Number of items in current page
    /// </summary>
    public int ItemCount => Items.Count();

    /// <summary>
    /// Create a new paginated result
    /// </summary>
    public PagedResultDto(IEnumerable<T> items, int totalCount, int pageNumber, int pageSize)
    {
        Items = items;
        TotalCount = totalCount;
        PageNumber = pageNumber;
        PageSize = pageSize;
    }

    /// <summary>
    /// Default constructor
    /// </summary>
    public PagedResultDto()
    {
    }
}