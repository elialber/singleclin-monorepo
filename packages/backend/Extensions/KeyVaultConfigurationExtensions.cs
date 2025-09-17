using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

namespace SingleClin.API.Extensions;

/// <summary>
/// Extension methods for configuring Azure Key Vault integration
/// </summary>
public static class KeyVaultConfigurationExtensions
{
    /// <summary>
    /// Adds Azure Key Vault as a configuration source
    /// </summary>
    /// <param name="builder">The configuration builder</param>
    /// <param name="environment">The hosting environment</param>
    /// <returns>The configuration builder</returns>
    public static IConfigurationBuilder AddAzureKeyVault(
        this IConfigurationBuilder builder,
        IHostEnvironment environment)
    {
        // Build temporary configuration to get Key Vault settings
        var tempConfig = builder.Build();

        var keyVaultUrl = tempConfig["AzureKeyVault:VaultUrl"];
        var useMangedIdentity = tempConfig.GetValue<bool>("AzureKeyVault:UseMangedIdentity", true);

        if (string.IsNullOrEmpty(keyVaultUrl))
        {
            // Key Vault not configured, skip
            return builder;
        }

        try
        {
            var credential = GetAzureCredential(tempConfig, environment, useMangedIdentity);

            var secretClient = new SecretClient(new Uri(keyVaultUrl), credential);

            builder.AddAzureKeyVault(secretClient, new PrefixedKeyVaultSecretManager());
        }
        catch (Exception ex)
        {
            // Log the error but don't fail the startup
            Console.WriteLine($"Warning: Failed to configure Key Vault: {ex.Message}");

            // In development, we might not have Key Vault configured
            if (!environment.IsDevelopment())
            {
                throw;
            }
        }

        return builder;
    }

    /// <summary>
    /// Gets the appropriate Azure credential based on environment and configuration
    /// </summary>
    private static Azure.Core.TokenCredential GetAzureCredential(
        IConfiguration config,
        IHostEnvironment environment,
        bool useMangedIdentity)
    {
        if (useMangedIdentity && !environment.IsDevelopment())
        {
            // Use Managed Identity in production (Container Apps)
            return new ManagedIdentityCredential();
        }

        if (environment.IsDevelopment())
        {
            // In development, try multiple credential sources in order
            var options = new DefaultAzureCredentialOptions
            {
                // Exclude interactive browser credential in containers
                ExcludeInteractiveBrowserCredential = true,
                // Try Azure CLI first (most common for local development)
                ExcludeAzureCliCredential = false,
                // Then try Visual Studio credential
                ExcludeVisualStudioCredential = false,
                // Then environment variables
                ExcludeEnvironmentCredential = false
            };

            return new DefaultAzureCredential(options);
        }

        // For non-development environments without managed identity
        var tenantId = config["AzureKeyVault:TenantId"];
        var clientId = config["AzureKeyVault:ClientId"];
        var clientSecret = config["AzureKeyVault:ClientSecret"];

        if (!string.IsNullOrEmpty(tenantId) &&
            !string.IsNullOrEmpty(clientId) &&
            !string.IsNullOrEmpty(clientSecret))
        {
            return new ClientSecretCredential(tenantId, clientId, clientSecret);
        }

        // Fallback to default credential
        return new DefaultAzureCredential();
    }
}

/// <summary>
/// Custom Key Vault secret manager that handles secret name transformations
/// </summary>
public class PrefixedKeyVaultSecretManager : KeyVaultSecretManager
{
    /// <summary>
    /// Transforms Key Vault secret names to configuration keys
    /// </summary>
    /// <param name="secret">The Key Vault secret</param>
    /// <returns>The configuration key</returns>
    public override string GetKey(KeyVaultSecret secret)
    {
        // Transform kebab-case secret names to configuration format
        var key = secret.Name.Replace("-", ":");

        // Map specific secrets to configuration keys
        return key switch
        {
            "database:connection:string" => "ConnectionStrings:DefaultConnection",
            "redis:connection:string" => "Redis:ConnectionString",
            "azure:storage:connection:string" => "AzureStorage:ConnectionString",
            "jwt:secret:key" => "JWT:SecretKey",
            "firebase:service:account" => "Firebase:ServiceAccount",
            _ => key
        };
    }

    /// <summary>
    /// Determines if a secret should be loaded
    /// </summary>
    /// <param name="secret">The Key Vault secret</param>
    /// <returns>True if the secret should be loaded</returns>
    public override bool Load(SecretProperties secret)
    {
        // Only load enabled secrets
        return secret.Enabled ?? false;
    }
}