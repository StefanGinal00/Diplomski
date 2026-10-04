# Upper Starfall civic details — 2026-09-27

`StarfallUpperCityArt.gd` is an @tool static drawing layer created by
`StarfallUpperCity.gd` after its architecture/workplaces are built.

- 10 houses: corner masonry and cornices, 40 arched divided windows with sills,
  10 boarded residential doors with metal bands and handles.
- 12 existing street lamps: shaped caps, divided glass, soft static glow, feet.
- 12 garden planters: branched silverleaf/shrub/flowering variants and trimmed
  containers, replacing triangle foliage.
- Three hanging bells: shaped shoulders/rims, highlights and clappers.
- Observatory telescope: eyepiece, metal bands and glass detail.

No new raster images or external assets were used in this pass. The existing
Starfall masonry/roof images remain in use unchanged. This is 2D code-native
art; all 90 replaced original leaf polygons remain in the scene, hidden.
House facade/roof geometry, routes, collision, lamp gameplay, NPCs, quests,
rewards and streaming are unchanged. Residential doors remain non-interactive
scenery. Drawing uses one node with no children or per-frame processing;
it inherits room visibility and remains behind actors/labels and walkways.

GPU close-ups (960×540, zoom 1.2), generated and visually checked:

- `../characters/preview_starfall_upper_artisans.png`
- `../characters/preview_starfall_upper_gardens.png`
- `../characters/preview_starfall_upper_bells.png`
- `../characters/preview_starfall_upper_crown.png`

## Walkways and distant architecture

`StarfallUpperStructureArt.gd` adds two static depth-separated drawing nodes:

- 79 stair treads, four district terraces and one skybridge use stone joints,
  highlighted collision-top edges and metal end caps/inlays. The bridge has
  rivets and shallow eight-pixel brackets, not blocking railings.
- Four existing distant towers retain their silhouettes and get crown trim,
  star medallions, narrow facade accents and 136 arched windows. Most windows
  remain unlit, with occasional muted warm accents below foreground intensity.

220 original leaf plates are hidden, not deleted. Collision rectangles supply
walkway bounds. No actors, doors, markers, physics, silhouettes, or jump gaps
change. Walkways draw at depth -1 behind actors, distant details at -6. Both
nodes cache their draw commands and have no per-frame processing or children.
The test checks 79/4/1 surface coverage, exact collision alignment, 4/136 skyline
coverage, scoped visibility changes, original geometry/transforms/physics,
idempotence and hidden-room visibility.

The preview script now also captures `preview_starfall_upper_bridge.png` and
`preview_starfall_upper_skyline.png`; all six views were visually reviewed.

The large stair-backing silhouettes and several workplace props are still
provisional. These details are not completion of the city or maps.
The new smoke test checks exact coverage, original visibility scope, geometry,
transforms and physics, idempotence and hidden-room behavior. Existing tests
cover traversal, first ascent/lift unlocking, residents and field-office flow.
