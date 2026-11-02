# MVP 2: Properties and listings

## Built
- Listing lifecycle: draft → pending_review → published, plus rejected/archived
- Agents: create/edit drafts, submit, withdraw, unpublish, archive, restore, delete drafts
- Admins: review queue (approve / reject with reason), all listings, reassign, platform rule
- Everyone: browse published listings with search, filters, sort and paging; detail screen
- Admin-configurable rule: require approval for new listings (default on)
- DB: `properties`, `app_settings`, RLS, `guard_property_write` trigger
  (`supabase/migrations/0002_properties.sql`), dev seed (`supabase/seed/dev_properties.sql`)

## Test plan
- Unit: workflow table, validators, use cases (permissions, ownership, rules)
- Data: repository against the fake (filters, sorting, paging)
- Widget: browse page (published only, debounced search, empty state)
- Database: four SQL checks (client insert denied, agent self-publish denied,
  happy path, edit-lock) run in the Supabase SQL editor

## Known limitations
- No photos (2.1), maps or offline cache (2.2)
- Agent names are not shown to clients (needs a public agent directory, MVP 3)
- Reassignment does not verify the target is an agent at the database level
- Price is a `double` in Dart (display only); money handling is revisited in MVP 4
- Offset pagination can repeat or skip rows if data changes while scrolling
- Admins cannot edit listing content in the UI (only status and owner)
- "Load more" is a button, not infinite scroll
- Fake backend does not emulate RLS
- Cached settings can be stale until restart (use cases re-check on every action)
- iOS unverified (no Mac)