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
import { getFirebaseErrorMessage, createAuthError } from '@/utils/authErrors';

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
    
    // Use standardized error messages
    throw createAuthError(error, 'email_login');
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
    // Use standardized error messages for Google login
    throw createAuthError(error, 'google_login');
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