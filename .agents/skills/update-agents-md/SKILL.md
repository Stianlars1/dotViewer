---
name: update-agents-md
description: Keep the repository root AGENTS.md up to date after each task by appending a concise, dated work log entry (what changed, why, and how it was verified).
---

# update-agents-md

Use this skill at the end of any task that changes code, scripts, or docs.

## Workflow

1. Open `AGENTS.md` in the repo root.
2. Append a new dated section under the newest date (or create the date header if missing).
3. Include only:
   - What changed (user-visible outcome first)
   - Key files touched (paths)
   - Verification performed (commands + pass/fail)
   - Any follow-ups / known gaps (short)
4. Keep entries short and factual. No narrative.

## Entry Template

```
## YYYY-MM-DD

### <short topic>
- Outcome: <what is now different / fixed>
- Files: <comma-separated paths>
- Verified:
  - <command> → <result>
- Follow-ups: <if any>
```

## Guardrails
- Do not rewrite older sections unless they are clearly wrong.
- Prefer one new entry per user-visible chunk of work (not every tiny change).
- If no verification was run, explicitly write: `Verified: (not run)` and say why.

