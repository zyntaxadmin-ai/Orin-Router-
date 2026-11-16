import postgres from 'postgres';
import { AsyncLocalStorage } from 'node:async_hooks';
import { toPg } from './sql-translate.js';
import type { Db, DbStatement, RunResult } from './types.js';

type Sql = postgres.Sql<any> | postgres.TransactionSql<any>;

// The transaction (if any) the current async call chain is running in.
const txStore = new AsyncLocalStorage<Sql>();

/** Per-request DB counters (only populated when the app wraps a request in statsStore.run). */
// In-flight query tracking: lets the app hold the serverless function open after the HTTP
// response is sent until the request's trailing bookkeeping (usage counters, request log) is done.
let dbInflight = 0;
let dbLastActivity = Date.now();

/** Resolves once no query has been running for `quietMs` (or after `maxMs` at the latest). */
export function waitForDbIdle(quietMs = 1200, maxMs = 20000): Promise<void> {
  const deadline = Date.now() + maxMs;
  return new Promise((resolve) => {
    const tick = () => {
      if (Date.now() >= deadline || (dbInflight === 0 && Date.now() - dbLastActivity >= quietMs)) return resolve();
      setTimeout(tick, 150);
    };
    tick();
  });
}

export const statsStore = new AsyncLocalStorage<{ queries: number; dbMs: number }>();

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
    max: Number(process.env.PG_POOL_MAX || 10),
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

  const DEBUG = process.env.DB_DEBUG === '1';

  async function query(sqlite: string, params: unknown[]) {
    const t = toPg(sqlite);
    const started = Date.now();
    dbInflight++;
    let rows;
    try {
      rows = await conn().unsafe(t.text, bindParams(params, t.names) as any[]);
    } finally {
      dbInflight--;
      dbLastActivity = Date.now();
    }
    const st = statsStore.getStore();
    if (st) { st.queries++; st.dbMs += Date.now() - started; }
    if (DEBUG && Date.now() - started > 300) console.warn(`[db] slow query ${Date.now() - started}ms: ${t.text.replace(/\s+/g, ' ').slice(0, 140)}`);
    return { rows: rows as unknown as Record<string, unknown>[], count: rows.count, returnsId: t.returnsId };
  }

  // Short read cache. The app was written for an in-process SQLite file where re-reading a
  // setting or a usage row 100 times per request was free; over the network each read costs a
  // round trip. Identical SELECTs within READ_TTL_MS (and identical ones already in flight)
  // share one result. Any write through this handle clears the cache, and reads inside a
  // transaction bypass it so they see their own writes.
  const READ_TTL_MS = Number(process.env.DB_READ_CACHE_MS ?? 2000);
  const readCache = new Map<string, { at: number; p: Promise<Record<string, unknown>[]> }>();
  const cacheable = (text: string) => /^\s*(WITH|SELECT)\b/i.test(text) && !/\b(random\(\)|for\s+update|nextval|pg_advisory)/i.test(text);

  async function read(sqlite: string, params: unknown[]): Promise<Record<string, unknown>[]> {
    const t = toPg(sqlite);
    if (READ_TTL_MS <= 0 || txStore.getStore() || !cacheable(t.text)) {
      return (await query(sqlite, params)).rows;
    }
    const key = t.text + '\u0000' + JSON.stringify(bindParams(params, t.names), (_k, v) => (typeof v === 'bigint' ? String(v) : v));
    const now = Date.now();
    const hit = readCache.get(key);
    let p: Promise<Record<string, unknown>[]>;
    if (hit && now - hit.at < READ_TTL_MS) {
      p = hit.p;
    } else {
      if (readCache.size > 500) {
        for (const [k, v] of readCache) if (now - v.at >= READ_TTL_MS) readCache.delete(k);
        if (readCache.size > 500) readCache.clear();
      }
      p = query(sqlite, params).then((r) => r.rows);
      readCache.set(key, { at: now, p });
      p.catch(() => { if (readCache.get(key)?.p === p) readCache.delete(key); });
    }
    const rows = await p;
    // Callers sort/mutate result rows in place; hand each caller its own copy.
    return rows.map((r) => ({ ...r }));
  }

  const db: Db = {
    prepare(sqlite: string): DbStatement {
      return {
        async get(...params) {
          const rows = await read(sqlite, params);
          return rows[0];
        },
        async all(...params) {
          return (await read(sqlite, params)) as unknown[];
        },
        async run(...params): Promise<RunResult> {
          readCache.clear();
          const { rows, count, returnsId } = await query(sqlite, params);
          const out: RunResult = { changes: Number(count ?? 0) };
          if (returnsId && rows[0] && rows[0].id !== undefined) out.lastInsertRowid = Number(rows[0].id);
          return out;
        },
      };
    },
    async exec(raw: string) {
      readCache.clear();
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
