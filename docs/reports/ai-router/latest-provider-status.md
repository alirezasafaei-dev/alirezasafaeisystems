# ASDEV AI Provider Status

| Item | Value |
|---|---|
| Started | 2026-07-10T14:54:05Z |
| Finished | 2026-07-10T14:54:05Z |
| Environment | LOCAL_PC |
| Hostname | asdev |
| Config source | /home/dev13/alirezasafaeisystems/config/ai-providers.example.json |

## Provider Status

| Provider | Status | Notes |
|---|---|---|
| MiMo | AVAILABLE | long-context planning; may need VPN |
| OpenCode | AVAILABLE | implementation/patch agent; MVP executor |
| DeepSeek | DISABLED_BY_POLICY | low-cost reasoning fallback; no API call |
| Hermes | AVAILABLE | reporting & provider inventory |
| OpenClaw | AVAILABLE | gateway/diagnostic; Telegram disabled by policy |
| Local small model | DISABLED_BY_POLICY | offline fallback; research only |

## Status Legend

| Status | Meaning |
|---|---|
| `AVAILABLE` | command found or config verified |
| `AVAILABLE_WITH_VPN` | available but VPN may be required |
| `CONFIG_MISSING` | command not found or env not set |
| `CONFIGURED_NOT_CALLED` | configured but no API call made |
| `DISABLED_BY_POLICY` | intentionally disabled per ASDEV policy |
| `UNKNOWN_NOT_TESTED` | not yet tested |

## Safety

This check does not call external APIs, print secrets, or execute provider commands.
