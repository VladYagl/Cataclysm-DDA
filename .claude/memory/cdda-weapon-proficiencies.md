---
name: cdda-weapon-proficiencies
description: "How CDDA melee weapon-category proficiencies work — stamina only, no accuracy or damage effect"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b73c37c3-98af-40d2-8ee3-c244cac42b34
  modified: 2026-08-28T09:51:04.636Z
---

Verified at `master` / `a724a08d5f`. Melee weapon proficiencies are
wired through `data/json/weapon_categories.json`, where each
`weapon_category` lists a familiar/pro/master proficiency ladder. Items
opt in via their `"weapon_category"` array, and an item may belong to
several.

**Their only effect is melee stamina cost.**
`Character::get_total_melee_stamina_cost()` (`src/melee.cpp:1001`) sums
the `bonuses.melee_attack.stamina` values of proficiencies you actually
have in each category, then
`proficiency_multiplier = clamp( 1 - loss, 0, proficiency_multiplier )`.
Because the running value is the upper bound, categories do not stack —
a multi-category weapon gets the single best (lowest) multiplier — while
tiers within one category do stack. The check is `has_proficiency`, so
partial learning progress gives nothing.

**There is no accuracy, damage, or to-hit penalty for lacking one.**
`category_proficiencies()` has exactly two call sites in the codebase,
both in `src/melee.cpp`: training at `:975` and the stamina calc at
`:1015`. `bonus_for( "melee_attack", stamina )` has one consumer,
`src/melee.cpp:1019`. Do not assume a weapon proficiency behaves like it
would in other games.

Training: each melee attack calls `practice_proficiency( prof,
1_seconds )` for every tier in the category (`src/melee.cpp:973-977`),
with `required_proficiencies` gating which one accumulates. Proficiency
JSON carries the comment "Code assumes each attack is 1s", so
`time_to_learn` in seconds reads directly as a number of attacks.

Note the inversion versus crafting proficiencies: combat proficiencies
still declare `default_time_multiplier` and `default_skill_penalty`, but
those are inert unless some recipe references the proficiency. Always
check which side is actually wired up. See
[[cdda-proficiency-crafting-maluses]] and
[[cdda-traits-skills-proficiencies-lookup]].
