# World structure artwork and prompts - 2026-09-30

Mode: built-in imagegen, original 2D raster generation plus one background-extraction edit. No CLI/API fallback and no third-party graphics downloaded in this pass. All final PNG files were copied unchanged into the project with their generated alpha preserved.

## Saved deliverables

| Asset | Saved path | Actual source resolution | Godot maximum edge |
| --- | --- | --- | --- |
| Passage facades | [passage_facades_v1.png](passage_facades_v1.png) | 2172 x 724 | 2048 px |
| Lift mechanisms | [lift_mechanisms_v1.png](lift_mechanisms_v1.png) | 1254 x 1254 | 1024 px |
| Ledge supports | [ledge_supports_v1.png](ledge_supports_v1.png) | 1536 x 1024 | 1024 px |

All paths above are relative to `art/visual_slice/`. Godot uses mipmaps and shared AtlasTexture crops with uniform scale. Source dimensions are measured outputs, not claims that the tool fulfilled requested dimensions. The three imported atlases total **16,763,580 decoded bytes including mipmaps** in the desktop test; this is additional texture data, not total game memory or a phone performance measurement.

## Generation sources

Source directory: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/`.

- Passage facades: `exec-4aeafcc5-b791-43ea-b18c-e5d3bf967797.png` -> `art/visual_slice/passage_facades_v1.png`.
- Lift mechanisms: `exec-01490546-baf2-450c-b89b-04fe03d1ea34.png` -> `art/visual_slice/lift_mechanisms_v1.png`.
- Ledge supports: `exec-5719f355-227d-4d0e-abae-8c72cfb8d69b.png` -> `art/visual_slice/ledge_supports_v1.png`.

The initial ledge-support generation (`exec-daf096f5-bedb-414e-be4a-5f8409a1aad9.png`) was superseded by the alpha cleanup edit below. It is not referenced by the project.

## Exact generation prompt set

### Passage facades

Use case: stylized-concept. Original production 2D side-scrolling dark fantasy game sprite atlas. TRUE TRANSPARENT ALPHA outside objects. 3072x1024 landscape requested, three separate equal 1024x1024 columns with 40px transparent gutters and canvas margins. Each column is a single substantial wide facade with a small walk-in dark passage at bottom center, NOT a freestanding arch: rock or masonry extends 3 door widths around and above the opening. Front orthographic elevation, painterly detailed realistic materials, no perspective ground plane. Column 1: damp blue-gray cave cliff, craggy strata and roots, mine passage reinforced with aged timber, restrained amber oil lantern. Column 2: burned ochre fortress wall, irregular layered brick and dark basalt, small arched doorway with riveted iron lintel, soot and muted ember marks, NOT glowing portal. Column 3: cool ivory-gray ruined cathedral wall, buttress stones and chipped gothic relief, small recessed pointed-arch doorway, sparse silver-green ivy. All three facades have a level bottom contact line, organic stepped edges at sides and top to blend into larger terrain. The passage interior is opaque almost-black, not transparent; the exterior surrounding canvas is transparent. Whole facades fully visible and not touching neighboring cells. Door opening at EXACT horizontal center of each cell, passage floor at same bottom level as wall. No labels, lettering, characters, skies, mountains or cast shadows outside the sprites. Crisp silhouettes and readable medium-scale material detail. Original art only.

### Lift mechanisms

Use case: stylized-concept. Original 2D dark fantasy side-scroller machinery sprite atlas on genuine TRANSPARENT ALPHA. Requested 1536x1536, exactly 2x2 evenly spaced cells, every object isolated with generous transparent gutters. Front orthographic view, hand-painted detailed weathered materials, readable functional engineering, no 3D perspective. Top left: ONE stout wooden and iron mine hoist HEAD ASSEMBLY, a broad horizontal timber crossbeam on short angled braces, two obvious metal pulley wheels at one-quarter and three-quarter span with axle bearings, a small winch drum/crank. No cables dangling downward beyond the head. Top right: ONE wide low suspended wooden LIFT DECK, flat horizontal board top and riveted dark iron fascia beneath, chain sockets at left and right edges, no chains above it. Bottom left: ONE matching stone-and-bronze gothic hoist HEAD ASSEMBLY with two pulleys and short braces, same broad proportions and pulley positions. Bottom right: ONE matching low iron-and-stone LIFT DECK with flat top and two edge chain sockets, same broad low proportions. Head assemblies approximately 3 times wider than tall; decks approximately 5 times wider than tall. Muted slate, aged brown wood, tarnished bronze, silver iron. Tiny restrained cyan inlay on gothic mechanism only. No people, hanging standalone chain columns, ground, background, text, arrows, labels or logos. These parts will be connected by real game-drawn suspension cables and anchored to level geometry.

### Ledge supports

Use case: stylized-concept. Original 2D side-scrolling dark fantasy environment support sprite atlas on true TRANSPARENT ALPHA. Requested 1536x1024, exactly three equal vertical columns, every piece isolated with clear transparent gutters. All objects front-on orthographic elevation, detailed hand-painted materials and readable silhouettes. Each cell contains ONE broad, roughly triangular downward-pointing UNDER-LEDGE SUPPORT MASS: flat wide top edge, substantial thick body narrowing toward bottom, NOT a floating island with grass, NOT an upright mountain. Left: irregular damp blue-gray fractured rock with roots and a few moss patches; layered overhang, visible erosion and crags under a flat cut stone top. Middle: a pair of heavy aged timber diagonal braces with bolts anchored into a rough dark rock corbel, supporting one horizontal timber beam across top, rusted metal bands. Right: carved pale-gray ruined gothic masonry corbel with worn recessed stone arch motif and chipped block edges, sparse ivy at outer edges. Leave large transparent space around full silhouettes. No doors, characters, scenery, dirt ground plane, labels, text, logos or lighting beams. Crisp alpha edge, material detail that reads at small gameplay sizes. These are modular underside brackets used to connect small elevated ledges to rock faces and load-bearing walls.

### Ledge support edit: final alpha cleanup

Use case: background-extraction. Edit target: attached three-piece 2D ledge support atlas. Change ONLY the background/alpha outside the three material objects: remove ALL soft brown/green/gray haze, diffuse shadows and blurred color clouds between and around the supports. Make ALL exterior space fully transparent alpha, including under the triangular supports and between the three pieces. Keep the three rock/wood/gothic objects exactly the same, same pixel positions, proportions, colors, internal detail and moss/root fine edges. Do not resize, crop, relight or rearrange them. No added elements. Clean isolated game sprite cutouts with no cast shadow or glow.

## Integration and checks

`StructureAtlas.gd` contains bounded facade/hoist regions and baked opaque contact rows. `LedgeSupportArt.gd` contains measured support bounds. Atlas crops preserve source pixels; no external raster postprocessing was used. Independent raw-alpha inspection and native D3D12 captures check cutouts, ground contact and layering. Facades remain behind player/checkpoint artwork. Hoist cables connect the painted pulley bearings to deck sockets; textured load posts terminate on the actual platform. The new art does not simulate a physical elevator ride or change native transport, gates or saves.
