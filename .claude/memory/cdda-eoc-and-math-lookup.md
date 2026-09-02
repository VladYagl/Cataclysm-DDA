---
name: cdda-eoc-and-math-lookup
description: "How to trace a CDDA JSON string, EOC effect key, or u_*() math function back to the C++ that implements it"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b73c37c3-98af-40d2-8ee3-c244cac42b34
  modified: 2026-09-02T00:00:00.000Z
---

The reliable route from player-visible text or JSON to C++, verified at
`master` / `a724a08d5f`:

1. `git grep` the exact message. Player text usually lands in
   `data/json/snippets/`, where a `"category"` groups interchangeable
   strings — the category, not the wording, is what carries meaning.
2. Grep the category name across `data/` to find its consumer. Modern
   flavor and trigger logic lives in
   `data/json/effects_on_condition/`, referenced with
   `{ "u_message": "<category>", "snippet": true }`.
3. EOC effect keys are registered in a table at `src/npctalk.cpp:8595`
   mapping each JSON key to a `talk_effect_fun::f_*` implementation
   (for example `"switch"` -> `f_switch` at `src/npctalk.cpp:7275`).
4. Math functions used in `{ "math": [ … ] }` and `"switch"` are
   registered in a table at `src/math_parser_diag.cpp:1840` mapping the
   name to its `*_eval` / `*_ass` pair.
5. Those eval functions call through a `talker`, not `Character`
   directly. `src/talker_character.cpp` is the bridge — and the names
   often differ, e.g. `u_health()` -> `talker::get_health()` ->
   `Character::get_lifestyle()`. Grepping the JSON name against
   `Character` alone will miss it.

Semantics worth not re-deriving: an EOC `"switch"` iterates cases in
declaration order and keeps the **last** one where `value >= case`
(`src/npctalk.cpp:7286-7295`), so ascending cases behave as "highest
match wins", and a value below the lowest case matches nothing and
silently does nothing.

Applied example: [[cdda-health-lifestyle-system]].

## EOC dispatch: which ones actually run

Only `RECURRING` EOCs are auto-queued per character
(`src/effect_on_condition.cpp:164`, and `load_existing_character` at
`:207`). An EOC with no `recurrence` and no `eoc_type` loads as
`ACTIVATION` (`src/effect_on_condition.cpp:88`) and runs **only when
something references it by id**. So before describing an EOC's effect,
grep its id across `data/` and `src/`: an `ACTIVATION` EOC with no
caller is dead code, however complete its logic looks. Live example at
`27939e29b8`: `EOC_DERMATIK_FORMICATION`
(`data/json/effects_on_condition/effects_eocs.json:139`) is written to
make a dermatik infestation itch and never fires.

`EVENT` EOCs are the other half of the answer. `"eoc_type": "EVENT"` +
`"required_event": "character_gains_effect"` / `"character_loses_effect"`
+ a `compare_string` on `{ "context_val": "effect" }` is the idiom that
carries an entire effect's lifecycle in JSON. **Grepping an effect id in
`src/` can come back nearly empty while all its behavior sits in
`data/json/effects_on_condition/`** — dermatik's incubation, birth,
larva spawn and cure-side cleanup are all there, with C++ contributing
only the drug and trait cures.

## Effect intensity driven by a vitamin

Some effects have no intensity logic of their own: a vitamin declares
`"excess": <effect_id>` (or `"deficiency"`) plus `disease_excess` /
`disease` bands, and `vitamin::severity()` (`src/vitamin.cpp:36`) maps
the counter to a level that `Character::update_vitamins()`
(`src/character.cpp:8697`) applies via `add_effect` / `set_intensity`.
So the answer to "what makes this effect worse over time" is in
`data/json/vitamin.json`, not in the effect definition. A
`"vit_type": "counter"` vitamin is the usual carrier, filled by a
`vitamins` block on some other effect.

Two consequences worth not re-deriving:

- `update_vitamins` adds the effect with **no body part**, so
  `u_effect_intensity('<eff>', 'bodypart': X)` returns −1 —
  `Creature::get_effect` keys on the body part
  (`src/creature.cpp:2049`).
- An effect's `*_amount` mod fires only on the turn it is applied
  (`is_new` → `get_amount`); ongoing turns read `*_min`/`*_max`, so a
  `pain_amount` with no `pain_min` is a one-shot, not a per-turn drain
  (`src/character.cpp:10935`, used at `:11049`).
