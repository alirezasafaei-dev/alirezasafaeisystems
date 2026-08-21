# Discover DGR-09 Freshness Contract Plan

> Execute with Superpowers TDD and verification. Keep runtime publication/data paths unchanged.

**Goal:** Require auditable freshness evidence for staged Discover resource manifests without persisting evidence into the Discover database payload.

**Contract:** Every `docs/discover/resources/*.json` document keeps exactly `{ payload, evidence }`. `evidence` must include a valid non-future `checkedAt` date in `YYYY-MM-DD` form and a non-empty, duplicate-free list of HTTPS `sources`. Existing descriptive evidence fields remain allowed. The validator rejects missing/malformed freshness evidence before invoking the schema contract test.

**Safety:** `payload.published` and `publishedEn` behavior is unchanged. DeepSeek and Vibe remain unpublished. No Admin/API/database/schema/production mutation.

## Task 1 — TDD freshness validation
- [ ] Extend `src/__tests__/lib/discover-manifests.test.ts` with valid-contract assertions.
- [ ] Add CLI regression cases for missing `checkedAt`, future/invalid dates, empty/duplicate/non-HTTPS sources.
- [ ] Add a test-only manifest-directory override so CLI failures can be exercised without mutating repository fixtures.

## Task 2 — Validator implementation
- [ ] Extend `scripts/discover/validate-manifests.mjs` to validate document shape and freshness metadata before the Vitest schema runner.
- [ ] Keep payload/evidence separation and existing cross-platform pnpm runner behavior intact.
- [ ] Emit actionable filename-specific validation errors.

## Task 3 — Revalidated evidence
- [ ] Record `checkedAt: 2026-08-21` only for claims independently rechecked on 2026-08-21.
- [ ] Add authoritative HTTPS sources for DeepSeek/G.Media and Vibe/Mistral.
- [ ] Keep both staged payloads `published: false` and omit runtime English publication.

## Task 4 — Verification and PR
- [ ] Run/obtain hosted secret scan, type-check, lint, unit/integration, build/E2E as routed.
- [ ] Open a dedicated DGR-09 PR and document the public revalidation sources.
- [ ] Do not perform any production content mutation or deployment.
