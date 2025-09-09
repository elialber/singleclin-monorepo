using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SingleClin.API.Migrations.ApplicationDb
{
    /// <inheritdoc />
    public partial class CreateClinicServicesTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Table and constraints already exist from previous attempts
            // This is a sync migration to match the current database state
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ClinicServices");
        }
    }
}
