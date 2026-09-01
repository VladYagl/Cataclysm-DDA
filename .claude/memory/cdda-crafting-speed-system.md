---
name: cdda-crafting-speed-system
description: "The full multiplier chain that sets CDDA crafting speed, and the workbench mass/volume penalty"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 059bf2c5-2638-4a93-9a93-9231ea385af3
  modified: 2026-08-28T09:48:16.933Z
---

Crafting speed is one product, assembled in
`Character::crafting_speed_multiplier` (`src/crafting.cpp:329-360`,
verified at `27939e29b8`):

```
light x bench x morale x enchantment x limb_score(manip) x pain
```

Each factor has a recipe-level opt-out flag — `NO_BENCH`, `NO_MANIP`,
`AFFECTED_BY_PAIN`, `NO_ENCHANTMENT`, `BLIND_EASY` — so before
explaining a factor, check whether the recipe disables it. In vanilla
`NO_BENCH` is used by **no** recipe at all (Aftershock esper practice
only), a good instance of the flag-exists-but-unused trap in
[[cdda-character-flag-sources]].

**The bench factor** comes from `workbench_crafting_speed_multiplier`
(`:248-300`), which resolves the crafting location in a fixed order:
`std::nullopt` (crafting from inventory) → the `f_fake_bench_hands`
furniture stats; then a vehicle part with the `WORKBENCH` feature; then
the tile's furniture `workbench` property; else `f_ground_crafting_spot`.

The two invisible spots are the ones people miss: **crafting from
inventory is 1.0x but capped at 5 kg / 10 L**, and **bare ground is a
flat 0.7x** with effectively unlimited capacity. Ranking otherwise:
`f_workbench` 1.2, lab bench 1.15, table/counter/desk/cupboard 1.1,
folding table 1.05, tarps and coffee table 0.85, black glass desk 0.7.

Over the furniture's `mass`/`volume` limits, `lerped_multiplier`
(`:233-245`) interpolates linearly from 1.0 at the limit down to **0.25x
at 1000 kg / 1000 L**. Two escapes worth knowing:

- A nearby `LIFT`-quality tool or rideable mech that can lift the craft's
  mass returns the raw multiplier and **skips both the mass and volume
  penalties entirely** (`:291-294`, `best_nearby_lifting_assist`).
- Below 0.1x the craft aborts outright with "too large and/or heavy to
  work on" (`:356-359`).

`workbench` on furniture must be paired with an `examine_action` of
`workbench` to function (`doc/JSON/JSON_INFO.md:3374`) — a furniture with
the property but no examine action is a false positive.

Unrelated despite the name overlap: the `SURFACE` "clean surface"
quality does nothing for crafting, only butchery —
[[cdda-tool-quality-sources]].
