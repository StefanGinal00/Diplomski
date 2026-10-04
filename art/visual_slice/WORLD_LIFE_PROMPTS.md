# World life / readable machinery art — 2026-09-29

Mode: built-in imagegen tool, following the imagegen skill. Original generated PNGs copied unchanged; no external asset downloads, image editor, Python raster edits, CLI/API fallback or paid marketplace assets. Atlas regions and in-engine drawing select parts without changing the source files.

Five originals retain full source resolution. Godot imports are capped at 1024 px with mipmaps and alpha borders for these small gameplay props/effects. This is deliberate: 1536/1774 px source quality does not require keeping the whole resolution in mobile video memory. Combined decoded RGBA+mipmap images currently measure 15,836,060 bytes (~15.1 MiB), not a measurement of total game memory/GPU allocations or phone FPS. Hazard frame regions scale with imported dimensions; machine crops normalize against the source size.

## field_machinery_atlas_v1

Saved: `art/visual_slice/field_machinery_atlas_v1.png` (1536 x 1024).

Original: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-59e260dc-07cb-4cdd-8be7-08a2d5558e1c.png`.

Exact generation prompt:

```text
Use case: stylized-concept. Asset type: production 2D dark-fantasy platformer machinery parts atlas, genuine transparent alpha. Exactly 3 columns and 2 rows of equal square cells with generous transparent margins, no overlap. Top left: a ROUND six-spoke weathered iron flywheel viewed straight on, centered circular axle, rust and brass rim, only the wheel, no stand. Top middle: low iron triangular flywheel bearing pedestal, wide riveted feet, upper bearing socket, NO wheel. Top right: compact paired piston water pump with copper pipes and small gauge, grounded machine. Bottom left: a small battered iron floor pressure vent grille with riveted rim, no steam or flame. Bottom middle: a compact stone-lined water drain channel outlet, damp moss and bronze sluice rim, no water spray. Bottom right: small readable-world prop, wooden notice board on a short stone post with blank weathered parchment, no letters. Detailed hand-painted side-view 2D game art, slate teal iron and muted brass, readable at tiny scale, not pixel art, not 3D. Isolate every object inside its own cell. No backdrop, no scenery, no text, no captions, no border, no watermark. Requested resolution 2400x1600. Transparent cutouts outside the objects.
```

## steam_water_hazards_v1

Saved: `art/visual_slice/steam_water_hazards_v1.png` (1774 x 887).

Original: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-5be7efdf-dc3e-4063-9f98-fe61f29fc596.png`.

Exact generation prompt:

```text
Use case: stylized-concept. Asset type: 2D game environmental hazard animation sprite sheet on genuinely transparent background. EXACT GRID 4 equal columns by 2 equal rows. Eight separate frames, every frame contained inside its cell with padding, no overlaps. Top row shows FOUR consecutive active-loop frames of a tall forceful WHITE STEAM JET emerging upward from bottom center; wispy turbulent curls change from frame to frame, amber highlights close to source, no solid pipe or floor. Bottom row shows FOUR consecutive active-loop frames of a splashing BLUE WATER SURGE emerging upward from bottom center, distinct turbulent wave crests and droplets, not a rectangular fill. Keep baseline and overall extents consistent across each row; entire emission including droplets inside each cell. Dark-fantasy painterly hand-inked 2D effects, crisp silhouettes, no glow backdrop, no pixel art, no 3D, no text, no numbers, no borders, no scenery. Requested 2048x1024. Real alpha outside steam/water; do not include a visible checkerboard.
```

## fire_soul_hazards_v1

Saved: `art/visual_slice/fire_soul_hazards_v1.png` (1774 x 887).

Original: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-8729802f-fce9-4b69-bf0e-e99891ffed07.png`.

Exact generation prompt:

```text
Use case: stylized-concept. Asset type: 2D game hazard animation sprite sheet, genuine transparent alpha. EXACT GRID four equal columns by two equal rows, eight separate frames, no overlap. Top row: four successive active-loop frames of a forceful rising ORANGE FIRE PLUME with pointed flame tongues and tiny sparks, source at bottom center, no solid furnace. Bottom row: four successive active-loop frames of a VIOLET SOUL ERUPTION, curling smoky ethereal ribbons with pale silver hot core, distinct from fire. Full emission in each cell with generous transparent margins, consistent bottom-center origin and comparable height; change curls/tongues visibly between frames. Dark fantasy painterly 2D hand-inked effect, readable at small scale, not pixel art, not 3D. No background glow field, no scene, no text, labels, watermark or border. Requested 2048x1024. Actual transparent background.
```

## rubble_root_hazards_v1

Saved: `art/visual_slice/rubble_root_hazards_v1.png` (1774 x 887).

Original: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-b18482ec-1e1f-407d-8324-3a794519d4eb.png`.

Exact generation prompt:

```text
Use case: stylized-concept. Asset type: 2D dark-fantasy environmental hazard animation sprite sheet, actual transparent alpha. EXACT GRID four equal columns by two equal rows, eight isolated frames with generous transparent padding, no overlap. Top row: four consecutive phases of FALLING CAVE RUBBLE: frame1 small falling pebbles and dust, frame2 larger tumbling slate rocks, frame3 rocks nearing bottom with dust, frame4 impact rubble and dust puff at bottom. Full falling column entirely inside each cell. Bottom row: four active animation frames of gnarled THORN ROOTS erupting upward from bottom center, mossy dark bark, curved sharp thorns, visibly different bending poses, same baseline and height. Painterly hand-inked side-view 2D game sprites, gray rocks/brown-green roots, legible at gameplay scale. No ground plane, no backdrop, no rectangle of color, no glow, no text or labels, no border/watermark. Requested 2048x1024. Transparent outside objects including dust.
```

## regional_hanging_vines_v1

Saved: `art/visual_slice/regional_hanging_vines_v1.png` (1536 x 1024).

Original: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-6f2bc84c-d39f-4f0f-8a2c-4ce7e260ddf8.png`.

Exact generation prompt:

```text
Use case: stylized-concept. Asset type: 2D game ambient vegetation atlas on genuinely transparent alpha. One row of three equal-width cells, distinct isolated hanging plant silhouettes, generous padding, no overlaps. Left: long trailing mossy ivy with loose tendrils and small leaves, attached at top to a chipped stone bracket. Middle: desiccated hanging roots and thin ash-colored grasses with a few dry orange leaves, attached at top to a broken iron hook. Right: long silver-blue cavern vine with fine fern fronds and a few pale seed pods, attached at top to a small old carved stone. Each entire cluster contained inside its cell, organic branching, asymmetrical hanging tips, readable at small scale. Painterly detailed side-view hand-inked 2D dark fantasy, no pixel art, no 3D, restrained colors, designed for subtle wind deformation. No background, no scenery, no floor, no glow, no text, no border/watermark. Requested 1800x1200. Preserve real transparent alpha.
```
