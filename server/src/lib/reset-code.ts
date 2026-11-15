import crypto from 'crypto';

// Password-reset code for the serverless build.
//
// A random per-request code held in memory cannot work on Vercel (the next request may run
// on a different instance), so resetting a forgotten password uses the same secret you
// chose for first-run setup: the SETUP_CODE environment variable.

function configured(): string {
  return (process.env.SETUP_CODE ?? '').trim();
}

export function generateResetCode(_accountEmail?: string | null): string {
  return '';
}

export function getResetCode(): string | null {
  return configured() || null;
}

export function clearResetCode(): void {
  // Stateless: nothing to clear.
}

// Constant-time comparison against SETUP_CODE.
export function resetCodeMatches(provided: unknown): boolean {
  const expected = configured();
  if (!expected || typeof provided !== 'string') return false;
  const a = crypto.createHash('sha256').update(provided.trim()).digest();
  const b = crypto.createHash('sha256').update(expected).digest();
  return crypto.timingSafeEqual(a, b);
}
