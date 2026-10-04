# Echo field-clue readability - 2026-09-28

EchoFieldSignLayout presents 75 existing RouteClue labels in eight explicitly
scoped Echo rooms. This is a code-native typography/layout pass, not new
generated artwork. All clue strings remain owned by their existing controllers.

## Behavior

- A stable grid search finds a nearby position within the rectangular headroom
  band of the clue's authored chamber. Narrow chambers constrain label width;
  text wraps at up to 300 game pixels without lowering the original font size.
- Candidate positions avoid StaticBody2D rectangles, other placed field clues,
  and rendered text bounds reserved by operation signs and route headings.
- Text boxes use their actual minimum text height instead of reserving invisible
  62/95-pixel panels. Outlines and absolute text depth keep lettering readable.
- Deferred layout is coalesced on construction and minimum-size changes, including
  objective-sign changes. No idle frame/physics polling or actor instantiation.
- Site anchors, NPC positions, furniture, collision, saves, rewards and progress
  flags are untouched. Updated record/status text remains live.

## Verification

75 labels: Grotto 9, Gallery 9, Archive 9, Tide Well 13, Causeway 9, Vault 9,
Nest 9 and Depths 8. The final smoke report has no unresolved candidates.
The test covers eight-room scope, text retention, stable repeated layout,
headroom bounds, unchanged collision/flags, dynamic record status, no repeated
reflow over idle frames and exclusion of the unrelated Ash causeway.

Six D3D12 captures from preview_echo_field_signs.gd were inspected: Grotto camp,
Archive catalogue, Well Keeper camp, Tide pump stores, upper flow gauge and
Gallery cargo. The helper frames the clue and its site together at 1.5x zoom;
it does not change the game's camera. Logs: .tmp-echo-sign-focused-preview.log.
Accepted regression reports are in tests/LATEST_SMOKE_RESULTS.md.

## Limits

This pass does not relocate operation signs, creature nameplates, door labels
or interaction prompts. Those can still crowd each other. Rectangular chamber
bounds are used, not the painted silhouette or all possible moving actors.
If future geometry/text yields no clear candidate, unresolved records it for
the smoke test; text is not silently discarded. Creature placeholder art,
remaining machinery and oversized solid-floor foundations are still unfinished.
No full-suite, manual traversal, editor acceptance or complete-map claim.
