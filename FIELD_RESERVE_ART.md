# Painted reserve markers - 2026-09-29

Three original transparent PNG assets replace the flat bodies of 18 existing
decorative reserve-status displays:

- Shaft: five weathered timber/iron survey reserves.
- Ash: six soot-dark iron and copper fortress reserves.
- Starfall: seven carved stone/silver archive reserves.

Sources are 1808 x 870, preserved with their generated alpha in
`art/visual_slice/shaft_reserve_v1.png`, `ash_reserve_v1.png` and
`starfall_reserve_v1.png`. Generation used the built-in image_gen tool through the
imagegen skill, not an API/CLI fallback. Exact prompts and saved paths are in
`art/visual_slice/RESERVE_PROMPTS.md`.

FieldReserveArt.gd uses atlas regions to exclude transparent margins without
rewriting the source images. Lossless texture import, alpha-border correction
and mipmaps support the much smaller in-game size. The visible width is 132px
and the artwork is foot-aligned to its existing site.

## Integration boundaries

These are decorative status markers, not extra interactive loot containers.
The existing actual reward caches, prompts and unlock conditions remain unchanged.
No new treasure, actors, colliders, enemy spawns or save fields are created.

The original controller-owned seals and latch stay in the scene: their positions
and scale fit the painted sockets (halved with the body in the gameplay-size
review), while their visibility and colors still follow
native progress and saved receipts. Only the flat backing polygon is hidden.
Missing/malformed site structure keeps its original presentation. Reattachment
is idempotent.

Shaft markers draw in front of background mine bracing but behind walkable
terrain; this layering was corrected after inspecting the first preview.
Route captions retain the preceding readability pass.

## Verification and limitations

The new smoke test checks all 18 markers, source resolution/alpha, imported
mipmaps, grounding, indicator alignment, no new collision, idempotence and live
progress changes. Existing regional dressing, sign-layout and exploration tests
cover save/streaming and reward compatibility separately.

Three in-engine close-ups were rendered and inspected. Source transparency was
also inspected directly. Host-only diagnostics included the known certificate
store error, Compatibility shader initialization messages, and denied editor
settings writes outside the workspace. An initial image-inspection launch using
the default user log failed before the script ran; subsequent diagnostics used
explicit workspace log files. The smoke checks use their existing isolated saves
and logs, not the real user save.

This does not complete all environment art or change combat pacing. Camp tents,
some braces/machinery, other prototype scenery and full room-by-room encounter
balance remain separate follow-up work.
