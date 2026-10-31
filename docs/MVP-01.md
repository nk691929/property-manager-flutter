# MVP 1: Authentication and role-based navigation

## Built
- Email/password sign-in and registration (Supabase), session restore, sign-out
- Roles (admin/agent/client) mapped to permissions; guards in router and use cases
- Role home shells; admin user list with role change
- Database: profiles table, RLS, role-escalation guard trigger, client-only
  sign-up trigger (`supabase/migrations/0001_profiles_and_roles.sql`)
- Seeded in-memory fake backend for dev and tests

## How to use
See the README (Backend). Sign in and you land on your role's home. With no
backend config, use admin@/agent@/client@example.com with `Password1`.

## Test plan
43 passing tests:
- Unit: roles/permissions, validators, use cases (including forbidden paths),
  repository (against the fake), redirect table
- Widget: login page (validation, wrong credentials)
- Integration (planned, MVP 2): login → role home → sign out against the fake

## Known limitations
- Google sign-in deferred to MVP 1.1
- No password reset or email-verification deep links
- A failed profile fetch (e.g. offline at launch) looks signed-out
- Role changes apply at next session start, not live
- Deep links requested while loading are not preserved after login
- No confirm dialog before changing a role
- Fake backend: the admin-users list is independent of fake auth state
- iOS unverified (no Mac)
