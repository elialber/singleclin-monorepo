# 🚀 Guia para Aplicar Migration em Produção

## Problema

A coluna `credit_cost` não existe na tabela `ClinicServices` em produção, causando erro 500 no
endpoint `/api/clinic/active`.

## Soluções Disponíveis

### 📝 **Opção 1: SQL Direto (Recomendado)**

Se você tiver acesso ao Azure Portal ou pgAdmin:

```sql
-- Verificar se a coluna já existe
SELECT EXISTS (
    SELECT FROM information_schema.columns
    WHERE table_name = 'ClinicServices' AND column_name = 'credit_cost'
);

-- Se retornar 'false', executar:
ALTER TABLE "ClinicServices" ADD COLUMN credit_cost integer NOT NULL DEFAULT 1;

-- Verificar se foi aplicado
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'ClinicServices' AND column_name = 'credit_cost';
```

### 🔧 **Opção 2: Script .NET (Se tiver acesso ao servidor)**

1. **No servidor de produção**, copie os arquivos:
   - `Scripts/ApplyProdMigration.cs`
   - `Scripts/MigrationScript.csproj`
   - `Scripts/Program.cs`

2. **Execute o script**:

```bash
cd Scripts
dotnet run
```

### 🌐 **Opção 3: Entity Framework Tools**

Se você tiver o .NET SDK no servidor/ambiente de produção:

```bash
# Na pasta do projeto backend
dotnet ef database update --connection "Host=singleclin-prod-postgres.postgres.database.azure.com;Database=singleclin;Username=singleclinadmin;Password=SingleClin123!;Port=5432;SSL Mode=Require;"
```

### ⚙️ **Opção 4: Reiniciar a Aplicação (Automático)**

Como implementamos a correção automática no `DatabaseExtensions.cs`, simplesmente **reiniciar a
aplicação** deve aplicar a migration automaticamente.

A aplicação vai executar este código na inicialização:

```csharp
// Verifica se a coluna existe e adiciona se necessário
IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'ClinicServices' AND column_name = 'credit_cost') THEN
    ALTER TABLE "ClinicServices" ADD COLUMN credit_cost integer NOT NULL DEFAULT 1;
END IF;
```

## ✅ **Verificação de Sucesso**

Após aplicar qualquer opção, teste:

1. **Endpoint da API**:

   ```bash
   curl https://singleclin-api.azurewebsites.net/api/clinic/active
   ```

2. **Verificação no banco**:
   ```sql
   SELECT COUNT(*) FROM "ClinicServices" WHERE credit_cost IS NOT NULL;
   ```

## 🔒 **Segurança**

- ✅ **Safe Operation**: `ADD COLUMN` com `DEFAULT` é seguro
- ✅ **Zero Downtime**: Não bloqueia tabelas existentes
- ✅ **Rollback**: Se necessário, pode ser removida com `DROP COLUMN`

## 📊 **Status Esperado**

Após a aplicação:

- ✅ Coluna `credit_cost` criada com valor padrão `1`
- ✅ Endpoint `/api/clinic/active` funcionando
- ✅ Todos os serviços existentes terão `credit_cost = 1`
- ✅ Novos serviços usarão o valor padrão correto

## 🎯 **Recomendação**

**Opção mais simples**: Reiniciar a aplicação em produção - a correção automática deve resolver o
problema.
