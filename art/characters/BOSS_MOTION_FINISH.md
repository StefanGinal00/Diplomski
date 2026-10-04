# Boss motion and arena materials - 2026-09-28

Follow-up to [combat presentation](BOSS_COMBAT_POLISH.md). Existing generated
sprite sheets and masonry textures reused; no new image generation in this pass.

## Changes

- Walking pose cadence and body bob now follow actual traveled distance, not
  elapsed time or requested velocity. Blocked actors do not walk in place;
  teleport-sized displacement does not advance steps.
- A 75 ms registered outgoing-pose transition softens pose changes. It is
  cleared on facing changes and hidden rooms. Four key poses remain the source;
  this is not a new frame-by-frame hand-drawn animation set.
- Frame-rate-independent body easing and a short cosmetic hit recoil that
  never moves the collision body. Death echoes retain the current body rotation.
- Shared authoritative windup sampling removes a one-frame dependency between
  the body and VFX. Charging and recovery suppress premature volley pre-cues;
  Guardian/Sovereign use only their explicit windups.
- Hazard outlines show progress from the actual attack timer and reset when
  hidden. Charge preparation effects follow committed facing. Ground dust
  stays above the floor rather than spraying below the stone.
- 37 horizontal arena surfaces receive bounded textured bevels, seams, chips
  and zone-colored weathering. Existing textures are reused; the previously
  flat Sentinel arena floor gets a cropped stone overlay only in his arena band.
  Irregular/broken platform silhouettes are excluded. Geometry, UVs, primary
  materials, collisions and one-way settings remain unchanged.
- Surface setup explicitly depends on the room texture pass, is idempotent,
  and adds no per-frame processing to static material details.

## Verification

`tests/boss_motion_smoke.gd` covers seven actors, stationary/blocked motion,
distance cadence at 30/120 FPS, transition cleanup, teleport handling, charge
priority, hit-recoil ownership, timer-driven hazard progress, and 37 surface
bounds/material/idempotence checks.

`tests/preview_boss_motion.gd` time-steps the real Warden physics state machine
at 60 Hz while retaining collision spaces. Eight D3D12 captures sample ticks
0, 20, 40, 48, 60, 76, 100 and 120. Warning -> charge -> recovery confirmed in
the log and screenshots; this is not a full manual player-controlled fight.

- [Preparation](preview_boss_motion_020.png)
- [Charge](preview_boss_motion_048.png)
- [Recovery](preview_boss_motion_076.png)

The focused regression reports are recorded in `tests/LATEST_SMOKE_RESULTS.md`.
Full repository suite not run. Final GPU capture logged the existing host
certificate-store warning, but no physics-space, script or shader errors.
