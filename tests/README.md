# Automated smoke tests

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
