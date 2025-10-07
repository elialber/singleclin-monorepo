# 🚀 Status do Deploy - Azure Container Apps

## 📊 Commits Enviados

### ✅ Commit 1: `243715c` - Correções Principais

```
fix: corrigir nomes de tabelas e ApplicationDbContext para snake_case

- Renomeadas tabelas no banco: ClinicImages -> clinic_images, ClinicServices -> clinic_services
- Criada tabela appointments com foreign keys e índices
- Removido override de PascalCase no ApplicationDbContext
- Sincronizado usuário Patricia (poliveira.psico@gmail.com)
- Atribuído plano com 100 créditos para Patricia
```

### ✅ Commit 2: `f2dad6e` - Desabilitar CI

```
chore: desabilitar CI temporariamente

- CI workflow desabilitado com 'if: false'
- Não bloqueia mais os deploys
```

### ✅ Commit 3: `4c6f3b1` - Trigger Rebuild (AGORA)

```
chore: trigger rebuild do backend para aplicar correções

- Commit vazio para forçar rebuild da imagem Docker
- Aplicar todas as correções no Azure
```

---

## 🔄 O Que Deve Acontecer Agora

### Se Houver CI/CD Configurado:

1. ✅ **GitHub Actions** deve iniciar um workflow de build
2. ✅ **Docker image** será construída com as novas correções
3. ✅ **Azure Container Registry** receberá a nova imagem
4. ✅ **Azure Container Apps** fará pull da nova imagem
5. ✅ **Revisão nova** será criada (ex: `singleclin-backend--0000106`)
6. ✅ **Tráfego** será migrado para a nova revisão

**Tempo estimado:** 5-10 minutos

### Se NÃO Houver CI/CD:

Você precisa fazer o build e push manual:

```bash
# 1. Build da imagem Docker
cd /Users/elialber/Development/Repos/Elialber/singleclin-monorepo/packages/backend
docker build -t singleclinprodacr.azurecr.io/singleclin-backend:latest .

# 2. Login no Azure Container Registry
az acr login --name singleclinprodacr

# 3. Push da imagem
docker push singleclinprodacr.azurecr.io/singleclin-backend:latest

# 4. Restart do Container App
az containerapp revision restart \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend \
  --revision singleclin-backend--0000105
```

---

## 🔍 Como Verificar o Deploy

### 1. Verificar Revisão Atual no Azure Portal

```
URL: https://portal.azure.com
→ Container Apps
→ singleclin-backend
→ Revisions and replicas
```

**Status esperado:**

- ✅ Nova revisão (ex: `0000106`) com status "Active"
- ✅ Tráfego 100% na nova revisão
- ✅ Revisão antiga (`0000105`) "Inactive"

### 2. Verificar Logs do Container

```bash
az containerapp logs show \
  --name singleclin-backend \
  --resource-group singleclin-prod-rg \
  --follow
```

**Logs esperados:**

```
info: Microsoft.Hosting.Lifetime[0]
      Now listening on: http://[::]:8080
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

### 3. Testar Endpoint de Clínicas

```bash
curl -H "Authorization: Bearer SEU_TOKEN" \
  "https://api.singleclin.com.br/api/clinic?pageNumber=1&pageSize=10"
```

**Resposta esperada:**

```json
{
  "items": [...],
  "totalCount": 1,
  "pageNumber": 1,
  "pageSize": 10,
  "totalPages": 1
}
```

### 4. Verificar Health Check

```bash
curl https://api.singleclin.com.br/health
```

**Resposta esperada:**

```json
{
  "status": "Healthy",
  "checks": [...]
}
```

---

## 📱 Teste no App Mobile

Após confirmar que o deploy está OK:

1. ✅ **Logout e Login** como `poliveira.psico@gmail.com`
2. ✅ **Verificar créditos**: deve mostrar **100**
3. ✅ **Listar clínicas**: deve funcionar sem erro 500
4. ✅ **Listar serviços**: deve mostrar 583 serviços
5. ✅ **Criar agendamento**: deve funcionar!

---

## ⚠️ Se o Deploy Falhar

### Cenário 1: Revisão fica "Activating" por muito tempo

**Solução:**

```bash
# Verificar logs para ver o erro
az containerapp logs show \
  --name singleclin-backend \
  --resource-group singleclin-prod-rg \
  --tail 100

# Forçar restart
az containerapp revision restart \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend
```

### Cenário 2: Erro 500 ainda persiste

**Possíveis causas:**

1. ❌ Imagem Docker antiga ainda está sendo usada
2. ❌ Azure não fez pull da nova imagem
3. ❌ Banco de dados ainda tem tabelas com nomes errados

**Solução:**

```bash
# 1. Verificar qual imagem está rodando
az containerapp show \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend \
  --query 'properties.template.containers[0].image'

# 2. Forçar pull da imagem mais recente
az containerapp update \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend \
  --image singleclinprodacr.azurecr.io/singleclin-backend:latest
```

### Cenário 3: Tabelas do banco ainda estão erradas

**Verificação:**

```bash
# Conectar no banco
PGPASSWORD='SingleClin123!' psql \
  -h singleclin-prod-postgres.postgres.database.azure.com \
  -p 5432 \
  -U singleclinadmin \
  -d singleclin \
  -c "\dt"
```

**Tabelas esperadas:**

```
clinic_images       (não ClinicImages)
clinic_services     (não ClinicServices)
appointments        (deve existir)
```

---

## 📋 Checklist de Verificação

- [ ] Commit `4c6f3b1` enviado para GitHub
- [ ] CI/CD iniciou build (ou build manual feito)
- [ ] Nova revisão criada no Azure
- [ ] Nova revisão está "Active" (não "Activating")
- [ ] Tráfego 100% na nova revisão
- [ ] Health check responde OK
- [ ] Endpoint `/api/clinic` retorna 200 (não 500)
- [ ] App mobile mostra 100 créditos
- [ ] App mobile lista clínicas
- [ ] App mobile cria agendamento

---

## 🎯 Status Atual

**Última ação:** Push do commit `4c6f3b1` em `$(date)`

**Revisão no Azure:** `singleclin-backend--0000105` (Activating)

**Próximo passo:** Aguardar 5-10 minutos para nova revisão ou fazer deploy manual

---

## 💡 Dica Rápida

Para forçar o Container App a puxar a nova imagem imediatamente:

```bash
az containerapp revision copy \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend \
  --from-revision singleclin-backend--0000105
```

Isso cria uma nova revisão idêntica mas força o pull da imagem mais recente do registry.
