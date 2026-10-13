#!/bin/bash
# Stale-session test (#140): an old session distilled last must not overwrite newer knowledge.
# Runs one distillation agent against a mktemp store, then asserts the result with check.sh.
# DISTILL_AGENT_CMD overrides the agent; it receives the prompt as its last argument.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
STORE="$(mktemp -d)"
"$DIR/setup.sh" "$STORE" >/dev/null
REPORT="$STORE/report.md"
AGENT="${DISTILL_AGENT_CMD:-claude -p --dangerously-skip-permissions --add-dir $STORE}"

$AGENT "$(cat "$STORE/prompt.md")" > "$REPORT" 2>&1 || true
"$DIR/check.sh" "$STORE" "$REPORT"
rc=$?
echo "store: $STORE"
exit $rc
