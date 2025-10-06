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

        public static async Task RunMigration(string[] args)
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
            var tableExistsResult = await tableExistsCmd.ExecuteScalarAsync();
            var tableExists = tableExistsResult as bool? ?? false;

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
            var columnExistsResult = await columnExistsCmd.ExecuteScalarAsync();
            var columnExists = columnExistsResult as bool? ?? false;

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
            var verifyScalar = await verifyCmd.ExecuteScalarAsync();
            var verifyResult = verifyScalar as bool? ?? false;

            if (verifyResult)
            {
                Console.WriteLine("✅ Verificação: Coluna credit_cost confirmada no banco");

                // Contar registros na tabela
                var countQuery = "SELECT COUNT(*) FROM \"ClinicServices\"";
                using var countCmd = new NpgsqlCommand(countQuery, connection);
                var countScalar = await countCmd.ExecuteScalarAsync();
                var recordCount = countScalar switch
                {
                    long longValue => longValue,
                    int intValue => intValue,
                    _ => Convert.ToInt64(countScalar ?? 0)
                };

                Console.WriteLine($"📊 Total de registros na tabela ClinicServices: {recordCount}");
            }
            else
            {
                Console.WriteLine("❌ Erro: Coluna não foi adicionada corretamente");
            }
        }
    }
}
