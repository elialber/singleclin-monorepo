# SingleClin - Guia de Deploy Azure

Este guia detalha como fazer o deploy da aplicação SingleClin no Azure usando Container Apps de
forma econômica e segura.

## 📋 Pré-requisitos

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) instalado
- Conta Azure com permissões para criar recursos
- [Docker](https://docs.docker.com/get-docker/) instalado (para desenvolvimento local)
- [Git](https://git-scm.com/) configurado
- Node.js 18+ e .NET 10 (para desenvolvimento local)

## 🏗️ Arquitetura da Solução

### Componentes Azure

- **Resource Group**: `singleclin-prod-rg`
- **Container Registry**: `singleclinprodacr.azurecr.io`
- **Container Apps Environment**: `singleclin-prod-env`
- **Key Vault**: `singleclin-kv-prod.vault.azure.net`
- **PostgreSQL**: `singleclin-prod-postgres.postgres.database.azure.com`
- **Redis Cache**: `singleclin-prod-redis.redis.cache.windows.net`
- **Storage Account**: `singleclinprodstorage`
- **Managed Identity**: `singleclin-prod-identity`

### Aplicações

- **Backend**: .NET 10 Web API
- **Frontend**: React + Nginx
- **Database**: PostgreSQL 15 Flexible Server
- **Cache**: Redis 7
- **Storage**: Azure Blob Storage

## 🚀 Deploy Inicial

### 1. Configuração Inicial

```bash
# Clone o repositório
git clone <repository-url>
cd singleclin-monorepo

# Login no Azure
az login

# Definir subscription (substitua pelo seu ID)
az account set --subscription "your-subscription-id"
```

### 2. Configurar Scripts

Edite os scripts para configurar seu Subscription ID:

```bash
# Editar scripts/create-infrastructure.sh
nano scripts/create-infrastructure.sh
# Altere a linha: SUBSCRIPTION_ID="your-subscription-id"

# Editar scripts/deploy-container-apps.sh
nano scripts/deploy-container-apps.sh
# Altere a linha: SUBSCRIPTION_ID="your-subscription-id"
```

### 3. Criar Infraestrutura

```bash
# Criar todos os recursos Azure
./scripts/create-infrastructure.sh
```

Este script irá criar:

- Resource Group
- Container Registry
- Key Vault com secrets básicos
- PostgreSQL Flexible Server
- Redis Cache
- Storage Account
- Container Apps Environment
- Managed Identity com permissões

### 4. Configurar Secrets

```bash
# Configurar Firebase service account
./scripts/setup-keyvault.sh firebase ./firebase-service-account.json

# SendGrid not used - skip this step

# Validar todas as secrets
./scripts/setup-keyvault.sh validate
```

### 5. Configurar GitHub Actions

Adicione os seguintes secrets no GitHub:

```bash
# Criar Service Principal para GitHub Actions
az ad sp create-for-rbac \
  --name "singleclin-github-actions" \
  --role "Contributor" \
  --scopes "/subscriptions/your-subscription-id/resourceGroups/singleclin-prod-rg" \
  --sdk-auth
```

No GitHub Repository > Settings > Secrets and variables > Actions, adicione:

- `AZURE_CREDENTIALS`: Output completo do comando acima
- `AZURE_SUBSCRIPTION_ID`: Seu subscription ID
- `AZURE_ACR_PASSWORD`: Password do Container Registry (obtido via Portal Azure)

### 6. Deploy Automático

O deploy automático ocorre via GitHub Actions quando você faz push na branch `main`:

```bash
git add .
git commit -m "feat: setup Azure CI/CD infrastructure"
git push origin main
```

## 🔧 Deploy Manual (Opcional)

Se preferir fazer deploy manual:

```bash
# Build e push das imagens
docker build -t singleclinprodacr.azurecr.io/singleclin-backend:latest -f packages/backend/Dockerfile packages/backend
docker build -t singleclinprodacr.azurecr.io/singleclin-frontend:latest -f packages/web-admin/Dockerfile packages/web-admin

# Login no registry
az acr login --name singleclinprodacr

# Push das imagens
docker push singleclinprodacr.azurecr.io/singleclin-backend:latest
docker push singleclinprodacr.azurecr.io/singleclin-frontend:latest

# Deploy das aplicações
./scripts/deploy-container-apps.sh
```

## 🛠️ Desenvolvimento Local

### Com Docker Compose

```bash
# Desenvolvimento completo com dependências
docker-compose up -d

# Apenas dependências (Postgres + Redis)
docker-compose up -d postgres redis

# Desenvolvimento com ferramentas de debug
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### URLs de Desenvolvimento

- **Backend**: http://localhost:5010
- **Frontend**: http://localhost:3000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **Swagger**: http://localhost:5010/swagger

### Variáveis de Ambiente Locais

Crie um arquivo `.env` na raiz do projeto:

```env
# Database
DATABASE_CONNECTION_STRING="Host=localhost;Database=singleclin_dev;Username=postgres;Password=postgres123"

# Redis
REDIS_CONNECTION_STRING="localhost:6379,password=redis123"

# JWT
JWT_SECRET_KEY="your-super-secret-key-for-development-only-min-32-characters"

# Firebase
FIREBASE_PROJECT_ID="your-firebase-project-id"
FIREBASE_SERVICE_ACCOUNT_PATH="./packages/backend/firebase-service-account.json"

# SendGrid disabled - not used in this project
# SENDGRID_API_KEY="not-configured"
```

## 🔍 Monitoramento e Troubleshooting

### Health Checks

- **Backend Health**: `https://your-backend.azurecontainerapps.io/health`
- **Backend Detailed**: `https://your-backend.azurecontainerapps.io/health/detailed`
- **Frontend Health**: `https://your-frontend.azurecontainerapps.io/health`

### Logs

```bash
# Ver logs do backend
az containerapp logs show \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend \
  --follow

# Ver logs do frontend
az containerapp logs show \
  --resource-group singleclin-prod-rg \
  --name singleclin-frontend \
  --follow
```

### Obter Credenciais de Produção

```bash
# Listar todas as secrets
./scripts/get-production-credentials.sh list

# Obter strings de conexão para debug
./scripts/get-production-credentials.sh local

# Criar arquivo .env para desenvolvimento
./scripts/get-production-credentials.sh create-env .env.production
```

## 💰 Gerenciamento de Custos

### Scaling Automático

- **Backend**: 0-3 réplicas baseado em CPU/memória/requests
- **Frontend**: 0-2 réplicas baseado em requests
- **Scale to zero**: Aplicações escalam para 0 quando não há tráfego

### Recursos Econômicos

- **PostgreSQL**: Burstable B1ms (1 vCore, 2GB)
- **Redis**: Basic C0 (250MB)
- **Container Apps**: Pay-per-use com auto-scaling
- **Storage**: Standard LRS

### Estimativa de Custos (Mensal)

- Container Apps: $30-50
- PostgreSQL: $25-35
- Redis: $15-20
- Key Vault: $5-10
- Storage: $5-10
- **Total**: ~$80-125

## 🔄 Atualizações e Manutenção

### Atualizações Automáticas

Commits na branch `main` acionam automaticamente:

1. Build das imagens
2. Testes automatizados
3. Deploy para produção
4. Limpeza de imagens antigas

### Rollback

```bash
# Ver revisões disponíveis
az containerapp revision list \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend \
  --output table

# Fazer rollback para revisão anterior
az containerapp revision set-mode \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend \
  --mode Single \
  --revision-name <revision-name>
```

### Backup

```bash
# Backup das secrets do Key Vault
./scripts/setup-keyvault.sh backup

# Backup do banco de dados (executado automaticamente pelo Azure)
az postgres flexible-server backup list \
  --resource-group singleclin-prod-rg \
  --server-name singleclin-prod-postgres
```

## 🗑️ Limpeza de Recursos

Para remover todos os recursos (CUIDADO - IRREVERSÍVEL):

```bash
# Via script
./scripts/cleanup-resources.sh cleanup

# Via GitHub Actions
# Use o workflow "Deploy Infrastructure" com a opção "destroy" = true
```

## 📞 Suporte

### Troubleshooting Comum

1. **Erro de autenticação Key Vault**:
   - Verificar se Managed Identity está configurada
   - Verificar permissions no Key Vault

2. **Container não inicia**:
   - Verificar logs: `az containerapp logs show`
   - Verificar health checks
   - Verificar variáveis de ambiente

3. **Database connection failed**:
   - Verificar se PostgreSQL está acessível
   - Verificar string de conexão no Key Vault
   - Verificar firewall do PostgreSQL

### Scripts Úteis

```bash
# Status geral da infraestrutura
az resource list --resource-group singleclin-prod-rg --output table

# Status das aplicações
az containerapp list --resource-group singleclin-prod-rg --output table

# Reiniciar aplicação
az containerapp revision restart \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend
```

---

**⚠️ Importante**: Mantenha suas credenciais seguras e nunca commite secrets no código. Use sempre o
Key Vault para armazenar informações sensíveis.
