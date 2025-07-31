using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SingleClin.API.Migrations.ApplicationDb
{
    /// <inheritdoc />
    public partial class FixPendingChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "first_name",
                table: "user",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "last_name",
                table: "user",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "amount",
                table: "transactions",
                type: "numeric",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "qrnonce",
                table: "transactions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "qrtoken",
                table: "transactions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "service_type",
                table: "transactions",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "notification_logs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    channel = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    subject = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    message = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    recipient = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    is_success = table.Column<bool>(type: "boolean", nullable: false),
                    error_message = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    external_message_id = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Metadata = table.Column<string>(type: "jsonb", nullable: true),
                    sent_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    retry_count = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_notification_logs", x => x.id);
                    table.ForeignKey(
                        name: "fk_notification_logs_asp_net_users_user_id",
                        column: x => x.user_id,
                        principalTable: "asp_net_users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "user_notification_preferences",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    enable_push = table.Column<bool>(type: "boolean", nullable: false),
                    enable_email = table.Column<bool>(type: "boolean", nullable: false),
                    low_balance_threshold = table.Column<int>(type: "integer", nullable: false),
                    preferred_language = table.Column<string>(type: "character varying(5)", maxLength: 5, nullable: false),
                    enable_promotional = table.Column<bool>(type: "boolean", nullable: false),
                    enable_payment = table.Column<bool>(type: "boolean", nullable: false),
                    quiet_hours_start = table.Column<string>(type: "character varying(5)", maxLength: 5, nullable: true),
                    quiet_hours_end = table.Column<string>(type: "character varying(5)", maxLength: 5, nullable: true),
                    device_token = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    device_platform = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_user_notification_preferences", x => x.id);
                    table.ForeignKey(
                        name: "fk_user_notification_preferences_asp_net_users_user_id",
                        column: x => x.user_id,
                        principalTable: "asp_net_users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_notification_logs_sent_at",
                table: "notification_logs",
                column: "sent_at");

            migrationBuilder.CreateIndex(
                name: "IX_notification_logs_user_type",
                table: "notification_logs",
                columns: new[] { "user_id", "type" });

            migrationBuilder.CreateIndex(
                name: "ix_user_notification_preferences_user_id",
                table: "user_notification_preferences",
                column: "user_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "notification_logs");

            migrationBuilder.DropTable(
                name: "user_notification_preferences");

            migrationBuilder.DropColumn(
                name: "first_name",
                table: "user");

            migrationBuilder.DropColumn(
                name: "last_name",
                table: "user");

            migrationBuilder.DropColumn(
                name: "amount",
                table: "transactions");

            migrationBuilder.DropColumn(
                name: "qrnonce",
                table: "transactions");

            migrationBuilder.DropColumn(
                name: "qrtoken",
                table: "transactions");

            migrationBuilder.DropColumn(
                name: "service_type",
                table: "transactions");
        }
    }
}
