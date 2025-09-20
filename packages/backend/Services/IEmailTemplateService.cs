using SingleClin.API.DTOs.EmailTemplate;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Service for processing and rendering email templates
    /// </summary>
    public interface IEmailTemplateService
    {
        /// <summary>
        /// Renders a user confirmation email template
        /// </summary>
        /// <param name="templateData">Data to populate the template</param>
        /// <param name="includeHtml">Whether to include HTML version</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Rendered email template</returns>
        Task<RenderedEmailTemplate> RenderUserConfirmationAsync(
            UserConfirmationTemplateData templateData,
            bool includeHtml = true,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Renders a low balance notification email template
        /// </summary>
        /// <param name="templateData">Data to populate the template</param>
        /// <param name="includeHtml">Whether to include HTML version</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Rendered email template</returns>
        Task<RenderedEmailTemplate> RenderLowBalanceNotificationAsync(
            LowBalanceTemplateData templateData,
            bool includeHtml = true,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Renders any email template with provided data
        /// </summary>
        /// <param name="templateName">Template file name (without extension)</param>
        /// <param name="templateData">Data to populate the template</param>
        /// <param name="includeHtml">Whether to include HTML version</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Rendered email template</returns>
        Task<RenderedEmailTemplate> RenderTemplateAsync(
            string templateName,
            object templateData,
            bool includeHtml = true,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Gets the HTML template content
        /// </summary>
        /// <param name="templateName">Template name</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>HTML template content</returns>
        Task<string> GetHtmlTemplateAsync(string templateName, CancellationToken cancellationToken = default);

        /// <summary>
        /// Gets the plain text template content
        /// </summary>
        /// <param name="templateName">Template name</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Plain text template content</returns>
        Task<string> GetTextTemplateAsync(string templateName, CancellationToken cancellationToken = default);
    }
}