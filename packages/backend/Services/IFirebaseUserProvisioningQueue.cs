namespace SingleClin.API.Services;

public interface IFirebaseUserProvisioningQueue
{
    Task EnqueueAsync(Guid userId, string email, string password, string? displayName);
}
