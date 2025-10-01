# Arquitetura

- **`packages/backend`**: ASP.NET Core 9 com Identity, EF Core (PostgreSQL), Redis, Hangfire,
  Firebase Admin SDK e integrações Azure (Storage, Communication); inclui middlewares próprios
  (`JwtAuthenticationMiddleware`, `FirebaseAuthenticationMiddleware`) e serviços de sincronização.
- **`packages/web-admin`**: React + Vite consumindo o backend via JWT local; usa Firebase Web SDK
  para login social/ID token.
- **`packages/mobile`**: Flutter com Firebase Auth; interceptor HTTP injeta ID tokens em todas as
  requisições.
- **`packages/shared`**: Tipos/utilitários TypeScript compartilhados entre frontend e backend.

## Red Flags Críticos

### Credenciais sensíveis versionadas

- **Impacto**: exposição direta de banco e contas Azure/Firebase se o repositório for acessado por
  terceiros.
- **Evidência**: `packages/backend/appsettings.json:10`, `packages/backend/appsettings.json:89`,
  `packages/backend/firebase-service-account.json:1`, `credentials/firebase-service-account.json:1`.
- **Recomendação**: mover segredos para Key Vault ou Secret Manager, remover arquivos do
  versionamento e rotacionar todas as chaves/senhas afetadas.
- **Tasks sugeridas**:
  1. Migrar connection strings, credenciais Firebase e senha de admin para o Key Vault/Azure App
     Configuration.
  2. Remover arquivos sensíveis do Git (adicionar ao `.gitignore` e limpar histórico com
     `git filter-repo` ou equivalente).
  3. Rotacionar senhas/chaves expostas e atualizar pipelines de CI/CD para consumir os novos
     segredos.

### Senhas enviadas em texto claro por e-mail

- **Impacto**: comprometimento imediato em caso de vazamento de caixa de e-mail; viola
  LGPD/compliance.
- **Evidência**: `packages/backend/Services/AuthService.cs:195`,
  `packages/backend/Services/UserService.cs:768`.
- **Recomendação**: substituir envio de senha por fluxo de convite ou reset seguro; invalidar
  qualquer credencial já distribuída dessa forma.
- **Tasks sugeridas**:
  1. Implementar fluxo de convite com token temporário para definição de senha (sem revelar senha
     gerada).
  2. Revogar/forçar reset de todas as contas criadas com senha enviada por e-mail.
  3. Atualizar templates de e-mail e testes automatizados para refletir o novo fluxo.

### Middleware Firebase gerando refresh tokens por requisição - 🚧

- **Impacto**: criação descontrolada de refresh tokens a cada request autenticado com
  `X-Firebase-Token`, abrindo espaço para DoS e inconsistência de sessões.
- **Evidência**: `packages/backend/Middleware/FirebaseAuthenticationMiddleware.cs:25` chamando
  `AuthService.FirebaseLoginAsync`, que persiste tokens em
  `packages/backend/Services/AuthService.cs:739`.
- **Recomendação**: validar ID tokens de forma stateless e emitir JWT transitório apenas quando
  necessário; mover conversão para um endpoint explícito de login ou camada de gateway.
- **Tasks sugeridas**:
  1. Refatorar `FirebaseAuthenticationMiddleware` para apenas validar o ID token e popular
     `HttpContext.User` sem criar refresh tokens.
  2. Criar endpoint dedicado para troca de ID token por JWT/refresh token quando realmente
     necessário.
  3. Implementar limpeza/revogação dos refresh tokens já emitidos indevidamente (job ou script de
     migração).

### Exclusão de usuário sem sincronizar com Firebase

- **Impacto**: usuários “removidos” localmente continuam com acesso ativo via Firebase.
- **Evidência**: ausência de chamada a `FirebaseAuthService.DeleteUserAsync` em
  `packages/backend/Services/UserService.cs:307`, enquanto o método existe em
  `packages/backend/Services/FirebaseAuthService.cs:109`.
- **Recomendação**: encapsular exclusão em orquestração que remova/disable o usuário tanto no
  Firebase quanto no banco, com compensação/outbox em caso de falha.
- **Tasks sugeridas**:
  1. Criar serviço transacional (outbox/saga) que dispare `DeleteUserAsync` no Firebase e só
     finalize a deleção local após sucesso.
  2. Instrumentar logs e alertas de reconciliação para detectar divergências entre banco e Firebase.
  3. Executar reconciliação pontual para remover/manter em quarentena usuários órfãos existentes.

## Red Flags Altos

### Atualização de usuário não propaga para Firebase e domínio

- **Impacto**: divergência de e-mail, claims e status entre sistemas, afetando autorização e
  experiência do usuário.
- **Evidência**: `packages/backend/Services/UserService.cs:258` (alteração apenas em Identity) e
  `packages/backend/Services/FirebaseAuthService.cs:211` (método de update não utilizado).
- **Recomendação**: sincronizar atualizações com Firebase (`UpdateUserAsync`) e
  `AppDbContext.Users`, garantindo idempotência via eventos/outbox.
- **Tasks sugeridas**:
  1. Incorporar chamadas ao `FirebaseAuthService.UpdateUserAsync` nos fluxos de
     atualização/ativação.
  2. Atualizar simultaneamente a entidade de domínio (`AppDbContext.Users`) ou mover a escrita via
     evento assíncrono com confirmação.
  3. Criar testes de integração cobrindo atualização de e-mail/status para validar propagação
     completa.

### Fluxo de cadastro não é atômico

- **Impacto**: criação parcial de clínicas/usuários quando falhas ocorrem, gerando resíduos e
  inconsciência com Firebase.
- **Evidência**: `packages/backend/Services/AuthService.cs:80-147`,
  `packages/backend/Services/UserService.cs:200-236` (clínica salva antes do usuário, ausência de
  compensação após falhas de Identity/Firebase).
- **Recomendação**: usar transação local + outbox (ou saga) garantindo consistência entre criação de
  clínica, `ApplicationUser` e Firebase.
- **Tasks sugeridas**:
  1. Reordenar fluxo para criar clínica somente após sucesso do `UserManager.CreateAsync`.
  2. Implementar transação local que envolva criação de clínica e usuário, com compensação se
     Firebase falhar.
  3. Configurar outbox/worker para reexecutar tentativas de criação no Firebase quando ocorrer falha
     temporária.

### SyncUserWithBackendAsync contorna UserManager

- **Impacto**: modifica `ApplicationUser` via `_context.SaveChangesAsync`, não atualiza
  `SecurityStamp`, mantendo tokens inválidos válidos.
- **Evidência**: `packages/backend/Services/AuthService.cs:782-838`.
- **Recomendação**: realizar toda alteração em `ApplicationUser` via `UserManager`, com atualização
  de `SecurityStamp` e revogação de tokens quando necessário.
- **Tasks sugeridas**:
  1. Refatorar `SyncUserWithBackendAsync` para usar `UserManager.UpdateAsync` e ajustar
     claims/tokens via APIs oficiais.
  2. Forçar regeneração de tokens (`SecurityStampValidator`) após sincronização.
  3. Adicionar testes garantindo que o sync invalida sessões antigas e aplica dados corretos.

### Dupla fonte de verdade para usuário

- **Impacto**: `ApplicationUser` e `AppDbContext.User` podem divergir, afetando relatórios e consumo
  de créditos.
- **Evidência**: criação “on demand” da entidade de domínio em
  `packages/backend/Services/UserService.cs:138`.
- **Recomendação**: definir fonte única de verdade e sincronizar a outra via eventos/outbox ou job
  periódico com alerta.
- **Tasks sugeridas**:
  1. Definir modelo mestre (sugestão: `ApplicationUser`) e propagar eventos para manter
     `AppDbContext.Users` consistente.
  2. Implementar job periódico de reconciliação que compare ambas as tabelas e corrija divergências
     automaticamente.
  3. Instrumentar métricas/alertas de divergência para observabilidade do processo.

## Outras Observações

- Não há testes automatizados cobrindo cadastro, login, atualização ou exclusão em fluxo Firebase ↔
  banco; criar suíte end-to-end que valide consistência e cenários de falha parcial.
- Health-check do Firebase (`packages/backend/HealthChecks/FirebaseHealthCheck.cs:27`) usa
  `CreateCustomToken`; considerar cachear resultado ou validar via `VerifyIdToken` para reduzir
  custo.
- Mobile envia ID tokens no header padrão, mas o backend depende de header customizado para
  middlewares; alinhar contrato (remover header extra ou documentar fallback consistente).
