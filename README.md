# FreeLLMAPI Web

Personal web port of FreeLLMAPI: one OpenAI-compatible `/v1` endpoint in front of many free LLM providers,
with the dashboard (add provider key → models detected → fallback chain, playground, analytics).
Runs on **Vercel** (dashboard static + one serverless function) with **Supabase** Postgres.

## Deploy
1. Supabase: create project, run `supabase/0001_init.sql` in the SQL editor (see `supabase/README.md`).
2. GitHub: push this folder as a repo.
3. Vercel: import the repo. Env vars: `DATABASE_URL` (Supabase *transaction pooler* string) and `ENCRYPTION_KEY` (64 hex chars). Optional: `CRON_SECRET`.
4. Open the site → Keys page → pick a provider, paste its API key.
Your `/v1` key is shown on the Keys page.

## Local
`cp .env.example .env`, fill it, `npm install`, `npm run dev`.

## Notes
- The database layer is a SQLite→Postgres translator (`server/src/db/sql-translate.ts`) + async adapter (`pg.ts`).
- No dashboard login in this build (single user).
- Vercel Hobby cron runs once a day (`/api/cron/health`); there is no 5-minute timer.
