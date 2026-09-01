---
name: cdda-health-lifestyle-system
description: "How CDDA's hidden health/lifestyle stat works and where its code and data live"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b73c37c3-98af-40d2-8ee3-c244cac42b34
  modified: 2026-08-14T08:26:38.926Z
---

The hidden "health" stat players see as wake-up flavor text is
`Character::lifestyle`. Verified at `master` / `a724a08d5f`.

- `Character::get_lifestyle()` — `src/character_health.cpp:728`. Returns
  stored `lifestyle` minus BMI penalties: `5 *` points over obese, and
  `50 *` points under normal — underweight is punished 10x harder than
  overweight. Floored at -200.
- `Character::update_health()` — `src/character_health.cpp:1253`. Daily
  health accumulates (clamped ±200), then once a day only *one seventh*
  of the tally moves `lifestyle`. It is a ~week moving average, so it
  never shifts overnight.
- `mod_daily_health( mod, cap )` — `src/character_health.cpp:770`. The
  `cap` is a per-effect ceiling in that direction, not a total.
- Inputs to daily health: sleep hours (`src/character_body.cpp:283-291`,
  doubled after 6+ continuous hours, capped +10), a -4/day sedentary
  penalty for never dropping below half stamina
  (`src/character_body.cpp:304`), cardio accumulator
  (`src/character_body.cpp:311-326`), comestible `healthy` values
  (`src/consumption.cpp:1385`), and addictions (`src/addiction.cpp`).

Starting values: `lifestyle` defaults to 0 via the member initializer at
`src/character.h:4123`, and nothing in character creation overrides it.
Effective lifestyle is also exactly 0, because `Character::initialize()`
sets calories to `get_healthy_kcal()` (`src/newcharacter.cpp:918`) and
the healthy-kcal and bmi-fat formulas cancel to `bmi_fat = 5.0` for
every height and body size — which falls in the penalty-free gap between
`normal = 3.0` and `obese = 10.0` (`src/game_constants.h:174-179`).
Exception: the XS and XXXL traits scale starting calories by 1/5 and 5x
(`src/newcharacter.cpp:919-924`), giving `bmi_fat` 1.0 and 25.0, so
those characters start at roughly -100 and -75 effective and wake to the
worst message from day one. Do not cite `set_lifestyle( 0 )` at
`src/character_health.cpp:3434` for any of this — that line is inside
`environmental_revert_effect()`, a cleanup routine, not creation.

Wake-up messages are pure flavor, not a separate mechanic:
`data/json/effects_on_condition/dream_eocs.json:22`
(`EOC_GIVE_HEALTH_MESSAGE`) fires on the `character_wakes_up` event and
switches on `u_health()`, pulling a snippet from
`data/json/snippets/health_msgs.json`. Bands: >=200 great, 100 very
good, 50 good, 10 silent, -10 bad, -50 very bad, -100 horrible. Two
traps worth remembering: the `health_bad` band spans -10..9 so a neutral
lifestyle of 0 still prints a bad message, and values below -100 match
no case at all so nothing prints. Suppressed during cold/flu and when a
nightmare already fired that sleep.

The JSON and the C++ disagree on tone for the -10..9 band. The engine
constant for it is named `fine` (`src/game_constants.h:189`) and the
sidebar readout prints "Feel Fine" in neutral gray for anything above
-10 (`src/display.cpp:769-796`), while the wake-up EOC calls the same
range `health_bad` with `"type": "bad"`. Note also that the display uses
strict `>` while the EOC switch uses `>=`, so they differ at exact
boundary values.

See [[cdda-eoc-and-math-lookup]] for the general path from a JSON
`u_*()` math function to its C++ implementation.
