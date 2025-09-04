using SingleClin.API.DTOs.Clinic;
using SingleClin.API.DTOs.Common;
using SingleClin.API.Repositories;
using SingleClin.API.Data.Models;
using SingleClin.API.Exceptions;
using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using Microsoft.AspNetCore.Http;

namespace SingleClin.API.Services;

/// <summary>
/// Service implementation for Clinic business logic
/// </summary>
public class ClinicService : IClinicService
{
    private readonly IClinicRepository _clinicRepository;
    private readonly IImageUploadService _imageUploadService;
    private readonly ILogger<ClinicService> _logger;

    public ClinicService(
        IClinicRepository clinicRepository, 
        IImageUploadService imageUploadService,
        ILogger<ClinicService> logger)
    {
        _clinicRepository = clinicRepository;
        _imageUploadService = imageUploadService;
        _logger = logger;
    }

    public async Task<PagedResultDto<ClinicResponseDto>> GetAllAsync(ClinicFilterDto filter)
    {
        var (clinics, totalCount) = await _clinicRepository.GetAllAsync(
            filter.PageNumber,
            filter.PageSize,
            filter.IsActive,
            filter.Type,
            filter.SearchTerm,
            filter.City,
            filter.State,
            filter.SortBy,
            filter.SortDirection);

        var clinicDtos = clinics.Select(MapToResponseDto);

        return new PagedResultDto<ClinicResponseDto>(clinicDtos, totalCount, filter.PageNumber, filter.PageSize);
    }

    public async Task<ClinicResponseDto?> GetByIdAsync(Guid id)
    {
        var clinic = await _clinicRepository.GetByIdAsync(id);
        return clinic != null ? MapToResponseDto(clinic) : null;
    }

    public async Task<IEnumerable<ClinicResponseDto>> GetActiveAsync()
    {
        var clinics = await _clinicRepository.GetActiveAsync();
        return clinics.Select(MapToResponseDto);
    }

    public async Task<ClinicResponseDto> CreateAsync(ClinicRequestDto clinicRequest)
    {
        // Validate clinic data
        var validationErrors = await ValidateAsync(clinicRequest);
        if (validationErrors.Any())
        {
            var errorMessage = string.Join("; ", validationErrors);
            throw new InvalidOperationException($"Validation failed: {errorMessage}");
        }

        var clinic = MapToEntity(clinicRequest);

        var createdClinic = await _clinicRepository.CreateAsync(clinic);

        _logger.LogInformation("Clinic created successfully: {ClinicName} (ID: {ClinicId})",
            createdClinic.Name, createdClinic.Id);

        return MapToResponseDto(createdClinic);
    }

    public async Task<ClinicResponseDto> UpdateAsync(Guid id, ClinicRequestDto clinicRequest)
    {
        // Check if clinic exists
        var existingClinic = await _clinicRepository.GetByIdAsync(id);
        if (existingClinic == null)
        {
            throw new InvalidOperationException($"Clinic with ID {id} not found");
        }

        // Validate clinic data
        var validationErrors = await ValidateAsync(clinicRequest, id);
        if (validationErrors.Any())
        {
            var errorMessage = string.Join("; ", validationErrors);
            throw new InvalidOperationException($"Validation failed: {errorMessage}");
        }

        var clinic = MapToEntity(clinicRequest);
        clinic.Id = id;

        var updatedClinic = await _clinicRepository.UpdateAsync(clinic);

        _logger.LogInformation("Clinic updated successfully: {ClinicName} (ID: {ClinicId})", updatedClinic.Name, updatedClinic.Id);

        return MapToResponseDto(updatedClinic);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var deleted = await _clinicRepository.DeleteAsync(id);

        if (deleted)
        {
            _logger.LogInformation("Clinic deleted successfully: ID {ClinicId}", id);
        }
        else
        {
            _logger.LogWarning("Clinic not found for deletion: ID {ClinicId}", id);
        }

        return deleted;
    }

    public async Task<ClinicResponseDto> ToggleStatusAsync(Guid id)
    {
        var clinic = await _clinicRepository.GetByIdAsync(id);
        if (clinic == null)
        {
            throw new InvalidOperationException($"Clinic with ID {id} not found");
        }

        clinic.IsActive = !clinic.IsActive;
        var updatedClinic = await _clinicRepository.UpdateAsync(clinic);

        _logger.LogInformation("Clinic status toggled: {ClinicName} (ID: {ClinicId}) - Active: {IsActive}",
            updatedClinic.Name, updatedClinic.Id, updatedClinic.IsActive);

        return MapToResponseDto(updatedClinic);
    }

    public async Task<Dictionary<string, int>> GetStatisticsAsync()
    {
        return await _clinicRepository.GetCountsByStatusAndTypeAsync();
    }

    public async Task<List<string>> ValidateAsync(ClinicRequestDto clinicRequest, Guid? excludeId = null)
    {
        var errors = new List<string>();

        // Validate required fields
        if (string.IsNullOrWhiteSpace(clinicRequest.Name))
        {
            errors.Add("Clinic name is required");
        }

        if (string.IsNullOrWhiteSpace(clinicRequest.Address))
        {
            errors.Add("Address is required");
        }

        // Validate coordinates if provided
        if (clinicRequest.Latitude.HasValue && (clinicRequest.Latitude < -90 || clinicRequest.Latitude > 90))
        {
            errors.Add("Latitude must be between -90 and 90");
        }

        if (clinicRequest.Longitude.HasValue && (clinicRequest.Longitude < -180 || clinicRequest.Longitude > 180))
        {
            errors.Add("Longitude must be between -180 and 180");
        }

        // Validate CNPJ format if provided
        if (!string.IsNullOrWhiteSpace(clinicRequest.Cnpj) && !IsValidCnpjFormat(clinicRequest.Cnpj))
        {
            errors.Add("CNPJ must be in format XX.XXX.XXX/XXXX-XX or 14 digits");
        }

        // Validate email format if provided
        if (!string.IsNullOrWhiteSpace(clinicRequest.Email) && !IsValidEmail(clinicRequest.Email))
        {
            errors.Add("Invalid email format");
        }

        // Validate phone format if provided
        if (!string.IsNullOrWhiteSpace(clinicRequest.PhoneNumber) && !IsValidPhoneNumber(clinicRequest.PhoneNumber))
        {
            errors.Add("Invalid phone number format");
        }

        // Check if name already exists
        if (!string.IsNullOrWhiteSpace(clinicRequest.Name))
        {
            var nameExists = await _clinicRepository.NameExistsAsync(clinicRequest.Name, excludeId);
            if (nameExists)
            {
                errors.Add($"Clinic name '{clinicRequest.Name}' already exists");
            }
        }

        // Check if CNPJ already exists (if provided)
        if (!string.IsNullOrWhiteSpace(clinicRequest.Cnpj))
        {
            var cnpjExists = await _clinicRepository.CnpjExistsAsync(clinicRequest.Cnpj, excludeId);
            if (cnpjExists)
            {
                errors.Add($"CNPJ '{clinicRequest.Cnpj}' already exists");
            }
        }

        return errors;
    }

    /// <summary>
    /// Update clinic image
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <param name="imageFile">Image file to upload</param>
    /// <returns>Updated clinic with new image</returns>
    public async Task<ClinicResponseDto> UpdateImageAsync(Guid id, IFormFile imageFile)
    {
        var clinic = await _clinicRepository.GetByIdAsync(id);
        if (clinic == null)
        {
            throw new InvalidOperationException($"Clinic with ID {id} not found");
        }

        try
        {
            // Remove existing image if present
            if (!string.IsNullOrEmpty(clinic.ImageFileName))
            {
                await _imageUploadService.DeleteImageAsync(clinic.ImageFileName, "clinics");
            }

            // Upload new image
            var uploadResult = await _imageUploadService.UploadImageAsync(imageFile, "clinics");

            if (uploadResult.Success)
            {
                // Update clinic with new image information
                clinic.ImageUrl = uploadResult.Url;
                clinic.ImageFileName = uploadResult.FileName;
                clinic.ImageSize = uploadResult.Size;
                clinic.ImageContentType = uploadResult.ContentType;
                clinic.UpdatedAt = DateTime.UtcNow;

                await _clinicRepository.UpdateAsync(clinic);

                _logger.LogInformation("Successfully updated image for clinic {ClinicId}: {ImageUrl}", 
                    id, uploadResult.Url);
            }
            else
            {
                throw new InvalidOperationException($"Image upload failed: {uploadResult.ErrorMessage}");
            }

            return MapToResponseDto(clinic);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating image for clinic {ClinicId}", id);
            throw;
        }
    }

    /// <summary>
    /// Delete clinic image
    /// </summary>
    /// <param name="id">Clinic ID</param>
    /// <returns>Updated clinic without image</returns>
    public async Task<ClinicResponseDto> DeleteImageAsync(Guid id)
    {
        var clinic = await _clinicRepository.GetByIdAsync(id);
        if (clinic == null)
        {
            throw new InvalidOperationException($"Clinic with ID {id} not found");
        }

        try
        {
            // Delete image from storage if exists
            if (!string.IsNullOrEmpty(clinic.ImageFileName))
            {
                await _imageUploadService.DeleteImageAsync(clinic.ImageFileName, "clinics");
            }

            // Clear image fields
            clinic.ImageUrl = null;
            clinic.ImageFileName = null;
            clinic.ImageSize = null;
            clinic.ImageContentType = null;
            clinic.UpdatedAt = DateTime.UtcNow;

            await _clinicRepository.UpdateAsync(clinic);

            _logger.LogInformation("Successfully deleted image for clinic {ClinicId}", id);

            return MapToResponseDto(clinic);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting image for clinic {ClinicId}", id);
            throw;
        }
    }

    private static ClinicResponseDto MapToResponseDto(Clinic clinic)
    {
        return new ClinicResponseDto
        {
            Id = clinic.Id,
            Name = clinic.Name,
            Type = clinic.Type,
            Address = clinic.Address,
            PhoneNumber = clinic.PhoneNumber,
            Email = clinic.Email,
            Cnpj = clinic.Cnpj,
            IsActive = clinic.IsActive,
            Latitude = clinic.Latitude,
            Longitude = clinic.Longitude,
            ImageUrl = clinic.ImageUrl,
            CreatedAt = clinic.CreatedAt,
            UpdatedAt = clinic.UpdatedAt,
            TransactionCount = clinic.Transactions?.Count ?? 0
        };
    }

    private static Clinic MapToEntity(ClinicRequestDto clinicRequest)
    {
        return new Clinic
        {
            Name = clinicRequest.Name,
            Type = clinicRequest.Type,
            Address = clinicRequest.Address,
            PhoneNumber = clinicRequest.PhoneNumber,
            Email = clinicRequest.Email,
            Cnpj = clinicRequest.Cnpj,
            IsActive = clinicRequest.IsActive,
            Latitude = clinicRequest.Latitude,
            Longitude = clinicRequest.Longitude
        };
    }

    private static bool IsValidCnpjFormat(string cnpj)
    {
        if (string.IsNullOrWhiteSpace(cnpj))
            return false;

        // Check if it matches XX.XXX.XXX/XXXX-XX format
        if (System.Text.RegularExpressions.Regex.IsMatch(cnpj, @"^\d{2}\.\d{3}\.\d{3}\/\d{4}\-\d{2}$"))
            return true;

        // Check if it matches 14 digits format
        if (System.Text.RegularExpressions.Regex.IsMatch(cnpj, @"^\d{14}$"))
            return true;

        return false;
    }

    private static bool IsValidEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return false;

        try
        {
            var addr = new System.Net.Mail.MailAddress(email);
            return addr.Address == email;
        }
        catch
        {
            return false;
        }
    }

    private static bool IsValidPhoneNumber(string phoneNumber)
    {
        if (string.IsNullOrWhiteSpace(phoneNumber))
            return false;

        return System.Text.RegularExpressions.Regex.IsMatch(phoneNumber, @"^\+?[\d\s\-\(\)]+$");
    }
}