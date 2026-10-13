#!/usr/bin/env bash
# distill-said-at -- when did the user say this? Reads a Claude Code or Codex transcript (JSONL).
#
#   distill-said-at.sh <transcript.jsonl> <phrase>        UTC timestamp of the one user message
#                                                         containing <phrase>, else "unknown"
#   distill-said-at.sh <transcript.jsonl> --session-start first timestamp in the transcript
#
# Only messages the user typed count: Claude Code "type":"user" lines that are not tool results
# or meta lines; Codex "user_message" events, or "role":"user" response items in rollouts that
# have no such events. The agent's own tool calls and their output never match, so a search for
# the phrase does not find itself. Two or more matching messages print "unknown": the caller
# picks a longer phrase. The phrase must not contain quotes, backslashes or line breaks (JSON
# escapes them in the transcript). Prints "unknown" for any failure; never guesses. Exit 0.

transcript="${1:-}"
phrase="${2:-}"
unknown() { echo unknown; exit 0; }

[ -r "$transcript" ] && [ -n "$phrase" ] || unknown
first_ts() { grep -o '"timestamp":"[^"]*"' | head -1 | sed 's/^"timestamp":"//; s/"$//'; }

if [ "$phrase" = "--session-start" ]; then
    ts=$(first_ts < "$transcript")
    [ -n "$ts" ] && echo "$ts" || unknown
    exit 0
fi

case "$phrase" in *'"'*|*'\'*|*$'\n'*) unknown ;; esac

if grep -q '"type":"user_message"' "$transcript"; then
    user_lines() { grep '"type":"user_message"' "$transcript"; }
elif grep -q '"type":"session_meta"' "$transcript"; then
    user_lines() { grep '"type":"response_item"' "$transcript" | grep '"role":"user"'; }
else
    user_lines() { grep '"type":"user"' "$transcript" | grep -v '"tool_result"' | grep -v '"isMeta":true'; }
fi

stamps=$(user_lines | grep -F -- "$phrase" | while IFS= read -r line; do printf '%s\n' "$line" | first_ts; done | sort -u)
[ -n "$stamps" ] && [ "$(printf '%s\n' "$stamps" | wc -l | tr -d ' ')" = 1 ] && echo "$stamps" || unknown
