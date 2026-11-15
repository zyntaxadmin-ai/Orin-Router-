import crypto from 'crypto';
import { createPgDb } from './pg.js';
import { initEncryptionKey, isEncryptionKeyInitialized, probeStoredSecrets } from '../lib/crypto.js';
import type { Db } from './types.js';

export type { Db } from './types.js';

let db: Db | null = null;
let ready: Promise<Db> | null = null;
let keyStoreDecryptable: boolean | null = null;

function databaseUrl(): string {
  const url = process.env.DATABASE_URL?.trim();
  if (!url) {
    throw new Error(
      'DATABASE_URL is not set. Use the Supabase pooled connection string ' +
      '(Project Settings → Database → Connection string → Transaction pooler, port 6543).',
    );
  }
  return url;
}

export function getDb(): Db {
  if (!db) db = createPgDb(databaseUrl());
  return db;
}

/** Connect (once per server instance), check the schema exists, make sure the unified API key exists. */
export function initDb(): Promise<Db> {
  if (!ready) {
    ready = (async () => {
      const d = getDb();
      const exists = (await d.prepare(
        "SELECT table_name AS name FROM information_schema.tables WHERE table_schema = current_schema() AND table_name = 'settings'",
      ).get()) as { name: string } | undefined;
      if (!exists) {
        throw new Error('Database is empty. Run supabase/0001_init.sql in the Supabase SQL editor first.');
      }
      if (!isEncryptionKeyInitialized()) initEncryptionKey();
      const key = await d.prepare("SELECT value FROM settings WHERE key = 'unified_api_key'").get();
      if (!key) {
        await d.prepare(
          "INSERT INTO settings (key, value) VALUES ('unified_api_key', ?) ON CONFLICT (key) DO NOTHING",
        ).run(`freellmapi-${crypto.randomBytes(24).toString('hex')}`);
      }
      keyStoreDecryptable = await probeStoredSecrets(d);
      if (keyStoreDecryptable === false) {
        console.error('[crypto] ENCRYPTION_KEY cannot decrypt the provider keys stored in this database. Use the key the keys were saved with.');
      }
      return d;
    })().catch((err) => {
      ready = null; // let the next request retry
      throw err;
    });
  }
  return ready;
}

export function isKeyStoreDecryptable(): boolean | null {
  return keyStoreDecryptable;
}

export async function getUnifiedApiKey(): Promise<string> {
  const row = (await getDb().prepare("SELECT value FROM settings WHERE key = 'unified_api_key'").get()) as { value: string };
  return row.value;
}

export async function regenerateUnifiedKey(): Promise<string> {
  const key = `freellmapi-${crypto.randomBytes(24).toString('hex')}`;
  await getDb().prepare("UPDATE settings SET value = ? WHERE key = 'unified_api_key'").run(key);
  return key;
}

export async function getSetting(key: string): Promise<string | undefined> {
  const row = (await getDb().prepare('SELECT value FROM settings WHERE key = ?').get(key)) as { value: string } | undefined;
  return row?.value;
}

export async function setSetting(key: string, value: string): Promise<void> {
  await getDb().prepare(`
    INSERT INTO settings (key, value) VALUES (?, ?)
    ON CONFLICT(key) DO UPDATE SET value = excluded.value
  `).run(key, value);
}
