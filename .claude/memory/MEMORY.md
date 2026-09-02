# Memory index

Routing, system mechanics, and traps — not per-question answers. See
[CDDA knowledge routing](cdda-knowledge-routing.md) for the rule.

## Working in this repo

- [CDDA reference clone purpose](cdda-reference-clone-purpose.md) — the
  fork answers questions from source on any machine; it is not a
  development checkout.
- [CDDA knowledge routing](cdda-knowledge-routing.md) — memory is for
  navigation, not answers; what to write and what to leave out.
- [CDDA JSON query tool](cdda-json-query-tool.md) — `cdda-q` answers
  "which entities have property X" in one call; vanilla-only by default,
  does not resolve `copy-from`.

## Finding things

- [CDDA trait/skill/prof lookup](cdda-traits-skills-proficiencies-lookup.md)
  — where each lives, the skill id vs display name trap, and the
  one-grep way to bound a proficiency's entire effect.
- [CDDA character flag sources](cdda-character-flag-sources.md) —
  `has_flag` unions five layers, and a flag in flags.json may be used by
  nothing.
- [CDDA item source tracing](cdda-item-source-tracing.md) — the five
  buckets that answer "where do I get X".
- [CDDA tool quality sources](cdda-tool-quality-sources.md) — furniture
  satisfies qualities through a pseudo-item, so the obvious grep misses.
- [CDDA gun magazine lookup](cdda-gun-magazine-lookup.md) — magwell
  `item_restriction` is a whitelist, guns spawn with their default mag,
  and the magazine loot-group tiers.
- [CDDA EOC and math lookup](cdda-eoc-and-math-lookup.md) — tracing a
  JSON string or `u_*()` math function back to the C++ behind it.

## System mechanics

- [CDDA crafting speed system](cdda-crafting-speed-system.md) — the full
  multiplier chain and the workbench mass/volume penalty.
- [CDDA proficiency crafting maluses](cdda-proficiency-crafting-maluses.md)
  — time multiplier is the real effect; skill_penalty is nearly inert.
- [CDDA weapon proficiencies](cdda-weapon-proficiencies.md) — melee
  category ladders affect stamina only, never accuracy or damage.
- [CDDA weapon skill selection](cdda-weapon-skill-selection.md) — no
  skill field; the highest melee damage type picks the skill.
- [CDDA item faults system](cdda-item-faults-system.md) — fault groups,
  damage mods, repairs, and a documented field with no caller.
- [CDDA armor absorption and ablative plates](cdda-armor-absorption-and-ablative.md)
  — the design doc that maps the whole pipeline, and how plate inserts
  and `non_functional` transforms work.
- [CDDA health/lifestyle system](cdda-health-lifestyle-system.md) — the
  hidden health stat, its BMI penalties, and the wake-up message bands.
