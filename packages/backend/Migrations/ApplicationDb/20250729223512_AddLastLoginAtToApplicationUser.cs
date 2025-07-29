using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SingleClin.API.Migrations.ApplicationDb
{
    /// <inheritdoc />
    public partial class AddLastLoginAtToApplicationUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "last_login_at",
                table: "asp_net_users",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "last_login_at",
                table: "asp_net_users");
        }
    }
}
