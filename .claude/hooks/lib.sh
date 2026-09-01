#!/usr/bin/env bash
# Shared helpers for this repo's hooks. Sourced, never run directly.
#
# Like every other piece of the reference clone, this derives its paths
# from its own location so the same checkout works on any machine.

hook_repo() { (cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd); }

# Per-session scratch. Gitignored: it records what a session started
# with, which is meaningless to anyone else and must never be committed.
hook_state_dir() {
  local dir
  dir="$(hook_repo)/.claude/.state"
  mkdir -p "$dir" 2>/dev/null || return 1
  # A session's scratch is worthless once the session is gone.
  find "$dir" -type f -mtime +7 -delete 2>/dev/null
  printf '%s' "$dir"
}

# A cheap content fingerprint of the memory directory. Comparing this
# against the value recorded at session start answers "did this session
# actually write anything down", which no amount of transcript grepping
# does reliably.
hook_memory_fingerprint() {
  local mem
  mem="$(hook_repo)/.claude/memory"
  [ -d "$mem" ] || { printf 'none'; return; }
  { find "$mem" -type f | LC_ALL=C sort
    find "$mem" -type f | LC_ALL=C sort | xargs cat; } | cksum | cut -d' ' -f1
}

# Read one string field out of the JSON a hook gets on stdin. jq when it
# is there, python3 otherwise — the same fallback session-banner.sh uses,
# since neither is guaranteed on a fresh cloud container.
hook_json_field() {
  local json="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r --arg f "$field" '.[$f] // empty' 2>/dev/null
  else
    JSON="$json" FIELD="$field" python3 -c '
import json, os, sys
try:
    print(json.loads(os.environ["JSON"]).get(os.environ["FIELD"], "") or "")
except Exception:
    pass' 2>/dev/null
  fi
}

# Emit a Stop-hook decision that keeps the turn alive with a reason.
hook_block() {
  local reason="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg r "$reason" \
      '{hookSpecificOutput: {hookEventName: "Stop", decision: "block", reason: $r}}'
  else
    REASON="$reason" python3 -c '
import json, os
print(json.dumps({"hookSpecificOutput": {"hookEventName": "Stop",
                                         "decision": "block",
                                         "reason": os.environ["REASON"]}}))'
  fi
}
