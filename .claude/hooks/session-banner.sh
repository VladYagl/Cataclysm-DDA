#!/usr/bin/env bash
# SessionStart banner for the Cataclysm-DDA reference clone.
# Prints a welcome banner and injects the same facts into Claude's context.
#
# This runs on any checkout of the fork, including cloud/web sessions, so it
# must not assume this machine: every path is derived from the script's own
# location, and it falls back to python3 when jq is missing.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
md="$repo/CLAUDE.md"
index="$repo/.claude/memory/MEMORY.md"

head_sha="$(git -C "$repo" rev-parse --short=10 HEAD 2>/dev/null || echo unknown)"
# The pin CLAUDE.md says answers were last verified at.
pin="$(sed -n 's/^Current reference point: .*`\([0-9a-f]\{7,\}\)`.*/\1/p' "$md" 2>/dev/null | head -1)"
ver="$(sed -n 's/^Current reference point: `\([^`]*\)`.*/\1/p' "$md" 2>/dev/null | head -1)"

if [ -z "$pin" ]; then
  drift="HEAD is at $head_sha. CLAUDE.md does not pin a reference point to compare it against."
elif [ "${head_sha#"$pin"}" != "$head_sha" ] || [ "${pin#"$head_sha"}" != "$pin" ]; then
  drift="HEAD is at $head_sha, which matches the reference point pinned in CLAUDE.md."
else
  drift="HEAD is at $head_sha, which has drifted from the $pin pinned in CLAUDE.md, so line numbers and counts need to be re-derived."
fi

dirty=""
[ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ] &&
  dirty=$'\n'"The working tree is dirty, which is unexpected for a clone meant to stay unmodified."

banner=$'\n'"Welcome to the Cataclysm-DDA reference clone${ver:+, currently on $ver}. \
This is a read-only checkout, kept for answering questions about game mechanics from source.
${drift}${dirty}"

# The memory index travels in the repo rather than in the host's auto-memory,
# so a session on any machine gets the same routing knowledge. Inject it.
memory=""
if [ -r "$index" ]; then
  memory=$'\n\n'"Memory index, read from $index (the canonical copy; individual \
entries are siblings of that file). Treat it as this project's memory: it is \
routing knowledge, not cached answers.

$(cat "$index")"
fi

context="Session is in the Cataclysm-DDA reference clone at $repo (see its CLAUDE.md).
$drift
Questions here are about CDDA game mechanics, to be answered from source rather than from memory.
Open your first reply of the session with a one-line marker: [CDDA ref - HEAD $head_sha] so the user can see this context was picked up.${memory}"

if command -v jq >/dev/null 2>&1; then
  jq -n --arg m "$banner" --arg c "$context" \
    '{systemMessage: $m,
      hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
else
  BANNER="$banner" CONTEXT="$context" python3 -c '
import json, os
print(json.dumps({"systemMessage": os.environ["BANNER"],
                  "hookSpecificOutput": {"hookEventName": "SessionStart",
                                         "additionalContext": os.environ["CONTEXT"]}}))'
fi
