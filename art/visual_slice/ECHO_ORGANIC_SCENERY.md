# Echo organic scenery - 2026-09-28

## Assets and generation

Generated with the built-in imagegen tool under the imagegen skill, one call per
asset. No CLI/API fallback, Blender, background-removal or scripted pixel edits.
Native RGBA images are retained; Godot imports enable mipmaps.

- [Mushrooms](echo_mushrooms_v1.png): 1358 x 1158, source region (258,112,873,927).
- [Mineral cluster](echo_mineral_cluster_v1.png): 887 x 1774, region (132,128,627,1548).

Both have actual transparent alpha, not a painted background. Regions trim empty
margins at render time; source files are not resized or modified.

## Integration

EchoSceneryArt replaces its old drawn mushroom/crystal silhouettes across grotto,
gallery, archive, tide, nest, causeway, vault and depths. Of 564 candidate anchors
(306 mushrooms / 258 minerals), 341 are rendered: 261 mushrooms and 80 minerals.
The other 223 are omitted for missing support, obstructions, crowding or masks.

Every visible cluster rests on an existing horizontal rectangular collider:
at most 140px horizontal / 12px vertical cosmetic repositioning, full-width
support, no intersecting collider or preceding cluster. Mushroom height is capped
at 29px, minerals at 100px, with uniform source proportions. Clipping uses the
existing chamber masks and corresponding source UVs, not stretched cutouts.

No new actors, collisions or per-prop nodes. The existing static drawing layer
remains behind gameplay. Original decoration nodes and level geometry remain
unmoved. Initial QA caught legacy mineral anchors over shafts; support checks now
skip them instead of drawing floating minerals.

Also corrected EchoGrazerAppearance's overly broad biome gate: only Mossling and
names ending in ' Grazer' receive the land-grazer sheet. Moths, bats, skimmers,
crawlers and newts retain their original art pending dedicated species artwork.
This does not alter their existing AI or movement.

## Validation

Six unique targeted smoke tests pass: organic scenery, scenery art, traversal,
room identity, painted props and grazer appearance. The new scenery test checks
alpha/mipmaps, support, obstacle clearance, clipping UVs, uniform scale, static
processing, idempotence and unchanged physics/shortcut state across eight routes.
The grazer test additionally rejects seven other Echo species and still exercises
real unload/recreation with native hostility and damage retained.

Eight GPU scenery views captured with an isolated save and frozen room fixtures;
reviewed for grounded placement, readable silhouettes and clipping. Preview exit
0 (.tmp-organic-preview.log); only the known root certificate warning. These are
visual fixtures, not a manual playthrough or Godot editor acceptance.

- [Grotto](../characters/preview_echo_scenery_grotto.png)
- [Gallery](../characters/preview_echo_scenery_gallery.png)
- [Archive](../characters/preview_echo_scenery_archive.png)
- [Tide](../characters/preview_echo_scenery_tide.png)
- [Causeway](../characters/preview_echo_scenery_causeway.png)
- [Vault](../characters/preview_echo_scenery_vault.png)
- [Nest](../characters/preview_echo_scenery_nest.png)
- [Depths](../characters/preview_echo_scenery_depths.png)

Remaining work: EchoShade silhouettes, species-specific small fauna, tiny grass
glyphs, root-room decorative polygons and other unfinished environmental shapes.
This pass does not complete all map artwork or replace all geometric objects.

## Exact generation prompts

### Mushrooms

Use case: stylized-concept. Asset type: transparent 2D environment sprite for a hand-painted dark fantasy cave platformer. One small asymmetrical cluster of three cave mushrooms, one taller broad gently domed cap and two smaller offset caps, slender curved ivory-gray stems joined on a very small flat grounded root base. Dusty muted blue-lilac caps, delicate radial gills visible underneath, irregular natural edges, subtle speckled matte surface, readable at 30 game pixels tall. Strict frontal side-scroller elevation, not isometric, entire cluster fully visible centered with generous transparent margins. Detailed painterly texture and gentle ambient light, no glow. Genuine transparent alpha around stems and under caps. No floor, no ground patch, no cast shadow, no halo, no fog, no background scene, no painted checkerboard, no text or border. Original natural organic design, not geometric umbrella shapes and not glossy 3D.

### Mineral cluster

Use case: stylized-concept. Asset type: transparent 2D scenery sprite for a hand-painted dark fantasy cave platformer. One narrow tall organic mineral cluster growing upright from a small rough gray stone base: a main irregular quartz-like prism, two shorter leaning side crystals and a few tiny fragments connected to the base. Height approximately twice width. Muted slate blue, dusty pale lavender and subtle gray-green translucent mineral colors, weathered fractured faces, cloudy mineral inclusions, chipped edges, restrained highlights. Natural asymmetry rather than identical perfect triangles. Strict frontal side-scroller elevation, not isometric, whole object centered and fully visible with transparent margins, base on a flat baseline. Matte painterly dark fantasy 2D texture, readable reduced to 35 pixels wide. Genuinely transparent alpha background. No broad floor, no external cast shadow, no glow or halo, no fog, no scene, no painted checkerboard, no text, no border or UI. Not a collectible icon, not a luminous magical object, not glossy 3D.
