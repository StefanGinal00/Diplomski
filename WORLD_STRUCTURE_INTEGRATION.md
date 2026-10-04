# World structures: entrances and lift terminals - 2026-09-30

This follows the user's instruction to treat screenshots as examples of systemic
problems, not to fix only the pictured locations. This is a completed shared
structure pass, **not final world-art, continuous playthrough or phone sign-off**.

## Implemented

- All 112 native passages across 39 distinct rooms now use a complete regional
  facade: damp timber-braced rock, scorched fortress masonry or gothic ruins.
  The atlas replaces the isolated doorway picture without changing its native
  interaction, arrival marker, lock, reward or save authority.
- Facades attach to surveyed geometry: 53 use nearby walls, 46 use a lower
  floor, and 13 use their existing floor foundation. Textured rear connections
  and separate underside corbels add depth. The previous pass's 26 physical
  endpoint boundaries remain unchanged; no new collider is added in this pass.
- All 40 native lift terminals now have a painted winch/pulleys, connected
  suspension, load-bearing posts, a low deck and an underside support tied to
  surveyed terrain. Post feet stay within their actual floor. The walkable deck
  top, not its bottom fascia, aligns with the native floor surface.
- Lift machinery gives slight feedback during accepted transport. Travel itself
  remains the native fade/teleport and shortcut system, **not an animated moving
  elevator ride**. Destination groups, prerequisites and saved shortcuts survive.
- Facades render behind nearby lamps, residents and player artwork. Device
  status captions use nearest-device focus (at most one within 100 world units),
  while native E/click/tap prompts and lock checks remain intact.
- Reentry is idempotent. Moving a doorway refreshes its decorative terrain
  connection without moving the native area. Late native devices in an already
  finished room automatically receive presentation after their initialization;
  one deferred coalesced refresh replaces per-frame world rescanning.

## Verification

Nine unique focused tests have passing final runs in this pass. Exact reports
are listed in `tests/LATEST_SMOKE_RESULTS.md`: structures, grounding, gameplay
review, native door interaction, routes, shaft return lifts, checkpoint
regression, readable notes and ambience.

The new structure test traverses all 39 rooms / 112 facades / 40 hoists, checks
anchors, post feet, rope endpoints, actual destinations, uniform scaling,
facade/lamp draw order, idempotence and automatically dressed late devices.
It also repositions a test door and verifies that presentation leaves its
native transform untouched. Tests use isolated workspace saves, not user saves.

Eight D3D12 captures in `art/characters/preview_grounding_*.png` cover the lamp,
opening exit, camp, shaft gate, side passage, lift, Ash gate and Starfall return.
All settle the player through real gravity before capture. The final log is
`.tmp-structure-preview-final.log`. These are controlled automatic captures,
not continuous manual exploration.

The first structure check found a lift post one pixel beyond its platform edge
and stale references after rebuilding a decorative surround; both were repaired
and tests repeated. Preview inspection also found a facade covering a nearby
lamp; the corrected rear layer is checked by the regression. Known host
certificate-store warnings remain; final smoke runs contain no script errors.

## Artwork / resource bounds

Three original PNG atlases were generated through the built-in imagegen skill,
then integrated as shared uniformly scaled AtlasTexture regions. Actual source
sizes, saved paths, exact prompts and source provenance are in
`art/visual_slice/WORLD_STRUCTURE_PROMPTS.md`. Godot imports use mipmaps and
2048/1024/1024 maximum edges. The three atlases together account for 16,763,580
decoded bytes including mipmaps in the desktop test. This is **not** the total
game/GPU memory footprint and does not establish performance on phones.

## Still open / next work

- Neighboring authored entrances in Echo Nest / Rim Return / Sanctum and other
  close pairs need placement/readability review, not just a common facade.
- Some old geometric scenery and custom mechanisms are still visible, including
  the decorative wedge near the Hollow lift. Do not equate these structure counts
  with replacement of every prototype object or support of every ordinary ledge.
- Facade/platform intersections and ordinary thin rectangular platforms still
  need room-specific composition work; regional atlas coverage is not enough to
  establish a natural silhouette for every camera position.
- The original intermittent saved-enemy respawn is still unconfirmed. Its focused
  regression passes, but this cosmetic pass is not a root-cause fix.
- Full-route combat/traversal, mobile memory/frame-time measurement and mobile
  controls remain separate unfinished milestones.

Restart the running game from Godot (stop, then F5) to load the changed scripts
and imported assets; this note does not assume that an earlier screenshot was
necessarily from a stale run.
