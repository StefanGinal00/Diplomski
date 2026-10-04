# Broken Ramparts painted art — 2026-09-27

Two new 2D assets generated with built-in ImageGen, not CLI or Blender:

- [broken_ramparts_depth_v1.png](broken_ramparts_depth_v1.png): 1536×1024 source painting of ruined defensive service galleries; 1024px mipmapped Godot import.
- [broken_watch_pillar_v1.png](broken_watch_pillar_v1.png): transparent 1280×1280 returned source, imported at 512px with mipmaps. Reused at four restrained landmarks, not four unique sprite designs.

Both source files were copied unchanged. Runtime placement reads alpha to ignore
near-transparent fringe below the visible stone, without editing the image.

## Integration and scope

`ExpeditionWing.gd` opts the Starfall region into `RampartPaintedArt.gd` through
`painted_ramparts_enabled` (default true). Shaft, Echo and Ash expeditions are
unchanged. The art builds after the generated route. The world-editor schematic
gets paintings but no fabricated floor bodies or pillar placements.

- 24 original background polygons: eight main chambers, four side chambers and twelve links including the optional loop.
- One shared shader/material and room-wide UV space keep adjacent masks continuous. Mirrored sampling limits magnification on the large map; motifs can recur and this is not a separately painted image per chamber.
- 105 existing horizontal walking-surface polygons use the existing Starfall masonry texture with collision-aligned thin rims. No new floors, blocked shaft openings or altered jump edges.
- 81 explicitly scoped decorative ruin/outline leaves are hidden. Their distant architecture is replaced by the painting; gameplay parents, actors, doors, controls, caches and existing field dressing remain untouched.
- Four static alpha pillar sprites at main chambers 0, 2, 4 and 7 stand behind actors. Anchors use actual supported floor segments, not a guessed chamber center over a hole.
- Far painting and haze reuse the existing 20 Hz camera-relative update and hidden-room sleep. Static trims and sprites do not animate. No 3D or new physics.

## Checks and limitations

8/8 targeted smoke tests passed: painted-art invariants, local rampart operations,
all four expedition layouts, population support, Starfall field dressing,
expedition jumps (322 hops / 42 descents / 12 tunnel walks), outer route and doors.
The art test was rerun after the final alpha-foot placement correction. This is
not the full suite (178 active scripts), a mobile performance certification or
a complete manual playthrough.

Five GPU views (watch, bridge, upper branch, western gate and wide) were captured
and reviewed. A visible small gap below pillars prompted the alpha-foot correction;
watch and bridge were rechecked after it. Final captures are logged in
`_tmp_rampart_art_preview2.log`. Only the known host certificate / shader-cache
write diagnostics remain there, with no script/shader compile failures.
Initial editor import found two inferred-type declarations in the new script;
explicit float types fixed those before the passing tests and captures.

These changes do not finish character art, vehicles, task boards, flora or every
Starfall foreground prop. Remaining region-specific backgrounds in Shaft, Echo
and Ash and the city sky still need rollout. Existing floating-world boundary
visuals outside playable chambers are not changed by this art pass.

## Exact prompts and source files

### broken_ramparts_depth_v1

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-f856cd1b-6d48-4465-9608-384ddb86f78f.png`

```text
Use case: stylized-concept. Asset type: opaque 1536x1024 painted background for a 2D side-scrolling dark-fantasy exploration game. Subject: the inner service passages of ruined Starfall defensive walls, deep layers of cracked buttresses, broken stone watch galleries, weathered arrow slits, fallen iron support beams and loose hanging old ropes, distant openings reveal cloudy desaturated blue dusk. More enclosed military masonry and service infrastructure than a panoramic city skyline, not a royal cathedral. Hand-painted illustration, broad silhouettes and restrained fine detail, dim slate blue and faded dusty mauve. Side-on layered background only; no playable foreground floor or platforms, no characters, enemies, readable text, apparent exit doors, UI, watermark, bright fire or glowing hazards. Low contrast so combat stays readable. Even detail across image; no central focal object or heavy vignette.
```

### broken_watch_pillar_v1

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-14c168e0-412d-412d-9e98-2aeb37dc6c24.png`

```text
Use case: stylized-concept. Asset type: single transparent-background 2D game scenery sprite, square 1024x1024. One broken defensive watch pillar made of weathered violet-gray stone blocks, front elevation, lower squat block pedestal supporting a narrower cracked fluted shaft with an asymmetrically shattered top and a little old iron binding around its base. Entire object fully inside frame with at least 8 percent transparent padding on EVERY side. Hand-painted dark fantasy illustration, bold readable silhouette, broad subdued shading, not photorealistic and not a 3D render. Muted slate and pewter, no glow. No floor, no cast shadow outside object, no scene background, no characters, foliage, text, watermark, duplicate objects or sheet. Genuine transparent alpha around the object, no painted checkerboard.
```
