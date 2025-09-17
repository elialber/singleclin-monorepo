using Microsoft.Extensions.Diagnostics.HealthChecks;
using Azure.Security.KeyVault.Secrets;
using Azure.Identity;

namespace SingleClin.API.HealthChecks;

/// <summary>
/// Health check for Azure Key Vault connectivity
/// </summary>
public class KeyVaultHealthCheck : IHealthCheck
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<KeyVaultHealthCheck> _logger;

    public KeyVaultHealthCheck(IConfiguration configuration, ILogger<KeyVaultHealthCheck> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// Checks the health of the Key Vault connection
    /// </summary>
    /// <param name="context">Health check context</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Health check result</returns>
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var keyVaultUrl = _configuration["AzureKeyVault:VaultUrl"];

            if (string.IsNullOrEmpty(keyVaultUrl))
            {
                return HealthCheckResult.Healthy("Key Vault not configured (development mode)");
            }

            var useMangedIdentity = _configuration.GetValue<bool>("AzureKeyVault:UseMangedIdentity", true);
            var credential = GetCredential(useMangedIdentity);

            var secretClient = new SecretClient(new Uri(keyVaultUrl), credential);

            // Try to get a well-known secret to test connectivity
            // We'll try to get the database connection string as it should always exist
            var response = await secretClient.GetSecretAsync("database-connection-string", cancellationToken: cancellationToken);

            if (response?.Value != null)
            {
                var data = new Dictionary<string, object>
                {
                    ["vault_url"] = keyVaultUrl,
                    ["secret_name"] = "database-connection-string",
                    ["secret_version"] = response.Value.Properties.Version ?? "unknown",
                    ["secret_updated"] = response.Value.Properties.UpdatedOn?.ToString("O") ?? "unknown",
                    ["using_managed_identity"] = useMangedIdentity
                };

                return HealthCheckResult.Healthy("Successfully connected to Key Vault", data);
            }

            return HealthCheckResult.Degraded("Key Vault accessible but test secret not found");
        }
        catch (Azure.RequestFailedException ex) when (ex.Status == 404)
        {
            // Secret not found - Key Vault is accessible but secret doesn't exist
            var data = new Dictionary<string, object>
            {
                ["error"] = "Test secret not found",
                ["status_code"] = ex.Status,
                ["error_code"] = ex.ErrorCode ?? "unknown"
            };

            return HealthCheckResult.Degraded("Key Vault accessible but test secret not found", ex, data);
        }
        catch (Azure.RequestFailedException ex) when (ex.Status == 401 || ex.Status == 403)
        {
            // Authentication/Authorization error
            var data = new Dictionary<string, object>
            {
                ["error"] = "Authentication/Authorization failed",
                ["status_code"] = ex.Status,
                ["error_code"] = ex.ErrorCode ?? "unknown"
            };

            _logger.LogError(ex, "Key Vault authentication failed");
            return HealthCheckResult.Unhealthy("Key Vault authentication failed", ex, data);
        }
        catch (Exception ex)
        {
            var data = new Dictionary<string, object>
            {
                ["error"] = ex.Message,
                ["error_type"] = ex.GetType().Name
            };

            _logger.LogError(ex, "Key Vault health check failed");
            return HealthCheckResult.Unhealthy("Key Vault connection failed", ex, data);
        }
    }

    private Azure.Core.TokenCredential GetCredential(bool useMangedIdentity)
    {
        if (useMangedIdentity)
        {
            return new ManagedIdentityCredential();
        }

        // For development, use default credential chain
        return new DefaultAzureCredential(new DefaultAzureCredentialOptions
        {
            ExcludeInteractiveBrowserCredential = true
        });
    }
}