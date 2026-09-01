---
name: cdda-item-source-tracing
description: "How to find every in-game source of a CDDA item id — recipes, loot groups, furniture, NPC shops."
metadata: 
  node_type: memory
  type: reference
  originSessionId: bf4b44a2-2071-4451-a751-fb479a92c1ad
  modified: 2026-08-17T09:02:07.765Z
---

To answer "where do I get X" in CDDA, `git grep -n '"<item_id>"' -- data/`
and sort the hits into five buckets — no single one is complete:

- `"result": "<id>"` in `data/json/recipes/` — the craft. Absence is
  meaningful: some items are only reachable via a two-stage
  intermediate (e.g. `long_pole` only comes from `soaking_long_pole`
  plus a `delayed_transform` use_action).
- `data/json/itemgroups/` — loot spawns. No hit means it never spawns
  as ordinary loot.
- `data/json/furniture_and_terrain/` — a furniture's `"item"` field
  (loaded into `base_item`, `src/mapdata.cpp:1339`) is what
  deconstruction returns; pair it with `EASY_DECONSTRUCT` for a
  no-tools source. Grep the furniture id in `data/json/mapgen*/` to
  find where it spawns.
- `data/json/npcs/**` — `shopkeeper_item_group` stock plus
  `shopkeeper_price_rules` gives merchants and prices.
- `data/json/construction/` — hits here are usually *consumers*, not
  sources.

Related: [[cdda-knowledge-routing]], [[cdda-eoc-and-math-lookup]].
