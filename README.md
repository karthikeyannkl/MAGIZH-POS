# MAGIZH POS — Android PWA foundation

This is the starting source project for the mobile-only MAGIZH POS Progressive Web App.

## Current status

This package contains:
- React + TypeScript + Vite application shell
- Emerald / forest green / dark orange mobile design foundation
- PWA manifest and service-worker configuration
- Responsive Android-first navigation shell
- Supabase client bootstrap using public environment variables
- Initial multi-tenant PostgreSQL schema and RLS read-policy foundation

It does **not** yet contain production billing, real payment confirmation, stock deduction, refunds, complete role permissions, or live business data. The preview dashboard intentionally displays dashes rather than fabricated sales figures.

## Requirements

- Node.js 20+
- A new Supabase project (create staging first)
- Git repository for source ownership

## Run locally

```bash
npm install
cp .env.example .env.local
npm run dev
```

Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `.env.local` only after creating the Supabase project.

Never put the Supabase service-role key or database password in frontend environment variables.

## Database

Review `supabase/migrations/001_initial_schema.sql` before applying it to a new Supabase project. It is an initial schema foundation, not the final 43-section database implementation. Complete write operations must use validated server-side workflows / RPC or Edge Functions, with explicit role and branch permissions.

## PWA install

Deploy over HTTPS. On Android Chrome, open the deployed URL, use the browser menu, then choose **Install app** or **Add to Home screen** (wording varies by Chrome version).

## Next implementation stages

1. Complete schema and authorization matrix.
2. Supabase Auth onboarding and business/branch setup.
3. Product and category management.
4. POS cart and server-side bill finalization.
5. Manual payment confirmation and idempotency.
6. Stock ledger, receipts, reporting, and the remaining blueprint modules.

Do not use this starter as a live POS until the production acceptance tests in the master blueprint pass.
