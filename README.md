# FreeLLMAPI Web

Personal web port of FreeLLMAPI: one OpenAI-compatible `/v1` endpoint in front of many free LLM providers,
with the dashboard (add provider key → models detected → fallback chain, playground, analytics).
Runs on **Vercel** (dashboard static + one serverless function) with **Supabase** Postgres.

## Deploy
1. Supabase: create project, run `supabase/0001_init.sql` in the SQL editor (see `supabase/README.md`).
2. GitHub: push this folder as a repo.
3. Vercel: import the repo. Env vars (see `.env.example`):
   - `DATABASE_URL`: Supabase *transaction pooler* string
   - `ENCRYPTION_KEY`: 64 hex chars (keep it; changing it makes stored API keys unreadable)
   - `SETUP_CODE`: any secret string; needed once to create the first dashboard account, and to reset a forgotten password
   - `CRON_SECRET`: any secret string; the daily cron routes refuse to run without it
4. Open the site → enter the `SETUP_CODE` and create your account → Keys page → pick a provider, paste its API key.
Your `/v1` key is shown on the Keys page.

## Local
`cp .env.example .env`, fill it, `npm install`, `npm run dev`.

## Notes
- The database layer is a SQLite→Postgres translator (`server/src/db/sql-translate.ts`) + async adapter (`pg.ts`).
- Single-user dashboard: the first account is created with `SETUP_CODE`, then you sign in with email + password.
- Vercel Hobby cron runs once a day (`/api/cron/health`); there is no 5-minute timer.
