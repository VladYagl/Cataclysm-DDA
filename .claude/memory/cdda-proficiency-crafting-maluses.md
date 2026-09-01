---
name: cdda-proficiency-crafting-maluses
description: "How CDDA proficiency time_multiplier and skill_penalty actually affect crafting, including the largely inert skill penalty"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b73c37c3-98af-40d2-8ee3-c244cac42b34
  modified: 2026-08-28T09:51:08.548Z
---

Verified at `master` / `a724a08d5f`. Proficiencies are defined in
`data/json/proficiencies/`, documented in `doc/JSON/PROFICIENCY.md`, and
referenced per-recipe with optional `time_multiplier` / `skill_penalty`
overrides of the proficiency's `default_*` values.

**Time malus** — `proficiency_time_malus()`, `src/recipe.cpp:1495`.
Returns `1.0` immediately if the crafter (or a helper) has the
proficiency, so the full `time_multiplier` applies only when lacking it.
Partial learning progress is mitigated by a sigmoid,
`malus *= 1 - (0.5 - 0.5*cos(pl*pi))^2`, which barely helps below
`pl = 0.5`. Books reduce it via `time_factor`.

**Skill penalty is not a skill penalty.** `proficiency_skill_malus()`
(`src/recipe.cpp:1656`) is consumed in only two places: the crafting GUI
display, and a *boolean* `> 0.0f` test in
`should_add_crafting_faults()` (`src/craft_command.cpp:471`). That flags
the craft `FAULT_ON_COMPLETION`, and on completion
`set_random_fault_of_type( "crafting_defect" )` runs on the result
(`src/crafting.cpp:2590`). It does not reduce effective skill and its
magnitude does not matter — only whether it is nonzero. Books are
deliberately ignored for this check.

**And that fault path is nearly always a no-op.** Only three
`crafting_defect` faults exist (`data/json/faults/faults_melee.json`),
all blade-related, bundled as the `bladed_weapon_craft_failures` group,
which exactly one item uses: `mc_katana`
(`data/json/items/melee/swords_and_blades.json:2770`).
`set_random_fault_of_type` does nothing when the item's own fault list
has no fault of that type (`src/item_degrade.cpp:404`). So for virtually
every recipe, `skill_penalty` has no observable effect and the time
multiplier is the entire mechanical impact of a proficiency.

Fault mechanics: [[cdda-item-faults-system]]. Where proficiencies live
and the other two wiring paths:
[[cdda-traits-skills-proficiencies-lookup]].
