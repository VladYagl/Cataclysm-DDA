---
name: cdda-eoc-and-math-lookup
description: "How to trace a CDDA JSON string, EOC effect key, or u_*() math function back to the C++ that implements it"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b73c37c3-98af-40d2-8ee3-c244cac42b34
  modified: 2026-08-14T08:20:38.246Z
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
