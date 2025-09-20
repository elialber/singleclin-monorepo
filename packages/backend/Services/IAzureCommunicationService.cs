using SingleClin.API.DTOs.EmailTemplate;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Interface for Azure Communication Services email functionality
    /// </summary>
    public interface IAzureCommunicationService
    {
        /// <summary>
        /// Send an email using Azure Communication Services
        /// </summary>
        /// <param name="to">Recipient email address</param>
        /// <param name="subject">Email subject</param>
        /// <param name="htmlContent">HTML content (optional)</param>
        /// <param name="textContent">Plain text content</param>
        /// <param name="fromEmail">Sender email address (optional, uses default if not provided)</param>
        /// <param name="fromName">Sender name (optional, uses default if not provided)</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Task representing the send operation</returns>
        Task<bool> SendEmailAsync(
            string to,
            string subject,
            string? htmlContent = null,
            string? textContent = null,
            string? fromEmail = null,
            string? fromName = null,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Send a rendered email template using Azure Communication Services
        /// </summary>
        /// <param name="to">Recipient email address</param>
        /// <param name="renderedTemplate">Rendered email template</param>
        /// <param name="fromEmail">Sender email address (optional, uses default if not provided)</param>
        /// <param name="fromName">Sender name (optional, uses default if not provided)</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Task representing the send operation</returns>
        Task<bool> SendEmailAsync(
            string to,
            RenderedEmailTemplate renderedTemplate,
            string? fromEmail = null,
            string? fromName = null,
            CancellationToken cancellationToken = default);
    }
}