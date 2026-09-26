# Visual style pilot — Echo Grotto / Starfall market

This is the first in-game 2D environment art sample, not final character art
or completion of the entire map.

## Scope and review

- EchoGrotto.tscn: painted entrance and nine gallery backplates, clipped to
  their existing silhouettes; stone ledge facing, sparse plants and motes.
- StarfallCitadel.tscn: market district only, x=2820..4280. New masonry hall
  and townhouse, arched windows, stalls, local stone trim and lantern flicker.
- Original movement, colliders, doors, puzzles, actors and save rules unchanged.
- Background UV displacement follows the camera at a slower rate than terrain.
  This is a first parallax layer, not the final multi-layer foreground system.
- Static scenery draw commands are cached. Only tiny ambient accents redraw
  at 20 Hz; hidden/inactive rooms do not animate. Two shared source textures
  are reused, not a bitmap per chamber. Mobile performance is not certified.
- Ordinary town residents now have native-vector lapels, boots, hair/face
  detail, a movement-driven stride, subtle idle breathing and talking gestures.
  This augments the existing resident shapes, not a finished sprite sheet.
  Merchants, the player, enemies, combat animations, audio and the rest of the
  city retain their prototype appearance.

Open EchoGrotto.tscn or StarfallCitadel.tscn in Godot to see the integrated
art (tool script). In the running game, visit Echo Grotto / Starfall Market.
For a reproducible screenshot run, use the existing Godot executable with:
`--path . --rendering-method mobile --script res://tests/preview_visual_style.gd --quit-after 600`.
The preview uses a separate temporary save, never the player's save.

In-engine captures (not image-generator mockups):
- [Grotto overview](preview_grotto.png)
- [Grotto at gameplay zoom](preview_grotto_gameplay.png)
- [Starfall market](preview_market.png)
- [Apothecary and resident detail](preview_apothecary.png)

## Assets / provenance

Generated with the built-in imagegen tool on 2026-09-25, not the API/CLI.
No third-party game art was downloaded or copied. Native foreground details
are implemented in VisualStyleSlice.gd; generation was used for the two
raster background plates only. These source PNGs live inside the project:
- `res://art/visual_slice/grotto_backdrop.png` (1536 x 1024)
- `res://art/visual_slice/city_backdrop.png` (1536 x 1024)

### Exact generation prompt — grotto

Use case: stylized-concept. Asset type: production background plate for a 2D side-scrolling fantasy game, wide landscape 1536x1024. Paint an original subterranean echo grotto: immense softly layered mineral arches receding into midnight teal mist, tiny muted turquoise crystal veins, elegant eroded stone shapes and delicate hanging roots. Hand-painted 2D illustration with clear shape design, restrained brush grain, atmospheric depth, no 3D rendering. The center and lower third must remain quiet low-contrast deep blue for readable gameplay sprites added later. Distant scenery ONLY: no playable platforms, no ground ledge across the foreground, no characters, enemies, interface, text, logos or watermark. Edge colors deep midnight navy. Rich but restrained cyan illumination, not neon outlines. A reusable backdrop, not a screenshot or mockup.

### Exact generation prompt — city

Use case: stylized-concept. Asset type: production background plate for a 2D side-scrolling fantasy game, wide landscape 1536x1024. Original Starfall safe-city skyline at blue hour: layered old slate-roofed houses, tall narrow bell towers, stone arches and suspended footbridges receding into indigo atmospheric haze. A few tiny warm amber windows. Elegant hand-painted 2D illustration, softly textured brush grain, same restrained storybook dark-fantasy art direction as a turquoise crystal cavern. Side-on distant architectural elevation, NOT isometric, NOT 3D. Keep center and bottom third dark, low contrast and uncluttered for real gameplay buildings, NPCs and ground that will be overlaid by the engine. No foreground ground or platforms, no characters, no readable signs, no text, no UI, no logos or watermark. Broad sky and distant architecture, beautiful irregular silhouettes, no copied game landmarks.

## Validation / limitations

The visual smoke checks both scenes, 11 image plates, valid UVs, camera
response and inactive-room sleep. Collider paths/transforms/shape identities
and one-way flags are compared before and after attaching the art module.
Separate targeted gameplay regressions protect Grotto traversal and city state.

The final screenshots were rendered and visually reviewed with the project's
D3D12 Forward Mobile renderer on the desktop GPU. The isolated environment
reported the known Windows certificate warning and a shader-cache write
warning; screenshots still saved successfully. The earlier OpenGL preview
reported driver shader-initialization warnings, so it is not the accepted
renderer path.

The initially observed Starfall schematic-preview errors are fixed: previews
and gameplay share the same floor/anchor construction, with merged shaft
holes preserved. Six previews match all 15 doors, 15 arrivals and 126 sampled
portal anchors against their live scenes. A fresh full headless editor import
reports no script or missing-node errors. The sandbox still rejects editor
settings writes outside the workspace; that environment warning is not
presented as a project-script failure. Exact runtime results are recorded
in tests/LATEST_SMOKE_RESULTS.md.

## Second polish pass

The market treatment now includes the adjacent apothecary facade, a herb
sign and planters. Grotto greenery has less uniform spacing and finer stems.
No new generated bitmaps were needed: this pass extends the native editable
foreground art and reuses the two original plates. ResidentMotion.gd alters
only the existing visual children and draws detail; actor roots, collision
shapes, labels, route logic, indoor transitions and dialogue state are not
changed. Hidden residents stop animating; teleport/restore jumps are ignored
by the stride calculation.
