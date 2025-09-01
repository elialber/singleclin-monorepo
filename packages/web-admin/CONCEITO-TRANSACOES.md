# Sistema de Transações - SingleClin

## Conceito Principal

O **Sistema de Transações** é o núcleo do SingleClin, permitindo que pacientes utilizem créditos pré-adquiridos em qualquer clínica parceira da rede. Uma transação representa o **uso de créditos** por um paciente em uma clínica para um serviço médico específico.

## Fluxo Completo da Transação

### 1. Pré-requisitos
- **Paciente**: Já comprou um plano (UserPlan) com créditos disponíveis
- **Clínica**: Cadastrada como parceira no sistema
- **Aplicativo Mobile**: Instalado tanto no dispositivo do paciente quanto da clínica

### 2. Início da Transação (Mobile do Paciente)
```
Paciente → Abre app → Seleciona plano com créditos → Gera QR Code
```

**O que acontece:**
- App mobile consulta UserPlans ativos do paciente
- Paciente seleciona qual plano usar e quantos créditos
- Sistema gera um **QR Code temporário** contendo:
  - JWT token com dados da transação
  - Nonce único para segurança
  - Data de expiração (30 minutos)
  - UserPlanId, créditos solicitados, etc.

### 3. Validação na Clínica (Mobile da Clínica/Scanner)
```
Staff Clínica → Abre scanner → Lê QR Code → Valida serviço → Confirma transação
```

**O que acontece:**
- Scanner decodifica o QR Code JWT
- Sistema valida:
  - Token não expirado
  - Nonce não foi usado antes
  - Paciente tem créditos suficientes
  - Clínica é parceira válida
- Staff confirma o serviço prestado
- **Transação é criada com status "Validated"**

### 4. Processamento Backend
```
Transaction criada → UserPlan atualizado → Créditos debitados → Notificações enviadas
```

**O que acontece:**
- Nova Transaction é inserida no banco
- UserPlan.CreditsRemaining é reduzido
- Logs de auditoria são criados
- Paciente recebe notificação do uso dos créditos
- Clínica recebe confirmação da transação

## Estrutura de Dados

### Transaction (Backend Model)
```csharp
public class Transaction : BaseEntity
{
    public string Code { get; set; }                    // Código único da transação
    public Guid UserPlanId { get; set; }                // Plano usado
    public Guid ClinicId { get; set; }                  // Clínica onde ocorreu
    public TransactionStatus Status { get; set; }       // Pending/Validated/Cancelled/Expired
    public int CreditsUsed { get; set; }                // Quantos créditos foram usados
    public string ServiceDescription { get; set; }      // Descrição do serviço prestado
    public DateTime? ValidationDate { get; set; }       // Quando foi validada
    public string? ValidatedBy { get; set; }            // Staff que validou
    public string? QRToken { get; set; }                // Token do QR Code usado
    public string? QRNonce { get; set; }                // Nonce para segurança
    public decimal Amount { get; set; }                 // Valor equivalente em dinheiro
    
    // Dados de geolocalização e auditoria
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
}
```

### UserPlan (Backend Model)
```csharp
public class UserPlan : BaseEntity
{
    public Guid UserId { get; set; }                    // Paciente dono do plano
    public Guid PlanId { get; set; }                    // Plano comprado
    public int Credits { get; set; }                    // Créditos totais comprados
    public int CreditsRemaining { get; set; }           // Créditos ainda disponíveis
    public decimal AmountPaid { get; set; }             // Valor pago pelo plano
    public DateTime ExpirationDate { get; set; }        // Data de vencimento
    public bool IsActive { get; set; }                  // Se está ativo
    
    // Relacionamento
    public ICollection<Transaction> Transactions { get; set; }
    
    // Propriedades calculadas
    public int CreditsUsed => Credits - CreditsRemaining;
    public bool IsExpired => DateTime.UtcNow > ExpirationDate;
}
```

## Integração entre Plataformas

### Mobile (Flutter) - Paciente
**Responsabilidades:**
- Autenticar paciente via Firebase
- Listar UserPlans ativos com créditos disponíveis
- Gerar QR Code temporário com JWT
- Receber notificações de transações processadas
- Histórico de transações do usuário

**APIs Utilizadas:**
- `GET /api/userplans/{userId}` - Listar planos do paciente
- `POST /api/qrcodes/generate` - Gerar QR Code para transação
- `GET /api/transactions/{userId}` - Histórico de transações

### Mobile (Flutter) - Scanner Clínica
**Responsabilidades:**
- Autenticar staff da clínica
- Scanner de QR Code (câmera)
- Validar dados da transação
- Confirmar serviço prestado
- Finalizar transação

**APIs Utilizadas:**
- `POST /api/qrcodes/validate` - Validar QR Code escaneado
- `POST /api/transactions` - Criar nova transação
- `GET /api/transactions/clinic/{clinicId}` - Transações da clínica

### Web Admin (React) - Portal Administrativo
**Responsabilidades:**
- Dashboard de métricas de transações
- Listagem e filtros avançados de transações
- Relatórios de uso por clínica/paciente/plano
- Gestão de transações (cancelamento, ajustes)
- Auditoria e logs

**APIs Utilizadas:**
- `GET /api/transactions` - Listagem paginada com filtros
- `GET /api/dashboard/metrics` - Métricas para dashboard
- `PUT /api/transactions/{id}/cancel` - Cancelar transação
- `GET /api/reports/transactions` - Relatórios detalhados

### Backend (.NET 9) - API e Business Logic
**Responsabilidades:**
- Autenticação JWT + Firebase
- Validação de QR Codes com nonce e expiração
- Processamento de transações
- Atualização de créditos nos UserPlans
- Logs de auditoria e segurança
- Notificações push

**Principais Endpoints:**
- `TransactionController` - CRUD de transações
- `QRCodeController` - Geração e validação de QR Codes
- `UserPlanController` - Gestão de planos de usuários
- `DashboardController` - Métricas e relatórios

## Segurança e Auditoria

### QR Code Security
- **JWT temporário** com expiração de 30 minutos
- **Nonce único** armazenado em Redis para prevenir reutilização
- **Validação online obrigatória** - sem uso offline
- **Geolocalização** para detectar uso em local incorreto

### Trilha de Auditoria
- **IP Address e User Agent** de todos os dispositivos
- **Timestamps precisos** de cada etapa da transação
- **Staff ID** que validou a transação
- **Coordenadas GPS** onde a transação ocorreu

### Validações de Negócio
- Verificar se UserPlan não está expirado
- Validar se há créditos suficientes
- Confirmar que clínica é parceira ativa
- Impedir reutilização de QR Codes

## Estados da Transação

### Pending (Pendente)
- QR Code gerado mas ainda não escaneado
- Créditos reservados mas não debitados
- Expira em 30 minutos se não validada

### Validated (Validada)
- Transação confirmada pela clínica
- Créditos debitados do UserPlan
- Serviço foi prestado e confirmado
- Estado final de sucesso

### Cancelled (Cancelada)
- Transação cancelada manualmente
- Créditos devolvidos ao UserPlan
- Motivo do cancelamento registrado

### Expired (Expirada)
- QR Code expirou sem ser usado
- Créditos liberados automaticamente
- Sistema limpa dados temporários

## Fluxo de Dados em Tempo Real

1. **Geração**: Paciente → Mobile App → Backend → QR Code JWT
2. **Escaneamento**: Scanner Clínica → Backend → Validação + Reserva
3. **Confirmação**: Staff Clínica → Backend → Transaction Created
4. **Atualização**: Backend → UserPlan Updated → Push Notifications
5. **Sincronização**: Todos os apps recebem atualização em tempo real

Este sistema garante que os créditos pré-pagos sejam utilizados de forma segura, auditável e em tempo real, criando um ecossistema integrado entre pacientes, clínicas parceiras e o sistema central de gestão.