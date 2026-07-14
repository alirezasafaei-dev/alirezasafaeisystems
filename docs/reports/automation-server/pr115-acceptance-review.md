# Acceptance Review: AuditSystems

**Repository**: `alirezasafaei-dev/auditsystems`
**Commit**: `ac85316e77d499b04857b6845ddb943c9905bfeb`
**Reviewer**: Automated Acceptance Review
**Date**: 2026-07-14
**Status**: PASS (with observations)

---

## 1. Repository Overview

| Attribute | Value |
|---|---|
| **Framework** | Next.js 16 (React 19) |
| **Language** | TypeScript 6.0 (strict mode) |
| **Runtime** | Node.js 22 |
| **Package Manager** | pnpm 9.15 |
| **Database** | PostgreSQL 16 (Prisma ORM) |
| **Process Manager** | PM2 (ecosystem.config.cjs) |
| **Testing** | Vitest |
| **Linting** | ESLint 9 (zero warnings policy) |

**Architecture**: Full-stack SaaS application for website auditing with:
- Next.js app router (`src/app/`) with 34 route directories
- Background job worker (`src/worker/`) with PostgreSQL-backed queue
- 104+ library modules (`src/lib/`) covering auth, billing, payments, SEO, scoring
- 22 API route groups (`src/app/api/`)
- 18 React components (`src/components/`)
- Comprehensive Prisma schema with 20+ models
- 15 operational scripts (`scripts/`)

---

## 2. Commit Verification

**Expected**: `ac85316e77d499b04857b6845ddb943c9905bfeb`
**Actual**: `ac85316e77d499b04857b6845ddb943c9905bfeb`
**Result**: MATCH

**Commit message**: `ci: harden self-hosted workflows with guarded cleanup (#45)`

**Files changed** (2 files, +37/-4):
- `.github/workflows/main-gate.yml` (+27/-3)
- `.github/workflows/roadmap-automation.yml` (+14/-1)

**Diff summary**:
1. **Same-repository PR guards**: Added `if:` condition to prevent external fork PRs from running on self-hosted runners (`github.event.pull_request.head.repo.full_name == github.repository`)
2. **Ref-scoped concurrency**: Changed concurrency group from `github.repository` to `github.head_ref || github.ref` for proper PR isolation
3. **Process-group cleanup**: Uses `setsid` + process-group kill (`kill -- "-$APP_PID"`) to ensure all child processes are terminated
4. **Runner workspace cleanup**: Added `always()` cleanup step that wipes `GITHUB_WORKSPACE` and `RUNNER_TEMP` directories
5. **PID file management**: Writes PID to file for reliable cleanup across steps

---

## 3. Key Observations

### Security Posture (Good)
- **SSRF protection**: Comprehensive IP blocking (private/reserved IPv4+IPv6 ranges), DNS verification, blocked hostname suffixes (`normalizeAuditTargetUrl.ts`)
- **Session management**: HMAC-signed session tokens with `crypto.timingSafeEqual` (`auth.ts`)
- **CSRF protection**: Double-submit cookie pattern with HMAC signatures (`csrf.ts`)
- **Password hashing**: `crypto.scryptSync` with random salt (`auth.ts`)
- **CSP headers**: Well-configured Content-Security-Policy with frame-ancestors, form-action, and base-uri restrictions (`next.config.ts`)
- **Security headers**: X-Frame-Options DENY, X-Content-Type-Options nosniff, HSTS with preload
- **Secret scanning**: Custom `scan-secrets.sh` with rg/grep fallback, AWS/GitHub/Google key pattern detection
- **Actions pinning**: `check:actions-pinned.sh` script and pinned SHA references in workflows
- **Environment-based secrets**: All secrets loaded from env vars, `.env` properly gitignored

### CI/CD Hardening (Good)
- Self-hosted runner isolation for fork PRs
- Concurrency groups prevent overlapping runs
- `permissions: contents: read` limits GITHUB_TOKEN scope
- 30-minute job timeouts
- `--frozen-lockfile` for deterministic installs
- Artifact uploads for debugging

### Code Quality (Good)
- TypeScript strict mode enabled
- Zero-warning lint policy (`--max-warnings=0`)
- Extensive test coverage: unit tests, integration tests, schema validation tests
- Comprehensive Prisma schema with proper indexes and cascade relationships
- Clean separation: worker, API routes, lib modules, components

### Operational Readiness (Good)
- PM2 config with memory limits (512M web, 256M worker)
- Health check endpoints (`/api/ready`)
- Structured logging and observability
- Graceful worker shutdown (SIGINT/SIGTERM handling)
- Database backup/restore scripts

---

## 4. Issues Found

### 4.1 CSRF Signature Verification: Timing Attack Vulnerability

**Severity**: Medium
**File**: `src/lib/csrf.ts:88`
**Issue**: CSRF token signature verification uses standard string equality (`!==`) instead of constant-time comparison.

```typescript
// Current (line 88):
if (signature !== expectedSignature) {
  return false;
}

// Should be:
const sigBuf = Buffer.from(signature, 'hex');
const expectedBuf = Buffer.from(expectedSignature, 'hex');
if (sigBuf.length !== expectedBuf.length || !crypto.timingSafeEqual(sigBuf, expectedBuf)) {
  return false;
}
```

**Context**: The auth module (`auth.ts:76`) correctly uses `crypto.timingSafeEqual` for session token verification, but the CSRF module does not follow the same pattern. This inconsistency suggests it may be an oversight.

### 4.2 Admin Password Comparison: Non-Constant-Time

**Severity**: Low
**File**: `src/lib/admin-auth.ts:45`
**Issue**: Admin credential validation uses standard string equality for password comparison.

```typescript
// Current (line 45):
return username === ADMIN_USERNAME && password === ADMIN_PASSWORD && ADMIN_PASSWORD.length > 0;

// Should use timing-safe comparison for the password:
const pwMatch = crypto.timingSafeEqual(
  Buffer.from(password),
  Buffer.from(ADMIN_PASSWORD)
);
return username === ADMIN_USERNAME && pwMatch && ADMIN_PASSWORD.length > 0;
```

**Mitigation**: Low practical risk since admin username is likely not secret, and rate limiting is applied to auth endpoints. However, it contradicts the security patterns established elsewhere in the codebase.

### 4.3 Rate Limiting Disabled by Default

**Severity**: Low (by design)
**File**: `src/lib/rateLimit.ts:73-79`
**Issue**: When no Redis instance is configured, rate limiting returns `allowed: true` for all requests. The `REQUIRE_DISTRIBUTED_RATE_LIMIT` env var exists to enforce it, but defaults to `false`.

**Context**: This is likely intentional for development/CI simplicity. The main-gate workflow sets `REQUIRE_DISTRIBUTED_RATE_LIMIT=false`. Production deployments should set this to `true` and configure Redis.

### 4.4 CSP Allows `unsafe-inline` and `unsafe-eval` for Scripts

**Severity**: Low (framework constraint)
**File**: `next.config.ts:36`
**Issue**: Content-Security-Policy includes `'unsafe-inline'` and `'unsafe-eval'` for `script-src`, which weakens XSS protections.

**Context**: This is a common Next.js requirement for client-side hydration and development mode. The policy is still restrictive in other dimensions (frame-ancestors none, form-action self, etc.).

### 4.5 Workflow Cleanup Aggressiveness

**Severity**: Informational
**File**: `.github/workflows/main-gate.yml:100`
**Issue**: The cleanup step uses `find "$GITHUB_WORKSPACE" -mindepth 1 -maxdepth 1 -exec rm -rf {} +` which recursively deletes all contents. On shared self-hosted runners, this is appropriate for isolation but could be surprising if the workspace is ever reused.

**Mitigation**: The `if: always()` condition ensures cleanup runs even on failure, which is good practice for self-hosted runners.

---

## 5. PR #45 Specific Assessment

The changes in commit `ac85316` are well-structured and address real self-hosted runner security concerns:

| Change | Assessment |
|---|---|
| Same-repository PR guard | **Correct** - prevents fork PRs from executing on private runners |
| Ref-scoped concurrency | **Correct** - allows parallel PR builds while serializing same-branch pushes |
| Process-group cleanup with `setsid` | **Correct** - ensures orphaned Next.js child processes are killed |
| PID file management | **Correct** - reliable cross-step process tracking |
| Workspace wipe on `always()` | **Correct** - prevents state leakage between runs |

No issues found in the PR diff itself. The workflow changes follow security best practices for self-hosted GitHub Actions runners.

---

## 6. Conclusion

**Verdict**: PASS

The repository is a well-architected Next.js SaaS application with strong security foundations. The codebase demonstrates:

- Consistent security patterns (HMAC signing, timing-safe comparisons, SSRF protection)
- Comprehensive testing and quality gates
- Proper secret management via environment variables
- Good operational practices (PM2, health checks, graceful shutdown)

The three actionable findings (4.1, 4.2, 4.3) are pre-existing issues unrelated to the PR under review. The PR itself (#45) correctly hardens self-hosted runner workflows with appropriate guards and cleanup procedures.

**Recommendation**: Accept the PR. Address findings 4.1 and 4.2 as follow-up items to align CSRF and admin auth with the timing-safe patterns already established in `auth.ts`.
