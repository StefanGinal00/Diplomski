# Ground contact and portal surroundings — 2026-09-30

## Cause and implemented changes

The opening floor really differed: the collider top was y=388 while its painted
top was y=390. Several atlas regions also contained transparent space below the
feet/base. Correct object origins alone therefore did not establish contact.

- `WorldSupport.gd` aligns matching rectangular material faces to collision
  corners in local coordinates. It preserves irregular authored silhouettes and
  does not move or resize existing collision shapes. 3,160 registered surfaces
  were checked across 39 distinct rooms.
- Player idle, walk, crouch/landing and attack frames now use measured opaque
  support pixels. Grounded crawler/grazer/fauna, compact enemy bodies and ranged
  sentinels receive equivalent frame registration. Airborne leg poses, flying
  moths/bats/wisps and hovering sentries retain their intentional presentation.
- Opening residents, field guides, checkpoint lamps, doors and lift terminals
  use actual supporting terrain. Only their rendered artwork moves: actor
  origins, patrol limits, interaction shapes, travel markers and save data do not.
  The all-room pass checked 204 visual contact registrations.
- Lift terminals have floor-supported timber gantries; their painted chains
  attach to the overhead beam instead of ending in open air. Pure decoration,
  with no added lift collision or transport authority.
- `PortalContextArt.gd` embeds all 112 existing doors in supported rock/mine or
  masonry recesses. Broad platforms get broader facades, narrow shelves get
  contained surrounds; foreground terrain can occlude the rear facade.
- 26 outer-edge StaticBody2D boundaries were added beyond the global room floor
  extents near endpoint doors. They intentionally change physical boundaries,
  unlike the visual-only contact correction. Internal ledge and side passages
  remain open. Automated checks reject overlap with door/arrival positions.
- Existing gate requirements, native E/click/tap handling, checkpoints, enemy
  persistence and transitions remain authoritative and are regression tested.

## Art and cost

Original three-part transparent atlas:
`art/visual_slice/portal_cliff_modules_v1.png` (1330 x 1182 source).
Built-in imagegen generation, copied unchanged; exact prompt and provenance in
`art/visual_slice/PORTAL_CONTEXT_PROMPT.md`. No third-party graphic downloaded.

One shared 1024-edge imported texture with mipmaps occupies 4,968,604 decoded
bytes. This is the new atlas only, not total game memory. Sprite contact metadata
is baked: the running game never reads image pixels to locate feet. Resident
support refresh shares the 0.12-second presentation tick and current-room floor
cache. The atlas does not create per-portal unique bitmap copies.

## Verification

See `tests/LATEST_SMOKE_RESULTS.md` for passing test folders. New checks:

- `ground_contact_assets_smoke.gd`: 106 baked contact rows independently checked
  against alpha in actual imported images; no source-image modification.
- `world_grounding_smoke.gd`: 39 rooms, 3,160 aligned faces, 204 contacts, 112
  contextualized passages and 26 boundaries; repeated entry remains idempotent;
  no actor/arrival transform mutation. Native gravity settles the player on the
  real opening floor, all grounded/attack poses touch it, walking into the east
  endpoint stays on the map, and jumping still works.
- Existing route, door interaction, lift, save/death and animation tests rerun.

Native D3D12 captures use `tests/preview_world_grounding.gd`. The player actually
settles via physics before capture. Frozen terrain explicitly retains collision
in this test harness (Godot's default process-disabled collision objects are
otherwise removed from physics). Captures live at
`art/characters/preview_grounding_*.png`; these are automatic checks, not a full
manual playthrough or a phone benchmark.

## Still open / not claimed complete

- Continuous playthrough and phone frame-time/total-memory measurement.
- Bespoke dressing and remaining prototype scenery across the complete world.
- Some generated-route destinations are very close together (e.g. Echo Nest's
  RimReturnDoor and SanctumDoor); their native placement has not been changed by
  this pass. Their distinct presentation/interaction spacing needs a focused
  routing pass rather than moving save/arrival points as a cosmetic shortcut.
- The originally reported intermittent saved-enemy respawn remains unconfirmed.
  Its focused regression passes; that alone does not establish the user's cause.
- This runtime finishing system improves F5/F6 camera views; the zoomed-out
  editor retains its authored overview instead of serializing thousands of
  generated cosmetic nodes into scenes.
