using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;
using SingleClin.API.Data.Seeders;

namespace SingleClin.API.Extensions;

/// <summary>
/// Extension methods for database configuration
/// </summary>
public static class DatabaseExtensions
{
    /// <summary>
    /// Configure database migrations and seeding
    /// </summary>
    public static async Task ConfigureDatabaseAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

        try
        {
            logger.LogInformation("Checking database migrations...");

            // Apply pending migrations in development
            if (app.Environment.IsDevelopment())
            {
                var pendingMigrations = await context.Database.GetPendingMigrationsAsync();
                if (pendingMigrations.Any())
                {
                    logger.LogInformation("Applying {Count} pending migrations...", pendingMigrations.Count());
                    await context.Database.MigrateAsync();
                    logger.LogInformation("Migrations applied successfully");
                }
            }
            else
            {
                // In production, just ensure database exists but don't auto-migrate
                await context.Database.EnsureCreatedAsync();
            }

            // Seed roles and default admin user
            logger.LogInformation("Seeding roles and default admin...");
            await RoleSeeder.SeedRolesAsync(scope.ServiceProvider);
            await RoleSeeder.SeedDefaultAdminAsync(scope.ServiceProvider);
            logger.LogInformation("Roles and admin seeding completed");

            // Create missing AppDbContext tables to resolve schema conflicts
            logger.LogInformation("Creating missing AppDbContext tables...");
            try
            {
                var appContext = scope.ServiceProvider.GetService<AppDbContext>();
                if (appContext != null)
                {
                    await EnsureTablesExist.CreateMissingTablesAsync(appContext);
                    logger.LogInformation("AppDbContext tables created successfully");
                }
            }
            catch (Exception tableEx)
            {
                logger.LogWarning(tableEx, "Could not create AppDbContext tables - will use mock data");
            }

            // Manually create ClinicServices table due to migration issues
            logger.LogInformation("Creating ClinicServices table if it doesn't exist...");
            try
            {
                await CreateClinicServicesTableAsync(context);
                logger.LogInformation("ClinicServices table creation completed");
            }
            catch (Exception tableEx)
            {
                logger.LogWarning(tableEx, "Could not create ClinicServices table");
            }

            // Seed sample clinics if none exist
            logger.LogInformation("Seeding sample clinics...");
            try
            {
                await SeedSampleClinicsAsync(context);
                logger.LogInformation("Sample clinics seeding completed");
            }
            catch (Exception clinicEx)
            {
                logger.LogWarning(clinicEx, "Could not seed sample clinics");
            }

            logger.LogInformation("Database seeding completed");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred while configuring the database");
            throw;
        }
    }

    /// <summary>
    /// Manually create ClinicServices table to resolve migration issues
    /// </summary>
    private static async Task CreateClinicServicesTableAsync(ApplicationDbContext context)
    {
        var sql = @"
            -- Check if table exists first
            DO $$ 
            BEGIN
                IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ClinicServices') THEN
                    -- Create the table fresh
                    CREATE TABLE ""ClinicServices"" (
                        id uuid NOT NULL DEFAULT gen_random_uuid(),
                        clinic_id uuid NOT NULL,
                        name character varying(100) NOT NULL,
                        description character varying(500),
                        price numeric(18,2) NOT NULL,
                        duration integer NOT NULL,
                        category character varying(50) NOT NULL,
                        is_available boolean NOT NULL DEFAULT true,
                        image_url character varying(500),
                        credit_cost integer NOT NULL DEFAULT 1,
                        created_at timestamp with time zone NOT NULL DEFAULT NOW(),
                        updated_at timestamp with time zone NOT NULL DEFAULT NOW(),
                        CONSTRAINT pk_clinic_services PRIMARY KEY (id),
                        CONSTRAINT fk_clinic_services_clinics_clinic_id 
                            FOREIGN KEY (clinic_id) REFERENCES clinics (id) ON DELETE CASCADE
                    );
                    
                    -- Create indexes
                    CREATE INDEX ""IX_ClinicServices_ClinicId"" ON ""ClinicServices"" (clinic_id);
                    CREATE INDEX ""IX_ClinicServices_Category"" ON ""ClinicServices"" (category);
                    CREATE INDEX ""IX_ClinicServices_IsAvailable"" ON ""ClinicServices"" (is_available);
                ELSE
                    -- Table exists, check if credit_cost column exists and add it if missing
                    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'ClinicServices' AND column_name = 'credit_cost') THEN
                        ALTER TABLE ""ClinicServices"" ADD COLUMN credit_cost integer NOT NULL DEFAULT 1;
                    END IF;
                END IF;
            END $$;
        ";

        await context.Database.ExecuteSqlRawAsync(sql);
    }

    /// <summary>
    /// Seed sample clinic data if none exists
    /// </summary>
    private static async Task SeedSampleClinicsAsync(ApplicationDbContext context)
    {
        // Check if clinics already exist - use a different approach
        var checkSql = @"
            DO $$ 
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM clinics LIMIT 1) THEN
                    -- Insert clinics data here
                    INSERT INTO clinics (id, name, type, address, phone_number, email, cnpj, is_active, latitude, longitude, created_at, updated_at) VALUES
                    (gen_random_uuid(), 'Clínica São Paulo Centro', 1, 'Rua das Flores, 123, Centro, São Paulo, SP', '(11) 3123-4567', 'contato@clinicasp.com.br', '12.345.678/0001-90', true, -23.5505, -46.6333, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Rio de Janeiro Copacabana', 2, 'Avenida Atlântica, 456, Copacabana, Rio de Janeiro, RJ', '(21) 2987-6543', 'atendimento@clinicario.com.br', '98.765.432/0001-10', true, -22.9068, -43.1729, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Belo Horizonte Savassi', 1, 'Rua Pernambuco, 789, Savassi, Belo Horizonte, MG', '(31) 3456-7890', 'recepcao@clinicabh.com.br', '31.222.333/0001-44', true, -19.9167, -43.9345, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Porto Alegre Moinhos', 2, 'Rua Padre Chagas, 321, Moinhos de Vento, Porto Alegre, RS', '(51) 3210-9876', 'agendamento@clinicapoa.com.br', '55.666.777/0001-88', true, -30.0346, -51.2177, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Salvador Barra', 1, 'Avenida Centenário, 654, Barra, Salvador, BA', '(71) 3789-0123', 'contato@clinicassa.com.br', '22.333.444/0001-55', true, -13.0167, -38.5108, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Recife Boa Viagem', 2, 'Rua dos Navegantes, 987, Boa Viagem, Recife, PE', '(81) 3654-3210', 'atendimento@clinicarecife.com.br', '33.444.555/0001-66', true, -8.1137, -34.9039, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Fortaleza Aldeota', 1, 'Avenida Dom Luís, 147, Aldeota, Fortaleza, CE', '(85) 3147-2583', 'recepcao@clinicafortaleza.com.br', '44.555.666/0001-77', true, -3.7327, -38.5267, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Brasília Asa Sul', 2, 'SQS 308, Bloco A, Loja 15, Asa Sul, Brasília, DF', '(61) 3258-1470', 'agendamento@clinicabsb.com.br', '66.777.888/0001-99', true, -15.7942, -47.8822, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Curitiba Centro', 1, 'Rua XV de Novembro, 258, Centro, Curitiba, PR', '(41) 3369-7410', 'contato@clinicacuritiba.com.br', '77.888.999/0001-00', true, -25.4372, -49.2697, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Goiânia Setor Oeste', 2, 'Avenida T-9, 753, Setor Oeste, Goiânia, GO', '(62) 3741-8520', 'atendimento@clinicagoiania.com.br', '88.999.000/0001-11', true, -16.6869, -49.2648, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Campinas Cambuí', 1, 'Rua Conceição, 159, Cambuí, Campinas, SP', '(19) 3852-9630', 'recepcao@clinicacampinas.com.br', '99.000.111/0001-22', true, -22.9099, -47.0626, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Santos Gonzaga', 2, 'Avenida Conselheiro Nébias, 357, Gonzaga, Santos, SP', '(13) 3963-7410', 'agendamento@clinicasantos.com.br', '00.111.222/0001-33', true, -23.9618, -46.3322, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Ribeirão Preto Centro', 1, 'Rua Álvares Cabral, 456, Centro, Ribeirão Preto, SP', '(16) 3074-1852', 'contato@clinicaribeiraopreto.com.br', '16.222.333/0001-44', true, -21.1767, -47.8108, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Sorocaba Vila Hortência', 2, 'Rua Aparecida, 789, Vila Hortência, Sorocaba, SP', '(15) 3185-2963', 'atendimento@clinicasorocaba.com.br', '15.333.444/0001-55', true, -23.5018, -47.4581, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica São José dos Campos Centro', 1, 'Avenida São José, 951, Centro, São José dos Campos, SP', '(12) 3296-7410', 'recepcao@clinicasjc.com.br', '12.444.555/0001-66', true, -23.1794, -45.8869, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Osasco Centro', 2, 'Rua Antônio Agu, 753, Centro, Osasco, SP', '(11) 3707-4185', 'agendamento@clinicaosasco.com.br', '11.555.666/0001-77', true, -23.5329, -46.7918, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Joinville América', 1, 'Rua do Príncipe, 258, América, Joinville, SC', '(47) 3418-5296', 'contato@clinicajoinville.com.br', '47.666.777/0001-88', true, -26.3045, -48.8487, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Londrina Centro', 2, 'Avenida Higienópolis, 654, Centro, Londrina, PR', '(43) 3529-6307', 'atendimento@clinicalondrina.com.br', '43.777.888/0001-99', true, -23.3045, -51.1696, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Maringá Zona 01', 1, 'Avenida Brasil, 147, Zona 01, Maringá, PR', '(44) 3630-7418', 'recepcao@clinicamaringa.com.br', '44.888.999/0001-00', true, -23.4205, -51.9331, NOW(), NOW()),
                    (gen_random_uuid(), 'Clínica Caxias do Sul Centro', 2, 'Rua Sinimbu, 852, Centro, Caxias do Sul, RS', '(54) 3741-8529', 'agendamento@clinicacaxias.com.br', '54.999.000/0001-11', true, -29.1678, -51.1794, NOW(), NOW());
                END IF;
            END $$;
        ";

        await context.Database.ExecuteSqlRawAsync(checkSql);
    }
}