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

# Everything the reference clone adds lives in these two paths; the rest of
# the tree is upstream's. Excluding them separates "the game changed" from
# "we committed a note", which HEAD alone cannot distinguish.
ours=(':(exclude)CLAUDE.md' ':(exclude).claude')

git_at() { git -C "$repo" "$@" 2>/dev/null; }

head_sha="$(git_at rev-parse --short=10 HEAD || echo unknown)"
# The newest commit reachable from HEAD that touches the game tree. Our own
# commits never move it, so this — not HEAD — is the sha a citation names
# and the sha the pin is compared against.
base_sha="$(git_at rev-list -1 --abbrev-commit --abbrev=10 HEAD -- . "${ours[@]}")"
[ -n "$base_sha" ] || base_sha="$head_sha"

# The pin CLAUDE.md says answers were last verified at.
pin="$(sed -n 's/^Current reference point: .*`\([0-9a-f]\{7,\}\)`.*/\1/p' "$md" 2>/dev/null | head -1)"
ver="$(sed -n 's/^Current reference point: `\([^`]*\)`.*/\1/p' "$md" 2>/dev/null | head -1)"

if [ -z "$pin" ]; then
  drift="The game tree is at $base_sha. CLAUDE.md does not pin a reference point to compare it against."
elif [ "${base_sha#"$pin"}" != "$base_sha" ] || [ "${pin#"$base_sha"}" != "$pin" ]; then
  drift="The game tree is at $base_sha, which matches the reference point pinned in CLAUDE.md. Cite that sha, not HEAD."
else
  drift="The game tree is at $base_sha, which has drifted from the $pin pinned in CLAUDE.md, so line numbers and counts need to be re-derived."
fi

# HEAD carrying reference tooling on top of the game tree is the normal
# state, not drift — but the two shas differ, so say which one to cite.
[ "$head_sha" != "$base_sha" ] &&
  drift="$drift"$'\n'"HEAD is $head_sha, which adds only the reference tooling (CLAUDE.md and .claude/) on top of that."

# A dirty game tree is a real problem; uncommitted notes are just unsaved
# work, and memory only persists once it is committed.
game_dirty="$(git_at status --porcelain -- . "${ours[@]}")"
ours_dirty="$(git_at status --porcelain -- CLAUDE.md .claude)"
dirty=""
[ -n "$game_dirty" ] &&
  dirty=$'\n'"The game tree has uncommitted changes, which is unexpected for a clone meant to stay unmodified."
[ -n "$ours_dirty" ] &&
  dirty="$dirty"$'\n'"CLAUDE.md or .claude/ has uncommitted changes; memory and tooling only persist for other sessions once committed."

banner=$'\n'"Welcome to the Cataclysm-DDA reference clone${ver:+, currently on $ver}. \
This is a read-only checkout, kept for answering questions about game mechanics from source.
${drift}${dirty}"

# Record what .claude/memory/ looked like when this session started, so
# the Stop hook in memory-check.sh can tell whether the session actually
# wrote anything down. Reading stdin is guarded: run by hand from a
# terminal there is no payload, and cat would hang waiting for one.
if [ -r "$repo/.claude/hooks/lib.sh" ]; then
  # shellcheck source=lib.sh
  . "$repo/.claude/hooks/lib.sh"
  payload=""
  [ -t 0 ] || payload="$(cat)"
  sid="$(hook_json_field "$payload" session_id)"
  if [ -n "$sid" ] && state_dir="$(hook_state_dir)"; then
    hook_memory_fingerprint > "$state_dir/base-$sid"
  fi
fi

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
Open your first reply of the session with a one-line marker: [CDDA ref - $base_sha] so the user can see this context was picked up.${memory}"

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
