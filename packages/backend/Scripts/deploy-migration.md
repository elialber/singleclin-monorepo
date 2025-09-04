# Script de Deploy - Migration para Upload de Imagens

## Pré-requisitos

1. **Backup do banco de dados** antes da aplicação:
```bash
pg_dump -h [host] -U [username] -d [database] > backup_antes_upload_imagens.sql
```

2. **Verificar conexão com o banco de produção**:
```bash
dotnet ef database drop --dry-run
```

## Aplicação da Migration

### 1. Definir variáveis de ambiente
```bash
export ConnectionStrings__DefaultConnection="[connection_string_producao]"
export ASPNETCORE_ENVIRONMENT=Production
```

### 2. Aplicar migration
```bash
dotnet ef database update --context AppDbContext
```

### 3. Verificar aplicação
```bash
# Conectar ao banco e verificar se as colunas foram criadas
psql -h [host] -U [username] -d [database] -c "
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'clinics' 
AND column_name IN ('imageurl', 'imagefilename', 'imagesize', 'imagecontenttype');"
```

## Rollback (se necessário)

```bash
# Voltar para a migration anterior
dotnet ef database update [MigrationAnterior] --context AppDbContext

# Remover migration se necessário
dotnet ef migrations remove --context AppDbContext
```

## Validação Pós-Deploy

1. **Testar endpoint de upload**:
```bash
curl -X POST "https://api.singleclin.com/clinic/[clinic-id]/image" \
  -H "Authorization: Bearer [token]" \
  -F "image=@test-image.jpg"
```

2. **Verificar logs da aplicação** para errors relacionados ao upload

3. **Testar interface web** para upload de imagens

## Monitoramento

- Verificar uso do Azure Blob Storage
- Monitorar performance dos endpoints de upload
- Acompanhar logs de erro relacionados a upload de imagens