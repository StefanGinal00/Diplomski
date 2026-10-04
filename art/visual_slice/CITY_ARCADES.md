# City terrace and masonry pass — 2026-09-27

StarfallUpperStructureArt now replaces the four flat TerraceArches leaves
with shallow, open-bottom stone arcades. Their openings reveal the existing
single city sky: no second background or painted fake sky is added. The
artisan, garden, bell and observatory terraces have separate stone tints;
the garden has sparse trailing ivy below its walk. Existing Starfall masonry
is reused with tiled UVs on these arch spandrels, six staircase backings and
three bell-frame members. No new raster asset was generated or edited.

Four distant buildings receive recessed arched facade bays, paired pilasters
and stone sills, retaining their original outer silhouettes and windows.
All work is static draw/material detail. No collision objects, per-frame
processing, extra supports into lower routes, actor moves or save changes.
Walkable highlighted edges remain on the original 84 colliders (79 steps,
four terraces and the cross-city bridge). Only the four named childless
TerraceArches leaves join the existing explicit decorative replacement set.

## Verification

starfall_upper_structure_smoke checks four arcade bounds/district identities,
nine tiled masonry surfaces, all original polygon points/transforms/depths,
unchanged collision snapshots, one-way flags, inactive-room hiding and
idempotence. Related art, background and upper-city tests are recorded in
tests/LATEST_SMOKE_RESULTS.md.

preview_city_arcades.gd captures six 1280x720 D3D12 views in the combined
world: whole, artisan, garden, bells, crown and masonry. Files are named
art/characters/preview_city_arcades_*.png. This is staged visual inspection,
not a manual movement playtest. Remaining simplistic foliage, props and
district landmarks are still candidates for subsequent passes; this does
not mark all map art complete.
