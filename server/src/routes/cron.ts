import { Router, type Request, type Response } from 'express';
import { checkAllKeys } from '../services/health.js';

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
