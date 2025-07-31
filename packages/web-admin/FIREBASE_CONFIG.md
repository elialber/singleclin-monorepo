# Firebase Configuration for Web Admin

This document explains how Firebase is configured in the SingleClin Web Admin portal.

## Overview

The web-admin uses Firebase for:
- **Authentication**: Email/password and Google Sign-In
- **Token Management**: Firebase tokens are exchanged for backend JWT tokens
- **Future Features**: Firestore, Storage, and other Firebase services

## Configuration Files

### 1. Environment Variables (`.env`)
```bash
# Firebase Configuration
VITE_FIREBASE_API_KEY=AIzaSyAdZpsqqHWwCDv-eOeE42JR2YnJAIY1ZKc
VITE_FIREBASE_AUTH_DOMAIN=singleclin-app.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=singleclin-app
VITE_FIREBASE_STORAGE_BUCKET=singleclin-app.firebasestorage.app
VITE_FIREBASE_MESSAGING_SENDER_ID=410494012909
VITE_FIREBASE_APP_ID=1:410494012909:web:d982c5ac9cf95223d6ebe4
```

### 2. Firebase Service Account (for server-side operations)
- Location: `firebase-service-account.json`
- **IMPORTANT**: This file is ignored by git for security
- Used only for server-side operations (not in the web app)

## Authentication Flow

1. **User Login**:
   - User enters email/password or clicks "Login with Google"
   - Firebase authenticates the user and returns a Firebase token
   - Web app sends Firebase token to backend API
   - Backend validates Firebase token and returns JWT tokens
   - Web app stores JWT tokens for API requests

2. **Token Refresh**:
   - When JWT expires, app gets fresh Firebase token
   - Exchanges Firebase token for new JWT tokens

3. **Logout**:
   - Clears local JWT tokens
   - Signs out from Firebase

## File Structure

```
packages/web-admin/
├── src/
│   ├── config/
│   │   └── firebase.ts          # Firebase initialization
│   ├── services/
│   │   ├── firebaseAuth.ts      # Firebase auth service
│   │   └── auth.service.ts      # Updated to use Firebase
│   ├── contexts/
│   │   └── AuthContext.tsx      # Updated with Firebase integration
│   └── pages/
│       └── auth/
│           └── Login.tsx        # Updated with Google Sign-In
├── .env                         # Environment variables
├── .env.example                 # Example environment file
├── firebase-service-account.json # Service account (gitignored)
└── .gitignore                   # Updated to ignore Firebase files
```

## Security Considerations

1. **Service Account Security**:
   - Never commit `firebase-service-account.json` to git
   - Store securely in production environment
   - Use environment variables for CI/CD

2. **Client-Side Security**:
   - Firebase config is safe to expose (it's public)
   - Authentication still requires valid credentials
   - Backend validates all Firebase tokens

3. **Token Management**:
   - Firebase tokens are short-lived (1 hour)
   - Backend JWT tokens have their own expiration
   - Automatic token refresh handles expiration

## Development Setup

1. **Install Dependencies**:
   ```bash
   npm install firebase firebase-admin
   ```

2. **Configure Environment**:
   - Copy `.env.example` to `.env`
   - Update with your Firebase project values

3. **Firebase Console Setup**:
   - Enable Email/Password authentication
   - Enable Google authentication
   - Add authorized domains for OAuth

## Production Deployment

1. **Environment Variables**:
   - Set all `VITE_FIREBASE_*` variables in production
   - Use secure storage for service account JSON

2. **Authorized Domains**:
   - Add production domain to Firebase Console
   - Update OAuth redirect URIs

3. **Security Rules**:
   - Configure Firestore/Storage rules if used
   - Enable App Check for additional security

## Troubleshooting

### Common Issues

1. **"Firebase app not initialized"**:
   - Check if `firebase.ts` is imported in `main.tsx`
   - Verify environment variables are loaded

2. **Google Sign-In not working**:
   - Check authorized domains in Firebase Console
   - Verify OAuth client configuration

3. **Token validation errors**:
   - Ensure backend has correct Firebase project ID
   - Check service account permissions

### Debug Mode

To enable Firebase debug logging:
```javascript
// In firebase.ts
import { setLogLevel } from 'firebase/app'
setLogLevel('debug')
```

## Next Steps

- [ ] Implement password reset functionality
- [ ] Add social login providers (Apple, Facebook)
- [ ] Enable Firebase Analytics
- [ ] Implement Firestore for real-time data
- [ ] Add Firebase Storage for file uploads