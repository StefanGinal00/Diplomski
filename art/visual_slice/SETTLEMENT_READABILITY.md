# Settlement readability and grounding — 2026-09-27

TownNameplateLayout.gd manages runtime NameLabel visibility in Echo Haven,
Cinder Hearth and Starfall Citadel. Three vertical lanes, viewport clipping
and text-size screen bounds prevent overlap at each 10 Hz layout refresh.
Active resident conversations, nearby interaction candidates and services
take precedence over ambient residents. Overflow names hide, not actors or
interaction areas. Social bubbles and interaction prompts reserve space.
Names return when residents separate; hidden/indoor residents are excluded.
Streaming additions are discovered every 0.5 seconds, freed actors pruned,
and hidden rooms do no layout work. The editor retains authored label layout.
This is not a replacement for interaction targeting or a full accessibility UI.

SettlementBuildingSupports.gd adds four open porticos under existing upper
houses (two per settlement) and six low foundations under Cinder's eastern
civic buildings. Floor height comes from existing collision geometry. These
are static code-native drawings behind actors, without collision or processing.
All original actor positions, doors, paths and building polygons are retained.
This pass uses no new generated bitmap assets.

## Validation

15 unique targeted smoke tests pass; see tests/LATEST_SMOKE_RESULTS.md.
The two new tests cover three viewport sizes/two camera zooms, name priority,
non-overlap, stable stationary layouts, separation, bubble avoidance, streaming,
hidden rooms, floor alignment, idempotence and unchanged physics/transforms.
Tests and preview use isolated workspace saves, not the player's save.

Four 960x540 staged D3D12 Forward Mobile captures were visually reviewed:

- ../characters/preview_echo_nameplates_supports.png
- ../characters/preview_cinder_nameplates_supports.png
- ../characters/preview_cinder_foundations.png
- ../characters/preview_starfall_nameplates.png

Reproduce with tests/preview_settlement_nameplates.gd. These are desktop
captures, not mobile profiling or a complete playthrough. Fast movement may
temporarily change spacing between 10 Hz refreshes. Large civic buildings,
world sprites, terrain and other-biome architecture still need further art.
