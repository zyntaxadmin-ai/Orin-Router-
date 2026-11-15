// Vercel serverless entry: the whole Express app behind one function.
import { createApp } from '../server/dist/app.js';
import { loadConfig } from '../server/dist/lib/config.js';

const app = createApp({ ...loadConfig(), serveStaticAssets: false });
export default app;
