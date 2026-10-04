# Side-room background coverage — 2026-09-28

The flat side-room rectangles were a real coverage omission: RoomPaintedDepth
selected main chamber/shaft masks, but skipped Branch*_Shadow and
Niche*_Alcove. Both authored mask families now use the room's existing image,
material and world-relative UV calculation. This adds 35 existing surfaces:
five in each of six Starfall routes and five in Blackwater Cistern. The nine
painted-depth profiles now cover 170 surfaces, previously 135. No new bitmap,
sky layer, collider or background polygon is created by this correction.

StarfallBranchArt adds static, shallow edge stones and small wall-side motifs
at 30 existing side floors. The six identities use rope coils, ward carvings,
archive shelves, foliage, pipe gauges or an unlit wall lantern. High niches
receive only shallow caps, not full-height frames. Thirty childless technical
labels (HIDDEN ALCOVE / DEAD-END CHAMBER) are hidden only in Starfall; actual
objective names, task instructions, status labels and rewards are untouched.
Cistern labels/landmarks remain unchanged in this pass.

## Verification

room_painted_depth_smoke requires exact new counts, shared material and
continuous UVs, preserved source image detail, camera response, inactive-room
sleep and unchanged physics/geometry. starfall_branch_art_smoke checks all
six themed sets, five masks per route, scoped label retirement, no gameplay
flag changes, no per-frame processing, idempotence and hidden-room visibility.
World background, task presentation, outer-route, inner-field and Cistern
tests provide the additional regression checks recorded in LATEST_SMOKE_RESULTS.

Eight 1280x720 staged D3D12 runtime captures completed with exit 0. Final
Rooted Hall/Cistern views were reviewed; initial Silent Gate/high-niche views
exposed oversized decorative frames, which were reduced before the final
capture. Log: .tmp-starfall-branch-final.log; only the known host certificate
store warning. The initial branch-art type-inference error was fixed before
accepted runs. No manual traversal or editor UI session in this pass.

The existing lightweight combined-world editor schematic may omit gameplay
branch floors. Branch art deliberately skips absent floors instead of
inventing a different editor-only layout. This does not remove that preview
limitation. Painting coverage applies whenever the authored masks exist.

Remaining work includes the large old biome identity silhouettes, ambient
labels/instruction layout and more bespoke room art. Source-image silhouettes
and branch geometry are unchanged; this is not a complete layout redesign or
a claim that every visual placeholder is finished.
