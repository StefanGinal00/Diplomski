# Regional route readability - 2026-09-29

This pass extends the existing Echo sign-placement system to 126 captions in
18 Shaft, Ash and Starfall routes. Echo retains its existing 75-caption layout.
No room terrain, enemy counts, combat damage, encounter triggers or rewards change.

## Layout

- Captions stay in an authored chamber's upper space and avoid rectangular
  terrain, other route captions, operation boards and encounter headings.
- Local machinery and encounter boards that load on entry are included in the
  next deferred layout. Visibility at the time of room_changed is not used as
  an entry signal: the room can still be hidden before the director shows it.
- Small Ash shelter ledges have overhead stairs and cannot hold another large
  caption. Their captions are placed in the actual approach gallery and explicitly
  say CLIMB TO the shelter. This does not create imaginary room space.
- Outlines and a fixed text depth protect clues from opaque background/terrain art.
- Reflow runs on construction, relevant entry and text-size changes, not every
  frame. Existing Echo width stays unchanged; the other regions retain wider text.

## Accurate completion cues

Shaft high-niche boards now acknowledge collected caches. Ash return boards and
guides distinguish prerequisites, encounter readiness, an unclaimed reserve and
a claimed reserve. Starfall return boards and guide advice also distinguish
victory from collection. Echo Gallery/Archive guides acknowledge collected
discovery and return caches.

Localized encounters check sibling caches requiring their completion event:
REWARD CLAIMED is shown only when every linked cache has a saved receipt.
Unrelated caches cannot complete that cue; clearing a fight does not imply the
reward was collected. Late-added siblings are checked on deferred initialization.
This is presentation only: it never opens a cache or unlocks a gate.

## Checks and remaining work

The regional sign test checks all 126 captions before and after native room
population loads and after progress changes, plus repeat-layout stability,
chamber containment, lack of continuous reflow and unchanged physics.
Existing regional dressing tests cover NPC/prop behavior and save rollback.
Additional assertions cover native cache collection and multi-reward feedback.

Four automatically rendered close-ups were inspected: Shaft reserve, Forge
shelter approach, Reservoir cargo and Starfall return board. The first Reservoir
capture exposed a late-loaded board overlap, which was corrected and re-rendered.
The Compatibility renderer logged shader initialization errors on this host even
though all four PNG captures completed; this is not graphics-driver certification.

Still pending: full physical traversal and combat pacing across all rooms,
replacement of remaining prototype scenery, comprehensive text/furniture/actor
overlap review and final difficulty/economy balance. This is not a finished-map
declaration or a manual playthrough.
