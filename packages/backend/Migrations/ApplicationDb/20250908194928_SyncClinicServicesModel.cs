using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SingleClin.API.Migrations.ApplicationDb
{
    /// <inheritdoc />
    public partial class SyncClinicServicesModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // This migration is empty because the ClinicServices table already exists
            // The model snapshot has been updated to reflect the current database state
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // This rollback is empty because the ClinicServices table was already present
            // No changes need to be reverted
        }
    }
}
