# Starfall scenery and instruction readability — 2026-09-28

StarfallSceneryArt is an explicitly scoped native-2D pass on decorative
Identity silhouettes and RoomIdentity leaves. It never traverses task-device
parents to hide content, nor changes routes, actors, collision or reward rules.

- Rooted Hall's flat filled root silhouettes and bright straight root network
  are replaced visually with thin baked curved strokes, bark highlights and
  sparse leaves. Original source polygons/line points remain stored unchanged.
  Final clipped output has 116 root strokes.
- Silent Gate, Memory Vault, Soul Crucible and Sunless Passage receive 150
  tiled masonry/iron surfaces on existing decorative polygons, using existing
  project images. Outskirts retains its previous material pass unchanged.
- Decorative tendrils, ward bars, memory ribbons and conduits are quieter
  strokes. New root/line drawings are sampled and clipped against the union
  of existing chamber/shaft/branch/niche masks so they do not extend through
  large empty areas outside the authored scenery. This is visual clipping,
  not a collision modification. Line thickness can straddle an edge by a few
  pixels; no pixel-exact clipping claim is made.
- Root-heart/core accents and dark curtains are subdued without changing
  their geometry. These are cosmetic identity nodes, not progression signals.

Fourteen local field signs now show a short local action, progress and save
reminder; the Rooted Hall version still states that grazers need not be harmed.
Twelve full entrance/reserve signs retain complete optional-task instructions,
guardian prerequisites and post-Sovereign return context. Interactive prompt
text, activation range and actual task conditions remain unchanged.

## Verification

starfall_scenery_art_smoke covers six routes, immutable original transforms,
depth and polygon/line points, collision snapshots, read-only flags, safe leaf
retirement, textured surfaces, clipped stroke vertices, idempotence and hidden
room behavior. It also checks all 26 signs fit their bounds and the reserve
instructions avoid the guardian status. Existing outer/inner field-operation,
dressing, branch, painted-depth and task-art tests remain in the targeted set.
Accepted reports are in tests/LATEST_SMOKE_RESULTS.md.

Eight 1280x720 D3D12 staged runtime captures completed, exit 0. Rooted Hall,
Soul Crucible and Memory Vault were reviewed; Rooted Hall/Crucible were reviewed
again after clipping stray strokes. Final log: .tmp-starfall-scenery-final.log.
Only the known certificate-store warning, no script/shader errors. No new
bitmap assets or image generation; no manual traversal/editor UI acceptance.

This is not complete final scenery. Existing mask silhouettes, some props,
ambient labels and enemy art still need work. The legacy editor schematic
limitation described in STARFALL_BRANCH_COVERAGE.md remains.
