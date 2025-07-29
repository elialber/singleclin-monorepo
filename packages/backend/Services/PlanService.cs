using SingleClin.API.DTOs.Plan;
using SingleClin.API.DTOs.Common;
using SingleClin.API.Repositories;
using SingleClin.API.Data.Models;
using SingleClin.API.Exceptions;

namespace SingleClin.API.Services;

/// <summary>
/// Service implementation for Plan business logic
/// </summary>
public class PlanService : IPlanService
{
    private readonly IPlanRepository _planRepository;
    private readonly ILogger<PlanService> _logger;

    public PlanService(IPlanRepository planRepository, ILogger<PlanService> logger)
    {
        _planRepository = planRepository;
        _logger = logger;
    }

    public async Task<PagedResultDto<PlanResponseDto>> GetAllAsync(PlanFilterDto filter)
    {
        var (plans, totalCount) = await _planRepository.GetAllAsync(
            filter.PageNumber,
            filter.PageSize,
            filter.IsActive,
            filter.SearchTerm,
            filter.MinPrice,
            filter.MaxPrice);

        var planDtos = plans.Select(MapToResponseDto);

        return new PagedResultDto<PlanResponseDto>(planDtos, totalCount, filter.PageNumber, filter.PageSize);
    }

    public async Task<PlanResponseDto?> GetByIdAsync(Guid id)
    {
        var plan = await _planRepository.GetByIdAsync(id);
        return plan != null ? MapToResponseDto(plan) : null;
    }

    public async Task<IEnumerable<PlanResponseDto>> GetActiveAsync()
    {
        var plans = await _planRepository.GetActiveAsync();
        return plans.Select(MapToResponseDto);
    }

    public async Task<PlanResponseDto> CreateAsync(PlanRequestDto planRequest)
    {
        // Validate plan data
        var validationErrors = await ValidateAsync(planRequest);
        if (validationErrors.Any())
        {
            throw new PlanValidationException(validationErrors);
        }

        var plan = new Plan
        {
            Name = planRequest.Name,
            Description = planRequest.Description,
            Credits = planRequest.Credits,
            Price = planRequest.Price,
            OriginalPrice = planRequest.OriginalPrice,
            ValidityDays = planRequest.ValidityDays,
            IsActive = planRequest.IsActive,
            DisplayOrder = planRequest.DisplayOrder,
            IsFeatured = planRequest.IsFeatured
        };

        var createdPlan = await _planRepository.CreateAsync(plan);
        
        _logger.LogInformation("Plan created successfully: {PlanName} (ID: {PlanId})", createdPlan.Name, createdPlan.Id);
        
        return MapToResponseDto(createdPlan);
    }

    public async Task<PlanResponseDto> UpdateAsync(Guid id, PlanRequestDto planRequest)
    {
        // Check if plan exists
        var existingPlan = await _planRepository.GetByIdAsync(id);
        if (existingPlan == null)
        {
            throw new PlanNotFoundException(id);
        }

        // Validate plan data
        var validationErrors = await ValidateAsync(planRequest, id);
        if (validationErrors.Any())
        {
            throw new PlanValidationException(validationErrors);
        }

        var plan = new Plan
        {
            Id = id,
            Name = planRequest.Name,
            Description = planRequest.Description,
            Credits = planRequest.Credits,
            Price = planRequest.Price,
            OriginalPrice = planRequest.OriginalPrice,
            ValidityDays = planRequest.ValidityDays,
            IsActive = planRequest.IsActive,
            DisplayOrder = planRequest.DisplayOrder,
            IsFeatured = planRequest.IsFeatured
        };

        var updatedPlan = await _planRepository.UpdateAsync(plan);
        
        _logger.LogInformation("Plan updated successfully: {PlanName} (ID: {PlanId})", updatedPlan.Name, updatedPlan.Id);
        
        return MapToResponseDto(updatedPlan);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var deleted = await _planRepository.DeleteAsync(id);
        
        if (deleted)
        {
            _logger.LogInformation("Plan deleted successfully: ID {PlanId}", id);
        }
        else
        {
            _logger.LogWarning("Attempted to delete non-existent plan: ID {PlanId}", id);
        }
        
        return deleted;
    }

    public async Task<Dictionary<string, int>> GetStatisticsAsync()
    {
        return await _planRepository.GetCountsByStatusAsync();
    }

    public async Task<List<string>> ValidateAsync(PlanRequestDto planRequest, Guid? excludeId = null)
    {
        var errors = new List<string>();

        // Validate required fields
        if (string.IsNullOrWhiteSpace(planRequest.Name))
        {
            errors.Add("Plan name is required");
        }

        if (planRequest.Credits <= 0)
        {
            errors.Add("Credits must be greater than 0");
        }

        if (planRequest.Price < 0)
        {
            errors.Add("Price must be greater than or equal to 0");
        }

        if (planRequest.OriginalPrice.HasValue && planRequest.OriginalPrice < 0)
        {
            errors.Add("Original price must be greater than or equal to 0");
        }

        if (planRequest.ValidityDays <= 0)
        {
            errors.Add("Validity days must be greater than 0");
        }

        if (planRequest.DisplayOrder < 0)
        {
            errors.Add("Display order must be greater than or equal to 0");
        }

        // Validate business rules
        if (planRequest.OriginalPrice.HasValue && planRequest.OriginalPrice <= planRequest.Price)
        {
            errors.Add("Original price must be greater than current price");
        }

        // Check if name already exists
        if (!string.IsNullOrWhiteSpace(planRequest.Name))
        {
            var nameExists = await _planRepository.NameExistsAsync(planRequest.Name, excludeId);
            if (nameExists)
            {
                errors.Add($"A plan with the name '{planRequest.Name}' already exists");
            }
        }

        return errors;
    }

    private static PlanResponseDto MapToResponseDto(Plan plan)
    {
        return new PlanResponseDto
        {
            Id = plan.Id,
            Name = plan.Name,
            Description = plan.Description,
            Credits = plan.Credits,
            Price = plan.Price,
            OriginalPrice = plan.OriginalPrice,
            ValidityDays = plan.ValidityDays,
            IsActive = plan.IsActive,
            DisplayOrder = plan.DisplayOrder,
            IsFeatured = plan.IsFeatured,
            CreatedAt = plan.CreatedAt,
            UpdatedAt = plan.UpdatedAt
        };
    }
}