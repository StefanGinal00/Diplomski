# Shared supply-crate presentation — 2026-09-28

The shared DestructibleCrate scene now draws planks, metal bands and rivets,
with four native 2D variants: travel bracing, Echo/shaft rope and patina,
Ash iron seal, Starfall paper/wax seal. Family selection uses the existing
WorldLayout room-name mapping (including names without biome prefixes).
Original Box/Border/Mark leaf nodes are retained but hidden. Quest-label
children and the 24x24 physics shape are untouched. No new raster generation.

Health changes explicitly redraw cracks; direct streaming health restoration
does not trigger hit effects. Repeated hit flashes cancel the preceding
cosmetic tween. Intact and damaged art do not process every frame.
Destruction adds six deterministic splinters through ProjectileImpact's
existing 24-effect cap, 0.22-second lifetime, pause and room/rest/transition
cleanup. Debris has no physics and does not consume the crate's loot RNG.
Loot, empty probability, destroyed signal and respawn authority are unchanged.

## Verification

Six targeted tests passed (reports in tests/LATEST_SMOKE_RESULTS.md):
crate presentation, world population, projectile impacts, Starfall dressing,
Starfall field operations and Ash industry dressing. New checks cover all
mapped room families, unchanged colliders, health restore, repeated hits,
32 oracle-compared seeded loot cases and one-shot destruction/expiry.
The world-population test checks an actually unloaded/reloaded wounded crate,
alongside existing destroyed-crate persistence assertions. Its initial fixture
mistakenly used nonexistent TraversalCrate01; corrected to existing tier 02.

Three 1280x720 D3D12 runtime captures completed and were reviewed: the 5x
inspection gallery with a 1x bottom row, Echo Grotto and Memory Vault context
views at 2x. Log .tmp-crate-preview.log, exit 0; only the known local
certificate-store warning. No manual gameplay/editor acceptance or full-suite
claim. Source geometry, loot tables, quests and room placement were not edited.

## Remaining work

Follow-up: [crate grounding](CRATE_FLOOR_PLACEMENT.md) now resolves 470 nearby
floor gaps on runtime load, leaving 85 audited exceptions for authored fixes.
Those exceptions are now resolved by [explicit anchors](CRATE_AUTHORED_ANCHORS.md).
The original appearance-pass capture/placement notes above describe that pass
before this follow-up.

Context views still expose existing primitive enemies/crystals, large labels
and some authored crate-to-floor gaps. Those are not fixed by this appearance
pass. Some quest crates retain their existing text markers; no new special
quest-loot promise is implied by the regional seals. This does not mark all
map art, props or level placement complete.
