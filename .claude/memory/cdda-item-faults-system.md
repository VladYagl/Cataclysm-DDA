---
name: cdda-item-faults-system
description: "How CDDA item faults work — assignment, damage mods, repair fixes, and the traps when identifying a fault by its display name"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b73c37c3-98af-40d2-8ee3-c244cac42b34
  modified: 2026-08-14T09:17:55.039Z
---

Item faults, verified at `master` / `a724a08d5f`.

Data lives in `data/json/faults/`: `faults_*.json` define faults,
`fault_groups_*.json` define weighted groups, `fault_fixes_*.json`
define repairs. Items reference a group via
`"faults": [ { "fault_group": "<id>" } ]`, and `copy-from` items inherit
it silently.

**Fault display names are not unique.** Several faults share one `name`
string, so a player report like "Broken handle" can map to multiple
faults with very different penalties — for the `handle_long` group,
`fault_handle_long_broken_half` (major, suffix "snapped", bash x0.7)
versus `fault_handle_long_broken` (critical, suffix "no handle", bash
x0.3). Always disambiguate by `item_suffix` or the description, never by
name alone, and use the group weights to say which is more likely.

Code paths:

- Assignment: `item::set_random_fault_of_type()` —
  `src/item_degrade.cpp:388`. Rolled on every damage event, once per
  `damage_scale` step (`src/item_degrade.cpp:873-877`). Uses only the
  static group weights.
- `item::can_have_fault()` — `src/item_degrade.cpp:345`. Enforces
  `block_faults`, which is how a severe fault displaces and locks out
  milder ones.
- Melee penalty: `item::damage_adjusted_melee_weapon_damage()` —
  `src/item_degrade.cpp:225`. Applies each `melee_damage_mod` as
  `(value + add) * multiply`, then a further -10% per damage level
  above 1.
- Name rendering: `faults_suffix` — `src/item_tname.cpp:82`.

**Doc/code mismatch to remember:** `"affected_by_degradation"` is
documented at `doc/JSON/JSON_INFO.md:1678` as adding item degradation to
the fault roll weight, but `fault::affected_by_degradation()` has no
callers anywhere in `src/` — the behavior is unimplemented. Degradation
does not currently raise the odds of severe faults. The similarly named
`degradation_mod` *is* live, at `src/item_degrade.cpp:194`. This is a
good reminder that JSON_INFO.md documents intent, not guaranteed
behavior — confirm a field has a caller before explaining it.

See [[cdda-eoc-and-math-lookup]] for the general JSON-to-C++ tracing
route.
