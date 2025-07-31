import {
  signInWithRedirect,
  getRedirectResult,
  GoogleAuthProvider,
  getIdToken,
} from 'firebase/auth';
import { auth } from '@/config/firebase';

// Auth providers
const googleProvider = new GoogleAuthProvider();

// Configure provider
googleProvider.setCustomParameters({
  prompt: 'select_account'
});

// Sign in with Google using redirect (avoids CORS issues)
export const signInWithGoogleRedirect = async (): Promise<void> => {
  await signInWithRedirect(auth, googleProvider);
};

// Get redirect result
export const getGoogleRedirectResult = async () => {
  try {
    const result = await getRedirectResult(auth);
    if (result) {
      const token = await getIdToken(result.user);
      return {
        user: result.user,
        token,
      };
    }
    return null;
  } catch (error: any) {
    console.error('Error getting redirect result:', error);
    throw error;
  }
};