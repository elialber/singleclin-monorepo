using Microsoft.Extensions.Logging;
using SingleClin.API.Data;

namespace SingleClin.API.Tests.Helpers;

public abstract class TestBase : IDisposable
{
    protected ApplicationDbContext DbContext { get; }
    protected Mock<ILogger> MockLogger { get; }

    protected TestBase()
    {
        DbContext = TestDbContextFactory.CreateInMemoryDbContext();
        MockLogger = new Mock<ILogger>();
    }

    public void Dispose()
    {
        DbContext?.Dispose();
        GC.SuppressFinalize(this);
    }
}

public abstract class TestBase<T> : TestBase
{
    protected Mock<ILogger<T>> MockTypedLogger { get; }

    protected TestBase() : base()
    {
        MockTypedLogger = MockHelpers.CreateMockLogger<T>();
    }
}