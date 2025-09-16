namespace SingleClin.API.Exceptions;

/// <summary>
/// Exception thrown when a plan is not found
/// </summary>
public class PlanNotFoundException : Exception
{
    public Guid PlanId { get; }

    public PlanNotFoundException(Guid planId)
        : base($"Plan with ID '{planId}' was not found")
    {
        PlanId = planId;
    }

    public PlanNotFoundException(Guid planId, string message)
        : base(message)
    {
        PlanId = planId;
    }

    public PlanNotFoundException(Guid planId, string message, Exception innerException)
        : base(message, innerException)
    {
        PlanId = planId;
    }
}

/// <summary>
/// Exception thrown when attempting to create a plan with a duplicate name
/// </summary>
public class DuplicatePlanNameException : Exception
{
    public string PlanName { get; }

    public DuplicatePlanNameException(string planName)
        : base($"A plan with the name '{planName}' already exists")
    {
        PlanName = planName;
    }

    public DuplicatePlanNameException(string planName, string message)
        : base(message)
    {
        PlanName = planName;
    }

    public DuplicatePlanNameException(string planName, string message, Exception innerException)
        : base(message, innerException)
    {
        PlanName = planName;
    }
}

/// <summary>
/// Exception thrown when plan validation fails
/// </summary>
public class PlanValidationException : Exception
{
    public IEnumerable<string> ValidationErrors { get; }

    public PlanValidationException(IEnumerable<string> validationErrors)
        : base($"Plan validation failed: {string.Join("; ", validationErrors)}")
    {
        ValidationErrors = validationErrors;
    }

    public PlanValidationException(string validationError)
        : base($"Plan validation failed: {validationError}")
    {
        ValidationErrors = new[] { validationError };
    }

    public PlanValidationException(IEnumerable<string> validationErrors, Exception innerException)
        : base($"Plan validation failed: {string.Join("; ", validationErrors)}", innerException)
    {
        ValidationErrors = validationErrors;
    }
}

/// <summary>
/// Exception thrown when attempting to perform invalid operations on plans
/// </summary>
public class InvalidPlanOperationException : Exception
{
    public Guid? PlanId { get; }
    public string Operation { get; }

    public InvalidPlanOperationException(string operation, string message)
        : base(message)
    {
        Operation = operation;
    }

    public InvalidPlanOperationException(Guid planId, string operation, string message)
        : base(message)
    {
        PlanId = planId;
        Operation = operation;
    }

    public InvalidPlanOperationException(string operation, string message, Exception innerException)
        : base(message, innerException)
    {
        Operation = operation;
    }

    public InvalidPlanOperationException(Guid planId, string operation, string message, Exception innerException)
        : base(message, innerException)
    {
        PlanId = planId;
        Operation = operation;
    }
}