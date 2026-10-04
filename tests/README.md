# Automated smoke tests

The 2026-10-04 ground-contact continuation is recorded in
`ground_dust_verification_v1.json`: 13 focused passes and 16 inspected final
native captures. `ground_dust_animation_smoke.gd` covers all 24 shared phases,
floor/slope registration, mirrored bounds, wall/overhang clearance, intervening
actors, finite 8/3 pools and the sub-4-MiB import budget. Existing contact tests
also check puff retirement on idle, warp, death, flight and noclip. The native
`preview_ground_dust.gd` uses real player walking and jump landings in four
regions. `resident_route_grounding_smoke.gd` independently samples 368 route
legs across 111 residents: 11,654 supported samples, no abrupt height changes.
This passing audit did not require NPC movement changes and is not a continuous
campaign or full-suite/performance sign-off.

The 2026-10-04 regional fauna continuation is recorded in
`ambient_fauna_verification_v1.json`: 12 focused passes and 12 inspected native
views. `ambient_fauna_smoke.gd` checks all 24 generated wing poses, registered
thorax pivots, source transparency, the sub-4-MiB mipmapped import budget,
scaled rooms, eased contact motion, both flight directions, quality toggles,
warps, culling, late walls and removed/restored habitat support. Its 39-room
audit retains 196 groups with unchanged native collision and stable reentry.
`ambient_contact_priority_smoke.gd` now combines grass, lamps, rotors and moths
inside the existing 18/8 animation cap. `preview_ambient_fauna.gd` walks the
actual player through four regional habitats and captures calm/startled/settled
phases. Combat simulation is frozen only in that preview. This is not a full
campaign, whole-suite pass or physical-device benchmark.

The 2026-10-04 reactive follow-through is recorded in
`reactive_followthrough_verification_v1.json`: 18 latest unique focused passes
and 12 inspected native 1280x720 captures. Across 39 rooms the corrected
foreground layer has 5,542 visible, supported tufts with no measured wall or
interaction-reservation overlap. Four-pose bounds, scaled roots, terrain
replacement, current-contact priority, upward root brushing and shared 18/8
animation plus 12/6 contact budgets have targeted regressions. Eight registered
opaque root tips feed 132 safely swept drip corridors. All 596 readables remain
available: 585 grounded generic pedestals, four cue-only fallbacks and seven
existing physical boards. First-visit registration is checked synchronously
after final terrain, not masked by a second finish call. The native preview
also verifies unlit/active/resting lamps with zero selected animation slots.
No new raster sources or gameplay colliders were added. These are focused
checks, not a full campaign, whole-suite run or physical-device benchmark.

The 2026-10-03 route-richness pass is recorded in
`route_richness_verification_v1.json`: nine focused passes, 12 inspected native
1280x720 views, eight original generated sheets and 48 registered cutouts.
All 39 rooms receive region-specific layered dressing: 6,329 visible ground
clusters (including 2,046 low walk-through foreground patches) and 3,667 hanging
and canopy details. Six selected solid vault pockets preserve native support
colliders and pass 30 real-controller jump/walk checks. The route test covers
actual alpha contacts, solid clearance, scaled rooms, late/disabled walls,
streamed wide devices, stable re-entry and the existing 8/18 wind budget.
The eight lossless 1024px mipmapped sheets use 26,079,712 decoded bytes.
`preview_route_richness.gd` renders the inspected route/settlement views;
`-- --vault-only` limits captures to the lowered-ceiling review.
This is route enrichment, not a claim that every older prototype prop is
finished, nor a full campaign or physical-phone performance benchmark.

The 2026-10-03 corridor/hoist clearance continuation is recorded in
`corridor_clearance_verification_v1.json`: 14 unique focused passes and eight
inspected native 1280x720 camera views. An independent failing-before audit
found 170 undersized placement footprints, 106 unrelated solid overlaps and
10 winch heads clipping platforms. The final 39-room audit retains 2,502
visible small ground clusters, 248 ceiling lips, seven clear interior crag
caps and all 40 complete hoists, with no such overlap or unsupported cluster.
`corridor_clearance_smoke.gd` covers actual sprite bounds, vertical walls,
late/disabled ceilings, scaled room roots, wide streamed device reservations,
one-way pillar guards and unchanged native ground. `hoist_clearance_smoke.gd`
covers attached cables/posts, uniform scale, art-only cache reflow, narrow side
walls, impossible synthetic headroom and one-pixel shared floor contact.
`preview_corridor_clearance.gd -- --final` captures the seven representative
rooms plus both Tide Well terminals with real native player collision.
Existing raster assets are reused without source pixel edits. This pass is
not whole-world visual completion, a full manual campaign or phone profiling.

The 2026-10-03 facade/route continuation is recorded in
`facade_route_verification_v1.json`: 43 latest unique focused passes, four
failing-before/fixed-after findings and nine inspected native camera views.
`facade_context_smoke.gd` checks all 91 windows own their facade, all 12 new
generated variants are used, 83 constrained wall details and 13 actual-floor
rear piers. The two imported sheets stay below 8 MiB including mipmaps.
`settlement_traversal_smoke.gd` now protects the exposed Cinder library descent
landings: 36 continuous basic-jump routes, 412 legs and six flat street walks.
`settlement_street_art_smoke.gd` includes the Haven outskirts, its twelve retired
bench-foot sketches, and grounded benches/stalls. Shared static canopy fitting
keeps five gate and ten street awnings clear of doors/windows/ceilings; two
cramped street sites retain compact open counters. `canopy_placement_smoke.gd`
adds scaled/translated and impossible-site/low-ceiling fixtures. The native
preview is `preview_facade_context.gd`; all players settle on real collision.
These checks do not imply whole-world visual completion, a full manual
campaign playthrough or physical-phone profiling.

The follow-up 2026-10-03 loot/ambient/safety pass is recorded in
`loot_ambient_safety_verification_v1.json`: 39 latest unique focused tests,
three failing-before/fixed-after fixtures and six native camera captures.
`pickup_geometry_smoke.gd` drives actual Area contacts across one-pixel cover,
retries after cover removal, and checks six shallow floor-overlap spawns.
`ambient_continuity_smoke.gd` checks that repeated camera selections preserve
retained grass/cloth/vine poses while retiring outgoing props exactly once;
the existing 18/8 animation budget stays unchanged.
`fall_recovery_threat_smoke.gd` rejects a cached safe point inside the actual
Warden torso and preserves health/checkpoint on fallback.
The older `combat_flipbook_smoke.gd` now checks registered opaque feet rather
than demanding the retired six-by-four runtime body grid; its 144 original
source-frame checks remain. No source-art pixels were rewritten in this pass.
`preview_ambient_continuity.gd` renders two real shared-tick samples each in
Training Passage, Echo Haven and Starfall Citadel. These captures and focused
tests are not an exhaustive campaign playthrough or a physical-phone benchmark.

The 2026-10-03 body/city continuation is recorded in
`body_city_repair_verification_v1.json`, including 19 focused results and native
camera evidence. `boss_body_hitbox_smoke.gd` checks 72 sword/arrow/magic impacts
at feet, torso and head across seven bosses plus Awakened Warden, proxy/native
deduplication, torso contact and unchanged navigation. `outer_boundary_collision_smoke.gd`
checks translated synthetic and actual Haven wall collisions above the old cap;
`city_walkway_occlusion_smoke.gd` checks all 91 windows and five supported awnings.
`projectile_sweep_smoke.gd` also puts a non-solid interaction Area before a thin
wall. `scenery_completion_smoke.gd` verifies retired waystone chevrons and retained
native scenery state. `preview_body_city_repairs.gd` renders 12 grounded camera
views; it is visual evidence, not a full campaign or phone benchmark.
The preceding compact-passage/civic guardhouse results are recorded separately
in `guardhouse_verification_v1.json`.

`encounter_streaming_smoke.gd` covers three authored biome ambushes and a gated
Echo return fixture: off-room/deferred guards, grace cancellation/expiry, actual
enemy node release, survivor HP/position, no defeated respawns, idempotent start /
completion, tier/bonus-health stability, Nest exclusion and projectile cleanup.
It drives the existing room activation/unload hooks, using an expired deadline
instead of sleeping through the grace period. No manual traversal or memory/FPS
benchmark is implied. See `ENCOUNTER_STREAMING.md` for the session-save boundary.

`story_lifecycle_smoke.gd` uses actual death signals, retry buttons and
`reload_current_scene`, not simulated node replacement. It checks saved reward/
scene rollback, corrupted-primary backup recovery, old audio-node release, new
no-save and Hardcore starts, mode switching, one-shot intro handoff, mute retention
and returning through the clean main menu. Only its isolated `_tmp_` save is
corrupted/deleted. Saved continuations never replay the opening.

`campaign_flow_smoke.gd` runs two event-driven campaign progressions, using native
boss deaths and world-progress APIs: early/late memories, queued interlude order,
staged/deferred claims, 820 Gold/5 SP campaign totals, finale-to-quest UI by button
and keyboard, three-size ending layout, replay backlog suppression, unsaved rollback
and final-save persistence. This does not traverse all rooms or simulate fair combat.
`preview_campaign_rewards.gd` captures epilogue states with 8/1/0 pending bundles
and the focused quest-log handoff at 960x540.

`story_pacing_smoke.gd` checks paused music duck/restore without restarting tracks,
crossfade coexistence, outgoing resource release, mute/unmute, rapid cancel/replay,
nested pause, contextual Guardian/memory narration snapshots and three-size layout.
`preview_story_pacing.gd` captures both contextual variants in the native renderer.
Campaign safety coverage also includes continuous quiet-window resets for new
threats, door transitions, dash and attack release.

`campaign_scenes_smoke.gd` checks ten 3-4-shot event sequences, native boss death
queues, Marshal full-arena gating, grounded/threat-free delayed playback,
main-quest milestone queues, native four-shot finale and return to the existing
epilogue, scrollable replay, catalog migration and death/new-game cleanup.
`preview_campaign_scenes.gd` captures all newly added sequences and library.

`story_scenes_smoke.gd` also checks gradual narration, paired images,
crossfade state, automatic completion, manual hold, reveal-before-advance,
skip/cancel cleanup and clean replay timelines. Timing is driven deterministically
through the same tick used by runtime processing; native previews include partial
text, a mid-crossfade and the completed shots.

`story_scenes_smoke.gd` checks the real new-game entry point, 31 illustrated
pages at three resolutions, stage gating, safe-rest offers, boss/menu safety,
skip/replay and pause ownership, no rewards, saved acknowledgment/rollback,
legacy migration and finale cleanup. `preview_story_scenes.gd` renders the original three
scenes, the journal actions and replay library. Assets/prompts: `art/story/README.md`.

`main_quest_smoke.gd` covers all 256 stage-order combinations, eight ordered
three-part bundles, native journal claims, reentry/duplicate rejection, side-task
independence, legacy receipt migration, unsaved rollback, new-game reset and
saved final rewards. It checks the claim UI at three resolutions and the final
mantle's equipped/unequipped effects without granting Dash. Native screenshots:
`preview_main_quest.gd`. Reward economy/manual campaign pacing remain unapproved.

`encounter_story_smoke.gd` verifies discovery-gated approach notes, six aftermath
cards and arrival subtitles at three resolutions, five native boss deaths,
rematch/duplicate suppression, arena completion, warning priority, mixed memory
queues, save/load and finale cleanup. `ash_arena_smoke.gd` also checks that the
Marshal's story waits for the actual four-wave completion. Native screenshots
come from `preview_encounter_story.gd` (Castellan arena, warning, aftermath,
Marshal card and journal). The HUD no longer overflows after Castellan victory.

`story_route_smoke.gd` checks 40 Echo/Ash gate combinations against guidance,
native Sanctum/throne requirements, missing-memory return instructions, four
precompleted tasks and three completed contacts before/after the finale.
It exercises real accept/claim buttons, one-time payouts and dialogue bounds
at three resolutions. `preview_story_route.gd` captures the early survey,
Marshal handoff, Eldric homecoming and contextual Ash journal.

`field_records_smoke.gd` opens eight actual cache instances, checks unchanged
seals/rewards, visible record cues, spoiler-safe journal/pair gating, native
memory/document queue coexistence, four resident replies and save/load rollback.
It also checks all eight excerpt cards at three resolutions. Documents from
previously opened caches restore without new payouts or discovery replay.
`preview_field_records.gd` captures the cache, discovery, journal and Ivara reply.

`world_story_smoke.gd` exercises twelve resident identities, 255 native dialogue
presentations at three resolutions, five live mission reactions, collected-memory
gates, combined outcomes, discovery/victory journal filtering, rematch stability,
new-game/save rollback and ending pause/continue. `preview_world_story.gd`
renders Neris, Atley, the homecoming and both ends of the ending scroll.

`boss_music_smoke.gd` checks seven distinct imported CC0 loops, native boss
signals, mute/unmute, player-death cancellation, defeat/finale, room exits and
release of outgoing streams. `ash_arena_smoke.gd` also checks Marshal music in
the actual fourth wave. See [music sources and license](../audio/music/CREDITS.md).

`quest_narrative_smoke.gd` checks all four states for six mission arcs in three
viewports, contact/action identity, portrait fallback, text bounds, resolved
journal entries and no save/reward mutation. `preview_quest_narrative.gd` renders
native dialogue and scrollable journal captures. This does not replace a full
playthrough or an in-game audio listening pass.

`player_projectile_flight_smoke.gd` covers 72 variant/FPS/direction cases,
the live 1-2-3-2 atlas sequence, independent spell palettes, compact head bounds,
world aim, hidden reset and unchanged projectile combat state.
`preview_projectiles.gd` captures two flight cells plus the real Echo Grotto.
[Details and captures](../art/characters/PLAYER_FLIGHT_FLIPBOOKS.md).

`player_projectile_lifecycle_smoke.gd` covers 50 room/rest/transition/hidden/
expiry cases with and without reserved damage, five projectile variants,
normal and piercing continuation, hidden/transition spawns, paused rest,
world-facing and signal cleanup. Appearance tests now reject revival after
hidden-room retirement.
[Details](../art/characters/PLAYER_PROJECTILE_LIFECYCLE.md).

`player_impact_flipbook_smoke.gd` checks 144 painted contact combinations,
breakup frames, wall-side bounds, transformed placement, 30/60/120 FPS,
expiry, hidden suppression and the existing player-impact budget.
`preview_projectile_impacts.gd` now captures both early and late breakup.
[Details and captures](../art/characters/PLAYER_IMPACT_FLIPBOOKS.md).

`mob_charge_cue_smoke.gd` covers two sentry families/two tiers at 30/60/120
FPS, native countdown and release/cancel precedence, hidden/missing-projectile
cleanup, unchanged fan counts/geometry and four ranged aim directions.
`sentry_cover_smoke.gd` also asserts painted cues disappear behind real cover.
`preview_mob_charge.gd` renders early/late preparation and native release.
[Details and capture](../art/characters/MOB_CHARGE_PRESENTATION.md).

`mob_attack_followthrough_smoke.gd` checks five mob families at 30/60/120 FPS,
native attack/recovery precedence, trail lifetime/facing, hidden cleanup and
twelve native directional muzzle launches in a rotated parent.
`preview_mob_followthrough.gd` compares active, breakup and particle stages.
[Details and capture](../art/characters/MOB_ATTACK_FOLLOWTHROUGH.md).

`mob_defeat_echo_smoke.gd` checks 20 native ordinary-mob deaths, immediate
single XP/gold drops, transformed pose snapshots, feet/flying lift, heated
palette, hidden appearance resets, neutral exclusion, cleanup and budgets.
`preview_mob_defeat.gd` renders all ten types at five deterministic stages.
[Details and captures](../art/characters/MOB_DEFEAT_PRESENTATION.md).

`boss_defeat_echo_smoke.gd` verifies all seven native defeats, immediate
gameplay cleanup, isolated dissolve materials, transformed-room registration,
pause/hidden/rest/room/transition cleanup, signal receiver disposal and the
shared 64-effect budget. `preview_boss_defeat.gd` captures actual arena defeat
callbacks at four deterministic dissolve stages.
[Details and captures](../art/characters/BOSS_DEFEAT_PRESENTATION.md).

`enemy_projectile_contact_smoke.gd` checks 40 material/direction contacts and
14 boss muzzle directions, hostile single-hit reservation, terrain-first
ordering, transformed parents, 4 real overlapping-target collisions, expiry,
transition/rest/room/hidden cleanup and suppressed transition spawns.
`preview_enemy_contacts.gd` renders flight, breakup and final particles for
ten materials in four directions. [Details and review](../art/characters/ENEMY_PROJECTILE_CONTACTS.md).

`boss_transition_readability_smoke.gd` checks seven bosses/minibosses for
opaque fast gait at 30/60/120 FPS, immediate charge frame, recovery facing,
monotonic preparation, and immediate hidden-room/marker cleanup even while
processing is disabled. `preview_marshal_transitions.gd` captures real Marshal
physics in Ash Arena with a scripted player crossover at native camera zoom.
[Review and limits](../art/characters/BOSS_TRANSITION_READABILITY.md).

`combat_readability_smoke.gd` checks compact gait at 30/60/120 FPS, non-stun hit
flash and stagger precedence, sentry hit feedback, forward-only native windups,
grounded root strike art with unchanged hitboxes, active/recovery separation,
room visibility resets and the 64-effect saturation/expiry budget.
`preview_combat_readability.gd` captures four staged overlapping-attack phases
in the real Echo Grotto at the standard 960x540 viewport / 2.5 zoom. These are
visual checks, not complete manual fight recordings.

`combat_flipbook_smoke.gd` checks 144 genuine frame cells, mipmaps, 30/60/120fps
selection, no breakup on live projectiles, compact mob body states/feet/palette,
hidden-room reset, untouched neutral art and effect expiry.
`preview_combat_flipbooks.gd` renders six actual Godot stages;
`assemble_combat_review.py` packages them as an animated review.
`prepare_combat_flipbooks.py` registers source RGBA frames without synthesizing
in-betweens. [Production assets and prompts](../art/characters/COMBAT_FLIPBOOKS.md).

`enemy_attack_art_smoke.gd` checks 20 unique alpha attack cells, mipmaps, grounded
bounds, contact archetypes, crystal/fire sentry fan variants, unchanged hitboxes,
passive neutrality, visibility reset, cosmetic budget and expiry.
`preview_enemy_attack_art.gd` renders the actual presenters for material review.
`prepare_attack_atlas.py` pads generated RGBA sources without replacing alpha.

`boss_frame_sequence_smoke.gd` verifies seven active twelve-frame atlases:
84 distinct nonempty transparent frames, all six locomotion poses, timed
anticipation, same-tick strike, follow-through/recovery, reset and unchanged
gameplay data. `preview_boss_extended_frames.gd` renders all twelve stages.
`prepare_boss_frames.py` is the user-approved offline source-matte/registration
tool (Pillow), not an image-generation API client.
[Sources and processing notes](../art/characters/BOSS_TWELVE_FRAME_ANIMATIONS.md).

`sentinel_combat_flow_smoke.gd` checks the first boss's actual arena physics:
acceleration, braking, planted telegraph, committed aim when crossed, recovery,
turning, phase-two fan, cancellation, boundaries, and 30/120 Hz acceleration.
`preview_sentinel_flow.gd` captures a scripted approach/cast/dodge/turn sequence.
`boss_motion_smoke.gd` also checks render frames between physics ticks do not
flash idle. [Behavior and limitations](../art/characters/SENTINEL_COMBAT_FLOW.md).

`boss_motion_smoke.gd` checks distance-driven walking at 30/120 FPS, blocked
movement, teleport filtering, pose transitions, charge priority, recoil,
timer-driven hazard progress and 37 bounded arena material surfaces.
`preview_boss_motion.gd` steps the actual Warden state machine at 60 Hz and
captures eight warning/charge/recovery samples with collision spaces retained.

`boss_combat_presentation_smoke.gd` checks seven bosses/minibosses: committed
charge facing, key-pose recovery, mirrored registration, release effects,
projectile art, bounded trails, effect cleanup, rematch consent/aura and seven
persistent arena landmark pairs. Use `preview_boss_combat.gd` for in-world GPU
warning/release/aura captures, and `preview_boss_appearances.gd` for the gallery.
[Scope and asset provenance](../art/characters/BOSS_COMBAT_POLISH.md).

boss_appearance_smoke.gd covers all six main boss sheets, clear-alpha cells, mipmaps,
hidden legacy body art and retained collision/warning nodes. The focused regression
set also includes Ash combat, boss-lamp reveal and Starfall arena art checks; see
[the 2026-09-28 report](LATEST_SMOKE_RESULTS.md#six-painted-bosses-2026-09-28).

echo_guide_appearance_smoke.gd now covers ten generated guide sheets (40 poses)
and checks that Leth's Echo Grotto art attaches on room entry. Focused verification
passed on 2026-09-28. [Asset provenance and exact prompts](../art/characters/ECHO_ADDITIONAL_GUIDES.md).

The waterworks extension of `echo_guide_appearance_smoke.gd` covers six guides
(24 poses), including Rill/Taren/Odel and their actual floor/name/prompt clearance.
`echo_device_art_smoke.gd` now validates paintings for all 18 dressed devices and
checks six valve/anchor/drain instruction bands against real terrain.
`echo_field_operations_smoke.gd` also checks device-art activation on partial/full
completion, unsaved rollback and completed reload. Run with crossing/habitat/room
dressing, machinery, sign layout, traversal and remaining-navigation regressions.
`preview_echo_waterworks.gd` produces twelve isolated-save GPU views.
[Waterworks assets and prompts](../art/characters/ECHO_WATERWORKS_BATCH.md).

`echo_guide_appearance_smoke.gd` checks three scoped field guides: four poses,
stepped native patrol/talk/attention in both directions, unchanged interaction,
alpha/mipmaps, true floor contact, label/terrain separation, lazy spawn, reentry,
inactive processing and Nest duplicate-awning retirement. `echo_device_art_smoke.gd`
also checks twelve painted instruments' uniform scale/alpha, grounded resonators,
native activation/listening/reset and all eighteen devices' unchanged reach.
Run alongside room/habitat dressing, field discoveries/operations, painted props,
prop clearance, field sign layout and Grotto regressions. `preview_echo_guides.gd`
captures nine GPU views with an isolated save.
[Assets and exact prompts](../art/characters/ECHO_GUIDES_AND_DEVICES.md).

`echo_fauna_appearance_smoke.gd` covers five species families in ten live neutral
cycles: rest/movement/provocation, hit/grace, both directions, scope exclusion,
alpha/gutters/mipmaps, unchanged shapes/rewards and actual unload/recreation.
It visits ten Echo locations, counts 49 actors and checks first-route fauna
portal clearance and full patrol floor support. `echo_entry_growth_smoke.gd`
checks ten grounded clusters replacing 50 triangles in five entry courts,
uniform scale, platform clearance, idempotence and unchanged gameplay geometry.
`preview_echo_fauna.gd` captures twelve GPU views with an isolated save.
[Assets and prompts](../art/characters/ECHO_FAUNA_BATCH.md).

`shade_appearance_smoke.gd` exercises four live EchoShade cycles (both facings,
both tiers), including upgraded followup, complete native warning timing, pose
selection, damage interruption/flash restoration, hidden/teleport handling,
disabled processing, collision/reward invariants and alpha/mipmaps. Run with
zone upgrade, Echo Sanctum, Gallery/Archive route, habitat and Ash/Star identity
regressions. `preview_shade.gd` captures six poses and three in-room views using
an isolated save. [Source and prompt](../art/characters/ECHO_SHADE_ART.md).

`echo_organic_scenery_smoke.gd` checks generated mushroom/mineral alpha and
mipmaps, uniform proportions, support on actual collision floors, obstacle and
cluster clearance, mask/UV clipping, idempotence, static processing and unchanged
physics/shortcut state across eight Echo routes. Run alongside scenery art,
traversal, room identity, painted props and grazer appearance. The latter now
also excludes non-grazer Echo species. GPU fixture: `preview_echo_scenery.gd`.
[Assets and exact generation prompts](../art/visual_slice/ECHO_ORGANIC_SCENERY.md).

`echo_grazer_appearance_smoke.gd` covers live rest/wander/provocation in both
directions, six poses, grace-window feedback, collision/reward invariants,
scope exclusion, alpha/mipmaps and actual room unload/recreation with retained
hostility and damage. Run with neutral-creature, habitat, Echo-room, crossing
and route-field dressing regressions. `preview_echo_grazer.gd` captures the
pose sheet and three in-room sleeping/provoked views with an isolated save.
[Source and generation prompt](../art/characters/ECHO_GRAZER_ART.md).

`broodling_appearance_smoke.gd` runs four live Echo Broodling AI cycles across
both facing directions and tiers, checking six poses, full native windup,
actual-travel stride, native hit feedback, hidden/teleport handling, unchanged
body/contact shapes and rewards, alpha and mipmaps. Run with Echo Nest, habitat,
field operations and zone upgrade regressions. `preview_broodling.gd` captures
the pose sheet, nursery and staged warning on the GPU with an isolated save.
See [asset provenance and prompt](../art/characters/ECHO_BROODLING_ART.md).

`echo_nest_art_smoke.gd` checks two nursery sites and twelve closed/spent sprite
variants, true alpha/mipmaps, idempotence, leaf-only retirement, floor anchoring,
uniform scale, platform clearance, independent native state visibility and room
re-entry. Run with habitat dressing (actual kills, streaming and save/reload),
field operations, field-sign layout, painted props and machinery regressions.
`preview_echo_nest_art.gd` captures both sites occupied and cleared on the GPU,
using an isolated save. [Asset provenance and prompts](../art/visual_slice/ECHO_NEST_ART.md).

`background_quality_smoke.gd` covers the user-reported entry occlusion,
market-only city background and excessive texture downsampling. It checks
33 profiles, deep generated terrain (Stone as well as Visual), native 1536px
imports, explicit hidden background leaves, pressure cells and ground-district
facades. `preview_background_quality.gd` captures eight entry/join/equipment/
city views with the normal D3D12 Mobile renderer. Run together with both
painted-room tests, visual slice, city materials/upper structure, Cistern
puzzle/hazards, Shaft/Echo identity, Ash switchback and shared shader consumers.

`remaining_room_art_smoke.gd` verifies 24 distinct imported images on 342
background masks, unchanged original physics/transforms/silhouettes,
explicit leaf-decoration retirement, shared UVs, mipmaps/1024px limits,
two-axis parallax, hidden-room sleep and idempotence. Run it with the existing
room/Ramparts/Driftworks art, Shaft infrastructure/identity, Echo traversal/
identity/sanctum, Ash switchback/arena/Castellan, settlement backdrop/expansion,
upper-city art and training decor regressions. `preview_remaining_room_art.gd`
captures 48 close/wide GPU views with the project's D3D12 Mobile renderer;
`preview_remaining_contact.gd` assembles local QA sheets (not exported assets).

`driftworks_painted_art_smoke.gd` checks 24 continuous mine backplates, 73 iron
surfaces, four alpha-grounded ore carts, unchanged original geometry/physics,
scoped prototype retirement, import budgets, parallax, hidden sleep, idempotence
and Shaft-only opt-in. `preview_driftworks_art.gd` captures five GPU views.
Run with the shared Ramparts art regression and Driftworks live normal/earned
return, Shaft infrastructure, expedition dressing/jumps/layout/population tests.

`rampart_painted_art_smoke.gd` checks 24 continuous painted chamber/link masks,
105 horizontal surfaces, grounded alpha props, original transforms/geometry/
physics, leaf-only retirement, parallax zoom/origin safety, hidden sleep,
idempotence and Starfall-only opt-in. `preview_rampart_art.gd` captures five
real-world views. Run with expedition jump/population/layout and rampart-task
regressions; the art does not authorize changing gameplay to fit the pictures.

`starfall_arena_art_smoke.gd` checks Empty Court / Hollow Throne paintings,
sixteen stone surfaces, two foundations, grounded alpha throne, original
geometry/collision/one-way state, scoped leaf retirement, texture budgets,
parallax at two zooms, translated room origins, hidden sleep and idempotence.
`preview_starfall_arena_art.gd` captures six GPU views including real attack
warnings. Run alongside Court, Hollow Throne, boss-lamp and navigation tests.

`room_painted_depth_smoke.gd` checks nine rooms / 135 painted surfaces, unchanged
collision and original geometry/visibility/transforms, shared continuous UVs,
1024px mipmapped imports, two parallax rates, camera zoom/room-origin handling,
hidden-room sleep, nine distinct textures, Starfall image scale and idempotence.
`preview_room_painted_depth.gd` captures 19 GPU views: close/wide for each room
and a camera-shifted Cistern view.

`starfall_upper_structure_smoke.gd` verifies 84 collision-aligned upper-city
surfaces, four skyline towers/136 windows, scoped visual replacements,
unchanged geometry/physics/transforms, static rendering and hidden-room sleep.
The upper-city preview now includes bridge and skyline views (six total).

`starfall_upper_art_smoke.gd` checks upper-city 2D detail coverage, leaf-only
replacement, unchanged transforms/geometry/physics, static rendering and
idempotence. `preview_starfall_upper_art.gd` captures four GPU views (artisans,
gardens, bells, crown). Run alongside `starfall_upper_city_smoke.gd`,
`starfall_field_office_smoke.gd` and the `town*_smoke.gd` regressions.

Run all `*_smoke.gd` scripts sequentially from PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_smoke_suite.ps1
```

Override the engine path or select a subset when needed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_smoke_suite.ps1 -Godot "C:\path\Godot.exe" -Filter "shaft_*_smoke.gd"
```

The runner uses headless Godot at fixed 60 FPS. Each test gets a separate
process and logs under a new `.tmp-smoke-suite-<timestamp>` directory.
`results.json` records each result, elapsed time, exit code, errors and log
location. Logs are retained for diagnosis.

Success requires an explicit `TEST PASSED` marker, exit code zero, and no
script/engine errors. The exact Windows certificate-store warning currently
seen on this machine is recorded in the logs but excluded from test failure.
Other errors are not silently ignored, even if the script prints a pass.
An unhandled script error ends that child process; the default wall-clock
timeout is 90 seconds per test (`-TimeoutSeconds` can override it).

Every runnable test must declare an isolated `res://_tmp_*.json` save path
before starting a game, opening the world or touching save state. Never run
a new test against the default `user://savegame.json`. The runner checks for
an explicit temporary path, but code review is still necessary to ensure
the assignment happens before any save operation. Tests with failed setup
may leave their temporary saves for investigation.

Finish editor imports before launching the suite. An import can rebuild the
shared global-class cache while a headless test starts, temporarily producing
missing-type errors (for example Player) unrelated to that test's changes.
Keep the failed log, finish import, then rerun; never count that run as PASS.

The two `preview_*.gd` scripts and helper libraries are not smoke suites and
are deliberately excluded. Passing these tests does not establish visual
quality, whole-game balance, phone performance or 5–10-minute room pacing.
Several encounter tests isolate enemies or grant extra health; consult each
test's comments before interpreting its result as a gameplay acceptance run.

## Connected Hollow combat and diagnostic modes

`hollow_live_normal_smoke.gd` now verifies the complete base-room route with
normal 5 HP and the starter sword. It cannot be switched to boosted health
by diagnostic command-line flags. Run it separately or in the full smoke batch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_smoke_suite.ps1 -Filter "hollow_live_normal_smoke.gd"
```

It keeps all actors/hazards active and supplies 36 setup Gold to purchase
two herbs. Acquired guaranteed cache herbs may extend the healing budget;
random drops are recorded but cannot increase that budget. This is not a
no-healing run. It completes the relay, side routes/cache, three ore samples,
real lift and camp reward in one continuous run. No enemy damage is injected
and there is no mid-route placement other than the actual lift transition.
Pilot steering now keeps corridor combat on confirmed ledges, handles
mid-jump ambushes and actor-supported landings, and returns from overlapping
upper planks using normal drops. The driver also accounts for warning windows
before crossing rockfalls and finishes breaking a crate before auto-jumping
onto it. The run validates this specific ordinary-health setup, not general
human-facing balance, all builds, an awakened campaign or 5-10-minute pacing.

`hollow_earned_return_smoke.gd` adds a second connected stage after that actual
base run. It spends two earned skill points through the UI on sword mastery
and reach, saves/reloads the first-clear progress and buys two return herbs
with earned Gold. Carried/random herbs cannot increase the return healing
budget. Health is preserved rather than refilled; the weapon remains the
starter sword and movement abilities are unchanged. First-clear caches are
revisited without payout; the new return trial is fought and claimed normally.
The completed return is saved/reloaded again to check health, inventory, survey
and claimed rewards. Both stages keep all room actors/hazards live.

Awakening is still an explicit tier-one fixture, NOT an earned Warden defeat.
Each stage begins with a single entrance placement. Shopping uses real UI
purchase handlers, not physical travel back to the merchant. This test covers
earned build/supplies and saved exploration state, not an entire campaign or
human pacing. Like the normal wrapper, diagnostic CLI flags cannot alter it.

`hollow_live_route_pilot.gd` remains the configurable diagnostic outside the
smoke glob. Its default uses the same base setup; fresh tier-one starter-sword
acceptance at 5 HP is still unfinished.

When invoking Godot directly, the optional trailing arguments
`-- --diagnostic-health` give this pilot alone 100 HP to investigate deeper
obstacles. Keep a unique workspace `--log-file`, fixed 60 FPS and the explicit
isolated save. Add `--awakened-fixture` to start a fresh tier-one setup and
also require the lower return trial and its reward. This does NOT defeat the
Warden or replay a saved first clear; campaign awakening/persistence has
separate integration coverage. `--trace-route` logs approaches and actual
side-route supports when investigating navigation.

Both 100-HP fixtures complete the relay, all seven galleries, five distinct
side detours, three samples, guarded cache, real lift and camp reward with
all actors/hazards live. A fresh tier-one 5-HP starter attempt still fails.
No boosted-health diagnostic pass is a normal-health balance result. Do not
interpret Godot's process exit code alone as a pass: inspect its explicit
verdict and engine/script errors. Latest logs/limits are in
[LATEST_SMOKE_RESULTS.md](LATEST_SMOKE_RESULTS.md).

## Connected Driftworks first visit

`driftworks_live_normal_smoke.gd` uses the expedition-specific graph through
`driftworks_live_route_pilot.gd`. It traverses eight main chambers and four
side branches, repairs both pumps, collects three caches, rides the actual
lift both ways and explicitly exits into Drowned Crossing. A final snapshot
reload checks health, supplies, mechanisms and one-time rewards.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_smoke_suite.ps1 -Filter "driftworks_live_normal_smoke.gd"
```

The setup fixes 5 HP, starter sword, no movement upgrades and two purchased
herbs for 36 setup Gold. Only guaranteed cache herbs increase the healing
allowance; random drops remain counted in inventory but cannot increase it.
All room actors/hazards are live. Passive fauna can be provoked by traversal
and their defeats are reported separately; this is not a pacifist test.
The first entrance placement and final persistence reload are explicit setup
operations; movement in between is continuous except for real lift travel.
This does not cover an awakened return, the optional LoopLink as a connected
route, human timing, visual quality or all builds. The shared jump driver now
steers across genuine gaps during ascent instead of waiting above a distant
solid lip; overlapping solid ledges retain their guarded ascent behavior.

`driftworks_earned_return_smoke.gd` extends that real base run with a saved
tier-one return. Two earned points buy sword mastery/reach; earned Gold buys
two return herbs. Base health and prior claims persist. It physically clears
the three-guardian engine trial and claims the new reserve, revisits old
caches without payout, then saves/reloads the completed return. Awakening is
explicit setup, not an earned Warden victory. There is no health refill,
injected XP or increased healing allowance from carried/random items.

## Connected Drowned Crossing

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_smoke_suite.ps1 -Filter "crossing_live_normal_smoke.gd"
```

This starts at the lower-Shaft entrance with starter sword/5 HP, no movement
upgrades and two herbs purchased with 36 setup Gold. It covers seven galleries,
five side detours, the valve, two caches, lift round trip and explicit travel
to Flooded Gallery. Currents remain live until the valve is physically reached
and activated. Completed progress and exact supplies persist through reload
without cache duplication. The driver is `crossing_live_route_pilot.gd`;
diagnostic CLI flags do not change this wrapper's ordinary-health setup.

Only acquired guaranteed cache herbs extend the healing budget. This is not
a continuous Driftworks-to-Crossing trip, an awakened return, a pacifist route,
visual review or human pacing measurement. Shared test steering hops crates
when a safe sword swing is blocked by passive fauna, and walks onto slightly
lower overlapping ledges instead of dropping through both platforms.

`crossing_earned_return_smoke.gd` extends the completed base run with a saved
tier-one return. Two earned skill points buy sword mastery/reach, and **54
earned Gold buys three herbs** through the merchant UI. The base finish's
health is preserved, with no refill or higher maximum HP. Only the new trial
cache's guaranteed herb can extend the three-herb healing allowance; carried
items and random drops cannot. It physically clears the two new sediment
wisps, claims their reserve, checks both old caches without a second payout,
rides the lift both ways, exits and reloads the completed progress. Awakening
itself remains an explicit fixture, not a Warden kill; shopping invokes the
real UI without walking to the merchant. Each stage has one entrance placement.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_smoke_suite.ps1 -Filter "crossing_earned_return_smoke.gd"
```

The shared live driver also uses ordinary available sword/healing input while
jumping. Its terrain-only parent retains an empty per-step input hook. When
a combat hop lands above a shallow walking step, navigation re-plans from
the actual support with a bounded retry rather than declaring arrival on the
wrong floor. Cache non-duplication is checked around the synchronous input:
loot collected during preceding settling frames is not a repeat cache reward.

## Connected earned-build Gallery and final Shaft rooms

`gallery_earned_arrival_smoke.gd` completes the actual base Crossing route,
buys sword mastery/reach with two earned points and two herbs with 36 earned
Gold, then enters Gallery through the real door. It keeps normal 5 maximum
HP, current health and basic movement. Gallery checks seven galleries, five
detours, both pressure circuits, both caches, the lift round trip, onward
exit and saved-state restoration. `gallery_earned_return_smoke.gd` adds the
saved tier-one Gallery return, three herbs purchased with 54 earned Gold,
both new inspection guardians, their reserve and old-cache non-duplication.

`cistern_earned_route_smoke.gd` extends the real Crossing/Gallery earnings
with base and saved awakened Cistern traversal. It physically operates all
three dials, revisits the memory niche after restoring the pump using the
real lift, takes all three base caches, clears the return trial and checks
the explicit onward exit and restored quantities/mechanisms. The optional
Cistern stage has one disclosed entrance placement, not a physically walked
Gallery-to-Cistern approach. The return also starts with one entry placement.
Two herbs are purchased for the first visit; three for the return.

All these runs retain live enemies, hazards, crates and fauna. They do not
inject damage, teleport between objectives, refill health or use random drops
to increase the healing allowance. Only purchased and actually acquired
guaranteed cache herbs extend that allowance. Awakening is explicit test
setup, not an earned boss victory. Shopping uses real UI handlers without
physical merchant travel. Return trials are distinct from the older optional
afterglow contract caches, which remain covered by separate integration tests.

`approach_earned_route_smoke.gd` uses the real Gallery exit for its base
arrival, then validates the saved awakened return: crank/bridge, both base
caches, new trial guardians/reserve, lift, exit and save restoration. It has
the same two-herb base/three-herb return preparation as Cistern, without a
health refill. Its return has one disclosed entrance placement.

The shared final-room driver is `shaft_final_rooms_pilot.gd`.
Consult [LATEST_SMOKE_RESULTS.md](LATEST_SMOKE_RESULTS.md)
for the exact current pass count and remaining failures. Advanced final-room
steering is opt-in: ledge rejoining after combat, bounded unreachable-foe
deferral, sidestepping overhead wildlife and low-pulse jump timing. None of
these disables actors or bypasses required kills.

`cistern_hazard_layout_smoke.gd` verifies that the three relocated full-size
pressure fields leave solid waiting pockets, do not cover stairs or each
other, retain their original damage/timing/force, and stop after pump repair.

### Standalone starter-sword Gallery diagnostic

`gallery_live_route_pilot.gd` is deliberately outside the smoke glob. It uses
5 HP, starter sword, no movement upgrades and two herbs purchased with 36
setup Gold, then attempts the connected galleries, five detours, two pressure
controls, caches and lift. The latest attempt reaches both controls, disables
the jets and defeats 16 enemies, but dies on the high-niche approach after
using both purchased herbs and the one already acquired guaranteed cache herb.
It does **not** establish whole-room traversal, onward exit or save acceptance.
No extra health or supplies have been added to turn this failure into a pass.
The earned-build wrappers above are a different, now-tested preparation;
their results do not turn this starter-sword attempt into an accepted run.

Per the user's 2026-09-25 direction, that extra starter-sword scenario is
not a development blocker and is not scheduled for further tuning now.

## Connected Echo exploration

`echo_grotto_earned_route_smoke.gd` uses actual Crossing earnings to buy
sword mastery/reach and three herbs, preserves ordinary 5-max-HP health,
then places the player once at the Echo entrance. It is not an earned
Warden defeat or a continuous campaign transition. All actors remain active;
the controller traverses both entry resonators, nine galleries/four branches,
three listening posts and the hidden offering, explicitly exits to Gallery
and checks the completed save without duplicate rewards. Random drops cannot
raise its finite healing allowance. The helper is `echo_grotto_live_pilot.gd`.
Human pacing and a complete inter-zone campaign remain separate coverage.

`echo_shaft_crossings_smoke.gd` isolates terrain and checks the upper plank's
reachable rims on BOTH sides and the bottom approach from the correct lower
chamber, using the real basic Player controller. It covers 60 shafts,
74 upper rims and 60 bottom approaches (134 hops) in all seven Echo rooms.
Unlike the connected Grotto suite, each jump has its own placement and actors are disabled; this
is not live-combat acceptance. It protects against offset top steps that
allow ascent onto one corridor rim but make the opposite rim unreachable.
Bottom coverage also protects against a neighbouring shaft removing the
expected lower takeoff floor. Three bottom planks now reach toward their
actual surviving lower floor with a 32-pixel gap; unrelated rooms are not
connected and collision remains one-way.

### Saved Echo return and Gallery / Archive follow-ups

`echo_grotto_return_route_smoke.gd` first earns and saves the complete Grotto
route above, explicitly sets the Echo tier to 1, then saves/reloads that tier.
This is a post-clear fixture, not a Matriarch fight. A single return-entrance
placement begins another connected nine-gallery/four-branch expedition.
The tier-six return trial is entered physically, its two guardians fight
normally and its reserve is collected. Reload checks completed guardians,
no respawn and refusal of both old and new duplicate rewards.

`echo_gallery_archive_route_smoke.gd` uses an actual Grotto door transition
into Gallery. The original platform climb collects the prism by overlap;
both witnesses, all nine galleries/four branches, the offering and onward
exit are visited physically. That first-time exit must lead to **Echo
Depths**. Depths itself is NOT traversed by this test: the Archive stage
starts with one explicitly placed entrance fixture and carries the actual
Gallery health, build, inventory and earnings. Archive visits Root, Star
and Echo mirrors through their normal interactions, then walks its nine
galleries. Its Zenith -> Dawn -> Dusk record order requires two links walked
backwards and forwards again and a fifth branch visit. The final shortcut
must lead to Grotto. Both room snapshots check exact HP, skills, currency,
inventory, completed records and one-time cache rewards.

Each follow-up buys three herbs for 54 genuinely earned Gold using actual
UI handlers. Merchant travel is not simulated. Maximum HP remains five;
no healing reset, movement upgrade, damage injection, disabled enemy or
intermediate objective teleport is allowed. Random herb drops do not raise
the budget; only the purchased herbs and actual guaranteed cache herbs do.
The shared helper is `echo_followup_live_pilot.gd`. Each smoke wrapper owns
its own temporary save and the inherited runner removes it on completion.

The Echo driver resolves floors by chamber identity (some chambers share
a height), visits the actual requested crossing plank after incidental
upper landings, and reverses unsafe outward landing momentum with a real
jump. Gallery/Archive use bounded corridor combat. A late patrolling guard
below an Archive listening post requires a physical descent and return.
These are test-controller changes, not easier production enemies/terrain.

### Remaining Echo connected navigation

`echo_remaining_navigation_smoke.gd` uses the actual basic controller for
Tide Well, Echo Nest, Crystal Causeway and Undertow Vault. One initial
placement per room is followed by continuous exploration: 40 chambers,
18 side branches (both shelf halves), the return-door approach and all
36 links in both directions. Left-facing branches reverse their physical
near/far shelf order, not their alphabetical node order.

Actors, interactions and hazards are disabled for terrain isolation. This
does not certify combat, original entry puzzles, door interactions or human
pacing. `echo_field_operations_smoke.gd` separately covers the four rooms
and Depths objectives, awakened trials, rewards and persistence using its
documented functional fixtures. Expedition jump coverage remains link-wise,
not a continuous Depths campaign run.

This route catches Tide Well's obsolete right wall crossing the enlarged
map, and Causeway's third branch mouth stranded across a shaft opening.
The wall now sits beyond the expanded route; branch entrance planks extend
toward their own surviving chamber floor only when the gap exceeds 70 px,
leaving 32 px and retaining one-way collision.

### 2D environment art sample

`visual_style_slice_smoke.gd` verifies the two integrated art scenes:
11 project-local painting plates, valid UVs, camera-driven displacement,
unchanged collider identities/transforms/one-way flags and inactive-room
animation sleep. It does not certify GPU performance or final art quality.
`preview_visual_style.gd` renders three isolated-save in-engine captures
with a graphics display driver, not headless. See
`art/visual_slice/README.md` for review locations, exact generation prompts,
source assets and the disclosed editor/import limitations.

`resident_motion_smoke.gd` checks movement-derived facing/stride, stationary
settling, hidden/indoor sleep and teleport rejection, plus actor/collider/UI
invariants. Existing ambient-life tests still verify actual town routes,
interiors and conversations.

`starfall_schematic_portals_smoke.gd` forces the production lightweight
preview branch through a test-only subclass. Separate parents preserve
authored room names. Across six rooms, 15 doors/15 arrivals and 126 supported
anchor samples must equal full live geometry. It also verifies that the
preview branch was actually used, without live overlooks. The shared floor
foundation extraction preserves the original live construction order.

Smoke-run output folders include milliseconds and a short GUID to avoid
collisions when consecutive small tests start within the same second.

### Character art pilot

`character_appearance_smoke.gd` checks the integrated Player/ShaftWisp atlas
presenters: all poses/facing, real grounded idle/walk/crouch/jump, dash state,
real sword attack and unchanged cooldown, damage/recoil, death/respawn,
safe-rest exclusion, enemy AI-state mapping, dive alignment, awakened color,
alpha padding, hidden sleep and unchanged body/melee/contact shapes.
It does not certify polished animation, all weapon-specific poses or mobile
performance. `preview_characters.gd` creates an enlarged pose gallery and a
staged normal-zoom Grotto capture with the graphics renderer and an isolated
save; see `art/characters/README.md` for provenance and exact prompts.

`crawler_appearance_smoke.gd` exercises four real AI loops (both directions,
normal/awakened): complete 0.52s warnings, awakened repeat charge, movement-
driven stride, high-refresh inter-tick pose retention, health-flash signals,
HUD separation, hidden/teleport rejection, alpha and collision invariants.
Its noncolliding stationary target deliberately isolates the AI/presentation
loop; real contact and weapon damage remain in the existing combat tests.
`preview_crawler.gd` renders both-facing pose review and staged gameplay-zoom
Grotto screenshots. See `art/characters/CRAWLER.md` for limitations/provenance.

`ranged_attack_cue_smoke.gd` drives the real RangedEnemy process at fixed
steps and checks three original-cadence launches per case (left/right,
level/elevated targets), projectile spawn/aim/stats and real physics contact
damage. It also checks warning cancellation for range/dead target, missing
projectile rejection, original hit flash, hidden reset and collider/muzzle
invariants. It also checks all four bitmap poses, both facings, atlas alpha
and visibility reset when the enclosing room has processing disabled.
`preview_ranged_cues.gd` captures the new stone-sentinel pose gallery and
staged gameplay art/cues with an isolated save. The original placeholder is
hidden, not removed from existing gameplay references.

`player_movement_art_smoke.gd` uses real floor/wall physics and input to
verify distance-driven walk, blocked idle, reverse facing, grounded crouch,
buffered jump/fall/landing, real dash and attack priority over compression.
It checks inter-physics render retention, teleport and disabled/hidden reset,
all ten poses across two atlases, interior alpha samples and unchanged body/
melee resources. `preview_player_movement.gd` renders both-facing comparisons
and a staged normal-zoom Grotto capture. Both scripts use isolated saves.

`player_attack_art_smoke.gd` exercises six weapon IDs, both horizontal
facings and up/down diagonal ranged shots with real melee/projectile
contact. It verifies successful-attack event/pose agreement, two visual
phases, unchanged timers/body/reach, cooldown/mana/missing-resource failures,
direct equip cancellation without cooldown reset, hurt/hidden/respawn cleanup
and atlas alpha. `preview_player_attack.gd` renders a pose gallery plus
three staged in-room attacks; both scripts use isolated saves.
The ranged cue smoke additionally covers a freed cached player target.

`weapon_appearance_smoke.gd` verifies native weapon registration for six
item IDs, both facings/phases and crouch, using fixed measured hand positions.
It checks actual aim, committed facing, unchanged melee/body/cooldown,
duplicate-prototype suppression, timeout and disabled-hidden resets.
`preview_player_attack.gd` now captures `preview_player_weapon_*`, including
a wider enlarged registration gallery and three staged successful attacks.

`projectile_appearance_smoke.gd` checks six native projectile variants in
six directions, palette, trajectory, lifetime/range, damage, piercing,
collision/transform invariants and disabled-hidden/stopped/deletion cleanup.
`preview_projectiles.gd` renders an enlarged/normal-zoom comparison and
frozen shots in Grotto; both scripts use isolated saves. Existing actual-hit
tests remain authoritative for contact and overlapping-target hit budgets.

`projectile_impact_smoke.gd` covers 36 direct contacts, seven real physics
shots (including saturated visual budget), no duplicate/source effects,
unchanged damage, cap, transformed parents, lifetime, pause, rest/room-change,
hidden/deleted-parent cleanup and transition suppression. The companion
`preview_projectile_impacts.gd` captures enlarged and normal-zoom frozen
contact effects; both use isolated saves.

`melee_impact_smoke.gd` uses the actual player ShapeCast for 48 combinations
of swords/facings/crouch/reach/target groups. It verifies multi-collider dedup,
damage/knockback/collision invariants, cooldown rejection, large target clamp,
immunity, queued target deletion, ignored objects, empty swings and damage
under visual-budget saturation. `preview_melee_impacts.gd` captures phases
and two staged actual in-room hits, including a left-facing crouched hit.

`player_damage_feedback_smoke.gd` checks post-defense damage events,
three knockback cases, rejected/heal/rest inputs, unchanged combat timers,
equal-HP Second Breath, shared-budget saturation, pause and lifecycle cleanup,
real enemy projectile contact, death/respawn and unchanged collision.
`preview_player_damage.gd` stages both-facing hurt and gold rescue feedback
at normal zoom. Both scripts use isolated temporary saves.

`player_gait_transition_smoke.gd` checks real direction reversal/restart,
walking exclusion during attack/recoil/crouch/airborne states, short room/rest/
transition relocations, hidden reset and collision invariants. Existing art
is retained. `inspect_walk_sheet.gd` is a read-only image alpha/bounds helper;
run it with a project-local --log-file and a PNG path after --. Four-frame
test/preview drafts live as .gd.txt in art/characters/drafts and are NOT
active scripts or passing acceptance tests; the generated art lacked alpha.

`resident_conversation_smoke.gd` verifies reciprocal conversation acceptance,
busy/hidden/self rejection, speaker turns, stationary partner/player facing,
player-priority interior pause, dead/hidden/freed/queued actors, room hiding,
stale partner isolation, route continuation and unchanged collision/UI.
`preview_resident_conversation.gd` stages opening/reply captures at Echo Haven's
existing meeting markers. Both use isolated temporary saves. The preview
also documents existing market crowding/nameplate overlap as pending work.

`npc_portrait_smoke.gd` checks Neris/Orin asset identity, 256px imports, missing
portrait fallback, all Neris lines, shop/forge headers, close/reset, focus,
collider invariants and panel bounds at 960x540, 1280x720 and 1920x1080. Every
shop item description is inspected, with long text scrolled to the bottom;
the clipped description area must stay separate from the purchase button.
`preview_npc_portraits.gd` captures the dialogue, shop, scrolled details and
forge at 960x540. Both scripts use isolated temporary saves. Viewport checks
are not physical mobile-device testing or a full UI-resolution redesign.

`quest_portrait_smoke.gd` covers all 14 Eldric/Lyra dialogue states at three
viewport sizes, portrait identity/import budgets, text/action separation,
fallback and close cleanup. It also drives the connected action button and
normal quest APIs for acceptance, completion, rewards and duplicate survey
reward rejection. `preview_quest_portraits.gd` captures Eldric's trial offer
and Lyra's survey hand-in at 960x540. Both use isolated temporary saves.

`settlement_portrait_smoke.gd` checks eight unique scene assignments and 256px
imports across three viewports. It covers every Mira/Tarin quest state, Ivara's
authored lines, five service/forge headers, fallback and close/pause cleanup.
`settlement_backdrop_smoke.gd` checks two textures across fourteen existing
polygons, continuous district UV bounds, geometry/collider invariants,
idempotence, camera response and hidden-room sleep. `preview_settlement_art.gd`
captures all eight actual UI panels and both expanded-town backgrounds at
960x540. All use isolated saves; screenshots are staged, not a full playthrough.

`settlement_building_art_smoke.gd` checks 98 painted surfaces and 59 window
frames, six 512px mipmapped textures, unchanged original polygons/colliders/
route markers, no art colliders or per-frame processing, and idempotent build.
`preview_settlement_buildings.gd` stages four 960x540 views of original and
expanded quarters in Echo Haven and Cinder Hearth. Both use isolated saves.

`settlement_street_art_smoke.gd` checks 141 decorative replacements, exact
bench/stall/barrel/cart/wheel/flora coverage and Moon Forge's smithing display.
It snapshots original nodes, polygon geometry and physics at non-zero room
origins; only selected leaf decorations may become hidden. It also verifies
unchanged node count apart from the static renderer, idempotent build, no
per-frame processing and inactive-room visibility. `preview_settlement_street_art.gd`
captures four staged 960x540 close-ups. Both use isolated temporary saves.

`town_nameplate_layout_smoke.gd` stages a crowd at three viewport sizes and
two zooms: priority, text non-overlap, viewport containment, stationary
stability, separation, social bubbles, hidden residents, streaming additions/
removals and unchanged actor/collider identities. All three towns are wired.
`settlement_supports_smoke.gd` checks four porticos and six foundations,
alignment with existing floor height, static/idempotent drawing and unchanged
physics, actors, doors and route transforms at non-zero room origins.
`preview_settlement_nameplates.gd` captures four staged 960x540 town views.
All three scripts use isolated temporary saves.

`settlement_civic_art_smoke.gd` checks six distinct Cinder public-building
roles, alignment at translated room origins, unchanged original polygons,
visibility, actor/door/route transforms and physics, static/idempotent build
and inactive-room visibility. `preview_cinder_civic_art.gd` stages six
960x540 close-ups. Both scripts use isolated temporary saves.

`settlement_walkway_art_smoke.gd` checks all 44 Cinder walking surfaces:
36 steps, five galleries and three street segments. It verifies transformed
collision-top alignment, original polygons/transforms/one-way flags, scoped
leaf-plate hiding, static/idempotent rendering, sorting and inactive-room
visibility. `preview_cinder_walkways.gd` stages five 960x540 views. Both use
isolated temporary saves; screenshots do not replace traversal testing.

`hearth_board_readability_smoke.gd` checks seven aligned road rows at three
viewport sizes, event-driven task/guard/return eligibility, accurate victory
totals and retained dialogue. It verifies the mounted board avoids all 44
town walking surfaces without moving residents. `preview_hearth_readability.gd`
captures first-clear/return board states and two upper-sky camera positions,
with the biome transition settled. Both use isolated temporary saves.

`town_material_expansion_smoke.gd` checks four shared 512px mipmapped images,
57 Echo walking surfaces, 27 Starfall existing facade/roof polygons and six
market material plates. It verifies UVs, repeat mode, complete upper-city
house coverage, original visibility/geometry/transforms/physics, static
application and idempotence. `preview_town_materials.gd` stages five 960x540
views with settled biome backgrounds. Both use isolated temporary saves.

`city_background_smoke.gd` checks the serialized city sky before tool scripts
run, its full-height coverage, single painting ownership after initialization,
repeat visits and collision-safe rebuilds. `preview_city_background_editor.gd`
captures standalone/world editor-hint views; this diagnostic harness currently
needs a timeout wrapper because editor shutdown can stall after captures.

`starfall_upper_structure_smoke.gd` additionally checks four district arcades,
nine tiled stair/bell masonry surfaces and unchanged original silhouettes.
`preview_city_arcades.gd` captures six full-world city detail/overview views
with an isolated temporary save.

`starfall_prop_art_smoke.gd` verifies four civic workplaces and Outskirts
caravans/barricades, deep ruin materials, safe leaf-only retirement, original
geometry/physics and idempotence. `preview_starfall_props.gd` captures seven
runtime views with an isolated save. These tests do not mark all art complete.

`starfall_task_art_smoke.gd` covers seven progress registers, nine optional
stations, five restored landmarks, prerequisite/completion symbols, unchanged
task flags/prompts/reach/physics and event filtering. `preview_starfall_tasks.gd`
captures ten deliberately staged initial/completed runtime views; it does not
replace field-operation interaction/save tests.

`starfall_branch_art_smoke.gd` checks 30 side floors in six themed routes,
branch/niche texture coverage, safe technical-label retirement and unchanged
physics/flags/geometry. `room_painted_depth_smoke.gd` now requires 170 existing
painted surfaces across its nine rooms (35 additional side/niche masks).
`preview_starfall_branches.gd` captures eight staged runtime views including
the upper reserve and Cistern side chamber, with an isolated temporary save.

`starfall_scenery_art_smoke.gd` verifies six-route decorative scope, preserved
source geometry/physics/task flags, clipped line/root samples, static/idempotent
rendering and 14 compact plus 12 full field signs. The branch preview also
captures this pass; gameplay save/activation tests remain separate.

`crate_presentation_smoke.gd` checks the shared crate's four styles, mapped
room families, static idle art, damage/health restore, unchanged collision,
repeated flash cleanup, 32 seeded loot-oracle cases and transient break effects.
`world_population_smoke.gd` also verifies damaged art across an actual unload
and reload. `preview_crates.gd` captures a scale-labelled gallery and two room
contexts using an isolated save; this is not full-map art acceptance.

`crate_floor_placement_smoke.gd` exercises 18 placement edge cases and visits
all mapped rooms. It checks bounded vertical-only settling, unchanged terrain,
no newly overlapping crates, idle processing and placement coverage (currently
470 of 556 crates moved; 85 unresolved positions are printed for review).
The population test also checks settled positions survive unload/reload.

Follow-up: `crate_floor_placement_smoke.gd` now requires all 556 inspected
crates to be supported, including 85 explicit authored corrections, with
headroom/overlap checks. `crate_spawn_anchors_smoke.gd` covers all 85 entries,
old-position migration, stale-geometry guards, unchanged loot/callbacks and
damaged-crate streaming. `preview_crate_anchors.gd` captures six staged room
views. `audit_crate_anchors.gd` is an offline candidate-report helper, not
runtime placement logic or an automatic source-writing tool.

`echo_device_art_smoke.gd` visits streamed Echo rooms and checks 18 devices
with five silhouettes, unchanged interaction physics/flags, static/idempotent
art, compact overhang fit, activation/reward/reset states and 10 compact/5 full
signs. `preview_echo_devices.gd` captures a scale-labelled gallery and six
staged runtime views with an isolated save. Existing Echo gameplay tests remain
the authority for listening timing, threats, puzzles and save/reload rules.

`echo_scenery_art_smoke.gd` checks eight Echo routes, static/idempotent native
art, preserved source geometry/depth/physics/flags, child-bearing-node guards
and polygon containment within authored room masks (0.02 px float tolerance).
`preview_echo_scenery.gd` captures eight representative runtime views with an
isolated save. Field-site props, actor art and old label overlap are not marked
complete by this test.

`echo_painted_props_smoke.gd` checks six generated high-resolution RGBA
textures with mipmaps, explicit eight-room scope, 11 mineral carts/5 shelves/
105 ferns/6 tents/8 desks/1 book cart, desk draw order and low shelter height,
uniform scale/foot anchors, leaf-only retirement, rebuild physics/flag safety,
clue visibility, room re-entry and exclusion of the unrelated Ash causeway. Eleven staged
runtime views are provided by `preview_echo_painted_props.gd`. Site/actor anchors
are retained; five Archive furniture pieces use audited art-only offsets/scales.

`echo_prop_clearance_smoke.gd` checks those five Archive furniture footprints
against actual floor and platform rectangles, 89 Grotto one-way terrain contours,
camp shelter clearance and stable cosmetic anchors on room re-entry.
`audit_echo_prop_clearance.gd` reports nearby terrain with an isolated save;
it is a read-only authoring helper, not a runtime placement solver.

`echo_field_sign_layout_smoke.gd` checks 75 clues in eight Echo rooms: no
unresolved obstacle placements, chamber headroom containment, unchanged text,
stable repeat layout, absolute text depth, preserved collision/flags, live
record-status updates and no idle reflow. Other sign categories remain owned
by their existing controllers and are only reserved as layout obstacles.
`preview_echo_field_signs.gd` captures six focused runtime views with an
isolated save; the preview's camera framing does not alter gameplay cameras.

`echo_machinery_art_smoke.gd` checks two imported RGBA assets, four machine
assemblies, static/idempotent installation, leaf-only replacement, grounded
uniform pump scaling, clear dial/platform bounds, independent live gauge
states, unrelated-event filtering, room re-entry and unchanged physics/flags.
`preview_echo_machinery.gd` captures both pumps, both active gauges and the
lower gauge calmed with an isolated save. These are cosmetic feedback gauges,
not additional interactable controls.

## Player-reactive vegetation and walkable relief (2026-10-03)

`reactive_foliage_smoke.gd` exercises 17 soft prop family/type combinations:
directional spring response, root anchoring, wind continuity, recovery, swept
dash contacts, distant-floor exclusion, room/teleport cleanup and 12/6 contact
budgets. It also enforces the 36-mote cap and no per-plant processing callbacks.

`route_relief_physics_smoke.gd` uses the actual Player on three rounded terrain
profiles: standing/crouching in both directions, downhill contact, six dashes,
three jumps and gold/XP/material settlement on each profile. Native support
rectangles remain intact below the added shallow collision contours.

`route_relief_world_smoke.gd` audits all 39 rooms, with 134 contours across 20
eligible rooms and 842 slope-aligned props. It walks a representative contour
in each eligible room both ways (40 walks), checks native landing margins,
headroom, device clearance and stable re-entry, then tests scaled rooms and
safe retirement when a wall arrives or the supporting floor is removed.

`preview_route_relief.gd` captures four runtime biome views plus the Sunken
Shaft grass while brushing and after recovery. The brush is caused by actual
Player movement, not a manually set leaf pose. Shader-cache write warnings in
the sandbox are environmental; headless tests must still have no script errors.
See `route_relief_verification_v1.json` for the final logs and exact coverage.

### Terrain contact follow-up

`terrain_joints_smoke.gd` checks 37 wall-foot deposits in 21 rooms and 268
additional slope-end cutouts (the existing 134 contours are not reshaped).
It verifies registered footprints, native support, material-crop containment,
non-overlap with devices, stable re-entry, uniform world scale, late wall/device
changes and safe relief retirement when its supporting shape is replaced.
The wall backing uses a painted tile end-cap within the existing solid corner,
not an untextured rectangle or a new collider.

`ground_contact_fx_smoke.gd` drives the actual Player to verify stride-driven
dust, exactly one burst per qualifying landing, real sloped contact normals,
six material colours, no idle/carried/teleport/dead/flying effects, and a
40-grain pool (12 in low-cost mode). The shared ambience tick owns simulation;
there are no new per-particle nodes, gameplay timers, physics bodies or saves.

`preview_terrain_contacts.gd` captures four live corner compositions and real
step/landing effects. `terrain_contacts_verification_v1.json` records the
follow-up runs; the previous relief report remains historical evidence for
its original 842 slope props. Including end deposits, that total is now 1110.

The envelope regression now explicitly checks both opaque outer masses meet
their physical wall edges exactly. It catches the former two-pixel inset that
showed a vertical slice of distant scenery alongside buried ground, while
retaining open space below actual platforms/bridges.

### Painted Starfall tasks and branch furnishings

`painted_tasks_smoke.gd` checks 18 registered raster cutouts, seven compact
ledgers, nine field stations and five restored landmarks. It verifies true
floor contact in both states, uniform scale, upper-platform clearance,
unchanged reach/physics/flags, stable re-entry, no overlapping generic receiver,
bounded shared-driver lighting, and rooted plant response/settling. Reading
through G exposes each native task state without spawning a second sign or
recursively appending reports to the authoritative clue. Atlas sources are
unchanged PNGs; three mipmapped 1024px imports are shared by all instances.

`starfall_prop_art_smoke.gd` and `starfall_branch_art_smoke.gd` preserve the
existing no-new-node/collision contracts while replacing four caravan/wheel
sets, six barricades and scenery across 30 side pockets with compact painted
furnishings. `starfall_scenery_art_smoke.gd` also checks the background root
ribbons stay subdued and within the authored masks.

`preview_painted_tasks.gd` renders four station families in both states, two
different register layouts and the live reading panel alongside the actual
Player. See `painted_tasks_verification_v1.json` for final regression evidence
and `art/visual_slice/starfall_task_art_manifest_v1.json` for source prompts.

### Living routes, adaptive vaults and understory

The 2026-10-04 route pass uses six rounded physical terrain profiles, with
native floor rectangles preserved and extra crate/item settling aprons.
`route_relief_physics_smoke.gd` exercises every profile with standing/crouched
walks, dash, jump and settling gold/XP/materials. The world test checks all six
are actually used, contact/clearance, stable re-entry and late-support retirement.

`route_richness_smoke.gd` now checks additional uneven rear/front understory,
reactivity on both sides of the player, up to 12 traced ceiling seep sources
per room, bounded drops that stop at the first real floor, and safe retirement
of unsupported lowered vaults. `reactive_foliage_smoke.gd` covers 21 soft
family/type combinations. No per-decoration process callbacks are added.

Adaptive vault selection keeps the existing arena/town exclusions and landing
margins, but searches narrower off-centre bays after central candidates fail.
`route_vault_traversal_smoke.gd` exercises every resulting vault with three
actual controller jumps and two walking directions. Pressure-pipe textures and
compact return markers are covered by `scenery_completion_smoke.gd`; native
controller references, clues and progress remain intact.

`preview_living_routes.gd` captures five actual rooms plus a real-player rear
grass brush/recovery pair. See `living_routes_verification_v1.json` for final
counts and logs. Earlier verification files describe their own prior snapshots,
not the current terrain count after the enlarged safety clearances.

### Buried tunnel ceilings

`tunnel_vault_mass_smoke.gd` checks all 39 rooms and the opaque backing on all
22 lowered vaults. The chipped rock/black-earth silhouette remains inside the
original collision and landing margins: it cannot obscure the playable tier
above. Two scaled fixtures cover support removal and late obstacles, including
retirement of the whole visual owner and no regrowth over a visiting player.
Repeated finishing must preserve node identities, actors and all collision
shapes/polygons. Static backing adds no per-object animation callbacks.

`preview_tunnel_vaults.gd` renders four real rooms both below the roof and on
its supporting upper floor, using the actual controller to settle on each.
The preview-only upward/downward camera offsets expose both geological edges
and the still-readable upper route. `tunnel_vault_verification_v1.json` records
the focused release checks; this is not a complete campaign playthrough.
