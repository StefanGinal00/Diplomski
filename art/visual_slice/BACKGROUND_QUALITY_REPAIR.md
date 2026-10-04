# Background coverage and readability repair — 2026-09-27

This supersedes the 1024px cap and completion wording in the initial remaining
background rollout. The user's screenshots exposed three real integration
defects: opaque legacy entry scenery, a market-only panorama, and excessive
image magnification. Assigning a texture was not enough to prove visibility.

## Implemented

- RoomArtFinish.gd retires explicitly named, childless background polygons
  in entry scenes, the old generated mine piers, and embedded gate/ward
  background plates in Starfall Citadel. Nodes are hidden, not deleted.
  Real doors, hazards, lights, actors, NPC paths and collision stay unchanged.
- Full-world checks cover 33 painted profiles. Material treatment reaches
  2,179 visible horizontal terrain polygons (including generated Stone nodes,
  not just entry Visual nodes), with a thin readable collision-edge seam.
  The per-profile report has 316 retirement entries; some shared-room entries
  can be recorded twice, so this is not a unique deleted-node count.
- Three pressure cells now use existing iron texture, seam and rivets. Nine
  circular gauges have rim/needle detail. Seven gate/ward house/roof/arch
  surfaces and nine distant city towers now reuse masonry/roof materials.
- Superseded by CITY_BACKGROUND_UNIFICATION.md: the separate lower-city
  panorama has been removed entirely. One serialized sky covers x=0..6250
  and y=-1950..500; no market/upper-image blending remains. Original market,
  NPCs and walkways stay positioned.
- 33 background imports preserve their native 1536x1024 source detail with
  mipmaps (no invented 4K upscaling). World-space image repetition is limited
  to roughly 1800 units instead of stretching one 1024px image over an entire
  room. The city market image now also imports mipmaps.
- The shared depth shader no longer mirrors vertically: towers/aqueducts
  remain upright. Horizontal reflection is retained, and vertical repeat
  seams are softened. Camera-relative parallax and hidden-room sleep remain.

No new raster assets were generated or source images edited. This pass
reuses existing images and extends native Godot material/shader code.

## Verification

15/15 targeted tests passed (not the full 181-test suite).
See tests/LATEST_SMOKE_RESULTS.md for the final targeted test results.
New background_quality_smoke.gd checks full-world coverage, texture detail,
deep-floor materials, explicit entry occluders, city span/embedded backgrounds,
three pressure cells and the extra houses. Existing art tests still compare
original physics, transforms, z order and polygon points; only reported
decorative retirement is permitted to alter visibility.

preview_background_quality.gd captures eight targeted D3D12 Mobile views,
including the screenshots' initial Cistern / Outskirts spaces, entry-to-route
join, tank, market, west/east streets and whole city. Captures:
art/characters/preview_quality_<cistern_entry|cistern_join|cistern_tank|
outskirts_entry|city_market|city_west|city_east|city_full>.png.

An intermediate edit had an indentation parse error; it was corrected before
the accepted final run. Intermediate preview2 images were overwritten by
successful final captures. Final GPU log: .tmp-background-quality-final2.log.
The Cistern UV phase is offset so masonry, not the source water band, fills
the dry entrance; the last art/quality tests were rerun after this adjustment.
Known host certificate-store and denied shader-cache/editor-settings writes
must be distinguished from script or shader compilation failures.

## Still unfinished

This does not finish every model/asset. Some enemies, boss bodies, crystals,
interaction icons, entry landmarks and quest boards remain code-native
placeholders. Thin platforms now have a surface texture but still need
bespoke underside/edge artwork. Other decorative identities can be replaced
room-by-room without hiding puzzle information or changing collisions.

The larger texture imports trade memory for detail. They are a desktop
visual-quality choice, not a phone optimization claim. Texture streaming,
device-specific compression and profiling remain needed before mobile
release; actor population already has separate activation behavior.
