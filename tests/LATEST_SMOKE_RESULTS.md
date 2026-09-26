# Smoke-suite checkpoints — latest 2026-09-26

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
