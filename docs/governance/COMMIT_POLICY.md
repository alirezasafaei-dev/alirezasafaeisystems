# Commit Policy — ASDEV

**Last Updated:** 2026-07-08

---

## Format

Conventional commits preferred:

```
feat(os): ...
ops(control-plane): ...
docs(memory): ...
fix(queue): ...
```

## Rules

1. Commit related files together.  
2. Message explains **why**, not only what.  
3. Never commit secrets, `.env`, private keys, raw customer data.  
4. Before commit: secret scan on staged paths.  
5. Do not amend published commits on shared branches without owner intent.  

## Agent commits

- Allowed on topic branches without asking for each commit  
- Batch push before PR  
- Update memory docs in the same batch when state/decisions change  
