// Applies supabase/0001_init.sql to the database in DATABASE_URL (alternative to pasting it
// into the Supabase SQL editor). Usage: DATABASE_URL=... npm run db:init -w server
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import postgres from 'postgres';

const url = process.env.DATABASE_URL;
if (!url) { console.error('DATABASE_URL is not set'); process.exit(1); }
const file = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../supabase/0001_init.sql');
const sql = postgres(url, { prepare: false, max: 1, ssl: 'require', onnotice: () => {} });
try {
  await sql.unsafe(fs.readFileSync(file, 'utf8'));
  console.log('Schema applied.');
} finally {
  await sql.end();
}
