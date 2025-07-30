namespace SingleClin.API.DTOs.EmailTemplate
{
    /// <summary>
    /// Represents a rendered email template with both HTML and text versions
    /// </summary>
    public class RenderedEmailTemplate
    {
        /// <summary>
        /// Subject line of the email
        /// </summary>
        public string Subject { get; set; } = string.Empty;

        /// <summary>
        /// HTML version of the email content
        /// </summary>
        public string? HtmlContent { get; set; }

        /// <summary>
        /// Plain text version of the email content
        /// </summary>
        public string TextContent { get; set; } = string.Empty;

        /// <summary>
        /// Template name used for rendering
        /// </summary>
        public string TemplateName { get; set; } = string.Empty;

        /// <summary>
        /// Timestamp when the template was rendered
        /// </summary>
        public DateTime RenderedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Whether HTML content is available
        /// </summary>
        public bool HasHtmlContent => !string.IsNullOrEmpty(HtmlContent);

        /// <summary>
        /// Whether text content is available
        /// </summary>
        public bool HasTextContent => !string.IsNullOrEmpty(TextContent);

        /// <summary>
        /// Creates a rendered template instance
        /// </summary>
        /// <param name="templateName">Template name</param>
        /// <param name="subject">Email subject</param>
        /// <param name="htmlContent">HTML content</param>
        /// <param name="textContent">Text content</param>
        /// <returns>Rendered email template</returns>
        public static RenderedEmailTemplate Create(
            string templateName,
            string subject,
            string? htmlContent,
            string textContent)
        {
            return new RenderedEmailTemplate
            {
                TemplateName = templateName,
                Subject = subject,
                HtmlContent = htmlContent,
                TextContent = textContent,
                RenderedAt = DateTime.UtcNow
            };
        }
    }
}