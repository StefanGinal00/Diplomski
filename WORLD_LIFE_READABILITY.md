# Environmental readability and living scenery — 2026-09-29

Follow-up to the gameplay screenshot report. This is an implemented pass, not a
claim that every map, actor, background or phone build is finished.

## Implemented

- The Crown Flywheel is decorative machinery, not a damaging obstacle. Replace
  its cyan outline/spokes with a bearing and independently turning iron wheel.
  Fit machinery beneath real overhead terrain; keep it behind actors. Drift
  pump stores/register/manifold and both interactive pump controls also use art.
  Native pump activation, partial repair persistence and reward gating are intact.
- Environmental danger reads its existing controller, collision footprint and
  timing. Steam, surge/current, fire, soul, rockfall and thorn effects use 24
  distinct generated frames (four per six visual families; current reuses water).
  Idle physical sources, low warning emissions, full active bursts and quiet
  disabled sources replace flat glow fills. Dashed endpoints mark the damage
  footprint, not a decorative platform. Currents remain nonlethal and show drift
  arrows rather than a damage caption. Warning lettering is not horizontally
  squashed when native hazard geometry is scaled.
- 290 notices across 39 distinct rooms are available through one nearby
  **G / clickable Read** prompt. The reading panel pauses gameplay; G/Esc/Close
  releases only the pause it owns. E is still reserved for doors/pumps/NPCs.
  Original labels remain as live authoritative text sources, but are not drawn
  over the world. This includes combined title+body RouteClues, work orders,
  survey/route boards and expedition chamber signs. Quest rewards/flags are not
  changed by reading. Revisit refresh discards freed sources and finds replacements.
- Regional green ivy, dry roots and silver vines sway gently from top anchors.
  One coordinator chooses on-camera objects in the current room: maximum 18
  decorative animations at 20 Hz, or 8 at 10 Hz in low-cost mode. Offscreen props
  remain static; previous-room props stop. Native danger warnings are independent
  of this decorative budget and are not discarded by low-cost mode.
- One behind-terrain air layer adds 18/8 subtle drifting motes, regional cinder/
  cool dust colors and a nearer parallax speed. Existing camera-covering paint
  retains 24% horizontal / 18% vertical parallax, with slowly moving seam haze.
  No extra full-screen bitmap copies, physics particles or per-vine timers.
- 222 grounded fern/fungus/mineral props replace the remaining expedition
  Flora/RouteCrystal silhouettes in Driftworks, Emberspine and Ramparts. Placement
  checks floor support, nearby geometry and overlap; static drawing is grouped
  by shared texture. Echo retains its already-painted scenery. No colliders,
  doors, enemies or loot were moved by this nature pass.

## Resources and performance boundary

Five new PNG atlases, generated using **built-in imagegen**; exact prompts,
originals and saved paths: [WORLD_LIFE_PROMPTS.md](art/visual_slice/WORLD_LIFE_PROMPTS.md).
The machinery/vines sources are 1536×1024; three effect sources are 1774×887.
Native frame selection uses normalized atlas regions, including individually
audited thorn/rockfall crops so neighboring rows do not leak into a frame.

Imports cap these small prop/effect atlases at 1024 px with mipmaps and alpha.
The originals are unchanged. Combined decoded import data is **15,836,060 bytes
(~15.1 MiB)**. This is not total game RAM/VRAM or a phone frame-rate measurement.
Low-cost ambience defaults on for the mobile feature tag and can be forced with
the project setting `world/ambient/low_cost`; no new graphics-settings UI yet.

## Verification

Three new automated tests cover native effect phases/geometry, distinct frames,
hidden legacy visuals, readable sources/replacement/revisit/death/distance/pause,
640×360 and 360×640 panel fit, animation caps and the five-atlas import budget.
Existing machinery, quest/return, story, checkpoint, terrain, damage/range and
streaming tests are rerun; final report folders are in `tests/LATEST_SMOKE_RESULTS.md`.
No user save is used or changed by these tests.

`tests/preview_world_life.gd` produces 13 real D3D12 Camera2D captures at native
zoom: flywheel, reading panel, four steam phases, five other damage effects and
two wall-vine moments. Images are `art/characters/preview_worldlife_*.png`.
The five cross-family comparison effects are explicitly staged native scenes in
the Drift camera fixture, not new placements in the shipped map. Actors are
frozen for framing; this is not a continuous manual playthrough.

Final native preview log: `_tmp_worldlife_preview_final.log`. Final import log:
`_tmp_worldlife_final_import.log`. Known host certificate-store and sandbox
shader-cache/editor-settings write messages are separate from project script
errors. No claim of Compatibility/OpenGL or mobile-device verification.

## Still open / next

- Reproduce the user's particular opening-mob respawn sequence. Current isolated
  regressions pass, but that does not establish the root cause or close the report.
- Continue native-camera audits of other custom mechanisms, resident bodies,
  decorative silhouettes and region-specific entrances. Not every object has
  bespoke art yet, and map-wide visual completion remains open.
- Review full motion/combat pacing and readability during actual traversal;
  automated fixed-camera captures cannot substitute for that.
- Profile complete loaded texture sets, draw calls, memory peaks and frame times
  on an actual phone, then finish touch UI/graphics controls and mobile exports.
  More/high-resolution bitmaps should follow measured budgets, not unlimited
  simultaneous texture loading.
