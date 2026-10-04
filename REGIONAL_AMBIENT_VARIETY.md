# Regional ambient variety - 2026-09-30

## Starfall textured city parallax - 2026-09-30

Two original builtin-imagegen RGBA sources are saved unchanged in the project:
`art/visual_slice/starfall_parallax_towers_v1.png` (bell tower, archive,
observatory) and `art/visual_slice/starfall_parallax_quarters_v1.png` (merchant,
library and artisan blocks). Exact prompts, source/copy paths, matched SHA-256
hashes and import settings: `art/visual_slice/CITY_PARALLAX_PROMPTS.json`.
Both remain 1536x1024 with alpha-border repair and mipmaps. Their combined
decoded size is **16,777,208 bytes including mipmaps**; this is only the added
texture budget, not whole-game memory or a phone performance measurement.

`CityParallaxAtlas` caches six silhouette-aware crops. `StarfallParallaxCity`
places them with deterministic spacing/height variation, uniform aspect,
low-contrast haze and faded foundations. The two planes move horizontally at
32% / 57% of camera travel and vertically at 4.5% / 9%; the far painted horizon
moves at 8% / 3.5%. Playable architecture stays at its original world positions.
Vertical city painting sampling is clamped instead of wrapped; cave backgrounds
retain their existing behavior. There is still only one opaque painting.

The new owner retires exactly 230 audited childless background renderers,
including the old upper skyline custom painter. It never hides a district root,
collider, service, arrival marker, platform or playable facade. There are no new
collision/interaction objects or per-building callbacks. Visible entries alone
are drawn, capped at 24 normal / 16 low-cost (actual native-camera counts are
lower); stationary-camera updates are skipped and hidden rooms stop processing.
`WorldAmbience` forwards its existing low-cost mode to the city scenery. The
18/8 animated-ornament budget is unchanged.

Verification: 14 focused smoke tests pass, including new atlas/retirement and
full-game Camera2D tests, two city visits, return to the cave, quality toggling,
unchanged original transforms/physics, zero cumulative drift and subpixel
camera math. Nine D3D12 Forward Mobile 1280x720 frames cover eight locations and
one extra camera-travel view; all eight actual player placements settle on
native floors. Native review reduced the initial oversized skyline twice.
Images: `art/characters/preview_atmosphere_parallax_*.png`. The renderer
completed all captures, but its log still reports two shader-cache write errors
during existing boss appearance initialization, alongside the certificate-store
warning; this is not a clean-log or phone-runtime sign-off.

Remaining visibly rough in those frames: upper-garden angular plants/planters,
street garden wedges, Crown Star Chart's prototype marker and large task/workshop
captions, plain bridge/workshop trim. This pass does not resolve the reported
enemy checkpoint respawn or complete all-world art. No commit/push or user-save
write was performed.

## Residential facades and utility props — 2026-09-30 follow-up

Builtin imagegen produced two original 1536x1024 RGBA atlases, copied unchanged:
`art/visual_slice/residential_doors_v1.png` and
`art/visual_slice/settlement_utilities_v1.png`. Exact prompts, source/copy paths,
verified SHA-256 values and import settings are in
`art/visual_slice/FACADE_AND_UTILITY_PROMPTS.json`.
The six closed doors and six utility pieces use cached regions in `FacadePropAtlas`;
imports have alpha-border repair, mipmaps and 1024px maximum edge.
**7,447,448 decoded bytes including mipmaps** are added by these two sheets, not a
measurement of whole-game RAM, export size or phone performance.

- `ResidentialFacadeDetails`: 18 Haven, 16 approach and 13 Cinder closed doors;
  six gate canopies and 14 attached Echo chimneys. It selects actual supporting
  floor footprints, moves only decorative canopies away from shelf gaps and keeps
  their original nodes hidden. No actor, collider or arrival marker is moved.
- Starfall: six closed street doors, three market doors and ten upper-house doors
  use the same atlas; thresholds are registered to native street/deck tops. These
  are scenery only, not new traversable portals. All 66 residential doors retain
  uniform aspect, and native camera review reduced their initial oversized scale.
- The approach previously had no `PaintedBuildings` consumer. Its 16 houses now
  have the same wall/roof treatment and 32 painted windows as the Haven family.
  No new large background was added and existing per-biome parallax is preserved.
- Fifteen Cinder supply pieces now vary barrels/crates/firewood at real ground
  contact. Existing stall posts are replaced by textured timber; the inn uses
  painted cloth and its attic window is no longer a plain luminous arch.
- Three upper bells, the foundry bell/stack, gardener barrel and observatory case
  use painted utility regions. The upper telescope includes its whole tripod:
  the old body AND tripod are retired. Native review reduced the telescope and
  shifted scenery away from the residential doorway, keeping the floor unchanged.
- Two original courtyard hanging crystals now reuse the existing lamp atlas,
  attached to their authored cables. Settlement hanging count is 101, all still
  under `WorldAmbience`'s 18/8 active budget; new static facade art has no autonomous
  frame callbacks and no collision/interaction/loot nodes.

Verification: 29 focused smoke tests and ten D3D12 Forward Mobile native 1280x720
camera captures via `tests/preview_residential_facades.gd`. Every preview lets the
actual player settle for 60 physics frames; all ten reported `is_on_floor=true`.
Final log: `.tmp-residential-preview-final.log`; screenshots:
`art/characters/preview_atmosphere_facade_*.png`. Prototype roof/bridge trim,
workshop strokes and some interactive task markers/labels remain visibly rough.
This pass is not a manual full-game traversal, persistence-bug fix or phone sign-off.

## Civic landmarks, joinery and settlement atmosphere — 2026-09-30

Three original builtin-imagegen RGBA atlases (1536×1024 each, copied unchanged)
add 16 usable pieces. Exact prompts, source paths and project paths are recorded
in `art/visual_slice/CIVIC_AND_JOINERY_PROMPTS.json`. All three source/copy
SHA-256 comparisons match. Imports use mipmaps, alpha-border fix and a 1024px
long edge: **11,171,172 decoded bytes total**, including mip levels. This is the
increment for these atlases, not the entire game's memory or phone profiling.

Coverage:
- 99 hanging objects: Echo Haven 30, Echo outskirts 30, Cinder Hearth 28, Starfall
  11. Three lanterns and three embroidered banners replace audited old shapes.
  Rings meet the actual sagging rope or wall fastener; freestanding lamps have
  grounded timber posts and attached crossbeams. No collider or native actor moves.
- Six civic landmarks: one fountain, one noticeboard, three ivy trellises and an
  armillary. Opaque base rows register to real floors; scale is uniform and
  reduced for low overhead platforms. The armillary sits east of the street lift
  at city x=5880, not among its ropes or in midair.
- Four balcony houses and six Cinder foundations use original painted posts,
  braces, lintels and masonry. Static drawing adds no child actors or callbacks.
- All 44 Cinder street/step/bridge surfaces now draw masonry or timber; the old
  opaque custom flat-block pass no longer hides the terrain materials.
- 12 upper-city lamps, 12 settlement benches, three carts and regional flora reuse
  painted assets. Wheels are part of the cart image, not doubled procedural wheels.
- Painted planters/trellises replace the huge flat Starfall arbor and 42 triangle
  plants. Root-level Cinder glow triangles and Echo expansion cavern masks are
  retired in runtime camera views, while editor overview masks are preserved.

Motion uses WorldAmbience's existing visible-room/camera selection, max 18 props
(8 low-cost), 20Hz (10Hz low-cost). Pendants rotate/shear subtly about their top
ring; the fountain has two small local water ripples. No per-decoration process,
physics body, light, full-screen transparency pass or additional particle system.

The two field offices retain their native live data rows, events, NPC dialogue
and reward rules. Runtime presentation hides the large world tables; a G/click
report displays the current table as scrollable text. Opening/revisiting/closing,
live updates, viewport fitting and no-progress/no-payout behavior are tested.
Selected settlement wayfinding/service signs use the same nearby-reader system.

Automated D3D12 native-camera captures are produced by
`tests/preview_settlement_atmosphere.gd`: seven settled player viewpoints plus
the open field report. They are renderer captures, not continuous manual traversal.
The report's asynchronous container-size overflow was found in native rendering,
fixed, and checked again: its 620x480 panel stays inside the 1280x720 viewport.
Final reports/log paths for 27 passing focused tests are in
`tests/LATEST_SMOKE_RESULTS.md`.

Remaining: some old residential doors, awnings, separate foliage patches,
workshop/civic symbols and facade details are still visibly schematic. Keep
replacing those shared sources; do not treat this pass or its tests as a claim
that every map is finished. Real phone frame times and export packaging remain
unverified. The old opening-enemy save/respawn report is still a separate open item.

This is a shared world-dressing follow-up, not whole-map artistic sign-off or a
phone performance claim. It preserves native routes, colliders, combat, quests,
rewards, device interactions and saves.

## New artwork and placement

Three original generated atlases contain 18 cutouts: damp cave rubble/reeds/
fungi/aqueduct remnants/roots/vines; ash bricks/grasses/jars/forge remnants/
streamers/herbs; and Starfall masonry/flowers/urns/column remnants/banner/ivy.
Exact prompts, source provenance and final paths are in
`art/visual_slice/REGIONAL_AMBIENT_PROMPTS.md` (built-in imagegen, no CLI fallback).

`RegionalAmbientDressing.gd` combines a substantial detail with a smaller plant,
then adds separately anchored hanging pieces. All 39 rooms participate. The
automated full-world check records **1253 cutouts**, including **769 possible
motion candidates**; these are not simultaneously animated. Placement uses real
rectangular terrain and current protected interactions/hazards, with a maximum
of 14 two-piece ground clusters and eight hanging pieces per room. Quiet space
is retained between clusters; wall and underside attachments are validated.

Small import rounding matters: Godot's drawn AtlasTexture dimensions are
integer-sized even when imported crop coordinates are fractional. Opaque contact
alignment now uses the actual drawn rectangle. Exact cutout bounds are checked
against nearby platforms in addition to the nominal composition bounds. The
initial test caught both issues; fixes were rerun, not assertions removed.

No per-object physics or frame callback is added. On cached-room refresh, late
native terminals hide only intersecting new decoration; their interaction area,
position and artwork remain native. Reentry does not duplicate compositions.

## Ambient motion and resource limits

`AmbientSetpiece.gd` applies small two-frequency wind rotations to reeds, flowers,
roots and hanging cloth about a fixed foot/attachment. Hanging pieces also have
a tiny shear. These are procedural ambient motions, not new character animation
frames. Static rocks, urns and machinery fragments do not sway.

`WorldAmbience.gd` shares its existing **18 normal / 8 low-cost** active-object
limit between old vines, machinery and the new details. Visible candidates are
prioritized by camera distance to avoid older vines consuming the whole budget.
Selection is updated every 0.25 s; motion updates use the existing 20/10 Hz
cadence. Deselected pieces reset to rest, and hidden/offscreen/other-room pieces
are not selected. The low-cost path is exercised automatically; no real phone
frame-time, memory, thermal or battery measurement has been performed.

All three PNG originals are 1536 x 1024 with generated alpha preserved. Shared
imports are capped at 1024 pixels with mipmaps. Their measured combined decoded
texture data is **11,171,172 bytes including mipmaps**, additional to existing
assets, not the total game/GPU memory footprint.

## Remaining sketch cleanup found during native previews

- 300 inert ore/loose-rock wedges retired. The selection is explicit, untextured,
  childless, background-only, and rejects collision-object ancestry.
- 1171 old terrain seam/seep lines retired; authored bridge ropes use subdued
  thinner rope coloring. No attack warning, hazard line or interaction is hidden.
- Room-root Backdrop rectangles are retired at runtime even when a painter
  targets a different polygon (the Forge's FurnaceWall left its Backdrop intact).
- Audited Forge core/duct and Echo Haven glow/canopy/vein sketches no longer
  obscure the full-camera painting. Painted Ash switchbacks do not draw their
  old solid rectangular background piers over it; editor previews/fallbacks stay.

## Verification

11 distinct focused smoke tests have passing final runs, listed in
`tests/LATEST_SMOKE_RESULTS.md`. They cover all-world dressing/contact/clearance,
resource and animation limits, late native doors, collision snapshots, structure
integration, old ambience, readables, routes, Ash traversal, settlement paintings,
native environmental hazard artwork and the isolated checkpoint regression.

Nine D3D12 captures at `art/characters/preview_ambient_*.png` cover eight distinct
locations plus a second Starfall wind pose. Each location settles the player
using native gravity before capture. Final log:
`.tmp-regional-ambient-preview-final.log`. These are controlled automatic
camera captures, not a continuous manual playthrough. Known host certificate
warnings and denied external shader-cache writes appear; no script errors in
final tests or captures. Tests use isolated temporary workspace saves.

## Resident and industrial follow up

The next 2026-09-30 pass replaces TownResident's polygon bodies with six shared
regional appearances and 24 painted frames across three original atlases.
`ResidentMotion.gd` retains native walking, partner/player attention and dialogue
priority, but displays idle, two stride drawings and a conversation gesture.
Small breathing scales from the planted boot; it does not lift the whole body.
Frame crops, horizontal pivots and opaque foot rows are measured individually.
The all-world test covers **96 visible painted residents across 39 rooms**,
including streamed population. Existing specially painted guides stay intact.

NPC art is 29/31 world units high after native-camera comparison with the player.
WorldPresentationFinish shares its floor survey with residents, handles late
arrivals and places focused names near their corrected head height. Standalone
town F6 scenes obtain local supports too. Actor roots, route markers, talk
colliders and native conversation/indoor behavior are not moved or replaced.
Sprite changes are capped at 20/10 Hz and culled outside the viewport margin;
there is no additional per-sprite callback or physics object.

A fourth original atlas supplies a ventilator housing, detached rotor, armour
rack and garrison banner. **17 supported fixtures** replace the Forge fan, field
rack/banner and all six Barracks schematic racks/eight standards. The rotor
starts only with the native `ash_forge_fan` flag and uses the shared 18/8 scenery
animation budget. Static fixtures remain static. Old bright Forge conduit strokes
are retired only inside the inert AshIdentity tree; actual hazard telegraphs,
valves and heat lanes remain authoritative. Area subtitles and route-identity
captions now use the existing nearby G reading UI instead of crossing the screen.

Testing exposed six old overview fixture coordinates above gaps or outside the
correct gallery. New cutouts now use both X and Y from the native `surface_at`
query, then register their painted feet to actual deck tops. The original
landmark roots and collision geometry are preserved. Initial type/import errors
and failed placement assertions were fixed and rerun, not waived.

The four source PNGs are unchanged: three 1536x1024 character sheets and one
1254x1254 industrial sheet, imported at a maximum edge of 1024 with mipmaps.
Additional decoded texture data totals **16,763,576 bytes including mipmaps**,
not total game memory. Source paths, final paths and exact prompts are in
`art/visual_slice/RESIDENT_AND_INDUSTRY_PROMPTS.json`; built-in imagegen was used,
without CLI fallback or third-party downloads.

14 focused tests have passing runs recorded in `tests/LATEST_SMOKE_RESULTS.md`.
Thirteen native D3D12 captures in `art/characters/preview_resident_*.png` cover
three settlements with idle/stride/gesture states, inactive/active Forge fan,
Barracks rack and the outskirts banner. The final log is
`.tmp-resident-painted-preview-final.log`; all six locations settle using native
gravity. Inspection led to the smaller NPC proportions, corrected name placement,
subtitle cleanup and replacing the additional Barracks sketches. These are
controlled automatic captures, not a continuous playthrough or phone benchmark.

## Service bodies and streetscape follow-up - 2026-09-30

Five original built-in imagegen atlases provide 12 service body frames and 18
scenery cutouts. Four shared body archetypes dress ten TownService instances,
including generated Canal Trade/Moon Forge and the embedded Lantern Ward. Native
stock, prices, forge recipes, portraits and interaction signals are unchanged.
Workplaces select the supported side of the actor; body frames retain a measured
boot contact in both facing directions. Only the native service callback drives
the 20/10 Hz viewport-limited pose updates. Standalone F6 towns and late services
receive contact registration too. Orin's existing distinct opening body remains.

The three poses are idle, quiet ledger/tool preparation and greeting, not a
complete hammer-strike cycle. No false impact animation or new damaging collider
was added. Goods/anvils render ahead of background decoration but behind the
service body; Moon Forge no longer has a second person-sized display anvil.

Echo/Cinder receive 59 painted windows and nine painted awnings/stalls. Starfall
receives 15 facade windows, 40 upper-house windows and 18 market windows, five
market stalls, 11 street lamps, 11 planters, four benches and one delivery cart.
The city uses its real street collider top, not the floor body's center. Original
market cart/wheel sketches are retired; original nodes/collisions stay intact.
Native dawn colors still reach the new windows/lamps, while masonry and lamp
poles remain opaque during subtle brightness pulses. All static drawings remain
cached; decorative props add no physics or individual animation callbacks.

Native previews caught and corrected a Polygon2D atlas issue: these surfaces
need the shared source plus explicit crop UVs, not an AtlasTexture assigned as
though it were a Sprite2D. The regression now checks those UVs. Further preview
fixes corrected floor-center burial, duplicate forge furniture and scenery
occluding the Ward anvil. Remaining large schematic scenery is still visible.

All five source PNGs are 1536x1024 with generated alpha, copied unchanged (SHA256
matches). Imports are max-edge 1024 with mipmaps; total **18,618,620 additional
decoded bytes**, not total application memory or a phone benchmark. Exact prompt
set, original/final paths and scope: `art/visual_slice/SERVICE_AND_STREET_PROMPTS.json`.
43 distinct focused tests have passing runs; see `tests/LATEST_SMOKE_RESULTS.md`.
Thirty D3D12 automatic captures cover all ten services with three poses each,
native gravity settling at every location, in `art/characters/preview_service_*.png`.
Final capture log: `.tmp-service-preview-final.log`. This is not manual playthrough.

## Explicitly unfinished

- Six shared resident looks are not bespoke bodies for every named portrait.
  Longer, more natural hand-refined walk/work cycles and bespoke service bodies
  matching every named portrait remain separate follow-ups.
- Some roofs, flat walls, hanging crystals/flame ornaments, old flowers, the
  Starfall fountain and upper-city workshop furnishings remain schematic.
  Remaining support beams, ordinary platforms and door/facade intersections need
  composition work. Painted market props do not finish all larger structures.
- Nearby entrance pairs and facade/platform intersections remain room-specific
  composition tasks from `WORLD_STRUCTURE_INTEGRATION.md`.
- The original intermittent saved-enemy respawn remains unconfirmed; another
  passing isolated regression is not proof of its root cause or resolution.
- Real-phone profiling and continuous visual/traversal review remain open.
