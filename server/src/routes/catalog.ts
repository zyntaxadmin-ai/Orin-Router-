import { Router } from 'express';
import type { Request, Response } from 'express';
import { getSyncState, syncCatalog } from '../services/catalog-sync.js';

export const catalogRouter = Router();

/** GET /api/catalog — current catalog sync state. */
catalogRouter.get('/', async (_req: Request, res: Response) => {
  res.json(await getSyncState());
});

/** POST /api/catalog/sync — manual "check for catalog updates now". */
catalogRouter.post('/sync', async (_req: Request, res: Response) => {
  const sync = await syncCatalog(true);
  res.status(sync.ok ? 200 : 502).json({ catalog: await getSyncState(), sync });
});
