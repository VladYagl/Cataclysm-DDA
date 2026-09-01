---
name: cdda-armor-absorption-and-ablative
description: "Where the CDDA armor damage pipeline is documented and coded, and how ablative plate inserts (ballistic vests, Hub 01, chainmail) work"
metadata: 
  node_type: memory
  type: reference
  originSessionId: c6cfc2d7-c624-4754-9989-77610652ac98
  modified: 2026-09-01T00:00:00.000Z
---

Armor routing, verified at `27939e29b8`.

## Start at the design doc, not `doc/JSON/`

`doc/design-balance-lore/` is a second documentation directory beyond
`doc/JSON/`, and armor questions start there:
`ARMOR_BALANCE_AND_DESIGN.md` carries the numbered damage-absorption
order, the layering/encumbrance rules and the flag tables. The same
numbered list is duplicated at `doc/DEVELOPER_FAQ.md:55-70` — either
copy is the map for coverage, sublimb selection, `cover_vitals`,
multi-material thickness, and where ablative plates enter.

That directory also holds `GAME_BALANCE.md`, `STEEL_CRAFTING.md`,
`melee_weapons/` and the lore docs — worth remembering for any
"why is it balanced this way" question.

## The absorb call chain

- `Character::absorb_hit` (`src/character_armor.cpp:137`) →
  `outfit::absorb_damage`
  (`src/character_attire.cpp:1886`) — one `rng(1,100)` roll per attack,
  reused by every layer; iterates `worn` in reverse (outermost first).
- Per item: ablative plates first (`Character::ablative_armor_absorb`,
  `src/character_armor.cpp:287`), then the garment itself
  (`Character::armor_absorb`, `src/character_armor.cpp:209`/`249`).
- Sub-body-part coverage is the unit of resolution; the torso also gets
  a `secondary_sbp` for gear hanging off the character.

## Ablative inserts

One system covers ballistic vests, Hub 01 modular rigs, chainmail
inserts, helmets and mi-go carapace. Three parts, and only the first is
greppable from the carrier:

1. Carrier pocket: `"ablative": true` plus `flag_restriction`
   (`ABLATIVE_LARGE` / `ABLATIVE_MEDIUM` / `ABLATIVE_MANTLE` /
   `ABLATIVE_SKIRT` / `ABLATIVE_CHAINMAIL_*` / `ABLATIVE_HELMET`).
2. Insert: normal armor carrying that flag **plus `CANT_WEAR`**, so it
   is never worn directly (`src/character_attire.cpp:110`).
3. Insertion is the ordinary "Insert item" action (`v`), gated by the
   pocket's volume/weight/length caps and `moves`.

Behavior worth knowing before answering:

- **At most one plate mitigates a given hit.** The shared roll is tested
  against each plate's coverage and *decremented* on a miss, then passed
  to the next pocket.
- **Plate encumbrance is added to the carrier** (`src/item.cpp:8390`),
  while `volume_encumber_modifier: 0` on the pocket keeps the bulk free.
- **Rigid armor blocks insertion.** `outfit::recalc_ablative_blocking`
  (`src/character_attire.cpp:404`) collects rigid sublocations from
  other worn items and calls `set_no_rigid` on every ablative pocket;
  `item_pocket::can_contain` then refuses hard plates there
  (`src/item_pocket.cpp:1540`). A "just put the plate in" answer is
  wrong whenever other hard armor covers the same sublimb.

## `non_functional`: transform instead of degrade

An armor with `"non_functional": "<itype_id>"` never takes ordinary
durability damage — it rolls to be **replaced** by that item
(`item::damage_armor_transforms`, `src/item.cpp:9538`): no break below
20% of the armor's own resistance, then `33.3 * (damage / resist)`
percent, tuned so plates survive ~3 rated shots. The replacement is
created inside the same pocket, so the useless remnant stays equipped
until removed by hand.

`git grep -n non_functional data/json` enumerates every item declaring
it. **The field only fires for items sitting in an ablative pocket** —
it is read nowhere but `ablative_armor_absorb`
(`src/character_armor.cpp:311`,`342`), as `doc/JSON/ITEM.md:314` warns,
so the same field on a directly-worn item (the riding helmet in
`data/json/items/armor/helmets.json:1452`) is inert and that helmet never
transforms. Steel and improvised plates omit the field and so damage,
degrade and repair like normal armor.
