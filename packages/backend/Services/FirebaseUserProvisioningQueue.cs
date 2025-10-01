using Hangfire;
using Microsoft.AspNetCore.DataProtection;
using SingleClin.API.Jobs;

namespace SingleClin.API.Services;

public class FirebaseUserProvisioningQueue : IFirebaseUserProvisioningQueue
{
    private readonly IBackgroundJobClient _backgroundJobClient;
    private readonly IDataProtector _protector;
    private readonly ILogger<FirebaseUserProvisioningQueue> _logger;

    public FirebaseUserProvisioningQueue(
        IBackgroundJobClient backgroundJobClient,
        IDataProtectionProvider dataProtectionProvider,
        ILogger<FirebaseUserProvisioningQueue> logger)
    {
        _backgroundJobClient = backgroundJobClient;
        _protector = dataProtectionProvider.CreateProtector("FirebaseUserProvisioning");
        _logger = logger;
    }

    public Task EnqueueAsync(Guid userId, string email, string password, string? displayName)
    {
        var protectedPassword = _protector.Protect(password);
        _backgroundJobClient.Enqueue<FirebaseUserProvisioningJob>(job =>
            job.ExecuteAsync(userId, email, protectedPassword, displayName));

        _logger.LogInformation("Enqueued Firebase provisioning job for UserId={UserId}", userId);
        return Task.CompletedTask;
    }
}
