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
                _logger.LogError("Azure Communication Services connection string is not configured");
                throw new InvalidOperationException("Azure Communication Services connection string is not configured");
            }

            _logger.LogInformation("Initializing Azure Communication Services with connection string length: {Length}", connectionString.Length);
            _emailClient = new EmailClient(connectionString);

            // Get default sender information from configuration
            _defaultFromEmail = _configuration["AzureCommunication:DefaultFromEmail"] ?? "noreply@singleclin.com";
            _defaultFromName = _configuration["AzureCommunication:DefaultFromName"] ?? "SingleClin";

            _logger.LogInformation("Azure Communication Service initialized with default from email: {FromEmail}", _defaultFromEmail);
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
                _logger.LogInformation("Starting email send process. To: {To}, Subject: {Subject}", to, subject);

                var fromAddress = fromEmail ?? _defaultFromEmail;
                var senderName = fromName ?? _defaultFromName;

                _logger.LogInformation("Email details - From: {FromAddress}, FromName: {FromName}, HasHtml: {HasHtml}, HasText: {HasText}",
                    fromAddress, senderName, !string.IsNullOrEmpty(htmlContent), !string.IsNullOrEmpty(textContent));

                var emailMessage = new EmailMessage(
                    senderAddress: fromAddress,
                    content: new EmailContent(subject)
                    {
                        PlainText = textContent,
                        Html = htmlContent
                    },
                    recipients: new EmailRecipients([new EmailAddress(to)]));

                _logger.LogInformation("Email message created, calling Azure Communication Services API...");

                var response = await _emailClient.SendAsync(
                    Azure.WaitUntil.Started,
                    emailMessage,
                    cancellationToken);

                _logger.LogInformation("Azure API call completed. HasValue: {HasValue}, Status: {Status}",
                    response.HasValue, response.GetRawResponse()?.Status);

                if (response.HasValue)
                {
                    var operation = response.Value;
                    _logger.LogInformation("Email operation started successfully. Operation ID: {OperationId}, To: {To}",
                        operation.Id, to);
                    return true;
                }
                else
                {
                    _logger.LogError("Failed to send email to {To}. No response value. HTTP Status: {Status}",
                        to, response.GetRawResponse()?.Status);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception occurred sending email to {To} with subject: {Subject}. Exception type: {ExceptionType}, Message: {Message}",
                    to, subject, ex.GetType().Name, ex.Message);
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