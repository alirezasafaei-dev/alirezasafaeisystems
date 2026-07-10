# ASDEV Audit Revenue Scorecard

Status: source-of-truth contract for `alirezasafaeisystems#96`.

The weekly scorecard uses two real inputs:

- System data: `Lead`, `AnalyticsEvent`, and `FunnelConversion` from the portfolio database.
- Manual sales data: a private weekly JSON file shaped like `docs/revenue/weekly-scorecard.manual.example.json`.

Do not count commits, tests, automation cycles, or generic traffic as revenue progress.

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
| delivery time | AuditSystems delivery timestamps when available; otherwise manual report log | < 3 business days |
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
