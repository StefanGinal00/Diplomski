# Crate grounding — 2026-09-28

Update: all 85 exceptions listed below are now addressed by the explicit
[authored-anchor pass](CRATE_AUTHORED_ANCHORS.md). The original results below
are retained as the baseline; current audit: 556 supported, zero unresolved.

Many spawn sites use 27–33 px character clearances although a crate is only
24 px tall. The result was visible air beneath static crates, including the
Echo Grotto and Memory Vault entry-court examples.

`CrateFloorPlacement.gd` batches new crates after construction/stream restore.
It lowers a crate by at most 48 world pixels onto a nearby horizontal static
support on terrain layer 1. Both feet must fit; X, collider dimensions, health,
loot, names, labels and destruction callbacks are unchanged. It rejects walls,
ledge edges, large drops, obstructed sweeps and overlap with other crates.
Rotated/other shapes and collision polygons are conservative blockers, never
invented horizontal supports. Disabled/zero-layer terrain is not support.
`settle_on_floor = false` allows an intentionally suspended authored object.

This is a one-time runtime placement pass, not falling-body simulation.
Each spawn batch shares terrain collection per containing mapped room; no
per-frame polling, timers, physics rays, eager population loads or retained
terrain cache. Pending references are weak. Later room changes get fresh
geometry. Static crate art and physics processing remain off while idle.
Editor-authored coordinates are not rewritten by this pass.

## Verification and remaining placement work

Final mapped-room audit: **556 crates visited, 470 lowered safely, one already
supported, 85 left unchanged without an accepted support**. Earlier checks
reported 504 moved; adding other-crate obstruction checks correctly excludes
34 more ambiguous/pre-overlapping placements. This pass does not promise to
fix every authored crate placement or certify a complete playthrough.

Remaining review counts (exact paths are printed by the audit test):

- Shaft: 38 — Hollow 6, Driftworks 2, Crossing 7, Gallery 12, Cistern 5,
  Warden Approach 6.
- Echo: 6 — Gallery 2, Tide Well 2, Crystal Causeway 1, Nest 1.
- Ash: 22 — Causeway 2, Forge 2, Barracks 7, Reservoir 2, Chapel 4,
  Hearth Outskirts 5.
- Starfall: 19 — Outskirts 5, Ramparts 2, Silent Gate 1, Memory Vault 2,
  Rooted Hall 4, Soul Crucible 1, Sunless Passage 4.

These need individually chosen anchor adjustments, especially beside shaft
stairs, branch landings and existing overlapping supply props. Do not expand
the automatic drop distance or remove reward-bearing objects to clear them.

Seven targeted tests pass; reports are in tests/LATEST_SMOKE_RESULTS.md.
The new audit includes 18 fixtures (scale, shape offsets, disabled terrain,
ledge, wall, slope, shaft, round/polygon/rotated obstruction, stacked crates,
opt-out, destroyed/freed actors, one-way support, idempotence), terrain
immutability and no new crate overlap. Population regression verifies a
wounded crate preserves its settled position and cracks across unload/reload.
Existing field-operation, dressing and seeded-loot tests also pass.

Three final D3D12 captures completed (gallery plus Echo Grotto/Memory Vault
contexts), exit 0, .tmp-crate-grounding-final.log; only the known certificate
store warning. Context views were inspected before and after the final stack
safety change. No full-suite, manual gameplay or editor acceptance claimed.
Primitive creatures, crystals and oversized labels remain separate art work.
