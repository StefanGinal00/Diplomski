# Echo and Starfall material batch — 2026-09-27

Four original images generated with built-in ImageGen (imagegen skill), one
call per material; no input images, API key, CLI fallback or external asset
library. All source PNGs copied unchanged into the project, with non-destructive
512px mipmapped Godot imports. Sources are 1254px square. Seamless edges were
requested, not mathematically guaranteed; in-game tiled use was reviewed.

## Integration

- Echo Haven: 57 existing floor/stair/balcony/nook polygons across the old
  court, UpperVillage and NewDistricts use the new stone/timber.
- Starfall Citadel: 27 original facade/roof polygons (including ten upper-city
  houses) plus six decorative textured polygons for three market buildings.
- TownMaterialExpansion applies static materials without changing original
  geometry, visibility, transforms or physics. Existing doors/windows remain.
- Market materials draw behind the original code-native facade details;
  the old grout pattern is skipped when new materials are present. Grotto's
  art path and texture-free market fallback remain available.
- No new building interiors, loot, interaction, actor positions or save fields.

Five staged GPU captures from tests/preview_town_materials.gd were reviewed
under art/characters/preview_town_material_*.png. Test coverage checks exact
surface counts, 512px mipmap imports, UVs, repeat mode, physics/transforms,
upper-city completeness and idempotence. This is a material pass, not final
world art or mobile profiling. Prototype Echo field-board layout, upper-city
backgrounds and other non-painted architecture remain follow-ups.

## Exact prompts and retained source paths

### echo_path_stone_v1

- Project asset: [echo_path_stone_v1.png](echo_path_stone_v1.png)
- Original: C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-71cb33e8-c4b6-45c7-83a9-be6118b757f8.png

```text
Use case: stylized-concept. Asset type: opaque tileable surface texture for a hand-painted 2D side-scrolling fantasy game. Square 1024x1024, straight-on orthographic flat material filling every pixel edge to edge. Crisp broad painted forms, restrained fine grain, soft even low-contrast lighting. Seamless repeating edges. Not a building, not a scene, not photorealistic, no 3D perspective, no text, no logo, no frame, no empty margins, no characters, no doors/windows, no ground/sky, no vignette. Cool blue-gray limestone paving in broad horizontal courses, worn rounded edges and narrow teal mineral seams, small restrained patches of moss. The front face of an inhabited cavern-town stone walkway; dark slate joints, readable at small game scale.
```

### echo_walk_timber_v1

- Project asset: [echo_walk_timber_v1.png](echo_walk_timber_v1.png)
- Original: C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-022c451d-8361-46e3-84eb-395d166b57aa.png

```text
Use case: stylized-concept. Asset type: opaque tileable surface texture for a hand-painted 2D side-scrolling fantasy game. Square 1024x1024, straight-on orthographic flat material filling every pixel edge to edge. Crisp broad painted forms, restrained fine grain, soft even low-contrast lighting. Seamless repeating edges. Not a building, not a scene, not photorealistic, no 3D perspective, no text, no logo, no frame, no empty margins, no characters, no doors/windows, no ground/sky, no vignette. Weathered dark blue-green timber planks in horizontal rows. Subtle teal stain, broad wood grain, small worn silver nailheads at spaced plank ends, no foliage. The front face of wooden walkways in a safe underground village. Muted teal, blue-black and desaturated jade.
```

### starfall_masonry_v1

- Project asset: [starfall_masonry_v1.png](starfall_masonry_v1.png)
- Original: C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-ffbd07ca-946c-4266-a453-2cf01d7aa6c2.png

```text
Use case: stylized-concept. Asset type: opaque tileable surface texture for a hand-painted 2D side-scrolling fantasy game. Square 1024x1024, straight-on orthographic flat material filling every pixel edge to edge. Crisp broad painted forms, restrained fine grain, soft even low-contrast lighting. Seamless repeating edges. Not a building, not a scene, not photorealistic, no 3D perspective, no text, no logo, no frame, no empty margins, no characters, no doors/windows, no ground/sky, no vignette. Elegant silver-gray limestone ashlar in orderly staggered rectangular courses, subtle lavender undertones and indigo mortar, occasional restrained weathered chisel lines. Warm-neutral highlights, broad clean blocks rather than rough cave rocks. An old peaceful fantasy citadel's civic architecture, not ruins.
```

### starfall_roof_tiles_v1

- Project asset: [starfall_roof_tiles_v1.png](starfall_roof_tiles_v1.png)
- Original: C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-f68cd959-e331-45ec-a4b7-3224b2d469c0.png

```text
Use case: stylized-concept. Asset type: opaque tileable surface texture for a hand-painted 2D side-scrolling fantasy game. Square 1024x1024, straight-on orthographic flat material filling every pixel edge to edge. Crisp broad painted forms, restrained fine grain, soft even low-contrast lighting. Seamless repeating edges. Not a building, not a scene, not photorealistic, no 3D perspective, no text, no logo, no frame, no empty margins, no characters, no doors/windows, no ground/sky, no vignette. Overlapping indigo and dusty violet slate roof tiles in orderly horizontal courses, broad slightly scalloped ends, restrained pale silver worn rims, no moss. Refined old fantasy citadel roofing, blue-hour palette. Roof surface only, no roof silhouette or ridge.
```
