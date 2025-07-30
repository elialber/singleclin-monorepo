namespace SingleClin.API.DTOs;

public class ResponseWrapper<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public List<string> Errors { get; set; } = new List<string>();
    public int StatusCode { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // Factory methods for creating responses
    public static ResponseWrapper<T> SuccessResponse(T data, string? message = null, int statusCode = 200)
    {
        return new ResponseWrapper<T>
        {
            Success = true,
            Data = data,
            Message = message ?? "Operation completed successfully",
            StatusCode = statusCode
        };
    }

    public static ResponseWrapper<T> ErrorResponse(string message, int statusCode = 400, List<string>? errors = null)
    {
        return new ResponseWrapper<T>
        {
            Success = false,
            Message = message,
            StatusCode = statusCode,
            Errors = errors ?? new List<string>()
        };
    }

    public static ResponseWrapper<T> NotFoundResponse(string message = "Resource not found")
    {
        return new ResponseWrapper<T>
        {
            Success = false,
            Message = message,
            StatusCode = 404
        };
    }

    public static ResponseWrapper<T> UnauthorizedResponse(string message = "Unauthorized access")
    {
        return new ResponseWrapper<T>
        {
            Success = false,
            Message = message,
            StatusCode = 401
        };
    }

    public static ResponseWrapper<T> ForbiddenResponse(string message = "Access forbidden")
    {
        return new ResponseWrapper<T>
        {
            Success = false,
            Message = message,
            StatusCode = 403
        };
    }

    public static ResponseWrapper<T> ValidationErrorResponse(List<string> errors, string message = "Validation failed")
    {
        return new ResponseWrapper<T>
        {
            Success = false,
            Message = message,
            StatusCode = 422,
            Errors = errors
        };
    }

    // Alias methods for backward compatibility
    public static ResponseWrapper<T> CreateSuccess(T data, string? message = null, int statusCode = 200)
    {
        return SuccessResponse(data, message, statusCode);
    }

    public static ResponseWrapper<T> CreateFailure(string message, T? data = default, int statusCode = 400, List<string>? errors = null)
    {
        return new ResponseWrapper<T>
        {
            Success = false,
            Data = data,
            Message = message,
            StatusCode = statusCode,
            Errors = errors ?? new List<string>()
        };
    }
}

// Non-generic version for responses without data
public class ResponseWrapper : ResponseWrapper<object>
{
    public static ResponseWrapper SuccessResponse(string? message = null, int statusCode = 200)
    {
        return new ResponseWrapper
        {
            Success = true,
            Message = message ?? "Operation completed successfully",
            StatusCode = statusCode
        };
    }

    public new static ResponseWrapper ErrorResponse(string message, int statusCode = 400, List<string>? errors = null)
    {
        return new ResponseWrapper
        {
            Success = false,
            Message = message,
            StatusCode = statusCode,
            Errors = errors ?? new List<string>()
        };
    }

    // Alias methods for backward compatibility
    public static ResponseWrapper CreateSuccess(object? data = null, string? message = null, int statusCode = 200)
    {
        return new ResponseWrapper
        {
            Success = true,
            Data = data,
            Message = message ?? "Operation completed successfully",
            StatusCode = statusCode
        };
    }

    public new static ResponseWrapper CreateFailure(string message, object? data = null, int statusCode = 400, List<string>? errors = null)
    {
        return new ResponseWrapper
        {
            Success = false,
            Data = data,
            Message = message,
            StatusCode = statusCode,
            Errors = errors ?? new List<string>()
        };
    }
}