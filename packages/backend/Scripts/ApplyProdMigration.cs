using Microsoft.EntityFrameworkCore;
using Npgsql;
using System;
using System.Threading.Tasks;

namespace SingleClin.API.Scripts
{
    /// <summary>
    /// Script para aplicar a migration credit_cost em produção
    /// </summary>
    public class ApplyProdMigration
    {
        private const string ProductionConnectionString =
            "Host=singleclin-prod-postgres.postgres.database.azure.com;Database=singleclin;Username=singleclinadmin;Password=SingleClin123!;Port=5432;SSL Mode=Require;";

        public static async Task Main(string[] args)
        {
            Console.WriteLine("🚀 Aplicando migration credit_cost no banco de produção...");

            try
            {
                await ApplyCreditCostMigration();
                Console.WriteLine("✅ Migration aplicada com sucesso!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Erro ao aplicar migration: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                Environment.Exit(1);
            }
        }

        private static async Task ApplyCreditCostMigration()
        {
            using var connection = new NpgsqlConnection(ProductionConnectionString);
            await connection.OpenAsync();

            Console.WriteLine("🔗 Conectado ao banco de produção");

            // Verificar se a tabela ClinicServices existe
            var tableExistsQuery = @"
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_name = 'ClinicServices'
                );";

            using var tableExistsCmd = new NpgsqlCommand(tableExistsQuery, connection);
            var tableExists = (bool)await tableExistsCmd.ExecuteScalarAsync();

            if (!tableExists)
            {
                Console.WriteLine("⚠️  Tabela ClinicServices não encontrada!");
                return;
            }

            Console.WriteLine("✅ Tabela ClinicServices encontrada");

            // Verificar se a coluna credit_cost já existe
            var columnExistsQuery = @"
                SELECT EXISTS (
                    SELECT FROM information_schema.columns
                    WHERE table_name = 'ClinicServices' AND column_name = 'credit_cost'
                );";

            using var columnExistsCmd = new NpgsqlCommand(columnExistsQuery, connection);
            var columnExists = (bool)await columnExistsCmd.ExecuteScalarAsync();

            if (columnExists)
            {
                Console.WriteLine("✅ Coluna credit_cost já existe na tabela ClinicServices");
                return;
            }

            Console.WriteLine("🔧 Adicionando coluna credit_cost...");

            // Adicionar a coluna credit_cost
            var addColumnQuery = @"
                ALTER TABLE ""ClinicServices""
                ADD COLUMN credit_cost integer NOT NULL DEFAULT 1;";

            using var addColumnCmd = new NpgsqlCommand(addColumnQuery, connection);
            await addColumnCmd.ExecuteNonQueryAsync();

            Console.WriteLine("✅ Coluna credit_cost adicionada com sucesso!");

            // Verificar se foi adicionada corretamente
            using var verifyCmd = new NpgsqlCommand(columnExistsQuery, connection);
            var verifyResult = (bool)await verifyCmd.ExecuteScalarAsync();

            if (verifyResult)
            {
                Console.WriteLine("✅ Verificação: Coluna credit_cost confirmada no banco");

                // Contar registros na tabela
                var countQuery = "SELECT COUNT(*) FROM \"ClinicServices\"";
                using var countCmd = new NpgsqlCommand(countQuery, connection);
                var recordCount = (long)await countCmd.ExecuteScalarAsync();

                Console.WriteLine($"📊 Total de registros na tabela ClinicServices: {recordCount}");
            }
            else
            {
                Console.WriteLine("❌ Erro: Coluna não foi adicionada corretamente");
            }
        }
    }
}