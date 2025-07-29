using System.Net;
using System.Text.Json;
using SingleClin.API.DTOs;
using SingleClin.API.Exceptions;
using FluentValidation;

namespace SingleClin.API.Middleware;

public class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlerMiddleware> _logger;
    private readonly IWebHostEnvironment _environment;

    public GlobalExceptionHandlerMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionHandlerMiddleware> logger,
        IWebHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        _logger.LogError(exception, "An unhandled exception occurred");

        var response = context.Response;
        response.ContentType = "application/json";

        var responseWrapper = GetErrorResponse(exception);
        response.StatusCode = responseWrapper.StatusCode;

        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = true
        };

        var json = JsonSerializer.Serialize(responseWrapper, jsonOptions);
        await response.WriteAsync(json);
    }

    private ResponseWrapper GetErrorResponse(Exception exception)
    {
        return exception switch
        {
            // FluentValidation exceptions
            ValidationException validationEx => ResponseWrapper.ErrorResponse(
                "Validation failed", 
                400, 
                validationEx.Errors.Select(e => e.ErrorMessage).ToList()),

            // Plan-specific exceptions
            PlanNotFoundException planNotFoundEx => ResponseWrapper.ErrorResponse(planNotFoundEx.Message, 404),
            DuplicatePlanNameException duplicateNameEx => ResponseWrapper.ErrorResponse(duplicateNameEx.Message, 409),
            PlanValidationException planValidationEx => ResponseWrapper.ErrorResponse(
                "Plan validation failed", 
                400, 
                planValidationEx.ValidationErrors.ToList()),
            InvalidPlanOperationException invalidOpEx => ResponseWrapper.ErrorResponse(invalidOpEx.Message, 400),

            // General exceptions
            UnauthorizedAccessException => ResponseWrapper.ErrorResponse(exception.Message, 401),
            KeyNotFoundException => ResponseWrapper.ErrorResponse(exception.Message, 404),
            InvalidOperationException invalidOpEx when invalidOpEx.Message.Contains("not found") => 
                ResponseWrapper.ErrorResponse(invalidOpEx.Message, 404),
            InvalidOperationException invalidOpEx when invalidOpEx.Message.Contains("already exists") => 
                ResponseWrapper.ErrorResponse(invalidOpEx.Message, 409),
            InvalidOperationException invalidOpEx => ResponseWrapper.ErrorResponse(invalidOpEx.Message, 400),
            ArgumentException or ArgumentNullException => ResponseWrapper.ErrorResponse(exception.Message, 400),
            NotImplementedException => ResponseWrapper.ErrorResponse("This feature is not yet implemented", 501),
            TimeoutException => ResponseWrapper.ErrorResponse("The operation timed out", 408),
            _ => GetDefaultErrorResponse(exception)
        };
    }

    private ResponseWrapper GetDefaultErrorResponse(Exception exception)
    {
        var message = _environment.IsDevelopment() 
            ? exception.Message 
            : "An error occurred while processing your request";

        var errors = new List<string>();

        if (_environment.IsDevelopment())
        {
            errors.Add($"Exception Type: {exception.GetType().Name}");
            
            if (!string.IsNullOrEmpty(exception.StackTrace))
            {
                errors.Add($"Stack Trace: {exception.StackTrace}");
            }

            if (exception.InnerException != null)
            {
                errors.Add($"Inner Exception: {exception.InnerException.Message}");
            }
        }

        return ResponseWrapper.ErrorResponse(message, 500, errors);
    }
}

// Extension method to add the middleware
public static class GlobalExceptionHandlerMiddlewareExtensions
{
    public static IApplicationBuilder UseGlobalExceptionHandler(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<GlobalExceptionHandlerMiddleware>();
    }
}