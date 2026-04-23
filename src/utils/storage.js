export const STORE_KEY = 'vnproject';
export const DTL_KEY = 'ember_dtl';
export const PROGRESS_KEY = 'ember_progress';

export function readStorage(key, fallback = null) {
  try {
    const value = localStorage.getItem(key);
    return value ?? fallback;
  } catch {
    return fallback;
  }
}

export function writeStorage(key, value) {
  try {
    localStorage.setItem(key, value);
    return true;
  } catch {
    return false;
  }
}
