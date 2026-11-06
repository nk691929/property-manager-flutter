# MVP 3: Favorites, inquiries and viewings

## Built
- Favorites: heart on cards and detail, "Saved" list, optimistic updates
- Agent name on listings (name only, never email or phone)
- Inquiries: conversation threads between a client and the listing's agent;
  inbox for both roles; close a conversation; one open thread per client and listing
- Viewings: the client proposes a date and time, the agent confirms or declines
  (with a reason), either side can cancel a confirmed viewing, the agent marks it
  completed after the time has passed; time window 1 hour to 90 days ahead
- DB: `favorites`, `inquiries`, `inquiry_messages`, `viewings`, `visible_names`,
  `create_inquiry` (`supabase/migrations/0004_engagement.sql`)

## Test plan
- Unit: permissions, rules (messages, viewings with an injected clock), the
  viewing state machine, all use cases (including outsiders, stale and finished states)
- Data: repository against the fakes, JSON parsing of embedded joins
- Widget: thread page, viewings page (agent confirm, client cancel)
- Provider: optimistic favorites (rollback of only its own change, double taps)
- Database: eleven SQL checks run in the Supabase SQL editor
- Manual: favorites, inquiry thread, viewing flow, offline failures, stale screens

## Known limitations
- No live updates or unread badges (planned with notifications in MVP 5)
- Thread messages are plain text: no attachments, edits or deletes
- Closed inquiries and finished viewings cannot be reopened (start a new one)
- Admins have database read access but no inquiry or viewing screens
- Agents don't see the client's contact details; all contact goes through threads
- Offset-free lists load the newest 50 inquiries and 100 viewings; no paging
- The fake backends do not emulate RLS or the guard triggers
- Viewing times are shown in the device's time zone with no time-zone label
- No reminders and no automatic expiry of unanswered requests
- iOS unverified (no Mac)