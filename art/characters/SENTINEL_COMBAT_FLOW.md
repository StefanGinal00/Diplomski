# Sentinel combat flow - 2026-09-28

Response to the playtest report that bosses still feel unnatural, especially
the first encounter. This pass changes real Sentinel combat behavior, not only
the presentation of an otherwise instantaneous shot. Existing raster assets
are reused; no new images were generated.

## Behavior and animation

- Approach accelerates at 160 px/s² and brakes at 270 px/s². A 112/150 px
  spacing band prevents repeated stop/start corrections. He does not endlessly
  retreat from melee players.
- The attack cycle is approach, brake, planted windup, release, recovery.
  Windup lasts 0.62 s (0.48 s in phase two), recovery 0.48 s (0.42 s).
  The cooldown still starts at release, so these deliberate windups also slow
  the overall firing cadence compared with the old instant attacks.
- Facing and aim commit at preparation. Crossing behind the boss does not
  rotate his attack or fire a projectile backwards at the last moment.
- Reorientation brakes first, then uses a 0.22 s pivot with a 24 px facing
  deadzone. The body, eye and projectile origin share authoritative facing.
- Energy forms at the painted chest core. Short directional sparks show the
  locked shot/fan direction; no additional damaging laser is introduced.
- Anticipation loads gradually, release leans forward and recovery settles.
  Sentinel's walking bob is removed so his registered feet stay on the floor.
- Pending attacks cancel when the player dies or leaves training_passage.
  Bounds are enforced after motion and outward velocity is stopped.
- Shared fix for all seven painted bosses: 65 ms stride continuity prevents
  idle-frame flashes on render frames between physics ticks (e.g. 120/60 Hz).
  Actual traveled distance still controls pose cadence, and teleports clear it.

Health, damage, reward/drop logic, persisted defeat, door unlocks and colliders
are unchanged. Other bosses' combat state machines are not rewritten here.
The four existing painted key poses are still a limitation: this is not a full
new frame-by-frame or skeletal animation set.

## Verification

`sentinel_combat_flow_smoke.gd` steps the real actor on the actual starting
arena floor. It checks acceleration, full windup/recovery durations, planted
feet, dodge-behind committed aim, one-bolt/three-bolt releases, deliberate
turning, facing deadzone, death/room-exit cancellation, arena bounds, and
30/120 Hz acceleration. Saves are isolated under a temporary project path.

`boss_motion_smoke.gd` additionally checks that an intermediate render frame
does not flash idle for any of the seven actors. Existing presentation,
appearance, lamp, shaft progression and room-door integration tests also pass.
See [accepted reports](../../tests/LATEST_SMOKE_RESULTS.md).

`preview_sentinel_flow.gd` produced five D3D12 captures from actual physics:
[approach](preview_sentinel_flow_approach.png),
[braking](preview_sentinel_flow_brake.png),
[windup](preview_sentinel_flow_windup.png),
[recovery](preview_sentinel_flow_recover.png),
[turn](preview_sentinel_flow_turn.png).
The player crosses behind at tick 52; the shot releases left at tick 72;
recovery finishes at tick 101 and the turn completes at tick 116.
These are scripted encounter samples, not a completed manual playthrough.
