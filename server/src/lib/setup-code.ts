import crypto from 'crypto';

// First-run setup code for the serverless build.
//
// POST /api/auth/setup creates the first (and only) account while there are zero users.
// A random per-boot code cannot work on Vercel (every invocation may be a fresh instance
// and there is no console to read it from), so the code is simply the SETUP_CODE
// environment variable. If it is not set, nobody can create the account.

function configured(): string {
  return (process.env.SETUP_CODE ?? '').trim();
}

export function generateSetupCode(): string {
  return '';
}

export function getSetupCode(): string | null {
  return configured() || null;
}

export function clearSetupCode(): void {
  // Nothing to clear: setup is closed as soon as a user exists (see routes/auth.ts).
}

// Constant-time comparison against SETUP_CODE.
export function setupCodeMatches(provided: unknown): boolean {
  const expected = configured();
  if (!expected || typeof provided !== 'string') return false;
  const a = crypto.createHash('sha256').update(provided.trim()).digest();
  const b = crypto.createHash('sha256').update(expected).digest();
  return crypto.timingSafeEqual(a, b);
}
