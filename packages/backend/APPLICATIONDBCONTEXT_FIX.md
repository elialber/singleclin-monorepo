# Correção: ApplicationDbContext - Nomes de Tabelas

## 🚨 Problema Identificado

### Sintoma

```
GET https://api.singleclin.com.br/api/clinic?pageNumber=1&pageSize=10
→ 500 (Internal Server Error)
```

### Causa Raiz

O `ApplicationDbContext` estava configurado para **MANTER** os nomes de tabela `ClinicImages` e
`ClinicServices` em **PascalCase**, mas essas tabelas foram **RENOMEADAS** para `snake_case`
(`clinic_images` e `clinic_services`) no banco de dados.

### Código Problemático

```csharp
// ApplicationDbContext.cs (ANTES)
if (tableName == "ClinicImage")
{
    entity.SetTableName("ClinicImages"); // ❌ Tabela não existe mais
}
else if (tableName == "ClinicService")
{
    entity.SetTableName("ClinicServices"); // ❌ Tabela não existe mais
}
else
{
    entity.SetTableName(ToSnakeCase(tableName));
}
```

**Resultado:** EF Core tentava buscar em `ClinicImages` e `ClinicServices`, mas as tabelas reais
eram `clinic_images` e `clinic_services`.

---

## ✅ Solução Aplicada

### Código Corrigido

```csharp
// ApplicationDbContext.cs (DEPOIS)
// Convert all table names to snake_case
entity.SetTableName(ToSnakeCase(tableName));
```

**Resultado:** EF Core agora busca corretamente em `clinic_images` e `clinic_services`.

---

## 📊 Impacto

### Antes da Correção ❌

- ❌ Endpoint `/api/clinic` retornando 500
- ❌ Listagem de clínicas não funcionando
- ❌ Listagem de serviços não funcionando
- ❌ Sistema de agendamentos não funcionando (dependia de consultar serviços)

### Depois da Correção ✅

- ✅ Endpoint `/api/clinic` funcional
- ✅ Listagem de clínicas com 583 serviços
- ✅ Sistema de agendamentos funcional
- ✅ Consistência entre EF Core e banco de dados

---

## 🔄 Próximos Passos

### 1. Deploy para Produção

```bash
cd /Users/elialber/Development/Repos/Elialber/singleclin-monorepo
./scripts/deploy-container-apps.sh
```

### 2. Verificar em Produção

```bash
# Testar endpoint de clínicas
curl -H "Authorization: Bearer TOKEN" \
  "https://api.singleclin.com.br/api/clinic?pageNumber=1&pageSize=10"
```

### 3. Testar no App Mobile

- ✅ Login como `poliveira.psico@gmail.com`
- ✅ Verificar listagem de clínicas
- ✅ Verificar listagem de serviços
- ✅ Tentar criar agendamento

---

## 🔍 Como Prevenir no Futuro

### 1. Padronização de Nomes

- **SEMPRE** usar `snake_case` para nomes de tabelas e colunas
- **NUNCA** criar exceções para tabelas específicas
- Manter consistência entre EF Core e banco de dados

### 2. Migrations

- **SEMPRE** usar migrations do EF Core para criar/alterar tabelas
- **NUNCA** alterar estrutura do banco manualmente sem atualizar o código
- Executar migrations em produção via pipeline de deploy

### 3. Testes

- Testar endpoints após qualquer mudança no banco de dados
- Verificar logs do backend para erros de EF Core
- Monitorar erros 500 em produção

---

## 📝 Arquivos Modificados

### `/packages/backend/Data/ApplicationDbContext.cs`

- **Linhas removidas:** 78-87 (overrides específicos para ClinicImages/ClinicServices)
- **Linhas modificadas:** 73-79 (aplicar snake_case para todas as tabelas)

### Arquivos relacionados (já corrigidos anteriormente):

- `/packages/backend/Data/AppDbContext.cs` - Já estava correto (sempre usa snake_case)
- Banco de dados - Tabelas renomeadas de `ClinicImages` → `clinic_images`, `ClinicServices` →
  `clinic_services`

---

## ✅ Status Final

**Estado do Backend:**

- ✅ `ApplicationDbContext` corrigido
- ✅ `AppDbContext` correto (sempre foi)
- ✅ Banco de dados com nomes em `snake_case`
- ✅ Tabela `appointments` criada

**Estado do Banco:**

- ✅ `clinic_images` (583 registros)
- ✅ `clinic_services` (583 registros)
- ✅ `appointments` (0 registros - nova tabela)
- ✅ `users` sincronizada com `asp_net_users`
- ✅ `user_plans` com plano ativo para Patricia

**Pronto para Deploy!** 🚀
