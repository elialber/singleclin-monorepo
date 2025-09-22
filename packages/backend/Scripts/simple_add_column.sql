-- Add is_active column to ClinicServices table
ALTER TABLE "ClinicServices" ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

-- Create index
CREATE INDEX IF NOT EXISTS "IX_ClinicServices_IsActive" ON "ClinicServices" (is_active);

-- Update existing records
UPDATE "ClinicServices" SET is_active = true WHERE is_active IS NULL;