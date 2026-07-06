# OpenCode — ASDEV Setup Guide

**Version:** v1.17.13
**Status:** Installed and working

---

## Installation

```bash
# Already installed at:
/home/dev13/.opencode/bin/opencode
```

## Configuration

OpenCode uses its own config. See `config.example.json` for template.

## Usage

### Read-only inspection

```bash
opencode run "Read {file} and summarize. Do not edit."
```

### Code draft

```bash
opencode run "Implement {feature} in {path}. Use existing patterns."
```

### Review

```bash
opencode run "Review {file} and suggest improvements."
```

## Provider

Default model: `deepseek-v4-flash-free`

Test with:
```bash
opencode run "Reply with exactly: opencode-health-ok"
```

## Safety

- PersianToolbox: read-only
- Deploy: denied
- Billing: denied
- Main branch: no direct push

---

*Setup guide complete.*
