# Painted player projectile flight

Arc Bolt and Sunder now use painted arc flight cells; Frost Orb uses the
crystalline sequence; Ember Arrow carries animated flame behind its physical
tip. This reuses existing immutable combat atlases (0, 16 and 13), not newly
generated bitmap assets. Hunter/Thorn arrows retain their compact physical
shaft, feather and point rendering.

Live flight loops cells 1-2-3-2 at 16 changes/second. It never plays the contact
breakup cells 4/5. Frame changes request redraw immediately; smaller continuous
visual changes retain the existing 30 Hz redraw limit. Hiding resets the clock,
frame and active state through the existing lifecycle cleanup.

Arc is violet, Sunder rose, and Frost cyan. A small per-projectile palette
shader preserves painted detail and alpha without sharing mutable uniform
state between simultaneous spells. The dense painted head stays near the
existing collision core and the long texture portion trails behind it.
Ember's upward-painted flame is rotated toward travel and stays behind the
arrow tip. No transforms, collision shapes, speed, range, damage, piercing
budgets, ammunition or mana rules are changed by the presenter.

## Verification

`player_projectile_flight_smoke.gd` checks 72 variant/rate/direction cases
(six variants, 30/60/120 FPS, four directions), fixed-time frame sequence,
no live breakup, isolated shader accents, compact bounds, rotated-room aim,
hidden reset and unchanged native combat state.

Existing projectile appearance, impact, lifecycle and 20-real-shot hit-budget
tests pass. Exact reports are in `tests/LATEST_SMOKE_RESULTS.md`.

Godot D3D12 captures:

- [Flight cell 2](preview_projectile_variants.png)
- [Flight cell 3](preview_projectile_variants_frame3.png)
- [Echo Grotto at gameplay zoom](preview_projectiles_grotto.png)

Enlarged and gameplay-scale captures inspected. Removed a detached-looking
Frost orbit stroke and flat disk during review; the painted cluster retains
only its small core glint.
Known host certificate/shader-cache warnings only; no project script/shader
compilation errors. These are staged visual samples, not full manual fights.
