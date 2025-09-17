# SingleClin Healthcare Management System

Sistema de gestão de saúde baseado em créditos, permitindo pacientes comprarem planos de tratamento em clínicas principais e utilizarem créditos em clínicas parceiras.

## 🏗️ Arquitetura

Monorepo com 4 pacotes principais:

- **Backend**: .NET 9 Web API com JWT + Firebase
- **Shared**: TypeScript types e utilitários compartilhados
- **Mobile**: Flutter app para pacientes e staff
- **Web Admin**: React portal administrativo

## 🚀 Quick Start

### Pré-requisitos

- .NET 9 SDK
- Node.js 18+
- PostgreSQL 15+
- Flutter 3.16+ (para mobile)

### 1. Backend (.NET API)

```bash
# Navegar para backend
cd packages/backend

# Restaurar dependências
dotnet restore

# Rodar API (HTTP apenas - desenvolvimento)
dotnet run --urls "http://localhost:5010"
```

**Backend estará disponível em:** `http://localhost:5010`
**Swagger/API Docs:** `http://localhost:5010`

### 2. Web Admin (React)

```bash
# Navegar para web admin
cd packages/web-admin

# Instalar dependências
npm install

# Rodar em desenvolvimento
npm run dev
```

**Web Admin estará disponível em:** `http://localhost:3000`

### 3. Mobile (Flutter)

```bash
# Navegar para mobile
cd packages/mobile

# Instalar dependências
flutter pub get

# Rodar no emulador/device
flutter run
```

## 🧪 Testes

### Backend Tests

```bash
cd packages/backend-tests
dotnet test
```

### E2E Tests (Web Admin)

```bash
cd packages/web-admin
npx playwright test --project=chromium
```

## 📊 Status do Projeto

### ✅ Funcionalidades Completas

- **Backend API**: .NET 9 com PostgreSQL + Firebase Auth
- **Web Admin**: React com conectividade real ao backend
- **Testes E2E**: Validação automatizada rigorosa
- **CI/CD**: GitHub Actions configurado

### 🔄 Em Desenvolvimento

- **Mobile Integration**: Substituindo mock data por APIs reais
- **Cache Layer**: Implementação de cache com Dio
- **Layout Mobile**: Responsividade e performance

## 🏃‍♂️ Comandos Essenciais

### Desenvolvimento Completo

```bash
# Terminal 1: Backend
cd packages/backend && dotnet run --urls "http://localhost:5010"

# Terminal 2: Frontend
cd packages/web-admin && npm run dev

# Terminal 3: Testes E2E
cd packages/web-admin && npx playwright test --project=chromium --ui
```

### Rodar Todos os Testes

```bash
# Backend tests
cd packages/backend-tests && dotnet test

# E2E tests
cd packages/web-admin && npx playwright test --project=chromium

# CI completo (simular GitHub Actions)
git push origin main  # Triggera workflow automaticamente
```

## 🚨 Troubleshooting

### Backend não conecta

1. Verificar se PostgreSQL está rodando
2. Conferir connection string em `appsettings.Development.json`
3. Verificar se porta 5010 está livre: `lsof -i :5010`

### Frontend não conecta com Backend

1. Verificar `packages/web-admin/.env` → `VITE_API_URL=http://localhost:5010/api`
2. Verificar se backend está rodando em HTTP (não HTTPS)

### Testes E2E falhando

1. Verificar se frontend E backend estão rodando
2. Rodar apenas Chromium: `--project=chromium`
3. Ver testes com UI: `--ui`

## 📡 Endpoints Funcionais

### API Status & Health
- `GET /health` - Status da API
- `GET /health/detailed` - Status detalhado com métricas
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe

### Autenticação
- `POST /api/auth/login/firebase` - Login com Firebase token
- `POST /api/auth/register` - Registro de novo usuário
- `POST /api/auth/refresh` - Refresh de access token
- `GET /api/auth/profile` - Dados do usuário logado
- `POST /api/auth/logout` - Logout

### Clínicas
- `GET /api/clinics` - Listar todas as clínicas
- `GET /api/clinics/{id}` - Obter dados de uma clínica
- `POST /api/clinics` - Criar nova clínica (Admin)
- `PUT /api/clinics/{id}` - Atualizar clínica

### Transações
- `GET /api/transactions` - Histórico de transações
- `POST /api/transactions` - Criar nova transação
- `GET /api/qrcode/generate` - Gerar QR Code para transação

**Swagger UI:** `http://localhost:5010` (quando backend rodando)

## 🔧 Configuração de Desenvolvimento

### Environment Variables

**Backend** (`appsettings.Development.json`):
- Connection String para PostgreSQL
- Firebase service account path
- JWT secret key

**Frontend** (`packages/web-admin/.env`):
- `VITE_API_URL=http://localhost:5010/api`
- Firebase config keys
- Google Maps API key

### Estrutura de Dados

**Core Models:**
- `IUser`: Autenticação e roles
- `IClinic`: Informações e parceria
- `IPlan`: Planos com alocação de créditos
- `ITransaction`: Registros de uso com QR codes

## 📈 CI/CD Status

[![CI Tests](https://github.com/seu-username/singleclin-monorepo/workflows/CI%20Tests/badge.svg)](https://github.com/seu-username/singleclin-monorepo/actions)

**Workflow inclui:**
- Backend tests (.NET)
- Frontend build (React)
- E2E tests (Playwright)
- PostgreSQL service

## 🎯 Próximos Passos

1. **Integração Mobile-Backend** (Fase 2)
2. **Layout Responsivo** (Fase 3)
3. **Deploy Production** (Fase 4)

---

**💡 Desenvolvido com metodologia anti-procrastinação: tarefas de 25 minutos com escape hatches para manter momentum!**# Deploy test with correct OIDC
# Testing OIDC fix 2
