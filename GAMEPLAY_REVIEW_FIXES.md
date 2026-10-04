# Gameplay screenshot review — 2026-09-29

This is an open repair checklist, not a declaration that world art, balance or
the reported persistence bug is finished.

City skyline follow-up (2026-09-30): six new textured building/block variants
now populate two camera-relative architectural planes, over the existing single
full-viewport painted horizon. Retired 230 old background-only renderers and
added atmospheric depth without moving native houses, routes or physics. Actual
camera motion, city revisit and both quality modes are covered by new tests;
14 focused regressions pass. Nine native camera frames were reviewed. Details,
asset manifest, native shader-cache log caveat and remaining prototype city
plants/markers/trim are in `REGIONAL_AMBIENT_VARIETY.md` and the latest test log.
The city painting's scroll factors are now distinct; other biomes are unchanged.

Facade follow-up (2026-09-30): 12 new original painted asset variants now cover
66 decorative residential doors plus utility stores, chimneys, bells and the
upper telescope. Six gate canopies gain actual floor-supported timber; the
approach's 16 houses and 32 windows no longer remain flat polygons. Two original
Haven hanging crystals were replaced with mounted, budgeted lamps. Native camera
inspection corrected initial oversized doors/telescope and caught the missing
approach material consumer. See `REGIONAL_AMBIENT_VARIETY.md` for exact coverage.
29 focused tests pass; ten native camera frames checked, not manual playthrough.
Next visible targets include the old Crown Star Chart marker/label and workshop
trim. The user's opening enemy-respawn report and native phone performance are
still unconfirmed by this visual pass. No user save, commit or push was changed.

Settlement follow-up (2026-09-30): 16 new original painted construction/civic
pieces, 99 mounted ambient ornaments, six grounded landmarks, textured Cinder
walkways and shared street furnishing/flora replacements. Native captures exposed
additional backdrop masks and the opaque Cinder custom floor painter, now
corrected. Starfall/Hearth field reports moved into the nearby G reader without
changing native task, cache or return-reward data. Details and limitations:
`REGIONAL_AMBIENT_VARIETY.md`. All-world art and phone performance remain open.

## Implemented and checked

Latest service/street follow-up (2026-09-30): painted bodies/three poses now cover
all ten TownService actors; new shared workplaces, 132 windows, 14 stalls and
Starfall street furniture replace more schematic art. Native purchase/forge and
portrait UI tests pass; 30 real-renderer camera captures cover every service.
Atlas UV, floor contact, duplicate furniture and layer defects found in previews
were corrected. See `REGIONAL_AMBIENT_VARIETY.md` and the latest smoke checkpoint.
The fountain, hanging ornaments and older house supports were addressed in the
following pass; remaining facade/platform composition, sketch scenery and
real-phone performance are still open. No new conclusion on
the intermittent enemy-respawn report is implied by this visual pass.

- [x] Add exact opening regression: New Game, kill Enemy/Enemy2/RangedEnemy,
  real lamp save, native death/Return to Lamp scene reload. All three stay dead.
  Baseline already passed before the repair, so this does not prove a root cause.
- [x] Read-only inspection and isolated-copy replay of the actual save: all three
  opening kills are recorded; cold load, revisit and death/revisit keep them dead.
  The original save's SHA256 remained unchanged. No save migration/reset performed.
- [x] Defensive enemy tracking: ready-time retry, idempotent signal registration,
  a post-world-ready reconciliation pass, and debug checkpoint ledger counts.
- [x] Sentinel core shot 2 HP; phase-two core 3 HP, side fragments 1 HP, core
  visibly larger. Other bosses distinguish charge/eruption/pulse/rift hits from
  smaller projectiles/contact. Actual Sentinel HP loss and Guardian Band mitigation
  tested; larger attacks are not a final difficulty/balance sign-off.
- [x] Explicit distance budgets for arrows, magic and hostile projectiles.
  Piercing continuation consumes the arrow budget; large-delta/long-lifetime tests
  cannot extend range. Sentinel shots capped at 460 world units.
- [x] Full-viewport painted plane with 24% horizontal / 18% vertical camera
  parallax, mirrored horizontal repetition and vertical seam haze. Runtime room
  paint plates are retired to avoid stacked background panels; editor overviews
  remain unchanged. Source art is not stretched over the whole room.
- [x] Runtime rectangular terrain finish across 39 distinct rooms: 3161 treated
  surfaces, including vertical sides, plus roots/chipped lips/ivy and retired
  named cyan seams. Regional stone sources retained. No collider changes except
  the intentional opening west wall; this does not cover every custom-drawn prop.
- [x] Painted Orin, Eldric and Deren bodies; broader use of existing painted fauna.
  Textured XP wisps, healing flowers, ore samples, iron spikes, gold coins, quest
  sigils and supply-pouch item drops (late item configuration updates the art).
  Native dialogue,
  collection, damage and one-time reward authorities remain unchanged.
- [x] Painted lantern/lift and masonry/mine entrance presentation: 186 devices.
  Mine variants selected for shaft/industrial rooms, regional tints elsewhere.
  Lamps are visually grounded; native lock/save/reveal prompts remain authoritative.
  Shaft arena relics moved away from entrances and checked against solid platforms.
- [x] Close the opening left ground edge with a textured wall. Intentional pits
  still exist, but camera artwork continues behind/below them.
- [x] MSDF default font, nearest ambient caption focus, shortened ore feedback,
  and center-HUD font fitting/wrapping without dropping objective text. All 39
  room objectives fit within two lines and the HUD panel in the coverage test.
- [x] Shaft ore carts reduced to 58–66 world units; Echo carts 82; reserve marker
  bodies and their progress indicators reduced together from 264 to 132 wide.
- [x] Replace entry triangles in 17 regional rooms with 33 supported fern,
  fungus/mineral clusters. Floor/ceiling overlap, idempotence and unchanged
  physics checked. Mining braces now carry timber material.
- [x] Ten real Camera2D captures at native zoom, including camp, high jump,
  opening west edge/exit, pickups, shaft lift, side/floor and Hollow. Final D3D12 captures
  saved as `art/characters/preview_review_*.png`; this is automated framing,
  not a full continuous manual playthrough.

## Still open

Follow-up implemented: readable nearby notices, animated environmental hazard
art, smaller fitted machinery, budgeted ambient motion and 222 additional
grounded expedition props. Details and remaining boundaries are in
`WORLD_LIFE_READABILITY.md`; this does not close the outstanding items below.

Follow-up 2026-09-30: actual floor/pixel-foot contact, supporting portal facades,
outer endpoint walls and lift gantries are implemented and checked across all
39 rooms. See `WORLD_GROUNDING_AND_PORTALS.md` for scope, native captures and
remaining neighboring-door spacing work. This is not whole-world art sign-off.

Further structure pass 2026-09-30: three new generated atlases add complete
regional facades to 112 passages and assembled winch/deck/suspension/support art
to 40 lift terminals. Terrain ties use actual walls/floors; nearby device labels
are focused, facades stay behind lamps, and late devices are refreshed without
reentry. See `WORLD_STRUCTURE_INTEGRATION.md` for nine passing focused tests and
eight native captures. Old custom shapes, close doorway pairs and ordinary ledge
composition still require follow-up; native lift transport was not redesigned.

Regional ambient follow-up: three new original atlases / 18 cutouts are combined
into grounded small scenes across all 39 rooms (1253 instances in the test).
Shared budgeted wind, protected gameplay space and late-device suppression are
checked. Legacy inert wedges/terrain seams and remaining root background covers
were retired, including Forge/Haven overlays found in native captures. See
`REGIONAL_AMBIENT_VARIETY.md`.

Resident/industry follow-up: 24 new frames provide six shared regional looks for
96 residents, with measured boot contact, native motion/conversation and bounded
offscreen-aware sprite updates. Seventeen supported fixtures replace the Forge
fan and Barracks/field racks and standards; the fan follows its existing flag.
Additional subtitles and identity captions use nearby G reading. See the same
report and `art/visual_slice/RESIDENT_AND_INDUSTRY_PROMPTS.json` for four untouched
original source sheets, import bounds, 14 passing focused tests and 13 native
captures. Service/merchant bodies, bespoke identities, buildings, remaining
large authored mechanisms and other scenery are still unfinished.

- [ ] Reproduce the reported two-mob respawn in a fresh user run. Evidence so far
  rules out missing opening kill records in the inspected snapshot, not every
  timing/path variant. Keep the issue open and use checkpoint diagnostics if it
  recurs; do not delete user progress to conceal it.
- [ ] Review every authored route at gameplay zoom, including custom `_draw`
  mechanisms, remaining relays/props, foreground silhouettes and collision-sized
  hazards. Automated material coverage does not establish artistic completion.
- [ ] More area-specific entrances/bridges and resident body variants. Four other
  shaft guides currently reuse the painted caretaker body; not all NPC art is unique.
- [ ] Full traversal/combat balance and mobile performance/controls remain
  separate. No claim of a full-suite pass or complete manual playthrough.

## Evidence and asset provenance

37 unique focused tests have passing final runs; report directories are listed in
`tests/LATEST_SMOKE_RESULTS.md`. Native D3D12 and Vulkan previews worked. A first
Compatibility/OpenGL preview crashed in renderer initialization, so that backend
is not verified. GPU preview logs include sandbox-denied shader-cache writes;
headless import reports denied external editor-settings writes and the known
host certificate-store message. No script error in the final smoke runs.

Four original PNG atlases were generated with the built-in imagegen tool using
the imagegen skill, not a CLI/API fallback. Exact prompts, original source paths,
saved paths and actual resolutions are in `art/visual_slice/GAMEPLAY_REVIEW_PROMPTS.md`.
Native AtlasTexture regions preserve the source alpha; all four imports use mipmaps.

Reference direction: original 2D art, layered silhouettes, material variety and quiet gameplay space. Official Silksong reference: https://hollowknightsilksong.com/ (reference only; do not copy its assets).
