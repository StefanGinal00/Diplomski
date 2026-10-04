# Echo camp and archive props - 2026-09-28

## Assets and generation

Created with the built-in imagegen tool, not the API/CLI. Original 2D raster artwork; no Blender/3D requirement. Accepted PNGs copied into the project:

- [Canvas shelter](echo_field_tent_v1.png): 1691 x 930, RGBA.
- [Field/reading desk](echo_field_desk_v1.png): 1774 x 887, RGBA.
- [Archive book cart](echo_book_cart_v1.png): 1702 x 924, RGBA.

True alpha verified in source and Godot imports. Full source resolution retained, mipmaps enabled, uniform AtlasTexture scaling; no scripted image alteration or chroma key.

## Integration

EchoPaintedProps now replaces 136 static props across eight Echo rooms: 11 mineral carts, five shelves, 105 ferns, six shelters, eight desks and one book cart. This pass adds 15 replacements to the previous 121. Archive cargo now contains books rather than ore. Small shelters fit below the 60-pixel raised walkway top, and desks render in front of bookcases while retaining their site's depth relative to actors. Field-table artwork is grounded at the site floor instead of the old floating 12-pixel baseline.

Only childless decorative leaves are hidden. NPC/loot spawns, collision, shortcuts, clues, streaming and save authority stay with existing controllers. No new checkpoint or safe zone is introduced.

## Verification and remaining limits

Later follow-up: [prop clearance](ECHO_PROP_CLEARANCE.md) fixes the audited
Grotto shelter and five Archive furniture/platform intersections mentioned
below. Historical screenshots/counts here describe the initial asset pass.

The painted-prop smoke checks all six textures, alpha, mipmaps, uniform scaling, anchors, coverage, desk draw order, shelter height, repeat builds, room re-entry, Ash exclusion and unchanged collision/flags. See tests/LATEST_SMOKE_RESULTS.md for accepted regression reports.

Ten D3D12 runtime captures were produced. The six new views (Grotto/Tide/Nest camps, Archive desk and book cart, Depths desk) were inspected. Visual review caught a desk hidden behind its bookcase and overly tall shelters; draw order and shelter scale were corrected. Existing thick foreground walkway art still occludes part of the Grotto shelter and some Archive furniture. That layout/art overlap is NOT resolved by this asset pass. Actors, oversized supporting silhouettes and text crowding remain unfinished. Full suite, manual traversal and editor acceptance are not claimed.

Editor imports completed, with the sandbox preventing global editor-settings writes outside the project. The known system certificate-store warning is unrelated to these local textures.

## Exact final prompts

### Canvas shelter

Use case: stylized-concept. Finished transparent PNG 2D environment sprite for an original dark fantasy side-scrolling cave game. One low broad expedition canvas shelter, about twice as wide as tall, patched desaturated slate teal cloth, visible seams, sagging fabric folds, weathered wooden poles, tied hemp cord close to the structure, dark open fabric entrance. Hand-painted richly textured 2D illustration with crisp readable silhouette and subtle upper-left ambient light. Strict frontal side-scroller elevation, level flat baseline, no isometric perspective. Entire shelter centered and fully visible with 8 percent transparent padding. No person, no lamp, no campfire, no separate props, no dirt or ground plane, no cast shadow outside the shelter, no glow, no text, no logo, no watermark. Genuinely transparent alpha background and empty holes; not a painted checkerboard. High resolution to reduce to roughly 200 by 110 game pixels. No glossy 3D render, no basic geometric placeholder.

### Field / reading desk

Use case: stylized-concept. Finished transparent PNG 2D environment sprite for a dark fantasy side-scrolling cave game. One compact battered wooden field desk with two sturdy trestle legs and a crossbrace, a low bundle of rolled parchment and one closed leather notebook resting on its tabletop. Wood grain, chipped edges, small oxidized brass fasteners, subdued brown and slate palette. Painterly hand-painted 2D game art with sharp readable silhouette, matte soft upper-left ambient light. Strict straight frontal elevation, no isometric view; horizontal desktop, feet on same flat baseline. Desk about twice as wide as tall including the papers. Whole object centered with transparent margins, high-resolution source readable at 90 to 135 pixels wide. Genuinely transparent alpha outside object and between legs. No floor or external shadow, no glow, no lantern, no character, no chair, no room background, no readable text, no watermark, no painted checkerboard.

### Archive book cart

Use case: stylized-concept. Finished transparent PNG 2D environment prop sprite for an original dark fantasy side-scrolling game. One small old wooden archive delivery cart filled with uneven stacks of worn muted lavender, ochre and gray leather books and tied parchment bundles, no crystals or ore. Two visible iron wheels on a common horizontal baseline, brown weathered planks, dark iron straps, a few brass rivets, frayed cord securing the stacks. Richly detailed hand-painted 2D illustration, matte soft upper-left ambient light, crisp readable silhouette. Strict straight side elevation, no isometric perspective and no ground plane. About twice as wide as tall. Whole cart centered fully visible, 8 percent transparent margin around all sides. Genuinely transparent alpha background including wheel openings; no shadow outside object, no fog, no glow, no scenery, no people, no readable text, no watermark, no painted checkerboard. High-resolution source to reduce to about 175 by 95 game pixels.
