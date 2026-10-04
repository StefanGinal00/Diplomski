# Echo scenery presentation

Implemented 2026-09-28. Eight routes: Grotto, Gallery, Prism Archive,
Tide Well, Crystal Causeway, Undertow Vault, Echo Nest and Echo Depths.

## Changes

`EchoSceneryArt.gd` replaces/quietens 1,484 explicitly named cosmetic leaves:
220 rock formations use the existing stone texture with smaller silhouettes;
258 crystal sites use faceted clusters; 306 fungus sites use bent stems,
rounded caps and gills. Old matching caps/ceiling cones are retired, while
background organs, reservoir contours, silk, mirror/gate structures and
resonance ribbons are muted and clipped. The 37 opaque alcove-mouth trapezoids
are replaced by short side edges, exposing the existing painted background.

The palettes vary by route, retaining the existing region-specific landmark
motifs. No new bitmap is generated. Eight static draw nodes replace the
visuals without adding actors, colliders or per-frame processing. The original
decorative nodes remain in place but hidden, with source geometry unchanged.
Any matching node with children is skipped to protect gameplay subtrees.
There is no change to floor topology, doors, spawns, drops or save rules.
Current arrows, surge warnings, phase bridges and task devices are untouched.

All replacement polygons are intersected with authored chamber/shaft/branch
masks. This clips tall background pillars and long strokes at actual room
edges, including both diagonal and concave boundaries. See the official
[Geometry2D reference](https://docs.godotengine.org/en/stable/classes/class_geometry2d.html)
for polygon intersection/difference semantics used by implementation/tests.

## Verification

`echo_scenery_art_smoke.gd` rebuilds all eight routes and verifies source
geometry/transforms/depth, physics and flags are unchanged. It checks scope,
triangulation, idempotence, static processing and child-bearing-node guards.
Every replacement shape is checked against its original mask using polygon
difference, with a 0.02-pixel tolerance for float32 boundary round trips.
Earlier development runs exposed a test-only XOR/difference mixup, then
subpixel boundary slivers; accepted results are in LATEST_SMOKE_RESULTS.md.

`preview_echo_scenery.gd` produced eight D3D12 runtime views, one per route,
all visually inspected. Log `.tmp-echo-scenery-final.log`, exit 0, known
certificate-store warning only. Images:
`art/characters/preview_echo_scenery_<route>.png`.

## Remaining work

These are representative staged views, not full manual traversal or editor
acceptance. Several field-site props (carts, bookshelves, polygon ferns),
creature placeholders, oversized foundation silhouettes and overlapping old
labels remain visible and need their own pass. Grotto's older terrain-facing
style also differs from the other Echo rooms. This is not final map art.
