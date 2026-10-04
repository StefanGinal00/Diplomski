# Echo Shade appearance - 2026-09-28

## Asset and generation

[echo_shade_v1.png](echo_shade_v1.png): native 1536 x 1024 RGBA, six 512 x 512
cells. Generated using the built-in imagegen tool under the imagegen skill.
No CLI fallback, Blender, background removal or scripted pixel edits. Source
copied into the project unchanged; Godot mipmaps enabled. Actual alpha verified
at corners, gutters and outside the character, with composited GPU inspection.

Six poses, row-major: idle, glide, windup, dash, recovery, hit. Original hooded
indigo wraith, mint eyes and ragged cloth. Uniform scale 0.09 with per-pose pivots
and a hem anchor at y=17.5, matching the unchanged body's lower edge. Source faces
right; poses mirror for left. These are six state-driven key poses, not a full
frame-by-frame animation cycle.

## Integration

ShadeAppearance is a Sprite2D child of EchoShade.tscn, covering authored and
spawned instances wherever that enemy scene is used. Only the childless Mantle,
BodyVisual and Eyes presentation polygons are hidden. Native BodyVisual remains
available to AI and the damage-flash tween. EchoShade.gd is unchanged.

Art reads native windup/dash/recovery timers and damage tint. Committed attacks
face dash_direction, including the upgraded followup. Glide follows real travel,
with short between-physics-tick grace; hidden relocation/teleports do not animate
as movement. Stronger shades receive a subtle teal tint. Inactive population
processing is inherited, with no new actors or collision objects.

The existing 130px warning line draws above the sprite; its shape, timing and
colors are unchanged. Body/contact rectangles stay 28 x 35; HP, rewards, movement,
contact damage, death and population rules are not changed by this art layer.

## Validation

shade_appearance_smoke exercises four real AI attack cycles (two facings x two
tiers), including the native double dash at tier 1. It checks full warning
duration, committed direction, glide, recovery, native damage interruption and
flash restoration, hidden/teleport handling, disabled processing, six pose pivots,
alpha/mipmaps and unchanged collision/rewards.

Regression reports are in [latest smoke results](../../tests/LATEST_SMOKE_RESULTS.md).
Four GPU captures reviewed, isolated temporary save, frozen in-room preview:

- [Six poses, both directions](preview_shade_poses.png)
- [Gallery neutral appearance](preview_shade_gallery_idle.png)
- [Base warning](preview_shade_gallery_warning.png)
- [Awakened warning](preview_shade_gallery_awakened.png)

Preview .tmp-shade-preview.log exit 0; only the known certificate-store warning.
Editor imports exited 0, with sandbox-denied global AppData settings saves.
No manual playthrough or editor acceptance claimed. Small fauna placeholders and
entry-room geometric decorations remain separate follow-up work.

## Exact generation prompt

Use case: stylized-concept. Asset type: production 2D side-scroller enemy sprite sheet on genuinely transparent alpha. One original Echo Shade: a small ominous hooded cavern wraith wrapped in tattered layered indigo and dusty violet cloth, black hollow face with two small mint eyes, tapering ragged hem instead of feet, compact floating torso and short spectral hands. Hand-painted matte dark fantasy texture with readable folds and restrained pale teal rim highlights, not glossy 3D, not pixel art. All six poses show exactly the same character facing RIGHT in a strict side-on view. Layout: exactly 3 columns by 2 rows, canvas 1536x1024, six equal 512x512 cells, no visible grid. Each whole sprite centered in its cell with generous transparent gutters, comparable body scale, baseline at local y=425. Row-major poses: 1 upright quiet hovering idle; 2 gliding right with hem drifting gently left; 3 attack anticipation leaning back with hands gathered at chest, compact and tense; 4 forward dash leaning strongly right with fabric swept behind, no trail or projectile; 5 tired recovery slouch, hands lowered; 6 hit recoil leaning backward with torn folds flared. Keep head and torso compact, each whole silhouette within local x=70..442, y=70..435. No scenery, floor, shadow, fog, glow cloud, text, numbers, border, painted checkerboard, effects or extra objects. The only visible pixels should be the six isolated character poses.
