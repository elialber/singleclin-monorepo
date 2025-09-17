# SingleClin - Scripts de Infraestrutura Azure

Este diretório contém scripts para gerenciar a infraestrutura Azure da aplicação SingleClin.

## 📋 Scripts Disponíveis

### `create-infrastructure.sh`
Cria toda a infraestrutura Azure necessária para o SingleClin.

**Recursos criados:**
- Resource Group
- Container Registry
- Key Vault com secrets básicos
- PostgreSQL Flexible Server
- Redis Cache
- Storage Account
- Container Apps Environment
- Managed Identity

**Uso:**
```bash
# Edite o script para configurar SUBSCRIPTION_ID
nano create-infrastructure.sh

# Execute
./create-infrastructure.sh
```

### `setup-keyvault.sh`
Gerencia secrets no Azure Key Vault.

**Comandos:**
```bash
# Configurar Firebase
./setup-keyvault.sh firebase ./firebase-service-account.json

# SendGrid not used - skip this step

# Configurar acesso para GitHub Actions
./setup-keyvault.sh github-access "service-principal-object-id"

# Configurar acesso para Container Apps
./setup-keyvault.sh container-apps-access

# Validar todas as secrets
./setup-keyvault.sh validate

# Fazer backup das secrets
./setup-keyvault.sh backup
```

### `get-production-credentials.sh`
Obtém credenciais de produção do Key Vault para desenvolvimento local.

**Comandos:**
```bash
# Listar todas as secrets
./get-production-credentials.sh list

# Obter variáveis para desenvolvimento local
./get-production-credentials.sh local

# Criar arquivo .env
./get-production-credentials.sh create-env .env.production

# Obter secret específica
./get-production-credentials.sh get database-connection-string

# Atualizar secret
./get-production-credentials.sh update sendgrid-api-key "new-value"
```

### `deploy-container-apps.sh`
Faz deploy das aplicações nos Container Apps.

**Uso:**
```bash
# Deploy com imagens latest
./deploy-container-apps.sh

# Deploy com tags específicas
BACKEND_IMAGE_TAG=v1.2.3 ./deploy-container-apps.sh
FRONTEND_IMAGE_TAG=v1.0.1 BACKEND_IMAGE_TAG=v1.2.3 ./deploy-container-apps.sh
```

### `cleanup-resources.sh`
Remove todos os recursos Azure (CUIDADO - IRREVERSÍVEL).

**Comandos:**
```bash
# Listar recursos sem deletar
./cleanup-resources.sh list

# Deletar todos os recursos
./cleanup-resources.sh cleanup

# Deletar e aguardar conclusão
./cleanup-resources.sh cleanup-wait
```

## 🔧 Configuração Inicial

### 1. Configurar Subscription ID

Edite cada script e configure o `SUBSCRIPTION_ID`:

```bash
# Em todos os scripts, altere:
SUBSCRIPTION_ID=""  # Para: SUBSCRIPTION_ID="your-subscription-id"
```

### 2. Fazer Login no Azure

```bash
az login
az account set --subscription "your-subscription-id"
```

### 3. Executar Scripts em Ordem

```bash
# 1. Criar infraestrutura
./create-infrastructure.sh

# 2. Configurar secrets específicas
./setup-keyvault.sh firebase ./firebase-service-account.json

# 3. Validar configuração
./setup-keyvault.sh validate

# 4. (Opcional) Deploy manual das aplicações
./deploy-container-apps.sh
```

## 🔒 Segurança

### Secrets no Key Vault

Todas as secrets são armazenadas exclusivamente no Azure Key Vault:

- `database-connection-string`: String de conexão PostgreSQL
- `redis-connection-string`: String de conexão Redis
- `azure-storage-connection-string`: String de conexão Storage Account
- `jwt-secret-key`: Chave secreta JWT (gerada automaticamente)
- `firebase-service-account`: JSON do Firebase Service Account

### Managed Identity

As aplicações usam Managed Identity para acessar o Key Vault, eliminando a necessidade de secrets hardcoded.

### GitHub Actions

O GitHub Actions usa apenas um Service Principal com acesso limitado ao Resource Group. Não há secrets da aplicação armazenadas no GitHub.

## 💡 Dicas de Uso

### Desenvolvimento Local

Use `get-production-credentials.sh` para obter credenciais de produção para desenvolvimento:

```bash
# Criar arquivo .env local
./get-production-credentials.sh create-env .env.local

# Usar no desenvolvimento
cd packages/backend
dotnet run
```

### Monitoramento

```bash
# Status geral
az resource list --resource-group singleclin-prod-rg --output table

# Logs das aplicações
az containerapp logs show --resource-group singleclin-prod-rg --name singleclin-backend --follow
az containerapp logs show --resource-group singleclin-prod-rg --name singleclin-frontend --follow
```

### Backup e Restore

```bash
# Backup das secrets
./setup-keyvault.sh backup secrets-backup-$(date +%Y%m%d).json

# Backup do banco (automático pelo Azure)
az postgres flexible-server backup list \
  --resource-group singleclin-prod-rg \
  --server-name singleclin-prod-postgres
```

## ⚠️ Avisos Importantes

1. **Scripts destrutivos**: `cleanup-resources.sh` remove TODOS os recursos permanentemente
2. **Secrets sensíveis**: Nunca commite arquivos com secrets no Git
3. **Subscription ID**: Configure sempre o ID correto antes de executar
4. **Permissions**: Certifique-se de ter permissões adequadas na subscription Azure
5. **Custos**: Monitore os custos Azure regularmente

## 🆘 Troubleshooting

### Erro: "Subscription not found"
```bash
az account list --output table
az account set --subscription "correct-subscription-id"
```

### Erro: "Access denied to Key Vault"
```bash
# Verificar acesso
az keyvault show --name singleclin-kv-prod

# Reconfigurar acesso
./setup-keyvault.sh container-apps-access
```

### Erro: "Container app not responding"
```bash
# Verificar logs
az containerapp logs show --resource-group singleclin-prod-rg --name singleclin-backend --tail 100

# Verificar health
curl -f https://your-app.azurecontainerapps.io/health
```

---

Para mais informações detalhadas, consulte o [AZURE_DEPLOYMENT_GUIDE.md](../AZURE_DEPLOYMENT_GUIDE.md).