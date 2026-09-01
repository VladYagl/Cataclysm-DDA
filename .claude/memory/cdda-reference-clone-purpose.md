---
name: cdda-reference-clone-purpose
description: Why the Cataclysm-DDA reference fork exists and how it is meant to be used
metadata: 
  node_type: memory
  type: project
  originSessionId: b73c37c3-98af-40d2-8ee3-c244cac42b34
  modified: 2026-08-14T08:15:05.827Z
---

This repo is a fork of CleverRaven/Cataclysm-DDA that exists for one
purpose: Vlad asks questions about the game and its mechanics, and the
answers get dug out of the source. It is not a development checkout — no
edits, builds, or commits to the game tree unless they ask.

Cloned 2026-08-14 at `master` / `a724a08d5f`. The checkout on Vlad's
machine is `~/Donuts/cdda`, but nothing may depend on that: on
2026-09-01 the reference tooling moved into the repo (`CLAUDE.md`,
`.claude/memory/`, `.claude/tools/cdda-q`, `.claude/hooks/`) and got
pushed to a fork, so the same setup answers questions from a cloud or
web session on any machine. Refer to everything by repo-relative path.
`CLAUDE.md` holds the layout map and the answering rules; findings
accumulate in `.claude/memory/` — see [[cdda-knowledge-routing]].

Local-machine footnote: keep this clone out of `~/.scripts/`, because
`~/.config/fish/config.fish:74` appends every subdirectory there to
`PATH` and the 13 GB clone added ~1,090 entries.
