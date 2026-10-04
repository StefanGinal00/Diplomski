# Resident conversation polish — 2026-09-26

This extends existing native vector residents, walking routes, interiors and
paired ambient dialogue. It does not add a new NPC population or new artwork.

- Stationary residents face their current partner or a nearby player. Only
  the speaker with a visible bubble gestures; the listener keeps a neutral arm.
- Player dialogue has priority over walking and entering a building. The talk
  prompt is hidden during dialogue and restored on close when appropriate.
- Social exchanges require both actors to be available. Hiding, moving apart,
  deleting a partner or deactivating a room cancels the paired exchange.
- Dead, hidden, freed or queued-for-deletion players no longer leave a resident
  stuck in a player-bound dialogue. Explicit unbound scripted pauses still work.
- Hidden/relocated residents clear stale stride history. Colliders, labels,
  routes, interaction reach, dialogue content and social timing are unchanged.

`tests/resident_conversation_smoke.gd` covers reciprocal acceptance, rejection,
speaker turns, facing, player priority, lifecycle cleanup, stale partner links,
interior pause, route continuation and collider/UI invariants. Eleven other
resident, settlement and restoration regressions also pass; see
`tests/LATEST_SMOKE_RESULTS.md`. This is not a full-suite or mobile result.

`tests/preview_resident_conversation.gd` freezes a real pair at Echo Haven's
authored meeting markers using an isolated save. Inspected D3D12 captures:

- [Opening line](preview_resident_opening.png)
- [Reply](preview_resident_reply.png)

The bubbles and speaker/listener gestures switch correctly. The staged view
also exposes existing crowding near the market: another resident overlaps
Calen, and some name labels overlap. That layout/nameplate work remains next;
these captures are not final settlement-art acceptance. No generated bitmap
asset was needed, and the blocked walk-sheet attempt remains unresolved.
