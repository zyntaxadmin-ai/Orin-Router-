// Local dev server (npm run dev): same app as Vercel, but with app.listen.
import './env.js';
import { createApp } from './app.js';
import { loadConfig } from './lib/config.js';

const port = Number(process.env.PORT || 3001);
createApp({ ...loadConfig(), serveStaticAssets: false }).listen(port, () => console.log(`API on http://localhost:${port}`));
