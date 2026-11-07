# MVP 4: Leases, rent schedule and recorded payments

## Built
- Leases: an agent creates a lease for a client who has contacted them about a
  rental listing (an inquiry or a completed viewing); one active lease per listing
- Rent schedule: one charge per month, generated with the lease (due day 1 to 28,
  at most 36 months)
- Payments: the agent records rent received (cash, bank transfer, cheque, other,
  with a reference); partial payments allowed, overpaying blocked
- Voiding: a mistaken payment is voided with a reason and stays in the history
- Ending a lease: shows which future charges will be cancelled; charges with a
  payment stay
- Tenant view: read-only schedule, payments and voided lines
- Derived status: paid, partly paid, due, overdue, cancelled
- DB: `leases`, `rent_charges`, `rent_payments`, `create_lease`, `end_lease`, payment
  guard triggers (`0005_leases_and_rent.sql`), and a policy so a tenant keeps
  reading the listing after it is archived (`0006_lease_party_listing_access.sql`)

## Test plan
- Unit: Money, Calendar, schedule generation, lease and payment rules, derived
  charge status (moving clock), the ending preview, all use cases (permissions,
  stale and finished states, concurrency on the same balance)
- Data: JSON parsing of nested embeds (lease, charges, payments), fake backend
- Widget: lease detail (statuses, refusal for non-parties)
- Database: nine SQL checks (0005) and an archived-listing check (0006)
- Manual: create, record, partial, overpay, void, end, stale screen, offline

## Known limitations
- Record-only: no online payments, no receipts or PDFs
- No late fees, no deposit ledger (the deposit is stored as information only),
  no lease renewals or amendments
- A lease does not unpublish the listing; the agent archives it
- Admins have database read access but no lease screens
- No reminders for due or overdue rent (planned with notifications, MVP 5)
- Prices of listings are still `double` in the properties feature; leases use Money
- A payment dated "tomorrow" is accepted (one day of timezone tolerance)
- Tenants see the agent's name only while the listing exists (0006 keeps it readable)
- The fake backend does not emulate RLS or the SQL functions
- iOS unverified (no Mac)