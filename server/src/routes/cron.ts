import { Router, type Request, type Response } from 'express';
import { checkAllKeys } from '../services/health.js';
import { getDb } from '../db/index.js';

export const cronRouter = Router();

// Vercel Cron (or any external pinger) hits this to run the key health pass that the
// desktop build ran on a timer. If CRON_SECRET is set, Vercel sends it as a Bearer token.
cronRouter.get('/health', async (req: Request, res: Response) => {
  const secret = process.env.CRON_SECRET;
  if (secret && req.headers.authorization !== `Bearer ${secret}`) {
    res.status(401).json({ error: { message: 'unauthorized' } });
    return;
  }
  try {
    await checkAllKeys();
    res.json({ ok: true });
  } catch (err: any) {
    res.status(500).json({ error: { message: String(err?.message ?? err) } });
  }
});

// GET /api/cron/dbping — measures the round trip from this function to the database.
// ~1-10 ms = same region, 100+ ms = the function and the database are far apart.
cronRouter.get('/dbping', async (_req: Request, res: Response) => {
  const db = getDb();
  const times: number[] = [];
  for (let i = 0; i < 6; i++) {
    const t0 = Date.now();
    await db.prepare(`SELECT ${i + 1} AS n`).run();
    times.push(Date.now() - t0);
  }
  res.json({ functionRegion: process.env.VERCEL_REGION ?? null, roundTripMs: times });
});

// GET /api/cron/dbstats — row counts only, to check that requests are being recorded.
cronRouter.get('/dbstats', async (_req: Request, res: Response) => {
  const db = getDb();
  const n = async (sql: string) => Number(((await db.prepare(sql).get()) as { n: number }).n);
  const last = (await db.prepare('SELECT MAX(created_at) AS t FROM requests').get()) as { t: string | null };
  res.json({
    requests: await n('SELECT COUNT(*) AS n FROM requests'),
    requestHourly: await n('SELECT COUNT(*) AS n FROM request_hourly'),
    requestAttempts: await n('SELECT COUNT(*) AS n FROM request_attempts'),
    lastRequestAt: last.t,
    serverTimeUtc: new Date().toISOString(),
  });
});
