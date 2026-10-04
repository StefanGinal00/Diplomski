# Player projectile lifecycle

Player arrows and magic projectiles now retire on room changes, checkpoint
rest, transition start, hidden ancestors and lifetime expiry. Retirement
immediately hides the shot, reserves its stopped state, disables monitoring
deferred, and schedules deletion. Late setup and physics cannot revive it.
Spawns during an active transition or inside a hidden room retire immediately.

Deferred damage has a separate lifecycle cancellation barrier. Normal contact
hiding still allows the reserved hit to resolve, including piercing arrows and
Frost Orb continuation. A room/rest/transition event between reservation and
resolution suppresses that old-room damage. Terrain stopping retains already
reserved native hits: the earlier target-before-wall behavior is unchanged.

Ancestor visibility is observed explicitly because an already contact-hidden
shot would not get a second effective visibility notification when its room
hides. This also covers non-Canvas intermediary nodes and disabled rooms.
Connections are automatically disposed when the projectile is freed.

World-space aim now sets world rotation rather than local rotation, avoiding
visual/flight disagreement under rotated parents. Pausing preserves position
and lifetime; explicit rest still retires projectiles while paused. No new
art was generated in this correctness pass.

## Tests

`player_projectile_lifecycle_smoke.gd` checks five variants across 50
event/pending-hit combinations, five normal reserved hits, piercing resume,
hidden and transition-time spawns, paused lifetime/rest, world aim and signal
receiver disposal. The pending-expiry case explicitly invokes the retirement
barrier; normal expiry is exercised through native physics.

Existing projectile impact and 20-real-shot budget checks cover actual contact
damage, overlap, terrain-before/after-target order and piercing. Appearance
checks now require a hidden retired projectile to stay retired, replacing their
old expectation that it could be shown again. The first run of that old
assertion failed as expected; updated regression passes.

See `tests/LATEST_SMOKE_RESULTS.md` for exact final reports and additional
weapon/live-combat checks. These are automated checks, not a full manual
playthrough, export or new visual asset pass.
