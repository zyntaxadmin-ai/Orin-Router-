# Supabase setup

1. Create a project at supabase.com.
2. Open **SQL Editor**, paste the whole of `0001_init.sql`, run it (once).
   (or: `DATABASE_URL=... npm run db:init -w server`)
3. Copy the **Transaction pooler** connection string into the `DATABASE_URL` env var (Vercel + local `.env`).
4. Generate `ENCRYPTION_KEY` (see `.env.example`) and set it in Vercel as well. Keep it: changing it makes stored API keys unreadable.
