import postgres from 'postgres';
import { AsyncLocalStorage } from 'node:async_hooks';
import { toPg } from './sql-translate.js';
import type { Db, DbStatement, RunResult } from './types.js';

type Sql = postgres.Sql<any> | postgres.TransactionSql<any>;

// The transaction (if any) the current async call chain is running in.
const txStore = new AsyncLocalStorage<Sql>();

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v) && !Buffer.isBuffer(v) && !(v instanceof Date);
}

function normalize(v: unknown): unknown {
  if (v === undefined) return null;
  if (typeof v === 'boolean') return v ? 1 : 0;
  return v;
}

function bindParams(params: unknown[], names: string[]): unknown[] {
  if (names.length > 0 && params.length === 1 && isPlainObject(params[0])) {
    const obj = params[0];
    return names.map((n) => normalize(obj[n]));
  }
  const flat = params.length === 1 && Array.isArray(params[0]) ? (params[0] as unknown[]) : params;
  return flat.map(normalize);
}

export function createPgDb(url: string): Db {
  const local = /@(localhost|127\.0\.0\.1)[:/]/.test(url);
  const sql = postgres(url, {
    // Supabase's pooler (Supavisor, port 6543, transaction mode) does not support prepared statements.
    prepare: false,
    max: Number(process.env.PG_POOL_MAX || 3),
    idle_timeout: 20,
    connect_timeout: 15,
    ssl: local ? false : 'require',
    onnotice: () => {},
    types: {
      // COUNT()/SUM() come back as bigint/numeric; the app expects plain numbers.
      bigint: { to: 20, from: [20], parse: (x: string) => Number(x), serialize: (x: unknown) => String(x) },
      numeric: { to: 1700, from: [1700], parse: (x: string) => Number(x), serialize: (x: unknown) => String(x) },
    },
  });

  const conn = (): Sql => txStore.getStore() ?? sql;

  async function query(sqlite: string, params: unknown[]) {
    const t = toPg(sqlite);
    const rows = await conn().unsafe(t.text, bindParams(params, t.names) as any[]);
    return { rows: rows as unknown as Record<string, unknown>[], count: rows.count, returnsId: t.returnsId };
  }

  const db: Db = {
    prepare(sqlite: string): DbStatement {
      return {
        async get(...params) {
          const { rows } = await query(sqlite, params);
          return rows[0];
        },
        async all(...params) {
          const { rows } = await query(sqlite, params);
          return rows as unknown[];
        },
        async run(...params): Promise<RunResult> {
          const { rows, count, returnsId } = await query(sqlite, params);
          const out: RunResult = { changes: Number(count ?? 0) };
          if (returnsId && rows[0] && rows[0].id !== undefined) out.lastInsertRowid = Number(rows[0].id);
          return out;
        },
      };
    },
    async exec(raw: string) {
      await conn().unsafe(raw);
    },
    transaction(fn) {
      return (async (...args: any[]) => {
        const parent = txStore.getStore() as postgres.TransactionSql<any> | undefined;
        if (parent) {
          return parent.savepoint((sp) => txStore.run(sp, () => fn(...args))) as any;
        }
        return sql.begin((tx) => txStore.run(tx, () => fn(...args))) as any;
      }) as any;
    },
    pragma() {
      return undefined;
    },
    async close() {
      await sql.end({ timeout: 5 });
    },
  };
  return db;
}
