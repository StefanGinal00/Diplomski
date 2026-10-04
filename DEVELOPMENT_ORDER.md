# Agreed development order

Latest city-background pass (2026-09-30): six original textured architecture
variants now form two camera-relative planes over Starfall's single opaque
horizon. Retired 230 old background silhouettes/windows/trim renderers, not
playable houses or physics. Camera motion, revisit, quality switching and 14
focused regressions pass. Nine native frames cover the street, upper districts
and a camera-travel pair; initial oversized scenery was reduced and hazed.
Next visible targets: upper-garden prototype botany, task markers/large captions
and workshop/bridge trim. Whole-world art and phone profiling remain open.
See the newest `REGIONAL_AMBIENT_VARIETY.md` and `tests/LATEST_SMOKE_RESULTS.md`.

Latest facade follow-up (2026-09-30): two new original RGBA atlases supply six
closed-door variants and six utility props. There are now 66 painted residential
doors across Haven, its approach, Cinder and both Starfall city levels; six old
gate awnings have grounded supports. Echo Haven Outskirts' 16 houses / 32 windows
now share the village material painter, fixing the flat exterior facades revealed
by native captures. Supply corners, chimneys, bells and telescope use painted art;
two original Haven hanging crystals now use the budgeted lamp artwork (101 total
settlement hangings). 29 focused tests pass and ten native camera views were
checked. Remaining: old interactive task symbols/labels, workshop and stone-trim
primitives, further biome-wide dressing and real phone profiling. This is not
all-map sign-off. See `REGIONAL_AMBIENT_VARIETY.md` and `tests/LATEST_SMOKE_RESULTS.md`.

Previous settlement atmosphere pass (2026-09-30): three original painted atlases
supply 16 reusable pieces, 99 rope/wall/post-mounted animated ornaments and six
grounded civic landmarks in Echo Haven, its outskirts, Cinder Hearth and Starfall.
House supports and 44 Cinder walk surfaces use textured construction; upper-city
lamps, street carts/benches and regional flora reuse existing art. Two field-office
tables now open through the shared G reader with live task/claim status instead
of obscuring the street. Camera captures also exposed and removed remaining
settlement background masks. See `REGIONAL_AMBIENT_VARIETY.md` and the latest test
checkpoint. This is not all-map art sign-off: residential door frames, some
older canopies/botany, civic workshop details and native phone profiling remain.

1. Finish boss and miniboss encounters.
2. Finish their arenas, then review 1 + 2 as one milestone.
3. Build the storyline.
4. Finish ordinary mobs and populate/refine all maps.
5. Improve UI, skill-tree presentation and related menus.
6. Adapt controls, layout, performance and builds for phones.

Current milestone: **1 + 2 implementation/review pass complete (2026-09-28)**.
Active: storyline implementation and automated continuity coverage are in place
(2026-09-29); manual story review is deferred at the user's request. Ordinary-mob
and population refinement continues alongside remaining story polish. See `STORYLINE.md`.
Priority override from the gameplay screenshots (2026-09-29): checkpoint
reproduction, varied boss damage, finite projectile range and native-camera world
presentation. The first repair pass adds viewport-covering parallax, material
coverage, painted devices/NPCs/pickups, regional plants, prop scale fixes and
readable text. See `GAMEPLAY_REVIEW_FIXES.md` for completed checks and the open
work. The reported opening-enemy respawn remains unconfirmed: fresh-run and
isolated-copy save/death/revisit checks pass, and defensive restore registration
has been strengthened. Do not mark the bug or all world art finished yet.
Latest follow-up: 290 nearby-readable notices across 39 rooms, generated
environmental attack frames, fitted Drift machinery, 222 expedition nature props,
and room/camera-budgeted vine/air/mist motion. See `WORLD_LIFE_READABILITY.md`.
Phone frame times and the original respawn report are still unverified; keep
both explicit instead of treating passing automated checks as final sign-off.
Latest grounding/portal follow-up (2026-09-30): rectangular material faces now
match their real colliders; opaque-foot registration covers player, terrestrial
mobs, field guides and devices. All 112 existing passages receive supported
regional surrounds; 26 outer-edge boundaries prevent walking past endpoint
gates without closing internal routes. See `WORLD_GROUNDING_AND_PORTALS.md`.
This remains a scoped visual/physics pass, not all-world art or phone sign-off.
Latest structure integration (2026-09-30): three new original atlases replace
isolated doors with 112 regional facades and dangling lift images with 40 hoist
terminals, including terrain ties, supports and attached suspension. Cached-room
late devices are dressed automatically; nearby device captions no longer stack.
See `WORLD_STRUCTURE_INTEGRATION.md`. Native lift travel remains fade/teleport;
remaining prototype scenery, close entrance pairs and phone profiling are open.
Latest ambient follow-up (2026-09-30): 18 new regional cutouts are composed into
1253 details across 39 rooms in the automated check. Ground/overhead attachment,
protected interaction space, and late-device suppression are covered. Wind uses
the shared 18/8 animation budget, not independent callbacks. Old inert wedges,
terrain seams and blocking Forge/Haven backdrop sketches are retired. See
`REGIONAL_AMBIENT_VARIETY.md`. Native previews identify settlement resident bodies
and large authored mechanisms as priority remaining visual work; phone profiling
and whole-map artistic review are still open.
Resident/industry follow-up (2026-09-30): six shared regional appearances with
24 frames now dress 96 residents; native walking/dialogue and real-foot contact
are checked. Seventeen grounded industrial fixtures replace the Forge fan,
Barracks racks/standards and field displays. The fan follows its native flag,
and additional subtitles use nearby G reading. Four new original sheets, 14
focused passing tests and 13 native captures are documented in
`REGIONAL_AMBIENT_VARIETY.md`. Next: service/merchant bodies and work props,
settlement windows/cloth/facade depth and remaining authored scenery; not whole
map or mobile sign-off.
Service/street follow-up (2026-09-30): five original imagegen atlases now dress
all 10 TownService actors with four shared bodies/three poses each, supported
workplaces, 132 facade windows and 14 market stalls across Echo/Cinder/Starfall.
Starfall also gains painted street lamps, planters, benches and its delivery cart.
Thirty native-camera captures and 43 distinct passing focused tests are recorded
in `tests/LATEST_SMOKE_RESULTS.md`; exact prompts and asset paths are in
`art/visual_slice/SERVICE_AND_STREET_PROMPTS.json`. Next: the oversized schematic
Starfall fountain, hanging ornaments, older house supports, remaining plants,
upper-city workshop furnishings and room-specific facade/platform intersections.
Three service poses are not finished hand-refined work cycles; original opening
merchant art is preserved. Whole-map review and real-phone profiling remain open.
The latest regional exploration pass connects 26 existing optional routes across
Shaft, Echo, Ash and Starfall to visited-only journal guidance, return readiness,
small local supply bonuses and recovered dispatches. Existing gates, enemy
persistence and map geometry are unchanged; see `EXPLORATION_LEDGER.md`.
Regional readability now extends Echo's caption layout to 126 signs across 18
other routes and corrects stale cache/return cues. Automatic close-up captures
were inspected; combat pacing and prototype scenery remain separate unfinished
work. See `REGIONAL_ROUTE_READABILITY.md`.
The next visual pass replaces flat reserve-display bodies in 18 Shaft/Ash/Starfall
sites with three generated 2D raster assets, preserving live progress seals and
all gameplay. See `FIELD_RESERVE_ART.md`; remaining prototype scenery and combat
pacing are still unfinished.
Mission purposes, resolved journal entries and six quest-contact dialogue arcs
are integrated. Seven third-party CC0 boss/miniboss themes are wired and tested;
an in-game listening/mix review is still pending (`audio/music/CREDITS.md`).
Living-world story pass adds twelve reactive residents, live local-task
consequences, discovery/victory chronicle and the expanded single ending.
Eight optional field records now connect four regions, with paired interpretations
and four resident responses. Six accompany first-clear caches and two remain
return-visit discoveries. A complete continuity/pacing playthrough remains before
declaring the storyline finished.
Route continuity now follows native Echo/Ash prerequisites, explicitly including
the required first Coliseum trial. Four contacts recognize precompleted work;
Eldric, Lyra and Mira have route-aware/ending responses. No gate or reward changed.
Six discovered encounter approaches and six first-victory aftermaths now connect
bosses/minibosses to the journey, with warning priority and no rematch/reload replay.
The main quest now spans eight ordered objective stages with three-part bundles,
receipt persistence and a unique first-clear defense item. Side activities remain
separate. See `MAIN_QUEST.md` for rewards, save compatibility and illustrated
opening/chapter scenes. Ten illustrated event sequences now cover opening, seven
principal boss/trial victories and two main-quest milestones: three shots each,
four for the finale, with gradual text, skip/replay and lamp-save persistence.
Continuous safe-window/door-transition guards and route-aware Guardian/memory
narration are implemented. Story/library music ducking preserves track continuity,
mute settings and nested pause ownership. Full-run pacing, a listening/mix review
and mobile presentation remain pending.
Two event-driven campaign-flow checks now cover early/late memories, native boss
deaths, ordered interludes, staged/deferred reward claims, epilogue-to-journal
navigation and final-save/rollback. Postgame rests no longer force earlier unseen
interludes; they remain available for replay. These checks are not physical
room-by-room playthroughs or final balance approval.
Native scene-reload lifecycle coverage now checks normal death/rollback, backup
recovery, new no-save runs, Hardcore retry/mode switch, mute retention and return
to the main menu. Fresh-run retries now request the opening once after reload;
valid save continuation does not. Manual review remains deferred separately.
With manual story review deferred, ordinary-mob work has resumed with localized
ambush streaming: off-room enemies unload, surviving HP/position is restored, and
dead foes/completion rewards do not repeat. First-clear and gated return encounters
are covered automatically (`ENCOUNTER_STREAMING.md`). This does not mark all map
population or ordinary-mob refinement complete.
Checkpoint continuity now includes saved ordinary-enemy defeats and destroyed
crates across unloaded rooms, with native death/reload, backup and legacy-save
coverage. Pickup collection is guarded against duplicate/reentrant awards and
dead-player contacts. Loose uncollected drops, partial prop damage and neutral
fauna state are not disk-persisted; these changes do not finish map population.
Quick room reentry now cancels stale ordinary-mob windups, lunges/dives and root
strikes while preserving HP and position; explicit unloads retire owned hostile
projectiles even outside the source-room subtree. Seven mob scenes/two tiers have
focused interruption coverage. Boss lifecycle and manual balance review remain
separate from this ordinary-mob safety pass.
Checkpoint I/O reliability received a priority pass: staged metadata, validated
temporary writes, protected backup/primary replacement, no false respawn/lamp
activation on failure, and explicit fast-travel save-failure feedback. Native
failure/retry/death tests are documented in SAVE_RELIABILITY.md. This is a save
safety fix, not the planned UI/skill-tree redesign or final map completion.
Ground patrol refinement now covers Enemy/AshFiend/neutral fauna: ledge-aware
walking/chasing, directional wall turns without high-rate jitter, and small-step
traversal while preserving physical falls/knockback. Controlled 30/60/120 Hz
coverage is recorded in GROUND_PATROLS.md; full authored-route review is pending.
The boss/arena checkpoint is not a release
or final difficulty sign-off: a complete manual playthrough remains pending.

Encounter roster: Void Sentinel, Abyss Warden, Echo Matriarch, Ash Castellan,
Starfall Guardian, Hollow Sovereign and Ember Marshal.

Acceptance: readable preparation/release/recovery, natural movement and turning,
both facings, later phases/rematches, no stale attacks after interruption,
defeat/reward cleanup, arena surfaces/backgrounds and navigation, warning
visibility, gates and post-victory lamps. Automated checks plus visual reviews
must have recorded evidence; do not equate isolated animation tests with a
complete manual playthrough or final balance approval.

Evidence: 21 unique focused tests have passing final runs, including native
combat/progression, 35 interruption cases, 30/60/120 Hz movement, arena
navigation, 19 textured doors with unchanged geometry/routes and victory lamps.
All seven arenas reviewed in D3D12 warning/release captures; Warden's actual
time-stepped windup/charge/recovery also reviewed. See
`art/characters/BOSS_ARENA_MILESTONE.md` and `tests/LATEST_SMOKE_RESULTS.md`.

Storyline phase should first connect the existing zones, bosses and NPCs into
one coherent player motivation, then define chapter goals, quest/dialogue
changes and the ending. No storyline, UI or mobile implementation was bundled
into this boss/arena pass.
