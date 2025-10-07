# Correções do Banco de Dados - 07/10/2025

## ✅ Problemas Identificados e Resolvidos

### 1. **Inconsistência nos Nomes das Tabelas** ❌ → ✅

**Problema:** O `AppDbContext` está configurado para converter todos os nomes de tabelas e colunas
para `snake_case`, mas algumas tabelas no banco de produção estavam em `PascalCase`:

- ❌ `ClinicImages` (PascalCase) - Backend procurava por `clinic_images`
- ❌ `ClinicServices` (PascalCase) - Backend procurava por `clinic_services`

**Solução:** Renomeamos as tabelas para `snake_case`:

```sql
ALTER TABLE "ClinicImages" RENAME TO clinic_images;
ALTER TABLE "ClinicServices" RENAME TO clinic_services;
```

**Resultado:** ✅ 583 serviços agora acessíveis pelo backend ✅ Sistema de agendamento pode
consultar os serviços

---

### 2. **Tabela `appointments` Não Existia** ❌ → ✅

**Problema:** O backend tentava criar agendamentos, mas a tabela `appointments` não existia no banco
de produção.

**Solução:** Criamos a tabela `appointments` com a estrutura correta:

```sql
CREATE TABLE appointments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    service_id uuid NOT NULL,
    clinic_id uuid NOT NULL,
    scheduled_date timestamp with time zone NOT NULL,
    status integer NOT NULL DEFAULT 0,
    transaction_id uuid,
    total_credits integer NOT NULL CHECK (total_credits > 0),
    confirmation_token character varying(100),
    created_at timestamp with time zone NOT NULL DEFAULT NOW(),
    updated_at timestamp with time zone NOT NULL DEFAULT NOW(),

    -- Foreign keys
    CONSTRAINT fk_appointments_user_user_id
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_service_service_id
        FOREIGN KEY (service_id) REFERENCES clinic_services(id) ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_clinic_clinic_id
        FOREIGN KEY (clinic_id) REFERENCES clinics(id) ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_transaction_transaction_id
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
);

-- Índices para performance
CREATE INDEX ix_appointments_user_id ON appointments(user_id);
CREATE INDEX ix_appointments_service_id ON appointments(service_id);
CREATE INDEX ix_appointments_clinic_id ON appointments(clinic_id);
CREATE INDEX ix_appointments_status ON appointments(status);
CREATE INDEX ix_appointments_scheduled_date ON appointments(scheduled_date);
CREATE INDEX ix_appointments_confirmation_token ON appointments(confirmation_token);
```

**Resultado:** ✅ Backend pode criar agendamentos ✅ Sistema de confirmação de agendamentos
funcional

---

### 3. **Usuário Patricia - Sincronização `asp_net_users` ↔ `users`** ❌ → ✅

**Problema:** Patricia existia em `asp_net_users` (Identity) mas não em `users` (domínio), causando:

- ❌ Créditos não sendo exibidos
- ❌ Impossibilidade de criar agendamentos

**Solução:** Criamos um script que sincroniza automaticamente o usuário:

```sql
-- Buscar usuário em asp_net_users
-- Criar entrada correspondente em users
-- Criar UserPlan com 100 créditos
```

**Resultado:** ✅ Patricia: `application_user_id` = `0199624f-db9c-73c2-a1d4-e1ab20948e87` ✅
Patricia: `domain_user_id` = `ae0df5fa-2a3f-4ae4-9c1e-6f017fb73016` ✅ Patricia: `userplan_id` =
`68020593-0ba5-411f-9c76-27d55dc10571` ✅ 100 créditos disponíveis até 2026-10-07

---

## 📊 Estado Atual do Banco

### Tabelas Corrigidas

```
✅ clinic_images       (antes: ClinicImages)
✅ clinic_services     (antes: ClinicServices)
✅ appointments        (NOVA)
✅ users               (sincronizada com asp_net_users)
✅ user_plans          (plano ativo para Patricia)
```

### Dados de Produção

- **Serviços**: 583 serviços ativos
- **Clínicas**: Clínica A e outras
- **Usuários**: Patricia (poliveira.psico@gmail.com) com 100 créditos

---

## 🔧 Próximos Passos

### Para Evitar Futuros Problemas

1. **Migrações EF Core**: Sempre executar migrations em produção
2. **Naming Convention**: Manter `snake_case` para TODAS as tabelas
3. **Sincronização de Usuários**: O `DomainUserSyncService` deve ser chamado em TODA operação que
   envolva usuários
4. **Soft Delete**: Nunca deletar registros de `users` (manter `is_active = false`)

### Monitoramento

- Verificar logs do Azure para erros de sincronização
- Acompanhar criação de agendamentos
- Monitorar créditos dos usuários

---

## 📝 Comandos Úteis para Diagnóstico

### Verificar sincronização de usuário

```sql
SELECT
    au.id as application_user_id,
    au.email,
    u.id as domain_user_id,
    COUNT(up.id) as active_plans,
    SUM(up.credits_remaining) as total_credits
FROM asp_net_users au
LEFT JOIN users u ON u.application_user_id = au.id
LEFT JOIN user_plans up ON up.user_id = u.id AND up.is_active = true
WHERE au.email = 'EMAIL_DO_USUARIO'
GROUP BY au.id, au.email, u.id;
```

### Verificar agendamentos

```sql
SELECT
    a.id,
    u.email,
    c.name as clinic_name,
    s.name as service_name,
    a.scheduled_date,
    a.status,
    a.total_credits
FROM appointments a
JOIN users u ON u.id = a.user_id
JOIN clinics c ON c.id = a.clinic_id
JOIN clinic_services s ON s.id = a.service_id
WHERE a.created_at > NOW() - INTERVAL '7 days'
ORDER BY a.created_at DESC;
```

---

## 🎉 Resultado Final

✅ **Sistema de Agendamentos**: Totalmente funcional ✅ **Créditos**: Exibindo corretamente no
mobile ✅ **Sincronização**: Identity ↔ Domínio funcionando ✅ **Database**: Nomes de tabelas
padronizados

**Teste agora no app mobile!** 🚀
