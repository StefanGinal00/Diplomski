# Painted room depth — 2026-09-27

Follow-up: [24 remaining room backgrounds](WORLD_BACKGROUND_ROLLOUT.md) extend
this system across Shaft, Echo, Ash, approaches, training and the city sky.

Four new opaque 1536×1024 images generated with the built-in ImageGen tool,
not the CLI. Source pixels are preserved; Godot imports use a 1024px maximum
edge and mipmaps. This pass adds background art, not new 3D models.

| Scene | Asset (in this directory) | Painted surfaces |
| --- | --- | --- |
| BlackwaterCistern | cistern_depth_v1.png | 15 |
| PrismArchive | prism_depth_v1.png | 22 |
| CinderForge | forge_depth_v1.png | 14 |
| StarfallMemoryVault | memory_depth_v1.png | 14 |

## Integration

Follow-up: [five Starfall route paintings](STARFALL_ROUTE_BACKDROPS.md) add 70
surfaces. The current implementation covers nine rooms / 135 surfaces with nine
distinct images. All six StarfallDescent routes now use this system. Starfall's
scene scale and mirrored sampling reduce magnification across the large bounds;
the other three profiles retain their original scale. The original four-asset
provenance below is retained.

RoomPaintedDepth.gd selects background silhouettes explicitly: entrance plates,
chambers, their connecting shafts and existing archive side chambers/lamp alcove.
Original polygon vertices, transforms, z order, collision, actors, doors and
interaction state are unchanged. All plates in one room share one UV space and
one ShaderMaterial, so intersecting chambers have continuous imagery rather than
restarting the painting at each floor. Images do not fill the unused rectangle
around an irregular room.

The forge previously drew background and platforms in a single _draw(). Its
opt-in painted_depth_enabled flag only suppresses those background fills; 13
new Polygon2D plates follow the exact seven gallery and six shaft shapes. The
existing FurnaceWall is the fourteenth plate. Other Ash rooms retain the old
renderer unchanged. Terrain, piers, hints and gameplay continue drawing.

room_depth.gdshader samples the far painting plus a subtle procedural haze
plane. Negative camera-relative UV offsets make both move more slowly than
the terrain, at different rates (0.08 and 0.025). Updates are capped at 20Hz;
hidden/inactive rooms do not update. Shared materials avoid per-plate uniform
writes. Camera canvas inversion handles zoom and separated editor room origins.
No TIME-based animation continues in inactive rooms.

## Validation and limits

room_painted_depth_smoke.gd now checks all 135 surfaces, exact continuous UV mapping,
texture imports/mipmaps, unchanged original geometry/transforms/visibility and
physics, two-axis camera movement, two zooms, translated room origins, hidden-room
sleep and build idempotence. Existing route, puzzle and door tests are also run.

preview_room_painted_depth.gd now captures close/wide views of all nine rooms plus
a camera-shifted Cistern view (19 images in ../characters/preview_room_depth_*).
The original four-room views and the new Starfall views were visually inspected.
The older flat pillars, machinery and terrain
remain provisional; the new paintings are deliberately subdued behind them.
This is not a claim that all rooms have new paintings or that visual work is done.

## Remaining rollout

- Shaft: Cistern and the [Driftworks expedition](DRIFTWORKS_ART.md) now have
  distinct paintings. Other dry excavation/mechanical shaft routes, flooded
  galleries and boss chamber still need related but distinct paintings/materials.
- Echo: grotto already has a pilot; remaining nest, tide and crystal routes need
  specific silhouettes and imagery rather than cloning the archive everywhere.
- Ash: forge now painted; causeway, barracks, reservoir, chapel and boss arena
  need individual environmental subjects and foreground materials.
- Starfall: all six StarfallDescent routes now painted. Empty Court and Hollow
  Throne received the separate [arena pass](STARFALL_ARENA_ART.md), and the
  [Broken Ramparts expedition](BROKEN_RAMPARTS_ART.md) is painted as well.
  The city's upper sky, boss bodies and other foreground props remain unfinished.
- Extend terrain facings/props and replace placeholder architecture gradually;
  retain readable collision edges, safe-town identity and mobile memory budgets.
- Validate each addition in its real room at gameplay zoom, including first-clear
  and replay encounters, not just on a standalone generated image.

## Exact prompts and source files

### cistern

Workspace: `art/visual_slice/cistern_depth_v1.png`

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-d8c00272-9b8a-4687-9448-f0caf0a31a61.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling game parallax background painting, opaque landscape 1536x1024. Hand-painted restrained dark fantasy, layered atmospheric depth, no 3D render. Entire image is DISTANT scenery, no playable foreground floor, no UI, text, letters, characters, enemies, doors indicating exits, logos or watermark. Keep contrasts low, small gentle highlights, details visible in dark midtones. Wide uninterrupted composition suited to cropping inside irregular chambers; avoid central hero object and black vignette. Subject: Drowned underground cistern: massive ancient damp stone reservoir arches receding into blue-green haze, partial submerged pillars and still blackwater reflections near lower edge, distant corroded pipes. Muted petrol blue and slate teal, sparse dim reflected cyan light. Quiet abandoned hydraulic infrastructure, no bright magical crystals.
```

### prism

Workspace: `art/visual_slice/prism_depth_v1.png`

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-e2207a01-27ef-41c2-9199-8b7ddff64335.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling game parallax background painting, opaque landscape 1536x1024. Hand-painted restrained dark fantasy, layered atmospheric depth, no 3D render. Entire image is DISTANT scenery, no playable foreground floor, no UI, text, letters, characters, enemies, doors indicating exits, logos or watermark. Keep contrasts low, small gentle highlights, details visible in dark midtones. Wide uninterrupted composition suited to cropping inside irregular chambers; avoid central hero object and black vignette. Subject: Subterranean prism archive: natural indigo cavern merging with old carved stone recesses holding small faceted mineral tablets, layered distant crystalline formations, subtle refracted turquoise and violet light in mist. Organic rock and scholarly vault architecture, not shelves of ordinary books, no readable glyphs, no enormous central crystal.
```

### forge

Workspace: `art/visual_slice/forge_depth_v1.png`

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-0a795291-8bd0-40d1-9e44-bfe252e449af.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling game parallax background painting, opaque landscape 1536x1024. Hand-painted restrained dark fantasy, layered atmospheric depth, no 3D render. Entire image is DISTANT scenery, no playable foreground floor, no UI, text, letters, characters, enemies, doors indicating exits, logos or watermark. Keep contrasts low, small gentle highlights, details visible in dark midtones. Wide uninterrupted composition suited to cropping inside irregular chambers; avoid central hero object and black vignette. Subject: Deep abandoned furnace hall: layered soot-dark brick furnace niches and iron ductwork disappearing through warm ash haze, distant cold anvils and hanging chains, very restrained ember orange glow within small kiln mouths. Dark umber, charcoal burgundy, weathered copper, no open foreground lava or fire hazard.
```

### memory

Workspace: `art/visual_slice/memory_depth_v1.png`

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-c1e17251-c9b6-4223-afe1-4558831533d2.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling game parallax background painting, opaque landscape 1536x1024. Hand-painted restrained dark fantasy, layered atmospheric depth, no 3D render. Entire image is DISTANT scenery, no playable foreground floor, no UI, text, letters, characters, enemies, doors indicating exits, logos or watermark. Keep contrasts low, small gentle highlights, details visible in dark midtones. Wide uninterrupted composition suited to cropping inside irregular chambers; avoid central hero object and black vignette. Subject: Starfall memory vault: long tiers of ancient pale stone niches and slender gothic archivolt arches, faint star-shaped ornamental inlays, translucent bluish haze, distant hanging silver threads and ruined archive architecture. Desaturated slate blue and dusty violet, faint cool pearl lights, quiet solemn moonless interior. No modern technology, no bright sci-fi circuitry.
```
