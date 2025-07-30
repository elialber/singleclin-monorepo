using SendGrid;
using SendGrid.Helpers.Mail;
using SingleClin.API.DTOs.Notification;
using SingleClin.API.DTOs.EmailTemplate;
using Microsoft.Extensions.Options;
using System.Text.Json;

namespace SingleClin.API.Services
{
    public class SendGridProvider : IEmailNotificationProvider
    {
        private readonly SendGridOptions _options;
        private readonly ILogger<SendGridProvider> _logger;
        private readonly ISendGridClient _sendGridClient;
        private readonly IEmailTemplateService _templateService;

        public NotificationChannel Channel => NotificationChannel.Email;

        public SendGridProvider(
            IOptions<SendGridOptions> options, 
            ILogger<SendGridProvider> logger,
            IEmailTemplateService templateService)
        {
            _options = options.Value;
            _logger = logger;
            _templateService = templateService;
            
            if (string.IsNullOrEmpty(_options.ApiKey))
            {
                _logger.LogWarning("SendGrid API key not configured. Email provider will not be functional.");
                _sendGridClient = null!;
            }
            else
            {
                _sendGridClient = new SendGridClient(_options.ApiKey);
            }
        }

        public async Task<NotificationResponse> SendAsync(NotificationRequest request, CancellationToken cancellationToken = default)
        {
            if (request is not EmailNotificationRequest emailRequest)
            {
                return NotificationResponse.Failed(
                    "Invalid request type for email notification", 
                    Channel
                );
            }

            return await SendEmailAsync(emailRequest, cancellationToken);
        }

        public async Task<NotificationResponse> SendEmailAsync(EmailNotificationRequest request, CancellationToken cancellationToken = default)
        {
            try
            {
                if (_sendGridClient == null)
                {
                    _logger.LogError("SendGrid client is not initialized");
                    return NotificationResponse.Failed("SendGrid client not initialized", Channel);
                }

                var message = BuildEmailMessage(request);
                
                _logger.LogInformation("Sending email to: {Email}, Subject: {Subject}", 
                    request.Email, request.Subject);

                var response = await _sendGridClient.SendEmailAsync(message, cancellationToken);

                if (response.IsSuccessStatusCode)
                {
                    var messageId = ExtractMessageId(response);
                    _logger.LogInformation("Email sent successfully. MessageId: {MessageId}", messageId);

                    var metadata = new Dictionary<string, object>
                    {
                        ["email"] = request.Email,
                        ["subject"] = request.Subject,
                        ["notificationType"] = request.Type.ToString(),
                        ["statusCode"] = (int)response.StatusCode
                    };

                    return NotificationResponse.Successful(messageId, Channel, metadata);
                }
                else
                {
                    var errorBody = await response.Body.ReadAsStringAsync();
                    _logger.LogError("SendGrid API error. Status: {StatusCode}, Body: {Body}", 
                        response.StatusCode, errorBody);

                    var errorMessage = ParseSendGridError(errorBody) ?? $"SendGrid API error: {response.StatusCode}";

                    return NotificationResponse.Failed(errorMessage, Channel, new Dictionary<string, object>
                    {
                        ["statusCode"] = (int)response.StatusCode,
                        ["email"] = request.Email,
                        ["errorDetails"] = errorBody
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error sending email to {Email}", request.Email);
                return NotificationResponse.Failed($"Unexpected error: {ex.Message}", Channel);
            }
        }

        public bool IsHealthy()
        {
            try
            {
                return _sendGridClient != null && !string.IsNullOrEmpty(_options.ApiKey);
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Sends a low balance notification email using templates
        /// </summary>
        /// <param name="recipientEmail">Recipient email address</param>
        /// <param name="recipientName">Recipient name</param>
        /// <param name="templateData">Template data</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Notification response</returns>
        public async Task<NotificationResponse> SendLowBalanceNotificationAsync(
            string recipientEmail,
            string recipientName,
            LowBalanceTemplateData templateData,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Sending low balance notification to {Email} using template", recipientEmail);

                // Render the template
                var renderedTemplate = await _templateService.RenderLowBalanceNotificationAsync(
                    templateData, 
                    includeHtml: true, 
                    cancellationToken);

                // Create email request using rendered content
                var emailRequest = new EmailNotificationRequest
                {
                    Email = recipientEmail,
                    Recipient = recipientName,
                    Subject = renderedTemplate.Subject,
                    Message = renderedTemplate.TextContent,
                    HtmlContent = renderedTemplate.HtmlContent,
                    PlainTextContent = renderedTemplate.TextContent,
                    Type = NotificationType.LowBalance,
                    Priority = templateData.CurrentBalance <= 1 ? 3 : 2,
                    FromEmail = _options.DefaultFromEmail,
                    FromName = _options.DefaultFromName,
                    Data = new Dictionary<string, object>
                    {
                        ["templateName"] = renderedTemplate.TemplateName,
                        ["userId"] = templateData.UserId.ToString(),
                        ["currentBalance"] = templateData.CurrentBalance,
                        ["planName"] = templateData.PlanName,
                        ["renderedAt"] = renderedTemplate.RenderedAt
                    }
                };

                // Send the email
                var result = await SendEmailAsync(emailRequest, cancellationToken);

                if (result.Success)
                {
                    _logger.LogInformation("Low balance notification sent successfully to {Email}", recipientEmail);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending low balance notification to {Email}", recipientEmail);
                return NotificationResponse.Failed($"Template email error: {ex.Message}", Channel);
            }
        }

        /// <summary>
        /// Sends a templated email
        /// </summary>
        /// <param name="recipientEmail">Recipient email</param>
        /// <param name="recipientName">Recipient name</param>
        /// <param name="templateName">Template name</param>
        /// <param name="templateData">Template data</param>
        /// <param name="notificationType">Notification type</param>
        /// <param name="priority">Email priority</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Notification response</returns>
        public async Task<NotificationResponse> SendTemplatedEmailAsync(
            string recipientEmail,
            string recipientName,
            string templateName,
            object templateData,
            NotificationType notificationType = NotificationType.General,
            int priority = 1,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Sending templated email {TemplateName} to {Email}", templateName, recipientEmail);

                // Render the template
                var renderedTemplate = await _templateService.RenderTemplateAsync(
                    templateName, 
                    templateData, 
                    includeHtml: true, 
                    cancellationToken);

                // Create email request using rendered content
                var emailRequest = new EmailNotificationRequest
                {
                    Email = recipientEmail,
                    Recipient = recipientName,
                    Subject = renderedTemplate.Subject,
                    Message = renderedTemplate.TextContent,
                    HtmlContent = renderedTemplate.HtmlContent,
                    PlainTextContent = renderedTemplate.TextContent,
                    Type = notificationType,
                    Priority = priority,
                    FromEmail = _options.DefaultFromEmail,
                    FromName = _options.DefaultFromName,
                    Data = new Dictionary<string, object>
                    {
                        ["templateName"] = renderedTemplate.TemplateName,
                        ["renderedAt"] = renderedTemplate.RenderedAt
                    }
                };

                // Send the email
                var result = await SendEmailAsync(emailRequest, cancellationToken);

                if (result.Success)
                {
                    _logger.LogInformation("Templated email {TemplateName} sent successfully to {Email}", templateName, recipientEmail);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending templated email {TemplateName} to {Email}", templateName, recipientEmail);
                return NotificationResponse.Failed($"Template email error: {ex.Message}", Channel);
            }
        }

        private SendGridMessage BuildEmailMessage(EmailNotificationRequest request)
        {
            var from = new EmailAddress(request.FromEmail, request.FromName);
            var to = new EmailAddress(request.Email, request.Recipient);
            
            var message = MailHelper.CreateSingleEmail(
                from, 
                to, 
                request.Subject, 
                request.PlainTextContent ?? request.Message, 
                request.HtmlContent
            );

            // Set priority
            if (request.Priority >= 2)
            {
                message.Headers = new Dictionary<string, string>
                {
                    ["X-Priority"] = "1",
                    ["X-MSMail-Priority"] = "High",
                    ["Importance"] = "High"
                };
            }

            // Add custom data as headers for tracking
            if (request.Data?.Any() == true)
            {
                message.Headers ??= new Dictionary<string, string>();
                
                // Add notification type and ID for tracking
                message.Headers["X-Notification-Type"] = request.Type.ToString();
                message.Headers["X-Notification-ID"] = Guid.NewGuid().ToString();
                
                // Add custom data (limit to safe header values)
                foreach (var item in request.Data.Take(5)) // Limit to 5 custom headers
                {
                    var headerKey = $"X-Custom-{item.Key}";
                    var headerValue = item.Value?.ToString();
                    
                    if (!string.IsNullOrEmpty(headerValue) && headerValue.Length <= 100)
                    {
                        message.Headers[headerKey] = headerValue;
                    }
                }
            }

            // Add template data if provided
            if (request.TemplateData?.Any() == true)
            {
                message.Personalizations[0].Substitutions = request.TemplateData;
            }

            // Add tracking settings
            message.TrackingSettings = new TrackingSettings
            {
                ClickTracking = new ClickTracking
                {
                    Enable = _options.EnableClickTracking,
                    EnableText = _options.EnableClickTracking
                },
                OpenTracking = new OpenTracking
                {
                    Enable = _options.EnableOpenTracking
                }
            };

            // Add attachments if provided
            if (request.Attachments?.Any() == true)
            {
                message.Attachments = new List<Attachment>();
                
                foreach (var attachmentPath in request.Attachments.Take(5)) // Limit to 5 attachments
                {
                    try
                    {
                        if (File.Exists(attachmentPath))
                        {
                            var fileBytes = File.ReadAllBytes(attachmentPath);
                            var fileName = Path.GetFileName(attachmentPath);
                            
                            message.Attachments.Add(new Attachment
                            {
                                Content = Convert.ToBase64String(fileBytes),
                                Filename = fileName,
                                Type = GetMimeType(fileName),
                                Disposition = "attachment"
                            });
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning("Failed to attach file {FilePath}: {Error}", attachmentPath, ex.Message);
                    }
                }
            }

            return message;
        }

        private static string ExtractMessageId(Response response)
        {
            try
            {
                var headers = response.Headers;
                if (headers?.Contains("X-Message-Id") == true)
                {
                    var messageIdValues = headers.GetValues("X-Message-Id");
                    return messageIdValues.FirstOrDefault() ?? Guid.NewGuid().ToString();
                }
            }
            catch
            {
                // Ignore header parsing errors
            }
            
            return Guid.NewGuid().ToString();
        }

        private static string? ParseSendGridError(string errorBody)
        {
            try
            {
                if (string.IsNullOrEmpty(errorBody))
                    return null;

                var errorResponse = JsonSerializer.Deserialize<SendGridErrorResponse>(errorBody);
                var firstError = errorResponse?.Errors?.FirstOrDefault();
                
                return firstError?.Message ?? "Unknown SendGrid error";
            }
            catch
            {
                return null;
            }
        }

        private static string GetMimeType(string fileName)
        {
            var extension = Path.GetExtension(fileName).ToLowerInvariant();
            
            return extension switch
            {
                ".pdf" => "application/pdf",
                ".doc" => "application/msword",
                ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                ".xls" => "application/vnd.ms-excel",
                ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                ".png" => "image/png",
                ".jpg" or ".jpeg" => "image/jpeg",
                ".gif" => "image/gif",
                ".txt" => "text/plain",
                ".csv" => "text/csv",
                _ => "application/octet-stream"
            };
        }
    }

    public class SendGridOptions
    {
        public const string SectionName = "SendGrid";
        
        public string? ApiKey { get; set; }
        public string DefaultFromEmail { get; set; } = "noreply@singleclin.com";
        public string DefaultFromName { get; set; } = "SingleClin";
        public bool EnableClickTracking { get; set; } = true;
        public bool EnableOpenTracking { get; set; } = true;
        public int TimeoutSeconds { get; set; } = 30;
    }

    internal class SendGridErrorResponse
    {
        public List<SendGridError>? Errors { get; set; }
    }

    internal class SendGridError
    {
        public string? Message { get; set; }
        public string? Field { get; set; }
        public string? Help { get; set; }
    }
}