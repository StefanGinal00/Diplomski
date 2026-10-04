# Cinder walkway facing — 2026-09-27

CinderWalkwayArt.gd replaces 44 leaf platform plates with one static drawing:
36 segmented stone steps with copper end caps, five timber galleries with
plank joints/fasteners/shallow brackets, and three paved street segments.
Includes the original court, UpperVillage, gate plaza and EasternDistricts.
No new raster assets or external asset sources were used.

Every surface rectangle comes from the existing RectangleShape2D transformed
into the renderer's local space. The highlighted top is aligned to collision;
steps keep their exact silhouette. Only gallery brackets extend below the
original plate (8px plus stroke), not above or into new walkable territory.
No collision, one-way flags, dimensions, terrain, routes, doors or actors change.
Original leaf plates are hidden, not deleted; their geometry is retained.

The renderer moves its own node after other town children and draws at z=-1:
above roof accents on that layer, behind actor bodies and labels on z=0.
This avoids both roof masking of landing edges and platform masking of names.
It has no children, frame processing, physics processing or timers, and hides
with inactive rooms. This is cached drawing, not a new mobile benchmark.

## Validation and remaining work

13 targeted smoke tests pass (171 active scripts; not the full suite).
settlement_walkway_art_smoke.gd checks exact counts, collision-aligned bounds,
translated rooms, original polygon/transform/one-way invariants, narrowly
scoped visibility changes, sorting, idempotence and inactive-room hiding.

Five staged 960x540 GPU views from preview_cinder_walkways.gd were reviewed:
preview_cinder_walkway_{old_court,foundry_steps,kiln_gallery,archive_steps,watch}.png
under art/characters. All tests/previews use isolated workspace saves.

The platform layout itself remains unchanged, so some routes still cross
facade ornaments. The upper watch capture also exposes the existing top
boundary of the painted sky and the prototype field-office panel. Background
edge blending and that panel's presentation remain follow-up work. This is
not final town/map art, mobile profiling or full manual traversal acceptance.
