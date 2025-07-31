# Solução para Avisos de CORS do Firebase Auth

## Problema

O aviso "Cross-Origin-Opener-Policy policy would block the window.closed call" aparece ao usar `signInWithPopup` do Firebase Auth. Isso é um aviso (não um erro) que ocorre devido às políticas de segurança modernas dos navegadores.

## Solução Implementada

### 1. Usar Método de Redirect ao invés de Popup

Mudamos de `signInWithPopup` para `signInWithRedirect` que é mais confiável e evita problemas de CORS:

```typescript
// Ao invés de:
await signInWithPopup(auth, googleProvider)

// Usamos:
await signInWithRedirect(auth, googleProvider)
```

### 2. Tratamento do Resultado do Redirect

No `AuthContext`, verificamos o resultado do redirect quando a página carrega:

```typescript
const redirectResult = await getRedirectResult(auth)
if (redirectResult) {
  // Processar login bem-sucedido
}
```

### 3. Componente Dedicado para Login com Google

Criamos `GoogleLoginButton.tsx` que encapsula toda a lógica de login com Google.

## Como Funciona

1. Usuário clica em "Entrar com Google"
2. App redireciona para página de login do Google
3. Após autenticação, Google redireciona de volta para o app
4. App detecta o resultado e completa o login

## Vantagens

- ✅ Sem avisos de CORS
- ✅ Funciona em todos os navegadores
- ✅ Mais confiável que popups
- ✅ Melhor experiência mobile

## Desvantagens

- ❌ Recarrega a página (mas estado é preservado)
- ❌ Um pouco mais lento que popup

## Alternativas

Se preferir manter o popup apesar dos avisos:

1. Os avisos são apenas informativos e não afetam funcionalidade
2. Pode-se ignorar os avisos no console
3. Firebase está trabalhando em soluções futuras

## Configuração do Firebase Console

Certifique-se de ter configurado:

1. **Domínios Autorizados**:
   - `localhost`
   - `localhost:3000`
   - Seu domínio de produção

2. **URIs de Redirecionamento OAuth**:
   - `http://localhost:3000`
   - `https://seu-dominio.com`

## Debug

Para debug detalhado:

```javascript
import { setLogLevel } from 'firebase/app'
setLogLevel('debug')
```

## Referências

- [Firebase Auth Web Best Practices](https://firebase.google.com/docs/auth/web/redirect-best-practices)
- [Cross-Origin-Opener-Policy MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Opener-Policy)