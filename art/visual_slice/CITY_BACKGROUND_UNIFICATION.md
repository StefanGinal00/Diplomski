# One Starfall city background — 2026-09-27

The previous repair still used two images: an upper sky plus a lower market
panorama. The user's next screenshot demonstrated why that was not a finished
integration. This change removes the lower painting rather than hiding its
boundary with another fade.

- StarfallCitadel/Sky is the only city painting: citadel_sky_depth_v1.png.
- Its texture, shader and UVs are serialized in StarfallCitadel.tscn, so the
  saved scene contains the full background before any tool script runs.
- RemainingRoomArt drives that same plate's camera response, not another
  image. VisualStyleSlice now handles facades, market and surface details
  only. It no longer loads city_backdrop.png or creates MarketSkyPainting.
- The city shader remains opaque, repeats horizontally and clamps vertically.
  It covers all districts from y=-1950 through y=500, with no separate band.
- Existing geometry, actors, routes, quests, save format and physics remain.

## Evidence

city_background_smoke.gd checks serialized state before tree entry, one owner
after initialization, repeated visits and idempotent collision-safe rebuilds.
background_quality_smoke.gd also rejects MarketSkyPainting in the full world.
Other targeted art/structure tests are recorded in LATEST_SMOKE_RESULTS.md.

The D3D12 runtime preview completed normally and captured eight views in
.tmp-single-city-runtime.log. City full/market captures were visually reviewed.
The editor-hint preview captured both standalone and combined-world contexts;
scene_whole and world_street were visually reviewed. The editor harness printed
its success marker but failed to exit before its 45-second watchdog and was
terminated. It also emitted editor current_window-null warnings. This is visual
capture evidence, NOT a clean editor-process test pass. No user's editor was
terminated. Captures: art/characters/preview_city_single_editor_*.png.

If an already-open Godot scene retains the old generated rectangle, reopen
that scene (or reload the project) after accepting these external changes.

This fixes background ownership, not all final game art. Source detail is
still 1536x1024; no upscaling or new raster generation is claimed. Large
support walls, platform undersides, some landmarks and gameplay placeholders
still need individually authored visual work and play-scale review.
