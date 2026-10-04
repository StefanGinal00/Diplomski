# Authored crate exceptions — 2026-09-28

Resolved the 85 sites left by the bounded grounding pass. New locations are
explicit entries in CrateSpawnAnchors.gd: old parent-local coordinate, new
parent-local coordinate and the supporting floor's room-relative node path.
They are not a runtime search for arbitrary empty space.

Most problems were intersections with Overlook/Niche platforms or adjacent
supplies sharing almost the same coordinates. The widest corrections are
408 px in Drowned Crossing and 456 px in Flooded Gallery, to existing clear
floor segments on the same level. Echo Nest's embedded crate rises 1 px.
No terrain, doors, NPCs, loot-bearing objects or quest callbacks were removed.
The baseline downward-only 48 px automatic placement rule is unchanged for
all other crates. No crate sizes, reward tables or region populations change.

The map audit now finds **556 supported crates, zero unsupported sites**;
85 reviewed exceptions are checked explicitly. Headroom around those 85
sites is checked against static terrain, with no newly overlapping boxes.
This is geometric placement validation, not a complete traversal/playtest.

## Streaming and stale-data protection

The exception pass runs once per loading batch, before normal grounding and
after population restore. It matches the old coordinate within 0.02 px, so
saved old positions migrate but new positions are never offset repeatedly.
Unrelated edited positions are preserved. Missing/disabled/changed support,
nonstandard collider shape/transform or scaled crates reject the correction.
The anchor table needs review when these authored floors are redesigned.
There is no additional frame processing or eager room population loading.
Editor scene coordinates are not rewritten; this remains runtime placement.

## Validation

- crate_floor_placement_smoke: 18 safety fixtures, all 556 placements,
  explicit 85-site contract, fixed terrain, headroom and no new box overlap.
- crate_spawn_anchors_smoke: all 85 entries, unchanged health/loot RNG/tables,
  colliders and destruction callbacks, one-time old-state migration,
  unrelated edits, disabled/scaled/rotated guards, unload/reload positions,
  wounded health and damage appearance.
- Existing population, route dressing, Starfall/Ash field-operation,
  Ash industry and seeded-loot presentation regressions remain in scope.
  They include archive-record and barracks drill-target completion/rest.

Accepted reports are in tests/LATEST_SMOKE_RESULTS.md. The new read-only
audit_crate_anchors.gd helper may propose candidates for future exceptions;
its output must be reviewed before changing the explicit table. It does not
edit source assets or change the running game's placement policy.

Six 1280x720 D3D12 staged runtime captures completed and were inspected:
Hollow, Crossing, Gallery, Tide Well, Barracks and Memory Vault. Log:
.tmp-crate-anchors-preview.log, exit 0; known certificate-store warning only.
No new raster assets, full-suite, manual playthrough or editor UI acceptance.

## Still unfinished

These captures expose existing crude scenery, small creature stand-ins,
oversized/overlapping labels and geometric devices. This pass resolves the
crate-position backlog, not all remaining map art or encounter balance.
