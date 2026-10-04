# Gameplay review assets

Generated with built-in imagegen; original alpha preserved. NPC sprite regions and equipment atlas crops are native AtlasTexture resources, not destructive image edits.

## `art/characters/opening_residents_v1.png`

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-db1b33c5-db18-48bb-a359-db4b3e15da32.png`

Use case: stylized-concept. Asset type: production 2D side-scrolling dark fantasy character sprite atlas, genuinely transparent background. Make one wide sheet with EXACTLY THREE equal-width columns, one full-body person per column, aligned feet on same baseline, generous transparent separation, no overlap. Left: Orin, stocky middle-aged itinerant merchant, mustard hood, purple-brown patched long coat, leather satchel, small rolled map. Middle: Eldric, elderly gentle caretaker, gray beard, moss green coat and weathered cream scarf, holds a small brass lantern. Right: Deren, lean ore surveyor, dark short hair, teal mining jacket with gray apron, measuring rod and small belt pouch. All grounded human proportions, 3/4 side view facing right, relaxed standing poses, boots fully visible, painterly clean hand-inked edges, detailed cloth and metal, muted blue-green cavern ambient light, readable silhouettes at tiny game scale. This is game-ready flat 2D illustration not 3D, not pixel art, no portrait framing. Transparent alpha, no ground plane or backdrop, no text, no labels, no borders, no watermark. High resolution 2400x1200 requested. Keep every figure entirely within its column, no fragments outside the cells.

## `art/visual_slice/cavern_dressing_atlas_v1.png`

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-3edcba79-c583-4af9-a4c7-ece9134732fd.png`

Use case: stylized-concept. Asset type: production 2D side-scrolling cavern prop atlas on genuinely transparent background. EXACT 3 columns x 2 rows of equal cells, every object wholly inside its cell with transparent margin and no overlap. Top left: mossy broken masonry tunnel arch with pitch-black interior opening, three-quarter shallow depth, no door leaf, no neon outline. Top middle: abandoned timber mine tunnel entrance with rock rim and dark opening, hanging tiny amber lantern. Top right: ornate small checkpoint lantern on a short stone pedestal, brass hood and warm teal glass, feet at bottom. Bottom left: compact wooden mine lift platform with iron brackets and two short hanging chains, no shaft backdrop. Bottom middle: irregular horizontally wide rocky ledge lip with dangling roots, small moss and tiny grass, visible rugged underside, suitable for dressing floor edge. Bottom right: long hanging ivy/vine cluster with dark chipped rocks at attachment point. Muted charcoal teal slate, restrained warm brass, painterly hand-inked detailed 2D game illustration, not pixel art, not 3D, consistent frontal side-view platform-game perspective. No scenery background, no text, no labels, no border, no watermark, no characters, no ground plane. High resolution 2400x1600 requested. Dark interiors of entrances opaque; outside each object truly transparent alpha.

The generated prop layout is not a perfect grid. Consumers use explicit non-overlapping rectangles rather than a regular grid. Alpha samples in the gaps are zero. Material scale and actual gameplay framing must be verified in Godot.

## `art/visual_slice/pickups_hazard_atlas_v1.png`

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-c56bfb03-d742-45e7-ba46-f59c681bb61b.png`

Use case: stylized-concept. Asset type: 2D dark fantasy platform game pickup and hazard sprite atlas. A single wide transparent PNG sheet, four equal-width cells in ONE horizontal row, completely isolated objects with generous alpha margins and no overlap. Cell 1: a small luminous cyan-blue essence wisp containing a warm golden spark, shaped like a delicately curling flame, no geometric gem. Cell 2: a red and golden healing flower with green leaves and a short mossy root base. Cell 3: a compact cluster of three naturally fractured pale turquoise ore crystals with dark stone base, no perfect polygons. Cell 4: a short horizontal row of five menacing rusted iron spikes set in a battered dark metal base, with sharp irregular points and lightly worn reddish tips, gameplay hazard clearly recognizable. Painterly 2D side-view hand-inked detail matching dark mossy caves; readable at small scale. Real transparent alpha outside each object, no scenery, no background gradient, no text, no numbers, no border, no watermark, no cast shadow outside each object. Requested resolution 2400x800. All four objects entirely within separate equal cells; no bleed across cells.

Actual delivered dimensions (not requested dimensions): residents 1774 x 887;
cavern dressing 1536 x 1024; pickups/hazards 2172 x 724. All three use lossless
imports with mipmaps. The atlas regions and in-game sizes were reviewed in
native Camera2D D3D12 captures; source PNGs remain unmodified.

## `art/visual_slice/loot_tokens_atlas_v1.png`

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-33ded88c-db7f-4df0-8cf4-ecf7623ca458.png`

Use case: stylized-concept. Asset type: high-resolution 2D dark fantasy platformer collectible sprite atlas. ONE wide sheet, three equal-width cells in a single row, isolated cutouts on genuinely transparent alpha background. Left cell: small stack of weathered golden coins with one upright coin, engraved sun motif, warm highlights. Middle cell: an ancient circular bronze-and-silver quest sigil medallion, four carved prongs around a small violet crystal center, physically detailed aged metal, no letters. Right cell: a small closed leather supply pouch, twine fastening and weathered blue-gray cloth flap, tiny brass buckle, no loose objects around it. Front/three-quarter view, painterly hand-inked 2D game art, not pixel art, not 3D, crisp readable silhouettes for small in-game items, muted mossy-cavern palette. All objects centered, same visual height, generous empty alpha margins; each wholly inside its cell, no overlap. No backdrop, scenery, floor, cast shadow, labels, text, border or watermark. Requested size 2400x800.

Delivered 2172 x 724, original transparent alpha, lossless import with mipmaps.
Used for gold, quest sigils and packaged generic item drops. Herb/material
pickups use their own flower/mineral cells from the preceding atlas. Generated
with the same built-in imagegen mode; no API/CLI fallback.
