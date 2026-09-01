---
name: cdda-knowledge-routing
description: "What goes in CDDA project memory — routing and system mechanics, never per-question answers"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 059bf2c5-2638-4a93-9a93-9231ea385af3
  modified: 2026-08-28T09:48:31.480Z
---

Vlad revised this on 2026-08-28. **Memory is not an answer cache.** Do
not write a memory entry to make a repeat question cheaper; write one
only when it makes a *different, future* question cheaper.

What belongs here:

- **Routing and detours** — where a system's data and code live, which
  indirection is easy to miss, which grep returns a misleading nothing.
- **How core system mechanics work** — the general rule, not the
  instance. "Proficiency `bonuses` categories have one consumer in
  `src/`" belongs; "Archer's Form lowers bow min_str by 2" does not.
- **Traps that produce confidently wrong answers** — id-vs-display-name
  mismatches, flags defined but unused, doc fields with no caller.

What does not: the answer to a specific question, item values, per-item
tables, anything re-derivable in one `cdda-q` call.

**Why:** he found the accumulated per-question entries were paying off
only on exact repeats, which rarely happen, while the same structural
detours cost a fresh search every time. Memory should compound on
*navigation*, not on trivia.

**How to apply.** After a non-trivial question, ask what was slow to
*find* rather than what the answer was, and write that. Prefer editing an
existing system entry over adding a sibling. Keep everything CDDA
specific — nothing here belongs in the global `~/.claude/CLAUDE.md`.
Durable, general orientation rules go in the repo `CLAUDE.md` instead;
memory holds the more specific layer beneath it. Always carry `file:line`
plus the commit sha, since upstream moves.

Thirteen per-question entries (clay, sand, kiln, corpse revival,
firestarter, recharger, helicopter, individual proficiency ladders, …)
were deleted under this rule. Their reusable routing content was folded
into [[cdda-traits-skills-proficiencies-lookup]],
[[cdda-tool-quality-sources]] and [[cdda-character-flag-sources]].

See [[cdda-reference-clone-purpose]] and [[cdda-json-query-tool]].
