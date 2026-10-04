# Echo furniture clearance - 2026-09-28

This follow-up reuses the six existing generated PNGs. No new generation,
pixel edits, physics bodies, NPC positions or loot rules were introduced.

## Changes

- Grotto one-way ledges now draw their rock underside within collision depth,
  instead of extruding up to 42 pixels into the passage beneath. Solid floors
  and city rendering retain their previous treatment. 89 ledges checked.
- Six small shelters use a 94-pixel width (uniform scale, about 42 px high),
  giving clearance below the lowest camp overhang rather than touching it.
- Three Archive bookcases move to individually audited free floor spans.
  Sizes vary to suit the catalogue and hidden-record alcoves.
- The Indexer's desk stays beside its resident and is scaled to fit below
  the raised shelf. The delivery cart and its decorative rails move together
  into the open floor to the right of the low overhang.
- Site/NPC/clue/loot anchors, sprite depth, collision geometry and traversal
  are unchanged. The renderer uses fixed authored cosmetic offsets, not a
  continuously running placement solver.

## Evidence

`echo_prop_clearance_smoke.gd` checks all five adjusted Archive props against
actual collision rectangles: no platform intersection and full-width floor
support. It verifies Grotto ledge contours, shelter clearance and stable
cosmetic anchors on room re-entry. Existing art/gameplay regressions also run;
accepted reports are in `tests/LATEST_SMOKE_RESULTS.md`.

Eleven D3D12 preview captures completed. Grotto camp, Archive catalogue,
Indexer's desk, delivery cart and unindexed shelf were visually inspected.
The identified prop/platform intersections are fixed at these audited sites.
Actors can correctly render in front of furniture. Existing crowded/obscured
clue labels, basic creature art and large solid-floor foundation silhouettes
are still unfinished. This does not claim full-map completion, a full test
suite, editor acceptance or manual gameplay traversal.

`tests/audit_echo_prop_clearance.gd` is a read-only geometry report helper
using an isolated save. It does not write placement values into source code.
