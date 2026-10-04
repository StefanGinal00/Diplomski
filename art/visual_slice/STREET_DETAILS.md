# Settlement street-detail pass — 2026-09-27

This pass extends the existing code-native decorative polygons in Echo Haven
and Cinder Hearth. No new generated bitmap, external asset or image edit was
used. The previous painted backgrounds and building textures are retained.

SettlementStreetArt replaces 141 existing decorative elements with cached 2D
draw commands: 12 slatted benches, 9 striped stalls, 15 banded barrels,
3 planked carts, 6 spoked wheels, and 96 leafy/flowering plants. Echo's
Moon Forge display uses ingots and a hammer instead of produce. Colours and
goods vary deterministically; reopening the room does not randomize them.

The old visual polygons are retained but hidden; twelve old bench feet are
also hidden because the new benches include feet. Only named decorative
children under the existing town expansion/garden nodes are selected. No
collider, loot, service, interaction or NPC behavior is added to these props.
All drawings stay behind characters. Two static nodes serve the two towns;
there are no per-prop nodes, per-frame redraws, physics ticks or timers.
RoomActivityDirector hides them with their parent rooms.

Validation: eleven unique targeted smoke tests pass. The dedicated test
checks exact coverage, original geometry/transforms/physics, visibility scope,
node count, idempotence and inactive-room hiding at a non-zero room origin.
Four 960x540 staged GPU captures were reviewed:

- ../characters/preview_echo_market_details.png
- ../characters/preview_echo_garden_details.png
- ../characters/preview_cinder_market_details.png
- ../characters/preview_cinder_cart_details.png

Initial validation caught a typed-array membership bug in the test and a
missing camera zoom multiplier in the preview helper; both were corrected.
The runtime art did not require a corresponding movement/physics change.
Known sandbox certificate/settings and GPU shader-cache diagnostics persist;
these are not claimed fixed. No mobile-device profiling or full playthrough
was done. These stylized props remain an intermediate visual pass, not final
map completion. Architectural grounding, crowded labels, world NPC/mob art,
and remaining biomes still need separate attention.
