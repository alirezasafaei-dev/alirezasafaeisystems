# Provider Fallback Policy — ASDEV Automation

**Status:** Active (2026-07-06)
**Purpose:** Reliable model selection for automation

---

## Provider Priority

| Priority | Provider | Model | Status | Use Case |
|---|---|---|---|---|
| 1 | DeepSeek | deepseek-chat | ✅ Pass | Primary for automation |
| 2 | OpenRouter | owl-alpha | ⚠️ Degraded | Gemini fallback issue |
| 3 | OpenCode | deepseek-v4-flash-free | ✅ Pass | Worker drafts |
| 4 | Gemini | gemini-2.0-flash | ❌ Quota exhausted | Avoid |

---

## Fallback Rules

1. **Primary:** Use `deepseek/deepseek-chat` for all automation tasks
2. **Degraded:** If DeepSeek fails, try `opencode run` with free model
3. **Avoid:** Do not use OpenRouter default (Gemini quota issue)
4. **Stop:** If both DeepSeek and OpenCode fail, stop and report

---

## Max Cost Rule

- Prefer free/low-cost models
- Do not retry expensive models more than 2 times
- If provider fails 3x, mark as degraded and move to next

---

## Provider Health Check

```bash
# DeepSeek (primary)
hermes -m deepseek/deepseek-chat -z "Reply with exactly: health-ok"

# OpenCode (worker)
opencode run "Reply with exactly: health-ok"
```

---

## When to Stop

Stop automation if:
- Primary provider (DeepSeek) fails 3 consecutive times
- All providers are degraded
- Provider returns auth errors (key expired)
- Rate limits hit on all providers

---

## Error Categories

| Category | Action |
|---|---|
| quota_exhausted | Skip provider, use next |
| auth_error | Report to owner, stop |
| rate_limit | Wait 60s, retry once |
| network_error | Retry once, then skip |
| unknown | Log, skip, continue |

---

*Provider fallback policy active.*
