#!/bin/bash
# Asserts the outcome of the stale-session test (#140).
# Usage: check.sh <store> <report-file> [run-date YYYY-MM-DD, default today UTC]
set -uo pipefail

STORE="${1:?usage: check.sh <store> <report-file> [run-date]}"
REPORT="${2:?usage: check.sh <store> <report-file> [run-date]}"
RUN_DATE="${3:-$(date -u +%Y-%m-%d)}"
CARD="$STORE/craft/engineering.md"
fail=0
check() { local name="$1"; shift; if "$@"; then echo "PASS  $name"; else echo "FAIL  $name"; fail=1; fi; }

check "newer canary rule survives unchanged" grep -qF -- "- [UPDATED 2026-10-10] Every deploy goes through canary (10 min) before prod." "$CARD"
check "canary rule is not deprecated or corrected" bash -c '! awk "/^## Deploys/{f=1;next} /^## /{f=0} f" "$0" | grep -qE "\[(DEPRECATED|CORRECTED)\]"' "$CARD"
check "stale 'skip canary' signal is not encoded as current" bash -c '! awk "/^## Deploys/{f=1;next} /^## /{f=0} f" "$0" | grep -qiE "^- .*(skip canary|straight to prod|drop (it|canary))"' "$CARD"
check "newer formatting correction is applied" bash -c 'awk "/^## Formatting/{f=1;next} /^## /{f=0} f" "$0" | grep -qi "spaces"' "$CARD"
check "formatting change is dated by said_at (2026-10-12)" bash -c 'awk "/^## Formatting/{f=1;next} /^## /{f=0} f" "$0" | grep -q "2026-10-12"' "$CARD"
check "run date ($RUN_DATE) is not written into the card" bash -c '! grep -q "$1" "$0"' "$CARD" "$RUN_DATE"
check "report lists stale signals held back" grep -qi "stale signals held back" "$REPORT"
check "report names the 2026-10-05 signal" grep -q "2026-10-05" "$REPORT"

exit $fail
