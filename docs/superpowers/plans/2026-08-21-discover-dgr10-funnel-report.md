# Discover DGR-10 Funnel Reporting Plan

> Execute with Superpowers TDD, systematic debugging, and verification.

**Goal:** Add read-only, access-controlled Admin reporting for stored consented Discover funnel events: landing view → detail view → Telegram click → Audit/qualification CTA.

**Architecture:** Add `/api/admin/discover/funnel` with a bounded 1–90 day query and hard scan cap. The database select is restricted to `name`, `locale`, and `metadata`; no session IDs, user IDs, IPs, user agents, or event IDs are returned. Aggregate counts are presented on a standalone `/admin/discover/funnel` page to avoid coupling with concurrent Admin-shell/Discover-editor work. Counts are event counts, not claimed user conversion rates. If the scan cap is reached, the response/UI explicitly marks the report partial.

**Consent statement:** `trackEvent()` stores these events only after the client-side analytics consent check. The report must explicitly state that it covers only stored consented telemetry and is not a complete traffic census.

## Task 1 — API contract (TDD)
- [ ] Add integration tests proving Admin auth is required.
- [ ] Reject `days < 1` or `days > 90`.
- [ ] Query only relevant Discover names, `site=portfolio`, and the bounded date range.
- [ ] Select only `name`, `locale`, `metadata`; use `take=5001` for a 5000-event scan cap.
- [ ] Aggregate landing/detail/Telegram/Audit-or-qualification CTA event counts by FA/EN/unknown locale.
- [ ] Parse CTA metadata safely and count only `target=audit_readiness|qualification`.
- [ ] Return `truncated=true` if >5000 rows and aggregate only the bounded 5000 rows.
- [ ] Empty stored telemetry returns zeroed steps without synthetic metrics.

## Task 2 — Read-only Admin report UI
- [ ] Add bilingual FA/EN report copy with clear consent scope and “event counts, not conversion rates” disclosure.
- [ ] Add loading/error/empty/partial states.
- [ ] Add day-window selector limited to 7/30/90 days.
- [ ] Render totals and locale breakdown only; no raw event/session table.
- [ ] Add a back link to `/admin`.

## Task 3 — Component/browser verification
- [ ] Component tests cover FA/EN copy, empty state, partial warning, and no raw identifier rendering.
- [ ] Playwright authenticated Admin test covers `/admin/discover/funnel` on desktop/mobile and verifies no horizontal overflow.
- [ ] Full hosted gates must pass before marking implementation-ready.

## Safety boundaries
- Read-only API only; no POST/PATCH/DELETE.
- No schema/migration changes.
- No new analytics collection or consent behavior.
- No production data mutation.
- Do not merge/deploy without the repository production approval gate.
