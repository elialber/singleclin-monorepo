using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SingleClin.API.Migrations.ApplicationDb
{
    /// <inheritdoc />
    public partial class SyncModels : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "application_user_id",
                table: "user",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<string>(
                name: "full_name",
                table: "user",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "image_content_type",
                table: "clinics",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "image_file_name",
                table: "clinics",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "image_size",
                table: "clinics",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "image_url",
                table: "clinics",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "application_user_id",
                table: "user");

            migrationBuilder.DropColumn(
                name: "full_name",
                table: "user");

            migrationBuilder.DropColumn(
                name: "image_content_type",
                table: "clinics");

            migrationBuilder.DropColumn(
                name: "image_file_name",
                table: "clinics");

            migrationBuilder.DropColumn(
                name: "image_size",
                table: "clinics");

            migrationBuilder.DropColumn(
                name: "image_url",
                table: "clinics");
        }
    }
}
