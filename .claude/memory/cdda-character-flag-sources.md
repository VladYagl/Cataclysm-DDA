---
name: cdda-character-flag-sources
description: "Character::has_flag unions five different sources, so answering 'what grants flag X' means checking all five"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 059bf2c5-2638-4a93-9a93-9231ea385af3
  modified: 2026-08-28T09:47:26.288Z
---

`Character::has_flag( json_character_flag )` at `src/character.cpp:12085`
is a union of **five** independent sources (verified at `27939e29b8`):

```cpp
return has_trait_flag( flag ) || has_bionic_with_flag( flag ) ||
       has_effect_with_flag( flag ) || has_bodypart_with_flag( flag ) ||
       has_mabuff_flag( flag );
```

**Why it matters:** a question like "how do I get GLARE_RESIST" cannot be
answered from one data directory. That flag comes from a bionic
(`bio_sunglasses`, `data/json/bionics.json`) in vanilla and from several
mod *effects*. Checking only `data/json/mutations/` would have returned
nothing and produced a confidently wrong "you can't".

**How to apply.** For any `json_character_flag`, sweep all five layers —
`cdda-q find 'has_flag("X")' --mods` covers traits, bionics, effects and
bodyparts in one pass, since they are all JSON objects with a `flags`
array. Then confirm the consumer side in `src/`. Note `count_flag`
(`:12097`) is the stacking variant.

Two traps that keep recurring:

- **Worn-item flags are a different namespace.** `worn_with_flag(
  flag_X )` scans equipment and is unrelated to `has_flag`. Glare checks
  both (`src/weather.cpp:104-110`): `worn_with_flag( SUN_GLASSES )` for
  gear, `has_flag( GLARE_RESIST )` for the character. Grepping only one
  gives half the answer.
- **A flag existing in `data/json/flags.json` proves nothing.** It may
  have no JSON user, no C++ consumer, or exist only for mods. `STR_DRAW`
  is defined in vanilla, read by `item::gun_range` — and carried by zero
  vanilla items, only Magiclysm and Aftershock. Always confirm both a
  data user and a code consumer before describing an effect as live. The
  same failure mode as the unimplemented `affected_by_degradation` field
  in [[cdda-item-faults-system]].

Related: [[cdda-json-query-tool]], [[cdda-eoc-and-math-lookup]].
