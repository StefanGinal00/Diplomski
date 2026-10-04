# Echo Broodling appearance — 2026-09-28

## Generated asset

[echo_broodling_v1.png](echo_broodling_v1.png) is an original 1536 × 1024 RGBA
sheet generated with the built-in imagegen tool, following the imagegen skill.
No API/CLI, Blender or scripted pixel modifications. The original source is
preserved at native size; mipmaps are enabled. True alpha was checked at the
background and cell gutters and visually against a solid and actual game
background. Broad halos visible in the raw RGB preview are not visible in the
alpha-composited game render.

Six 512 × 512 cells, row-major: idle, stride A, stride B, windup crouch, leap,
recovery (also used on hit). Facing right in the source; mirrored for left.
Feet registered per pose, uniform 0.09 scale, sprite pivot at actor foot y=9.
Standing silhouette is about 32 × 26 game pixels, leap about 40 pixels wide.
Body/contact hitboxes remain the original 27 × 18 pixels, not the decorative
spine/leg silhouette.

## Integration

BroodlingAppearance is attached to EchoBroodling.tscn, covering authored,
streamed and encounter-spawned instances of that enemy. Native body/spines/eye
leaves are hidden but preserved; their modulation still supplies damage flash.
The native warning icon remains, raised to y=-36 so its pulse cannot overlap
the health bar. Windup duration, AI, movement, collision, health, drops, tier
upgrades, nest membership and persistence are unchanged.

Walking follows actual horizontal movement while grounded. Brief grace keeps
the frame stable between physics ticks; hidden/teleported actors do not accrue
walking distance. The art inherits room processing. Windup/leap/recovery read
the AI enum directly; no new attack timer or animation-driven damage. Tier-one
art has a subtle cool tint, without replacing the native warning cue.

## Verification

- broodling_appearance_smoke.gd: four live AI cycles (both directions, both
  tiers), full 0.48-second windup, stride stability, leap/recovery, damage flash,
  hidden relocation, visible teleport, source alpha/mipmaps and unchanged
  shapes/transforms/rewards.
- Related nest, habitat, field-operation and tier regressions are recorded in
  tests/LATEST_SMOKE_RESULTS.md.
- Three GPU captures inspected: [six poses, both directions](preview_broodling_poses.png),
  [actual nursery](preview_broodling_nursery.png),
  [warning in entry room](preview_broodling_warning.png).
- Preview uses a temporary save, frozen actors and an explicitly staged warning
  pose. It is visual QA, not a manual playthrough or balance acceptance.

This pass replaces one enemy family. Neutral fauna, other enemy families and
remaining geometric flora are not claimed complete.

## Exact generation prompt

Use case: stylized-concept. Asset type: production 2D game animation sprite sheet, six poses of ONE consistent original small cave broodling creature. Canvas landscape 1536x1024, exact 3 columns by 2 rows of equal 512x512 cells, no grid lines or labels. Each cell contains one fully visible identical creature facing RIGHT in strict side profile, same scale, feet/bottom centered near local x256 y410, generous transparent space. Creature design: low compact beetle-like cave hatchling, dusty teal segmented carapace with three swept-back short dorsal spines, pale lavender soft belly, four short jointed legs, small amber eye, blunt insect head on the RIGHT, no wings, no equipment. Matte hand-painted dark fantasy 2D art, finely textured shell, strong readable silhouette at 35 pixels wide, not glossy 3D. Row 1 left to right: relaxed standing idle; walking stride A with foreleg forward; walking stride B with opposing foreleg forward. Row 2 left to right: clearly compressed low crouch charging a leap; airborne leap with legs stretched and body extended horizontally; low tired recovery pose with legs splayed, no gore. Keep the same shell markings, face, proportions and consistent character size in all six cells. True transparent alpha background surrounding every pose, not black or painted checkerboard. No ground, no cast shadow, no external glow, no text, no UI, no border, no additional creatures. Each entire pose stays well inside its own cell.
