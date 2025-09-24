namespace SingleClin.API.Middleware;

public class CorsHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<CorsHandlerMiddleware> _logger;
    private readonly string[] _allowedOrigins = {
        "http://localhost:3000",
        "http://localhost:3001",
        "http://localhost:4200",
        "http://localhost:5173",
        "http://localhost:5010",
        "capacitor://localhost",
        "http://localhost",
        "https://singleclin.com.br",
        "https://api.singleclin.com.br",
        "https://singleclin-frontend.proudbay-ea4166c5.eastus.azurecontainerapps.io"
    };

    public CorsHandlerMiddleware(RequestDelegate next, ILogger<CorsHandlerMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var origin = context.Request.Headers["Origin"].ToString();

        if (!string.IsNullOrEmpty(origin) && _allowedOrigins.Contains(origin))
        {
            context.Response.Headers["Access-Control-Allow-Origin"] = origin;
            context.Response.Headers["Access-Control-Allow-Credentials"] = "true";
            context.Response.Headers["Access-Control-Allow-Headers"] =
                "Content-Type, Authorization, X-Requested-With, Accept, Origin";
            context.Response.Headers["Access-Control-Allow-Methods"] =
                "GET, POST, PUT, DELETE, OPTIONS, PATCH";

            _logger.LogDebug("CORS headers set for origin: {Origin}", origin);
        }

        // Handle preflight requests
        if (context.Request.Method == "OPTIONS")
        {
            context.Response.StatusCode = 204;
            return;
        }

        await _next(context);
    }
}

public static class CorsHandlerMiddlewareExtensions
{
    public static IApplicationBuilder UseCorsHandler(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<CorsHandlerMiddleware>();
    }
}