# Ground patrol terrain safety

Implemented 2026-09-29 for Enemy.gd and its AshFiend/NeutralCreature subclasses.
Map geometry, spawn locations, health, rewards and movement speeds are unchanged.

Grounded walking now probes beneath the leading foot, with look-ahead scaled to
the movement step. Missing support turns a passive patrol; an active chase stops
at the safe edge until the target returns to reachable ground. Contact with a wall
turns a patrol only when movement points into that wall, avoiding stale-contact
flip-flopping at high physics rates.

The probe accepts solid/one-way static terrain, tolerates small downward steps and
looks past other actors to actual supporting ground. It does not create geometry,
grant jumps or provide full pathfinding. Current actors use rectangular body shapes.
Airborne movement and hit-stun knockback bypass this steering, so they can still
fall or be knocked from ledges. Idle sleeping fauna do not run the moving-foot probe.
Neutral creatures remain passive until attacked and keep their existing wake grace.

tests/ground_patrol_smoke.gd exercises 108 controlled physics cases: three actor
scenes, both directions, solid/one-way floors, patrol/chase and walls at 30/60/120
Hz, followed by small descending steps, actor-obscured floor probes and unassisted
fall/knockback cases. Initial testing exposed neutral-creature wall jitter at 120
Hz; directional wall-normal checking fixes that case. Existing combat, neutral
fauna, population, save and arena tests provide focused regression coverage.

This does not certify every authored route, moving platforms or final encounter
balance. Full manual map traversal remains pending separately. Final reports:
tests/LATEST_SMOKE_RESULTS.md.
