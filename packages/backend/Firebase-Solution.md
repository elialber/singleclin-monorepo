# Solução Firebase - Criação de Usuários

## Problema
Ao registrar um novo usuário via `/api/Auth/register`, o usuário era criado no banco de dados local mas não no Firebase Authentication.

## Causa Raiz
1. Inicialização duplicada do Firebase em dois lugares diferentes
2. Chave de configuração inconsistente (`ServiceAccountPath` vs `ServiceAccountKeyPath`)
3. Falta de logs detalhados para debug

## Solução Implementada

### 1. Centralização da Inicialização
- Removida a inicialização do Firebase de `AuthenticationExtensions.cs`
- Criado `FirebaseInitializerService` como Hosted Service para inicializar Firebase no startup
- Firebase agora é inicializado uma única vez durante o startup da aplicação

### 2. Melhorias no FirebaseAuthService
- Reescrito completamente com melhor tratamento de erros
- Adicionados logs detalhados em todos os pontos críticos
- FirebaseAuth instance é criado e armazenado no construtor

### 3. Logs Detalhados no AuthService
- Adicionados logs específicos para rastrear a criação de usuários no Firebase
- Logs incluem status de configuração, tentativas e resultados

### 4. Endpoint de Teste
- Criado `FirebaseTestController` para testar isoladamente a funcionalidade
- Endpoints:
  - `GET /api/FirebaseTest/status` - Verifica se Firebase está configurado
  - `POST /api/FirebaseTest/test-create-user` - Testa criação direta de usuário

## Arquivos Modificados

1. **FirebaseInitializerService.cs** (novo)
   - Hosted service que inicializa Firebase no startup
   - Logs detalhados sobre a inicialização

2. **FirebaseAuthService.cs** (refatorado)
   - Inicialização simplificada
   - Melhor tratamento de erros
   - Logs mais detalhados

3. **AuthenticationExtensions.cs**
   - Removida inicialização do Firebase

4. **AuthService.cs**
   - Adicionados logs detalhados para debug

5. **Program.cs**
   - Registrado FirebaseInitializerService como Hosted Service

## Como Testar

1. Reinicie o servidor:
```bash
dotnet run
```

2. Verifique os logs de inicialização - deve aparecer:
```
=== Firebase Initializer Service Starting ===
✅ Firebase Admin SDK initialized successfully!
```

3. Teste o registro de usuário:
```bash
curl -X 'POST' \
  'https://localhost:5001/api/Auth/register' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "email": "test@example.com",
  "password": "Test123!",
  "fullName": "Test User",
  "role": "Patient"
}'
```

4. Verifique os logs - deve aparecer:
```
=== FIREBASE USER CREATION START ===
✅ SUCCESS: Created user in Firebase - Email: test@example.com, UID: xxxxx
```

5. Verifique no Firebase Console se o usuário foi criado

## Configuração Necessária

Certifique-se de que `appsettings.json` contenha:
```json
{
  "Firebase": {
    "ProjectId": "singleclin-app",
    "ServiceAccountKeyPath": "firebase-service-account.json"
  }
}
```

E que o arquivo `firebase-service-account.json` exista no diretório raiz do backend.