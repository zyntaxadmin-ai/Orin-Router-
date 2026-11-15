import crypto from 'crypto';
import type { Db } from '../db/types.js';

const ALGORITHM = 'aes-256-gcm';

let cachedKey: Buffer | null = null;

/**
 * AES-256-GCM uses a 32-byte key, hex-encoded as 64 chars.
 * A typo'd ENCRYPTION_KEY (e.g. "abc") would historically fall through
 * the placeholder check, get truncated to 1.5 bytes, and only fail at
 * the first encrypt() call with a cryptic node:crypto error. Validate
 * the length up front and fail fast with an actionable message.
 */
const KEY_BYTES = 32;
const KEY_HEX_LEN = KEY_BYTES * 2;
const PLACEHOLDER_KEY = 'your-64-char-hex-key-here';

// The dev-fallback key lives in a file next to the DB, NOT in the DB itself.
// Storing it beside the ciphertext it protects (the old `settings` row) meant
// encryption-at-rest protected nothing for a default install: whoever copied
// the DB also copied the key. The file sits in the same directory but is a
// separate artifact, and is chmod 0600 so it isn't world-readable.
const KEY_FILE_NAME = '.encryption-key';

function parseHexKey(value: string, source: 'env' | 'db' | 'file'): Buffer {
  if (value.length !== KEY_HEX_LEN || !/^[0-9a-fA-F]+$/.test(value)) {
    throw new Error(
      `Invalid ENCRYPTION_KEY (${source}): expected ${KEY_HEX_LEN} hex chars (32 bytes), got ${value.length} chars. ` +
      `Generate one with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`,
    );
  }
  return Buffer.from(value, 'hex');
}

// Outside production we auto-generate and persist a key so a fresh clone
// (`npm run dev`) boots without manual setup — the placeholder ENCRYPTION_KEY
// in .env.example would otherwise crash the server on boot, which surfaces in
// the client as "Can't reach the server". Production still requires an explicit
// env key: a generated key lives only on the local disk and silently losing it
// would make every stored API key undecryptable.
function isDevFallbackAllowed(): boolean {
  return process.env.NODE_ENV !== 'production';
}

function missingKeyError(): Error {
  return new Error(
    'ENCRYPTION_KEY is required in production for API key encryption. ' +
    `Set a ${KEY_HEX_LEN}-char hex key (generate one with: ` +
    `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"). ` +
    'Outside production a local key file is auto-generated next to the database.',
  );
}

/**
 * Initialize the encryption key from the ENCRYPTION_KEY env var (64 hex chars).
 * On Vercel there is no writable disk, so the env var is the only source.
 */
export function initEncryptionKey(_db?: unknown): void {
  const envKey = process.env.ENCRYPTION_KEY;
  if (envKey && envKey !== PLACEHOLDER_KEY) {
    cachedKey = parseHexKey(envKey, 'env');
    return;
  }
  throw missingKeyError();
}

function getEncryptionKey(): Buffer {
  if (!cachedKey) {
    throw new Error('Encryption key not initialized. Call initEncryptionKey() first.');
  }
  return cachedKey;
}

/**
 * A short, non-reversible identifier for the key currently in use.
 *
 * Database dumps record it in their header so a restore can tell, before it
 * touches a row, whether the api_keys ciphertext in the file was written under
 * this key. sha256 truncated to 64 bits: enough to catch a different key,
 * nowhere near enough to help recover the key itself, and safe to show in an
 * error message or write to a file an operator emails around.
 *
 * Returns null before initEncryptionKey() has run.
 */
export function encryptionKeyFingerprint(): string | null {
  if (!cachedKey) return null;
  return `sha256:${crypto.createHash('sha256').update(cachedKey).digest('hex').slice(0, 16)}`;
}

export function isEncryptionKeyInitialized(): boolean {
  return cachedKey !== null;
}

export function encrypt(text: string): { encrypted: string; iv: string; authTag: string } {
  const key = getEncryptionKey();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');

  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag,
  };
}

// AUTH_TAG_BYTES pins the GCM tag length to 16 bytes. Without this option Node
// will accept any tag of length 4–16 bytes (RFC 5116 §3.2), which lets anyone
// who can rewrite a row in `api_keys` swap in a 4-byte tag and start brute-
// forcing forgeries at 2^32 attempts. Pinning closes that truncation path.
const AUTH_TAG_BYTES = 16;

export function decrypt(encrypted: string, iv: string, authTag: string): string {
  const key = getEncryptionKey();
  const decipher = crypto.createDecipheriv(ALGORITHM, key, Buffer.from(iv, 'hex'), { authTagLength: AUTH_TAG_BYTES });
  decipher.setAuthTag(Buffer.from(authTag, 'hex'));

  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

/**
 * Whether the loaded key can open the secrets already stored in this database.
 *
 * A key file that exists but no longer matches the ciphertext is a silent
 * disaster: every `api_keys` row fails GCM authentication, so the health checks
 * report one platform at a time as broken with "Unsupported state or unable to
 * authenticate data", and the router ends up with no usable key. Nothing in that
 * output says the key file is the problem. Probing one row at boot turns the
 * whole class into a single accurate diagnosis.
 *
 * The mismatch is easy to reach: appdata is portable, so copying a database
 * between installs while keeping the older `.encryption-key` (or restoring from
 * a backup that carries its own) produces exactly this state.
 *
 * Returns null when there is nothing to check: no key init yet, no `api_keys`
 * table, or no stored secret.
 */
export async function probeStoredSecrets(db: Db): Promise<boolean | null> {
  let row: { encrypted: string; iv: string; auth_tag: string } | undefined;
  try {
    row = (await db.prepare(
      'SELECT encrypted_key AS encrypted, iv, auth_tag FROM api_keys WHERE length(encrypted_key) > 0 LIMIT 1',
    ).get()) as typeof row;
  } catch {
    return null;
  }
  if (!row) return null;
  try {
    decrypt(row.encrypted, row.iv, row.auth_tag);
    return true;
  } catch {
    return false;
  }
}

// A masked key is display-only — it feeds the `maskedKey` field every key,
// media, embedding and client-profile route hands to the dashboard — so it must
// never be enough to reconstruct the secret. The old short-key branch was
// `'****' + key.slice(-4)`, and slice(-4) keeps the last four characters no
// matter how short the input is: a 4-character key was echoed back IN FULL, and
// a 5-character key gave away 4 of its 5 characters. Short keys are not
// hypothetical — proxy credentials, self-hosted Ollama tokens and local dev
// keys all land here.
//
// So reveal nothing at all below 5 characters, and at most the last TWO up to
// 8: enough tail to tell two rows apart in the UI, not enough to be a
// meaningful share of the secret. Long keys keep the familiar prefix+suffix
// form, where 8 revealed characters out of 20+ is a fixed, small fraction.
export function maskKey(key: string): string {
  if (key.length < 5) return '****';
  if (key.length <= 8) return '****' + key.slice(-2);
  return key.slice(0, 4) + '...' + key.slice(-4);
}
