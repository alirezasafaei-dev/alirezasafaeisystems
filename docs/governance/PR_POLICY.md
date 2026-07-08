# Pull Request Policy — ASDEV

**Last Updated:** 2026-07-08

---

## When to open a PR

Any change that should land on `main` goes through a PR (even agent-driven).

## Batching

| Good | Bad |
|------|-----|
| One PR: governance + memory + registry | 8 PRs for 8 markdown files |
| One PR: deploy engine scripts + docs | Separate PR per script |

## Required sections

Use `.github/pull_request_template.md`:

- Summary + ASDEV goal  
- Gates taken / not taken  
- Validation commands  
- Explicit non-changes  

## Review

- CODEOWNERS paths auto-request owner  
- Agent may merge with admin when owner authorized autonomous ops **and** change is non-gated  
- Gated production mutations still need phrase **before** runtime action (PR alone is not a deploy phrase)

## CI

- Prefer local validation when GHA infra is red  
- Do not thrash failed workflows without diagnosis  
