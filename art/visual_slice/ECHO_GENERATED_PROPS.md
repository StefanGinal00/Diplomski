# Generated Echo prop assets — 2026-09-28

Created with the built-in imagegen tool (not the API/CLI). Original 2D PNG artwork; no 3D models or Blender dependency. Project-bound outputs are copied into art/visual_slice, never loaded from the generation cache.

## Accepted assets

- `echo_cargo_cart_v1.png`: 1672×941 RGBA, crystal-loaded timber/iron cart.
- `echo_archive_shelf_v1.png`: 1586×992 RGBA, three-tier archive shelf.
- `echo_cave_fern_v1.png`: 1484×1060 RGBA, matte cave fern.

Full source resolution is retained; Godot mipmaps and linear filtering are enabled. The renderer uses atlas regions and uniform scale without rewriting the PNGs. Alpha was checked in the source and imported images. Discarded fern glow/checkerboard variants are not referenced by the project. No manual chroma-key or background removal was used.

## Integration

Follow-up: [Echo camp props](ECHO_CAMP_PROPS.md) adds shelters, desks and a
dedicated book-delivery cart, bringing current coverage to 136. The counts
and pending archive-cargo note below describe this original 121-prop pass.

EchoPaintedProps.gd replaces 121 leaf-only placeholder props: 11 carts, 5 shelves and 105 ferns across eight explicitly named Echo rooms. Archive book-delivery carts remain unchanged: the new cart carries ore, not books. Rails, clue text, reading desks, devices, threats and loot-bearing crates remain owned by their existing systems. Each sprite retains a bottom-center foot anchor and uniform scale. The component is static and repeat installation does not duplicate sprites. Missing textures preserve the old artwork. Room-name allowlisting prevents the Ash route also called causeway from receiving Echo art.

## Visual review and limits

Four runtime captures were inspected: Echo Nest cargo, Prism Archive shelves, Tide Well ferns and Echo Depths shelves. They show actual alpha compositing, not concept mockups. Existing foreground platforms still pass in front of some background props; their old anchor sites/topology have not been redesigned. Actor placeholders, oversized foundation silhouettes, other field equipment, archive cargo and old label overlap remain unfinished. This is not complete-map art, full-suite, manual traversal or editor acceptance.

Editor import completed; the sandbox prevented saving global Godot editor settings, without preventing project texture imports. Runtime checks are recorded in tests/LATEST_SMOKE_RESULTS.md.

## Final prompts (verbatim)

### Cart

Use case: stylized-concept. Asset type: finished transparent PNG environment prop sprite for an original dark fantasy 2D side-scrolling game, NOT a concept scene. Subject: one battered wooden mineral cart loaded with a few weathered blue-gray crystal chunks; iron straps, rivets, two visible small iron wheels resting on exactly the same horizontal baseline. Strict straight side elevation, parallel horizontal edges, no isometric view, no perspective floor. Painterly hand-painted 2D game art with rich wood grain, chipped oxidized metal, sharp readable silhouette, subdued teal and slate with warm desaturated brown planks. Soft upper-left light, no bloom. Cart is twice as wide as tall. Entire cart and load centered and fully visible, fills about 85 percent canvas width, transparent margin on every side. Genuinely transparent background with alpha including around spokes, no ground patch or cast shadow outside object, no scenery, no people, no UI, no text, no watermark. Detailed high-resolution source, readable when reduced to about 170 by 95 game pixels. This replaces a basic polygon cart in a cavern game.

### Shelf

Use case: stylized-concept. Asset type: finished transparent PNG environment prop sprite for an original dark fantasy 2D side-scrolling game, NOT a scene or concept sheet. Subject: one old archive bookcase, broad squat three-tier dark wooden shelves containing irregular muted lavender, ochre and slate leather books, tied parchment bundles and a few rolled scrolls. Aged wood grain, worn brass brackets, uneven bindings; handcrafted believable detail. Straight-on orthographic front elevation, flat frontal shelves, NO isometric camera and no perspective floor. Painterly hand-painted 2D game art, subdued dusty purple/blue-gray shadows and muted brown wood, soft upper-left light, no bloom. Wider than tall, about 1.6 to 1 aspect. All legs on same baseline. Entire object centered fully visible with clear transparent margin on all sides. Genuinely transparent background alpha including empty spaces between shelf supports, no wall or backdrop, no floor shadow, no people, no UI, no letters readable on books, no watermark. High-resolution source readable reduced to roughly 240 by 150 game pixels.

### Fern (accepted regeneration)

Use case: stylized-concept. Create one finished hand-painted 2D game sprite of a small natural cave fern: five curving feathered fronds, muted dusty blue-green leaves with visible veins, aged moss-green stems, narrow root base. Side-view flat illustration for a dark fantasy platform game. Organic botanical detail, not geometric shapes, not a vector icon. Centered complete plant on a genuinely TRANSPARENT background with alpha channel. The fern is not glowing: NO light emission, NO haze, NO aura, NO ground, NO shadow, NO painted checkerboard or background of any color. No text, no labels. Soft matte ambient lighting only, fine crisp leaf edges and transparent holes between fronds. Entire plant visible with 10 percent empty transparent margin. Slightly wider than tall. High resolution source to scale down to 45 pixels tall.

## Discarded iterations

The first fern had an excessive diffuse aura; two edit attempts produced opaque checkerboard backgrounds. They were rejected. A fresh built-in generation produced the accepted alpha sprite above.
