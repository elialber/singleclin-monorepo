using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data.Models;
using SingleClin.API.Data.Models.Enums;

namespace SingleClin.API.Data;

/// <summary>
/// Seed initial data for the database
/// </summary>
public class DatabaseSeeder
{
    private readonly AppDbContext _context;
    
    public DatabaseSeeder(AppDbContext context)
    {
        _context = context;
    }
    
    /// <summary>
    /// Seed all initial data
    /// </summary>
    public async Task SeedAsync()
    {
        // Seed in the correct order to respect dependencies
        await SeedPlansAsync();
        await SeedClinicsAsync();
        await SeedUsersAsync();
        
        await _context.SaveChangesAsync();
    }
    
    private async Task SeedPlansAsync()
    {
        if (await _context.Plans.AnyAsync())
            return;
            
        var plans = new List<Plan>
        {
            new Plan
            {
                Id = Guid.NewGuid(),
                Name = "Plano Básico",
                Description = "Ideal para usuários ocasionais",
                Credits = 10,
                Price = 49.90m,
                ValidityDays = 365,
                IsActive = true,
                DisplayOrder = 1,
                IsFeatured = false
            },
            new Plan
            {
                Id = Guid.NewGuid(),
                Name = "Plano Premium",
                Description = "Para usuários frequentes com necessidades regulares",
                Credits = 30,
                Price = 129.90m,
                OriginalPrice = 149.90m,
                ValidityDays = 365,
                IsActive = true,
                DisplayOrder = 2,
                IsFeatured = true
            },
            new Plan
            {
                Id = Guid.NewGuid(),
                Name = "Plano Enterprise",
                Description = "Solução completa para empresas e equipes",
                Credits = 100,
                Price = 399.90m,
                ValidityDays = 365,
                IsActive = true,
                DisplayOrder = 3,
                IsFeatured = false
            }
        };
        
        await _context.Plans.AddRangeAsync(plans);
    }
    
    private async Task SeedClinicsAsync()
    {
        if (await _context.Clinics.AnyAsync())
            return;
            
        var adminClinic = new Clinic
        {
            Id = Guid.NewGuid(),
            Name = "SingleClin Administrativo",
            Type = ClinicType.Administrative,
            Address = "Rua Virtual, 123 - Centro, São Paulo - SP",
            PhoneNumber = "(11) 9999-9999",
            Email = "admin@singleclin.com.br",
            Cnpj = "00.000.000/0001-00",
            IsActive = true,
            Latitude = -23.550520,
            Longitude = -46.633308
        };
        
        await _context.Clinics.AddAsync(adminClinic);
    }
    
    private async Task SeedUsersAsync()
    {
        if (await _context.Users.AnyAsync())
            return;
            
        var adminUser = new User
        {
            Id = Guid.NewGuid(),
            Email = "admin@singleclin.com.br",
            Role = UserRole.Admin,
            DisplayName = "Administrador",
            PhoneNumber = "(11) 9999-9999",
            IsActive = true
        };
        
        await _context.Users.AddAsync(adminUser);
    }
}