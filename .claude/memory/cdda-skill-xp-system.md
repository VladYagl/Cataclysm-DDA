---
name: cdda-skill-xp-system
description: "How CDDA skill XP works — practical vs theoretical levels, the XP curve, what trains which, and the book-field grep trap"
metadata:
  node_type: memory
  type: reference
---

Answers any "how do I level skill X" question. Verified at `27939e29b8`.

## Two levels per skill

Every skill carries a *practical* level (`_level`/`_exercise`) and a
*theoretical* / knowledge level (`_knowledgeLevel`/`_knowledgeExperience`)
— `src/skill.h:154,244`. The number that gates recipes and most checks is
the practical one (`get_skill_level`); `get_knowledge_level` is theory.

- **Theory only**: reading books (`SkillLevel::readBook`,
  `src/skill.cpp:429` → `knowledge_train`, `src/skill.cpp:339`) and NPC
  dialogue previews. A book can never raise practical level.
- **Practical**: `Character::practice()`, `src/character.cpp:2804`, which
  also drags knowledge along (`knowledge_amount` capped at 0.9×catchup,
  `src/skill.cpp:313`).
- NPC training (`activity_handlers::train_finish`,
  `src/activity_handlers.cpp:822`) is the exception that *does* give
  practical xp: `practice( sk, 100, knowledge_level + 2 )`.

## The numbers

- Level-up threshold: `10000 * (level+1)^2` exercise points
  (`SkillLevel::on_exercise_change`, `src/skill.cpp:455`). 0→3 = 140,000.
- `practice()` scales its argument: `adjust_for_focus(min(1000,amt)) * 100`
  (`src/character.cpp:2837`), i.e. ×100 at focus 100. Focus is stored
  ×1000 (`src/character.h:2818`).
- Catch-up: if knowledge > practical, xp is multiplied by
  `catchup_modifier * (knowledge/level)` where
  `catchup_modifier = 1 + (2*INT + PER)/24` (`src/character.cpp:2818`,
  `src/skill.cpp:288`). **Reading the theory book first is worth 2–6× the
  grind rate** — the single biggest lever on any "how do I level" answer.
- Focus drain per practice call, and `SKILL_TRAINING_SPEED` /
  `INT_BASED_LEARNING_*` in `data/core/external_options.json`.
- Modifiers: PACIFIST /3 on combat skills, SAVANT ×0.5 off your best
  skill, `PRED4` skips focus drain, `COMBAT_CATCHUP` enchantment.

## Practice recipes

`data/json/recipes/practice/*.json`, type `"practice"`. The ceiling is
`practice_data.skill_limit`, and `recipe::get_skill_cap()`
(`src/recipe.cpp:71`) returns `skill_limit - 1` as the `cap` argument to
`practice()` — so a recipe with `"skill_limit": 1` trains only while you
are level 0. Check `skill_limit` before claiming a practice recipe can
carry a skill anywhere.

## Traps

- **Books do not have a `"skill"` field.** Since the ITEM/subtypes
  rewrite the fields are `read_skill`, `max_level`, `min_level`,
  `intelligence`, `time`, `read_fun` (`src/item_factory.cpp:3362,3369`).
  Grepping `"skill": "<id>"` for books returns nothing but npc_class
  hits. Grep `read_skill` instead.
- Only one `practice( skill_x, … )` call site usually exists per combat
  skill — grep `skill_<id>` in `src/` to enumerate every trainer in one
  call. For guns it is `src/ranged.cpp:1209`.
- NPC teachers must have practical level > your *knowledge* level
  (`Character::skills_offered_to`), cost
  `1000*(1+knowledge)^2` cents, free from a friendly/follower teacher
  (`src/npctalk.cpp:550`), 6h `asked_to_train` cooldown.
- `faction_camp.cpp` / `mission_companion.cpp` uses of a skill id are
  companion-mission math, not player training.
