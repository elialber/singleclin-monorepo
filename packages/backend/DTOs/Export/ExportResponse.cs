namespace SingleClin.API.DTOs.Export
{
    /// <summary>
    /// Export response model
    /// </summary>
    public class ExportResponse
    {
        public bool Success { get; set; }
        public string FileName { get; set; } = string.Empty;
        public string ContentType { get; set; } = string.Empty;
        public byte[] FileContent { get; set; } = Array.Empty<byte>();
        public long FileSize { get; set; }
        public Dictionary<string, string> Metadata { get; set; } = new();
        public List<string> Warnings { get; set; } = new();
    }
}