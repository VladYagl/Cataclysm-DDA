#!/usr/bin/env bash
# Stop hook: ask once per session whether anything learned is worth
# recording, and only when the session actually went digging.
#
# CLAUDE.md's rule about recording what you learn is read at session
# start and then sits 20k tokens back by the time an answer lands, with
# nothing observing "an answer just finished". This is that observer. It
# blocks the stop once, with a concrete question, and never again.
#
# It fails open everywhere: no baseline, no transcript, no python3, a
# malformed payload — all exit 0 rather than trap a session in a loop.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# How much searching counts as "went digging". Tuned to skip a question
# answered from an entry already in memory, which is the case where
# there is by definition nothing new to write.
THRESHOLD=8

payload="$(cat)"
state="$(hook_state_dir)" || exit 0

sid="$(hook_json_field "$payload" session_id)"
transcript="$(hook_json_field "$payload" transcript_path)"
stop_reason="$(hook_json_field "$payload" stop_reason)"
[ -n "$sid" ] || exit 0

# max_tokens or a stop sequence means the turn was cut off, not finished;
# asking for a memory entry there interrupts work mid-thought.
case "$stop_reason" in ""|end_turn) ;; *) exit 0 ;; esac

asked="$state/asked-$sid"
base="$state/base-$sid"
[ -e "$asked" ] && exit 0

now="$(hook_memory_fingerprint)"

# No baseline means session-banner.sh did not run (project hooks are
# trusted per host and per path, so a fresh clone often has none). Record
# one now and stay quiet: a first turn is too early to have learned
# anything worth keeping.
if [ ! -r "$base" ]; then
  printf '%s' "$now" > "$base"
  exit 0
fi

# Memory already changed this session — the rule is being followed, so
# never ask again.
if [ "$now" != "$(cat "$base")" ]; then
  : > "$asked"
  exit 0
fi

# Count the tool calls that went digging — calls, not matches, so one
# command mentioning three paths is one search. Grepping the whole transcript
# would count CLAUDE.md's own mentions of src/ and data/json/, which are
# injected every session and have nothing to do with this question.
searches=0
if [ -r "$transcript" ]; then
  searches="$(grep '"tool_use"' "$transcript" 2>/dev/null |
    grep -c -E 'git grep|cdda-q|rg |data/json|doc/JSON|doc/design|src/[a-z_]+\.(cpp|h)' |
    tr -d ' ')"
fi
[ "${searches:-0}" -ge "$THRESHOLD" ] || exit 0

: > "$asked"
hook_block "This session ran ~$searches searches through the game tree and \
wrote nothing to .claude/memory/. Before you stop, decide once — not per \
question — whether any of it makes a *different* question cheaper:

  - a route whose obvious first grep came back empty, and the real one
    was somewhere else;
  - an answer that took more than two hops to bound;
  - a plausible-looking answer that would have been wrong;
  - an entry point you did not know about — a doc directory, a registry,
    a loader table.

If yes, add or extend an entry: .claude/tools/cdda-remember new <slug> \
--section <heading> --summary <line>, body on stdin, which writes it, \
indexes it in MEMORY.md and commits in one call. Run 'cdda-remember check \
<words>' first — extending an existing entry beats a near-duplicate \
sibling. Then push, since an unpushed entry reaches no other session.

If none of that applies, say 'nothing worth recording' in one line and \
stop. Do not invent an entry to satisfy this check, and do not save the \
answer itself: memory is routing knowledge, not an answer cache. This \
fires once per session."
exit 0
