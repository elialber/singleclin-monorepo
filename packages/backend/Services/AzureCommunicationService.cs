using Azure.Communication.Email;
using SingleClin.API.DTOs.EmailTemplate;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Azure Communication Services email implementation
    /// </summary>
    public class AzureCommunicationService : IAzureCommunicationService
    {
        private readonly EmailClient _emailClient;
        private readonly ILogger<AzureCommunicationService> _logger;
        private readonly IConfiguration _configuration;
        private readonly string _defaultFromEmail;
        private readonly string _defaultFromName;

        public AzureCommunicationService(
            ILogger<AzureCommunicationService> logger,
            IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;

            var connectionString = _configuration.GetConnectionString("AzureCommunication");
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new InvalidOperationException("Azure Communication Services connection string is not configured");
            }

            _emailClient = new EmailClient(connectionString);

            // Get default sender information from configuration
            _defaultFromEmail = _configuration["AzureCommunication:DefaultFromEmail"] ?? "noreply@singleclin.com";
            _defaultFromName = _configuration["AzureCommunication:DefaultFromName"] ?? "SingleClin";
        }

        public async Task<bool> SendEmailAsync(
            string to,
            string subject,
            string? htmlContent = null,
            string? textContent = null,
            string? fromEmail = null,
            string? fromName = null,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Sending email to {To} with subject: {Subject}", to, subject);

                var fromAddress = fromEmail ?? _defaultFromEmail;
                var senderName = fromName ?? _defaultFromName;

                var emailMessage = new EmailMessage(
                    senderAddress: fromAddress,
                    content: new EmailContent(subject)
                    {
                        PlainText = textContent,
                        Html = htmlContent
                    },
                    recipients: new EmailRecipients([new EmailAddress(to)]));

                var response = await _emailClient.SendAsync(
                    Azure.WaitUntil.Started,
                    emailMessage,
                    cancellationToken);

                if (response.HasValue)
                {
                    _logger.LogInformation("Email sent successfully to {To}", to);
                    return true;
                }
                else
                {
                    _logger.LogError("Failed to send email to {To}. No response value", to);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending email to {To} with subject: {Subject}", to, subject);
                return false;
            }
        }

        public async Task<bool> SendEmailAsync(
            string to,
            RenderedEmailTemplate renderedTemplate,
            string? fromEmail = null,
            string? fromName = null,
            CancellationToken cancellationToken = default)
        {
            return await SendEmailAsync(
                to,
                renderedTemplate.Subject,
                renderedTemplate.HtmlContent,
                renderedTemplate.TextContent,
                fromEmail,
                fromName,
                cancellationToken);
        }
    }
}