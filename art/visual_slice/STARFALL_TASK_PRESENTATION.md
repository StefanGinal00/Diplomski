# Starfall task presentation — 2026-09-27

This is a native 2D drawing/readability pass, not new task logic or bitmap art.

- Seven route registers replace their open frame and trapezoid lamps with a
  mounted metal panel, fasteners, indicator dials and completion checkmarks.
  Existing objective names, counts and instructions remain authoritative.
- Nine optional controls have distinct silhouettes: two caravan winches,
  two ward terminals, two seedbeds and three procession beacon controls.
  They show prerequisite-locked, available/pending or completed state using
  symbols as well as color. Nearby-enemy blocking still uses the original
  station's interaction text; the new badge is not a threat sensor.
- Two restored garden landmarks and three procession lantern landmarks
  replace oversized monochrome leaves/flames with botanicals and framed
  lanterns. They reflect their original event IDs and avoid the neighboring
  station status text. The old leaf polygons remain hidden, not deleted,
  so the authoritative controller's color/state references stay valid.

StarfallTaskArt observes GameState shortcut events and reads station state.
It filters unrelated events, coalesces updates until the next deferred call,
and has no per-frame polling. It never writes flags, grants rewards, changes
interaction reach, adds collision or moves stations/labels. Three explicit
visual leaves per station and the register's old decorative frame/lamps are
hidden; prompts, interaction areas and gameplay children remain untouched.
Landmark art is a sibling of the hidden source polygon, not its child.

## Verification

starfall_task_art_smoke checks all seven registers/nine stations, prerequisite
and completion feedback, unchanged flags after redraw, the 34px trigger
shape, collision snapshots, original prompts, idempotence, five landmark
replacements and ignoring unrelated events. Existing field-operation and
inner-field tests exercise activation gates, beacon order, saved partial
progress, guardian prerequisites and exactly-once rewards. Dressing tests
retain route-level progress cues and population unload/reload behavior.

preview_starfall_tasks.gd produced ten 1280x720 D3D12 state views, exit 0.
The preview deliberately stages event flags in an isolated temporary save;
it is not an interaction playtest. Partial register, locked terminal, repaired
winch, restored garden and lit beacon views were reviewed. Final landmark
captures are in .tmp-starfall-task-final.log; only the known host certificate
store warning, no script/shader errors. A type-inference error in the initial
new test was corrected before accepted runs.

Runtime field controls retain existing lazy population timing. Route registers
are tool-rendered; runtime-only stations are not promised as new editor
previews. Manual traversal and the full regression suite were not run here.
Other branch backgrounds, labels, enemy/prop art and containment models still
need separate passes. This does not mark all Starfall art complete.
