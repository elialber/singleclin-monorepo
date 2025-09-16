using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using SingleClin.API.Extensions;
using System.Text;

namespace SingleClin.API.Tests.Extensions;

public class AuthenticationExtensionsTests
{
    private IServiceCollection CreateServiceCollection()
    {
        return new ServiceCollection()
            .AddLogging();
    }

    private IConfiguration CreateConfiguration(Dictionary<string, string> settings)
    {
        return new ConfigurationBuilder()
            .AddInMemoryCollection(settings!)
            .Build();
    }

    [Fact]
    public void AddFirebaseAuthentication_ValidConfiguration_ShouldConfigureAuthentication()
    {
        // Arrange
        var services = CreateServiceCollection();
        var configuration = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = "ThisIsAVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting12345",
            ["JWT:Issuer"] = "test-issuer",
            ["JWT:Audience"] = "test-audience"
        });

        // Act
        services.AddFirebaseAuthentication(configuration);

        // Assert
        var serviceProvider = services.BuildServiceProvider();

        // Verify authentication services are registered
        var authSchemeProvider = serviceProvider.GetService<IAuthenticationSchemeProvider>();
        authSchemeProvider.Should().NotBeNull();

        // Verify JWT Bearer scheme is registered
        var jwtBearerOptions = serviceProvider.GetService<Microsoft.Extensions.Options.IOptionsMonitor<JwtBearerOptions>>();
        jwtBearerOptions.Should().NotBeNull();

        var options = jwtBearerOptions!.Get(JwtBearerDefaults.AuthenticationScheme);
        options.Should().NotBeNull();
    }

    [Fact]
    public void AddFirebaseAuthentication_ValidConfiguration_ShouldConfigureTokenValidationParameters()
    {
        // Arrange
        var services = CreateServiceCollection();
        var secretKey = "ThisIsAVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting12345";
        var issuer = "test-issuer";
        var audience = "test-audience";

        var configuration = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = secretKey,
            ["JWT:Issuer"] = issuer,
            ["JWT:Audience"] = audience
        });

        // Act
        services.AddFirebaseAuthentication(configuration);

        // Assert
        var serviceProvider = services.BuildServiceProvider();
        var jwtBearerOptions = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptionsMonitor<JwtBearerOptions>>();
        var options = jwtBearerOptions.Get(JwtBearerDefaults.AuthenticationScheme);

        // Verify token validation parameters
        var tokenValidationParams = options.TokenValidationParameters;
        tokenValidationParams.Should().NotBeNull();
        tokenValidationParams.ValidateIssuerSigningKey.Should().BeTrue();
        tokenValidationParams.ValidateIssuer.Should().BeTrue();
        tokenValidationParams.ValidIssuer.Should().Be(issuer);
        tokenValidationParams.ValidateAudience.Should().BeTrue();
        tokenValidationParams.ValidAudience.Should().Be(audience);
        tokenValidationParams.ValidateLifetime.Should().BeTrue();
        tokenValidationParams.ClockSkew.Should().Be(TimeSpan.Zero);

        // Verify signing key
        var symmetricSecurityKey = tokenValidationParams.IssuerSigningKey as SymmetricSecurityKey;
        symmetricSecurityKey.Should().NotBeNull();
        var expectedKey = new SymmetricSecurityKey(Encoding.ASCII.GetBytes(secretKey));
        symmetricSecurityKey!.Key.Should().BeEquivalentTo(expectedKey.Key);
    }

    [Fact]
    public void AddFirebaseAuthentication_ValidConfiguration_ShouldConfigureJwtBearerOptions()
    {
        // Arrange
        var services = CreateServiceCollection();
        var configuration = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = "ThisIsAVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting12345",
            ["JWT:Issuer"] = "test-issuer",
            ["JWT:Audience"] = "test-audience"
        });

        // Act
        services.AddFirebaseAuthentication(configuration);

        // Assert
        var serviceProvider = services.BuildServiceProvider();
        var jwtBearerOptions = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptionsMonitor<JwtBearerOptions>>();
        var options = jwtBearerOptions.Get(JwtBearerDefaults.AuthenticationScheme);

        options.RequireHttpsMetadata.Should().BeFalse(); // Development setting
        options.SaveToken.Should().BeTrue();
        options.Events.Should().NotBeNull();
    }

    [Fact]
    public void AddFirebaseAuthentication_MissingSecretKey_ShouldThrowException()
    {
        // Arrange
        var services = CreateServiceCollection();
        var configuration = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:Issuer"] = "test-issuer",
            ["JWT:Audience"] = "test-audience"
            // Missing JWT:SecretKey
        });

        // Act & Assert
        var exception = Assert.Throws<InvalidOperationException>(() =>
            services.AddFirebaseAuthentication(configuration));

        exception.Message.Should().Be("JWT:SecretKey is not configured");
    }

    [Fact]
    public void AddFirebaseAuthentication_EmptySecretKey_ShouldThrowException()
    {
        // Arrange
        var services = CreateServiceCollection();
        var settings = new Dictionary<string, string>
        {
            ["JWT:Issuer"] = "test-issuer",
            ["JWT:Audience"] = "test-audience",
            ["JWT:SecretKey"] = ""
        };

        var configuration = CreateConfiguration(settings);

        // Act & Assert - Empty string produces zero-length byte array which is invalid for SymmetricSecurityKey
        var exception = Assert.Throws<ArgumentException>(() =>
        {
            services.AddFirebaseAuthentication(configuration);
            var serviceProvider = services.BuildServiceProvider();
            var jwtBearerOptions = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptionsMonitor<JwtBearerOptions>>();
            // Exception thrown when trying to access the configured options
            jwtBearerOptions.Get(JwtBearerDefaults.AuthenticationScheme);
        });

        exception.Message.Should().Contain("key length is zero");
    }

    [Fact]
    public void AddFirebaseAuthentication_WhitespaceSecretKey_ShouldCreateWeakKey()
    {
        // Arrange
        var services = CreateServiceCollection();
        var secretKey = "   "; // 3 spaces
        var settings = new Dictionary<string, string>
        {
            ["JWT:Issuer"] = "test-issuer",
            ["JWT:Audience"] = "test-audience",
            ["JWT:SecretKey"] = secretKey
        };

        var configuration = CreateConfiguration(settings);

        // Act - Whitespace strings create weak but non-zero length keys
        services.AddFirebaseAuthentication(configuration);

        // Assert - Verify that configuration succeeds but creates weak security
        var serviceProvider = services.BuildServiceProvider();
        var jwtBearerOptions = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptionsMonitor<JwtBearerOptions>>();
        var options = jwtBearerOptions.Get(JwtBearerDefaults.AuthenticationScheme);

        // The key will be created with space characters (weak security)
        var symmetricKey = options.TokenValidationParameters.IssuerSigningKey as SymmetricSecurityKey;
        symmetricKey.Should().NotBeNull();

        // This is a security concern - whitespace keys create weak security
        var expectedKeyBytes = System.Text.Encoding.ASCII.GetBytes(secretKey);
        symmetricKey!.Key.Should().BeEquivalentTo(expectedKeyBytes);
        symmetricKey.Key.Length.Should().Be(3); // 3 space characters
    }

    [Fact]
    public void AddFirebaseAuthentication_NullSecretKey_ShouldThrowException()
    {
        // Arrange
        var services = CreateServiceCollection();
        var settings = new Dictionary<string, string>
        {
            ["JWT:Issuer"] = "test-issuer",
            ["JWT:Audience"] = "test-audience"
            // Missing JWT:SecretKey (null case)
        };

        var configuration = CreateConfiguration(settings);

        // Act & Assert
        var exception = Assert.Throws<InvalidOperationException>(() =>
            services.AddFirebaseAuthentication(configuration));

        exception.Message.Should().Be("JWT:SecretKey is not configured");
    }

    [Fact]
    public void AddFirebaseAuthentication_ShouldConfigureDefaultAuthenticationSchemes()
    {
        // Arrange
        var services = CreateServiceCollection();
        var configuration = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = "ThisIsAVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting12345",
            ["JWT:Issuer"] = "test-issuer",
            ["JWT:Audience"] = "test-audience"
        });

        // Act
        services.AddFirebaseAuthentication(configuration);

        // Assert
        var serviceProvider = services.BuildServiceProvider();
        var authOptions = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptionsMonitor<AuthenticationOptions>>();
        var options = authOptions.Get(Microsoft.Extensions.Options.Options.DefaultName);

        options.DefaultAuthenticateScheme.Should().Be(JwtBearerDefaults.AuthenticationScheme);
        options.DefaultChallengeScheme.Should().Be(JwtBearerDefaults.AuthenticationScheme);
    }

    [Fact]
    public void AddFirebaseAuthentication_ShouldReturnServiceCollection()
    {
        // Arrange
        var services = CreateServiceCollection();
        var configuration = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = "ThisIsAVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting12345",
            ["JWT:Issuer"] = "test-issuer",
            ["JWT:Audience"] = "test-audience"
        });

        // Act
        var result = services.AddFirebaseAuthentication(configuration);

        // Assert
        result.Should().BeSameAs(services);
    }

    [Fact]
    public void AddFirebaseAuthentication_MultipleConfigurations_ShouldUseLatest()
    {
        // Arrange
        var services = CreateServiceCollection();

        var firstConfig = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = "ThisIsAVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting12345",
            ["JWT:Issuer"] = "first-issuer",
            ["JWT:Audience"] = "first-audience"
        });

        var secondConfig = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = "AnotherVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting67890",
            ["JWT:Issuer"] = "second-issuer",
            ["JWT:Audience"] = "second-audience"
        });

        // Act
        services.AddFirebaseAuthentication(firstConfig);
        services.AddFirebaseAuthentication(secondConfig);

        // Assert
        var serviceProvider = services.BuildServiceProvider();
        var jwtBearerOptions = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptionsMonitor<JwtBearerOptions>>();
        var options = jwtBearerOptions.Get(JwtBearerDefaults.AuthenticationScheme);

        // Should use the second (latest) configuration
        options.TokenValidationParameters.ValidIssuer.Should().Be("second-issuer");
        options.TokenValidationParameters.ValidAudience.Should().Be("second-audience");

        var expectedKey = new SymmetricSecurityKey(Encoding.ASCII.GetBytes("AnotherVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting67890"));
        var actualKey = options.TokenValidationParameters.IssuerSigningKey as SymmetricSecurityKey;
        actualKey!.Key.Should().BeEquivalentTo(expectedKey.Key);
    }

    [Fact]
    public void AddFirebaseAuthentication_MinimumValidConfiguration_ShouldSucceed()
    {
        // Arrange
        var services = CreateServiceCollection();
        var configuration = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = "MinimumLengthSecretKeyThatIs32Ch", // Exactly 32 characters
            // Missing optional issuer and audience - should still work
        });

        // Act & Assert - Should not throw
        services.AddFirebaseAuthentication(configuration);

        var serviceProvider = services.BuildServiceProvider();
        var jwtBearerOptions = serviceProvider.GetService<Microsoft.Extensions.Options.IOptionsMonitor<JwtBearerOptions>>();
        jwtBearerOptions.Should().NotBeNull();
    }

    [Fact]
    public void AddFirebaseAuthentication_WithNullIssuerAndAudience_ShouldConfigureCorrectly()
    {
        // Arrange
        var services = CreateServiceCollection();
        var configuration = CreateConfiguration(new Dictionary<string, string>
        {
            ["JWT:SecretKey"] = "ThisIsAVeryLongSecretKeyThatIsAtLeast32CharactersLongForTesting12345"
            // No issuer or audience specified
        });

        // Act
        services.AddFirebaseAuthentication(configuration);

        // Assert
        var serviceProvider = services.BuildServiceProvider();
        var jwtBearerOptions = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptionsMonitor<JwtBearerOptions>>();
        var options = jwtBearerOptions.Get(JwtBearerDefaults.AuthenticationScheme);

        options.TokenValidationParameters.ValidIssuer.Should().BeNull();
        options.TokenValidationParameters.ValidAudience.Should().BeNull();
        options.TokenValidationParameters.ValidateIssuer.Should().BeTrue();
        options.TokenValidationParameters.ValidateAudience.Should().BeTrue();
    }
}