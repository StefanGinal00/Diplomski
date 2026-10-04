# Smoke-suite checkpoints - latest 2026-10-04

## Regional reactive moth habitats - 2026-10-04

12 focused tests pass; all 12 native 1280x720 captures were inspected. Four
new transparent sheets provide 24 thorax-registered wing poses. The 39-room
audit retains 196 bounded moth habitats (at most six per room), using existing
supported vegetation without adding collision. Passing players cause eased
retreat and recovery; hidden/removed habitats, room warps and quality changes
are covered. Lamps, rotors, fauna and grass share the unchanged 18/8 animation
cap and 12/6 contact pool. Imports total 3,721,008 decoded bytes with mipmaps.
Actual controller contact was verified in four regions, and all 110 existing
low-vault traversal checks still pass. This is a focused continuation, not a
full campaign or whole-suite run. Evidence and preview limitations:
[ambient_fauna_verification_v1.json](ambient_fauna_verification_v1.json).

## Reactive scenery and grounded reading signs - 2026-10-04

18 focused tests pass; 12 native camera captures were inspected. Grass uses
actual painted/flex bounds and rebuilds when its support changes. New nearby
contacts no longer lose to old settling plants; upward jumps brush roots.
Flames and machinery retain part of the unchanged animation budget, and lamp
state updates immediately even outside that budget. Drops release from eight
registered opaque tips along 132 fully supported fall corridors.

All 596 readables remain available, with 585 grounded generic pedestals and
four cue-only fallbacks. A first-visit regression reproduces eight stale sign
fits before the fix and zero afterward across 39 rooms. Reentry, restoration
of disabled support, narrow scaled ledges and door clearance are covered.
110 actual-player ceiling traversal checks also pass. Detailed results and
limitations: [reactive_followthrough_verification_v1.json](reactive_followthrough_verification_v1.json).

## Buried tunnel ceilings and release regression - 2026-10-04

13 focused tests pass, including all 22 lowered vaults across 39 audited
rooms, actual-player ceiling traversal, terrain/foliage continuity, full boss
hurtboxes, projectile disposal, grounded pickups and outer-wall collision.
Eight native 1280x720 captures show four rooms from below their ceilings and
from the playable upper floor. The opaque fill never extends into that upper
route. Detailed evidence: [tunnel_vault_verification_v1.json](tunnel_vault_verification_v1.json).

The preceding living-route pass is recorded in
[living_routes_verification_v1.json](living_routes_verification_v1.json): six
physical profiles, 1468 additional understory details and 163 ceiling seeps.
These are focused checks, not a complete run of all 307 tests or a full
normal-health campaign playthrough. Native rendering/import runs also retain
documented sandbox cache/settings-write warnings; no script/shader compilation
errors were found. Local transient artifacts are excluded from the release.

## Starfall textured parallax - 2026-09-30

**14 distinct focused tests pass.** This is not the full suite, a continuous
manual traversal, exported-build sign-off or native-phone profiling. Reports
below use prefix `.tmp-smoke-suite-20260930-`.

| Test | Passing report suffix |
| --- | --- |
| background_quality | `145139-568-7d16396a` |
| city_background | `145139-568-7d16396a` |
| city_parallax | `150010-847-db97da9f` |
| city_parallax_runtime | `150010-847-db97da9f` |
| residential_facade | `150157-728-b2635626` |
| settlement_backdrop | `150151-016-06ea3341` |
| settlement_motion_budget | `145811-315-061ccfbc` |
| starfall_dawn | `150041-068-d81fd745` |
| starfall_upper_art | `145200-709-8e4fce04` |
| starfall_upper_city | `145200-709-8e4fce04` |
| starfall_upper_structure | `145200-709-8e4fce04` |
| visual_style_slice | `150153-897-e8c1aa3a` |
| world_ambience | `145747-770-5172a70b` |
| world_grounding | `150113-289-fd6c1ea8` |

New tests cover source alpha, 1536x1024 mipmapped imports, 16,777,208 decoded bytes,
six cached clipped regions, 230 audited retired leaf renderers, translated-room
transforms, unchanged physics/actors/markers, culled 24/16 draw caps, no idle-camera
redraw, idempotence, hidden-room suspension and no cumulative drift. Full-game
Camera2D tests cover two visits, three heights, both quality modes, exact horizon
uniforms, background viewport coverage and no city-state leakage into the cave.
Maximum measured projection error is 0.000395924 world units. An initial test
parse error was corrected with explicit Node/TextureRect types; the initial
strict relative float comparison was replaced with a documented 0.02-world-unit
absolute tolerance (<0.05 px at the native zoom), not a removed motion check.

Native review: `.tmp-city-parallax-preview-final.log`, D3D12 Forward Mobile /
RTX 4050, 1280x720. Eight floor-settled player placements and nine successful
captures, including camera travel (100,-60) with far UV change (0.010417,-0.004102).
All nine `art/characters/preview_atmosphere_parallax_*.png` frames were inspected;
initial oversized scenery was reduced and atmospheric contrast added. The final
native log contains two `_save_to_cache` write errors from existing BossAppearance
initialization and the root-certificate-store warning; captures finish, but do
not report this as a clean native log. Headless tests contain no unexpected errors.

Additional editor-hint check: `.tmp-city-parallax-editor.log` reports all four
successful standalone/combined-world captures and passes the single-sky / 230
retired-background-owner assertions. Standalone whole-city and combined-world
street overview images were inspected. The custom `--editor --script` harness
also logs null progress-window, outside-workspace AppData settings-save and
editor teardown RID errors; this is an editor art check, not a clean editor
lifecycle or manually inspected Godot-session sign-off.

User saves were not used; no commit/push. Remaining: prototype garden botany,
task markers/captions, bridge/workshop trim, further world dressing and real-phone
profiling. No new claim about the reported opening-enemy respawn defect.

## Residential facades and utility props — 2026-09-30 follow-up

**29 distinct focused tests have passing runs.** This is not the full smoke suite
or manual / exported-build / native-phone sign-off. New checks cover shared
atlas alpha/mipmaps and 7,447,448 decoded bytes, uniform scaling, real floor
support for doors/canopies, exact replacement scope, translated rooms, unchanged
actors/markers/physics, idempotence, 32 approach windows and native telescope feet.
The existing upper-art test now expects 103 retired polygons (the additional
telescope tripod); the atmosphere test expects 101 hangings (two old Haven lamps).

Reports below use prefix `.tmp-smoke-suite-20260930-`.

| Test | Passing report suffix |
| --- | --- |
| city_street_painted | `143112-762-725711a4` |
| driftworks_painted_art | `143112-762-725711a4` |
| echo_painted_props | `143112-762-725711a4` |
| echo_settlement_expansion | `143718-416-24670152` |
| rampart_painted_art | `143112-762-725711a4` |
| resident_painted_art | `143112-762-725711a4` |
| residential_facade | `143656-679-fa24003b` |
| room_painted_depth | `143112-762-725711a4` |
| service_painted_art | `143112-762-725711a4` |
| settlement_atmosphere | `143555-715-2f2db6bb` |
| settlement_backdrop | `143555-715-2f2db6bb` |
| settlement_building_art | `143555-715-2f2db6bb` |
| settlement_civic_art | `143555-715-2f2db6bb` |
| settlement_motion_budget | `143555-715-2f2db6bb` |
| settlement_portrait | `143555-715-2f2db6bb` |
| settlement_reading_occlusion | `143555-715-2f2db6bb` |
| settlement_street_art | `143555-715-2f2db6bb` |
| settlement_supports | `143555-715-2f2db6bb` |
| settlement_traversal | `143555-715-2f2db6bb` |
| settlement_walkway_art | `143555-715-2f2db6bb` |
| starfall_dawn | `143747-042-2e957fae` |
| starfall_prop_art | `143244-128-853ad819` |
| starfall_upper_art | `143659-469-37d0080f` |
| starfall_upper_city | `143659-469-37d0080f` |
| starfall_upper_structure | `143659-469-37d0080f` |
| visual_style_slice | `143720-628-02e192d0` |
| world_ambience | `143722-859-dcde9f70` |
| world_grounding | `143706-765-b99457de` |
| world_readables | `143731-368-e2d0be90` |

Native review: `.tmp-residential-preview-final.log` completed all ten captures
through D3D12 Forward Mobile / RTX 4050 at 1280x720. Each actual player settled
on a real floor for 60 physics ticks; all ten report true. Images are
`art/characters/preview_atmosphere_facade_*.png`. The initial camera targets for
two Echo views were outside their actual floor intervals; only the preview
coordinates were corrected. Visual inspection also exposed the missing approach
house material consumer, oversized initial doors/telescope and bulky gate posts;
those production issues were corrected before the final native captures.

The first new smoke test failed on unsupported schematic awnings. Floor selection
now requires the whole post footprint, with bounded scenery-only relocation to
nearby shelves. Native portal/actor/collider positions did not change.
Final runtime/native logs contain no unexpected script errors; Windows root
certificate-store warning remains the documented environment exception. The
editor import also cannot save outside-workspace AppData editor settings; the
assets imported and runtime tests succeeded. User saves were not used.

Open: old interactive task markers, some workshop/bridge trim, broader world
art and phone profiling. This pass makes no new claim about the reported
checkpoint enemy-respawn defect. No commit/push.


## Settlement atmosphere, civic art and readable field reports — 2026-09-30

**27 distinct focused tests have passing runs in this pass.** Not a full suite,
manual continuous traversal, exported-build or native-phone performance sign-off.
New tests cover 99 hanging details, six civic landmarks, no collider/actor moves,
opaque contact, uniform scaling, ceiling clearance, idempotence, all three atlas
imports, room/camera motion budget (18/8), retired runtime masks, nearby live
reports, safe modal pause, two viewport sizes and no quest/currency changes.
Old progression, streaming, save/load, native services, upper-city traversal and
dawn-light tests were rerun. Reports below use prefix `.tmp-smoke-suite-20260930-`.

| Test | Passing report suffix |
| --- | --- |
| ash_frontier_operations | `140514-280-3338c004` |
| city_street_painted | `140337-530-0dcf42a8` |
| echo_settlement_expansion | `140339-188-6c46b4ab` |
| hearth_board_readability | `140152-122-76e194df` |
| rampart_field_operations | `140153-641-de4d986e` |
| regional_ambient | `140313-311-4c39e57c` |
| service_painted_art | `140328-686-ddde7943` |
| settlement_atmosphere | `141041-379-73230e3f` |
| settlement_backdrop | `135905-530-46c78350` |
| settlement_building_art | `135905-530-46c78350` |
| settlement_civic_art | `135905-530-46c78350` |
| settlement_motion_budget | `140604-582-128ceeec` |
| settlement_portrait | `135905-530-46c78350` |
| settlement_reading_occlusion | `141234-280-1e98518f` |
| settlement_street_art | `135905-530-46c78350` |
| settlement_supports | `135905-530-46c78350` |
| settlement_traversal | `135905-530-46c78350` |
| settlement_walkway_art | `135905-530-46c78350` |
| starfall_dawn | `140245-285-97e5467a` |
| starfall_entry | `140236-171-078d6516` |
| starfall_field_office | `140139-422-ffe8aacc` |
| starfall_upper_art | `140234-251-49e3f52a` |
| starfall_upper_city | `135426-989-f3c603ad` |
| starfall_upper_structure | `135426-989-f3c603ad` |
| world_ambience | `140130-632-2c563b89` |
| world_grounding | `140257-878-cab6d01f` |
| world_readables | `141243-598-bfb51233` |

Three original imagegen sheets, 16 cutouts, 11,171,172 decoded bytes with mipmaps.
Full prompts/source/final paths: `art/visual_slice/CIVIC_AND_JOINERY_PROMPTS.json`.
`tests/preview_settlement_atmosphere.gd` produces seven native D3D12 camera views
(after real player floor settling) and one open field-report capture. Final log:
`.tmp-atmosphere-preview-delivery.log` (world views), with the final report UI
verified in `.tmp-atmosphere-report-fixed.log`. Images:
`art/characters/preview_atmosphere_{echo_terrace,smithy_lantern,cinder_joinery,fountain,noticeboard,garden,observatory,field_report}.png`.
These are automated renderer captures, not a manual playthrough.
The final report crop is also saved as `preview_atmosphere_field_report_settled.png`.
Native rendering revealed an asynchronous minimum-size expansion that the earlier
headless resize checks did not catch. The open panel now re-clamps after container
layout; a no-manual-resize regression was added. The native log confirms a
620x480 report inside the 1280x720 viewport with Close visible and text scrolling.

Fixes found by these checks: incorrect layer accumulation hiding pendants,
unsupported old armillary position, low balcony cutting through fountain,
expansion background masks covering the camera painting, the Cinder custom
block overlay masking material floors, and huge field-office tables.
The armillary was also moved clear of the street lift. An initial atlas script
type-inference error and unsupported preview probe were corrected before final runs.

The Ash frontier regression initially failed on an obsolete literal dialogue
phrase, not lost progress: the restored reports were 2/2 and the scout correctly
said “Claimed.” for the already-collected reserve. The assertion now explicitly
checks that claimed-reward state; production progression logic was not changed.
An initial civic coverage failure correctly rejected an unsupported old location;
the final pass does not relax the floor requirement.

## Painted services and streetscape - 2026-09-30

**43 distinct focused tests have passing runs. Not a full-suite, continuous
manual-traversal or phone-performance sign-off.** Reports use prefix
`.tmp-smoke-suite-20260930-`.

| Test | Passing report suffix |
| --- | --- |
| city_street_painted | `133222-113-fd8513f1` |
| forge | `133012-711-c0ba2577` |
| resident_painted_art | `132530-537-54cd2b6d` |
| service_painted_art | `132758-084-1acf9b19` |
| settlement_backdrop | `131314-694-b525f1af` |
| settlement_building_art | `131314-694-b525f1af` |
| settlement_civic_art | `131314-694-b525f1af` |
| settlement_portrait | `131314-694-b525f1af` |
| settlement_street_art | `132940-196-aafcd8f9` |
| settlement_supports | `131314-694-b525f1af` |
| settlement_traversal | `131314-694-b525f1af` |
| settlement_walkway_art | `131314-694-b525f1af` |
| starfall_arena_art | `131911-053-294e9706` |
| starfall_branch_art | `131911-053-294e9706` |
| starfall_courier | `131911-053-294e9706` |
| starfall_dawn | `132930-129-e43911b6` |
| starfall_dressing | `131911-053-294e9706` |
| starfall_empty_court | `131911-053-294e9706` |
| starfall_entry | `131911-053-294e9706` |
| starfall_expanded_route | `131911-053-294e9706` |
| starfall_field_office | `131911-053-294e9706` |
| starfall_field_operations | `131911-053-294e9706` |
| starfall_hollow_throne | `131911-053-294e9706` |
| starfall_inner_fields | `131911-053-294e9706` |
| starfall_outer_route | `131911-053-294e9706` |
| starfall_outskirts | `131911-053-294e9706` |
| starfall_population_support | `131911-053-294e9706` |
| starfall_prop_art | `131911-053-294e9706` |
| starfall_rooted_hall | `132445-441-6a8422db` |
| starfall_route | `131911-053-294e9706` |
| starfall_scenery_art | `131911-053-294e9706` |
| starfall_schematic_portals | `131911-053-294e9706` |
| starfall_soul_crucible | `131911-053-294e9706` |
| starfall_spawn_restore | `131911-053-294e9706` |
| starfall_sunless_passage | `131911-053-294e9706` |
| starfall_task_art | `131911-053-294e9706` |
| starfall_upper_art | `131911-053-294e9706` |
| starfall_upper_city | `131911-053-294e9706` |
| starfall_upper_structure | `131911-053-294e9706` |
| town_havens | `133021-256-aab035c9` |
| town_nameplate_layout | `132339-961-46edd74c` |
| visual_style_slice | `132559-455-524771c8` |
| world_grounding | `132807-876-039264d0` |

The Starfall batch initially finished 26/27: Rooted Hall assumed an enemy was
already patrolling immediately after a door transition, although room suspension
starts a safe recovery. The test now observes that bounded recovery, asserts its
strike area stays inactive, then still requires the warning and interruption
before checking native damage. Its focused rerun passed; no AI timing/damage was
changed to make the test pass. New-test type/room-ID mistakes and failed furniture
contact/UV assertions were corrected and rerun, not ignored.

Coverage: 10 service actors, four shared body identities with three poses each,
132 facade windows, 14 market stalls, and painted Starfall lamps/planters/benches/
cart. Five unchanged generated PNGs; 18,618,620 additional decoded bytes with
mipmaps at max-edge 1024. Exact prompts and saved paths:
`art/visual_slice/SERVICE_AND_STREET_PROMPTS.json`.

Thirty native D3D12 captures cover all ten services with idle/work-preparation/
greeting poses, checked gravity settling at every location:
`art/characters/preview_service_*.png`; `.tmp-service-preview-final.log`.
Preview review found and fixed duplicate Moon Forge furniture, a background
layer covering the Ward anvil, buried prop feet, and Polygon2D displaying an
entire atlas instead of its crop. New tests cover explicit UVs, support, native
shop signals/portraits, late population, F6 scenes, imports and stable collisions.
Purchase/forge, settlement traversal, 27 Starfall behaviors, native dawn/rollback,
nameplates and previous resident contacts have passing regression runs.

Remaining: hand-refined work cycles, bespoke named-service bodies, large fountain
and other authored sketch scenery, hanging ornaments, house supports and some
facade/platform intersections. Original intermittent respawn and real-phone
performance remain open. Expected host certificate-store messages and sandbox-
denied editor-settings writes occurred; final focused runs contain no script error.

## Painted residents and industrial fixtures - 2026-09-30

**14 distinct focused tests have passing runs. No full-suite, continuous manual
traversal or real-phone performance claim.** Report folder prefix:
`.tmp-smoke-suite-20260930-`.

| Test | Passing report suffix |
| --- | --- |
| resident_painted_art (96 residents, 6 looks, 17 fixtures, 39 rooms, frame contacts, late population, standalone town) | `082905-858-2214474d` |
| resident_motion | `082038-177-39b49756` |
| resident_conversation | `082039-165-4f878185` |
| town_ambient_life | `081510-411-8131db70` |
| town_nameplate_layout | `082621-551-4d08c6a5` |
| settlement_portrait | `081512-730-de0eb829` |
| ash_industry_dressing | `082456-583-b094d684` |
| ash_star_identity | `081918-301-1943d50d` |
| world_readables | `081922-583-883e86a0` |
| gameplay_review | `082921-022-dc04c0e0` |
| world_ambience | `082029-769-c51397d9` |
| regional_ambient | `082301-893-76beb29b` |
| world_grounding | `082316-775-59ac5360` |
| opening_checkpoint_regression | `082506-111-2a5c60fa` |

Four original sheets: 24 resident frames and four industrial cutouts. Shared
imports total 16,763,576 additional decoded bytes including mipmaps. Six regional
base looks are reused; this is not 96 distinct character designs. Actor roots,
routes, native conversations, shops/quests, collisions and saves remain native.
Thirteen native D3D12 captures cover six locations and extra pose/fan states:
`art/characters/preview_resident_*.png`, final log
`.tmp-resident-painted-preview-final.log`. Native player settling is checked at
all six locations. Preview review corrected oversized NPC proportions, distant
name labels, crossing ambient subtitles and remaining Barracks sketch furniture.

Failed intermediate runs identified type-inference errors and six unsnapped
overview landmark coordinates. Final art uses native gallery support X and Y,
actual floor tops and per-frame painted foot rows; original collision snapshots
remain unchanged. Host certificate/editor-settings and external shader-cache
warnings remain; no final GDScript errors. Tests use isolated workspace saves.
The original intermittent respawn report and real-phone profiling remain open.
Details: `REGIONAL_AMBIENT_VARIETY.md`; exact prompts and final PNG paths:
`art/visual_slice/RESIDENT_AND_INDUSTRY_PROMPTS.json`.

## Regional ambient compositions and wind - 2026-09-30

**11 distinct focused tests have passing final runs. Not a full-suite, continuous
manual traversal or real-phone performance claim.** Folder prefix:
`.tmp-smoke-suite-20260930-`.

| Test | Passing report suffix |
| --- | --- |
| regional_ambient (39 rooms, 1253 details, attachment/clearance, late devices, motion bounds) | `012806-890-7cd3cbed` |
| world_ambience (shared 18/8 animation cap, offscreen reset) | `012523-859-84bfe6a4` |
| gameplay_review (native collisions, materials, interactions, idempotence) | `012822-530-48722ed5` |
| world_structure (112 facades / 40 hoists) | `012838-180-4343d413` |
| world_grounding | `013051-085-8ebbcfb7` |
| world_readables | `013035-993-2b7ce9e8` |
| world_routes | `012849-833-478e5ca4` |
| ash_switchback | `012846-848-c39c7445` |
| settlement_backdrop | `012902-912-bb9ebdfb` |
| environment_hazard_art | `012853-464-569c7092` |
| opening_checkpoint_regression | `012854-495-01da0eda` |

Three new original atlases provide 18 cutouts; shared imports total 11,171,172
decoded bytes including mipmaps. There are 769 possible motion candidates,
not concurrent animations. 300 inert wedges and 1171 obsolete terrain/seep
lines retired. Known native hazard telegraphs are not targeted.

Nine native D3D12 captures (eight locations plus an alternate wind pose):
`art/characters/preview_ambient_*.png`, final log
`.tmp-regional-ambient-preview-final.log`. All eight locations report native
gravity settling. Preview inspection found and fixed opaque Forge background
coverage and Haven's leftover sketch overlays. It also records unresolved
settlement resident art/footing and large schematic mechanisms; this is not
artistic completion of those objects. Details: `REGIONAL_AMBIENT_VARIETY.md`.
Prompts/provenance: `art/visual_slice/REGIONAL_AMBIENT_PROMPTS.md`.

Initial failures caught imported crop rounding and cutouts intersecting nearby
platforms; both were repaired before final passing runs. Known host certificate
warnings and denied external shader-cache writes remain; no final script errors.
No user save was changed. The original intermittent respawn report stays open.

## Complete facades and supported hoists - 2026-09-30

**9 unique focused tests have passing final runs. No full-suite, continuous
manual traversal or phone-performance claim.** Report folders below use prefix
`.tmp-smoke-suite-20260930-`.

| Test | Passing report suffix |
| --- | --- |
| world_structure (39 rooms / 112 facades / 40 hoists, anchors, automatic late-device art, reentry, layers) | `004445-329-e3b08bd1` |
| world_grounding (3160 faces / 204 contacts / 112 passages / 26 boundaries) | `004310-448-41d3f3b7` |
| gameplay_review | `004459-688-e8bc9160` |
| room_door_interaction | `004127-080-e67ce4a0` |
| world_routes | `004135-251-47f4d892` |
| shaft_return_lift (15 local walks / 15 trips / 5 saved shortcuts) | `004445-363-0deafa95` |
| opening_checkpoint_regression | `004459-382-04dd2494` |
| world_readables | `004514-042-a1110ae2` |
| world_ambience | `004310-101-8e5d5b36` |

Eight native D3D12 captures were regenerated in
`art/characters/preview_grounding_*.png`; all eight report actual player
physics settling in `.tmp-structure-preview-final.log`. Structure anchors:
53 walls / 46 lower floors / 13 foundations. Three new shared atlases total
16,763,580 decoded bytes with mipmaps; this is not whole-game memory or a phone
benchmark. `WORLD_STRUCTURE_INTEGRATION.md` records scope and remaining issues;
`art/visual_slice/WORLD_STRUCTURE_PROMPTS.md` records exact generation prompts.

The first structure test caught an out-of-floor post and freed decorative-node
references during reflow. Both were repaired and rerun, not suppressed. A native
preview caught facade/lamp occlusion; corrected layering is now regression tested.
The original intermittent saved-enemy respawn is still unconfirmed. No user save
was modified. Known host certificate-store warnings remain.

## Ground contact and integrated entrances - 2026-09-30

**18 unique focused tests have passing final runs. Not a full-suite, continuous
manual traversal or phone-performance claim.** Report folders below use prefix
`.tmp-smoke-suite-20260930-`.

| Test | Passing report suffix |
| --- | --- |
| world_grounding (39 rooms, 3160 registered faces, 204 contacts, 112 passages, 26 boundaries; native gravity/walk/jump) | `002114-641-49708673` |
| ground_contact_assets (106 opaque-pixel rows independently verified) | `002202-845-c9309cf3` |
| gameplay_review (3187 textured surfaces / 186 devices, idempotence) | `002114-676-147660a2` |
| character_appearance | `001730-581-4ac85dfb` |
| player_gait_transition | `001734-832-0174d727` |
| crawler_appearance | `001603-614-71b64788` |
| echo_guide_appearance | `001607-858-5413f540` |
| echo_fauna_appearance | `001617-238-4e9516e9` |
| echo_grazer_appearance | `001626-877-7896848f` |
| ranged_attack_cue | `001634-943-27d51a28` |
| mob_attack_followthrough | `001639-218-ef11beb4` |
| mob_room_reentry | `001739-068-03a61fdd` |
| room_door_interaction (E/click/tap, lock, return) | `001631-584-40707b76` |
| world_routes | `001639-867-e1c0dfdf` |
| opening_checkpoint_regression | `001651-986-9a699cd3` |
| shaft_infrastructure | `001732-208-76e1d75b` |
| shaft_return_lift (15 local walks / 15 trips / 5 saved shortcuts) | `001833-852-04993630` |
| world_ambience | `001748-165-7051627c` |

Eight native D3D12 captures in `art/characters/preview_grounding_*.png`, with
actual player physics settling before each capture. Final logs:
`.tmp-grounding-preview-final.log` and `.tmp-grounding-lift-preview-final.log`
(last gantry refinement). Read `WORLD_GROUNDING_AND_PORTALS.md` for limits and
`art/visual_slice/PORTAL_CONTEXT_PROMPT.md` for generated asset provenance.
The original intermittent saved-enemy respawn remains unconfirmed, despite its
passing focused regression. No user save was modified.

Early failures uncovered test-harness assumptions (auto-named colliders,
world-coordinate rounding, and process-disabled collision removal); these were
corrected, not suppressed in the runner. The final pixel-data and native-motion
checks pass. Host certificate-store warnings are unchanged.

## Environmental readability and world life - 2026-09-29

**16 unique focused tests have passing final runs. No full-suite, phone-device or
continuous manual playthrough claim.** Three new tests cover the generated effect
frames, readable-note modal and bounded ambient motion. Report folders below use
prefix `.tmp-smoke-suite-20260929-`.

| Test | Passing report suffix |
| --- | --- |
| environment_hazard_art (8 native cases, 7 styles, 24 distinct raster frames) | `234456-213-195dd016` |
| world_readables (290 notices / 39 rooms, modal ownership, resize, replaced streamed source) | `234633-399-5c598de4` |
| world_ambience (222 grounded props, 18/8 budget, 15,836,060 decoded atlas bytes, no vine stretching) | `235032-474-c4ace13b` |
| gameplay_review (39 rooms / 3161 surfaces / 186 devices) | `234653-160-fc99dbaa` |
| shaft_infrastructure (independent pumps, reward gate, save/reload) | `234524-372-fe2ec0b9` |
| expedition_dressing | `234126-705-3b6de107` |
| story_lifecycle | `234141-840-286e8403` |
| opening_checkpoint_regression | `234208-603-92c36f99` |
| cistern_hazard_layout | `234219-129-3096e498` |
| hollow_hazard_layout | `234226-520-28dd4ea1` |
| attack_damage_range | `234517-277-fad9c1a9` |
| shaft_route_dressing | `234633-442-5f44a8e8` |
| echo_entry_growth | `234647-843-63512f3a` |
| boss_arena_finish | `234654-935-d7fcffb9` |
| world_population | `234748-434-5e335185` |
| encounter_streaming | `234759-049-83faab0f` |

13 native D3D12 fixed-camera captures: `art/characters/preview_worldlife_*.png`.
Final capture log `_tmp_worldlife_preview_final.log`; editor import log
`_tmp_worldlife_final_import.log`. Earlier failing development runs exposed missing
GDScript type declarations, combined RouteClue title/body storage, and parent-ready
ordering; repaired before the listed passing runs. Known certificate-store and
denied external editor-settings/shader-cache writes remain host-only messages.
Tests use isolated temporary saves, never the user's save.

See `WORLD_LIFE_READABILITY.md` and `art/visual_slice/WORLD_LIFE_PROMPTS.md`.

## Native gameplay screenshot repairs - 2026-09-29

**37 unique focused tests have passing final runs. No full suite/manual playthrough.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test/group | Final report suffix |
| --- | --- |
| opening_checkpoint_regression | `225621-051-79142d5c` |
| enemy_checkpoint, prop_checkpoint | `230511-821-403d97bb` |
| gameplay_review (39 rooms, 3161 surfaces, 186 devices, HUD fit, four atlases, relic clearance) | `231214-421-7fc89557` |
| attack_damage_range (including actual equipped defense) | `230001-925-713f1857` |
| six projectile tests | `224930-997-ab3d4be0` |
| ten appearance tests | `225055-637-e84cfbbc` |
| eleven boss tests | `225223-063-49055797` |
| boss_arena_finish rerun after separating shaft relics from entrances | `231035-355-5e33434a` |
| echo_entry_growth (33 clusters / 17 regional rooms) | `225255-087-c0bda7a3` |
| field_reserve_art | `225416-524-7f45d408` |
| sentinel_combat_flow | `225503-147-d4e10ea9` |
| driftworks_painted_art | `225727-119-bf9cf2c9` |
| pickup_claim | `231018-509-ed5b330a` |
| hollow_ore_survey | `230119-307-4dd90f0f` |
| echo_painted_props | `230143-198-a53ea7d4` |

Appearance/projectile/boss groups overlap; 37 is the deduplicated count. Initial
failures exposed a deferred background access during reload, nested entry floor
discovery, and an invalid unowned-defense test fixture; all have passing final
runs above. The reproduction also passed before persistence hardening: the
reported respawn is NOT root-caused. A separate isolated copy of the actual save
passed cold-load/death/revisit checks (`_tmp_review_actual_save_repro.log`), with
the original save hash unchanged. Diagnostics never point tests at the live save.

Ten final native Camera2D captures reviewed using the project's D3D12 renderer
(`_tmp_gameplay_review_placement_final.log`), also checked with Vulkan earlier.
GPU logs contain sandbox-denied shader cache writes; initial Compatibility mode
crashed in renderer setup and is not certified. Import's external editor-settings
write and host certificate errors are documented separately. Final smoke logs
contain no project script/runtime errors. See `GAMEPLAY_REVIEW_FIXES.md` for
the exact implemented scope, imagegen asset provenance and remaining work.

## Painted reserve markers - 2026-09-29

**8/8 focused tests have passing final runs. No full suite/manual playthrough.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| field_reserve_art | `220945-904-a90176b2` |
| regional_sign_layout | `220750-454-ea13581a` |
| shaft_route_dressing | `220806-879-1980a9c1` |
| shaft_deep_dressing | `220828-523-daeb40e0` |
| ash_route_dressing | `220852-484-1932179a` |
| ash_industry_dressing | `220800-417-3d4192d7` |
| starfall_dressing | `220811-891-6e1a460f` |
| exploration_ledger | `220839-404-7707f3f2` |

The art test checks 18 markers (5 Shaft, 6 Ash, 7 Starfall), high-resolution
transparent source textures, imported mipmaps, foot alignment, live seal
registration, idempotence, no added collision and controller updates. Existing
regional tests preserve save, streaming, captions and one-time reward behavior.
All final smoke logs have no project errors; the known certificate-store error
remains filtered as a host issue.

Three in-engine close-ups were inspected. A first Shaft preview showed foreground
timber hiding the artwork; a layer correction and second render resolved that
without drawing over walkable terrain. Separate preview/import host warnings
are documented in FIELD_RESERVE_ART.md. This is an art-only pass, not a claim
that prototype scenery or encounter pacing is finished.

## Regional route readability - 2026-09-29

**12/12 focused tests have passing final runs. No full suite/manual playthrough.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| regional_sign_layout | `215648-601-dbe0ad9d` |
| echo_field_sign_layout | `215456-138-283643de` |
| shaft_route_dressing | `215729-507-31ccc109` |
| shaft_deep_dressing | `215526-493-d4b4f0eb` |
| ash_route_dressing | `215548-084-0da4b33c` |
| ash_industry_dressing | `215558-015-f01d0504` |
| starfall_dressing | `215750-759-b29bb924` |
| exploration_ledger | `215506-346-1c2202b1` |
| encounter_streaming | `215532-559-29c96c14` |
| echo_room_dressing | `215818-824-76556dfa` |
| enemy_checkpoint | `215603-936-442ecf81` |
| localized_encounter | `215840-454-353452ae` |

126 captions in 18 Shaft/Ash/Starfall routes have layout, live-entry, progress,
stability and physics-preservation coverage; existing 75 Echo captions retain
their separate coverage. Native collection updates Shaft/Starfall signs and Echo
advice, while multi-cache encounter feedback waits for every linked receipt.
Initial failures exposed cramped Ash approach space, late-loaded board overlap,
old text expectations and an incorrect fixture path. These were corrected before
the final passing runs. No project errors appear in the final smoke logs; the
known certificate-store error remains filtered as a host issue.

Four automatic rendered close-ups were inspected and re-rendered after fixing
Reservoir overlap. Preview-only OpenGL shader initialization errors remain a host
rendering caveat; the four PNG captures succeeded. No manual traversal or final
combat balance claim. See REGIONAL_ROUTE_READABILITY.md.

## Regional exploration ledger - 2026-09-29

**13/13 focused tests have passing final runs. No full suite/manual playthrough.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| exploration_ledger | `214658-366-4be89f0d` |
| shaft_exploration_sites | `214518-438-1104ebe5` |
| echo_field_discoveries | `214537-540-972f7996` |
| echo_field_operations | `214559-791-8ebd71d3` |
| ash_field_operations | `214618-919-6c3d367a` |
| ash_frontier_operations | `214637-854-55332c42` |
| starfall_field_operations | `214610-456-97ae7e4f` |
| starfall_inner_fields | `214632-986-3e1cf2de` |
| rampart_field_operations | `214656-886-8d71a83f` |
| field_records | `214719-710-887049bc` |
| return_contracts | `214735-409-883a333a` |
| enemy_checkpoint | `214722-752-23cc8400` |
| world_population | `214738-324-cba25dad` |

The new test resolves all 26 catalog entries to real streamed reserves, checks
visited-only clues, all return states, dead-player/reentrant award rejection,
exact added supplies and existing base rewards, and save/reload without repayment.
Recovered dispatches remain readable outside their original rooms. Initial tests
found the Ash outskirts room-ID mismatch and a fixture comparing JSON floats with
integer inventory values; both were corrected before the final run. Final logs
have no project errors; the known host certificate-store warning remains.
Existing native field operations, records, return contracts, population and
enemy-checkpoint tests also pass. This does not certify economy or traversal
balance throughout the entire world. See EXPLORATION_LEDGER.md.

## Ground patrol terrain safety - 2026-09-29

**8/8 focused tests have passing final runs. No full suite/manual playthrough.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| ground_patrol | `213633-780-9a4c41bf` |
| neutral_creatures | `213638-445-0a5a3893` |
| world_population | `213648-001-918784ad` |
| enemy_checkpoint | `213703-320-aa0edfb0` |
| melee_impact | `213719-560-c23ae05a` |
| town_ambient_life | `213725-136-832c1d5e` |
| ash_arena | `213727-452-717c2d7d` |
| enemy_attack_art | `213742-888-3d3de5c4` |

Enemy, AshFiend and NeutralCreature now steer grounded patrols away from ledges
and walls, and hold an unsafe edge during pursuit. The probe looks past actors
to real support, handles solid/one-way floors and allows small downward steps.
Airborne falls and hit-stun knockback remain physical; fauna do not become hostile
from navigation. Speeds, health, rewards, spawns and map geometry are unchanged.

The new test covers 108 controlled cases, including both directions and
30/60/120 Hz patrol/chase/wall checks, small steps, actor-obscured probes and
physical falls/knockback. Initial testing found two 120 Hz neutral wall-jitter
cases; checking movement against the wall normal resolved both. All final focused
logs have no project script errors; known host certificate warning remains.
This is not complete pathfinding or certification of every authored route.
See GROUND_PATROLS.md.

## Checkpoint write-failure safety - 2026-09-29

**9/9 focused tests have passing final runs. No full suite/manual playthrough.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| save_failure | `212820-015-3334d286` |
| lamp_travel | `212343-520-33efa63c` |
| story_lifecycle | `212834-016-40ef824f` |
| enemy_checkpoint | `212907-091-c1d34a8f` |
| prop_checkpoint | `212922-119-6e4c22c2` |
| main_quest | `212830-307-18dc65fb` |
| story_scenes | `212844-022-75118d29` |
| campaign_flow | `212857-919-0481c83c` |
| starfall_field_operations | `212915-055-46db68d0` |

Checkpoint/lamp metadata now commits only after a successful disk replacement.
Temporary JSON is flushed/validated, a valid primary must be backed up first,
and primary/backup destinations are replaced without a preceding delete.
Failed lamp saves do not alter player respawn/activation; failed travel autosaves
report the error while keeping the completed trip and previous saved checkpoint.

New tests exercise real temporary-path open failure, injected copy and replacement
failure, rejected first save, successful retry, first primary without initial
backup, reentrant-save rejection, native timed-rest cleanup, UI fast travel and
death/reload to the old checkpoint. Live unsaved progression is not discarded.
Existing quest, cinematic, backup, enemy and crate-save tests pass.

The failure test intentionally emits handled WARNING diagnostics. No project
script errors occurred; known host certificate warning remains. These checks
do not simulate power loss or qualify other platforms. See SAVE_RELIABILITY.md.

## Ordinary-mob quick reentry safety - 2026-09-29

**10/10 focused tests have passing final runs. No full suite/manual playthrough.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| mob_room_reentry | `211641-248-a9096ecf` |
| world_population | `211719-263-35bf99f2` |
| encounter_streaming | `211732-825-1d9301b9` |
| enemy_checkpoint | `211742-889-f64a699e` |
| mob_attack_followthrough | `211802-361-0edf1495` |
| mob_charge_cue | `211729-379-0a2645e5` |
| enemy_projectile_contact | `211730-696-11feb6e3` |
| shaft_mixed_combat | `211844-510-3fa8e813` |
| shaft_guard_combat | `211858-616-06af5572` |
| echo_nest | `211904-943-87518f81` |

Seven ordinary-mob scenes now cancel stale windups, lunges/dives, followups and
root strikes when their active room is hidden, including the quick-return window
before unloading. The same living actor keeps HP/position and must prepare its
next attack normally. Same-room activation does not cancel fresh preparation.
Explicit population unload retires hostile shots by room or source ownership,
including shots parented elsewhere, with immediate late-contact protection.

New coverage checks 28 tier/attack-state interruption cases and explicit unload.
Existing automated live-AI tests completed 15 mixed encounters (12 with dives,
21 projectiles, 166 native sword attacks), plus 8 edge charges and a two-guardian
return fight. These are controlled combat checks, not final difficulty approval.

The first mixed-combat run failed because its standalone fixture never selected
its active room, so existing LocalizedEncounter guards correctly rejected every
trigger. Mixed/guard fixtures now select their native room ID before spawning;
no activity guard was bypassed. Final runs pass without project script errors;
the known host certificate warning remains. Details: `ENCOUNTER_STREAMING.md`.

## Prop checkpoints and pickup claims - 2026-09-29

**9/9 focused automated tests passed. No full suite or manual playthrough run.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| pickup_claim | `211040-443-187c1d68` |
| prop_checkpoint | `211050-224-f68242f4` |
| enemy_checkpoint | `211123-110-069e1154` |
| world_population | `211138-959-4dd1f590` |
| crate_presentation | `211151-781-26611a51` |
| crate_floor_placement | `211152-900-6661f477` |
| inventory_consumables | `211133-344-5419b9ac` |
| return_contracts | `211142-337-e06b3e9c` |
| main_quest | `211200-955-8610514d` |

Destroyed crate placements now persist at checkpoints, including unloaded rooms.
New coverage checks 82 crates across four biomes plus the passage, actual loot
collection, native death/UI restart, repeated streaming, unsaved destruction
rollback, backup recovery, legacy saves and new-game reset. Restoration never
rerolls loot or replays destruction. Existing RNG/presentation/placement tests pass.

Gold, items and XP accept collection once even if reward listeners reenter or
another contact arrives before deletion. Dead/non-player contacts and rejected
values do not consume the pickup; late timers cannot reactivate claimed loot.
Quest, inventory and prior enemy-persistence regressions pass. These tests do not
claim loose-loot disk persistence or final world-population completion.
No project script errors in final logs; known host certificate warning remains.

## Enemy checkpoint persistence - 2026-09-29

**8/8 focused automated tests passed. Full suite/manual playthrough not run.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| enemy_checkpoint | `210342-036-ff3aba31` |
| world_population | `210405-738-2fe7e3d2` |
| encounter_streaming | `210419-289-a7347ae7` |
| echo_nest | `210429-385-04669acf` |
| ember_barracks | `210415-978-b5bd2178` |
| ash_arena | `210430-086-cb009567` |
| story_lifecycle | `210444-569-fabbfc30` |
| return_contracts | `210520-940-7b64fc02` |

Ordinary enemy defeats now enter the disk checkpoint, including prior unloaded
rooms. The new regression uses real player death, the UI restart signal and
native scene reload, checking static/curated/authored/four-biome generated mobs,
an unsaved kill rollback, partial ambush and Nest progress, passage-gate counts,
backup recovery, legacy saves and new-game reset. Arena waves and boss rematches
retain encounter-level rules. No rewards are emitted to restore a saved kill.

Old saves have no historical enemy ledger; tracking begins with new defeats and
subsequent saves. Living-enemy HP/position remain session-local. Details and
content-key stability contract: `ENCOUNTER_STREAMING.md`.
Final logs contain no project script errors; known host certificate warning remains.

## Localized ambush streaming - 2026-09-29

**9/9 unique focused automated tests have passing final runs. Full suite/manual review not run.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| encounter_streaming | `205403-290-da6ddfea` |
| localized_encounter | `204925-122-d0708cec` |
| world_population | `205126-976-802e7748` |
| ash_field_operations | `205141-540-540bfc00` |
| starfall_field_operations | `205202-587-6adc335b` |
| echo_field_discoveries | `205228-011-076ab823` |
| ash_frontier_operations | `205247-405-72f87ebb` |
| echo_nest | `205413-740-c7b64d95` |
| return_contracts | `205429-035-1fa86fa4` |

Optional ambush survivors now unload through the same 10-second room-population
grace path as other mobs, retaining session-local HP, position and patrol anchors.
Quick reentry cancels the grace; later entry recreates survivors only. Attack state
restarts normally and stale projectiles are retired. Completed foes are not reborn,
unloading emits no defeat/reward, and completion callbacks are idempotent.

New coverage uses three authored biome ambushes plus a gated Echo return fixture,
checking room-exit/deferred spawn races, grace cancellation/deterministic expiry,
real node release, survivor state, required boss/tier/mechanism, bonus-health
stability, Nest exclusion and completion authority. Existing regressions confirm
field rewards, population and optional return contracts. Details/save boundary:
`ENCOUNTER_STREAMING.md`.

The expanded test initially had two GDScript inference errors; explicit Node
types corrected them. Final focused logs have no project script errors; the known
host certificate warning remains. No manual traversal, new art, map geometry
changes or measured whole-game RAM/FPS claim in this pass.

## Native story lifecycle and reloads - 2026-09-29

**14/14 unique focused automated tests have passing final runs. No manual review or full suite run.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| story_lifecycle | `203330-063-2c64e186` |
| story_scenes | `203205-370-9828abc9` |
| campaign_scenes | `203215-829-146ee39e` |
| campaign_flow | `203223-093-124bd571` |
| story_pacing | `203235-138-3e72b0aa` |
| boss_music | `203242-111-c5a7c43b` |
| main_quest | `203249-225-411be1f1` |
| main_story | `203258-831-c7352aaf` |
| world_story | `203305-230-4d7bde79` |
| story_route | `203311-928-b90b698a` |
| quest_narrative | `203318-428-64db1139` |
| encounter_story | `203324-832-5a6e85d0` |
| field_records | `203334-414-2ea5fe77` |
| starfall_hollow_throne | `203344-752-5de169c5` |

New lifecycle test invokes actual death, retry buttons and six native scene
reloads. Normal saved return rolls back unsaved boss rewards and an interrupted
scene without losing prior receipts; a deliberately corrupted isolated primary
save recovers its consistent older backup. Old audio nodes are released.

The initial run reproduced three missing intros: no-save normal retry, Hardcore
retry and switching from Hardcore to Normal. Fixed with an explicit transient
one-shot opening request consumed after the replacement UI is ready. It is never
serialized; ordinary saved continuation and direct test boots do not request it.
Tests also cover request consumption, retained mute preference, Hardcore save
deletion, clean Restart Journey menu and its native new-game button.

Only `res://_tmp_story_lifecycle.json` and its own backup/temp siblings are used
for the destructive recovery fixture; the user's save is not touched. Final
focused logs contain no project script errors. Known host certificate-store
warning remains. No visual/manual traversal, audio listening or new art in this pass.

## Campaign flow and postgame handoff - 2026-09-29

**6/6 unique focused tests have passing final runs. Full suite/manual traversal not run.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| campaign_flow | `201310-778-de0f7a02` |
| campaign_scenes | `200939-598-0013d497` |
| story_scenes | `200947-111-cc69e28a` |
| main_quest | `200957-394-5d73ce6f` |
| starfall_hollow_throne | `201132-584-73733610` |
| story_pacing | `201020-342-b16a1556` |

Two start-to-finish event-driven campaign checks cover native boss deaths,
world-progress APIs, early/late memories, ordered boss/milestone scenes, deferred
versus staged claims, and all eight quest bundles (820 Gold, 5 SP plus items).
The scenario explicitly bypasses traversal/puzzles through progress APIs and
applies lethal boss damage: this is integration coverage, not a fair-combat clear
or elapsed-time/difficulty/economy validation.

The epilogue's Review rewards button and [J] now enter the paused quest log with
the claim action focused, without paying rewards or skipping an active movie.
Hints count pending bundles and distinguish already-claimed rewards. Stale victory
notifications are cleared during the handoff. Three desktop sizes checked.
After the finale, old unseen interludes remain replayable without being forced
at a lamp; an unacknowledged finale retains priority. Unsaved victory/scene/rewards
roll back together, and saved completed progress cannot duplicate the last bundle.

Four native 960x540 captures reviewed: epilogue with 8/1/0 pending bundles and
focused journal handoff (`art/characters/preview_campaign_rewards_*.png`).
Preview log: `.tmp-campaign-rewards-preview.log`; known host certificate and
shader-cache warnings remain. Final focused logs have no project script errors.
No new artwork/audio or external state changes in this pass.

## Story pacing and reading mix - 2026-09-29

**7/7 unique focused tests have passing final runs. Full suite/manual campaign not run.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| story_pacing | `193034-744-bec5cc77` |
| campaign_scenes | `193042-734-018ce7b5` |
| story_scenes | `193252-999-ccc191f1` |
| boss_music | `193101-623-1fe0d029` |
| main_quest | `193208-751-29d13e22` |
| story_route | `193219-576-e08e1384` |
| starfall_hollow_throne | `193226-677-db5d3cc1` |

Live scenes now require a continuous quiet window, reset by threats, attack
release, dash and door transitions. Failed playback retains the queue entry.
Safe-lamp offers cannot overlap door transitions. Tests exercise interrupted
windows as well as the previously covered native boss/arena events.

Guardian/memory narration adapts to actual progress and is snapshotted per replay.
Both contextual variants pass three desktop sizes and were visually reviewed in
native 960x540 captures `art/characters/preview_story_pacing_{guardian,memories}.png`.

Scene/library music ducking uses a separate gain envelope, retaining track
identity and crossfade cleanup. Tests cover paused fades, rapid cancel/reopen,
mute/unmute, outgoing release and nested pause. This is lifecycle/mix-state
validation, not a listening review. Initial GDScript type-inference error in the
new context helper was fixed before all passing runs. Native preview retains
known host certificate/shader-cache warnings; no final script errors.
No new artwork or third-party audio downloaded in this pass.

## Campaign-wide illustrated sequences - 2026-09-29

**10/10 unique focused tests have passing final runs. Full suite and end-to-end campaign pacing not run.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| campaign_scenes | `191945-322-703544e3` |
| story_scenes | `191953-713-398e0f05` |
| main_quest | `185215-133-9dfdea3c` |
| main_story | `185421-296-05d490f2` |
| encounter_story | `185428-981-b4c05f7b` |
| quest_narrative | `185752-349-85df2a23` |
| quest_portrait | `185800-279-5b95df69` |
| field_records | `185808-629-add3002a` |
| ash_arena | `185821-670-ca9dd2e3` |
| starfall_hollow_throne | `191150-038-4762f471` |

Ten sequences / 31 shots: opening, seven principal boss/trial victories and two
main-quest milestones. Each event has three distinct images; the finale has four.
Twenty-one new selected illustrations join nine existing assets (one intentional
cross-event shelter recall). Built-in imagegen prompts and selected paths are in
`art/story/CAMPAIGN_PROMPTS.md`; two rejected first versions remain unused.

Coverage includes native boss-death queues, grounded/threat-free playback delay,
full Marshal arena gating, milestone transitions, four-shot finale returning to
the paused epilogue, replay scrolling/focus, catalog migration and cleanup.
Initial fixture failures were corrected by keeping the player's physics body
active, setting the native throne room, and waiting for library container layout.
All final targeted runs pass without project script errors.

The native preview generated 25 captures: all 22 newly added sequence shots,
library top/bottom, and epilogue return. Representative shots, corrected finale
image, library and epilogue were visually reviewed. All selected new source
illustrations were also inspected. Preview log: `.tmp-campaign-scenes-preview.log`;
captures: `art/characters/preview_campaign_*.png`.
Known host certificate/D3D shader-cache/editor-settings warnings remain.
No voice-over, mobile review or full manual campaign pacing sign-off.

## Multi-shot scenes and gradual narration - 2026-09-29

**5/5 unique focused tests passed. Full suite and full campaign pacing not run.**
Report directories use prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| story_scenes | `184234-306-d1bddb58` |
| main_quest | `183901-076-85b85425` |
| encounter_story | `184140-068-7f045b53` |
| main_story | `184151-489-e7b042cc` |
| starfall_hollow_throne | `184201-309-00e6c557` |

Six new 1672x941 PNGs, nine total illustrations paired one-to-one with pages.
Deterministic timeline tests cover partial text, reveal-before-advance, crossfade,
automatic completion, manual hold, auto-resume reading time, immediate skip,
cancel/replay isolation and texture release, plus prior gating/save/pause checks.
All nine image paths/resolutions and page layouts checked at three desktop sizes.
Native 960x540 previews include partial narration, mid-crossfade, complete shots,
journal and library; log `.tmp-story-sequence-preview.log`. Known host certificate,
D3D shader-cache and external editor-settings warnings remain; no script errors.
Prompts and project asset paths: `art/story/README.md` (built-in imagegen).
No voice-over, mobile review or end-to-end campaign pacing sign-off.

## Illustrated opening and chapter scenes - 2026-09-29

**10/10 unique focused tests have passing final runs. Full suite not run.**
Report directories have prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| story_scenes | `183001-317-f3ca28d8` |
| main_quest | `182724-882-61c1ca1c` |
| main_story | `182735-799-4699f732` |
| world_story | `182742-832-9cbec48a` |
| encounter_story | `182750-815-68162163` |
| quest_portrait | `182801-967-7e9cc455` |
| quest_narrative | `182809-486-b0309ca7` |
| field_records | `182817-026-8569ee20` |
| starfall_hollow_throne | `182829-546-c3164255` |
| starfall_dawn | `182843-796-1ae0254f` |

New coverage: actual new-game UI entry, three chapter eligibility states, safe
lamp offers, no reward-triggered movie, nine pages at three resolutions,
skip/replay/pause ownership, non-rewarding playback, save/rollback, legacy
backlog suppression, death cancellation and finale priority. Initial new-test
type-inference error was corrected; the final run has no project script errors.
An attempted `normal_death_smoke.gd` filter matched no test and is not counted;
death cleanup is explicitly covered by the new story-scenes test.

Three generated 1672x941 illustrations imported from `art/story/`; original
prompts and built-in tool provenance in its README. Five native 960x540 captures
visually reviewed: `art/characters/preview_cinema_{opening,haven,memories,
journal_actions,library}.png`. Log: `.tmp-story-scenes-preview.log`.
Known host certificate/shader-cache and external editor-settings write warnings
remain. No voice-over, full-run pacing, mobile or remaining-chapter sign-off.

## Linked main quest and first-clear rewards - 2026-09-29

**13/13 unique focused tests have passing final runs. Full suite not run.**
Report directories have prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| main_quest | `181658-167-9e1a5454` |
| main_story | `181356-380-ba4a0f95` |
| story_route | `181403-888-9698c8b6` |
| quest_portrait | `181411-116-fbed2e56` |
| quest_narrative | `181418-584-105c3517` |
| world_story | `181425-844-50904698` |
| defense | `181433-678-5bb5a645` |
| inventory_consumables | `181440-930-9551d10a` |
| starfall_hollow_throne | `181448-344-fd055e9a` |
| ash_arena | `181502-650-31af3174` |
| starfall_route | `181514-061-7ae2bebd` |
| starfall_dawn | `181525-335-8afcbdca` |
| field_records | `181536-400-c86c59e4` |

Main quest coverage: 256 progression combinations, eight linked stages,
three-part reward bundles, real journal claim button, exact item/gold/SP amounts,
duplicate/reentrant rejection, independent side tasks, legacy saves without
receipts, unsaved rollback, saved final reward and new-game reset. Claim UI
checked at 960x540, 1280x720 and 1920x1080. Wayfarer Mantle tested for mitigation
at 1/2/3/4 incoming damage, dash cooldown, no implicit Dash unlock and unequip.

Six native 960x540 captures reviewed in `art/characters/preview_main_quest_*.png`:
start, first bundle, next stage, final bundle, complete history and ending hint.
Preview log `.tmp-main-quest-preview.log`; existing host certificate/shader-cache
warnings remain. No full-run economy/pacing approval; introduction and chapter
cutscene art remain deliberately deferred. See `MAIN_QUEST.md`.

## Encounter story transitions - 2026-09-29

**11/11 unique focused tests have passing final runs. Full suite not run.**
Report directories have prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| encounter_story | `180401-887-f6a94ecf` |
| main_story | `180035-241-8fd6e5bc` |
| world_story | `180042-293-b6de7aa5` |
| story_route | `180049-836-657e0729` |
| memory_revelation | `180057-228-c185c41b` |
| field_records | `180108-244-31da2218` |
| ash_arena | `180236-379-0b861bdc` |
| echo_sanctum | `180132-499-932a0aaa` |
| ash_castellan | `180333-841-bd8114dd` |
| starfall_hollow_throne | `180203-804-29e917ee` |
| starfall_dawn | `180219-064-603b8a8a` |

New coverage: six discovery-gated approaches/aftermaths, three viewport sizes,
native boss deaths, actual arena completion, warnings before aftermath,
duplicate/rematch suppression, mixed record/memory queue, no replay on load,
new-game reset and finale cleanup. Initial fixture failures (assuming every
boss has `die()`, then retaining a freed boss across a frame) were fixed by
using native `take_damage()` and performing signal checks before deletion.

Native visual review: `art/characters/preview_encounter_*.png`; log
`.tmp-encounter-story-preview.log`. The preview preserves the awakening banner
before displaying the aftermath. Shortened the previously overflowing
Castellan victory HUD. Renderer retains the known host certificate/shader-cache
warnings. No complete manual continuity/pacing playthrough or audio sign-off.

## Story route continuity - 2026-09-29

**14/14 unique focused tests have passing final runs. Full suite not run.**
Report directories have prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| story_route | `174033-147-d3f8a173` |
| main_story, world_story | `173854-667-937348f7` |
| quest_portrait | `173916-543-441380e1` |
| quest_narrative | `174216-877-925374ec` |
| ash_arena | `173930-438-07987c2d` |
| ash_chapel | `173941-338-e52b8cf5` |
| echo_nest | `173952-443-f95f0887` |
| echo_survey | `174003-471-4783f3cc` |
| starfall_route | `174205-696-78c8360b` |
| ash_hearth | `174028-454-04cc2d06` |
| field_records | `174029-672-0ac96ac7` |
| starfall_courier | `174223-939-693c81ff` |
| starfall_hollow_throne | `174234-976-7139523e` |

New regression covers 40 Echo/Ash prerequisite combinations, native door
requirements, late missing memories, four precompleted tasks, real button
acceptance/claims, duplicate-payout rejection and three contacts before/after
the finale. Dialogue bounds checked at 960x540, 1280x720 and 1920x1080.

An initial `starfall_route` run failed an outdated assertion that the completed
task title must disappear entirely. The journal intentionally preserves
`RESOLVED - Lantern Route`; the test now independently verifies no claim button,
no active `SIDE:` objective and the retained outcome. Reward checks remain.

Four native rendered captures visually reviewed:
`art/characters/preview_story_route_{early_survey,marshal,eldric_homecoming,journal}.png`.
Text/actions fit the 960x540 UI. Preview log: `.tmp-story-route-preview.log`.
The renderer reports the existing host certificate/shader-cache warnings;
all four images were saved successfully. No full manual story/pacing playthrough
or audio listening sign-off is implied.

## Optional field records - 2026-09-29

**12/12 unique focused tests have passing final runs. Full suite not run.**
Report directories have prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| field_records | `172223-583-882b30ca` |
| world_story | `171736-582-c848f020` |
| memory_revelation | `172117-430-5bb733c8` |
| main_story | `171755-499-9e91c38e` |
| quest_narrative | `171802-823-dfde255e` |
| return_contracts | `171810-818-b24b862c` |
| world_population | `171825-681-0e8e4cc4` |
| blackwater_cistern | `171835-405-cdff9805` |
| ash_chapel | `171847-423-dcb9e095` |
| prism_archive | `171858-822-f0be637d` |
| starfall_outer_route | `171945-715-550434b9` |
| starfall_dawn | `171914-990-78111c6b` |

Eight actual cache instances verified (including native return-spawned Echo
caches), existing seals/rewards, record cues, duplicate-open rejection,
spoiler-safe full journal and paired interpretations, four resident replies,
mixed record/memory discovery queue, save/reload and unsaved rollback. Existing
opened caches restore their text/cue without replay or payment. All eight
excerpt cards checked at 960x540, 1280x720 and 1920x1080 for overflow, viewport
bounds and separation from reward notifications.

Native D3D12 cache/discovery/journal/Ivara captures inspected at 960x540:
`art/characters/preview_records_*.png`. Discovery cards moved below reward
notifications after the first visual review. Log: `.tmp-field-records-preview.log`.
Known host certificate/shader-cache warnings remain. No full-route manual
playthrough or full-suite completion claimed.

## Living-world story and ending - 2026-09-29

**10/10 unique focused tests have passing final runs. Full suite not run.**
Report directories have prefix `.tmp-smoke-suite-20260929-`:

| Test | Final report suffix |
| --- | --- |
| world_story | `151647-105-a8ac2b35` |
| main_story | `151417-157-f209a391` |
| world_timeline | `151424-097-d12c0d67` |
| starfall_dawn | `151431-998-beaa2304` |
| starfall_hollow_throne | `151442-568-9258261d` |
| quest_narrative | `151456-754-e151bdd3` |
| settlement_portrait | `151503-870-577c82f3` |
| resident_conversation | `151510-961-8c748ced` |
| memory_revelation | `151515-413-f600a439` |
| return_contracts | `151525-912-f6a353dd` |

The new fixture checks 255 live dialogue lines for twelve residents across
960x540, 1280x720 and 1920x1080; also five live mission reactions, unclaimed
versus completed states, combined memory/task outcomes, no progress mutation,
new-game/reset and actual saved rollback. History stays gated by discovery and
defeat, rematches do not duplicate it, and Atley interprets only collected memories.
Arrival/ending presentation, pause/continue and save-hint separation are checked.
Existing final-boss/quest/timeline/social regressions retain their assertions.

Native D3D12 captures `art/characters/preview_world_story_*.png` inspected:
Neris's drowned-bell response, Atley's interpretation, Vey's homecoming and
both ends of the expanded ending scroll. Log: `.tmp-world-story-preview.log`.
Known host certificate/shader-cache warnings; no project script errors in these runs.
This is not a full continuity playthrough, environmental-story completion or
audio listening review.

## Mission narrative and boss music - 2026-09-29

**18/18 unique focused tests have passing final runs. Full suite not run.**

All report directories below have prefix `.tmp-smoke-suite-20260929-` and
contain `results.json` plus individual test logs:

| Test | Final report suffix |
| --- | --- |
| boss_music | `142521-811-aa133694` |
| quest_narrative | `143012-738-a2bf5ce1` |
| ash_arena | `142657-465-3d1cac4c` |
| ash_castellan | `142708-118-3438aa66` |
| echo_sanctum | `142722-041-145e91ea` |
| shaft_zone | `142736-675-5882f9b7` |
| starfall_empty_court | `142750-975-ad369815` |
| starfall_hollow_throne | `142804-635-0b2e2a76` |
| main_story | `142818-709-51b9e62d` |
| quest_portrait | `142825-883-7a24beed` |
| echo_survey | `142832-675-94cb9474` |
| ash_hearth | `142845-877-1fac7aeb` |
| starfall_courier | `143019-821-8838124a` |
| starfall_dawn | `142858-149-89012294` |
| return_contracts | `142908-916-9d045bf8` |
| boss_encounter_safety | `142922-937-b068c155` |
| boss_arena_finish | `143056-340-28ad5ebf` |
| sentinel_combat_flow | `143103-506-80b0ab9a` |

New music fixture verifies seven distinct imported streams (69.8–123.4 seconds),
loop configuration, boss/miniboss signals, idempotent registration, mute/unmute,
death cancellation, victory/finale, room exit and outgoing resource release.
The arena regression verifies the actual Marshal wave starts its own theme.
Existing rematch tests verify dynamically registered encounters retain music.
Sources, CC0 licenses and original SHA-256 values: `audio/music/CREDITS.md`.

New mission fixture covers 24 quest states across three viewports, live contact
selection, action visibility, portrait/fallback layout, active reasons/resolved
outcomes and no save/reward mutation. Initial failures caught an overlong courier
offer and fixture assumptions that every NPC had a portrait. The fixture now
checks native portrait/no-portrait paths. Courier regression caught loss of the
full destination name; the shorter offer restores Whisperlight Haven and Cinder
Hearth. Final tests pass without changing their reward/save assertions.

D3D12 captures `art/characters/preview_mission_*.png` visually reviewed at
960x540: Lyra hand-in, Rook courier, Atley offer and journal outcome scrolling.
Shortened courier buttons to avoid clipping. Editor import also exposed an
existing @tool arena decorator calling non-tool door runtime fields; gated only
those runtime writes/status calls. Final import has no script errors.
Known host certificate/shader-cache/editor-settings permission warnings remain.

Not claimed: an audio listening/mix review, perfect loop audibility, a complete
manual playthrough, full-suite pass or every resident's final story writing.

## Main storyline foundation - 2026-09-29

**7/7 unique focused tests have passing final results. Full suite not run.**

Report folders (`results.json` in each):

- main_story: `.tmp-smoke-suite-20260929-130445-908-f60ed503`
- quest_portrait: `.tmp-smoke-suite-20260929-130452-677-9b742823`
- memory_revelation + memory_sigils: `.tmp-smoke-suite-20260929-130049-212-250c31c9`
- echo_survey: `.tmp-smoke-suite-20260929-130112-448-72e5d3ab`
- starfall_courier: `.tmp-smoke-suite-20260929-130125-209-2344da5a`
- starfall_hollow_throne: `.tmp-smoke-suite-20260929-130205-671-2947d0f6`

New fixture covers 80 guardian/sigil/route combinations, native journal display,
hidden unknown memory text, read-only save projection, rematch independence,
actual isolated save/load rollback, new game, both early/late Eldric handoffs,
Rook text bounds and arrival-title dismissal when opening story interfaces.
Existing portrait test checks Eldric/Lyra quest states at 960x540, 1280x720,
1920x1080. It caught initial long-line overlap; copy was shortened and rerun.

D3D12 opening/missing-memory journals and Eldric/Lyra offers inspected at
960x540. Arrival title no longer obscures conversations or the journal.
Known host certificate/shader-cache warnings remain; no project script errors.
No new raster generation, full manual playthrough, export, commit or push.
`git diff --check` clean. Story writing remains in progress; see `STORYLINE.md`.

## Boss + arena completion pass - 2026-09-28

**21/21 unique focused tests have passing final results. Full repository suite not run.**

Workspace-root-relative folders, each containing `results.json`:

- ten `boss_*` tests: `.tmp-smoke-suite-20260928-234711-532-e872421b`
- sentinel_combat_flow: `.tmp-smoke-suite-20260928-234756-633-e61362f0`
- arena_navigation_support, ash_arena, starfall_arena_art: `.tmp-smoke-suite-20260928-234457-284-ebfda659`
- ash_castellan + rollback: `.tmp-smoke-suite-20260928-234221-700-41f94d38`
- starfall_empty_court: `.tmp-smoke-suite-20260928-234245-704-c9851e58`
- starfall_hollow_throne: `.tmp-smoke-suite-20260928-234259-195-3bf1515a`
- warden_approach: `.tmp-smoke-suite-20260928-234312-862-5813f94d`
- remaining_room_art: `.tmp-smoke-suite-20260928-234616-545-9f5d35ed`
- echo_sanctum: `.tmp-smoke-suite-20260928-234741-769-a8812046`

New safety fixture: 7 bosses x 5 interruptions. Native locomotion checked at
30/60/120 Hz and both arena bounds. Arena finish audits 19 doors' materials,
unchanged transforms/collisions/destinations, and specific decoration repairs.
Sentinel fixture now expects live hostile bolts to retire on player death;
remaining-room art fixture audits build mutations before deliberately hiding
the room (hiding now legitimately resets boss animation transients).
Initial fixture parse/setup failures were corrected and rerun; final reports
above pass. All seven authored arenas reviewed in D3D12 captures, plus native
Warden motion samples. Known host certificate/shader-cache warnings remain.
No full manual playthrough, export, new raster generation or Git push.
[Scope and visual evidence](../art/characters/BOSS_ARENA_MILESTONE.md).

## Painted player spell / Ember flight - 2026-09-28

**5/5 unique focused tests PASS. Full repository suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- player_projectile_flight: `.tmp-smoke-suite-20260928-232159-623-6665c03d`
- projectile_appearance: `.tmp-smoke-suite-20260928-232025-824-9f66113a`
- player_projectile_lifecycle: `.tmp-smoke-suite-20260928-232200-625-a4589d10`
- projectile_impact: `.tmp-smoke-suite-20260928-232201-379-c39c2481`
- projectile_hit_budget: `.tmp-smoke-suite-20260928-232202-208-4c025963`

New fixture checks 72 combinations of variant, frame rate and aim, isolated
spell palette materials, flight-only atlas cells, compact bounds and hidden
reset. Existing tests cover native stats/geometry, actual shot hit budgets,
impact dedup and deferred-damage cancellation.

D3D12 captures of two flight cells and gameplay-scale Echo Grotto inspected.
Final visual iteration removed the disconnected Frost orbit stroke.
Known host root-certificate/shader-cache warnings; no project script/shader
compilation errors. No new raster generation, full manual fight or export.
`git diff --check` clean.
[Details and captures](../art/characters/PLAYER_FLIGHT_FLIPBOOKS.md).

## Player projectile lifetime and deferred-damage cancellation - 2026-09-28

**6/6 unique focused tests have passing final results. Full suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- player_projectile_lifecycle:
  `.tmp-smoke-suite-20260928-231218-453-170e0f97`
- projectile_appearance, updated retirement expectation:
  `.tmp-smoke-suite-20260928-231142-967-c2c41eaf`
- projectile_impact: `.tmp-smoke-suite-20260928-231009-616-da00c54d`
- projectile_hit_budget: `.tmp-smoke-suite-20260928-231010-531-e68777c7`
- weapon_styles: `.tmp-smoke-suite-20260928-231219-981-bb5a5b51`
- shaft_ranged_combat: `.tmp-smoke-suite-20260928-231300-971-660a21ab`

The original projectile appearance assertion expected a hidden shot to become
live again and failed in `.tmp-smoke-suite-20260928-231036-216-d6201e13`.
Updated it to assert the intended non-revival lifecycle; final rerun passes.
No damage/balance expectation was relaxed.

New coverage: 50 lifecycle/reserved-hit combinations, normal/piercing hit
resolution, hidden/transition spawns, rotated-room facing, paused rest and
signal disposal. Existing physical tests cover hit budgets and terrain order;
live Shaft tests exercise four ranged loadouts, resources and combat.
`git diff --check` clean. No new raster assets, export or full manual
playthrough performed in this correctness pass.
[Details](../art/characters/PLAYER_PROJECTILE_LIFECYCLE.md).

## Painted player projectile contact effects - 2026-09-28

**5/5 unique focused tests PASS. Full repository suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- player_impact_flipbook: `.tmp-smoke-suite-20260928-225350-603-b9c409e8`
- projectile_impact: `.tmp-smoke-suite-20260928-225352-835-c33cdc04`
- projectile_hit_budget: `.tmp-smoke-suite-20260928-225118-508-d3d65503`
- melee_impact: `.tmp-smoke-suite-20260928-225028-018-c59f8048`
- player_damage_feedback: `.tmp-smoke-suite-20260928-225034-668-1d117ff0`

New coverage includes 144 material/surface/frame-rate/direction combinations.
Existing checks cover real shot damage and piercing budgets, contact dedup,
melee and player hurt, pause and effect cleanup. Gameplay damage logic unchanged.

D3D12 captures reviewed at 55/160 ms and in Echo Grotto. Visual iteration
removed the old line-stars from painted contacts, then improved dark-material
contrast with a brief compact glint. Final gameplay-scale capture inspected.
Known host certificate warning; no project script/shader errors.
`git diff --check` clean. No export/full manual fight claim.
[Details and captures](../art/characters/PLAYER_IMPACT_FLIPBOOKS.md).

## Painted ranged charge cues - 2026-09-28

**6/6 unique focused tests PASS. Full repository suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- mob_charge_cue: `.tmp-smoke-suite-20260928-224646-366-9d587425`
- sentry_cover, including new painted-cue assertions:
  `.tmp-smoke-suite-20260928-224629-927-ef65b3cf`
- ranged_attack_cue: `.tmp-smoke-suite-20260928-224442-625-bff95193`
- mob_attack_followthrough: `.tmp-smoke-suite-20260928-224455-393-879511d2`
- combat_readability: `.tmp-smoke-suite-20260928-224458-663-b1a3cf14`
- mob_defeat_echo: `.tmp-smoke-suite-20260928-224556-689-8dbdcbf1`

Coverage: twelve sentry preparation cycles (two types, two tiers, three
frame rates), monotonic atlas cells, four ranged aim directions, native
release/fan counts, cancellation/hidden cleanup and geometry. Live sentry
tests also verify cancelled painted effects behind actual solid cover.

D3D12 early/late/release gallery captured and inspected. Known host root
certificate/shader-cache warnings only; no project script/shader errors.
No export or full manual-fight claim.
[Details and capture](../art/characters/MOB_CHARGE_PRESENTATION.md).

## Mob attack recovery and aimed muzzle effects - 2026-09-28

**7/7 unique focused tests have passing final results. Full suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- mob_attack_followthrough: `.tmp-smoke-suite-20260928-223736-893-a1bf7e80`
- combat_readability: `.tmp-smoke-suite-20260928-223555-503-8856c9e7`
- ranged_attack_cue: `.tmp-smoke-suite-20260928-223833-612-f787254d`
- shaft_guard_combat: `.tmp-smoke-suite-20260928-223606-468-f83cf1de`
- enemy_attack_art: `.tmp-smoke-suite-20260928-223617-443-7dc63fd8`
- shade_appearance: `.tmp-smoke-suite-20260928-223739-608-7f647768`
- shaft_mixed_combat: `.tmp-smoke-suite-20260928-223746-393-4f3c08eb`

The first new fixture failed to parse because it referred to a nonexistent
global RootStalker class; fixed the fixture to inspect the native phase field.
Final fixture additionally checks Shade body-facing preservation. Five families
are sampled at 30/60/120 FPS and twelve native muzzle launches cover three
shooters in four directions under a rotated parent. Existing tests exercise
native combat cadence, contact damage, mixed combat and live Shade cycles.

D3D12 staged comparison captured and inspected. Corrected the preview's missing
active-body sample before recovery; no gameplay-facing change was required.
Known host certificate-store warning; no project script/shader errors.
`git diff --check` clean. No export or complete manual-fight claim.
[Details and capture](../art/characters/MOB_ATTACK_FOLLOWTHROUGH.md).

## Ordinary-mob defeat and hit presentation - 2026-09-28

**15/15 focused tests PASS. Full repository suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- mob_defeat_echo: `.tmp-smoke-suite-20260928-222746-955-ab4ea156`
- combat_readability: `.tmp-smoke-suite-20260928-222557-686-a5ae0dac`
- Ten appearance regressions: `.tmp-smoke-suite-20260928-222818-816-f00868d8`
  (boss, broodling, character, crawler, echo_fauna, echo_grazer, echo_guide,
  projectile, shade and weapon appearance).
- ranged_attack_cue: `.tmp-smoke-suite-20260928-222946-680-eab78294`
- neutral_creatures: `.tmp-smoke-suite-20260928-222953-456-6d914827`
- shaft_mixed_combat: `.tmp-smoke-suite-20260928-223009-573-f44631d6`

New fixture verifies 20 native defeats and unchanged single XP/gold rewards,
transformed body snapshots, foot registration/flying drift, Ash palette,
all ten hidden appearance resets, neutral exclusion and cleanup/budgets.
Five D3D12 preview captures completed; before/contact/85 ms/cleared inspected.
Initial default user-log launch crashed; explicit workspace log rerun succeeded,
with known host certificate/cache warnings but no project script/shader errors.
No export or full manual-fight claim.
[Details and captures](../art/characters/MOB_DEFEAT_PRESENTATION.md).

## Boss defeat presentation and arena cleanup - 2026-09-28

**9/9 unique focused tests have passing final results. Full repository suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- boss_defeat_echo, corrected fixture rerun:
  `.tmp-smoke-suite-20260928-222039-471-374535f1`
- Six existing boss checks:
  `.tmp-smoke-suite-20260928-221942-451-bd0875f9`
  (boss_appearance, boss_combat_presentation, boss_frame_sequence,
  boss_lamp_reveal, boss_motion, boss_transition_readability).
  This earlier batch also contains a failed new boss_defeat_echo fixture,
  superseded by the passing standalone rerun above.
- ash_arena: `.tmp-smoke-suite-20260928-222129-256-ad1a7128`
- enemy_projectile_contact: `.tmp-smoke-suite-20260928-222154-457-72115dc4`

The new fixture originally attempted to damage Hollow Sovereign outside its
required current room. Correct test-room setup fixed it; the native guard is
unchanged. Final coverage includes seven immediate native defeats, pose and
mask snapshots, transformed-room registration, dissolve lifetime, pause,
hidden disabled rooms, rest/room/transition retirement and shared budget.

Fifteen D3D12 captures produced across Castellan, Matriarch and Marshal:
before defeat plus four dissolve stages. Mid/late dissolve and cleared arena
samples inspected. No project script/shader errors in preview; known host
shader-cache write/root-certificate warnings. No export/manual full-fight claim.
[Details and captures](../art/characters/BOSS_DEFEAT_PRESENTATION.md).

## Hostile projectile contact and cleanup - 2026-09-28

**14/14 focused tests PASS across the runs below. Full repository suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- enemy_projectile_contact: `.tmp-smoke-suite-20260928-221341-452-4f528c8a`
- enemy_attack_art: `.tmp-smoke-suite-20260928-221349-365-993b01bd`
- Six boss tests: `.tmp-smoke-suite-20260928-220947-660-6f6af2e4`
  (boss_appearance, boss_combat_presentation, boss_frame_sequence,
  boss_lamp_reveal, boss_motion, boss_transition_readability).
- combat_readability: `.tmp-smoke-suite-20260928-221033-370-3612f0ec`
- combat_flipbook: `.tmp-smoke-suite-20260928-221034-457-09291069`
- shaft_mixed_combat: `.tmp-smoke-suite-20260928-221126-256-4691883f`
- shaft_ranged_combat: `.tmp-smoke-suite-20260928-221139-956-33318e50`
- world_population: `.tmp-smoke-suite-20260928-221221-369-dccddb19`
- sentinel_combat_flow: `.tmp-smoke-suite-20260928-221244-831-fd7b0196`

The new test covers 40 material/direction impacts, 14 boss muzzle directions,
4 live overlapping-target collision cases, single-hit reservation, terrain-first
ordering, transformed parents and hidden/rest/room/transition cleanup. A final
guard rejects newly spawned shots in already hidden parents; both hostile
contact and material integration checks were rerun after that guard.

Three D3D12 material-matrix captures reviewed (flight, breakup, particles).
No project script errors in final preview; known host root-certificate warning.
An intermediate name-shadowing parse error and incomplete local visibility
cleanup were corrected before rerunning their affected tests. No export or
complete manual-fight claim. [Details and captures](../art/characters/ENEMY_PROJECTILE_CONTACTS.md).

## Boss/miniboss transition readability - 2026-09-28

**8/8 focused tests PASS. Full repository suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- Six boss tests: `.tmp-smoke-suite-20260928-215159-229-b0e0b678`
  (boss_appearance, boss_combat_presentation, boss_frame_sequence,
  boss_lamp_reveal, boss_motion, boss_transition_readability).
- ash_arena: `.tmp-smoke-suite-20260928-215225-205-24ce4ea3`
- sentinel_combat_flow: `.tmp-smoke-suite-20260928-215235-165-f257dc68`

Four D3D12 Marshal captures reviewed at 960x540 / 2.5 zoom. First charge
frame is fully opaque; recovery retains committed facing after a scripted
target crossover. No project script errors; known host certificate and
shader-cache write warnings. No manual full fight / export claim.
[Changes and captures](../art/characters/BOSS_TRANSITION_READABILITY.md).

## Gameplay-scale combat readability - 2026-09-28

**11/11 focused tests PASS in final runs. Full repository suite not run.**

Workspace-root-relative reports, each containing `results.json`:

- Eight combat tests: `.tmp-smoke-suite-20260928-214638-735-278f8ced`
  (boss_combat_presentation, combat_flipbook, combat_readability,
  sentinel_combat_flow, shaft_guard_combat, shaft_hollow_entry_combat,
  shaft_mixed_combat, shaft_ranged_combat).
- starfall_rooted_hall: `.tmp-smoke-suite-20260928-214332-978-261ffe96`
- enemy_attack_art: `.tmp-smoke-suite-20260928-214437-136-0b82c271`
- neutral_creatures: `.tmp-smoke-suite-20260928-214443-442-95590239`

Initial broad run exposed an entry-pilot stall above an out-of-sword-reach
enemy. The test driver now walks off the ledge to approach the lower level;
no damage callbacks, healing, relaxed assertions or game-balance edits added.
The final eight-test rerun is clean. One intermediate GDScript inferred-type
error was corrected and all affected checks rerun.

D3D12 staged captures reviewed at native 960x540 / 2.5 zoom: warning, release,
late active roots and recovery. Root paint/warning no longer sinks into the
floor; legacy Ash Fiend polygon removed from rendering. Cosmetic saturation
checks retain the 64-effect cap. No project script errors in final captures;
host root-certificate warning remains. No manual full-fight or export claim.
[Implementation and captures](../art/characters/COMBAT_FLIPBOOKS.md).

## Actual combat flipbooks - 2026-09-28

**12/12 focused tests PASS. Full repository suite not run.**

Workspace-root-relative report folders (each contains `results.json`):

- combat_flipbook: `.tmp-smoke-suite-20260928-213236-092-d006ab2f`
- enemy_attack_art: `.tmp-smoke-suite-20260928-212831-140-9054efa4`
- boss_combat_presentation: `.tmp-smoke-suite-20260928-213236-849-48f23b65`
- boss_motion: `.tmp-smoke-suite-20260928-213215-914-f819a74c`
- ranged_attack_cue: `.tmp-smoke-suite-20260928-213222-165-c1f8675f`
- neutral_creatures: `.tmp-smoke-suite-20260928-212837-382-a07c2e91`
- shaft_ranged_combat: `.tmp-smoke-suite-20260928-212845-125-6eb6b993`
- starfall_rooted_hall: `.tmp-smoke-suite-20260928-212911-101-734aa163`
- sentinel_combat_flow: `.tmp-smoke-suite-20260928-212848-778-326f06b0`
- ash_arena: `.tmp-smoke-suite-20260928-212856-584-22c57b4d`
- echo_grotto: `.tmp-smoke-suite-20260928-212907-650-3617c872`
- world_population: `.tmp-smoke-suite-20260928-213225-357-075063cc`

Six D3D12 gallery stages and three boss arena releases reviewed. Host certificate
and shader-cache write warnings persist; no project script errors. Editor import
has the known external editor-settings write warning, not scene/script failures.
[Assets, exact prompts and verification limits](../art/characters/COMBAT_FLIPBOOKS.md).

## Painted attack materials - 2026-09-28

**11/11 focused tests PASS; full repository suite not run.**

- Attack material coverage: `.tmp-smoke-suite-20260928-210908-710-8891ae0b/results.json`
- Boss presentation: `.tmp-smoke-suite-20260928-210437-222-df1b45f9/results.json`
- Ranged cue: `.tmp-smoke-suite-20260928-210046-305-9ef4b94c/results.json`
- Shaft progression: `.tmp-smoke-suite-20260928-210056-585-45ded36b/results.json`
- Empty Court: `.tmp-smoke-suite-20260928-210110-227-8bd5e5d3/results.json`
- Neutral creatures: `.tmp-smoke-suite-20260928-210156-187-953cb997/results.json`
- Rooted Hall: `.tmp-smoke-suite-20260928-210202-765-0c2066e6/results.json`
- Shaft ranged combat: `.tmp-smoke-suite-20260928-210217-363-9bfbe74b/results.json`
- Sentinel combat flow: `.tmp-smoke-suite-20260928-210248-178-5a82168c/results.json`
- Echo Grotto: `.tmp-smoke-suite-20260928-210254-608-d10cabad/results.json`
- Ash arena: `.tmp-smoke-suite-20260928-210304-387-3e3766f6/results.json`

Reports above are workspace-root relative. D3D12 gallery and three scripted boss
arena captures reviewed; known host certificate/cache warnings, no script errors.
See [material coverage and limitations](../art/characters/ENEMY_ATTACK_MATERIALS.md).

## Expanded boss animation atlases - 2026-09-28

**12/12 focused tests PASS. Full repository suite not run.**

- Boss appearance, combat presentation, frame sequence, lamps and motion (5): [report](../.tmp-smoke-suite-20260928-204156-581-3889d29d/results.json).
- Sentinel combat flow: [report](../.tmp-smoke-suite-20260928-203620-030-4f795bb4/results.json).
- Ash arena/miniboss: [report](../.tmp-smoke-suite-20260928-203907-588-a1909ef6/results.json).
- Ash Castellan: [report](../.tmp-smoke-suite-20260928-203917-731-13756f15/results.json).
- Echo sanctum: [report](../.tmp-smoke-suite-20260928-203927-971-493ea0d8/results.json).
- Starfall Empty Court: [report](../.tmp-smoke-suite-20260928-203938-153-82065889/results.json).
- Starfall Hollow Throne: [report](../.tmp-smoke-suite-20260928-203948-349-6c098aed/results.json).
- Shaft progression/Warden: [report](../.tmp-smoke-suite-20260928-204206-796-81f16725/results.json).

Twelve-stage D3D12 gallery and scripted in-arena Sentinel captures reviewed.
The GPU preview host reports root-certificate and shader-cache write warnings;
captures complete. No full manual playthrough or exported build is claimed.
[Assets, prompts and limitations](../art/characters/BOSS_TWELVE_FRAME_ANIMATIONS.md).

## Sentinel combat flow and high-FPS animation - 2026-09-28

**7/7 focused tests PASS. Full repository suite not run.**

- Sentinel flow (final rerun): [report](../.tmp-smoke-suite-20260928-191832-418-bd6662d6/results.json).
- Boss appearance, presentation and lamp reveal: [report](../.tmp-smoke-suite-20260928-191437-495-82721c6c/results.json).
- Boss motion, including the new inter-physics render check: [report](../.tmp-smoke-suite-20260928-191607-638-d48c6993/results.json).
- Shaft progression and persistent first-boss defeat: [report](../.tmp-smoke-suite-20260928-191625-414-0b7f7e55/results.json).
- Room-door interactions: [report](../.tmp-smoke-suite-20260928-191714-064-01b65a1d/results.json).

Five GPU samples use the real Sentinel physics controller, including the player
crossing behind during windup. Reviewed cast origin, planted feet and recovery.
Only the known host root-certificate warning appears in the accepted GPU log.
No full manual encounter or full new animation sheet is claimed.
[Details and samples](../art/characters/SENTINEL_COMBAT_FLOW.md).

## Boss motion and material finishing - 2026-09-28

**7/7 focused tests PASS. Full repository suite not run.**

| Test | Accepted report |
| --- | --- |
| boss_motion_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-190109-588-41adeb36/results.json) |
| boss_combat_presentation_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-190125-908-2a6d8f79/results.json) |
| remaining_room_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-190141-898-45612ed9/results.json) |
| starfall_arena_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-190323-273-07a705bb/results.json) |
| boss_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-190324-147-f3b09141/results.json) |
| ash_castellan_rollback_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-190324-962-af50df6d/results.json) |
| ash_arena_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-190342-635-1bf8719b/results.json) |

Motion checks cover seven actors and 37 bounded material surfaces. Eight GPU
frames time-step the actual Warden fight at 60 Hz; prepare, charge, recovery,
ground registration and trails inspected. The first preview's disabled physics
space was corrected in the preview harness; final run has no physics/script
errors (only the existing host certificate warning). Not a manual full-fight
playthrough. [Changes and reviewed samples](../art/characters/BOSS_MOTION_FINISH.md).

## Boss combat presentation and arena polish - 2026-09-28

**12/12 focused tests PASS. Full repository suite not run.**

| Test | Accepted report |
| --- | --- |
| boss_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-185101-481-fd81ae0e/results.json) |
| boss_combat_presentation_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-185102-456-de1b2bef/results.json) |
| ash_castellan_smoke.gd, ash_castellan_rollback_smoke.gd | [2 PASS](../.tmp-smoke-suite-20260928-184204-706-24ce9dea/results.json) |
| ash_arena_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-184714-948-cb455e56/results.json) |
| starfall_empty_court_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-184735-061-980d679f/results.json) |
| starfall_hollow_throne_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-184800-886-66c7b7e0/results.json) |
| echo_sanctum_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-184826-647-dc70a90a/results.json) |
| shaft_zone_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-184857-766-20180443/results.json) |
| boss_lamp_reveal_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-184926-986-024fa954/results.json) |
| remaining_room_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-184928-094-be348859/results.json) |
| starfall_arena_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-184942-163-962ba4a5/results.json) |

In-world GPU warning/release/aura captures and the seven-actor pose gallery were
rendered with the project D3D12 renderer. Reviewed arena shots led to removing
legacy geometric overlays in the Sanctum and Castellan Throne. Host certificate
and shader-cache write warnings occurred in the restricted environment; no
script exceptions or shader compilation errors in final captures. These held
previews are not a full manual playthrough of every fight.
[Assets, exact prompts, implementation and limits](../art/characters/BOSS_COMBAT_POLISH.md).

## Six painted bosses - 2026-09-28

**4/4 focused regressions PASS.**

| Test | Accepted report |
| --- | --- |
| boss_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-181945-344-9afca2b3/results.json) |
| ash_arena_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-181946-732-36252f91/results.json) |
| boss_lamp_reveal_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-181958-324-e7f631de/results.json) |
| starfall_arena_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-181959-691-5ddbba47/results.json) |

GPU live-scale gallery reviewed: art/characters/preview_boss_appearances.png. Full suite not run.

## Four additional field-guide sprites - 2026-09-28

**3/3 focused tests PASS.**

| Test | Accepted report |
| --- | --- |
| echo_guide_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-174814-106-6952f7af/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-175107-085-b23b4a7b/results.json) |
| ash_industry_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-175122-445-0e3f3523/results.json) |

This expands the sheet sweep to ten guides / 40 poses, verifies Leth is attached
only after Echo Grotto entry, and retains alpha, mipmap, dialogue, patrol, floor,
facing, talk, lazy activation and re-entry checks. Full suite not run.

## Echo waterworks guides, controls and instruction placement - 2026-09-28

**10/10 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_guide_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-172855-757-f4f54080/results.json) |
| echo_device_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-172904-239-c1b559df/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-173002-922-90365e29/results.json) |
| echo_crossing_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-173021-337-6f51e297/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-173036-252-033248a5/results.json) |
| echo_field_sign_layout_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-173051-718-733bcbb5/results.json) |
| echo_room_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-173053-525-f9f4ead9/results.json) |
| echo_machinery_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-173109-998-3eb0044d/results.json) |
| echo_traversal_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-173117-289-0d78c277/results.json) |
| echo_remaining_navigation_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-173121-401-3fa0001f/results.json) |

Three new guide sheets (12 poses) and three instrument paintings. Six guide
regions and all 18 explicitly dressed Echo devices now have generated artwork.
Six new devices and their relocated instruction labels clear actual terrain.
Native activation, partial/full rewards, rollback and completed reload pass.
Twelve GPU views inspected: `.tmp-echo-waterworks-preview.log` exits 0. Source
alpha bounds inspected; mipmaps enabled. `git diff --check` clean.

Initial operations-test parse error on a newly inferred local was fixed by an
explicit Node2D type and rerun. Accepted runs have no project script errors;
known certificate-store warning remains. Import's global AppData editor-settings
write is sandbox-blocked. No full-suite/manual whole-map acceptance claimed.
[Assets, exact prompts, limitations](../art/characters/ECHO_WATERWORKS_BATCH.md).

## Echo guides, instruments and camp readability - 2026-09-28

**10/10 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_guide_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-170000-116-c109415e/results.json) |
| echo_device_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-170228-822-b15d2e96/results.json) |
| echo_room_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-170020-771-04a42a0f/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-170032-668-ff1fa1fb/results.json) |
| echo_field_discoveries_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-165630-015-27e3c0eb/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-165642-028-d6f8640b/results.json) |
| echo_painted_props_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-165908-534-4569c674/results.json) |
| echo_prop_clearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-165915-071-959e9329/results.json) |
| echo_field_sign_layout_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-170006-558-794218ef/results.json) |
| echo_grotto_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-170012-280-0beb62ed/results.json) |

Three distinct four-pose field guide sheets; two generated instrument images
cover two resonators and ten receivers. Native interaction/progression stays
authoritative. Guide feet and root resonator images register to existing support;
name/talk labels clear the camp walkway. One redundant Nest awning contour hidden.
Nine GPU captures produced by `preview_echo_guides.gd`, accepted log
`.tmp-echo-guides-preview-final.log`; native PNGs/alpha and enlarged pose/state
composites inspected. No manual full-map playthrough. Known certificate-store
warning remains; import cannot save sandboxed global AppData editor settings.

Initial verification-script errors (Depths preview target and Label transform
getter) were corrected and their checks rerun. No runtime parse/script errors
in accepted reports. [Assets and exact prompts](../art/characters/ECHO_GUIDES_AND_DEVICES.md).

## Echo fauna batch, entry flora and spawn clearance - 2026-09-28

**12/12 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_fauna_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-163203-609-410c7b57/results.json) |
| echo_entry_growth_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162354-291-e76534e6/results.json) |
| echo_grazer_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162558-745-36cd2122/results.json) |
| neutral_creatures_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162604-639-f3ebe78c/results.json) |
| world_population_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162610-072-de7c1bba/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162617-717-ecb10c18/results.json) |
| echo_crossing_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162629-682-651e632f/results.json) |
| echo_sanctum_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162641-984-631cdc9c/results.json) |
| echo_organic_scenery_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162654-245-551194e6/results.json) |
| echo_traversal_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162906-405-67a1985a/results.json) |
| echo_room_identity_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-162909-692-907c7d4d/results.json) |
| echo_gallery_archive_route_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-163121-902-4b4e7410/results.json) |

Five native 1254-square RGBA species sheets, twenty key poses, 49 observed fauna
actors across ten Echo locations. Ten live neutral cycles plus actual streaming
retain health/hostility. Seven first-route fauna anchors moved away from doors
with complete patrol floor support. Entry flora replaces 50 triangles with ten
supported clusters in five courts; static rendering and original geometry kept.

Initial fauna test-only type inference error fixed. Skimmer v1 had cell overlap;
an edit produced opaque checkerboard and was rejected. Accepted v3 has verified
alpha and clear gutters. Neither rejected attempt is used by runtime art.

The first long-route run failed at Gallery ListeningPost1: a live shade entered
the listening radius after the pilot cleared the lane. The test already had a
physical descend/fight/climb-back retry for Archive; it now uses that same policy
for Gallery, without bypassing threats or granting progress. Accepted log records
LISTEN RETRY at Gallery tier 5, then real completion: Gallery 23 foes, 8 links,
4 branches; Archive 24 foes, 8 links, 5 branches, with saves and rewards verified.
Failed report retained at .tmp-smoke-suite-20260928-162916-084-9a165ab7.

Twelve GPU previews reviewed. Final .tmp-echo-fauna-preview.log exit 0, known
certificate warning only. Editor imports exit 0; global AppData editor settings
writes blocked by sandbox. No manual playthrough or editor acceptance claimed.
Some existing device silhouettes, NPC bodies and contextual labels remain.
[Selected assets, exact prompts and QA](../art/characters/ECHO_FAUNA_BATCH.md).

## Generated Echo Shade appearance - 2026-09-28

**6/6 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| shade_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-160553-858-9d15948e/results.json) |
| zone_upgrade_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-160647-102-26ec3615/results.json) |
| echo_sanctum_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-160653-124-5e0c930a/results.json) |
| echo_gallery_archive_route_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-160705-743-09564b72/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-160803-700-509e5400/results.json) |
| ash_star_identity_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-160815-855-ca8bb6bd/results.json) |

Native-resolution six-pose RGBA sprite replaces EchoShade body polygons.
Four live AI cycles cover both facings and tiers, complete warnings, upgraded
followup, hit interrupt/flash, hidden/teleport handling and collision invariants.
EchoShade.gd unchanged. Existing warning lane layered above new sprite.
Four GPU captures reviewed: all poses mirrored, Gallery idle/glide, base and
awakened windup. .tmp-shade-preview.log exit 0, known certificate warning only.
Final import exit 0 (global AppData settings writes blocked by sandbox).
No manual playthrough claimed. [Source, exact prompt and QA](../art/characters/ECHO_SHADE_ART.md).

## Grounded Echo organic scenery - 2026-09-28

**6/6 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_organic_scenery_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-155742-085-ca2496a8/results.json) |
| echo_scenery_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-154952-486-7710716b/results.json) |
| echo_traversal_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-155026-495-ebec9607/results.json) |
| echo_room_identity_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-155029-581-4ba73dc6/results.json) |
| echo_painted_props_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-155035-785-df68c25d/results.json) |
| echo_grazer_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-155454-319-7c707637/results.json) |

Two generated native-resolution alpha sprites: 261 grounded mushroom and 80
mineral clusters across eight routes. Invalid legacy anchors are omitted rather
than floating over shafts. Verified static rendering, clipped UV registration,
floor support/clearance and unchanged physics/progression. Grazer scope corrected
to exclude non-grazer Echo fauna; live state/streaming regression passes.
Eight GPU views reviewed; final .tmp-organic-preview.log exit 0, known certificate
warning only. Editor import exit 0 (global AppData settings blocked by sandbox).
Not a manual playthrough. [Assets, prompts and QA](../art/visual_slice/ECHO_ORGANIC_SCENERY.md).

## Generated Echo neutral grazer appearance — 2026-09-28

**6/6 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_grazer_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-153554-678-6548d150/results.json) |
| neutral_creatures_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-153600-918-55129deb/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-153606-501-851949db/results.json) |
| echo_room_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-153618-415-d975c459/results.json) |
| echo_crossing_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-153631-197-3911aa8a/results.json) |
| route_field_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-153643-199-1be7b35d/results.json) |

One generated RGBA sheet, six poses for Echo-only neutral fauna. Native AI,
neutrality, warning grace, collision, rewards and streaming remain unchanged.
The new live test includes actual room unloading/recreation and both facings.
Initial test-only type inference and float-epsilon warning assertions corrected;
native gameplay timing was not altered. Four final GPU captures inspected,
.tmp-grazer-preview.log exit 0. Name labels moved below health bars after the
initial views showed platform overlap. Final editor import exit 0; sandbox
blocks global AppData settings writes. Runtime logs show only the known root
certificate warning. No manual playthrough or editor visual acceptance claimed.
[Asset, exact prompt and QA](../art/characters/ECHO_GRAZER_ART.md).

## Generated Echo Broodling appearance — 2026-09-28

**6/6 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| broodling_appearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-142407-199-39d20078/results.json) |
| echo_nest_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-142113-976-753e557b/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-142143-657-3f16f253/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-142244-484-b13e4ee7/results.json) |
| zone_upgrade_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-142346-324-9ad1a593/results.json) |
| echo_nest_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-142409-225-6774c2eb/results.json) |

One six-pose generated RGBA sheet replaces the Broodling body/spines/eye.
Four live AI cycles cover both facing directions and tiers, full native windup,
leap, recovery and hit feedback. Walking uses actual ground travel; hidden or
teleported actors do not stride. Body/contact geometry, rewards and AI code
are unchanged. The original warning remains, raised above the health bar.

Three D3D12 captures inspected; .tmp-broodling-preview.log exit 0. One bounded
import process timed out after importing; only that child was terminated.
The subsequent isolated import completed with exit 0 (.tmp-broodling-import-final.log).
Runtime tests/previews report only the known certificate warning; editor import
also cannot save global AppData settings in the sandbox. No manual playthrough,
editor visual acceptance or completion of all creature/flora art claimed.
[Asset, exact prompt and QA](../art/characters/ECHO_BROODLING_ART.md).

## Generated Echo Nest silk props — 2026-09-28

**6/6 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_nest_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-123653-387-a40a495a/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-123704-239-ce553681/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-123736-973-3efa0743/results.json) |
| echo_field_sign_layout_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-123810-649-b9f8b15d/results.json) |
| echo_painted_props_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-123822-983-90bb7c1d/results.json) |
| echo_machinery_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-123838-986-128da3cd/results.json) |

Two generated RGBA textures replace nursery pods and spent shells at two sites;
12 state variants, six visible at a time. Existing containers control visibility
without extra listeners, frame processing, gameplay or save-state changes.
An initial smoke failed on two platform intersections: center cocoons reduced
from 42 to 38px, and the final all-platform clearance assertion passes.

Four final D3D12 views inspected (both sites occupied/cleared); preview exit 0,
log .tmp-echo-nest-preview.log. Runtime tests/previews report only the known root
certificate warning. Editor import also cannot write global AppData settings
inside the sandbox; project assets/imports succeed. No manual playthrough or
editor acceptance claimed. [Assets, exact prompts and QA](../art/visual_slice/ECHO_NEST_ART.md).

## Generated Echo water machinery — 2026-09-28

**6/6 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_machinery_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-122239-824-8adc62fb/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-122051-173-d3066703/results.json) |
| echo_crossing_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-122133-462-bbd829ec/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-122219-901-f33d3af3/results.json) |
| echo_field_sign_layout_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-122306-146-b66dcc70/results.json) |
| echo_painted_props_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-122312-901-29fd25ef/results.json) |

Two built-in imagegen RGBA assets used in four machinery assemblies: two
maintenance pumps and two live pressure gauges. All original gameplay
controllers, native state nodes, actor/site anchors and rewards are retained.
Tests check alpha/mipmaps, grounded scaling, dial/platform clearance,
independent state changes, event filtering and room re-entry.

Five D3D12 runtime views inspected (exit 0); final log:
.tmp-echo-machinery-preview.log. An initial typed-ternary-array runtime error
was corrected, then the first upper-gauge preview exposed a stair through its
face. The art-only offset and explicit clearance assertion resolve that case.
Final runtime log has the known certificate-store warning only. Project
imports succeeded despite sandbox-blocked global editor-settings writes.
`git diff --check` passes. No full-suite, manual traversal, editor acceptance
or full-map art completion claimed. Assets and exact final prompts:
art/visual_slice/ECHO_MACHINERY.md.

## Echo field-clue readability — 2026-09-28

**7/7 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_field_sign_layout_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-121014-299-b06d12b3/results.json) |
| echo_painted_props_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-120836-107-8f0112b4/results.json) |
| echo_prop_clearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-120851-763-73369d52/results.json) |
| echo_device_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-120906-473-fd815722/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-120922-832-170c2d0d/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-120954-253-a10437ae/results.json) |
| route_field_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-121042-494-a6479549/results.json) |

75 clues across eight Echo rooms; zero unresolved layout candidates. Final
label-specific test includes live record-status updates and five idle frames
with no reflow. Original text, physics, site/actor anchors and progress remain
owned by existing systems. Layout is construction/size-event-driven.

Initial 360 px boxes failed in three tight locations. Width/height fitting
and rendered-text reservations resolve those cases. An intermediate Control
transform API mistake was caught and corrected; the final focused GPU log
contains no script errors. Six D3D12 site captures inspected, exit 0:
.tmp-echo-sign-focused-preview.log. Known certificate-store warning only.
`git diff --check` passes. Other label categories, machinery/actor art and
foundation silhouettes remain unfinished. No full-suite/manual traversal/
editor acceptance or full-map completion claimed.
Details: art/visual_slice/ECHO_FIELD_SIGN_LAYOUT.md.

## Echo prop/platform clearance — 2026-09-28

**5/5 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_prop_clearance_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-114703-941-64672590/results.json) |
| echo_painted_props_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-114712-456-fdda72d1/results.json) |
| visual_style_slice_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-114723-153-c9900ca4/results.json) |
| route_field_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-114724-477-426f631b/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-114749-102-7a913eca/results.json) |

Five Archive furniture pieces have complete floor support and no collision
rectangle intersections. All 89 Grotto one-way ledge contours stay within
collider depth; the camp shelter clears the low overhang. No collider,
NPC/loot anchor or progression changes; the existing 136 props remain.

Eleven D3D12 captures completed (exit 0), with five affected site views
inspected. Log: .tmp-echo-clearance-preview.log. The known system certificate
warning remains. Initial read-only audit helper had a type-inference parse
error, fixed before the successful geometry audit; accepted tests all pass.
Other labels, actor placeholders and solid-floor foundations remain unfinished.
Details: art/visual_slice/ECHO_PROP_CLEARANCE.md. No manual traversal/editor
acceptance or full-map completion claimed. `git diff --check` passes.

## Echo camp and archive raster follow-up — 2026-09-28

**7/7 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_painted_props_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-113859-816-72b774ee/results.json) |
| route_field_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-113808-835-f5ca0dd4/results.json) |
| echo_crossing_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-113834-922-066f5b6d/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-113906-550-175eb458/results.json) |
| expedition_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-113938-412-b7f79d10/results.json) |
| ash_route_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-114011-418-c590389f/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-114021-128-dd2de527/results.json) |

Three more built-in imagegen assets: canvas shelter, field/reading desk and
book-delivery cart. Coverage is now 136 props (15 additional replacements).
Tests cover all six alpha/mipmap textures, anchors, static/idempotent art,
desk draw order, shelter height, eight-room scope and preserved gameplay.
The first expanded test failed parsing because a shelf variable lacked an
explicit type; corrected and rerun successfully in the accepted report above.

Ten D3D12 captures completed (exit 0), six new views inspected after fixing
desk/bookcase draw order and reducing shelter height. Log:
.tmp-echo-camp-preview.log. The known certificate-store warning remains.
Thick foreground platforms still cover some Grotto/Archive prop artwork;
this is not full visual acceptance, manual traversal or complete-map art.
Exact prompts, PNG paths and limitations: art/visual_slice/ECHO_CAMP_PROPS.md.

## Generated Echo prop sprites — 2026-09-28

**7/7 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_painted_props_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-111754-809-20281c09/results.json) |
| route_field_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-111804-667-fca7aaec/results.json) |
| echo_crossing_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-111834-457-7974bb89/results.json) |
| echo_habitat_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-112026-928-cb8b61bc/results.json) |
| expedition_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-111929-898-bd5ba746/results.json) |
| ash_route_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-112000-627-cfe71b09/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-112005-928-8488dbed/results.json) |

Three built-in imagegen PNGs, true alpha and full-resolution/mipmap imports.
121 props: 11 carts, five shelves, 105 ferns in eight explicitly named Echo
rooms. A first scope test exposed the shared Ash `causeway` region name;
room allowlisting fixes this and the Ash exclusion regression passes.
The habitat test's older requirement for full cache clues on every local sign
was updated to require that clue at the entrance and progress/save guidance
on compact station signs; other puzzle/streaming/economy assertions remain.

Four D3D12 runtime captures inspected: cargo, shelf, fern and Depths shelf.
Log .tmp-echo-painted-preview.log, exit 0; known certificate-store warning only.
Editor imports succeeded but could not save global editor settings outside
the sandbox. No full-suite/manual traversal/editor acceptance claimed.
Remaining prop placement/art limitations and exact final prompts:
art/visual_slice/ECHO_GENERATED_PROPS.md.

## Echo scenery silhouettes — 2026-09-28

**7/7 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| echo_scenery_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-105450-454-73d11a5a/results.json) |
| echo_device_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-105516-106-58568e12/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-105529-510-e2b1bfaa/results.json) |
| echo_field_discoveries_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-105602-826-6e094ad7/results.json) |
| remaining_room_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-105627-457-8047bf5b/results.json) |
| world_routes_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-105642-669-74113e1c/results.json) |
| visual_style_slice_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-105701-710-c0780f9d/results.json) |

Eight routes, 1,484 known cosmetic leaves replaced/quietened: 220 rock sites,
258 crystal sites, 306 fungus sites plus matching old caps, pendants and
background motifs. Includes 37 opaque alcove-mouth fills replaced by edges.
Original geometry/depth/physics/flags and child-bearing nodes preserved.
Containment test uses polygon difference with 0.02 px float tolerance;
development test-only XOR/difference and boundary-rounding failures resolved.

Eight D3D12 captures completed and were inspected. Log
.tmp-echo-scenery-final.log, exit 0; known certificate-store warning only.
No full-suite/manual traversal/editor acceptance or complete-map claim.
Remaining field props, creatures, foundations and old labels documented in
art/visual_slice/ECHO_SCENERY_PRESENTATION.md.

## Echo device presentation and local signs — 2026-09-28

**7/7 unique targeted tests PASS.** Full suite not run. Device-art test was
rerun after compacting station artwork to fit low overhangs.

| Test | Accepted report |
| --- | --- |
| echo_device_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-104200-770-7e46e109/results.json) |
| echo_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-103924-751-4d3af467/results.json) |
| echo_field_discoveries_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-104018-515-5b433399/results.json) |
| tide_well_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-104105-812-89243170/results.json) |
| crystal_causeway_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-104135-936-79f70222/results.json) |
| world_routes_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-104204-995-e780cd70/results.json) |
| starfall_task_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-104311-311-fb78bbaa/results.json) |

18 devices, five silhouettes, static state-driven art, unchanged interaction
physics and gameplay flags; 10 compact local signs and five full entry clues.
Live activation, pair reward, duplicate rejection and receiver reset checked.
The initial art-test fixture counted before room entry; it was corrected to
visit streamed rooms before the accepted audit above.

Seven D3D12 captures completed and were inspected, including active/inactive
states. Final log .tmp-echo-devices-final.log, exit 0; known certificate-store
warning only. No manual traversal/editor acceptance or complete-map claim.
Notes: art/visual_slice/ECHO_DEVICE_PRESENTATION.md.

## Authored crate-placement exceptions — 2026-09-28

**8/8 unique targeted tests PASS.** Full suite not run. Floor and anchor
tests were rerun after adding disabled/scaled/rotated-collider guards.

| Test | Accepted report |
| --- | --- |
| crate_floor_placement_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-102816-634-caadc7e0/results.json) |
| crate_spawn_anchors_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-102837-740-3121c845/results.json) |
| world_population_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-102442-451-5b7fc8b5/results.json) |
| route_field_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-102500-000-628adb9d/results.json) |
| starfall_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-102535-368-9bdd040e/results.json) |
| ash_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-102620-683-23cafdad/results.json) |
| ash_industry_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-102656-701-264d6c00/results.json) |
| crate_presentation_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-102708-995-4abb8467/results.json) |

All 85 former exceptions have explicit supported anchors. Current world audit:
556 supported, zero unsupported (554 lowered, Echo Nest's crate raised 1 px,
one already grounded). Terrain/loot/population counts/callbacks unchanged;
new positions retain headroom and do not overlap other crates. All 85 survive
damaged-state unload/reload without positional drift. Memory-record and
barracks-target field-operation completion/rest regressions pass.

Six D3D12 runtime captures completed and were inspected. Log
.tmp-crate-anchors-preview.log, exit 0, known certificate-store warning only.
No full-suite, manual traversal or editor acceptance. Runtime-only placement.
Remaining art/labels/devices are not marked complete.
Notes: art/visual_slice/CRATE_AUTHORED_ANCHORS.md.

## Bounded crate grounding — 2026-09-28

**7/7 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| crate_floor_placement_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-094619-676-76c1a721/results.json) |
| world_population_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-094453-071-6033f3c9/results.json) |
| route_field_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-094500-018-3280349e/results.json) |
| starfall_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-094510-165-160ca50c/results.json) |
| ash_industry_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-094522-007-40cd71b8/results.json) |
| starfall_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-094527-286-0a2b2529/results.json) |
| crate_presentation_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-094540-389-949db54c/results.json) |

Final audit: 556 visited, 470 safely lowered, one already supported, 85
unresolved positions deliberately unchanged. Eighteen edge fixtures,
unchanged terrain, no new crate overlap, no idle processing, streamed
position/damage restore and unchanged loot/field progression checks pass.
Three D3D12 captures completed and reviewed; final log
.tmp-crate-grounding-final.log, exit 0, known certificate-store warning only.
No full-suite, manual traversal or editor acceptance. Runtime-only positioning;
remaining authored exceptions: art/visual_slice/CRATE_FLOOR_PLACEMENT.md.

## Shared crate presentation — 2026-09-28

**6/6 unique targeted tests PASS.** Full suite not run.

| Test | Accepted report |
| --- | --- |
| crate_presentation_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-092323-840-405ba1fc/results.json) |
| world_population_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-092324-751-9ca52d20/results.json) |
| projectile_impact_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-092331-744-350d7fbc/results.json) |
| starfall_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-092332-667-1cca29b0/results.json) |
| starfall_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-092344-908-71ca846a/results.json) |
| ash_industry_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-092358-465-55b0e1de/results.json) |

Four regional styles, room-family mapping, health-driven cracks, actual
population unload/reload, unchanged collisions, 32 loot-oracle cases and
shared capped/ephemeral effects. Three D3D12 previews reviewed (gallery,
Echo Grotto, Memory Vault), exit 0, .tmp-crate-preview.log. Only known
certificate-store warning. Existing actor placeholders, labels and some
crate-to-floor gaps remain; no complete-map or editor acceptance claimed.
Notes: art/visual_slice/CRATE_PRESENTATION.md.

## Starfall scenery and field-sign readability — 2026-09-28

**7/7 unique targeted tests PASS.** Full suite not run. Scenery, branch and
painted-depth tests were rerun after clipping decorative strokes; gameplay
tests include the compact-sign changes. Task logic was not otherwise changed.

| Test | Accepted report |
| --- | --- |
| starfall_scenery_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-091159-450-c3f9e092/results.json) |
| starfall_branch_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-091204-994-bc542741/results.json) |
| room_painted_depth_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-091206-787-c145a0a8/results.json) |
| starfall_inner_fields_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-091030-767-8a47831f/results.json) |
| starfall_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-091044-227-ddc94ceb/results.json) |
| starfall_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-091058-573-bdeb69d8/results.json) |
| starfall_task_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-090852-542-330edd4a/results.json) |

Final scenery coverage: 150 textured decorative surfaces; 171 source leaves
hidden in favor of quieter/clipped line/root drawing; 116 clipped root strokes.
Fourteen local signs are compact; twelve full entrance/reserve instruction
signs remain. Tests preserve original geometry/transforms/depth/collisions,
check all stroke vertices against room masks, enforce static/idempotent art
and verify instruction bounds, guardian-status separation and unchanged flags.

Eight D3D12 staged runtime captures completed, exit 0. Rooted Hall, Crucible
and Memory Vault reviewed; Rooted Hall/Crucible reviewed again after clipping.
Final log: .tmp-starfall-scenery-final.log. Known certificate-store warning
only. No full-suite, manual traversal or editor UI acceptance claimed.
Notes: art/visual_slice/STARFALL_SCENERY_READABILITY.md.

## Side-room coverage and Starfall branch details — 2026-09-28

**7/7 unique targeted tests PASS.** Full suite not run. The final branch-art
run follows the shallow-edge adjustment; painting/gameplay checks cover the
unchanged shared-mask and interaction behavior.

| Test | Accepted report |
| --- | --- |
| room_painted_depth_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-090210-226-869c6a65/results.json) |
| starfall_branch_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-090348-635-3c62edac/results.json) |
| background_quality_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-090217-710-aa541092/results.json) |
| starfall_task_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-090225-892-ea1ece40/results.json) |
| starfall_outer_route_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-090350-496-63f2fbf1/results.json) |
| starfall_inner_fields_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-090400-757-0d88c91a/results.json) |
| blackwater_cistern_smoke.gd | [PASS](../.tmp-smoke-suite-20260928-090414-446-692c97fb/results.json) |

Coverage: 35 previously skipped branch/niche masks, 170 total painted-depth
surfaces across nine profiles, 30 Starfall side-floor detail sites and 30
hidden technical labels. Existing UV continuity, depth, geometry, collision,
task states and inactive-room rendering are checked. No new background image
or material owner is added.

Eight staged runtime GPU captures completed, exit 0. Final Rooted Hall and
Cistern views were reviewed; initial Silent Gate/upper reserve review led to
reducing oversized decorative frames. Final log: .tmp-starfall-branch-final.log.
Known certificate-store warning only. Initial type-inference error fixed
before accepted runs. No editor UI or manual traversal acceptance in this pass.
Notes and schematic-editor limitation: art/visual_slice/STARFALL_BRANCH_COVERAGE.md.

## Starfall task presentation — 2026-09-27

**4/4 unique targeted tests PASS.** Full suite not run. Final task-art and
inner-field runs include filtered/coalesced event updates and all five
landmark replacements; the earlier field/dressing runs cover the unchanged
activation, save and route-level feedback behavior.

| Test | Accepted report |
| --- | --- |
| starfall_task_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-230124-215-0226e5a1/results.json) |
| starfall_inner_fields_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-230145-374-5fe02ce3/results.json) |
| starfall_field_operations_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-225804-535-837ad0d9/results.json) |
| starfall_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-225536-339-19c69790/results.json) |

Presentation coverage: seven registers, nine stations and five restored
landmarks. Assertions include locked/pending/done states, read-only task flags,
unchanged collision/prompt/reach, idempotence and ignored unrelated events.
Existing gameplay checks cover prerequisite ordering, partial-save reload,
population streaming, guardian requirements and one-time rewards.

Ten staged D3D12 1280x720 captures completed, exit 0. Partial register, locked
terminal, repaired winch, garden and beacon views were reviewed. Final log:
.tmp-starfall-task-final.log. Known host certificate-store warning only; no
script/shader errors. No manual traversal or editor UI test in this pass.
The initial new-test type-inference error was corrected before accepted runs.
Notes: art/visual_slice/STARFALL_TASK_PRESENTATION.md.

## Starfall civic / Outskirts prop expansion — 2026-09-27

**8/8 unique targeted tests PASS.** Full suite not run. After final draw-order,
wheel and ruin-material adjustments, prop coverage, background quality and
Starfall dressing/state were rerun; earlier unrelated structure/route checks
are retained below with their exact run identifiers.

| Test | Accepted report |
| --- | --- |
| starfall_prop_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-223558-166-69123f52/results.json) |
| starfall_upper_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-223508-839-bf7d9569/results.json) |
| starfall_upper_structure_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-223237-168-7f0326cc/results.json) |
| city_background_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-223510-892-b592c398/results.json) |
| background_quality_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-223601-776-341636df/results.json) |
| starfall_outskirts_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-223301-499-6fccb3fc/results.json) |
| starfall_outer_route_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-223331-231-6ce5c24f/results.json) |
| starfall_dressing_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-223627-366-31c3e306/results.json) |

New coverage: four workplaces/23 retired decorative leaves; four wagons,
four wheel replacements and six barricades/14 retired leaves; 28 textured
ruin silhouettes. Twelve city planters use static branched foliage. The
dressing test retains population unload/reload, saved task cues and reward
rules across seven Starfall routes.

Seven runtime GPU captures completed, exit 0; garden, workshop, nursery and
caravan views reviewed. Final log: .tmp-starfall-props-material-final.log.
No manual traversal or editor UI test this pass. Known certificate-store
warning only. Initial scene-assignment/test-array defects were corrected;
their failed intermediate runs are not accepted evidence.

## City arcades and masonry — 2026-09-27

**6/6 targeted tests PASS** after the final stair/bell material changes.
Full suite not run. Existing geometry, 84 upper walkway colliders and one-way
flags remain unchanged; four shallow arcades and nine tiled material surfaces
have explicit coverage. No new background owner or per-frame art work added.

| Test | Final report |
| --- | --- |
| starfall_upper_structure_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-214413-797-b549768a/results.json) |
| starfall_upper_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-214415-712-1eb33ded/results.json) |
| city_background_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-214417-625-fc243f22/results.json) |
| background_quality_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-214419-668-a34ba4c6/results.json) |
| town_material_expansion_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-214429-542-65b153df/results.json) |
| starfall_upper_city_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-214431-447-a3b88bc5/results.json) |

Six D3D12 1280x720 captures completed with exit 0. Final full-city and bell
views reviewed; garden also reviewed after the arcade material was added.
Log: .tmp-city-arcades-material-final.log. Only the known host certificate-store
warning; no script or shader errors. No manual traversal or editor UI test in
this pass. Art notes: art/visual_slice/CITY_ARCADES.md.

## Single city background correction — 2026-09-27

**9/9 targeted tests PASS** after removing the separate market painting.
Full suite not run. These results supersede the city-background implementation
described in the previous checkpoint, not the unrelated map-art results.

| Test | Final report |
| --- | --- |
| city_background_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210848-798-fec6f2ca/results.json) |
| background_quality_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210851-021-1d526bb0/results.json) |
| visual_style_slice_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210900-936-1ff6a5f5/results.json) |
| remaining_room_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210903-533-4bdbed87/results.json) |
| room_painted_depth_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210916-997-777645c4/results.json) |
| town_material_expansion_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210921-442-2e09370e/results.json) |
| starfall_upper_structure_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210923-693-f4fb9c33/results.json) |
| starfall_upper_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210925-537-e7382362/results.json) |
| starfall_upper_city_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-210927-514-aa4bfcc1/results.json) |

Runtime GPU capture completed normally (eight views); city full and market
were reviewed. Four editor-hint captures cover standalone and full-world
contexts; standalone whole and world street were reviewed. The editor harness
printed its success marker but required watchdog termination after 45 seconds
and emitted current_window-null warnings. It is not counted among clean test
passes. See art/visual_slice/CITY_BACKGROUND_UNIFICATION.md for limitations.

## Entry visibility / full city panorama / detail repair — 2026-09-27

**15/15 unique targeted tests PASS.** 181 active smoke scripts; full suite not run.

| Test | Final report |
| --- | --- |
| background_quality_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205620-995-7b80ceac/results.json) |
| room_painted_depth_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205615-178-0c439dbd/results.json) |
| driftworks_painted_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205456-182-09af30e4/results.json) |
| rampart_painted_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205453-752-5dfc5bd9/results.json) |
| starfall_arena_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205452-516-ca510ade/results.json) |
| ash_switchback_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205450-597-637c0919/results.json) |
| echo_room_identity_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205432-231-4183ac52/results.json) |
| shaft_room_identity_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205410-155-751f1670/results.json) |
| cistern_hazard_layout_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205358-128-3138bdf3/results.json) |
| blackwater_cistern_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205331-806-4923fa57/results.json) |
| starfall_upper_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205330-123-f2323587/results.json) |
| starfall_upper_structure_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205328-341-15267c56/results.json) |
| town_material_expansion_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205326-483-a3775a73/results.json) |
| visual_style_slice_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205324-198-f54a16b1/results.json) |
| remaining_room_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-205311-210-93ce4e30/results.json) |

Coverage: 33 painted profiles, 2,179 textured terrain polygons, 316 decorative
retirement report entries (not necessarily unique), 19 equipment/facade
surfaces, three pressure cells with nine detailed gauges. Physics, original
transforms, polygon shapes and z ordering remain protected by the art tests.
The smoke tests now require native 1536px backgrounds instead of 1024px.

Eight targeted GPU shots were reviewed, covering Cistern entry/join/tank,
Outskirts entry, market, west/east streets and full city. The Cistern's final
UV phase was adjusted to put masonry behind the dry entry instead of the
source image's water band; both art/quality tests passed again afterward.
Final captures: `.tmp-background-quality-final2.log` (D3D12 Forward Mobile).
Only known certificate-store and denied shader-cache writes; no script or
shader compilation errors. Editor import `.tmp-art-quality-final-import.log`
also reports sandbox-denied editor-settings writes. An intermediate
indentation error was corrected; earlier failed captures are superseded.

No new bitmap generation, full playthrough or phone-memory certification.
See [scope, source detail and remaining work](../art/visual_slice/BACKGROUND_QUALITY_REPAIR.md).


## Remaining world backgrounds — 2026-09-27

**16/16 unique targeted tests PASS.** 180 active smoke scripts; full suite not run.

| Test | Final status / report |
| --- | --- |
| ash_castellan_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202814-938-ef27f9f8/results.json) |
| ash_arena_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202754-330-9c1e05b9/results.json) |
| remaining_room_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202749-081-96b2025f/results.json) |
| echo_settlement_expansion_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202638-860-ccba6ba8/results.json) |
| training_passage_decor_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202634-711-ec34bf0e/results.json) |
| starfall_upper_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202633-451-d4c78151/results.json) |
| settlement_backdrop_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202632-207-2a6b38da/results.json) |
| ash_switchback_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202616-627-825b3cfc/results.json) |
| echo_room_identity_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202611-667-d22f339a/results.json) |
| echo_sanctum_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202601-903-404509fa/results.json) |
| echo_traversal_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202600-357-0ed80c43/results.json) |
| shaft_room_identity_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202550-405-f44023b0/results.json) |
| shaft_infrastructure_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202536-260-f492b545/results.json) |
| rampart_painted_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202534-080-354385f4/results.json) |
| driftworks_painted_art_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202531-927-7dec28a5/results.json) |
| room_painted_depth_smoke.gd | [PASS](../.tmp-smoke-suite-20260927-202529-182-d65bc589/results.json) |

The initial art check incorrectly assumed every original background had z <= -3;
the Shaft entry deliberately has z = -2, still behind actors. The assertion
now checks negative depth and separately preserves original z ordering.
After GPU inspection the flat grandstand/vault decorations were retired in
the two Ash arenas. Art, arena and Castellan tests were repeated afterward.

48 final D3D12 Forward Mobile captures were reviewed (24 close + 24 wide).
All capture saves returned 0. GPU log `.tmp-remaining-preview-final.log`
contains only the known certificate-store diagnostic. Fresh editor import
`.tmp-remaining-final-import.log` also reports sandbox-denied editor-settings
writes outside the project, but no script errors. The earlier OpenGL preview
is superseded because of driver initialization warnings.
Original/new PNG hashes match for all 24 assets. `git diff --check` passes.
No full playthrough, all-tests run or mobile performance claim.
See [coverage and exact ImageGen prompts](../art/visual_slice/WORLD_BACKGROUND_ROLLOUT.md).


## Driftworks mine art — 2026-09-27

**9/9 unique targeted tests PASS.** 179 active smoke scripts; full suite not run.

- [Art invariants, final cart placement](../.tmp-smoke-suite-20260927-192935-202-2e72262f/results.json).
- [Shared Ramparts art regression](../.tmp-smoke-suite-20260927-192509-388-f47358a9/results.json).
- [Shaft infrastructure](../.tmp-smoke-suite-20260927-192511-449-1ab98249/results.json).
- [Expedition population support](../.tmp-smoke-suite-20260927-192522-629-b36b7ee4/results.json).
- [Driftworks live normal route](../.tmp-smoke-suite-20260927-192548-164-4178bfc0/results.json).
- [Driftworks earned return route](../.tmp-smoke-suite-20260927-192619-222-935d8775/results.json).
- [Expedition field dressing](../.tmp-smoke-suite-20260927-192710-372-63813bec/results.json).
- [Expedition jumps](../.tmp-smoke-suite-20260927-192559-353-f4fe3e92/results.json).
- [Four expedition layouts](../.tmp-smoke-suite-20260927-192609-878-820d93cb/results.json).

The gameplay regressions preceded only a decorative cart-position correction;
the dedicated art test was repeated afterward. Five GPU views were reviewed,
with intake, pressure and outflow rechecked after moving carts away from boards.
Final captures: `_tmp_drift_art_preview2.log`; only known certificate/denied
shader-cache-write diagnostics, no script/shader compilation errors. Not a
complete manual playthrough or phone performance certification. See
[assets, exact prompts and remaining scope](../art/visual_slice/DRIFTWORKS_ART.md).

## Broken Ramparts art — 2026-09-27

**8/8 unique targeted tests PASS.** 178 active smoke scripts; full suite not run.

- [Art invariants, final alpha-foot correction](../.tmp-smoke-suite-20260927-191742-607-42210a7b/results.json).
- [Rampart field operations](../.tmp-smoke-suite-20260927-191617-847-45ec6e59/results.json).
- [Expedition jumps: 322 hops, 42 descents, 12 tunnels](../.tmp-smoke-suite-20260927-191628-158-2f88e560/results.json).
- [Four expedition layouts](../.tmp-smoke-suite-20260927-191631-903-51729aa3/results.json).
- [Expedition population support](../.tmp-smoke-suite-20260927-191635-588-9b9e57fb/results.json).
- [Starfall outer route](../.tmp-smoke-suite-20260927-191639-624-a734b3d5/results.json).
- [Starfall field dressing](../.tmp-smoke-suite-20260927-191640-153-d5246cf7/results.json).
- [Door interaction](../.tmp-smoke-suite-20260927-191652-527-7ad694a0/results.json).

The seven gameplay regressions preceded only the final decorative alpha-foot
placement adjustment; the dedicated art test was repeated afterward. Five GPU
views were captured/reviewed; watch and bridge rechecked after correcting the
visible foot position. `_tmp_rampart_art_preview2.log` has successful captures
and only known certificate / denied shader-cache-write diagnostics. Initial
imports found two new inferred-type parse errors, fixed before passing tests.
Not a full manual playthrough or mobile performance certification.
See [saved assets, prompts and limitations](../art/visual_slice/BROKEN_RAMPARTS_ART.md).

## Starfall arena art — 2026-09-27

**8/8 unique targeted tests PASS.** 177 active smoke scripts; full suite not run.
Accepted local reports after the final foundation addition:

- [Arena art invariants](../.tmp-smoke-suite-20260927-190100-039-7fcb65bc/results.json).
- [Empty Court combat / return lock](../.tmp-smoke-suite-20260927-190101-633-ce335626/results.json).
- [Arena navigation](../.tmp-smoke-suite-20260927-190110-054-b8867aac/results.json).
- [Starfall route](../.tmp-smoke-suite-20260927-190112-138-1fe19a84/results.json).
- [Final boss / battle lock / rewards](../.tmp-smoke-suite-20260927-190113-869-51cdd1b2/results.json).
- [Door interaction](../.tmp-smoke-suite-20260927-190122-154-68e5126e/results.json).
- [Boss-lamp reveal](../.tmp-smoke-suite-20260927-190127-539-4c9d8095/results.json).
- [Existing nine-room painted depth](../.tmp-smoke-suite-20260927-190129-224-ea3eb682/results.json).

Six GPU views captured and inspected (two close, two wide, two warning states),
logged in `_tmp_arena_art_preview2.log`. No script/shader compilation errors;
known host certificate and denied shader-cache-write diagnostics remain.
First art report `190000-975-8b6c8edb` failed an incorrect nine-surface expectation
for the Throne (actual eight); corrected count and detached-owner test warning.
This is not a full manual combat playthrough or mobile performance certification.
See [assets and exact ImageGen prompts](../art/visual_slice/STARFALL_ARENA_ART.md).

## Starfall route paintings — 2026-09-27

**11/11 unique targeted tests PASS after the final scene-scale adjustment.**
176 active smoke scripts; this is not a full-suite run. Accepted local reports:

- [Painted depth: nine rooms / 135 surfaces](../.tmp-smoke-suite-20260927-184726-427-f51986a6/results.json).
- [Outskirts](../.tmp-smoke-suite-20260927-184730-440-1d2ede9a/results.json).
- [Expanded routes](../.tmp-smoke-suite-20260927-184736-397-d230586b/results.json).
- [Outer route / Silent Gate](../.tmp-smoke-suite-20260927-184739-345-e58fa377/results.json).
- [Schematic portals](../.tmp-smoke-suite-20260927-184739-376-92fc6dbe/results.json).
- [Spawn restore](../.tmp-smoke-suite-20260927-184742-197-1971b803/results.json).
- [Rooted Hall](../.tmp-smoke-suite-20260927-184750-741-cdf4ed68/results.json).
- [Biome backdrop](../.tmp-smoke-suite-20260927-184751-180-f2c584ff/results.json).
- [Door interaction](../.tmp-smoke-suite-20260927-184756-752-a1cd258c/results.json).
- [Soul Crucible](../.tmp-smoke-suite-20260927-184801-218-75471a60/results.json).
- [Sunless Passage](../.tmp-smoke-suite-20260927-184812-246-30484cdc/results.json).

The GPU preview captured 19 images in `_tmp_star_depth_preview2.log`. Close/wide
views of all five new routes and adjusted Memory Vault, plus a Cistern regression
view, were inspected. Source images were also inspected. The first capture
showed excessive image magnification; Starfall now uses continuous mirrored
sampling with room-size-dependent scale. Shader compiled successfully. Known
host root-certificate and denied shader-cache-write diagnostics remain; these
are not claimed fixed. Headless reports contain no non-excluded errors.

Backgrounds add 70 surfaces without changing geometry, doors or actors. Existing
foreground pillars, roots, terrain and puzzle props are still provisional.
This pass does not certify mobile frame rate, final art or all rooms' backgrounds.
See [asset provenance and exact prompts](../art/visual_slice/STARFALL_ROUTE_BACKDROPS.md).

## Four-room painted parallax — 2026-09-27

**10/10 unique targeted tests PASS.** 176 active smoke scripts exist; the full
suite was not run. Accepted ignored local reports:

- [Painted depth (four rooms / 65 surfaces)](../.tmp-smoke-suite-20260927-183453-130-538c65a5/results.json).
- [Blackwater Cistern](../.tmp-smoke-suite-20260927-183520-332-7f9bbc8f/results.json).
- [Prism Archive](../.tmp-smoke-suite-20260927-183529-524-fa0ae5d6/results.json).
- [Forge](../.tmp-smoke-suite-20260927-183551-885-66b056ac/results.json).
- [Ash switchbacks](../.tmp-smoke-suite-20260927-183556-954-72e37efb/results.json).
- [Echo traversal](../.tmp-smoke-suite-20260927-183558-763-600ccb39/results.json).
- [Shaft expanded routes](../.tmp-smoke-suite-20260927-183530-310-5cf9134a/results.json).
- [Starfall expanded routes](../.tmp-smoke-suite-20260927-183532-253-556dda3a/results.json).
- [Biome backdrop](../.tmp-smoke-suite-20260927-183535-538-d2044455/results.json).
- [Room-door interaction](../.tmp-smoke-suite-20260927-183547-425-678af9c2/results.json).

Nine GPU previews were captured and visually inspected at gameplay/wide zoom,
including a moved-camera view. New shader has no compilation errors. Preview
logging includes the known host certificate diagnostic and denied shader-cache
write (`_save_to_cache`, `f.is_null()`); captures completed. Headless test logs
have no errors except the certificate warning excluded by the runner.

Initial editor import revealed Starfall's generated parent is StarfallDescent,
not AuthoredDescent; corrected and reimported successfully. Initial smoke report
`183335-691-5f2709a4` failed because the new test expected six forge galleries
rather than the actual seven; the assertion now checks 13 generated plates plus
the original FurnaceWall. Neither failed run counts toward the accepted result.
Editor AppData settings writes remain denied by the sandbox. This is not a full
performance, full-suite or hands-on combat playthrough result.

## Upper Starfall walkways and skyline — 2026-09-27

**8/8 unique targeted tests PASS.** 175 active smoke scripts exist; this is not
a full-suite result. Accepted ignored local reports:

- [Upper civic art, traversal/lift and structure art (3)](../.tmp-smoke-suite-20260927-181533-183-260045b3/results.json).
- [Town ambient, havens, materials and nameplates (4)](../.tmp-smoke-suite-20260927-181611-996-191110da/results.json).
- [Starfall field office (1)](../.tmp-smoke-suite-20260927-181622-236-6623ff6a/results.json).

Editor import finished with no script parse/compile errors. Its known host
certificate-store and sandboxed AppData editor-settings diagnostics remain.
All accepted runtime test logs contain no errors except the certificate-store
diagnostic excluded by the runner. Six 960×540 GPU previews were captured and
visually checked: artisans, gardens, bells, crown, bridge and skyline. No new
bitmap generation in this code-native 2D detail pass; no full performance or
hands-on playthrough claim. Geometry, collision and gameplay remain unchanged.

## Upper Starfall civic detail — 2026-09-27

**7/7 unique targeted tests PASS.** 174 active smoke scripts exist; the full
suite was not run. Accepted reports after the final code changes:

- [Upper art + traversal/lift/residents (2)](../.tmp-smoke-suite-20260927-180300-460-209fadb9/results.json).
- [Town ambient/havens/materials/nameplates (4)](../.tmp-smoke-suite-20260927-180338-091-20fcb6d9/results.json).
- [Starfall field office (1)](../.tmp-smoke-suite-20260927-180347-725-e3f0b2bf/results.json).

Four 960×540 GPU close-ups were generated with `preview_starfall_upper_art.gd`
and visually checked. New coverage: 10 facades/doors, 40 windows, 12 lanterns,
12 planters, three bells and telescope. Original geometry, routes, transforms
and collision remain unchanged; replacement scope is 90 leaf polygons.

Initial import caught a missing explicit float annotation, fixed before tests.
The first test run (`180040-844-d71bb0af`) failed because its assertion looked
up arbitrary Node2D instances in a Polygon2D-typed array; a type guard fixed
the test. Those runs are not counted as passes. Accepted runtime logs have
no script/runtime errors; the known host certificate-store diagnostic remains.
Editor import additionally cannot save sandboxed AppData editor settings.

## Echo/Starfall image-material expansion — 2026-09-27

**14/14 unique targeted tests PASS.** 173 active smoke scripts exist; this is
not a complete-suite result. Accepted local ignored reports:

- [Settlement art/backdrop/traversal (8)](../.tmp-smoke-suite-20260927-174155-313-536e1a79/results.json).
- [New material integration](../.tmp-smoke-suite-20260927-174208-887-cd2cc0fc/results.json).
- [Visual style pilot/Grotto regression](../.tmp-smoke-suite-20260927-174210-216-80cb7b8c/results.json).
- [Starfall upper city](../.tmp-smoke-suite-20260927-174211-560-41f43e9c/results.json).
- [Starfall field office](../.tmp-smoke-suite-20260927-174216-580-3d8029ff/results.json).
- [Echo expansion](../.tmp-smoke-suite-20260927-174220-704-427e9a38/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260927-174221-721-af1d020c/results.json).

Four newly generated project-local opaque textures, 512px mipmapped imports;
57 Echo walking surfaces and 33 Starfall facade/roof surfaces. Five GPU views
reviewed; old market grout drawing was disabled under new texture coverage.
Initial preview indentation typo corrected before accepted capture. Original
geometry/visibility/transforms/collisions and gameplay state retained. Known
environment certificate/settings/shader-cache diagnostics persist, with no
accepted-run script/shader compile errors. Not complete map art, a full
playthrough or mobile profiling. Asset prompts/provenance are recorded in
art/visual_slice/ECHO_STARFALL_MATERIALS.md.

## Hearth noticeboard and sky — 2026-09-27

**14/14 unique targeted tests PASS.** 172 active smoke scripts exist; this is
not a complete-suite result. Accepted local ignored reports:

- [Settlement art/backdrop/traversal (8)](../.tmp-smoke-suite-20260927-172920-135-2d2a7226/results.json).
- [Board readability/progression](../.tmp-smoke-suite-20260927-172933-941-ba1a2cdf/results.json).
- [Ash road records/save flow](../.tmp-smoke-suite-20260927-172934-884-99586005/results.json).
- [Ash frontier operations](../.tmp-smoke-suite-20260927-172940-878-d43f8457/results.json).
- [Nameplate layout](../.tmp-smoke-suite-20260927-172947-376-531ef5ff/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260927-172950-533-4f42a9ba/results.json).
- [Resident conversations](../.tmp-smoke-suite-20260927-172954-938-947ffb3f/results.json).

Four GPU captures reviewed: seven aligned status rows before/after boss and
two cameras near the top sky edge. Table spacing and placement were corrected
before acceptance; the frame avoids all 44 walking rectangles and leaves NPC
positions intact. Only EasternSky has a 140px top fade. Existing guidance,
progress/reward behavior and saves are retained. A prior run overlapped editor
import and reported transient missing Player types; it is NOT counted here.
The complete targeted set passed after import finished. Known certificate,
sandbox editor-settings and GPU cache diagnostics remain. No final-runtime
script/shader compile errors, full playthrough or mobile profiling claim.

## Cinder walkway facing — 2026-09-27

**13/13 unique targeted tests PASS.** 171 active smoke scripts exist; this is
not a complete-suite result. Accepted local ignored reports (final draw order):

- [Settlement art/portraits/supports/traversal (8)](../.tmp-smoke-suite-20260927-171628-859-54cd529e/results.json).
- [Cinder expansion](../.tmp-smoke-suite-20260927-171642-692-96621a6f/results.json).
- [Nameplate layout](../.tmp-smoke-suite-20260927-171645-923-cb81a725/results.json).
- [Town havens](../.tmp-smoke-suite-20260927-171648-957-e0ea568d/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260927-171652-843-de99de2b/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260927-171656-900-222333d5/results.json).

44 collision-aligned surface replacements; only original leaf plates hidden.
Physics, one-way flags, original geometry, doors and routes are unchanged.
Five staged GPU views reviewed; roof and NPC label occlusion were corrected
by drawing after roof accents at z=-1, behind actors/names. Existing sky edge
and prototype field-office panel remain documented follow-ups. No runtime
script/compile errors; known certificate/settings/shader-cache environment
diagnostics remain. Not a full playthrough or mobile performance result.

## Cinder civic facades — 2026-09-27

**13/13 unique targeted tests PASS.** 170 active smoke scripts exist; this is
not a complete-suite result. Accepted local ignored reports:

- [Settlement art/portraits/supports/traversal (7)](../.tmp-smoke-suite-20260927-170211-649-751f5a6c/results.json).
- [Nameplate layout](../.tmp-smoke-suite-20260927-170224-797-2b5be292/results.json).
- [Cinder expansion](../.tmp-smoke-suite-20260927-170228-042-a1cefbd8/results.json).
- [Town havens](../.tmp-smoke-suite-20260927-170230-973-b9f5516d/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260927-170234-940-3cf884f4/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260927-170238-844-2be70532/results.json).
- [Resident motion](../.tmp-smoke-suite-20260927-170243-443-d43ebf2c/results.json).

Six staged 960x540 GPU views were visually reviewed. Initial type inference
and school trim draw order were corrected before the accepted run. The new
test verifies static facade construction without changing original polygons,
visibility, transforms or physics. Headless editor import has no script
errors. Known environment certificate/settings/shader-cache diagnostics remain;
no new runtime script or shader compile errors. No full playthrough/mobile claim.

## Settlement readability and supports — 2026-09-27

**15/15 unique targeted tests PASS.** 169 active smoke scripts exist; this is
not a complete-suite result. Accepted local ignored reports:

- [Nameplate layout](../.tmp-smoke-suite-20260927-165429-869-af6e08ce/results.json).
- [Settlement art/supports/portraits/traversal (6)](../.tmp-smoke-suite-20260927-165433-238-b4b3c284/results.json).
- [Town havens](../.tmp-smoke-suite-20260927-165446-162-a1e19ce7/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260927-165450-045-f4e52621/results.json).
- [Resident motion](../.tmp-smoke-suite-20260927-165453-600-f035e7d9/results.json).
- [Resident conversations](../.tmp-smoke-suite-20260927-165454-340-b5861aa3/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260927-165457-237-2cf481c0/results.json).
- [Cinder expansion](../.tmp-smoke-suite-20260927-165501-583-e43d037e/results.json).
- [Echo expansion](../.tmp-smoke-suite-20260927-165504-699-4ee44680/results.json).
- [UI flow](../.tmp-smoke-suite-20260927-165505-678-f31d131b/results.json).

Four GPU town captures were visually reviewed. New tests exercise screen-space
name layout at three resolutions/two zooms and floor-aligned visual supports
without changing physics or existing transforms. Initial nullable priority
handling, test type inference and viewport content-scale setup were corrected
before this accepted run. Headless editor import has no script errors; known
certificate-store, sandbox editor-settings and GPU shader-cache diagnostics
remain. No full campaign playthrough or mobile performance claim.

## Settlement street details — 2026-09-27

**11/11 unique targeted tests PASS.** 167 active smoke scripts exist; this is
not a full-suite result. Local ignored reports:

- [Settlement art/backdrops/portraits/traversal (5)](../.tmp-smoke-suite-20260927-163826-216-df2d6066/results.json).
- [Final street art with Moon Forge display](../.tmp-smoke-suite-20260927-163932-183-82baced1/results.json).
- [Town havens](../.tmp-smoke-suite-20260927-163838-233-b23c35d1/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260927-163842-541-0fbf9aa0/results.json).
- [Cinder expansion](../.tmp-smoke-suite-20260927-163846-251-3a677da7/results.json).
- [Echo expansion](../.tmp-smoke-suite-20260927-163849-313-984f7a5e/results.json).
- [Resident motion](../.tmp-smoke-suite-20260927-163850-312-bb93d1cd/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260927-163851-244-be755072/results.json).

141 existing decorative elements now use cached detailed drawing; twelve old
bench feet are hidden as part of the same replacement. Original scene nodes,
geometry, physics and transforms are retained, with narrowly scoped visibility
changes. Four staged 960x540 close-ups were visually reviewed. Initial test
typed-array membership and preview zoom-transform defects were corrected;
the rejected initial report is not a passing checkpoint. Existing environment
certificate/settings/shader-cache diagnostics persist; no runtime script or
shader compile errors. No mobile profiling or complete map-art claim.

## Settlement building materials — 2026-09-27

**10/10 targeted tests PASS.** 166 active smoke scripts exist; this is not a
complete-suite result. Accepted local reports:

- [Settlement art/backdrop/portraits/traversal (4)](../.tmp-smoke-suite-20260927-161855-615-30594c45/results.json).
- [Town havens](../.tmp-smoke-suite-20260927-161906-836-1b04feda/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260927-161910-802-0ffa3fc7/results.json).
- [Cinder expansion](../.tmp-smoke-suite-20260927-161914-208-1cf40112/results.json).
- [Echo expansion](../.tmp-smoke-suite-20260927-161917-214-90b8ee17/results.json).
- [Resident motion](../.tmp-smoke-suite-20260927-161918-223-749e3361/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260927-161918-954-2f70598c/results.json).

Six new opaque surface textures are integrated, using shared 512px mipmapped
imports. 65 Echo and 33 Cinder polygons are painted; 59 window trims are static.
Tests retain all original geometry, visibility, physics and route markers.
Four staged GPU captures in art/characters/preview_*_houses.png were reviewed.
The balcony houses were added after the first visual review to avoid leaving
untextured foreground houses among the updated buildings. No world sprites,
colliders, gameplay rules or user saves were changed. No full playthrough or
mobile hardware profile is claimed. Existing environment root-certificate,
editor-settings and GPU shader-cache file diagnostics persist; no script or
shader compile errors occurred.

## Eight settlement portraits and two backgrounds — 2026-09-26

**13/13 unique targeted tests PASS.** 165 active smoke scripts exist; this is
not a complete-suite result. Reports (duplicate portrait runs counted once):

- [Backdrop/portrait/traversal (3)](../.tmp-smoke-suite-20260926-172530-672-bb7c3420/results.json).
- [All portrait regressions (3, one overlap)](../.tmp-smoke-suite-20260926-172540-635-7806af6d/results.json).
- [Expanded settlement quest-state/line coverage](../.tmp-smoke-suite-20260926-172711-093-a67fc5ea/results.json).
- [Town havens](../.tmp-smoke-suite-20260926-172614-973-cb651b45/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260926-172619-609-b29c9e9e/results.json).
- [Forge](../.tmp-smoke-suite-20260926-172623-885-4d53b22e/results.json).
- [UI flow](../.tmp-smoke-suite-20260926-172627-723-cc6082d2/results.json).
- [Existing visual slice](../.tmp-smoke-suite-20260926-172631-511-295a0d2b/results.json).
- [Cinder expansion](../.tmp-smoke-suite-20260926-172633-697-19aaaa5b/results.json).
- [Echo expansion](../.tmp-smoke-suite-20260926-172637-512-ef8e1a2b/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260926-172639-510-42522dda/results.json).

Eight unique 256px portrait imports are assigned explicitly in three scenes.
Two 1536px paintings cover fourteen pre-existing non-colliding background
polygons. Tests preserve physics, geometry, interaction fallback and UI layout.
Echo's new districts share continuous texture coordinates across floors/shafts.

Ten staged D3D12/mobile-renderer captures were visually reviewed in
art/characters/preview_*_settlement.png and preview_*_painted.png. Preview room
selection was corrected to `ash_hearth`; settlement shader tint/crop and shared
district UVs were corrected after reviewing the initial renders. Source PNGs
were not edited. No mobile hardware playtest or full world-art pass is claimed.

Editor import reported only the existing sandbox root-certificate/settings
write diagnostics. GPU captures completed successfully, with an additional
shader-cache `_save_to_cache` file diagnostic in this environment; no shader
compile or script errors were reported. Headless regressions have no unexpected
errors. These environment diagnostics are not presented as a fixed engine issue.

## Eldric and Lyra quest portraits — 2026-09-26

**9/9 targeted tests PASS on final runtime code.** 163 active smoke scripts
exist; this is not a complete-suite result. Accepted local ignored reports:

- [Quest portrait states/actions/rewards](../.tmp-smoke-suite-20260926-170647-524-04df4f16/results.json).
- [Neris/Orin portrait and shop layout](../.tmp-smoke-suite-20260926-170720-250-c70cc966/results.json).
- [Echo Survey/save/restore](../.tmp-smoke-suite-20260926-170724-237-e6931f3f/results.json).
- [UI flow](../.tmp-smoke-suite-20260926-170729-375-6f424402/results.json).
- [Town havens](../.tmp-smoke-suite-20260926-170733-116-a56c131b/results.json).
- [Resident conversation/motion (2)](../.tmp-smoke-suite-20260926-170737-591-5ec31a6b/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260926-170741-350-951ed23f/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260926-170746-341-bfb9f572/results.json).

Both new opaque portrait assets are integrated and imported at 256px. The
dedicated test covers 14 dialogue states at three headless viewport sizes,
then uses connected buttons and normal quest APIs for acceptance and rewards.
Two D3D12 staged captures at 960x540 were inspected, including visible quest
action buttons. Exact prompts/provenance: art/characters/QUEST_PORTRAITS.md.
World sprites and existing town crowding remain unchanged. Final import has
no script errors; known sandbox certificate/editor-settings diagnostics
remain. No physical-device test or full art/map acceptance is claimed.

## Generated NPC portraits and bounded shop descriptions — 2026-09-26

**10/10 targeted tests PASS on final runtime code.** 162 active smoke scripts
exist; this is not a complete-suite result. Accepted local ignored reports:

- [Portrait identity/layout/scrolling and 3 viewport sizes](../.tmp-smoke-suite-20260926-161520-259-6e3aa0ce/results.json).
- [UI flow/input/pause](../.tmp-smoke-suite-20260926-161555-885-6d4ca51d/results.json).
- [Town havens/purchases](../.tmp-smoke-suite-20260926-161559-562-5d14c78d/results.json).
- [Resident conversation and motion (2)](../.tmp-smoke-suite-20260926-161604-221-265ea816/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260926-161607-850-bc163510/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260926-161612-252-0dc86440/results.json).
- [Forge](../.tmp-smoke-suite-20260926-161617-156-9ade604b/results.json).
- [Weapon identity](../.tmp-smoke-suite-20260926-161620-891-e9750878/results.json).
- [Weapon styles](../.tmp-smoke-suite-20260926-161624-730-6b254a3f/results.json).

Four staged D3D12 captures at 960x540 were inspected: Neris dialogue, Orin
shop, scrolled item details and forge. Both generated portrait PNGs are
accepted and integrated; these are intentionally opaque UI assets, not new
world sprites or a fix for the failed transparent walk sheet. Original source
images are intact; Godot imports them at 256px. A pre-existing shop text/button
overlap discovered during capture was fixed with a bounded scrolling area.
See art/characters/NPC_PORTRAITS.md for exact prompts and provenance.

Final import has no script errors; known sandbox certificate/editor-settings
diagnostics remain. git diff --check passes. No full-world pacing, physical
mobile test, final settlement layout or full NPC art rollout is claimed.

## Resident conversation lifecycle and attention — 2026-09-26, 15:54 local

**12/12 targeted tests PASS on final runtime code.** 161 active smoke scripts
exist; this is not a complete-suite result. Accepted local ignored reports:

- [Conversation lifecycle and native motion (2)](../.tmp-smoke-suite-20260926-155430-525-ffce4098/results.json).
- [Ambient life and town havens (2)](../.tmp-smoke-suite-20260926-155248-014-4124b072/results.json).
- [Starfall field office](../.tmp-smoke-suite-20260926-155253-234-5dcfb52f/results.json).
- [Ash road records](../.tmp-smoke-suite-20260926-155257-891-6a08d3d1/results.json).
- [Chapter settlements](../.tmp-smoke-suite-20260926-155303-651-7b560dc0/results.json).
- [Hub support](../.tmp-smoke-suite-20260926-155307-838-edc5ff35/results.json).
- [Settlement traversal](../.tmp-smoke-suite-20260926-155310-389-a186a16b/results.json).
- [Cinder expansion](../.tmp-smoke-suite-20260926-155317-452-2aa01e08/results.json).
- [Echo expansion](../.tmp-smoke-suite-20260926-155321-181-327dc656/results.json).
- [Biome spawn/restore](../.tmp-smoke-suite-20260926-155323-147-d90ce2e5/results.json).

Two staged normal-zoom D3D12 captures were inspected: correct speaker/listener
gestures and facing. Existing overlapping market residents/nameplates remain
a follow-up, not a passed layout acceptance. See
`art/characters/RESIDENT_CONVERSATIONS.md`. Editor import has no script errors;
known sandbox certificate/editor-settings diagnostics remain. No new bitmap
art, mobile profiling or whole-map playthrough is claimed.

## Gait boundary fixes; new artwork blocked — 2026-09-26, 15:43 local

**9/9 targeted tests PASS on final code.** 160 active smoke scripts exist;
this is not a complete-suite result. Existing sprite atlases remain unchanged.
Accepted local ignored reports:

- [Gait reversal/restart and interruption boundaries](../.tmp-smoke-suite-20260926-154213-668-9edf9db0/results.json).
- [Movement art / wall / jump / dash](../.tmp-smoke-suite-20260926-154246-620-7bc46c49/results.json).
- [Character appearance](../.tmp-smoke-suite-20260926-154249-911-6bb59c58/results.json).
- [Actual attacks / contact](../.tmp-smoke-suite-20260926-154252-867-60eb6ca7/results.json).
- [Incoming damage feedback](../.tmp-smoke-suite-20260926-154255-996-54644404/results.json).
- [Melee impact](../.tmp-smoke-suite-20260926-154259-002-139d4f37/results.json).
- [Weapon registration](../.tmp-smoke-suite-20260926-154302-143-8f0d257e/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-154305-097-c4ae3e06/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-154310-778-0cca2620/results.json).

Built-in imagegen generation plus two transparency corrections all produced
opaque RGB checkerboards (1254x1254, zero transparent pixels per cell). No
new walk art is accepted or integrated; four-frame scripts are inactive .txt
drafts. Prompts and failed output paths: art/characters/WALK_CYCLE_ATTEMPT.md.
Import has no script errors; known sandbox certificate/settings diagnostics
remain. An initial inspection command without a local log override crashed
while opening user://logs; corrected read-only inspections succeeded. This
is not a full-map playthrough, four-frame animation delivery or mobile test.

## Incoming player damage feedback — 2026-09-26, 15:32 local

**9/9 targeted tests PASS on final code.** 159 smoke scripts exist; this is
not a full-suite rerun. Accepted local ignored reports:

- [Accepted damage / armor / rescue / real enemy shot](../.tmp-smoke-suite-20260926-153106-843-d95477c4/results.json).
- [Character appearance](../.tmp-smoke-suite-20260926-153124-897-1bb3cbb1/results.json).
- [Movement art](../.tmp-smoke-suite-20260926-153127-859-8ae3d536/results.json).
- [Actual attacks / contact](../.tmp-smoke-suite-20260926-153130-912-2c49cb28/results.json).
- [Melee impact](../.tmp-smoke-suite-20260926-153134-135-d6234bc1/results.json).
- [Projectile impact / shared budget](../.tmp-smoke-suite-20260926-153137-276-cf557466/results.json).
- [Guard combat](../.tmp-smoke-suite-20260926-153138-966-25ca0d0c/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-153142-178-2d2e79d9/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-153147-873-642492c2/results.json).

Three final D3D12 normal-zoom captures were inspected, after adjusting tint
brightness to work with existing invulnerability alpha. Accepted events
cover equal-HP Second Breath; rejected hits/heal/rest do not flash. Timers,
armor, knockback and collision remain unchanged. Lifecycle and full-budget
fallback are tested. Final preview/import have no script errors; sandbox
certificate/editor-settings-write diagnostics remain. Details:
`art/characters/PLAYER_DAMAGE.md`. No full playthrough or mobile benchmark.

## Sword contact feedback — 2026-09-26, 15:13 local

**9/9 targeted tests PASS on final code.** 158 smoke scripts exist; this is
not a full-suite rerun. Accepted local ignored reports:

- [48-case actual melee contacts and edge cases](../.tmp-smoke-suite-20260926-151130-549-a62a0ab5/results.json).
- [Actual attacks / contact](../.tmp-smoke-suite-20260926-151249-230-cefeb2c3/results.json).
- [Weapon registration](../.tmp-smoke-suite-20260926-151252-418-3196b947/results.json).
- [Projectile contact / shared cap cleanup](../.tmp-smoke-suite-20260926-151255-350-045ec09a/results.json).
- [Projectile hit budgets](../.tmp-smoke-suite-20260926-151256-909-245be407/results.json).
- [Weapon identity / target bonuses](../.tmp-smoke-suite-20260926-151302-856-d0c16c62/results.json).
- [Guard combat](../.tmp-smoke-suite-20260926-151306-870-d9d61bf1/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-151311-095-61a777a7/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-151319-755-4473d77c/results.json).

Three D3D12 captures reviewed: enlarged phases and two actual in-room sword
hits (right standing / left crouched). Final import/preview has no script
errors; sandbox certificate/editor-settings-write diagnostics remain. The
early test fixture's illegal synchronous self-free was corrected to queued
deletion before acceptance. Details: `art/characters/MELEE_CONTACTS.md`.
No complete-map playthrough, new body atlas or mobile profiling in this pass.

## Projectile contact feedback — 2026-09-26, 15:04 local

**7/7 targeted tests PASS on final code.** 157 smoke scripts exist; this is
not a complete-suite rerun. Local ignored reports:

- [Impact cases, seven physical shots, cap and cleanup](../.tmp-smoke-suite-20260926-150307-323-9d1ed24f/results.json).
- [Overlapping-target hit budgets](../.tmp-smoke-suite-20260926-150329-182-8b335040/results.json).
- [Actual attacks / contact](../.tmp-smoke-suite-20260926-150336-769-96de5e5c/results.json).
- [Weapon registration](../.tmp-smoke-suite-20260926-150340-282-38a0f86b/results.json).
- [Projectile appearance](../.tmp-smoke-suite-20260926-150343-629-cb1f6677/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-150345-451-17de54e1/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-150356-350-b4680038/results.json).

Two staged D3D12 contact-effect captures were inspected (enlarged and normal
Grotto zoom). No script errors in preview/import; sandbox certificate and
editor-settings-write diagnostics remain. Effects are contact feedback, not
damage confirmation or exact material detection. Full-map playthrough and
mobile profiling are not covered. See `art/characters/PROJECTILES.md`.

## Native projectile presentation — 2026-09-26, 14:54 local

**9/9 targeted tests PASS on final code.** There are now 156 smoke scripts;
this is not a complete-suite rerun. Accepted local reports (ignored temp
folders are not published to Git):

- [Projectile appearance / 36 variant-direction cases](../.tmp-smoke-suite-20260926-145239-408-5ad3aca0/results.json).
- [Projectile overlap / hit budget](../.tmp-smoke-suite-20260926-145343-909-af2af20e/results.json).
- [Six-weapon actual attack contact](../.tmp-smoke-suite-20260926-145354-702-393657df/results.json).
- [Weapon registration](../.tmp-smoke-suite-20260926-145359-267-ecc42049/results.json).
- [Weapon identity](../.tmp-smoke-suite-20260926-145403-553-43e3fab6/results.json).
- [Weapon styles](../.tmp-smoke-suite-20260926-145409-701-3fca0942/results.json).
- [Player movement art](../.tmp-smoke-suite-20260926-145416-375-cc87862f/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-145420-462-15ddded3/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-145436-452-164ea354/results.json).

New checks cover actual shot direction, palette, hidden/stopped/deletion
cleanup and unchanged shape/transform/damage/range/speed/piercing. D3D12
enlarged and normal-zoom Grotto captures were inspected. Editor import and
GPU previews have no script errors; sandbox certificate/editor-settings
diagnostics remain. See `art/characters/PROJECTILES.md`. Full-map playtime,
mobile performance and final painted effects remain unverified/pending.

## Native weapon presentation — 2026-09-26, 14:37 local

**9/9 targeted tests PASS on final code.** There are now 155 smoke scripts;
this is not a new complete-suite result.

- [Six-variant hand/weapon registration](../.tmp-smoke-suite-20260926-143732-658-a504351c/results.json).
- [Six-weapon actual attacks/contact](../.tmp-smoke-suite-20260926-143736-073-7a754d5f/results.json).
- [Player movement art](../.tmp-smoke-suite-20260926-143739-479-b4270634/results.json).
- [Player / wisp appearance](../.tmp-smoke-suite-20260926-143743-048-6e1e86d0/results.json).
- [Weapon identity](../.tmp-smoke-suite-20260926-143746-427-8510c2ce/results.json).
- [Weapon styles](../.tmp-smoke-suite-20260926-143750-597-b876e889/results.json).
- [Projectile hit budget](../.tmp-smoke-suite-20260926-143754-968-9d88613d/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-143803-026-553fa28e/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-143816-297-774bd5d4/results.json).

New tests check measured atlas hand anchors, mirrored/diagonal/crouched
weapon placement, phase changes, committed facing and unchanged collision/
cooldowns, plus hidden reset and zero opacity of legacy drawing nodes.
Both-facing and three staged in-room GPU captures were inspected. The
gallery was widened and staff tilt adjusted after the first review. Final
editor import and GPU preview have no script errors; sandbox certificate/
editor-settings errors remain. This extends native vector weapon art, not
bitmap generation. Projectiles/final material art and live full-map/mobile
validation remain pending. Details: `art/characters/WEAPONS.md`.

## Player attack body poses — 2026-09-26, 14:25 local

**9/9 targeted tests PASS on final code.** There are now 154 smoke scripts;
this is not a complete-suite rerun.

- [Six-weapon body animation / real contact](../.tmp-smoke-suite-20260926-142502-193-97d2a8d3/results.json).
- [Player movement art](../.tmp-smoke-suite-20260926-142505-812-080477a8/results.json).
- [Player / wisp appearance](../.tmp-smoke-suite-20260926-142509-404-1a6af5ce/results.json).
- [Ranged cues / freed target guard](../.tmp-smoke-suite-20260926-142513-162-dcfcfafa/results.json).
- [Weapon identity](../.tmp-smoke-suite-20260926-142516-736-78195aee/results.json).
- [Weapon styles](../.tmp-smoke-suite-20260926-142520-816-9bb63eb0/results.json).
- [Projectile hit budget](../.tmp-smoke-suite-20260926-142524-924-9bdef297/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-142534-700-7da5912c/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-142548-877-7a9df00b/results.json).

New coverage uses successful attack events and actual melee/projectile
contact for six weapon IDs, both facings and diagonal shots. It verifies
release/follow-through, original timers/body/reach, rejected attack silence,
equip/hurt/hidden/respawn cancellation and alpha. The initial fixture used
default equipment slots without selecting the active weapon; it was fixed
to equip the tested primary slot. Its failure also exposed a real freed-
target error in the ranged cue, now guarded and explicitly regression-tested.

Only the final genuine-alpha imagegen output was integrated; two opaque
drafts were rejected. Both-facing gallery and three staged attack captures
were inspected with the D3D12 renderer. Final import/preview have no script
errors; sandbox certificate/editor-settings errors remain. Weapon polygons
are still prototypes; these results do not certify finished animation,
manual live readability across all maps or mobile performance. Provenance
and exact prompts: `art/characters/PLAYER_ATTACKS.md`.

## Player movement art — 2026-09-26, 14:09 local

**9/9 targeted tests PASS on final code.** There are now 153 smoke scripts;
this is not a new full-suite run.

- [Real player movement / new poses](../.tmp-smoke-suite-20260926-140952-655-48d19f41/results.json).
- [Player / wisp appearance](../.tmp-smoke-suite-20260926-140956-046-1934d4bc/results.json).
- [Ranged art / projectile contact](../.tmp-smoke-suite-20260926-140959-755-97b295fb/results.json).
- [Weapon identity](../.tmp-smoke-suite-20260926-141003-309-030bca1d/results.json).
- [Weapon styles](../.tmp-smoke-suite-20260926-141007-485-8c24f07e/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-141011-974-03cbd1d9/results.json).
- [One-way drop through](../.tmp-smoke-suite-20260926-141026-743-def17672/results.json).
- [Close-platform descent](../.tmp-smoke-suite-20260926-141030-921-08acf96e/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-141034-961-1932daaf/results.json).

New checks cover real walking against a wall, both facings, high-refresh
pose hold, crouch/jump/fall/landing/dash, real attack during compression,
teleport/disabled-hidden resets, all atlas mappings and interior alpha.
Initial two focused tests also passed before final mipmap import. Both-facing
and normal-zoom GPU previews were inspected; no script errors in final
import/preview. Sandbox certificate/editor-settings write errors remain.
The first opaque imagegen draft was rejected, corrected through imagegen,
and only the genuine-alpha result was integrated. See
`art/characters/PLAYER_MOVEMENT.md` for exact provenance and prompts.
These are limited poses, not final animation or mobile/live campaign QA.

## Ranged bitmap continuation — 2026-09-26, 13:54 local

**7/7 targeted tests PASS on final code.** The suite still contains 152
smoke scripts; this is not a new complete-suite run.

- [Ranged bitmap / actual projectile contact](../.tmp-smoke-suite-20260926-135436-894-cdb06501/results.json).
- [Weapon identity](../.tmp-smoke-suite-20260926-135441-185-53f29562/results.json).
- [Weapon styles](../.tmp-smoke-suite-20260926-135447-198-f39536a2/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-135452-872-78252985/results.json).
- [Player / wisp appearance](../.tmp-smoke-suite-20260926-135508-776-93ce2bc3/results.json).
- [Crawler appearance](../.tmp-smoke-suite-20260926-135513-154-ea8dcb26/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-135517-424-3da1743d/results.json).

The built-in imagegen retry succeeded; the four-pose stone sentinel bitmap
is integrated. No credentials or client configuration changed, and the
earlier 401 root cause remains unknown. New assertions cover bitmap/cue
agreement in both directions, hurt art, alpha and hidden-room reset even
when processing was disabled. All prior projectile/cadence/collision checks
remain. The import and both D3D12 GPU captures completed without script
errors; sandbox certificate/editor-settings errors remain. Pose gallery
and staged normal-zoom capture were visually inspected. See
`art/characters/RANGED_CUES.md` for source, exact prompt and limitations.
This is not final animation, live full-map visual QA or mobile validation.

## Ranged attack cues — 2026-09-26 (earlier checkpoint)

**7/7 targeted tests PASS.** There are now 152 smoke scripts, not a new full
suite result. Accepted final reports:

- [Ranged cues / actual projectile contact](../.tmp-smoke-suite-20260926-005503-007-cfbd0ebf/results.json).
- [Weapon identity](../.tmp-smoke-suite-20260926-005505-613-b671e563/results.json).
- [Weapon styles](../.tmp-smoke-suite-20260926-005508-510-cda11003/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-005511-524-896afd9f/results.json).
- [Player / wisp art](../.tmp-smoke-suite-20260926-005516-997-ab6127f2/results.json).
- [Crawler art / live AI](../.tmp-smoke-suite-20260926-005519-270-e4b02395/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-005521-572-7dfabea9/results.json).

The new cue test verifies three launches per case with unchanged 0.6s first
shot / 1.4s repeats, left/right and elevated targets, actual physics contact,
warning cancellation and collision/muzzle invariants. A test-only inferred
type parse error was corrected before this accepted run. The final editor
import and GPU preview have no script errors; sandbox certificate/settings/
shader-cache write warnings remain.

Only native warning/muzzle cues were delivered. Bitmap generation failed
authorization (401); no new ranged sprite exists, and original art remains
visible. No broken bitmap reference or unfinished sprite presenter remains.
See `art/characters/RANGED_CUES.md`. This is not final ranged art, a new AI
windup rule, full-map acceptance or mobile-performance certification.

## Shaft Crawler art continuation — 2026-09-26

**7/7 targeted tests PASS on the final code.** There are now 151 smoke
scripts; this is not a new full-suite run.

- [Crawler appearance / live AI](../.tmp-smoke-suite-20260926-004032-167-a2995d62/results.json).
- [Guard / real melee](../.tmp-smoke-suite-20260926-004034-909-ef1d1e19/results.json).
- [Ranged combat](../.tmp-smoke-suite-20260926-004037-709-35e289ff/results.json).
- [Mixed combat](../.tmp-smoke-suite-20260926-004048-825-96f4c10a/results.json).
- [Player / wisp appearance](../.tmp-smoke-suite-20260926-004054-303-0b0c0a67/results.json).
- [Weapon identity](../.tmp-smoke-suite-20260926-004056-914-7eb03b8a/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-004100-148-06778028/results.json).

New art reads existing crawler AI and real displacement. Four live loops
verify both directions/tiers, complete warnings and awakened echo charges.
The HUD warning no longer overlaps health; body/contact shapes remain
unchanged. Tests also check first-hit feedback, inter-physics-frame stride
retention, hidden/teleport behavior and transparent atlas padding. The
fixture's stationary target is noncolliding; separate combat tests above
verify real weapon/contact interactions.

Final D3D12 pose/gameplay screenshots were inspected, including corrected
warning placement. The final PNG has real alpha (an intermediate opaque
checkerboard variant was rejected). Editor import/preview show no script
errors; known sandbox certificate, editor-settings and shader-cache write
warnings remain. This is limited 2D animation, not all-enemy production art,
full-map acceptance or mobile performance validation.

## Player and flying-spirit art pilot — 2026-09-26

**7/7 focused tests PASS on final production code.** There are now 150 smoke
scripts; this is not a rerun of the entire suite.

- [Character appearance](../.tmp-smoke-suite-20260926-002020-396-db035808/results.json).
- [Wisp cover / live dive](../.tmp-smoke-suite-20260926-002022-640-382f5ffb/results.json).
- [Weapon styles](../.tmp-smoke-suite-20260926-002025-622-2e52f548/results.json).
- [Ranged combat](../.tmp-smoke-suite-20260926-002028-498-eb9a1d8c/results.json).
- [Guard / melee combat](../.tmp-smoke-suite-20260926-002040-206-13cc58e8/results.json).
- [Basic jump routes](../.tmp-smoke-suite-20260926-002042-877-6b736c21/results.json).
- [Biome spawn / restore](../.tmp-smoke-suite-20260926-002047-310-ef909576/results.json).

New bitmap presenters replace only visible prototype art for the player and
ShaftWisp. Body/contact/attack shapes and timers are unchanged. The new test
covers real movement/attack/damage/death/respawn, all pose mappings, facing,
safe-rest handling, hidden sleep, alpha and awakened warning readability.
Initial test failures were fixture issues (respawning a living player;
comparing tier color before the existing hit-flash tween finished), fixed
without weakening gameplay. Preview-only frame indexing was corrected.

Final editor import reports no script errors. Final D3D12 GPU preview renders
two captures under `art/characters/`, inspected at enlarged and gameplay
scale. Sandbox certificate/editor-settings/shader-cache warnings remain;
these are not counted as successful writes. No device-performance, final
animation, full campaign or 5–10-minute room-pacing certification is implied.

## Environment polish, resident motion and Starfall editor repair — 2026-09-25

**12/12 targeted tests PASS** on the final code; 149 scripts now exist, but
this is not a new full-suite result. Accepted reports:

- [Resident motion](../.tmp-smoke-suite-20260925-192048-567-f3171caa/results.json).
- [Starfall schematic/live parity](../.tmp-smoke-suite-20260925-192049-478-0ef70dc6/results.json).
- [Town ambient life](../.tmp-smoke-suite-20260925-192051-022-a3a494f0/results.json).
- [Visual invariants](../.tmp-smoke-suite-20260925-192052-106-1953f991/results.json).
- [Expanded portal alignment](../.tmp-smoke-suite-20260925-192053-562-f2910694/results.json).
- [Remaining jump routes](../.tmp-smoke-suite-20260925-192055-572-b043ac27/results.json).
- [Shaft crossings](../.tmp-smoke-suite-20260925-192103-151-9587a625/results.json).
- [Upper city](../.tmp-smoke-suite-20260925-192106-421-f5896592/results.json).
- [City courier](../.tmp-smoke-suite-20260925-192111-081-6bc0e29b/results.json).
- [Starfall spawn/restore](../.tmp-smoke-suite-20260925-192115-161-5626a208/results.json).
- [World layout](../.tmp-smoke-suite-20260925-192119-511-752f2953/results.json).
- [Earned Grotto traversal](../.tmp-smoke-suite-20260925-192125-391-e41a94d9/results.json).

The market pilot includes the adjacent apothecary, herb sign and planters;
Grotto greenery is less uniform. ResidentMotion adds native vector detail
and idle/walk/talk animation to ordinary TownResidents, driven by actual
movement. Root position, interaction shape, labels, routes and indoor/social
logic are unchanged. Hidden residents stop animating and relocation does
not produce a walking stride. Service NPCs and combat characters retain
their previous art; this is not a final sprite-sheet delivery.

The Starfall schematic branch previously omitted the floor/semantic anchors
needed by portal placement. It now shares the live foundation builder,
without full live stairs/overlooks/population. Six preview/live pairs agree
on 15 doors, 15 arrivals and 126 sampled supported positions. This fixes the
missing T*_Bridge0 / null position errors documented below. Full editor
import/reopening completed with no script or missing-node errors in
`_tmp_visual_polish_editor_complete.log`; certificate-store and sandbox-blocked
editor-settings writes remain environmental warnings.

Four screenshots were re-rendered with D3D12 Forward Mobile and inspected,
including a gameplay-zoom apothecary/resident view. Capture succeeded; the
restricted shader-cache write warning remains. Static screenshots plus the
movement-state regression do not establish on-device animation performance.
The smoke runner now uses unique timestamp/GUID output folders after two
fast sequential invocations exposed a same-second folder collision.

## First 2D environment art pilot — 2026-09-25

Integrated original imagegen background paintings and native foreground
details in Echo Grotto and the Starfall market district. Five targeted
regressions pass on the final code (not a new full-suite run):

- [Visual invariants, UVs, camera response and hidden-room sleep](../.tmp-smoke-suite-20260925-185812/results.json).
- [Earned Grotto live traversal](../.tmp-smoke-suite-20260925-185814/results.json).
- [Upper-city gameplay](../.tmp-smoke-suite-20260925-185834/results.json).
- [World layout / activity](../.tmp-smoke-suite-20260925-185839/results.json).
- [City courier quest](../.tmp-smoke-suite-20260925-185845/results.json).

No test failures or script errors; runner ignores only its documented
certificate-store warning. Art adds no colliders; the new test compares
existing shapes/transforms/flags before and after art attachment. Static
scenery stays cached and animated accents are throttled. Desktop GPU
screenshots were rendered using D3D12 Forward Mobile and visually reviewed;
the capture logged a shader-cache write warning in the restricted environment.
The earlier OpenGL attempt is not used as the accepted renderer result.

There are now 147 smoke scripts. This is an environment sample, not final
characters, combat animation, mobile performance or whole-world art approval.
The headless editor import exposed separate existing Starfall schematic
portal-anchor errors and restricted editor-settings writes; no claim of a
clean combined-world editor import is made. See [art notes, exact prompts
and in-engine captures](../art/visual_slice/README.md).

## Remaining Echo navigation — 2026-09-25

The new `echo_remaining_navigation_smoke.gd` passes continuous terrain-only
round trips in Tide Well, Echo Nest, Crystal Causeway and Undertow Vault:
**40 chambers, 18 side branches, 36 forward + 36 reverse links**. One initial
placement per room, ordinary five-HP/basic-movement controller, no intermediate
teleports. Actors, hazards and interactions are disabled; this is not live
combat or 5-10-minute human-pacing acceptance.

Production fixes: Tide Well's old right wall at x=2000 obstructed its expanded
third chamber; it now sits at x=3200, beyond the route. Causeway's third branch
entrance was stranded across a shaft mouth. First branch planks now extend
toward the nearest surviving floor of their own chamber only when the gap
exceeds 70 px, leaving 32 px and preserving one-way collision. No movement,
enemy or reward statistics changed. The test also orders left-facing shelves
by physical entrance/interior distance instead of alphabetical A/B names.

The [new round-trip report](../.tmp-smoke-suite-20260925-181410/results.json)
passes. The [expedition regression](../.tmp-smoke-suite-20260925-181444/results.json)
passes **4/4**, including 322 isolated controller hops, 42 link-wise continuous
descents and 12 tunnel walks across all four wings. This includes Depths but
does not establish a continuous Gallery -> Depths -> Archive campaign.
The separately tested Echo field operations cover first-clear tasks, awakened
trials, one-time rewards, partial save rollback and completed-save restoration
with functional fixtures, not ordinary-health live fights.

There are now 146 smoke scripts. The full 145-script run below is the previous
checkpoint; it was not rerun or relabelled as a new full-suite result.

Final targeted regression: **22/22 PASS** across the
[18 Echo scripts](../.tmp-smoke-suite-20260925-181434/results.json) and
[four expedition scripts](../.tmp-smoke-suite-20260925-181444/results.json).
This reruns the earned Grotto route, saved awakened return, Gallery/Archive
live follow-up, all 134 shaft-entry/rim hops and the new four-room round trip
on the final terrain. No script errors or failures; only the documented
Windows certificate-store warning is ignored. `git diff --check` is clean
and the new navigation test removes its temporary save.

## Saved Echo return, Gallery and Archive — 2026-09-25

**All 145 current smoke scripts pass in one complete sequential run: no
failures, missing scripts or duplicates.** See the [full report](../.tmp-smoke-suite-20260925-174717/results.json).
This includes both new connected follow-ups and the expanded shaft regression
on the final production code. The new routes' temporary saves/backups were
cleaned by their runners; `git diff --check` and whitespace checks on the new
helpers are clean. Only the runner's documented Windows certificate-store
warning is ignored. The older checkpoints below describe earlier states.

Accepted focused reports:

- [Grotto earned route, saved return and room mechanics: 3/3](../.tmp-smoke-suite-20260925-173524/results.json).
- [Gallery / Archive connected follow-up](../.tmp-smoke-suite-20260925-174625/results.json).
- [Expanded shaft coverage: 134 real-controller hops](../.tmp-smoke-suite-20260925-174621/results.json).

`echo_grotto_return_route_smoke.gd` earns the original Crossing/Grotto
progress, explicitly sets the post-clear Echo tier to one, saves/reloads
it and starts a return-entrance fixture. It physically traverses all nine
galleries/four branches again, enters the tier-six trial, defeats both
guardians and collects its reserve. A second load verifies completed
guardians do not respawn and neither old nor new caches pay twice. Result:
**25 foes, 4/5 HP at entry and finish, two herbs used, 194.0 bot seconds**
in the final full run (193.3 seconds in the earlier focused run).
This tests saved awakened exploration, not a Matriarch defeat.

`echo_gallery_archive_route_smoke.gd` carries the actual preceding earnings,
HP and build through a real Grotto -> Gallery door. Gallery physically
collects its prism, visits nine galleries/four branches, hears both
witnesses and claims the offering. Its explicit first Archive approach
correctly goes to **Echo Depths**. Depths is not traversed in this script:
Archive uses one disclosed entrance placement, retaining Gallery's earned
inventory and current HP. Its original Root -> Star -> Echo mirrors are
operated normally. The Zenith -> Dawn -> Dusk field sequence includes two
links walked backwards and forwards and a fifth branch visit. A late
patrolling guard below the Dusk balcony is fought by physically descending
and climbing back. The final shortcut leads to Grotto. Both saved room
snapshots preserve exact health, build, currency, items and completed
records, and refuse duplicate cache rewards.

Final focused results: **Gallery 25 foes, 4/5 -> 4/5 HP, one herb, 186.0 bot
seconds; Archive 25 foes, 4/5 -> 4/5 HP, no herbs, 234.7 bot seconds**.
Each stage buys three herbs for 54 genuinely earned Gold through normal UI
handlers, without claiming merchant travel. Only those purchases and actual
guaranteed cache herbs enlarge the healing budget; random drops do not.
Maximum HP remains five and movement stays basic. There is no health refill,
damage injection, disabled enemy or intermediate objective teleport.

The Archive run exposed a real lower-shaft issue: a neighbouring shaft had
removed the expected takeoff floor. Expanded seven-room coverage found
three lower approaches outside the 70-pixel safety bound: Gallery link 8
(76.1 px), Archive link 7 (92.7 px) and Tide Well link 4 (79.0 px). Those
bottom planks now extend toward their actual surviving lower-chamber floor,
leaving a 32-pixel gap. Other steps, silhouettes, one-way collision and
unrelated galleries are unchanged. Archive's optional `AlcoveCrate06` also
moves 110 px left on the same shelf so it no longer stops the mandatory
jump with a head collision. A placement assertion protects that clearance.
The regression now checks **60 lower entries + 74 upper rims = 134 hops**.
Earlier failing diagnostic logs remain available; they were not relabelled.

Test-driver corrections distinguish same-height galleries by chamber ID,
rejoin the actual crossing plank after an incidental high landing, and use
an ordinary jump to reverse outward momentum at a precarious rim. Bounded
Gallery/Archive combat and listening retries preserve live actor behavior.
Enemy strength, player stats, reward amounts and listening rules were not
relaxed to pass these tests.

Next: connected exploration/returns through remaining Echo routes (including
Depths), then comparable Ash/Starfall playthrough coverage. Human readability,
5–10-minute room pacing, whole-campaign balance, final 2D art and real-phone
performance remain separate work. The ignored weak starter-sword Flooded
Gallery diagnostic remains outside the acceptance blockers.

## Connected Echo Grotto and reversible shaft rims — 2026-09-25

**28 relevant smoke scripts pass after this increment.** The project now
contains 143 runnable smoke scripts; the full 143-script batch was not rerun.
The older complete 141-script checkpoint below predates these changes.
Coverage comprises the [14-test Echo batch](../.tmp-smoke-suite-20260925-171040/results.json),
the [new connected Grotto run](../.tmp-smoke-suite-20260925-171149/results.json)
and 13 focused regressions: basic jumps, Prism Archive, Tide Well, Crystal
Causeway, Undertow Vault, portal alignment, biome support/spawn restoration,
world population/layout/routes, route dressing and world expansion integration.
Those reports run from `.tmp-smoke-suite-20260925-171227` through
`.tmp-smoke-suite-20260925-171317` (excluding the separate Grotto repeat).
The [Grotto repeat](../.tmp-smoke-suite-20260925-171309/results.json) also
passes with the same route/health/supply metrics. `git diff --check` is clean;
the Echo tests' temporary saves/backups were removed by their own cleanup.

The connected route exposed a real terrain gap missed by isolated ascent
tests: the top shaft plank favoured one rim, leaving a 125-pixel gap plus a
roughly 50–59-pixel rise on the opposite side. Grotto's Tier07 crossing failed
while the player was alive. Echo top planks now extend toward both actual
upper-corridor rims, including merged openings, leaving 32-pixel gaps while
retaining one-way collision. Separate neighbouring galleries are not joined.
`echo_shaft_crossings_smoke.gd` checks all **60 shafts / 74 real rims** across
the seven Echo rooms and performs **74 actual basic-controller ascent hops**.
This is isolated terrain coverage, not seven full combat playthroughs.

`echo_grotto_earned_route_smoke.gd` completes the real Crossing route first,
spends two earned skill points on sword mastery/reach and buys three herbs
for 54 earned Gold. Echo starts with one explicitly placed entrance fixture;
no Warden kill or physical inter-zone arrival is claimed. Maximum health
remains 5, current health is preserved and movement stays basic. The initial
Crossing setup retains its documented 36 setup Gold/two herbs. Shopping
uses the actual UI handlers without merchant travel. No actors are disabled,
no damage is injected and there are no intermediate player placements.

The Echo stage physically visits both original resonators, all nine main
galleries, four side chambers, the low/middle/high listening sequence and
the hidden offering. It exits by explicit Gallery-door interaction, then
reloads a snapshot and checks room, HP, earned skills, both resonators,
completed records and exact item/Gold quantities. The claimed offering
refuses a second payout. JSON numeric quantities are compared by value,
not by int/float Variant type. Result: **25 enemy defeats, entered 3/5 HP,
finished 4/5 HP, two herbs used, 195.5 bot physics seconds**. Only purchased
and acquired guaranteed herbs increase the healing budget; random drops do
not. This is not a human room-duration measurement or awakened Echo return.

The high listening balcony could be blocked by a guard on the floor below.
The driver now physically clears that lane, while the production prompt
identifies threats **above / below / left / right / nearby**. Threat radius,
listening duration, interruption and completion rules are unchanged. The
discovery regression verifies every direction and clearing a stale warning.

During development, a stale UI reference retained after the Crossing reload
crashed one pilot process. The new driver now acquires the new world's UI;
only that identified test process was terminated. This was a harness issue,
not evidence that the user's earlier editor crash has been diagnosed.

User direction: the additional starter-sword Gallery diagnostic is ignored
as a development blocker. Its historical failed logs are retained, not
relabelled as passing. **Next:** saved awakened Echo Grotto exploration,
then connected Echo Gallery/Archive and remaining Echo routes. Whole-campaign
combat, hands-on readability, final art, phone performance and human
5–10-minute pacing still remain outside this acceptance.

## Earned-build Gallery, Cistern and Approach — 2026-09-25

**All 141 current smoke scripts were run and pass: no missing scripts or
failures.** This is the [full sequential 140-script batch](../.tmp-smoke-suite-20260925-164228/results.json)
plus the [new Approach wrapper](../.tmp-smoke-suite-20260925-164545/results.json),
which was added after that batch started. It is not a single 141-script
batch. The unique report names were compared with every current
`tests/*_smoke.gd`: 141 expected, 141 tested, zero missing, zero failed.
Cistern additionally passed its [two-test focused batch](../.tmp-smoke-suite-20260925-164125/results.json).
`git diff --check` is clean and the new tests' temporary saves/backups were
cleaned up. The only exempted log error is the exact known Windows root
certificate-store warning. The separately failed starter Gallery diagnostic
below is **not** included in the passing smoke count.

The 136-test result below is an older checkpoint. New accepted connected
runs use **ordinary maximum 5 HP**, the
starter sword with mastery/reach bought using two points earned in the actual
Crossing clear, and no movement upgrades. The real Crossing door leads into
Gallery; Gallery's real exit leads into Approach. Optional Cistern has one
explicit entrance placement. Each awakened return has one entry placement.

| Stage | Enemy defeats | Entry / final HP | Herbs used | Bot physics seconds |
| --- | ---: | --- | ---: | ---: |
| Gallery first visit | 21 | 3 / 4 | 4 | 171.2 |
| Gallery tier-one return | 23 | 4 / 3 | 3 | 175.5 |
| Cistern first visit | 20 | 4 / 3 | 2 | 268.7 |
| Cistern tier-one return | 20 | 3 / 3 | 2 | 222.9 |
| Approach first visit | 21 | 3 / 3 | 1 | 162.2 |
| Approach tier-one return | 23 | 3 / 3 | 3 | 165.3 |

These are particular automated routes, not human 5–10-minute pacing results.
The chain's initial Crossing fixture has the documented 36 setup Gold for
two herbs; later preparation uses only rewards earned by actual traversal.
Two herbs cost 36 genuinely earned Gold before each base stage; three cost
54 earned Gold before each return. Only herbs actually acquired from
guaranteed rewards extend the allowance. Carried stock and random drops are
tracked but cannot raise it. There are no health refills or injected kills.
Shopping uses real UI handlers without walking to the merchant. Awakening
is a tier fixture, not an earned Warden defeat or whole-campaign run.

Each stage traverses seven galleries and five side detours, completes its
controls, claims its base rewards, rides the actual return lift both ways
and explicitly exits. Cistern additionally uses the repaired shortcut to
revisit its pump-locked memory niche, then collects its old lower cache.
The returns physically defeat the new trial guardians and claim their new
reserve while checking old caches pay nothing. Completed saves restore
exact HP, skill progress, supplies, mechanisms, shortcuts and one-time
rewards. The older optional afterglow-contract caches are separate from
these trial reserves and remain covered by isolated integration tests.

**Production correction:** three Cistern pressure fields were relocated
with their tank/gauge dressing. Ten detected field/stair/waiting-floor
conflicts are removed. Field size, damage, timing and knockback are unchanged;
48-pixel waiting pockets and protected stair approaches are now checked by
`cistern_hazard_layout_smoke.gd`. Pump completion still disables all fields.

Test steering now physically rejoins a cache's support after knockback and
re-plans overlapping-floor arrivals. Advanced final-room steering is opt-in:
rejoin the actual main floor before distant shaft jumps, descend onto shaft
spans before using them for the next hop, move beside overhead fauna rather
than repeatedly jumping into them, and cross low pulses using warning-aware
jumps. Actors remain active; required guardian defeats are still asserted.

Earlier failed Approach diagnostics identified a hostile BranchGrazer above
Niche1: a too-small combat search radius excluded it as the bot sidestepped,
then navigation repeatedly jumped underneath it. Expanding that search
radius only for the Approach return produced the completed ordinary-health
run above; no animal/enemy stats or platform collisions were changed.

### Remaining acceptance boundaries

- User direction (2026-09-25): ignore the additional fresh starter-sword
  Gallery scenario below. Keep its historical result, but it is no longer a
  blocker or the next development task; continue Echo connected exploration.
- The separate fresh starter-sword Gallery diagnostic was repeated after
  the final driver changes and still fails: death at the Niche4 ambush after
  its two purchased herbs and the first guaranteed herb. Its controls and
  earlier combat succeed, but not the whole route. The retained log is
  `.tmp-gallery-starter-final.log`. This is not the earned-build acceptance
  setup, and the passing wrappers do not erase this failed balance/steering
  diagnostic. No stat nerf or extra setup supply was used to conceal it.
- Ordinary-health end-to-end campaign/boss progression and other builds are
  not established by isolated encounter tests or tier fixtures.
- Human navigation/readability, visual polish, 5–10-minute pacing and real
  phone performance still need hands-on acceptance. Maps are not declared
  production-complete by this automated batch.

## Saved earned-build Crossing return and Gallery diagnostic — 2026-09-25

**Full sequential regression: 136/136 smoke scripts pass, zero failures.**
[Complete report](../.tmp-smoke-suite-20260925-155653/results.json).
This run includes the final shared-driver changes and the new Crossing
return, which also passed twice separately. Only the exact existing Windows
certificate-store warning is exempted; all other engine/script errors fail
the runner. `git diff --check` is clean, and both new isolated save files
were cleaned up. The unfinished Gallery diagnostic below is not included
in the 136 passing suites or presented as accepted gameplay.

`crossing_earned_return_smoke.gd` now passes repeated ordinary-health runs.
The real base traversal earns its preparation; two points buy sword
mastery/reach and **54 earned Gold buys three return herbs** through actual
UI handlers. This is a three-herb preparation, not the two-herb base setup.
There is no health refill, injected XP, maximum-health increase or movement
upgrade. Carried/random herbs cannot increase the finite healing allowance;
only the new trial's one guaranteed herb can extend it.

The saved tier-one return preserves the valve and all seven quiet currents,
traverses seven galleries and five side detours, physically defeats both new
sediment wisps, claims their reserve, checks both old caches without payout,
rides the lift both ways and explicitly exits. Reload verifies health, skill
progress, mechanisms, quantities, trial completion and one-time rewards.
Repeated result: **22 enemy defeats, entered at 3/5 HP, finished at 4/5 HP,
three herbs used, 186.4 bot physics seconds**. Base-earned Gold varies with
loot (293 and 285 in the first two passing runs). Awakening itself is an
explicit fixture, not a Warden victory. Each stage has one entrance placement;
shopping does not include physical merchant travel. This is not pacifist,
full-campaign, visual or human 5–10-minute pacing acceptance.

Test-driver corrections, with no production map/stat changes:

- Normal available sword/healing input continues during jump steps, not only
  corridor walking; terrain-only tests retain an empty input hook.
- A combat hop onto a higher incidental plank triggers a bounded physical
  re-plan, not a false arrival on the lower shallow step.
- A destination outside an incidental narrow support is not clamped forever
  to that support; an emergency combat hold inside the lip margin finishes
  at a safe reachable point on the same ledge.
- Previously claimed cache payout is compared around synchronous interaction,
  excluding ordinary loot collected during preceding settling frames.

Repeated standalone reports:
[first pass](../.tmp-smoke-suite-20260925-155558/results.json),
[repeat pass](../.tmp-smoke-suite-20260925-155642/results.json).

**Flooded Gallery remains unfinished.** Its new diagnostic
`gallery_live_route_pilot.gd` stays outside the smoke glob. The latest starter
sword/5-HP attempt, with two herbs purchased using 36 setup Gold, activates
both controls and disables all seven jets. It defeats 16 enemies and completes
four gallery links/three detours, but dies at the high-niche approach after
using the two purchased herbs and one guaranteed herb already acquired.
The remaining reward, route, lift and onward exit are not accepted; final
Gallery persistence checks are not yet implemented. Its failure is retained
in [the diagnostic log](../.tmp-gallery-live-03.log), not counted as a pass.
Next investigate combat positioning and an earned-build arrival from Crossing,
then complete the remaining route/exit/save checks. No additional health or
supplies were added to the Gallery fixture to force success.

## Earned Driftworks return and connected Drowned Crossing — 2026-09-25

**35 distinct relevant smoke suites pass after this increment.** There are
135 runnable smoke scripts; the complete 135-test batch was not rerun.

`driftworks_earned_return_smoke.gd` first completes and saves the normal base
route, then spends two genuinely earned points on sword mastery/reach and
36 earned Gold on two return herbs through the real UI handlers. The latest
base stage earned 10 points and 331 Gold (Gold varies with loot). It preserves
the base finish's 4/5 HP, repaired pumps, quiet leaks and claimed base caches.
After explicit tier-one setup and save/reload, the connected return traverses
all eight chambers/four branches, physically clears all three new engine
guardians and claims their separate reserve. It checks all three old caches
through interaction without payout, rides the lift both ways, explicitly
exits and saves/reloads the completed return, including skill progress.
Latest return: **23 enemy defeats, 3/5 HP, two herbs used, 212.9 bot physics
seconds**. Four provoked fauna defeats are logged separately. Only its one
new guaranteed cache herb extends the two-herb allowance; carried/random
herbs cannot. Awakening is a fixture, not a Warden victory. Each stage has
one initial entrance placement; shopping does not include merchant travel.

`crossing_live_normal_smoke.gd` covers all seven Drowned Crossing galleries,
five side detours, the actual valve interaction, guarded high cache and
Crossing supply cache, return lift both ways and explicit exit to Flooded
Gallery. Seven currents begin active and are silenced only by the valve;
the driver does not pretend continuous currents have a periodic safe phase.
The completed snapshot preserves health, valve, quiet currents, lift, Gold,
inventory quantities and claimed caches without repeat rewards. Latest:
**22 enemy defeats, 4/5 HP, two herbs used, 193.9 bot physics seconds**.
Setup fixes starter sword/5 HP, no movement upgrades and two herbs purchased
with 36 setup Gold; only guaranteed cache herbs extend the healing budget.
This starts at the lower-Shaft entrance, not a continuous Driftworks arrival.

Two Crossing stalls were test-driver issues, not confirmed terrain defects:
the driver withheld a sword swing near passive fauna but waited forever at
the intervening crate; it now hops that obstacle. A drop input also skipped
both overlapping planks when the destination was only four pixels lower;
it now walks beyond the upper lip and settles normally on the lower plank.
The shared Hollow detour skips ore-survey interactions only when the room has
no survey. No production terrain, combat stats, movement strength or player
health changed in this increment. None of these runs is pacifist acceptance.

Reports: [Driftworks 2/2](../.tmp-smoke-suite-20260925-153141/results.json),
[Crossing live](../.tmp-smoke-suite-20260925-153038/results.json),
[Hollow 6/6](../.tmp-smoke-suite-20260925-153048/results.json),
[Shaft 19/19](../.tmp-smoke-suite-20260925-153157/results.json),
[expedition 4/4](../.tmp-smoke-suite-20260925-153241/results.json),
[Crossing integration](../.tmp-smoke-suite-20260925-153252/results.json),
[neutral creatures](../.tmp-smoke-suite-20260925-153257/results.json),
[close-platform descent](../.tmp-smoke-suite-20260925-153300/results.json).
Only the existing exact Windows certificate-store warning is exempted.
`git diff --check` is clean; isolated Crossing/Driftworks saves were cleaned up.

Next: earned-build awakened Crossing and connected Flooded Gallery, followed
by the remaining room routes. Full-campaign/Warden progression, other builds,
manual visual review and human 5–10-minute room pacing remain unverified.

## Connected ordinary-health Driftworks — 2026-09-25

**31 distinct relevant smoke suites pass after this increment.** There are now
133 runnable smoke scripts; the complete 133-test batch was not rerun. The
previous complete 132/132 checkpoint below predates these driver changes.

The new `driftworks_live_normal_smoke.gd` walks all eight main chambers and
four side branches with the starter sword, normal 5 HP and no movement
upgrades. All room actors/hazards stay live. It restores both pumps through
physical interactions, checks each pressure leak independently, collects
MidCache, RimCache and Engineer Reserve, uses the real return lift both ways,
walks to the exit and requires explicit interaction to enter Drowned Crossing.
A snapshot reload then preserves health, pumps, disabled leaks, activated
lift, Gold, all inventory quantities and claimed caches without repeat payout.
The first-visit run does not trigger the separate awakened machinery trial.

Latest result: **19 enemy defeats, 4/5 HP remaining, three herbs used and
217.4 bot physics seconds**. Preparation supplies 36 Gold to buy two herbs
through the real shop handlers; only actually acquired guaranteed cache herbs
extend that healing allowance. Random drops cannot raise it. There is one
initial entrance placement, no artificial damage/kills or mid-route resets;
the lift and exit use actual transitions. Seven grazers start passive, but
five provoked fauna are defeated during traversal and counted separately.
This is not a pacifist/animal-avoidance acceptance run.

An initial connected attempt exposed a test steering limitation: it waited
until above a distant solid lip before moving sideways, wasting the basic
jump arc. The shared driver now approaches during ascent when a real gap
separates the platforms; it still delays sideways motion for overlapping
solid ledges. No production terrain, movement strength, health or enemy stats
were changed. The pilot exposes geometry/hazard hooks so Driftworks tests its
own floor graph and pressure leaks rather than Hollow's rockfalls.

Reports: [Driftworks](../.tmp-smoke-suite-20260925-151653/results.json),
[Hollow 6/6](../.tmp-smoke-suite-20260925-151344/results.json),
[Shaft 19/19](../.tmp-smoke-suite-20260925-151531/results.json),
[expedition 4/4](../.tmp-smoke-suite-20260925-151625/results.json),
[neutral creatures](../.tmp-smoke-suite-20260925-151703/results.json).
Only the existing exact Windows certificate-store warning is exempted.
`git diff --check` is clean; the isolated Driftworks temporary saves are removed.

Limits: this is one base-room route, not the awakened return, all builds or a
whole-zone/Warden playthrough. The optional LoopLink shortcut is not part of
this connected route; its isolated traversal remains in the expedition suite.
Bot physics time is not human 5–10-minute exploration timing. Manual visual
review and neutral-fauna avoidance still need playtesting. Next: Driftworks'
earned-build awakened return and connected Drowned Crossing acceptance.

## Full suite and earned-build Hollow return — 2026-09-25

**132/132 runnable smoke scripts pass in one complete sequential run.**
[Full report](../.tmp-smoke-suite-20260925-145423/results.json).
The runner checks explicit pass markers, exit codes and engine/script errors;
only the existing exact Windows certificate-store warning is exempted.
All scripts declare isolated temporary save paths; the player's save is not
used. The full run includes all six Hollow suites and all 19 Shaft suites,
along with Echo, Ash, Starfall, settlements, UI, progression and population.

New `hollow_earned_return_smoke.gd` connects two live-combat room stages:

- Base: starter sword, 5 maximum HP, 36 setup Gold buying two herbs; 22 live
  defeats, three herb uses and 4/5 HP remaining, 223.7 bot physics seconds.
- Earned preparation: 12 skill points and 315 Gold earned in this full-run
  base stage; two points spent through the UI on sword mastery/reach and
  36 earned Gold spent on two return herbs. Gold varies with ordinary loot.
- Awakened return: first-clear progress saved/reloaded, health preserved at
  4/5 HP; 23 defeats, one herb used, 3/5 HP remaining, 201.0 physics seconds.
  The new trial is completed and its reserve claimed. Carried/random herbs
  cannot raise the healing budget; the one new guaranteed cache herb can.
- Three actual interactions with already claimed first-clear caches produce
  no payout. A second save/reload preserves health, inventory, survey records,
  completed return encounter and all three cache claims without duplicates.

[Independent earned-return rerun](../.tmp-smoke-suite-20260925-145459/results.json)
also passes. An earlier persistence assertion compared integer/float Variant
storage rather than item quantities after JSON reload; the test now compares
every key and exact numeric quantity, without truncation or ignored items.
This was a test assertion issue, not lost inventory. No production terrain,
combat stats, player health or movement abilities were changed in this pass.

Limits: awakening is explicitly configured, not earned by a Warden fight.
Each stage has one initial entrance placement; shopping invokes real UI
handlers without physical merchant travel. Both stages otherwise use normal
movement/attacks with room actors and hazards live. These results do not
validate an entire campaign, every build, manual visual quality, mobile
performance or human 5–10-minute room pacing. The fresh tier-one starter-sword
5-HP diagnostic remains failed and is not counted as a passing smoke test.
Next: connected first-visit Driftworks and Drowned Crossing routes and their
saved awakened returns, plus hands-on visual/timing review.

## Ordinary-health Hollow route and rockfall placement — 2026-09-25

**24 distinct relevant smoke suites pass: 19 Shaft and five Hollow suites.**
The new base-room connected test now finishes at ordinary 5 HP; boosted-health
and failed fresh tier-one attempts remain separate from this passing count.
There are 131 runnable smoke scripts; the complete batch was not rerun.

The new hazard-placement audit first reproduced 12 failures: rockfalls
overlapped each other and stair takeoff/waiting spaces. All five full-sized
fields now occupy separate solid corridor runs with at least 48 pixels of
clear waiting space on each side. Loose-rock scenery follows them. No damage,
knockback, hitbox size, hazard count or phase duration was reduced. Base map
terrain, enemy stats and player movement/health are unchanged.

The fixed ordinary-health wrapper completes all seven galleries, five distinct
detours, relay, guarded high cache, three samples, actual lift return and camp
reward: **22 defeats, 4/5 HP remaining, three herbs used, 223.7 physics seconds**.
Setup provides 36 Gold to buy two herbs through the real shop. Only physically
acquired guaranteed cache herbs can extend the healing allowance; random drops
are logged/inventory-accounted but cannot increase that budget. The successful
run is therefore not dependent on lucky random healing. This is a specific
starter-build, finite-healing acceptance run, not a no-healing run, whole-zone
boss clear, visual review or a 5–10-minute human pacing measurement.

Test-driver fixes account for warning windows before walking across a hazard,
avoid auto-jumping onto a half-broken crate, and compare arrival height with
the requested gallery rather than incidental upper support. The older relay
test initially left a one-health far guardian behind after a dodged dive; it
now physically backtracks to finish that fight. The gate still requires both
original guardians, with no forced deaths or bypasses.

Reports:
[Shaft 19/19](../.tmp-smoke-suite-20260925-135439/results.json),
[four Hollow regressions](../.tmp-smoke-suite-20260925-134748/results.json),
[fixed normal-health run](../.tmp-smoke-suite-20260925-135430/results.json),
[pre-fix hazard audit](../.tmp-smoke-suite-20260925-134535/results.json).
Only the existing Windows certificate-store error is exempted.

The fresh tier-one starter/5-HP fixture still fails
([log](../.tmp-hollow-awakened-normal-01.log)); it does not model an earned
post-Warden build. Its explicit 100-HP diagnostic completes with 25 defeats,
84/100 HP and all return-trial rewards at 238.5 physics seconds
([diagnostic log](../.tmp-hollow-awakened-hazards-diagnostic-01.log)). Neither
result establishes awakened ordinary-health campaign balance. That and
hands-on visual/timing review remain open.

## Connected Hollow diagnostic completion — 2026-09-25

**Base and tier-one connected fixtures now pass with the explicit 100-HP
diagnostic allowance. Ordinary 5-HP acceptance still fails.** The pilot stays
outside the passing smoke glob and must not be counted as a balance success.

Latest clean diagnostic runs:

- [Base](../.tmp-hollow-base-final-02.log): 22 live defeats, 81/100 HP,
  no herbs consumed, 244.1 seconds of automated physics time.
- [Fresh tier one](../.tmp-hollow-awakened-final-01.log): 25 live defeats,
  78/100 HP, no herbs consumed, 255.1 seconds.

Both complete the relay, all seven galleries, five distinct side detours,
guarded high cache, three physical sample interactions, actual return lift
and the camp reserve. Tier one also clears/claims the awakened lower trial.
Actors and hazards remain live; sword hits, movement, drops and interactions
are real. Only the entrance placement and actual lift relocation are used.
Tier one is an explicit fresh setup, NOT a boss-cleared saved campaign.
Timing excludes human exploration/reading; neither result proves the desired
5–10-minute ordinary-room pacing. Health and timing can vary between repeats.

The [ordinary run](../.tmp-smoke-suite-20260925-132003/results.json) remains
failed: 11 defeats, both purchased herbs consumed, 0/5 HP at 95.6 seconds.
Do not read Godot's direct OS exit code as a pass. These are still test-driver
limitations/balance-review inputs, not proof that human survival is impossible.

Test-only fixes keep combat/rockfall steering on confirmed gallery support,
reject same-x arrival on a lower floor, handle ambushes appearing mid-jump,
walk off sentry support before fighting, settle stale floor contacts, use
normal drops after landing on an overlapping upper plank, and recognize an
already-reached step within the existing four-pixel landing tolerance.
No game stats, jump strength, population or map geometry changed.

Four relevant regression suites pass:
[three Hollow suites](../.tmp-smoke-suite-20260925-131339/results.json) and
[close-platform descent](../.tmp-smoke-suite-20260925-131745/results.json).
The complete 129-script batch was not rerun. Only the known Windows
certificate-store error is exempted. An earlier awakened diagnostic emitted
an ObjectDB exit-leak warning (`.tmp-hollow-awakened-trace-05.log`); a verbose
repeat and both final runs did not reproduce it. This is not a claimed leak
fix, and any recurrence needs investigation.

## Close-platform descent correction — 2026-09-25

**27 distinct relevant smoke suites pass:** 19 Shaft, three Hollow, three
jump-route suites, existing drop-through and new close-platform descent.
Only the known certificate-store warning was exempted. There are now 129
runnable smoke scripts; the complete 129-script batch was not run.

The new test first reproduced a lost second Down+Jump input while standing
on a closely spaced lower plank: the earlier exception's global cooldown
blocked another deliberate drop. Active exceptions are now excluded from
the feet query without blocking new supported drops. Collision is restored
after the player clears the platform's bounds, not while still overlapping
it. The new five-case test covers immediate/delayed drops, a stable lower
landing, return jumping, lateral exit and removal of the platform itself.
That last case also exposed a stale physics RID after a platform was freed;
cleanup now removes the stored RID even when its Node is gone. Solid/mixed/
compound-solid support refusal, one-drop-per-input, death cleanup and the
authored stair checks continue to pass.

Reports:
[close platforms](../.tmp-smoke-suite-20260925-001853/results.json),
[original descent](../.tmp-smoke-suite-20260925-002225/results.json),
[jump routes](../.tmp-smoke-suite-20260925-002302/results.json),
[Shaft](../.tmp-smoke-suite-20260925-001924/results.json),
[Hollow](../.tmp-smoke-suite-20260925-002125/results.json).

The connected combat pilot remains **unfinished**, outside the passing count.
Its latest ordinary run died after 11 defeats with both purchased herbs used
([failed pilot report](../.tmp-smoke-suite-20260925-002318/results.json)).
An explicit `--diagnostic-health` mode, using 100 HP only inside the test,
reached deeper: 15 defeats before losing the route around Niche4, with 84 HP
left. It still did not complete; see `.tmp-hollow-live-diagnostic-13.log`.
No full-room or awakened acceptance/pacing success is claimed. Enemy stats,
map geometry and ordinary player maximum health are unchanged.

## Earlier Wisp cover and connected-pilot follow-up — 2026-09-24

**24 distinct relevant smoke suites pass:** 19 Shaft suites, three Hollow
suites, Wisp cover and world population. Only the known certificate-store
warning was exempted. The unfinished live-combat pilot is reported separately
below and must not be included in this pass count.

The new cover test first reproduced 20 failed assertions across four base/
awakened wall/floor fixtures. After the AI correction, all four fixtures pass:
solid cover blocks acquisition and cancels windup, reacquisition gives a full
new warning, and an unobstructed dive still deals real damage. Two additional
scaffold/trigger fixtures verify that one-way planks and areas are not opaque.
Enemy stats and room geometry are unchanged.

The full live-combat Hollow pilot is **not passing**. Its latest attempt used
both purchased herbs and died after seven defeats. It is retained as
`hollow_live_route_pilot.gd`, outside the passing `*_smoke.gd` batch, with an
explicit command and limitations in `README.md`. Test steering still needs
work around fauna, overlapping ledges, knockback and hazards. This is neither
proof of impossible level geometry nor a completed balance/pacing review.
No connected awakened whole-room success is claimed.

The existing terrain-only complete loop still passes at 162.3 seconds of
automated physics time, with the same limitations as before. Three local
first/awakened encounters also pass at normal 5 HP and without healing.

Current local reports:
[Wisp cover](../.tmp-smoke-suite-20260924-235601/results.json),
[Hollow suites](../.tmp-smoke-suite-20260924-235637/results.json),
[Shaft regression](../.tmp-smoke-suite-20260924-235709/results.json),
[population](../.tmp-smoke-suite-20260924-235805/results.json).
There are now 128 runnable smoke scripts; the complete 128-script suite has
not been run. The separate unfinished combat pilot is not included in that
count. The older full-suite baseline below still predates these changes.

## Earlier Hollow exploration follow-up

**24 distinct relevant suites pass after this content increment.** There are
now 127 smoke scripts in the repository; the complete 127-script batch has
not been run. The 124-suite baseline below predates the ore survey.

- Three new Hollow suites: continuous terrain navigation and sample/return
  loop; survey interaction/save/reward integration; three isolated 5-HP
  starter-sword encounters without healing.
- Nineteen existing Shaft suites, plus UI flow and world population.
- The initial Shaft batch passed 18/19: its dressing test still expected
  three resident lines, while Hollow now has four. The assertion was updated
  to require the extra survey clue, and that complete suite passed on rerun.
- A new layout assertion initially caught the survey board overlapping the
  chest prompt. The prompt was moved and the full survey test passed.
- The 5-HP encounter suite was repeated after adding an explicit survival
  assertion to the shared combat harness; it passed again.
- Only the known certificate-store warning was exempted by the runner.

Local machine-readable results:
[new Hollow suites](../.tmp-smoke-suite-20260924-233319/results.json),
[Shaft batch](../.tmp-smoke-suite-20260924-233337/results.json),
[corrected dressing rerun](../.tmp-smoke-suite-20260924-233537/results.json),
[UI](../.tmp-smoke-suite-20260924-233356/results.json),
[population](../.tmp-smoke-suite-20260924-233419/results.json),
[normal-health rerun](../.tmp-smoke-suite-20260924-233437/results.json).
These ignored result folders are local artifacts, not committed fixtures.

The full navigation loop took 162.3 seconds of automated physics time with
combat/hazards disabled. That excludes reading, combat and human exploration.
The normal-health fights start fresh at each encounter and isolate unrelated
actors. Neither result establishes whole-room survival or the requested
5-10-minute first-visit pacing. Connected live-combat and hands-on visual/timed
playthroughs remain open; this does not mark all maps complete.

## Earlier full-suite baseline

**124 / 124 existing automated smoke suites passed.**

- Engine: Godot 4.6.2 stable, Windows, headless, fixed 60 FPS.
- Unique scripts executed: 124; failures/timeouts: 0.
- Sum of per-test process durations: 649.34 seconds (about 10 min 49 sec).
- Every test printed its success marker, exited with code 0, and had no
  script/engine errors except the known certificate-store warning below.
- Preview scripts and helper libraries were excluded from the runnable suite.

Coverage includes all four regions, settlements, population streaming and
restoration, doors, platforming, local combat, bosses, projectiles, equipment,
skills, consumables, shops, fast travel, quests, difficulty increases and
save/load/rollback contracts. This is the union of the existing tests, not a
claim that every possible gameplay sequence has been tested.

The per-test names, durations, exit codes and log paths are recorded in the
[full machine-readable report](../.tmp-smoke-suite-20260924-230220/results.json).
That ignored directory is a local test artifact, not a committed fixture.

## Test-harness changes and verification

22 older tests now assign their own temporary save path before any world/save
work. All 124 declare isolated workspace saves; none uses the player's
default save. No declared temporary save, backup or transaction file remained
after this run.

Added [run_smoke_suite.ps1](run_smoke_suite.ps1) with sequential processes,
per-test logs, explicit pass-marker/error checks, a timeout and JSON results.
The first full invocation completed all tests but returned an error in its
final PowerShell cleanup because its last process object was already disposed.
This was a runner defect, not a Godot test failure. The runner now clears its
process reference after disposal. The corrected version was verified with
one isolated test and a two-test weapon batch; both invocations ended cleanly
with exit code 0. The 124-test batch was not repeated after this cleanup-only
runner change.

No gameplay production code was changed during this full-suite pass.

## Remaining limitations

The existing Windows warning `Failed to read the root certificate store.`
appeared in the logs. Only that exact warning is exempted from failure.
No other engine/script errors or warnings were found in the full-run logs.

These are headless functional checks, including some isolated encounters with
explicit harness allowances. They do not establish visual polish, normal-health
balance for every complete room, 5–10-minute exploration pacing, phone
performance or resolution/device compatibility. Full first-clear and awakened
playthroughs remain necessary before declaring the map production-complete.
