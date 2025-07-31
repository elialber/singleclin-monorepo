import {
  signInWithEmailAndPassword,
  signInWithPopup,
  GoogleAuthProvider,
  signOut,
  onAuthStateChanged,
  User,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  updateProfile,
  getIdToken,
} from 'firebase/auth';
import { auth } from '@/config/firebase';
import { IUser } from '@singleclin/shared';

// Auth providers
const googleProvider = new GoogleAuthProvider();

export interface FirebaseAuthResult {
  user: User;
  token: string;
}

// Sign in with email and password
export const signInWithEmail = async (
  email: string,
  password: string
): Promise<FirebaseAuthResult> => {
  try {
    console.log('Attempting Firebase authentication for:', email);
    const result = await signInWithEmailAndPassword(auth, email, password);
    console.log('Firebase authentication successful, getting ID token...');
    const token = await getIdToken(result.user);
    console.log('ID token obtained successfully');
    return { user: result.user, token };
  } catch (error: any) {
    console.error('Firebase authentication error:', {
      code: error.code,
      message: error.message,
      email,
      customData: error.customData,
    });
    
    // Provide better error messages
    if (error.code === 'auth/invalid-credential') {
      throw new Error('Email ou senha incorretos. Verifique suas credenciais.');
    } else if (error.code === 'auth/user-not-found') {
      throw new Error('Usuário não encontrado. Verifique o email digitado.');
    } else if (error.code === 'auth/wrong-password') {
      throw new Error('Senha incorreta. Tente novamente.');
    } else if (error.code === 'auth/too-many-requests') {
      throw new Error('Muitas tentativas de login. Tente novamente mais tarde.');
    }
    
    throw error;
  }
};

// Sign in with Google
export const signInWithGoogle = async (): Promise<FirebaseAuthResult> => {
  try {
    // Configure provider with additional scopes if needed
    googleProvider.setCustomParameters({
      prompt: 'select_account'
    });
    
    const result = await signInWithPopup(auth, googleProvider);
    const token = await getIdToken(result.user);
    return { user: result.user, token };
  } catch (error: any) {
    // Handle specific Firebase auth errors
    if (error.code === 'auth/popup-blocked') {
      throw new Error('Por favor, permita popups para fazer login com Google');
    } else if (error.code === 'auth/cancelled-popup-request') {
      throw new Error('Login cancelado');
    } else if (error.code === 'auth/popup-closed-by-user') {
      throw new Error('Janela de login fechada');
    }
    throw error;
  }
};

// Create new user with email and password
export const createUser = async (
  email: string,
  password: string,
  displayName: string
): Promise<FirebaseAuthResult> => {
  const result = await createUserWithEmailAndPassword(auth, email, password);
  
  // Update user profile with display name
  if (displayName) {
    await updateProfile(result.user, { displayName });
  }
  
  const token = await getIdToken(result.user);
  return { user: result.user, token };
};

// Sign out
export const logOut = async (): Promise<void> => {
  await signOut(auth);
};

// Send password reset email
export const resetPassword = async (email: string): Promise<void> => {
  await sendPasswordResetEmail(auth, email);
};

// Get current user token
export const getCurrentUserToken = async (): Promise<string | null> => {
  const user = auth.currentUser;
  if (!user) return null;
  return getIdToken(user);
};

// Auth state observer
export const onAuthStateChange = (
  callback: (user: User | null) => void
): (() => void) => {
  return onAuthStateChanged(auth, callback);
};

// Convert Firebase User to SingleClin IUser format
export const convertFirebaseUserToIUser = async (
  firebaseUser: User
): Promise<Partial<IUser>> => {
  const token = await getIdToken(firebaseUser);
  
  // Parse custom claims from token if available
  const idTokenResult = await firebaseUser.getIdTokenResult();
  const claims = idTokenResult.claims;
  
  return {
    email: firebaseUser.email || '',
    displayName: firebaseUser.displayName || '',
    photoURL: firebaseUser.photoURL || undefined,
    role: claims.role || 'patient',
    // Additional fields will be populated from backend
  };
};

// Check if user is authenticated
export const isAuthenticated = (): boolean => {
  return !!auth.currentUser;
};

// Get current user
export const getCurrentUser = (): User | null => {
  return auth.currentUser;
};