# Hermes Provider Health Check

**Date:** 2026-07-06T20:10:00Z
**Hermes Version:** v0.17.0
**Secrets Exposed:** None

---

## Provider Status

| Provider | Env Present | Health | Error Category | Notes |
|---|---|---|---|---|
| OpenRouter | ✅ Yes | ⚠️ degraded | Gemini fallback quota exhaustion | Default model routes to Gemini |
| Google/Gemini | ✅ Yes | ❌ fail | quota_exhausted (free tier) | Rate limited, 0 quota remaining |
| DeepSeek | ✅ Yes | ✅ pass | — | Works directly, not via OpenRouter |
| Kimi | ✅ Yes | ❌ fail | Gemini fallback quota exhaustion | Routes through Gemini |
| OpenAI | ❌ No | not-tested | — | Not configured |
| xAI/Grok | ❌ No | not-tested | — | Not configured |
| Anthropic | ❌ No | not-tested | — | Not configured (available via OpenRouter) |

---

## Test Results

### DeepSeek (direct)

```bash
hermes -m deepseek/deepseek-chat -z "Reply with exactly: provider-health-ok"
# Output: provider-health-ok
# Status: PASS
```

### OpenRouter (default: owl-alpha)

```bash
hermes -m openrouter/owl-alpha -z "Reply with exactly: provider-health-ok"
# Error: HTTP 429 Gemini quota exhaustion
# Status: DEGRADED (Gemini fallback exhausted)
```

### Kimi

```bash
hermes -m kimi/kimi-k2 -z "Reply with exactly: provider-health-ok"
# Error: HTTP 429 Gemini quota exhaustion
# Status: FAIL (Gemini fallback exhausted)
```

---

## Recommendations

1. **Primary model for automation:** Use `deepseek/deepseek-chat` for kanban dispatch and dry-runs (reliable, no Gemini dependency)
2. **Gemini quota:** Free tier exhausted. Either wait for quota reset or configure paid Gemini API key
3. **OpenRouter fallback:** Currently routes to Gemini on failure. Consider removing Gemini from fallback chain or adding more reliable fallback
4. **For production automation:** Configure at least 2 reliable providers (DeepSeek + one other) to avoid single-point failures

---

## Configured Providers Summary

```
OpenRouter: present (key masked)
Google/Gemini: present (key masked)
DeepSeek: present (key masked)
Kimi: present (key masked)
```

---

*Health check complete. No secrets exposed.*
