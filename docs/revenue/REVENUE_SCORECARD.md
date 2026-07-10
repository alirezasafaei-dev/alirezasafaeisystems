# ASDEV Audit Revenue Scorecard

Status: source-of-truth contract for `alirezasafaeisystems#96`.

The weekly scorecard uses two real inputs:

- System data: `Lead`, `AnalyticsEvent`, and `FunnelConversion` from the portfolio database.
- Manual sales data: a private weekly JSON file shaped like `docs/revenue/weekly-scorecard.manual.example.json`.

Do not count commits, tests, automation cycles, or generic traffic as revenue progress.

Manual input is intentionally strict:

- no file argument: report runs with `manual_input: NO_MANUAL_FILE`
- missing file: exits non-zero with `INVALID_MANUAL_INPUT / MANUAL_FILE_NOT_FOUND`
- malformed JSON: exits non-zero with `INVALID_MANUAL_INPUT / MALFORMED_JSON`
- schema-invalid JSON: exits non-zero with `INVALID_MANUAL_INPUT / SCHEMA_INVALID`
- valid JSON: report runs with `manual_input: MANUAL_FILE_VALID`

## Metrics

| Metric | Source | Target |
|---|---|---:|
| qualified prospects | `Lead.status = qualified` plus approved manual prospect register | 50 |
| personalized outreach | private manual scorecard | 40 |
| positive responses | private manual scorecard | 8 |
| calls | private manual scorecard | 5 |
| proposals | private manual scorecard | 3 |
| won/lost | `Lead.status` plus private manual scorecard | won >= 1 paid pilot |
| paid pilots | private manual scorecard until payment activation is approved | 1 |
| delivery time | AuditSystems `started_at` → `delivered_at` timestamp pairs when available; otherwise explicit `not_available` | < 72 hours |
| call-to-paid conversion | paid pilots / calls | >= 20% |
| lead source | `Lead.source`, UTM fields, and analytics metadata | report actual |
| loss reason | manual field until schema expansion is approved | report actual |

## Weekly Report Format

Every weekly row must include:

- actual
- target
- variance
- blocker
- next action

When data is unavailable, show `0` or `not_available`, not demo data.

## Dependency Order

1. AuditSystems PR #30 must be reviewed and ready first because this site routes users to its qualification/report destination.
2. Any AuditSystems migration requires separate owner approval before production execution.
3. The AuditSystems qualification/sample-report route must be production-ready before production links are deployed from this repository.
4. Mother PR #97 deploys only after the destination is ready; until then these changes remain Draft and local/test only.
