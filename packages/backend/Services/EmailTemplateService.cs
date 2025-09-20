using System.Text.Json;
using System.Text.RegularExpressions;
using SingleClin.API.DTOs.EmailTemplate;

namespace SingleClin.API.Services
{
    /// <summary>
    /// Service for processing and rendering email templates
    /// </summary>
    public class EmailTemplateService : IEmailTemplateService
    {
        private readonly ILogger<EmailTemplateService> _logger;
        private readonly IWebHostEnvironment _environment;
        private readonly string _templatesPath;

        public EmailTemplateService(
            ILogger<EmailTemplateService> logger,
            IWebHostEnvironment environment)
        {
            _logger = logger;
            _environment = environment;
            _templatesPath = Path.Combine(_environment.ContentRootPath, "Templates", "Email");
        }

        public async Task<RenderedEmailTemplate> RenderUserConfirmationAsync(
            UserConfirmationTemplateData templateData,
            bool includeHtml = true,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Rendering user confirmation template for user {UserEmail}", templateData.UserEmail);

                const string templateName = "UserConfirmation";

                // Generate subject
                var subject = GenerateUserConfirmationSubject(templateData);

                // Render HTML content if requested
                string? htmlContent = null;
                if (includeHtml)
                {
                    var htmlTemplate = await GetHtmlTemplateAsync(templateName, cancellationToken);
                    htmlContent = ProcessTemplate(htmlTemplate, templateData);
                }

                // Render text content
                var textTemplate = await GetTextTemplateAsync(templateName, cancellationToken);
                var textContent = ProcessTemplate(textTemplate, templateData);

                var renderedTemplate = RenderedEmailTemplate.Create(
                    templateName,
                    subject,
                    htmlContent,
                    textContent);

                _logger.LogInformation("Successfully rendered user confirmation template for user {UserEmail}", templateData.UserEmail);
                return renderedTemplate;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rendering user confirmation template for user {UserEmail}", templateData.UserEmail);
                throw;
            }
        }

        public async Task<RenderedEmailTemplate> RenderLowBalanceNotificationAsync(
            LowBalanceTemplateData templateData,
            bool includeHtml = true,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Rendering low balance notification template for user {UserId}", templateData.UserId);

                const string templateName = "LowBalanceNotification";

                // Generate subject
                var subject = GenerateLowBalanceSubject(templateData);

                // Render HTML content if requested
                string? htmlContent = null;
                if (includeHtml)
                {
                    var htmlTemplate = await GetHtmlTemplateAsync(templateName, cancellationToken);
                    htmlContent = ProcessTemplate(htmlTemplate, templateData);
                }

                // Render text content
                var textTemplate = await GetTextTemplateAsync(templateName, cancellationToken);
                var textContent = ProcessTemplate(textTemplate, templateData);

                var renderedTemplate = RenderedEmailTemplate.Create(
                    templateName,
                    subject,
                    htmlContent,
                    textContent);

                _logger.LogInformation("Successfully rendered low balance notification template for user {UserId}", templateData.UserId);
                return renderedTemplate;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rendering low balance notification template for user {UserId}", templateData.UserId);
                throw;
            }
        }

        public async Task<RenderedEmailTemplate> RenderTemplateAsync(
            string templateName,
            object templateData,
            bool includeHtml = true,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Rendering template {TemplateName}", templateName);

                // Generate a basic subject (can be enhanced based on template type)
                var subject = $"Notificação - {templateName}";

                // Render HTML content if requested
                string? htmlContent = null;
                if (includeHtml)
                {
                    var htmlTemplate = await GetHtmlTemplateAsync(templateName, cancellationToken);
                    htmlContent = ProcessTemplate(htmlTemplate, templateData);
                }

                // Render text content
                var textTemplate = await GetTextTemplateAsync(templateName, cancellationToken);
                var textContent = ProcessTemplate(textTemplate, templateData);

                var renderedTemplate = RenderedEmailTemplate.Create(
                    templateName,
                    subject,
                    htmlContent,
                    textContent);

                _logger.LogInformation("Successfully rendered template {TemplateName}", templateName);
                return renderedTemplate;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rendering template {TemplateName}", templateName);
                throw;
            }
        }

        public async Task<string> GetHtmlTemplateAsync(string templateName, CancellationToken cancellationToken = default)
        {
            try
            {
                var filePath = Path.Combine(_templatesPath, $"{templateName}.html");

                if (!File.Exists(filePath))
                {
                    throw new FileNotFoundException($"HTML template file not found: {filePath}");
                }

                var content = await File.ReadAllTextAsync(filePath, cancellationToken);

                _logger.LogDebug("Loaded HTML template {TemplateName} from {FilePath}", templateName, filePath);
                return content;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading HTML template {TemplateName}", templateName);
                throw;
            }
        }

        public async Task<string> GetTextTemplateAsync(string templateName, CancellationToken cancellationToken = default)
        {
            try
            {
                var filePath = Path.Combine(_templatesPath, $"{templateName}.txt");

                if (!File.Exists(filePath))
                {
                    throw new FileNotFoundException($"Text template file not found: {filePath}");
                }

                var content = await File.ReadAllTextAsync(filePath, cancellationToken);

                _logger.LogDebug("Loaded text template {TemplateName} from {FilePath}", templateName, filePath);
                return content;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading text template {TemplateName}", templateName);
                throw;
            }
        }

        /// <summary>
        /// Processes template content by replacing variables with actual values
        /// </summary>
        /// <param name="template">Template content</param>
        /// <param name="data">Data object to extract values from</param>
        /// <returns>Processed template content</returns>
        private string ProcessTemplate(string template, object data)
        {
            try
            {
                // Convert object to dictionary for easier processing
                var properties = GetObjectProperties(data);

                // Replace simple variables {{variableName}}
                var result = Regex.Replace(template, @"\{\{(\w+)\}\}", match =>
                {
                    var propertyName = match.Groups[1].Value;
                    if (properties.TryGetValue(propertyName, out var value))
                    {
                        return value?.ToString() ?? string.Empty;
                    }

                    _logger.LogWarning("Template variable {PropertyName} not found in data", propertyName);
                    return match.Value; // Keep original if not found
                });

                // Process conditional blocks {{#condition}}content{{/condition}}
                result = ProcessConditionalBlocks(result, properties);

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing template");
                throw;
            }
        }

        /// <summary>
        /// Processes conditional blocks in templates
        /// </summary>
        /// <param name="template">Template content</param>
        /// <param name="properties">Property dictionary</param>
        /// <returns>Processed template</returns>
        private string ProcessConditionalBlocks(string template, Dictionary<string, object?> properties)
        {
            // Handle {{#condition}}content{{/condition}} blocks
            var conditionalPattern = @"\{\{#(\w+)\}\}(.*?)\{\{/\1\}\}";

            return Regex.Replace(template, conditionalPattern, match =>
            {
                var conditionName = match.Groups[1].Value;
                var content = match.Groups[2].Value;

                if (properties.TryGetValue(conditionName, out var value))
                {
                    // Check if condition is true
                    bool isTrue = false;
                    if (value is bool boolValue)
                    {
                        isTrue = boolValue;
                    }
                    else if (value is string stringValue)
                    {
                        isTrue = !string.IsNullOrEmpty(stringValue);
                    }
                    else if (value != null)
                    {
                        isTrue = true;
                    }

                    return isTrue ? content : string.Empty;
                }

                return string.Empty;
            }, RegexOptions.Singleline);
        }

        /// <summary>
        /// Extracts properties from an object into a dictionary
        /// </summary>
        /// <param name="obj">Object to extract properties from</param>
        /// <returns>Dictionary of property name-value pairs</returns>
        private Dictionary<string, object?> GetObjectProperties(object obj)
        {
            var properties = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);

            if (obj == null)
                return properties;

            var type = obj.GetType();
            var propertyInfos = type.GetProperties();

            foreach (var propertyInfo in propertyInfos)
            {
                try
                {
                    var value = propertyInfo.GetValue(obj);
                    properties[propertyInfo.Name] = value;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error getting property {PropertyName} from object", propertyInfo.Name);
                }
            }

            return properties;
        }

        /// <summary>
        /// Generates subject line for user confirmation emails
        /// </summary>
        /// <param name="templateData">Template data</param>
        /// <returns>Generated subject line</returns>
        private string GenerateUserConfirmationSubject(UserConfirmationTemplateData templateData)
        {
            return $"Bem-vindo ao SingleClin, {templateData.UserName}!";
        }

        /// <summary>
        /// Generates subject line for low balance notifications
        /// </summary>
        /// <param name="templateData">Template data</param>
        /// <returns>Generated subject line</returns>
        private string GenerateLowBalanceSubject(LowBalanceTemplateData templateData)
        {
            var creditText = templateData.CurrentBalance == 1 ? "crédito" : "créditos";
            return $"Saldo Baixo - {templateData.CurrentBalance} {creditText} restante{(templateData.IsPlural ? "s" : "")}";
        }
    }
}