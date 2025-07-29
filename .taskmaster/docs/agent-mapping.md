# Mapeamento de Agentes para Tarefas do SingleClin

Este documento define qual agente especializado deve ser usado para cada tarefa do projeto.

## Delegação de Agentes por Tarefa

### Task 1: Configurar Estrutura Monorepo
**Agente:** `monorepo-architect`
- Especialista em npm workspaces, TypeScript, ESLint, CI/CD
- Aplica-se a todas as subtarefas (1.1 a 1.5)

### Task 2: Configurar Backend API com .NET e JWT
**Agente:** `dotnet-api-expert`
- Especialista em .NET 9 Web API, JWT, Firebase Admin SDK
- Aplica-se a todas as subtarefas (2.1 a 2.5)

### Task 3: Configurar Banco de Dados PostgreSQL
**Agente:** `database-architect`
- Especialista em PostgreSQL, Entity Framework Core, migrations
- Aplica-se a todas as subtarefas (3.1 a 3.5)

### Task 4: Implementar Sistema de Autenticação Multi-Perfil
**Agente Principal:** `auth-security-expert`
**Agente Auxiliar:** `dotnet-api-expert`
- Especialistas em autenticação, JWT, Firebase Auth, roles
- Aplica-se a todas as subtarefas (4.1 a 4.5)

### Task 5: Criar CRUD de Planos (Admin Only)
**Agente Principal:** `dotnet-api-expert`
**Agente Auxiliar:** `database-architect`
- CRUD operations, validações, autorização
- Aplica-se a todas as subtarefas (5.1 a 5.5)

### Task 6: Desenvolver App Mobile Flutter - Estrutura Base
**Agente:** `flutter-mobile-expert`
- Especialista em Flutter, Clean Architecture, GetX
- Aplica-se a todas as subtarefas (6.1 a 6.5)

### Task 7: Implementar Autenticação no App Mobile
**Agente Principal:** `flutter-mobile-expert`
**Agente Auxiliar:** `auth-security-expert`
- Firebase Auth no Flutter, login social
- Aplica-se a todas as subtarefas (7.1 a 7.5)

### Task 8: Criar Sistema de Geração de QR Code
**Agente:** `qr-transaction-specialist`
- Especialista em QR codes, JWT, Redis, segurança
- Aplica-se a todas as subtarefas (8.1 a 8.5)

### Task 9: Implementar Tela de Visualização de Plano e Saldo
**Agente:** `flutter-mobile-expert`
- UI/UX mobile, state management, integração API
- Aplica-se a todas as subtarefas (9.1 a 9.5)

### Task 10: Desenvolver Funcionalidade de Geração de QR Code no App
**Agente Principal:** `flutter-mobile-expert`
**Agente Auxiliar:** `qr-transaction-specialist`
- QR code display, timer, brightness control
- Aplica-se a todas as subtarefas (10.1 a 10.5)

### Task 11: Criar Sistema de Leitura e Validação de QR Code
**Agente Principal:** `qr-transaction-specialist`
**Agente Auxiliar:** `dotnet-api-expert`
- Validação JWT, transações, rate limiting
- Aplica-se a todas as subtarefas (11.1 a 11.5)

### Task 12: Implementar Scanner de QR Code no App da Clínica
**Agente Principal:** `flutter-mobile-expert`
**Agente Auxiliar:** `qr-transaction-specialist`
- Mobile scanner, permissões, feedback visual
- Aplica-se a todas as subtarefas (12.1 a 12.5)

### Task 13: Desenvolver Portal Web Admin com React
**Agente:** `react-admin-specialist`
- React, TypeScript, Material-UI, dashboards
- Aplica-se a todas as subtarefas (13.1 a 13.5)

### Task 14: Implementar Sistema de Notificações
**Agente:** `notification-system-expert`
- FCM, SendGrid, job scheduling, templates
- Aplica-se a todas as subtarefas (14.1 a 14.5)

### Task 15: Criar Sistema de Relatórios e Analytics
**Agente:** `analytics-reporting-specialist`
- Queries otimizadas, Chart.js, exportação Excel/PDF
- Aplica-se a todas as subtarefas (15.1 a 15.5)

## Como Usar Este Mapeamento

Quando trabalhar em uma tarefa específica:

1. Consulte este documento para identificar o agente correto
2. Use o comando: `/agent [nome-do-agente]`
3. Forneça o contexto da tarefa/subtarefa para o agente
4. O agente aplicará sua expertise especializada

## Colaboração Entre Agentes

Para tarefas com múltiplos agentes:
- O **Agente Principal** lidera a implementação
- O **Agente Auxiliar** fornece suporte em aspectos específicos
- Ambos devem ser consultados para decisões arquiteturais

## Benefícios da Delegação

- **Expertise Especializada**: Cada agente tem profundo conhecimento em sua área
- **Melhores Práticas**: Aplicação automática de padrões e convenções
- **Eficiência**: Redução de erros e retrabalho
- **Qualidade**: Código mais robusto e manutenível