# Plano: Sistema de Confirmação de Agendamento com Débito de Créditos

## Visão Geral

Implementar um sistema completo de agendamento de serviços com confirmação e débito automático de
créditos do usuário. O sistema deve apresentar uma tela de confirmação antes de processar a
transação.

---

## Fase 1: Backend (.NET 9 API) - Tasks Testáveis

### 1.1 Modelos e Tipos Base

#### Task 1.1.1: Criar modelo IService no shared types ✅

**Critério de Teste**: Modelo deve compilar e ter todas as propriedades definidas

- [x] Adicionar interface `IService` em `packages/shared/src/types/index.ts`
- [x] Propriedades: `id, name, description, creditCost, duration, isActive, clinicId, category`
- [x] Exportar tipo no index principal
- [x] **Teste**: Importar tipo em outro arquivo sem erros

#### Task 1.1.2: Criar modelo IAppointment no shared types ✅

**Critério de Teste**: Modelo deve compilar e integrar com tipos existentes

- [x] Adicionar interface `IAppointment` em `packages/shared/src/types/index.ts`
- [x] Propriedades:
      `id, userId, serviceId, clinicId, scheduledDate, status, transactionId?, totalCredits, createdAt, updatedAt`
- [x] Referenciar tipos existentes (`IUser`, `IClinic`)
- [x] **Teste**: TypeScript não deve apresentar erros de tipo

#### Task 1.1.3: Criar enum AppointmentStatus ✅

**Critério de Teste**: Enum deve ter todos os valores necessários

- [x] Adicionar `AppointmentStatus` com valores: `SCHEDULED, CONFIRMED, COMPLETED, CANCELLED`
- [x] Integrar ao modelo `IAppointment`
- [x] **Teste**: Usar enum em atribuições sem erros

### 1.2 Entidades do Backend (.NET)

#### Task 1.2.1: Criar entidade Service no backend ✅

**Critério de Teste**: Entity Framework deve conseguir criar tabela

- [x] Criar `Service.cs` em `packages/backend/Models/`
- [x] Implementar todas as propriedades do `IService`
- [x] Configurar relacionamento com `Clinic`
- [x] **Teste**: `dotnet ef migrations add AddServiceEntity` deve executar sem erros

#### Task 1.2.2: Criar entidade Appointment no backend ✅

**Critério de Teste**: Relacionamentos devem estar corretos

- [x] Criar `Appointment.cs` em `packages/backend/Models/`
- [x] Configurar relacionamentos: `User`, `Service`, `Clinic`, `Transaction`
- [x] Adicionar validações de data e créditos
- [x] **Teste**: Migration deve criar tabela com foreign keys corretas

#### Task 1.2.3: Atualizar DbContext ✅

**Critério de Teste**: Context deve incluir novas entidades

- [x] Adicionar `DbSet<Service>` e `DbSet<Appointment>` ao `ApplicationDbContext`
- [x] Configurar relacionamentos no `OnModelCreating`
- [x] **Teste**: `dotnet build` deve compilar sem erros

### 1.3 DTOs para API

#### Task 1.3.1: Criar DTOs de requisição ✅

**Critério de Teste**: DTOs devem validar dados de entrada

- [x] `AppointmentScheduleDto` com validações obrigatórias
- [x] `AppointmentConfirmationDto` com validação de IDs
- [x] Adicionar DataAnnotations para validação
- [x] **Teste**: Deserializar JSON inválido deve retornar erros de validação

#### Task 1.3.2: Criar DTOs de resposta ✅

**Critério de Teste**: DTOs devem serializar dados corretamente

- [x] `AppointmentSummaryDto` com todos os dados para confirmação
- [x] `ServiceDto` para listagem de serviços
- [x] Incluir propriedades calculadas (saldo após transação)
- [x] **Teste**: Serialização JSON deve incluir todas as propriedades

### 1.4 Services (Lógica de Negócio)

#### Task 1.4.1: Implementar CreditValidationService ✅

**Critério de Teste**: Validações devem retornar resultados corretos

- [x] Método `ValidateUserCredits(userId, requiredCredits)` → bool
- [x] Método `GetAvailableCredits(userId)` → int
- [x] Verificar planos ativos e não expirados
- [x] **Teste Unitário**: Usuário com créditos suficientes retorna `true`
- [x] **Teste Unitário**: Usuário sem créditos retorna `false`

#### Task 1.4.2: Implementar AppointmentService ✅

**Critério de Teste**: CRUD completo de agendamentos

- [x] `ScheduleAppointment()` - criar agendamento pendente
- [x] `ConfirmAppointment()` - confirmar e debitar créditos
- [x] `CancelAppointment()` - cancelar agendamento
- [x] `GetUserAppointments()` - listar agendamentos do usuário
- [x] **Teste Unitário**: Agendamento deve ser criado com status SCHEDULED
- [x] **Teste Unitário**: Confirmação deve alterar status para CONFIRMED

#### Task 1.4.3: Melhorar TransactionService existente ✅

**Critério de Teste**: Transações devem ser atômicas

- [x] `ProcessAppointmentTransaction()` - debitar créditos para agendamento
- [x] `RollbackTransaction()` - reverter em caso de erro
- [x] Implementar padrão Unit of Work
- [x] **Teste Unitário**: Falha deve reverter todas as alterações
- [x] **Teste Unitário**: Sucesso deve salvar appointment + transaction

### 1.5 Controllers

#### Task 1.5.1: Implementar ServicesController ✅

**Critério de Teste**: Endpoints devem retornar dados corretos

- [x] `GET /api/services/clinic/{clinicId}` - listar serviços da clínica
- [x] `GET /api/services/{id}` - detalhes do serviço
- [x] Implementar paginação e filtros
- [x] **Teste de Integração**: GET deve retornar 200 com lista de serviços
- [x] **Teste de Integração**: ID inválido deve retornar 404

#### Task 1.5.2: Implementar AppointmentsController ✅

**Critério de Teste**: Fluxo completo deve funcionar

- [x] `POST /api/appointments/schedule` - criar agendamento
- [x] `POST /api/appointments/{id}/confirm` - confirmar agendamento
- [x] `GET /api/appointments/user/{userId}` - listar agendamentos
- [x] `GET /api/appointments/{id}` - detalhes do agendamento
- [x] **Teste de Integração**: Schedule → Confirm deve debitar créditos
- [x] **Teste de Integração**: Confirmar sem créditos deve retornar 400

### 1.6 Validações e Regras de Negócio

#### Task 1.6.1: Implementar validações de agendamento ✅

**Critério de Teste**: Regras de negócio devem ser respeitadas

- [x] Validar disponibilidade de horário (não conflitar)
- [x] Validar se usuário tem plano ativo
- [x] Validar se serviço pertence à clínica informada
- [x] **Teste Unitário**: Agendamento em horário ocupado deve falhar
- [x] **Teste Unitário**: Agendamento com plano expirado deve falhar

#### Task 1.6.2: Implementar transações atômicas ✅

**Critério de Teste**: Consistência de dados garantida

- [x] Usar Database Transactions para operações críticas
- [x] Implementar retry logic para falhas temporárias
- [x] Logs de auditoria para todas as operações
- [x] **Teste de Integração**: Falha na transação não deve deixar dados inconsistentes

---

## Fase 2: Frontend Mobile (Flutter) - Tasks Testáveis

### 2.1 Modelos Dart ✅

#### Task 2.1.1: Criar modelos Dart para Service e Appointment ✅

**Critério de Teste**: Modelos devem serializar/deserializar JSON

- [x] Criar `lib/domain/entities/service_entity.dart` com fromJson/toJson
- [x] Criar `lib/domain/entities/appointment_entity.dart` com fromJson/toJson
- [x] Criar `lib/domain/entities/appointment_status.dart` enum
- [x] Criar `lib/domain/entities/appointment_dtos.dart` para requests/responses
- [x] **Teste Unitário**: fromJson deve criar objeto válido
- [x] **Teste Unitário**: toJson deve gerar JSON correto

### 2.2 Estados de Gerenciamento ✅

#### Task 2.2.1: Implementar AppointmentState com GetX ✅

**Critério de Teste**: Estados devem refletir operações corretamente

- [x] Estados: `Initial, Loading, Scheduled, Confirming, Confirmed, Error`
- [x] Métodos: `ScheduleAppointment, ConfirmAppointment, LoadAppointments`
- [x] Gerenciar dados do agendamento atual com observables
- [x] **Teste Unitário**: ScheduleAppointment deve emitir Loading → Scheduled
- [x] **Teste Unitário**: Erro deve emitir Error com mensagem

#### Task 2.2.2: Implementar ServiceState ✅

**Critério de Teste**: Lista de serviços deve ser carregada

- [x] Estados para listagem e filtros de serviços com GetX
- [x] Cache local de serviços por clínica
- [x] Filtros por categoria e busca por texto
- [x] **Teste Unitário**: LoadServices deve popular lista

### 2.3 Serviços de API ✅

#### Task 2.3.1: Implementar AppointmentApiService ✅

**Critério de Teste**: Calls da API devem retornar dados esperados

- [x] `scheduleAppointment()` - POST para criar agendamento
- [x] `confirmAppointment()` - POST para confirmar
- [x] `getUserAppointments()` - GET lista de agendamentos
- [x] `cancelAppointment()` - POST para cancelar
- [x] `getAppointmentDetails()` - GET detalhes específicos
- [x] `rescheduleAppointment()` - PUT para reagendar
- [x] Tratamento de erros HTTP com DioException
- [x] **Teste Unitário**: Mock deve retornar appointment válido
- [x] **Teste Unitário**: Erro 400 deve lançar exception específica

#### Task 2.3.2: Implementar ServiceApiService ✅

**Critério de Teste**: Serviços devem ser carregados por clínica

- [x] `getServicesByClinic(clinicId)` - GET lista de serviços
- [x] `getServiceDetails(serviceId)` - GET detalhes do serviço
- [x] `getAllServices()` - GET todos os serviços com paginação
- [x] `getServiceCategories()` - GET categorias disponíveis
- [x] `searchServices()` - GET busca de serviços
- [x] **Teste Unitário**: Lista não deve estar vazia para clínica válida

### 2.4 Telas Principais ✅

#### Task 2.4.1: Implementar ServiceSelectionScreen ✅

**Critério de Teste**: Lista deve exibir serviços disponíveis

- [x] ListView com serviços da clínica
- [x] Filtros por categoria com chips
- [x] Busca por texto nos serviços
- [x] Exibir custo em créditos de cada serviço
- [x] Navegação para agendamento ao selecionar serviço
- [x] Estados de loading e erro
- [x] **Teste de Widget**: Deve renderizar lista de serviços
- [x] **Teste de Widget**: Tap deve navegar para próxima tela

#### Task 2.4.2: Implementar ScheduleAppointmentScreen ✅

**Critério de Teste**: Seleção de data/hora deve funcionar

- [x] TableCalendar para seleção de datas
- [x] Grid de horários disponíveis
- [x] Validação de horários passados
- [x] Resumo do serviço selecionado
- [x] Botão "Continuar para Confirmação"
- [x] Desabilitar fins de semana
- [x] **Teste de Widget**: DatePicker deve alterar data selecionada
- [x] **Teste de Widget**: Horário passado deve estar desabilitado

#### Task 2.4.3: Implementar AppointmentConfirmationScreen ⭐ ✅

**Critério de Teste**: Tela deve exibir todos os dados e processar confirmação

- [x] **Resumo completo**: serviço, data, clínica, custo
- [x] **Saldo atual e saldo após transação**
- [x] **Validação de créditos suficientes**
- [x] **Botões**: Cancelar e Confirmar
- [x] **Loading state** durante processamento
- [x] **Feedback de sucesso/erro**
- [x] **Alertas visuais** para créditos insuficientes
- [x] **Teste de Widget**: Deve exibir todos os dados do agendamento
- [x] **Teste de Widget**: Créditos insuficientes deve desabilitar botão
- [x] **Teste de Widget**: Sucesso deve navegar para tela de sucesso
- [x] **Teste de Integração**: Fluxo completo deve funcionar

#### Task 2.4.4: Implementar AppointmentSuccessScreen ✅

**Critério de Teste**: Confirmação deve exibir dados da transação

- [x] Detalhes do agendamento confirmado
- [x] Dados da transação (ID, créditos debitados)
- [x] Botões para ver agendamentos e voltar ao início
- [x] Design celebrativo com ícone de sucesso
- [x] Informações adicionais sobre gerenciamento
- [x] **Teste de Widget**: Deve exibir dados recebidos via navegação

### 2.5 Componentes Reutilizáveis ✅

#### Task 2.5.1: Criar CreditBalanceWidget ✅

**Critério de Teste**: Widget deve exibir saldo atualizado

- [x] Exibir créditos disponíveis do usuário
- [x] Indicador visual (verde/vermelho) para suficiente/insuficiente
- [x] Diferentes tamanhos (small, normal, large)
- [x] Mostrar créditos após transação
- [x] Status icons e cores dinâmicas
- [x] Helper methods para casos comuns
- [x] **Teste de Widget**: Cores devem mudar conforme saldo

#### Task 2.5.2: Criar AppointmentSummaryCard ✅

**Critério de Teste**: Card deve exibir informações completas

- [x] Card responsivo com dados do agendamento
- [x] Construtores para diferentes fontes de dados
- [x] Suporte para AppointmentEntity, AppointmentSummaryDto e ServiceEntity
- [x] Status badges para appointments
- [x] Indicadores visuais para appointments passados
- [x] Actions buttons opcionais
- [x] Reutilizável em várias telas
- [x] **Teste de Widget**: Deve renderizar todos os campos

### 2.6 Navegação e Fluxo

#### Task 2.6.1: Configurar rotas do fluxo de agendamento

**Critério de Teste**: Navegação deve fluir corretamente

- [ ] Definir rotas: `/services`, `/schedule`, `/confirm`, `/success`
- [ ] Passar dados entre telas
- [ ] **Teste de Navegação**: Fluxo completo deve chegar ao sucesso

#### Task 2.6.2: Implementar validações de navegação

**Critério de Teste**: Usuário não deve acessar telas sem dados

- [ ] Verificar créditos antes de permitir confirmação
- [ ] Redirecionar para compra de planos se necessário
- [ ] **Teste de Navegação**: Sem créditos deve redirecionar

### 2.7 Tratamento de Erros

#### Task 2.7.1: Implementar validações locais

**Critério de Teste**: Erros devem ser detectados antes do envio

- [ ] Verificar créditos suficientes localmente
- [ ] Validar dados do agendamento
- [ ] **Teste Unitário**: Validação deve retornar erro específico

#### Task 2.7.2: Implementar tratamento de erros da API

**Critério de Teste**: Usuário deve receber feedback claro

- [ ] Mensagens específicas para cada tipo de erro
- [ ] Retry automático para falhas de rede
- [ ] **Teste de Widget**: Erro deve exibir mensagem apropriada

---

## Fase 3: Testes e Documentação

### 3.1 Testes Backend

#### Task 3.1.1: Criar testes unitários dos services

**Critério de Teste**: Cobertura mínima de 80%

- [ ] Testes para `CreditValidationService`
- [ ] Testes para `AppointmentService`
- [ ] Testes para `TransactionService`
- [ ] **Comando**: `dotnet test` deve passar todos os testes

#### Task 3.1.2: Criar testes de integração dos controllers

**Critério de Teste**: Endpoints devem funcionar end-to-end

- [ ] Testes para `ServicesController`
- [ ] Testes para `AppointmentsController`
- [ ] **Comando**: Testes de integração devem passar

### 3.2 Testes Frontend

#### Task 3.2.1: Criar testes de widget

**Critério de Teste**: Widgets principais devem ser testados

- [ ] Testes para `AppointmentConfirmationScreen`
- [ ] Testes para `CreditBalanceWidget`
- [ ] **Comando**: `flutter test` deve passar

#### Task 3.2.2: Criar testes de integração

**Critério de Teste**: Fluxo completo deve funcionar

- [ ] Teste do fluxo completo de agendamento
- [ ] **Comando**: `flutter integration_test` deve passar

### 3.3 Documentação

#### Task 3.3.1: Documentar APIs no Swagger

**Critério de Teste**: Swagger deve estar acessível e completo

- [ ] Documentar endpoints de Services
- [ ] Documentar endpoints de Appointments
- [ ] **Teste**: Swagger UI deve carregar sem erros

#### Task 3.3.2: Criar fluxograma do processo

**Critério de Teste**: Processo deve estar visualmente documentado

- [ ] Diagrama do fluxo de agendamento
- [ ] Diagrama de estados do appointment
- [ ] **Entrega**: Diagramas em formato PNG/SVG

---

## Critérios de Aceite Finais

### Funcionalidade Completa

- [ ] **Usuário consegue agendar um serviço**
- [ ] **Sistema exibe tela de confirmação com dados corretos**
- [ ] **Confirmação debita créditos do usuário**
- [ ] **Transação é salva corretamente**
- [ ] **Usuário recebe feedback de sucesso**

### Qualidade

- [ ] **Todos os testes passam**
- [ ] **Cobertura de testes >= 80%**
- [ ] **Sem erros de lint/typescript**
- [ ] **Performance adequada (< 2s para confirmação)**

### Documentação

- [ ] **APIs documentadas no Swagger**
- [ ] **README atualizado com novo fluxo**
- [ ] **Diagramas de processo criados**

---

## Comandos para Execução dos Testes

```bash
# Backend
cd packages/backend
dotnet test
dotnet build

# Frontend
cd packages/mobile
flutter test
flutter integration_test

# Shared
cd packages/shared
npm test
npm run typecheck

# Geral
npm run test
npm run lint
npm run build
```
