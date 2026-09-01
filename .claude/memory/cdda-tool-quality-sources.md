---
name: cdda-tool-quality-sources
description: "How a CDDA tool quality requirement gets satisfied — items, furniture pseudo-items, vehicle parts — and why furniture is the easy one to miss"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 059bf2c5-2638-4a93-9a93-9231ea385af3
  modified: 2026-08-28T09:48:02.353Z
---

When a recipe, construction or butchery step demands a quality
(`{ "id": "SURFACE", "level": 3 }`), it is satisfied from the crafting
inventory, which is wider than the player's pockets. Verified at
`27939e29b8`.

Four sources, and **furniture is the one that gets missed**:

- **Carried or nearby items** — the item's own `qualities` array. Both
  spellings occur: `[["SURFACE", 3]]` and `[{"id": …, "level": …}]`.
- **Furniture** — via `crafting_pseudo_item`, naming a fake item in
  `data/json/items/tool/pseudo.json` that carries the qualities. This is
  the indirection that costs a search every time: grepping `SURFACE` in
  `furniture_and_terrain/` returns **nothing**, because the furniture
  only names `large_surface_pseudo`. Always resolve the pseudo item.
- **Vehicle parts** — `qualities` on the part, e.g. kitchen units and
  welding rigs.
- **Bionics** — `passive_pseudo_items`, e.g. `bio_sunglasses` supplying
  `fake_goggles`.

`cdda-q quality SURFACE` returns all of these plus the requirement
objects that *demand* it, in one call ([[cdda-json-query-tool]]).

**The same `crafting_pseudo_item` mechanism also satisfies plain `tools`
requirements**, not just qualities — training dummies work exactly this
way, letting a melee practice recipe require furniture in range. If a
recipe seems to demand a tool that has no item form, look for furniture.

**Quality requirements are usually a soft gate, not a hard one.** Check
whether the requirement id has a `_no_surface`-style sibling before
saying something is impossible. Butchery is tiered by *time multiplier*
in `data/json/butchery_requirements.json`, keys `1.0` and `1.2`;
`get_fastest_requirements` (`src/butchery_requirements.cpp:99`) walks
tiers ascending and takes the first satisfiable one, so a missing surface
costs 20% time rather than blocking.

Do not confuse the `SURFACE` quality with crafting speed. They are
unrelated systems: `SURFACE` is butchery-only (zero recipes reference
it), while crafting speed comes from the furniture `workbench` property —
[[cdda-crafting-speed-system]].

Related: [[cdda-item-source-tracing]].
