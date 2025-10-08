using Microsoft.EntityFrameworkCore;
using SingleClin.API.Data;

namespace SingleClin.API;

/// <summary>
/// Helper class to ensure required tables exist in the database
/// This is a temporary solution to resolve schema conflicts between DbContexts
/// </summary>
public static class EnsureTablesExist
{
    public static async Task CreateMissingTablesAsync(AppDbContext context)
    {
        try
        {
            // Create plans table if it doesn't exist (may already exist from ApplicationDbContext)
            await context.Database.ExecuteSqlRawAsync(@"
                CREATE TABLE IF NOT EXISTS plans (
                    id uuid NOT NULL DEFAULT gen_random_uuid(),
                    name character varying(255) NOT NULL,
                    description character varying(1000),
                    credits integer NOT NULL DEFAULT 0,
                    price numeric(10,2) NOT NULL DEFAULT 0,
                    original_price numeric(10,2),
                    validity_days integer NOT NULL DEFAULT 365,
                    is_active boolean NOT NULL DEFAULT true,
                    display_order integer NOT NULL DEFAULT 0,
                    is_featured boolean NOT NULL DEFAULT false,
                    created_at timestamp with time zone NOT NULL DEFAULT NOW(),
                    updated_at timestamp with time zone NOT NULL DEFAULT NOW(),
                    CONSTRAINT pk_plans PRIMARY KEY (id)
                );
            ");

            // CRITICAL FIX: DO NOT drop tables - this deletes all user data!
            // These tables should be created by migrations, not dropped on every startup
            
            // Create users table only if it doesn't exist
            await context.Database.ExecuteSqlRawAsync(@"
                CREATE TABLE IF NOT EXISTS users (
                    id uuid NOT NULL DEFAULT gen_random_uuid(),
                    application_user_id uuid NOT NULL,
                    email character varying(255) NOT NULL,
                    full_name character varying(255) NOT NULL,
                    role integer NOT NULL DEFAULT 0,
                    first_name character varying(255),
                    last_name character varying(255),
                    display_name character varying(255),
                    phone_number character varying(20),
                    firebase_uid character varying(128),
                    is_active boolean NOT NULL DEFAULT true,
                    created_at timestamp with time zone NOT NULL DEFAULT NOW(),
                    updated_at timestamp with time zone NOT NULL DEFAULT NOW(),
                    CONSTRAINT pk_users PRIMARY KEY (id),
                    CONSTRAINT uq_users_email UNIQUE (email),
                    CONSTRAINT uq_users_application_user_id UNIQUE (application_user_id)
                );
            ");

            // Create user_plans table only if it doesn't exist
            await context.Database.ExecuteSqlRawAsync(@"
                CREATE TABLE IF NOT EXISTS user_plans (
                    id uuid NOT NULL DEFAULT gen_random_uuid(),
                    user_id uuid NOT NULL,
                    plan_id uuid NOT NULL,
                    credits integer NOT NULL DEFAULT 0,
                    credits_remaining integer NOT NULL DEFAULT 0,
                    amount_paid numeric(10,2) NOT NULL DEFAULT 0,
                    expiration_date timestamp with time zone NOT NULL,
                    is_active boolean NOT NULL DEFAULT true,
                    payment_method character varying(50),
                    payment_transaction_id character varying(255),
                    notes character varying(1000),
                    created_at timestamp with time zone NOT NULL DEFAULT NOW(),
                    updated_at timestamp with time zone NOT NULL DEFAULT NOW(),
                    CONSTRAINT pk_user_plans PRIMARY KEY (id),
                    CONSTRAINT fk_user_plans_user_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
                    CONSTRAINT fk_user_plans_plan_plan_id FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE RESTRICT
                );
            ");

            // Create basic indices for better performance
            await context.Database.ExecuteSqlRawAsync(@"
                CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
                CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
                CREATE INDEX IF NOT EXISTS idx_plans_is_active ON plans(is_active);
                CREATE INDEX IF NOT EXISTS idx_plans_display_order ON plans(display_order);
                CREATE INDEX IF NOT EXISTS idx_user_plans_user_id ON user_plans(user_id);
                CREATE INDEX IF NOT EXISTS idx_user_plans_plan_id ON user_plans(plan_id);
                CREATE INDEX IF NOT EXISTS idx_user_plans_expiration_date ON user_plans(expiration_date);
            ");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Warning: Could not create missing tables: {ex.Message}");
            // Don't throw - let the application continue with mock data
        }
    }
}