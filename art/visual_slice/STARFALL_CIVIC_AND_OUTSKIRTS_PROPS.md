# Starfall civic life and outskirts props — 2026-09-27

This pass extends beyond terrace architecture into two rooms. It uses native
2D draw geometry and the existing masonry bitmap; no new generated raster
assets, downloads or upscaling are involved.

## Implemented

- All 12 Hanging Gardens planters now use deterministic branched foliage,
  individual pointed leaves/veins and alternating silverleaf/green/flowering
  variants instead of circular canopy clusters. A shared StarfallBotany helper
  also supplies three nursery trays and sparse dry roadside plants.
- Four upper-city workplaces now have paper-lantern ribs/handles, stacked
  paper/tools, a banded water barrel, nursery trays, offering candles, and an
  instrument case/rolled chart beside the existing telescope. Their 23 old
  visible decorative polygon leaves are hidden; labels, telescope/tripod,
  residents and interactive landmarks are not retired.
- Outskirts has four slatted abandoned wagons with torn cloth/spoked wheels,
  plus six individual-stake barricades. These replace 14 named leaf polygons,
  not interactable crates or repair mechanisms. Decorative wheel bottoms
  were corrected up to the authored road top rather than sinking through it.
- All 28 authored Outskirts Identity ruin silhouettes reuse tiled Starfall
  masonry. The original outline, depth, transform and collision remain intact.

StarfallPropArt is attached only to StarfallCitadel and StarfallOutskirts.
It is static and sleeps with its room: no timers, actors, collision nodes,
new loot, task flags or save fields. City prop art sorts after facade ink at
z=-1, below gameplay, so windows do not draw on top of the workbench goods.

## Verification and limitations

starfall_prop_art_smoke compares original transforms, visibility, polygon
points and collision snapshots, requires four city workplaces, four wagons,
four wheel replacements, six barricades and the deep ruin materials. It also
checks idempotence and inactive-room hiding. Existing upper art, structure,
background, Outskirts route and Starfall dressing/state tests are retained.

Seven 1280x720 D3D12 captures completed with exit 0. Gardens, lantern workshop,
nursery and caravan views were inspected; a final material capture confirms
the ruin textures. Log: .tmp-starfall-props-material-final.log. Only the known
host certificate-store warning, no script/shader errors. Captures are staged
runtime views, not an editor UI session or manual traversal test.

Initial testing caught a misplaced scene script assignment and a typed-array
membership check in the new test; both were corrected before accepted runs.

Not complete final art: quest-device frames/markers, some repair-site props,
old awnings, enemy bodies and other zones still need their own passes. Do not
hide task-state visuals simply to remove their remaining basic shapes.
