# 🚨 CORREÇÃO CRÍTICA - IMAGEM DOCKER ANTIGA EM PRODUÇÃO

## ❌ Problema Atual

O Azure Container Apps está rodando uma **imagem Docker antiga** que NÃO contém as correções do
`ApplicationDbContext`.

### Erro em Produção:

```
relation "ClinicImages" does not exist
```

**Causa:** A imagem Docker foi buildada ANTES do commit `243715c` que corrigiu o
`ApplicationDbContext`.

---

## 📊 Histórico de Commits

```
af5a79f - fix: corrigir query do FirebaseRefreshTokenCleanupJob (MAIS RECENTE)
a076cf8 - fix: Improve appointment management
4c6f3b1 - chore: trigger rebuild
f2dad6e - chore: desabilitar CI
243715c - fix: corrigir ApplicationDbContext (CORREÇÃO PRINCIPAL) ⭐
```

---

## 🔍 O Que Deve Acontecer

### GitHub Actions Workflow: `build-and-deploy.yml`

1. ✅ **Trigger:** Push para `main` (linha 4-5)
2. ✅ **Build Job:**
   - Checkout código
   - Build imagem Docker do backend (linha 54-57)
   - Push para Azure Container Registry
3. ✅ **Deploy Job:**
   - Update Container App com nova imagem (linha 228-231)

### Status Esperado:

- ✅ Workflow deve rodar automaticamente após push
- ✅ Build deve incluir o código do commit `af5a79f`
- ✅ Imagem deve conter `ApplicationDbContext` corrigido
- ✅ Container deve iniciar sem erro "ClinicImages does not exist"

---

## 🔧 SOLUÇÕES

### Opção 1: Verificar se Workflow Está Rodando (MAIS PROVÁVEL)

1. **Acesse GitHub Actions:**

   ```
   https://github.com/elialber/singleclin-monorepo/actions
   ```

2. **Procure pelo workflow "Build and Deploy to Azure Container Apps"**

3. **Verifique o status:**
   - 🟡 **Running:** Aguarde conclusão (5-10 minutos)
   - ✅ **Success:** Deploy concluído, aguarde Container App reiniciar
   - ❌ **Failed:** Veja logs do erro e corrija

### Opção 2: Workflow Não Triggerou (Improvável)

Se não houver workflow rodando:

```bash
# Trigger manual via GitHub CLI
gh workflow run build-and-deploy.yml

# OU via GitHub Web UI
# GitHub → Actions → Build and Deploy → Run workflow
```

### Opção 3: Forçar Novo Commit (Se Workflow Falhou)

```bash
cd /Users/elialber/Development/Repos/Elialber/singleclin-monorepo

git commit --allow-empty -m "chore: force rebuild com ApplicationDbContext corrigido

- Imagem Docker precisa incluir correção do commit 243715c
- ApplicationDbContext agora usa snake_case para TODAS as tabelas
- Fix para erro: relation ClinicImages does not exist"

git push origin main
```

---

## 🎯 Como Confirmar que Funcionou

### 1. Verificar Tag da Imagem no ACR

```bash
az acr repository show-tags \
  --name singleclinprodacr \
  --repository singleclin-backend \
  --orderby time_desc \
  --top 1
```

**Esperado:** Tag com hash do commit `af5a79f` (ex: `main-af5a79f`)

### 2. Verificar Imagem Usada pelo Container App

```bash
az containerapp show \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend \
  --query 'properties.template.containers[0].image' -o tsv
```

**Esperado:** `singleclinprodacr.azurecr.io/singleclin-backend:main-af5a79f`

### 3. Testar Endpoint

```bash
curl "https://api.singleclin.com.br/api/clinic?pageNumber=1&pageSize=1"
```

**Esperado:** Status `200` e JSON com clínicas (não erro 500)

### 4. Verificar Logs

```bash
az containerapp logs show \
  --name singleclin-backend \
  --resource-group singleclin-prod-rg \
  --tail 20
```

**Esperado:**

```
Now listening on: http://[::]:8080
Application started
```

**NÃO deve aparecer:**

```
relation "ClinicImages" does not exist
```

---

## 📱 Teste Final no App Mobile

Após confirmar que a imagem correta está rodando:

1. ✅ Logout e login como `poliveira.psico@gmail.com`
2. ✅ Verificar 100 créditos
3. ✅ Listar clínicas (não deve dar erro 500)
4. ✅ Criar agendamento

---

## ⚠️ Se Ainda Assim Não Funcionar

### Possível Causa: Cache do Container Registry

```bash
# Forçar pull da imagem mais recente
az containerapp revision copy \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend

# Ou restart forçado
az containerapp restart \
  --resource-group singleclin-prod-rg \
  --name singleclin-backend
```

---

## 📋 Checklist de Verificação

- [ ] Workflow "Build and Deploy" rodou com sucesso
- [ ] Nova imagem foi pushed para ACR com tag `main-af5a79f`
- [ ] Container App está usando a nova imagem
- [ ] Container está em status "Running" (não "Activating")
- [ ] Health check retorna 200
- [ ] Endpoint `/api/clinic` retorna 200 (não 500)
- [ ] Logs NÃO mostram erro "ClinicImages does not exist"
- [ ] App mobile lista clínicas sem erro

---

## 🎯 STATUS ATUAL

**Última ação:** Push do commit `af5a79f` em $(date)

**Imagem esperada:** `singleclinprodacr.azurecr.io/singleclin-backend:main-af5a79f`

**Problema:** Imagem antiga ainda em uso, causando erro "ClinicImages does not exist"

**Solução:** Aguardar workflow completar ou forçar novo build

---

## 💡 Para o Futuro

**Como evitar esse problema:**

1. ✅ Sempre verificar GitHub Actions após push
2. ✅ Confirmar que workflow completou com sucesso
3. ✅ Verificar que Container App está usando imagem correta
4. ✅ Testar endpoint antes de considerar deploy completo

**Tempo total esperado:**

- Build: 5-8 minutos
- Deploy: 2-3 minutos
- Container start: 1-2 minutos
- **Total:** ~10-15 minutos
