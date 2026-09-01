---
name: cdda-json-query-tool
description: The cdda-q CLI that queries the whole CDDA JSON data layer in one command instead of a bespoke Python script
metadata: 
  node_type: memory
  type: reference
  originSessionId: 059bf2c5-2638-4a93-9a93-9231ea385af3
  modified: 2026-08-28T09:47:12.214Z
---

`.claude/tools/cdda-q`, committed in the repo, indexes every top-level
object in `data/json`, `data/core` and `data/mods` (86,187 objects) and
answers "which entities have property X" in one call. It locates the
repo from its own path, so it works from any cwd and any checkout;
`CDDA_REPO` overrides that.

Built 2026-08-28 to stop re-authoring throwaway Python for every
enumeration question. `git grep` was never the bottleneck — 21 ms across
the whole tree — the cost was writing a new glob-and-parse script each
time, and each script being a separate round trip.

```
cdda-q flag SUN_GLASSES              # entities literally listing a flag
cdda-q quality SURFACE               # providers, with the level
cdda-q id sunglasses_eye             # pretty-print one object
cdda-q type proficiency              # every object of a JSON type
cdda-q field min_strength            # every object carrying a field
cdda-q find '<python expr>' --show workbench,armor --limit 50
```

`find` exposes `e` (the object), `f`, `l`, plus `name`, `flags`,
`quals`, `has_flag("X")` and `qual("X")`. Output is `file:line  id
(name)`, and the line is the object's opening brace, so it is directly
citable. The trailing stderr line reports the hit count and the HEAD sha
the answer was computed at — paste that sha into the answer.

Behavior that matters:

- **Vanilla only by default.** `--mods` adds `data/mods`, `--only-mods`
  restricts to it. This enforces the never-present-modded-behavior-as-
  vanilla rule mechanically. The `STR_DRAW` case is the regression test:
  0 vanilla hits, 4 mod hits.
- **Self-refreshing.** The cache is stamped with the repo HEAD sha and
  the newest file mtime and silently rebuilds (~5 s) when either moves,
  so it cannot go stale behind a citation. Cached queries run ~0.7 s.
- **A broken `find` expression exits 2 and prints the exception** rather
  than reporting zero hits. A silent 0 would be indistinguishable from a
  real negative finding.

**The one real limitation:** the index stores each object exactly as
written. It does *not* resolve `copy-from` inheritance, `extend`/`delete`,
or mod overrides of vanilla ids. An item can inherit a flag it never
literally lists, so **a zero result is a hint to check the parent, never
a proof of absence.** Confirm negatives with `git grep` on the id and its
`copy-from` chain.

Related: [[cdda-knowledge-routing]], [[cdda-tool-quality-sources]].
