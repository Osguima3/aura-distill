# Stale-session distillation (#140)

## Failure

A session stays open for days. Other sessions distill newer rules in the meantime. When the old session is distilled last, its signals contradict the newer rules and replace them, because the run date is treated as the date of the knowledge.

## Fixture

`setup.sh` builds a store with one card:

- Deploys: canary before prod, `[UPDATED 2026-10-10]`.
- Formatting: tabs, `last_validated: 2026-10-01`.

The harvest comes from a session that started on 2026-10-04:

1. 2026-10-05: "skip canary, deploy straight to prod". Older than the canary rule, so it must be held back.
2. Time unknown: "drop canary". Falls back to the session start (2026-10-04), so it must be held back.
3. 2026-10-12: "use spaces, not tabs". Newer than the tabs rule, so it must be applied and dated 2026-10-12.

## Pass criteria (`check.sh`)

- The canary rule is unchanged and not marked `[DEPRECATED]` or `[CORRECTED]`.
- The formatting entry says spaces and carries 2026-10-12.
- The run date does not appear in the card.
- The report lists the held-back signals, including the 2026-10-05 one.

## Run

```bash
./run-stale-session-test.sh
```

`DISTILL_AGENT_CMD` swaps the agent (for example `codex exec`). The store is a `mktemp -d` directory; the test never touches `~/.aura-distill`.
