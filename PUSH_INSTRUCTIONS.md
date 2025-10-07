# 🚨 Instruções para Fazer Push

## Problema Detectado

O GitHub está bloqueando o push porque detectou uma **Azure Communication Services Key** em um
commit anterior (`4c1801d`).

---

## ✅ Opção 1: Permitir o Push no GitHub (MAIS RÁPIDO)

1. Acesse este link no navegador:

   ```
   https://github.com/elialber/singleclin-monorepo/security/secret-scanning/unblock-secret/33l3AfbMBTDPHvsO9nqMDszj10Z
   ```

2. Clique em **"Allow secret"** ou **"I'll fix it later"**

3. Volte ao terminal e execute:
   ```bash
   git push origin main
   ```

**⚠️ IMPORTANTE:** Depois do push, você DEVE:

- Rotacionar a chave do Azure Communication Services
- Remover a chave do arquivo ou usar variáveis de ambiente
- Adicionar `appsettings.json` ao `.gitignore`

---

## 🔧 Opção 2: Remover a Chave do Commit Anterior

Se você quiser remover a chave do histórico (mais seguro):

```bash
# 1. Fazer backup do branch atual
git branch backup-main

# 2. Fazer rebase interativo para editar o commit
git rebase -i 4c1801d^

# 3. Marcar o commit 4c1801d como "edit"
# 4. Remover a chave do appsettings.json
# 5. Continuar o rebase
git add packages/backend/appsettings.json
git commit --amend --no-edit
git rebase --continue

# 6. Fazer push forçado (CUIDADO!)
git push origin main --force-with-lease
```

⚠️ **ATENÇÃO:** A Opção 2 reescreve o histórico do Git e pode causar problemas se outras pessoas
estiverem trabalhando no repositório!

---

## 📋 Commit Atual Pronto para Deploy

Seu commit mais recente (`243715c`) está correto e **NÃO** contém a chave problemática:

```
fix: corrigir nomes de tabelas e ApplicationDbContext para snake_case

- Renomeadas tabelas no banco
- Criada tabela appointments
- Corrigido ApplicationDbContext
- Sincronizado usuário Patricia
- 100 créditos atribuídos
```

---

## 🚀 Depois do Push

Após conseguir fazer o push, o deploy automático deve iniciar (se você tem CI/CD configurado).

Se não houver deploy automático, execute:

```bash
./scripts/deploy-container-apps.sh
```

---

## 🔒 Segurança - Próximos Passos

1. **Rotacionar chave do Azure:**
   - Acesse Azure Portal
   - Vá em Communication Services
   - Regenere a Access Key
   - Atualize as variáveis de ambiente do Container App

2. **Usar variáveis de ambiente:**

   ```csharp
   // appsettings.json - NUNCA commitar chaves reais
   "AzureCommunication": "{{AZURE_COMMUNICATION_CONNECTION_STRING}}"
   ```

3. **Atualizar .gitignore:**
   ```
   appsettings.json
   appsettings.*.json
   !appsettings.example.json
   ```

---

**Escolha a Opção 1 para agilizar o deploy!** ✅
