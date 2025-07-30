# Firebase Configuration Setup

Este arquivo contém as instruções para configurar o Firebase no projeto SingleClin App.

## 1. Configuração do Firebase Console

### Pré-requisitos
1. Ter uma conta Google
2. Acessar o [Firebase Console](https://console.firebase.google.com/)
3. Criar um projeto chamado `singleclin-app`

### Configuração do Projeto
1. No Firebase Console, clique em "Adicionar projeto"
2. Nome do projeto: `SingleClin App`
3. ID do projeto: `singleclin-app`
4. Habilite o Google Analytics (opcional)

## 2. Configuração Android

### Adicionar App Android
1. No console do Firebase, clique em "Adicionar app" > Android
2. Package name: `br.com.singleclin.singleclin_app`
3. App nickname: `SingleClin Android`
4. SHA-1: Obter com o comando:
   ```bash
   cd android && ./gradlew signingReport
   ```

### Baixar Arquivo de Configuração
1. Baixe o arquivo `google-services.json`
2. Copie para: `android/app/google-services.json`
3. **IMPORTANTE**: Não commite este arquivo no git (já está no .gitignore)

### Verificar build.gradle
O arquivo `android/app/build.gradle.kts` deve ter:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## 3. Configuração iOS

### Adicionar App iOS
1. No console do Firebase, clique em "Adicionar app" > iOS
2. Bundle ID: `br.com.singleclin.singleclinApp`
3. App nickname: `SingleClin iOS`

### Baixar Arquivo de Configuração
1. Baixe o arquivo `GoogleService-Info.plist`
2. Copie para: `ios/Runner/GoogleService-Info.plist`
3. **IMPORTANTE**: Não commite este arquivo no git (já está no .gitignore)

### Atualizar Info.plist
No arquivo `ios/Runner/Info.plist`, substitua:
- `YOUR_REVERSED_CLIENT_ID` pelo valor do campo `REVERSED_CLIENT_ID` do GoogleService-Info.plist

## 4. Habilitar Métodos de Autenticação

No Firebase Console > Authentication > Sign-in method, habilite:

### Email/Password
1. Clique em "Email/Password"
2. Habilite "Email/Password"
3. Habilite "Email link (passwordless sign-in)" se desejado

### Google Sign-In
1. Clique em "Google"
2. Habilite
3. Configure o email de suporte do projeto
4. Adicione os SHA-1 certificates (Android)

### Apple Sign-In (iOS)
1. Clique em "Apple"
2. Habilite
3. Configure os valores necessários:
   - Team ID (encontre no Apple Developer)
   - Key ID (da chave de autenticação)
   - Private Key (.p8 file)

## 5. Configurar Regras do Firestore (se usar)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read for plans
    match /plans/{document} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.token.role == 'admin';
    }
  }
}
```

## 6. Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto Flutter com:
```env
FIREBASE_WEB_API_KEY=your_web_api_key
FIREBASE_PROJECT_ID=singleclin-app
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

## 7. Teste da Configuração

Execute o projeto e verifique se:
1. O Firebase inicializa sem erros
2. A autenticação funciona
3. Os logs mostram conexão bem-sucedida

```bash
flutter run
```

## Troubleshooting

### Erro: "No Firebase App"
- Verifique se `Firebase.initializeApp()` está sendo chamado no main.dart
- Verifique se os arquivos de configuração estão no lugar correto

### Erro: Google Sign In
- Verifique o SHA-1 no Firebase Console
- Verifique se o package name está correto
- Verifique se o GoogleService-Info.plist está configurado corretamente

### Erro: Apple Sign In
- Verifique se está testando em device físico (não funciona no simulador para produção)
- Verifique as configurações no Apple Developer Console