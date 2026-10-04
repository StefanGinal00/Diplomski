# Mob attack follow-through

Crawler, Wisp, Shade and Broodling now play the existing breakup/particle cells
4 and 5 for 140 ms after a native charge/dive/leap ends, matching the Root
Stalker's existing recovery treatment. Alpha fades continuously. Trails remain
behind the body and preserve their committed heading while it brakes.

Only an observed attack-to-native-recovery transition starts the fade. A new
warning/attack immediately replaces it; hiding a disabled room clears it.
No extra nodes, hitboxes, damage windows or AI delays are introduced.

Ranged Enemy and both Sentry variants now orient their muzzle flipbook to the
actual world-space shot direction, including diagonal shots and rotated rooms.
The Ash flame material's upward-painted axis is corrected separately. The
Ranged Enemy's small muzzle rays also convert world aim into local draw space.
Native projectile origin, cadence, velocity and damage are unchanged.

This pass reuses existing painted flipbooks; it adds no new bitmap assets.

## Review

[Actual Godot presenter comparison](preview_mob_followthrough.png):
active attack, recovery start, and 85 ms particle stage, enlarged 2.5x.
The gallery initially skipped the active body sample for recovery columns,
causing an artificial Shade facing mismatch. It now runs body presentation
before entering recovery; both the focused test and live Shade test verify
the real sequence. No gameplay-facing fix was necessary.

The D3D12 capture was inspected. Known host certificate-store warning only;
no project script/shader error. This is a staged visual review, not a full
manual fight recording.

`tests/mob_attack_followthrough_smoke.gd` covers five families at 30/60/120
FPS, full active-frame persistence, both recovery cells, expiry, committed
heading/ Shade body facing, follow-up precedence, no fake recovery, hidden
cleanup and collider invariants. It also exercises twelve native muzzle
launches across three shooters, four directions, and a rotated room.
See `tests/LATEST_SMOKE_RESULTS.md` for regression reports.
