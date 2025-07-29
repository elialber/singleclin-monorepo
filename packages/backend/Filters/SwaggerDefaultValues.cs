using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using Microsoft.OpenApi.Any;

namespace SingleClin.API.Filters;

/// <summary>
/// Swagger operation filter to improve API documentation
/// </summary>
public class SwaggerDefaultValues : IOperationFilter
{
    /// <summary>
    /// Apply the filter to the operation
    /// </summary>
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var apiDescription = context.ApiDescription;

        // Update operation ID if needed
        if (string.IsNullOrEmpty(operation.OperationId))
        {
            operation.OperationId = context.MethodInfo.Name;
        }

        // Add response headers for all responses
        foreach (var response in operation.Responses.Values)
        {
            response.Headers ??= new Dictionary<string, OpenApiHeader>();
            
            if (!response.Headers.ContainsKey("X-Request-Id"))
            {
                response.Headers.Add("X-Request-Id", new OpenApiHeader
                {
                    Description = "Unique request identifier for tracking",
                    Schema = new OpenApiSchema { Type = "string" }
                });
            }
        }

        // Parameters
        if (operation.Parameters == null)
        {
            return;
        }

        foreach (var parameter in operation.Parameters)
        {
            var description = apiDescription.ParameterDescriptions.FirstOrDefault(p => p.Name == parameter.Name);
            
            if (description != null)
            {
                // Set defaults
                parameter.Description ??= description.ModelMetadata?.Description;

                if (parameter.Schema.Default == null && description.DefaultValue != null)
                {
                    // Create appropriate OpenAPI value based on type
                    var defaultValue = description.DefaultValue;
                    parameter.Schema.Default = defaultValue switch
                    {
                        string str => new OpenApiString(str),
                        int i => new OpenApiInteger(i),
                        long l => new OpenApiLong(l),
                        double d => new OpenApiDouble(d),
                        bool b => new OpenApiBoolean(b),
                        _ => null
                    };
                }

                parameter.Required |= description.IsRequired;
            }
        }
    }
}