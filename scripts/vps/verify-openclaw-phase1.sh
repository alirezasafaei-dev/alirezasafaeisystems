#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "[VERIFY] $*"; }
ok() { echo -e "[OK] $*"; }
warn() { echo -e "[WARN] $*"; }
fail() { echo -e "[FAIL] $*"; }

ISSUES=0

log "=== OpenClaw Phase 1 Verification (No-LLM) ==="
echo ""

log "--- OpenClaw Version ---"
if command -v openclaw >/dev/null 2>&1; then
  VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
  ok "OpenClaw: ${VERSION}"
else
  fail "OpenClaw not found in PATH"
  ISSUES=$((ISSUES + 1))
fi
echo ""

log "--- Node Version ---"
if command -v node >/dev/null 2>&1; then
  ok "Node: $(node -v)"
else
  fail "Node not found"
  ISSUES=$((ISSUES + 1))
fi
echo ""

log "--- Gateway Status ---"
if openclaw gateway status >/dev/null 2>&1; then
  ok "Gateway running"
else
  warn "Gateway not running (may need openclaw onboard first)"
fi
echo ""

log "--- Gateway Bind Address ---"
GATEWAY_BIND=$(ss -tlnp 2>/dev/null | grep 18789 | awk '{print $4}' || echo "")
if echo "$GATEWAY_BIND" | grep -q "127.0.0.1"; then
  ok "Gateway bound to loopback (127.0.0.1)"
elif [ -n "$GATEWAY_BIND" ]; then
  fail "Gateway bound to ${GATEWAY_BIND} — must be 127.0.0.1"
  ISSUES=$((ISSUES + 1))
else
  warn "Gateway not listening yet"
fi
echo ""

log "--- Config File ---"
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
  ok "Config exists"
  if grep -q '"127.0.0.1"' "$HOME/.openclaw/openclaw.json" 2>/dev/null; then
    ok "Config has loopback gateway"
  else
    fail "Config missing loopback gateway"
    ISSUES=$((ISSUES + 1))
  fi
  if grep -q '"pairing"' "$HOME/.openclaw/openclaw.json" 2>/dev/null; then
    ok "Config has pairing mode"
  else
    warn "Config may not have pairing mode"
  fi
  if grep -q '"denied"' "$HOME/.openclaw/openclaw.json" 2>/dev/null; then
    ok "Config has tool denials"
  else
    warn "Config may not have tool denials"
  fi
  if grep -q '"UNCONFIGURED"' "$HOME/.openclaw/openclaw.json" 2>/dev/null; then
    ok "Config has UNCONFIGURED model (no paid LLM)"
  elif grep -q '"openai"' "$HOME/.openclaw/openclaw.json" 2>/dev/null; then
    fail "Config has OpenAI provider — no paid API approved"
    ISSUES=$((ISSUES + 1))
  fi
else
  fail "Config not found at ~/.openclaw/openclaw.json"
  ISSUES=$((ISSUES + 1))
fi
echo ""

log "--- Skills ---"
if [ -f "$HOME/.openclaw/workspace/skills/asdev-status/SKILL.md" ]; then
  ok "asdev-status skill installed"
else
  warn "asdev-status skill not found"
fi
echo ""

log "--- Phase 1 Safety ---"
if [ -f "$HOME/.openclaw/workspace/skills/asdev-commands/SKILL.md" ]; then
  fail "asdev-commands skill found — Phase 1 must NOT have command submitter"
  ISSUES=$((ISSUES + 1))
else
  ok "No command submitter skill (correct for Phase 1)"
fi

if grep -q "openai" "$HOME/.openclaw/openclaw.json" 2>/dev/null; then
  fail "OpenAI provider found — no paid API approved"
  ISSUES=$((ISSUES + 1))
else
  ok "No OpenAI provider (correct for Phase 1)"
fi
echo ""

log "=== Summary ==="
if [ "$ISSUES" -gt 0 ]; then
  fail "Issues found: ${ISSUES}"
  exit 1
else
  ok "All Phase 1 checks passed (no-LLM mode)"
  exit 0
fi
