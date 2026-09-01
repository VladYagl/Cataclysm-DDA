---
name: cdda-weapon-skill-selection
description: "How CDDA decides which melee skill a weapon uses — highest melee damage type wins, no skill field exists"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2a34726d-a747-45da-850d-d5521158d195
  modified: 2026-08-25T07:46:58.093Z
---

Melee weapons have **no** `"skill"` field. `item::melee_skill()`
(`src/item.cpp:11071`, at `27939e29b8`) returns the skill of whichever
damage type has the highest `damage_melee()` value; each type names its
skill in `data/json/damage_types.json` (bash→bashing, cut→cutting,
stab→stabbing, parsed at `src/damage.cpp:115`). Guns are the opposite:
`gun->skill_used`, explicit (`src/item.cpp:11044`).

Gates and nuances:

- `is_melee()` requires some type > `MELEE_STAT` = 5
  (`src/item.cpp:10166`, `src/game_constants.h:104`); below that the
  skill is null and only generic `melee` applies.
- Ties go to the earlier-defined type (strict `>`), i.e. bash first.
- `melee_skill()` only feeds the to-hit roll (`src/melee.cpp:362`).
  Damage uses each damage type's *own* skill (`src/melee.cpp:1279`),
  and XP is split proportional to damage share (`src/melee.cpp:504`).
- Unarmed comes from the attack vector, not the item
  (`src/melee.cpp:501`, `1276`).
- Bayonet on a gun takes per-type max (`src/item.cpp:7626`), can flip
  the skill.
- `weapon_category` is martial arts / proficiencies only — unrelated.
  See [[cdda-weapon-proficiencies]].

In-game: the `Melee damage: Bash: X  Cut: Y  Pierce: Z` line
(`src/item.cpp:5487`) is the only clue; there is no "Skill used" line
for melee.
