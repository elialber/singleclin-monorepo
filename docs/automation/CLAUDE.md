# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Task Master AI Instructions

**Import Task Master's development workflow commands and guidelines, treat as if import is in the
main CLAUDE.md file.** @./.taskmaster/CLAUDE.md

## Project Overview: SingleClin Healthcare Management System

SingleClin is a credit-based healthcare management platform allowing patients to purchase treatment
plans at a main clinic and use credits at any partner clinics. The system consists of a monorepo
with four main packages:

- **Backend**: .NET 9 Web API with JWT authentication and Firebase integration
- **Shared**: TypeScript types, utilities, and constants shared across all packages
- **Mobile**: Flutter app for patients and clinic staff (scanner functionality)
- **Web Admin**: React admin portal for system management

## Architecture & Structure

### Monorepo Organization

```
SingleClin/
├── packages/
│   ├── backend/          # .NET 9 Web API
│   ├── shared/           # TypeScript shared types/utilities
│   ├── mobile/           # Flutter app
│   └── web-admin/        # React admin portal
├── .taskmaster/          # Task Master AI configuration
└── .claude/              # Claude Code configuration
```

### Core Domain Models

From `packages/shared/src/types/`:

- **IUser**: User authentication and roles (Patient, Clinic, Admin)
- **IClinic**: Clinic information and partnership status
- **IPlan**: Treatment plans with credit allocation
- **IUserPlan**: User-plan associations with remaining credits
- **ITransaction**: Credit usage records with QR code validation
- **IQRCode**: Temporary QR codes for clinic visits

### Backend Architecture (.NET 9)

- **Controllers/**: API endpoints organized by domain
- **Services/**: Business logic layer
- **Models/**: Data models and entities
- **DTOs/**: Data transfer objects for API communication
- **Extensions/**: Service configuration extensions
- **Middleware/**: Custom middleware for authentication/validation

## Development Commands

### Monorepo Management

```bash
# Install all dependencies across workspaces
npm install

# Build all packages
npm run build

# Run development servers
npm run dev

# Run tests across all packages
npm run test

# Lint and format code
npm run lint
npm run lint:fix
npm run format

# Type checking
npm run typecheck

# Clean build artifacts
npm run clean

# Individual package commands
npm run build:shared
npm run build:web-admin
npm run dev:shared
npm run dev:web-admin
npm run test:shared
npm run test:web-admin
```

### Backend (.NET 9)

```bash
# Navigate to backend
cd packages/backend

# Run the API
dotnet run

# Build project
dotnet build

# Run tests
dotnet test

# Entity Framework migrations
dotnet ef migrations add MigrationName
dotnet ef database update
```

### Frontend Development

```bash
# Shared package development
npm run dev:shared
npm run build:shared

# Web admin development
npm run dev:web-admin
npm run build:web-admin

# Mobile (Flutter) - from packages/mobile directory
npm run mobile:run
npm run mobile:build:android
npm run mobile:build:ios

# Or directly with Flutter
cd packages/mobile
flutter run
flutter build apk
flutter build ios
```

## Task Master Integration

This project uses Task Master AI for systematic development workflow. Current progress:

- ✅ **Task 1**: Complete monorepo setup with npm workspaces (COMPLETED)
- 🔄 **Task 2**: Backend API with JWT authentication (in progress - subtask 2.2)
- ⏳ **Task 3+**: Database setup, authentication system, QR code generation, mobile app development

### Monorepo Setup Completion

The monorepo structure is now fully configured with:

- ✅ npm workspaces for dependency management
- ✅ Shared TypeScript package with comprehensive types and utilities
- ✅ Web admin package with React/Vite setup
- ✅ Mobile Flutter package structure (existing)
- ✅ ESLint 9 with flat config for modern linting
- ✅ Prettier for consistent code formatting
- ✅ Husky + lint-staged for pre-commit hooks
- ✅ Comprehensive .gitignore for all package types

### Key Task Master Commands

```bash
# Get next task to work on
task-master next

# Show specific task details
task-master show 2.2

# Update task status
task-master set-status --id=2.2 --status=done

# Update subtask with implementation notes
task-master update-subtask --id=2.2 --prompt="implementation details"
```

## Firebase Integration

The system uses Firebase for:

- **Authentication**: JWT token validation via Firebase Admin SDK
- **User Management**: Social login (Google/Apple) support
- **Token Security**: Firebase tokens converted to internal JWT

### Configuration Files

- `packages/backend/appsettings.json`: Firebase project configuration
- Service account JSON file needed for Firebase Admin SDK

## Database Integration

### PostgreSQL with Entity Framework Core

- **Connection String**: Configured in appsettings.json
- **Migrations**: Automatic on startup in development
- **Models**: Located in `packages/backend/Models/`

### Key Entities

- Users with role-based access control
- Clinics (Origin/Partner classification)
- Plans with credit allocation
- Transactions for credit usage tracking

## Security Considerations

### Authentication Flow

1. Firebase authentication (social/email+password)
2. Firebase token validation via Admin SDK
3. Internal JWT token generation with custom claims
4. Role-based authorization (Patient, Clinic, Admin)

### QR Code Security

- Temporary JWT tokens with 30-minute expiration
- Unique nonces stored in Redis to prevent reuse
- Online validation required for all transactions

## Testing Strategy

### Backend Testing

- Unit tests for services and utilities
- Integration tests for API endpoints
- Authentication flow testing with mocked Firebase

### Frontend Testing

- Jest for shared TypeScript utilities
- Flutter widget testing for mobile UI
- React Testing Library for admin portal

### E2E Testing

- QR code generation and validation flow
- Credit debit and balance updates
- Multi-role authentication scenarios

## Development Workflow

### Starting Development

1. Use Task Master to get next task: `task-master next`
2. Review task details: `task-master show <id>`
3. Set task to in-progress: `task-master set-status --id=<id> --status=in-progress`
4. Implement following task requirements
5. Update subtasks with progress: `task-master update-subtask --id=<id> --prompt="progress notes"`
6. Complete task: `task-master set-status --id=<id> --status=done`

### Code Quality

- Pre-commit hooks with Husky and lint-staged
- ESLint 9 with flat config for TypeScript
- Prettier for code formatting
- TypeScript strict mode enabled
- Workspace-based dependency management
- Consistent package structure across all TypeScript packages

### Git Workflow

- Feature branches for task implementation
- Reference task IDs in commit messages: `feat: implement JWT auth (task 2.2)`
- Pull requests for task completion review

## Current Development Status

**Completed**: Task 1 - Complete monorepo setup with npm workspaces ✅ **Active Task**: Subtask
2.2 - Firebase Admin SDK and JWT middleware configuration **Next Priority**: Complete backend
authentication system, then proceed to database setup

### Package Dependencies

The shared package (`@singleclin/shared`) is now available to other packages via workspace
references:

- Web admin imports: `import { IUser, API_ENDPOINTS } from '@singleclin/shared'`
- Backend can reference shared types for consistency
- Mobile app can utilize shared constants and utilities

Use Task Master AI workflow for systematic development following the established task hierarchy and
dependencies.
