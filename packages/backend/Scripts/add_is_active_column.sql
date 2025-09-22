-- Add is_active column to ClinicServices table if it doesn't exist
-- This script is safe to run multiple times

DO $$
BEGIN
    -- Check if the column exists before adding it
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'ClinicServices'
        AND column_name = 'is_active'
    ) THEN
        -- Add the column with default value
        ALTER TABLE "ClinicServices"
        ADD COLUMN is_active boolean NOT NULL DEFAULT true;

        RAISE NOTICE 'Added is_active column to ClinicServices table';
    ELSE
        RAISE NOTICE 'is_active column already exists in ClinicServices table';
    END IF;
END $$;

-- Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS "IX_ClinicServices_IsActive" ON "ClinicServices" (is_active);

-- Update all existing records to have is_active = true (if they don't already)
UPDATE "ClinicServices"
SET is_active = true
WHERE is_active IS NULL;

RAISE NOTICE 'Successfully ensured is_active column exists on ClinicServices table';