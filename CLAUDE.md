# CLAUDE.md — Cataclysm-DDA reference clone

This is a fork of CleverRaven/Cataclysm-DDA used as a **read-only
reference for answering questions about game mechanics from source**. The
game tree is unmodified upstream; the only files that are ours are
`CLAUDE.md` and `.claude/`, added on the `cdda-reference` branch. Do not
edit game files, build the game, or commit to the game tree unless
explicitly asked.

## Where this runs

The same checkout answers questions on any machine, so nothing here may
assume a particular host:

- **This repo carries its own context.** The routing memory
  (`.claude/memory/`), the query tool (`.claude/tools/cdda-q`) and the
  session hook (`.claude/hooks/`) are committed, not kept in a host's
  `~/.claude`. Refer to them by repo-relative path, never absolute.
- **The session hook injects the memory index** at start, because a
  session outside the original machine has no auto-loaded memory for
  this project. Individual entries are read on demand from
  `.claude/memory/`.
- **Memory writes have to be committed** to persist. Writing the file is
  only half of it; see *Recording what you learn* below.

## Where things live

- `src/` — 923 flat C++ files, 416 of them `.cpp` (no subsystem subdirs
  beyond `chkjson`, `cldr` and `third-party`). Behavior lives here.
  Largest and most central, by size: `item.cpp`, `game.cpp`,
  `character.cpp`, `mapgen.cpp`, `map.cpp`, `npctalk.cpp`, `iuse.cpp`,
  `activity_actor.cpp`, `vehicle.cpp`, `overmap.cpp`, `iexamine.cpp`.
- `data/json/` — 3,013 JSON files, the data layer. Values, definitions,
  and content live here, grouped by type (`items/`, `monsters/`,
  `recipes/`, `mapgen/`, `mutations/`, `vehicleparts/`, …).
- `data/core/` — engine-level data, 8 files including
  `external_options.json`, `world_option_sliders.json`, `weather.json`,
  `help.json` and `mod_migrations.json`.
- `data/mods/` — 42 in-repo mods that can override or extend vanilla.
- `doc/JSON/` — 38 schema and mechanic docs. `JSON_INFO.md` is the
  master schema reference, `JSON_FLAGS.md` lists flags, and per-system
  docs cover `MAPGEN`, `MUTATIONS`, `MAGIC`, `NPCs`, `PROFICIENCY`,
  `VEHICLES_JSON`, and more.
- `tests/` — 218 Catch2 test files. Often the clearest executable
  statement of what a mechanic is supposed to do.

Counts above verified at `27939e29b8`; re-derive rather than trust them
if the clone has been updated.

## The three-layer rule

Nearly every mechanic is split across three places. An answer citing
only one layer is usually incomplete:

1. `doc/JSON/` — what the schema says a field means.
2. `data/json/` — the actual values in play.
3. `src/` — the code that consumes them and decides behavior.

Say which layer each part of an answer came from.

## Finding the code behind a JSON type

`src/init.cpp:255` (`DynamicDataLoader::initialize`) maps every JSON
`"type"` string to its loader function — 160 registrations of the form
`add( "terrain", &load_terrain )`. This is the fastest route from a JSON
type name to the C++ that parses it. Start there instead of grepping
blind.

## Search

Searching is not the bottleneck — `git grep` across the whole tree takes
21 ms and parsing every JSON file takes 340 ms. **Round trips are the
bottleneck.** Optimize for fewer, wider tool calls, not faster ones.

- **Fan out speculatively on the first call.** Given a new mechanic, the
  three-layer rule already tells you where the answers live, so issue
  the `doc/JSON/` grep, the `data/json/` grep, the `src/` consumer grep
  and the `src/flag.cpp`/`init.cpp` registration lookup *in one parallel
  block*, then do one follow-up to close gaps. Do not walk the chain one
  link per turn. Empty results are free; extra turns are not.
- `git grep -n` is the default: fast, tree-aware, no index needed.
- `rg` for anything outside version control or for richer patterns.
- ctags only when a question needs real symbol jumping, built on demand
  rather than pre-emptively:

  ```sh
  ctags -R --languages=C++ -f .claude/.tags src/
  ```

  `.claude/.tags` is ignored via `.claude/.gitignore`, which keeps
  upstream's own `.gitignore` untouched.

### Enumerating the data layer

For "which entities have property X" questions, use the query tool
instead of writing a throwaway parse script:

```sh
.claude/tools/cdda-q flag SUN_GLASSES
.claude/tools/cdda-q quality SURFACE
.claude/tools/cdda-q find \
  'e.get("type")=="furniture" and e.get("workbench")' --show workbench
```

Also `id`, `type`, `field`, and `--show` / `--limit` / `--mods`. It is
vanilla-only by default, prints `file:line` and the HEAD sha, and
rebuilds itself when the repo moves — including on a fresh clone, where
the first call spends about a second building the index that
`.claude/.gitignore` deliberately keeps out of git. **It does not
resolve `copy-from`, `extend`/`delete`, or mod overrides** — a zero
result means "not literally written here", so confirm negatives against
the parent chain.

### Routes that are easy to get wrong

- **Quality providers.** Grepping a quality id in
  `furniture_and_terrain/` returns nothing even when furniture provides
  it — furniture points at a `crafting_pseudo_item` in
  `items/tool/pseudo.json` which carries the qualities. The same
  indirection satisfies plain `tools` requirements.
- **Proficiency effects.** A `bonuses: { "<category>": … }` block is
  consumed in usually exactly one place; grep the category string in
  `src/` to bound the entire effect in one call.
- **Character flags.** `Character::has_flag` unions traits, bionics,
  effects, body parts and martial-arts buffs, and is separate from
  `worn_with_flag` for gear. Check the right namespace, and all of it.
- **A flag in `flags.json` may be inert.** It can have no vanilla user,
  no C++ consumer, or exist only for mods. Confirm both sides before
  describing an effect as live.
- **Skill ids are not display names.** 21 differ — `swimming` is
  athletics, `gun` is marksmanship, `traps` is devices, `firstaid` is
  health care, `chemistry` is applied science.

## Citing answers

Cite `file:line` for every claim, and note the commit the answer was
verified at. This clone tracks an active upstream, so line numbers
drift — a citation without a SHA rots silently into a wrong answer.

Current reference point: `0.I` at `27939e29b8`.

## Vanilla vs mods

Default to vanilla (`data/json/`). If something in `data/mods/` changes
the answer, say so explicitly and name the mod. Never present modded
behavior as base-game behavior.

## Recording what you learn

**Memory is not an answer cache.** Do not write an entry to make the same
question cheaper next time; write one only when it makes a *different*
question cheaper. After answering, ask what was slow to **find**, not
what the answer was.

Worth saving: routing and detours, how a core system works in general,
and traps that produce confidently wrong answers. Not worth saving: the
answer itself, item values, per-item tables, anything re-derivable in one
`cdda-q` call.

Prefer extending an existing system entry over adding a sibling. Keep
memory CDDA-specific — nothing here belongs in a host's global
`CLAUDE.md`. Durable, general orientation rules go in this file; memory
holds the more specific layer beneath it.

Entries live in `.claude/memory/`, one file each, indexed by
`.claude/memory/MEMORY.md`. **Write the entry there and commit it** —
an uncommitted entry is lost to every other session, and on this machine
the host's auto-memory path is a symlink to that same directory, so
there is exactly one copy to keep straight.
