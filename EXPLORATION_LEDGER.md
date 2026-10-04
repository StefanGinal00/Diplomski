# Regional exploration pass - 2026-09-29

The existing optional routes now have persistent journal guidance across all
four regions: five Shaft routes, eight Echo routes, six Ash routes and seven
Starfall routes (26 total). This pass does not add or copy room geometry.

## Player-facing changes

- The quest journal lists only visited routes, grouped by region.
- The current route has an authored first-visit clue and return-location clue,
  including machinery, listening posts, signal sequences or guardian requirements.
- Return status distinguishes boss/tier lock, unfinished local task, uncleared
  reserve guards, available encounter, unclaimed reserve and collected reserve.
- Each of the 26 existing return reserves retains its original gold, item and
  weapon-adaptive supply. It also awards one local common material/remedy or two
  Ember Arrows. No extra rare shards, equipment or skill points are introduced.
- The journal previews the additional supply for the current route. A short,
  location-specific recovered dispatch remains in the journal after collection,
  connecting maintenance, relief work and reopened roads to the existing story.

This is an optional exploration layer, not a replacement main quest or another
mandatory unlock. It introduces no new actors or eager-loading requirement.
Existing field boards, residents, encounters and their actual gates are unchanged.

## Persistence and compatibility

ExplorationLedger reads discovered_rooms, unlocked_shortcuts, zone_tiers,
defeated_bosses and opened_caches. It writes none of them and needs no new save
fields. ResonanceCache awards the extra supply only after its existing once-only
receipt succeeds. Previously collected reserves remain collected: they acquire
journal text, but do not retroactively pay extra supplies. Unknown/unrelated cache
IDs retain their old rewards. Saved enemy defeats and world streaming are untouched.

## Verification

tests/exploration_ledger_smoke.gd resolves every catalog entry to a real streamed
reserve in Game.tscn, checks its completion ID, all journal states, blocked opening,
exact reward amounts, reentrant opening and save/reload across all 26 routes.
It uses an isolated test save. Existing regional field-operation and story-record
tests cover native objectives separately.

This is not final economy balance or a full physical traversal of every map.
Remaining map work includes room-by-room encounter pacing, environmental readability
and rewards outside these field routes. Manual playthrough remains deferred.
