# Guia de Configuração do Firebase - SingleClin

Este guia detalha o processo de configuração do Firebase para os projetos backend (.NET) e web-admin (React) do SingleClin.

## 📋 Pré-requisitos

- Conta no [Firebase Console](https://console.firebase.google.com)
- Node.js 18+ instalado
- .NET 9 SDK instalado
- Acesso de administrador ao projeto Firebase

## 🚀 Configuração Inicial do Firebase

### 1. Criar um Projeto no Firebase

1. Acesse o [Firebase Console](https://console.firebase.google.com)
2. Clique em "Adicionar projeto"
3. Nome do projeto: `singleclin-app` (ou outro de sua preferência)
4. Desative o Google Analytics (opcional)
5. Clique em "Criar projeto"

### 2. Ativar Authentication

1. No menu lateral, clique em "Authentication"
2. Clique em "Começar"
3. Na aba "Sign-in method", ative os provedores desejados:
   - **Email/Senha**: Ative para login tradicional
   - **Google**: Ative para login social
   - **Apple**: Ative para login com Apple (requer configuração adicional)

### 3. Configurar Domínios Autorizados

1. Em Authentication > Settings > Authorized domains
2. Adicione os domínios:
   - `localhost` (desenvolvimento)
   - Seu domínio de produção (ex: `app.singleclin.com`)

## 🔧 Configuração do Backend (.NET)

### 1. Obter Service Account Key

1. No Firebase Console, clique no ícone de engrenagem > "Configurações do projeto"
2. Vá para a aba "Contas de serviço"
3. Clique em "Gerar nova chave privada"
4. Salve o arquivo JSON em local seguro

### 2. Configurar o Backend

#### A. Estrutura de Arquivos

```
packages/backend/
├── Firebase/
│   └── serviceAccountKey.json  # NÃO COMMITAR!
├── appsettings.json
├── appsettings.Development.json
└── .gitignore
```

#### B. Adicionar ao .gitignore

```gitignore
# Firebase
Firebase/serviceAccountKey.json
serviceAccountKey.json
**/serviceAccountKey.json

# App settings locais
appsettings.Development.json
```

#### C. Configurar appsettings.json

```json
{
  "Firebase": {
    "ProjectId": "singleclin-app",
    "ServiceAccountKeyPath": "Firebase/serviceAccountKey.json"
  },
  "Authentication": {
    "Issuer": "https://securetoken.google.com/singleclin-app",
    "Audience": "singleclin-app",
    "TokenExpiration": "24:00:00"
  }
}
```

#### D. Configurar appsettings.Development.json (Desenvolvimento)

```json
{
  "Firebase": {
    "ProjectId": "singleclin-app",
    "ServiceAccountKeyPath": "Firebase/serviceAccountKey.json"
  }
}
```

#### E. Variáveis de Ambiente (Produção)

Para produção, use variáveis de ambiente em vez do arquivo JSON:

```bash
# Linux/Mac
export FIREBASE_PROJECT_ID="singleclin-app"
export FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
export FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxx@singleclin-app.iam.gserviceaccount.com"

# Windows
set FIREBASE_PROJECT_ID=singleclin-app
set FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...
set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@singleclin-app.iam.gserviceaccount.com
```

#### F. Configuração no Program.cs

O código já está configurado em `Extensions/FirebaseExtensions.cs`:

```csharp
// Program.cs
builder.Services.AddFirebaseAuthentication(builder.Configuration);
```

### 3. Testar a Configuração

```bash
cd packages/backend
dotnet run
```

Acesse: `https://localhost:5001/swagger`

## 🌐 Configuração do Web Admin (React)

### 1. Adicionar Aplicativo Web no Firebase

1. No Firebase Console, clique no ícone de engrenagem > "Configurações do projeto"
2. Na seção "Seus aplicativos", clique em "</>" (Web)
3. Registre o app:
   - Nome: "SingleClin Web Admin"
   - ✅ Configurar Firebase Hosting (opcional)
4. Copie a configuração fornecida

### 2. Instalar Dependências

```bash
cd packages/web-admin
npm install firebase
```

### 3. Criar Arquivo de Configuração

#### A. Criar `src/config/firebase.ts`

```typescript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
  storageBucket: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.REACT_APP_FIREBASE_APP_ID,
  measurementId: process.env.REACT_APP_FIREBASE_MEASUREMENT_ID
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

export default app;
```

#### B. Criar `.env.local` (Desenvolvimento)

```env
# Firebase Configuration
REACT_APP_FIREBASE_API_KEY=AIzaSyAdZpsqqHWwCDv-eOeE42JR2YnJAIY1ZKc
REACT_APP_FIREBASE_AUTH_DOMAIN=singleclin-app.firebaseapp.com
REACT_APP_FIREBASE_PROJECT_ID=singleclin-app
REACT_APP_FIREBASE_STORAGE_BUCKET=singleclin-app.firebasestorage.app
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=410494012909
REACT_APP_FIREBASE_APP_ID=1:410494012909:web:xxxxxxxxxxxxx
REACT_APP_FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX

# Backend API
REACT_APP_API_URL=http://localhost:5000
```

#### C. Adicionar ao .gitignore

```gitignore
# Environment files
.env.local
.env.development.local
.env.production.local
```

### 4. Configurar Context de Autenticação

#### A. Criar `src/contexts/AuthContext.tsx`

```typescript
import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  User,
  signInWithEmailAndPassword,
  signInWithPopup,
  GoogleAuthProvider,
  signOut,
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  updateProfile
} from 'firebase/auth';
import { auth } from '../config/firebase';
import { api } from '../services/api';

interface AuthContextType {
  currentUser: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, name: string) => Promise<void>;
  loginWithGoogle: () => Promise<void>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  getIdToken: () => Promise<string | null>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  // Sync user with backend
  const syncUserWithBackend = async (user: User) => {
    try {
      const token = await user.getIdToken();
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      
      await api.post('/auth/sync', {
        firebaseUid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified
      });
    } catch (error) {
      console.error('Error syncing user with backend:', error);
    }
  };

  // Login with email and password
  const login = async (email: string, password: string) => {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    await syncUserWithBackend(userCredential.user);
  };

  // Register new user
  const register = async (email: string, password: string, name: string) => {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    
    // Update display name
    await updateProfile(userCredential.user, {
      displayName: name
    });

    await syncUserWithBackend(userCredential.user);
  };

  // Login with Google
  const loginWithGoogle = async () => {
    const provider = new GoogleAuthProvider();
    const userCredential = await signInWithPopup(auth, provider);
    await syncUserWithBackend(userCredential.user);
  };

  // Logout
  const logout = async () => {
    await signOut(auth);
    delete api.defaults.headers.common['Authorization'];
  };

  // Reset password
  const resetPassword = async (email: string) => {
    await sendPasswordResetEmail(auth, email);
  };

  // Get current user's ID token
  const getIdToken = async (): Promise<string | null> => {
    if (!currentUser) return null;
    return await currentUser.getIdToken();
  };

  // Listen to auth state changes
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user);
      
      if (user) {
        // Set default authorization header
        const token = await user.getIdToken();
        api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      } else {
        delete api.defaults.headers.common['Authorization'];
      }
      
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const value = {
    currentUser,
    loading,
    login,
    register,
    loginWithGoogle,
    logout,
    resetPassword,
    getIdToken
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
```

### 5. Configurar Interceptador Axios

#### A. Criar `src/services/api.ts`

```typescript
import axios from 'axios';
import { auth } from '../config/firebase';

const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:5000',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  async (config) => {
    const user = auth.currentUser;
    if (user) {
      const token = await user.getIdToken();
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle token refresh
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const user = auth.currentUser;
        if (user) {
          const token = await user.getIdToken(true); // Force refresh
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return api(originalRequest);
        }
      } catch (refreshError) {
        // Redirect to login if token refresh fails
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

export { api };
```

### 6. Integrar no App Principal

#### A. Atualizar `src/App.tsx`

```typescript
import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { AppRoutes } from './routes';
import { ThemeProvider } from './contexts/ThemeContext';

function App() {
  return (
    <BrowserRouter>
      <ThemeProvider>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </ThemeProvider>
    </BrowserRouter>
  );
}

export default App;
```

## 🔒 Segurança e Boas Práticas

### 1. Variáveis de Ambiente

**Nunca commite credenciais!** Use variáveis de ambiente:

#### Backend (.NET)
- Desenvolvimento: `appsettings.Development.json` (gitignored)
- Produção: Variáveis de ambiente do sistema ou Azure Key Vault

#### Frontend (React)
- Desenvolvimento: `.env.local` (gitignored)
- Produção: Variáveis de ambiente do servidor de build

### 2. Regras de Segurança Firebase

Configure no Firebase Console > Firestore > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Apenas usuários autenticados podem ler/escrever
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. CORS Configuration

No backend, configure CORS para permitir o frontend:

```csharp
// Program.cs
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowWebAdmin",
        builder => builder
            .WithOrigins(
                "http://localhost:3000",
                "https://admin.singleclin.com"
            )
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials());
});
```

## 🧪 Testando a Integração

### 1. Backend

```bash
# Terminal 1 - Iniciar o backend
cd packages/backend
dotnet run

# Terminal 2 - Testar autenticação
curl -X POST https://localhost:5001/api/auth/sync \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"firebaseUid": "test123", "email": "test@example.com"}'
```

### 2. Frontend

```bash
# Iniciar o web admin
cd packages/web-admin
npm start

# Acessar http://localhost:3000
# Testar login com email/senha ou Google
```

## 📱 Configuração Adicional para Mobile

Para o app mobile Flutter, consulte o arquivo `packages/mobile/README.md` para instruções específicas de configuração do Firebase no iOS e Android.

## 🚨 Troubleshooting

### Problema: "No Firebase App has been created"
**Solução**: Certifique-se de que o Firebase está sendo inicializado antes de usar qualquer serviço.

### Problema: "Permission denied" no Firestore
**Solução**: Verifique as regras de segurança do Firestore e se o usuário está autenticado.

### Problema: Token JWT inválido no backend
**Solução**: Verifique se o `ProjectId` no appsettings.json corresponde ao ID do projeto no Firebase.

### Problema: CORS error no frontend
**Solução**: Adicione a origem do frontend na política CORS do backend.

## 🔗 Links Úteis

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Admin SDK (.NET)](https://firebase.google.com/docs/admin/setup)
- [Firebase Web SDK](https://firebase.google.com/docs/web/setup)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

---

**Importante**: Este guia assume que você está usando as credenciais de exemplo. Substitua todas as chaves e IDs pelos valores reais do seu projeto Firebase.