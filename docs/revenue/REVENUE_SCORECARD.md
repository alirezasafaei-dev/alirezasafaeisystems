# ASDEV Audit Revenue Scorecard

Status: source-of-truth contract for `alirezasafaeisystems#96`.

The weekly scorecard uses two real inputs:

- System data: `Lead`, `AnalyticsEvent`, and `FunnelConversion` from the portfolio database.
- Manual sales data: a private weekly JSON file shaped like `docs/revenue/weekly-scorecard.manual.example.json`.

Do not count commits, tests, automation cycles, or generic traffic as revenue progress.

## Reporting period

- `week_start` is an optional `YYYY-MM-DD` UTC date in the manual file.
- When provided, the reporting interval is `[week_start 00:00 UTC, +7 days)`.
- When omitted, the script uses the current UTC week from Monday 00:00 through the following Monday.
- The generated JSON always includes `reporting_period.start`, `end_exclusive`, `timezone`, and `source`.
- Database-backed `Lead`, `AnalyticsEvent`, and `FunnelConversion` queries are limited to the same reporting interval.
- Qualified prospects currently mean leads **created during the interval** that are currently marked `qualified`; the existing `Lead` model has no `qualifiedAt` timestamp, and the output states this limitation.

Manual input is intentionally strict:

- no file argument: report runs with `manual_input: NO_MANUAL_FILE`
- missing file: exits non-zero with `INVALID_MANUAL_INPUT / MANUAL_FILE_NOT_FOUND`
- malformed JSON: exits non-zero with `INVALID_MANUAL_INPUT / MALFORMED_JSON`
- schema-invalid JSON, invalid dates, or negative delivery durations: exits non-zero with `INVALID_MANUAL_INPUT / SCHEMA_INVALID`
- valid JSON: report runs with `manual_input: MANUAL_FILE_VALID`

## Metrics

| Metric | Source | Target |
|---|---|---:|
| qualified prospects | `Lead.status = qualified` within the reporting interval, plus approved manual prospect register | 50 |
| personalized outreach | private manual scorecard | 40 |
| positive responses | private manual scorecard | 8 |
| calls | private manual scorecard | 5 |
| proposals | private manual scorecard | 3 |
| won/lost | private manual scorecard until a dated sales-status model is approved | won >= 1 paid pilot |
| paid pilots | private manual scorecard until payment activation is approved | 1 |
| delivery time | AuditSystems `started_at` → `delivered_at` timestamp pairs when available; otherwise explicit `not_available` | < 72 hours |
| call-to-paid conversion | paid pilots / calls | >= 20% |
| lead source | weekly `Lead.source` and submitted UTM fields | report actual |
| product analytics | weekly `AnalyticsEvent.event` counts and `FunnelConversion` session/converted counts, reported separately from outreach | report actual |
| loss reason | manual field until schema expansion is approved | report actual |

## Weekly Report Format

Every weekly metric row must include:

- actual
- target
- variance
- blocker
- next action

Product analytics remain in their own block and are not substituted for manual outreach, calls, proposals, paid pilots, or revenue.

When data is unavailable, show `0` only for a known zero and `not_available` when evidence is missing. Never insert demo data into an operational scorecard.

## Dependency Order

1. AuditSystems PR #30 has merged; its production database migration and deployment remain separate owner-gated operations.
2. The AuditSystems qualification and sample-report destinations must be production-ready before production links are deployed from this repository.
3. Mother PR #97 may merge independently of deployment, but production publication remains explicitly gated.
4. External outreach, public pricing, payment activation, and production deployment require separate approval and are not performed by this scorecard workflow.
