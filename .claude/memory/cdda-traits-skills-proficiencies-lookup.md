---
name: cdda-traits-skills-proficiencies-lookup
description: "Where CDDA traits, skills and proficiencies live, how each reaches C++, and the id-vs-display-name trap"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 059bf2c5-2638-4a93-9a93-9231ea385af3
  modified: 2026-08-28T09:47:47.134Z
---

The three character-progression systems, their data homes and their code
entry points. Verified at `27939e29b8`. Loader registrations are all in
`DynamicDataLoader::initialize`, `src/init.cpp`.

| System | JSON | `init.cpp` | Doc |
| --- | --- | --- | --- |
| Traits/mutations | `data/json/mutations/` | `:301` `mutation` | `MUTATIONS.md` |
| Skills | `data/json/skills.json` | `:296` `skill` | — |
| Proficiencies | `data/json/proficiencies/` | `:292` `proficiency` | `PROFICIENCY.md` |
| Flags | `data/json/flags.json` | `:266` `json_flag` | `JSON_FLAGS.md` |

**Traits.** `Character::has_trait( trait_id )` lives in
`src/mutation.cpp:126`, not `character.cpp`. But most trait *effects*
reach code as flags rather than trait ids — see
[[cdda-character-flag-sources]] — so grep the flag before the trait id.

**Skills: the id is usually not the display name.** 21 of them differ,
and grepping the name the player used will silently find nothing:

`swimming`→athletics, `gun`→marksmanship, `firstaid`→health care,
`traps`→devices, `chemistry`→applied science, `driving`→vehicles,
`speech`→social, `cooking`→food handling, `tailor`→tailoring,
`computer`→computers, `throw`→throwing, `dodge`→dodging,
`bashing`/`cutting`→…weapons, `stabbing`→piercing weapons,
`unarmed`→unarmed combat, plus the gun subskills (`pistol`→handguns,
`smg`→submachine guns, …).

`swimming` being the athletics skill is the one that bites hardest:
athletics practice recipes and muscle-vehicle pedaling both grant
*swimming* XP, which reads as a bug and is not. All real XP multipliers
(focus, INT/PER catch-up, PACIFIST, SAVANT) are in `Character::practice`,
`src/character.cpp:2804` — the call sites only pass a raw amount.

**Proficiencies.** Three separate wiring paths, and a given proficiency
usually uses only one:

- `bonuses: { "<category>": [ { type, value } ] }` — **grep the category
  string in `src/`; there is typically exactly one consumer.** `athlete`
  resolves only to muscle-engine power in `vehicle.cpp`; `archery` only
  to `item::get_min_str` in `item.cpp`. This one grep bounds the entire
  effect and is the fastest way to refute "it probably also helps
  accuracy".
- `default_time_multiplier` / `default_skill_penalty` — crafting only,
  and inert unless some recipe references the proficiency. See
  [[cdda-proficiency-crafting-maluses]].
- `bonuses.melee_attack.stamina` for weapon categories —
  [[cdda-weapon-proficiencies]].

**`can_learn: false` is a hard wall that NPC training hides.**
`proficiencies_offered_to` filters on `is_teachable` only
(`src/character_proficiency.cpp:127`), so an NPC will happily offer to
teach a chargen-only proficiency, run the activity, print success, and
grant nothing — `proficiency_set::practice` rejects it at
`src/proficiency.cpp:309`. Check that line before ever saying an NPC can
teach something.

Training call sites are per-system and easy to miss: melee in
`src/melee.cpp:973`, archery during *aiming* in `src/ranged.cpp:1711`,
plus the `data/json/recipes/practice/` recipes for most ladders.

Related: [[cdda-json-query-tool]], [[cdda-weapon-skill-selection]].
