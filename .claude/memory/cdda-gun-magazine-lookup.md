---
name: cdda-gun-magazine-lookup
description: "Which magazines fit a CDDA gun, where they spawn, and why same-caliber feed devices still don't fit."
metadata:
  node_type: memory
  type: reference
---

Answering "what magazine does gun X take / where do I get it" has a
fixed route. Fan all of it out in one call.

**Compatibility is a whitelist, not caliber matching.** The gun's
`pocket_data` `MAGAZINE_WELL` carries `item_restriction`, an explicit
list of magazine ids (`data/json/items/gun/<caliber>.json`). Same
caliber is *not* sufficient — e.g. `762x39_clip` is 7.62x39 and
craftable, but the AKM's magwell lists only `akmag*`, so it is
SKS-only. Always read the restriction list before saying something
fits.

**Default magazine** = `item_restriction.front()`
(`src/item_pocket.cpp:159`, via `item_pocket::magazine_default`
`:718` and `item_contents::magazine_default`
`src/item_contents.cpp:2085`). No `default_magazine` field is usually
written; order in the JSON list decides it.

**Guns usually spawn loaded.** An item_group's `"magazine": N` /
`"ammo": N` are percent chances applied in
`src/item_group.cpp:651-661`: `spawn_mag` puts `magazine_default()`
into the gun. `guns_rifle_common` sets `"magazine": 100`
(`data/json/itemgroups/Weapons_Mods_Ammo/guns.json:180`), so for most
"where do I get a mag" questions the real answer is *find another gun
of that family*, not *find a bare magazine*.

**Loot group naming convention**, three tiers:
- `magazines_<gun>` (e.g. `magazines_akm`) —
  `itemgroups/Weapons_Mods_Ammo/magazines/magazine_collections_by_guns.json`
- `common_magazines_<caliber>` / `common_magazines_restricted_<caliber>` —
  `.../magazines/magazines_by_caliber.json`
- `mags_common`, `mags_rifle_hunting`, … — `.../magazines/magazines.json`,
  the tier that mapgen and SUS groups actually reference.
Also `nested_<gun>` in `Weapons_Mods_Ammo/nested_guns.json` = gun +
1-2 spare mags + ammo, and `boxed_<gun>` in `gunstore_guns.json` =
new-in-box gun store version. Some `nested_*` entries are defined but
referenced nowhere (`nested_ak47`) — check for a referencing group
before citing one as a spawn source.

**Craftable magazines are the exception.** Only
`data/json/recipes/weapon/magazines.json` has them: stripper clips,
`*_makeshiftmag` for a specific handful of rifles, and beowulf
conversions. Most factory magazines, AK included, have no recipe and
no uncraft — a zero result there is the answer, not a missed grep.

Related: [[cdda-item-source-tracing]].
