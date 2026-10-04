# Visual style pilot — Echo Grotto / Starfall market

Latest route enrichment (2026-10-03): [eight original transparent sheets, 48 cutouts and exact built-in ImageGen prompts](route_dressing_manifest_v1.json),
with [39-room placement checks, 30 real-controller ceiling checks, nine focused test passes and 12 inspected native views](../../tests/route_richness_verification_v1.json).
Wet caves, mines, cinder regions and Starfall use distinct low ground bands,
walk-through foreground, attached rock scallops, ivy, ropes, chains and cloth.
Six broad ceiling pockets combine textured cores with layered cutouts and
feathered lower joins; native support colliders remain untouched.
Soft props share the camera-scoped wind budget instead of ticking individually.
The original generated PNGs are byte-preserved; alpha gutters, crops and contact
rows are registered in RouteDressingAtlas. Eight 1024px mipmapped lossless imports
total 26,079,712 decoded bytes. This does not claim full-game visual completion.

Previous facade/route continuation (2026-10-03): [two original transparent sheets, 12 modular cutouts and exact built-in ImageGen prompts](facade_relief_manifest_v1.json),
with [43 focused passes, four reproduced repairs and nine inspected native camera views](../../tests/facade_route_verification_v1.json).
Haven, its outskirts and Hearth gain 44 wall pilasters, 39 small ivy patches
and 13 rear piers spanning actual existing floors. Architectural caps, shafts
and feet retain uniform material scale; no decorative collider or per-prop tick
is added. All 91 windows own a real house silhouette. Outskirts bench remnants
use the shared painted street renderer. Five gate and ten street canopies
reserve final doors/windows and floor/ceiling space; two cramped sites use
compact open counters. The Cinder library descent now exposes every landing
to the basic-jump controller. The two lossless, 1024px mipmapped imports total
7,447,448 decoded bytes. This is a scoped continuation, not whole-game visual
completion or a physical-phone benchmark.

Previous body/city repair (2026-10-03): [three original ledge images, 12 variants and exact built-in ImageGen prompts](city_walkway_manifest_v1.json),
with [19 focused regressions and 12 native camera views](../../tests/body_city_repair_verification_v1.json).
262 built street/platform edges across Haven, its outer housing quarter, Hearth
and Starfall now use shallow architectural cornices instead of cave undersides.
91 facade windows were checked; 63 were refitted clear of balconies. Expansion
gables, roof silhouettes and supported canopy posts were repaired. Opaque cluster
feet are registered to real ground; old overview chevrons, giant cones, circles
and diagonal niche lines no longer draw over the finished scenery. Incoming
earth-strip joins overlap and feather; superseded tiled wall faces are hidden.
Seven boss types plus Awakened Warden have central body/head damage receivers,
with 72 feet/torso/head sword/arrow/magic cases and torso contact checks. Native
boss navigation remains unchanged; audited existing exterior walls are explicitly
extended to stop jumps above their old caps. This includes a real Haven cliff
collision check, not merely a painted boundary. No whole-game completion or
physical-phone performance is claimed; the three imports use 11,171,172 decoded
bytes including mipmaps.

Previous guardhouse pass (2026-10-01, recorded here 2026-10-03): [seven original images, 22 cutouts and exact prompts](guardhouse_manifest_v1.json),
with [13 focused regressions and 19 native camera views](../../tests/guardhouse_verification_v1.json).
25 constrained passages use compact regional facades; all 112 portal contexts
were checked. Cinder civic buildings and the open Starfall street arch gain
painted detail, with ten budgeted watch banners anchored to fixed rods. Five
entrances and their paired arrivals intentionally move horizontally on their
existing landing; three authored stair widths clear those approaches. The seven
1024px mipmapped imports use 26,066,068 decoded bytes; phone profiling is pending.

Earlier gateway pass (2026-09-30): [five original images, 15 cutouts and exact prompts](gate_dressing_manifest_v1.json),
with [contact, traversal, reading and camera verification](../../tests/gate_dressing_verification_v1.json).
Three Haven/ward gate compositions replace intersecting schematic towers; 112
doorways gain regional low thresholds. Thirty outer-district garden wedges are
retired, with 26 supported plants using the existing ambient motion budget.
Thirteen extra Haven notices are available through G; physical reading signs
prefer a supported spot beside door mouths. No collider or destination is moved.
The five 1024px mipmapped imports use 18,618,620 decoded bytes; phone profiling
is still pending. This is a scoped continuation, not whole-world completion.

Earlier city pass (2026-09-30): [six original images, atlas regions and exact prompts](city_architecture_manifest_v1.json),
with [architecture, reading, collision and native-camera verification](../../tests/city_architecture_verification_v1.json).
Three 512px wall imports and three 1024px shared RGBA atlases dress 79 facade
surfaces, three market walls, 30 shallow terrace arches and observatory equipment.
Six roof gaps and six root-house footings are closed behind the original geometry.
Old pilot skirts and luminous settlement guide lines no longer draw over finished
terrain. Gameplay collision, routes and progression are unchanged. Originals are
preserved bit-for-bit; this pass does not claim a complete whole-game art finish.

Earlier terrain pass (2026-09-30): [24 modular edge variants and exact generation prompts](terrain_edge_manifest_v1.json),
with [39-room collision/art checks and focused gameplay regressions](../../tests/terrain_edge_verification_v1.json).
Six original alpha PNG atlases feed static, uniformly scaled edge segments; their
top contact follows the existing collider. No collision, one-way status or route
is changed. Source images are preserved; runtime imports use 1024px with mipmaps.

Earlier repair: [entry visibility, full city panorama and native detail](BACKGROUND_QUALITY_REPAIR.md).

Earlier rollout: [24 remaining world backgrounds](WORLD_BACKGROUND_ROLLOUT.md),
with exact prompts, original file provenance, 342 masks and verification scope.

This is the first in-game 2D environment art sample, not final character art
or completion of the entire map.

## Echo and Starfall material expansion

[Driftworks mine art and exact prompts](DRIFTWORKS_ART.md) add a distinct mining
painting across 24 chamber/link masks, iron texture on 73 walking surfaces and
four transparent ore-cart props. The shared expedition art has separate Shaft
and Starfall styles; the two regions do not share their new paintings or props.

[Broken Ramparts painting and exact prompts](BROKEN_RAMPARTS_ART.md) cover the
separate expedition's 24 background polygons, 105 existing walking surfaces and
four transparent watch-pillar props. Its eight main/four side chambers and all
physics remain unchanged. Other expedition biomes do not opt into this art.

[Starfall arena art and exact prompts](STARFALL_ARENA_ART.md) add two distinct
painted/parallax backgrounds for Empty Court and Hollow Throne, a transparent
2D throne sprite, sixteen stone walking surfaces and two below-floor foundations.
Boss bodies and gameplay effects remain unchanged; this is not final boss art.

[Five additional Starfall backgrounds](STARFALL_ROUTE_BACKDROPS.md) cover outer
defenses, Silent Gate, Rooted Hall, Soul Crucible and Sunless Passage. Together
with Memory Vault, all six expanded StarfallDescent routes now have distinct
paintings and parallax. The shared system totals nine rooms / 135 surfaces;
foreground architecture and other rooms still need further visual passes.

[Four-room painted depth pass](ROOM_PAINTED_DEPTH.md) introduces distinct
cistern, prism archive, furnace hall and memory vault images, clipped to 65
existing room surfaces with continuous UVs and two camera-relative depth rates.
That document includes image paths, exact built-in ImageGen prompts and the
remaining room-by-room background rollout.

[Upper Starfall civic details](STARFALL_UPPER_DETAILS.md) add code-native 2D
windows, residential doors, lanterns, plants, bells and telescope detail over
the existing image materials. No additional bitmap generation or 3D models.

[Four generated textures, exact prompts and coverage](ECHO_STARFALL_MATERIALS.md)
dress 57 Echo walking surfaces and 33 Starfall facade/roof surfaces, including
the market and ten upper-city homes. Originals are retained; shared imports
are 512px with mipmaps. Existing gameplay geometry and actor routes stay intact.

## Settlement street details

[Street furniture, market displays and flora](STREET_DETAILS.md) extend the
existing code-native decoration. 141 replacements are cached in two static
nodes; Moon Forge has its own smithing display. No gameplay objects or physics
are added. Four close-up previews and dedicated regression coverage accompany
the pass. This is not final world-character or map art.

## Settlement building materials

[Six surface textures and exact prompts](BUILDING_MATERIALS.md) now cover
original, upper-balcony and expanded houses in Echo Haven and Cinder Hearth.
98 polygons reuse six 512px mipmapped imports; 59 window frames add static
detail. Existing building silhouettes, routes and colliders stay unchanged.
Preview images are in ../characters/preview_*_houses.png.

## Settlement background batch

Echo Haven and Cinder Hearth now also have distinct generated paintings:
[assets, exact prompts and scope](../characters/SETTLEMENT_ART_BATCH.md).
PaintedSettlementBackdrop changes fourteen existing background polygons only.
Echo's district pockets and shafts share one continuous painting space, not
one repeated image per floor. A separate shader preserves vertex tint without
double-multiplying texture colour. Camera UV parallax updates at 20Hz only in
visible active rooms. Houses, terrain and world-character sprites are unchanged.

## Scope and review

- EchoGrotto.tscn: painted entrance and nine gallery backplates, clipped to
  their existing silhouettes; stone ledge facing, sparse plants and motes.
- StarfallCitadel.tscn: market district only, x=2820..4280. New masonry hall
  and townhouse, arched windows, stalls, local stone trim and lantern flicker.
- Original movement, colliders, doors, puzzles, actors and save rules unchanged.
- Background UV displacement follows the camera at a slower rate than terrain.
  This is a first parallax layer, not the final multi-layer foreground system.
- Static scenery draw commands are cached. Only tiny ambient accents redraw
  at 20 Hz; hidden/inactive rooms do not animate. Two shared source textures
  are reused, not a bitmap per chamber. Mobile performance is not certified.
- Ordinary town residents now have native-vector lapels, boots, hair/face
  detail, a movement-driven stride, subtle idle breathing and talking gestures.
  This augments the existing resident shapes, not a finished sprite sheet.
  Merchants, the player, enemies, combat animations, audio and the rest of the
  city retain their prototype appearance.

Open EchoGrotto.tscn or StarfallCitadel.tscn in Godot to see the integrated
art (tool script). In the running game, visit Echo Grotto / Starfall Market.
For a reproducible screenshot run, use the existing Godot executable with:
`--path . --rendering-method mobile --script res://tests/preview_visual_style.gd --quit-after 600`.
The preview uses a separate temporary save, never the player's save.

In-engine captures (not image-generator mockups):
- [Grotto overview](preview_grotto.png)
- [Grotto at gameplay zoom](preview_grotto_gameplay.png)
- [Starfall market](preview_market.png)
- [Apothecary and resident detail](preview_apothecary.png)

## Assets / provenance

Generated with the built-in imagegen tool on 2026-09-25, not the API/CLI.
No third-party game art was downloaded or copied. Native foreground details
are implemented in VisualStyleSlice.gd; generation was used for the two
raster background plates only. These source PNGs live inside the project:
- `res://art/visual_slice/grotto_backdrop.png` (1536 x 1024)
- `res://art/visual_slice/city_backdrop.png` (1536 x 1024)

### Exact generation prompt — grotto

Use case: stylized-concept. Asset type: production background plate for a 2D side-scrolling fantasy game, wide landscape 1536x1024. Paint an original subterranean echo grotto: immense softly layered mineral arches receding into midnight teal mist, tiny muted turquoise crystal veins, elegant eroded stone shapes and delicate hanging roots. Hand-painted 2D illustration with clear shape design, restrained brush grain, atmospheric depth, no 3D rendering. The center and lower third must remain quiet low-contrast deep blue for readable gameplay sprites added later. Distant scenery ONLY: no playable platforms, no ground ledge across the foreground, no characters, enemies, interface, text, logos or watermark. Edge colors deep midnight navy. Rich but restrained cyan illumination, not neon outlines. A reusable backdrop, not a screenshot or mockup.

### Exact generation prompt — city

Use case: stylized-concept. Asset type: production background plate for a 2D side-scrolling fantasy game, wide landscape 1536x1024. Original Starfall safe-city skyline at blue hour: layered old slate-roofed houses, tall narrow bell towers, stone arches and suspended footbridges receding into indigo atmospheric haze. A few tiny warm amber windows. Elegant hand-painted 2D illustration, softly textured brush grain, same restrained storybook dark-fantasy art direction as a turquoise crystal cavern. Side-on distant architectural elevation, NOT isometric, NOT 3D. Keep center and bottom third dark, low contrast and uncluttered for real gameplay buildings, NPCs and ground that will be overlaid by the engine. No foreground ground or platforms, no characters, no readable signs, no text, no UI, no logos or watermark. Broad sky and distant architecture, beautiful irregular silhouettes, no copied game landmarks.

## Validation / limitations

The visual smoke checks both scenes, 11 image plates, valid UVs, camera
response and inactive-room sleep. Collider paths/transforms/shape identities
and one-way flags are compared before and after attaching the art module.
Separate targeted gameplay regressions protect Grotto traversal and city state.

The final screenshots were rendered and visually reviewed with the project's
D3D12 Forward Mobile renderer on the desktop GPU. The isolated environment
reported the known Windows certificate warning and a shader-cache write
warning; screenshots still saved successfully. The earlier OpenGL preview
reported driver shader-initialization warnings, so it is not the accepted
renderer path.

The initially observed Starfall schematic-preview errors are fixed: previews
and gameplay share the same floor/anchor construction, with merged shaft
holes preserved. Six previews match all 15 doors, 15 arrivals and 126 sampled
portal anchors against their live scenes. A fresh full headless editor import
reports no script or missing-node errors. The sandbox still rejects editor
settings writes outside the workspace; that environment warning is not
presented as a project-script failure. Exact runtime results are recorded
in tests/LATEST_SMOKE_RESULTS.md.

## Second polish pass

The market treatment now includes the adjacent apothecary facade, a herb
sign and planters. Grotto greenery has less uniform spacing and finer stems.
No new generated bitmaps were needed: this pass extends the native editable
foreground art and reuses the two original plates. ResidentMotion.gd alters
only the existing visual children and draws detail; actor roots, collision
shapes, labels, route logic, indoor transitions and dialogue state are not
changed. Hidden residents stop animating; teleport/restore jumps are ignored
by the stride calculation.

## Reactive route vegetation and terrain relief (2026-10-03)

This code-native pass reuses the registered route/foreground/regional prop
atlases and terrain-edge paintings; it generates no replacement bitmap art.
Soft grass, shrubs and hanging growth bend toward actual player passage and
spring back. Their root/top anchors remain fixed, with small capped contact
motes. `WorldAmbience` uses a room-local 96 px spatial grid and a separate
12-object contact budget (6 in low-cost mode), alongside the existing 18/8
wind budget. Noclip, death, teleport and room changes clear transient contacts.

`WorldRouteRelief` adds three rounded shallow profiles to safe broad ground,
with collision and texture contours sampled from the same surface. Original
floors, jump mouths, one-way platforms, town streets and protected arenas are
not reshaped. The 134 placements in 20 rooms rise 22-30 world pixels; 842 small
painted props use their actual local height/tangent. Old city relief is stone
and soil over the paving, not warped ornamental masonry. Existing lower vaults
are clearance obstacles, so a new rise cannot consume normal-jump headroom.

The route-relief preview script writes representative live gameplay screenshots
under `art/characters/preview_route_relief_*` and a brush/recovery pair. Tests
and their final run evidence are documented in `tests/README.md` and
`tests/route_relief_verification_v1.json`; this is not a frame-rate benchmark or
a claim that every older scenic asset has received another art pass.

### Terrain contact follow-up

`WorldTerrainJoints` reconnects painted wall feet to their real supporting
floors: 37 small deposits in 21 rooms, with inset floor-edge caps where a cliff
alpha fringe exposed a black seam. Caps sample the registered outer edge of
the surrounding floor material instead of showing a square atlas cut. All
art stays at the physical junction; native collision geometry is unchanged.
The 134 shallow contours also carry 268 compact end deposits, bringing their
slope-aligned decoration total to 1110. Existing route atlases supply the art;
this follow-up does not add generated PNG sources.

`GroundContactFx` adds short, subtle dust grains to actual footfalls/landings,
using ray-tested contact points, slope normals and the native surface material.
Stone, shale, moss/soil, ash, wood and metal have different colours; wood/metal
surfaces emit at most two grains. There are no permanent footprints or rewards.
Small spawn corrections, idling, passive carrying, death, debug flight and
teleports do not create a continuous trail. The shared ambience driver owns a
40/12-grain capped pool, cleared on room changes. The four-corner and movement
captures are under `art/characters/preview_terrain_joint_*` and
`art/characters/preview_terrain_contact_*`; verification is in
`tests/terrain_contacts_verification_v1.json`.

The opaque outer rock mass now meets the exact collision boundary on either
side. Removing its former two-pixel inset closes the bright vertical sliver
beside deep foundations, without changing the playable edge or filling bridges.

### Compact Starfall tasks and route furnishings

Three new transparent source atlases contain 18 independently registered
cutouts (`starfall_task_stations_v1.png`, `starfall_task_registers_v1.png`,
`starfall_route_furnishings_v1.png`). The built-in imagegen prompts, original
source paths and SHA-256 hashes are preserved in
`starfall_task_art_manifest_v1.json`; source pixels are not edited. Godot uses
lossless mipmapped imports capped at 1024px and cached `AtlasTexture` crops.

`StarfallTaskAtlas` registers opaque support rows and uniform display widths.
Seven task ledgers are now 82/90px wide instead of 290px; nine stations have
distinct winch/terminal/seedbed/beacon appearances, with paired dormant/lit or
grown states. Five adjacent landmarks are grounded independently. Nearby
ceilings uniformly reduce art around its planted foot, never the interaction
body. A generic legacy receiver no longer overlays the specialized station.
Native task flags remain the only authority for state and report text.

Active lanterns/beacons pulse through the existing room animation budget;
garden patches use the existing player-contact spring, without moving roots.
Ground dressing and relief reserve these task props. G reads the actual
painted ledger, with individual objective marks and no duplicate sign.

Four smaller two-wheel caravans, six damaged barricades, and stone/plant/book
motifs across 30 side pockets replace remaining flat prototype drawings.
The long Rooted Hall root ribbons now have slight irregular bends and lower
contrast/width so they do not resemble solid walkways. No new colliders,
actors, rewards or save fields are introduced by this art pass.

### Living-route composition pass (2026-10-04)

The existing 48 registered `route_*` cutouts are reused in irregular plant
companions around rock/log groups: taller fronds behind the player, low leaves
in front, reserved space around interaction art and traps. Rear grass now uses
the same rooted wind/contact spring as foreground grass. Rigid rubble stays
rigid. `CanopySeep.gd` provides tiny intermittent root drips, traced to the first
actual floor; dry Ash rooms are excluded. Both effects use the existing shared
camera animation budget, with no private timers or physics objects.

Six physical route profiles include eroded shelves, shoulders and saddles in
addition to the original mounds. Adaptive low vaults reuse the existing ceiling
atlas modules and dark filled core, preserving jumping headroom and shaft mouths.
The nine Gallery conduits/manifolds now use the existing aged iron texture with
cross-pipe shading. Six expedition task/return rings are compact planted relics
whose parent modulation still follows native progress; G retains the full report.
No new raster sources or image edits were needed for this composition pass.

### Buried ceiling cross-sections (2026-10-04)

All 22 lowered RouteVaults now have an opaque `050a0d` interior, chipped side
and underside contours, and geological strata sampled from the existing
`terrain_foundations_v1` atlas. The underside reverses the floor's depth
direction; exposed sides have their own texture orientation. Sample blending
at corners avoids stretched texture streaks. Rock/root cutouts feather into
the core without leaving a straight black shelf at their upper crop.

The fill follows each existing solid vault rather than extending infinitely
upward: upper floors, shaft mouths and landing margins stay open and readable.
Both rim and backing belong to the vault, so support/obstacle retirement hides
everything together. Existing hanging details, drips and reactive understory
remain intact. This pass reuses registered artwork, with no new raster source.
Eight `preview_tunnel_vault_*` captures show four rooms from both playable tiers.
