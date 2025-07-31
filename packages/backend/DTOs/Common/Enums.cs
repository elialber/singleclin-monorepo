namespace SingleClin.API.DTOs.Common
{
    /// <summary>
    /// Export format options
    /// </summary>
    public enum ExportFormat
    {
        /// <summary>
        /// JSON format (default)
        /// </summary>
        Json,

        /// <summary>
        /// Excel format (.xlsx)
        /// </summary>
        Excel,

        /// <summary>
        /// PDF format
        /// </summary>
        Pdf,

        /// <summary>
        /// CSV format
        /// </summary>
        Csv
    }

    /// <summary>
    /// Paper size options for PDF exports
    /// </summary>
    public enum PaperSize
    {
        A4,
        Letter,
        Legal,
        A3
    }

    /// <summary>
    /// Paper orientation options for PDF exports
    /// </summary>
    public enum PaperOrientation
    {
        Portrait,
        Landscape
    }
}