# Painted ranged anticipation

Three existing ranged families now use their own painted anticipation cells:
Ranged Enemy (thorn, material 7), Shaft Sentry (crystal, 16), and Ash Sentry
(flame, 13). The two preparation frames progress with the actor's native
countdown; they do not loop or invent a second attack timer. Size and opacity
increase slightly toward release.

The effect is centered on the real muzzle and follows world-space aim,
converted into local drawing coordinates. The flame atlas's upward-painted
axis is corrected. Existing danger icons and aim/fan lines remain unchanged.
This pass reuses existing atlases, not newly generated bitmap assets.

SentryAttackCue is a single non-colliding presenter per sentry, inheriting the
room's process mode. Idle sentries do not request continuous redraws. Hidden
rooms clear it immediately, including rooms with processing already disabled;
cancelled or missing-projectile windups clear on the next native presentation
tick. RangedAttackCue also clears stale progress on cancellation and hiding.
No body/muzzle geometry, damage, warning duration, cooldown or fan count changes.

## Checks

- `mob_charge_cue_smoke.gd`: twelve sentry cycles across two families,
  two tiers and 30/60/120 FPS; monotonic preparation frames, native fan counts,
  release/cancel precedence, missing projectile, hidden cleanup and geometry.
  Also four ranged directions and four countdown samples in a rotated room.
- `sentry_cover_smoke.gd`: actual Shaft/Ash base/awakened AI behind solid cover,
  interrupted windup and fresh full warning, with added painted-charge checks.
- Existing ranged cadence/contact, attack follow-through, combat readability
  and ordinary-mob defeat checks were rerun.

[Godot comparison](preview_mob_charge.png) shows early charge, late charge and
native release at 3x enlargement. Capture inspected; effects remain compact at
the muzzle and retain separate family colors. Staged sample, not a full manual
fight. D3D12 capture emitted known host certificate/shader-cache warnings, with
no project script/shader compilation errors.

See `tests/LATEST_SMOKE_RESULTS.md` for the exact six focused test reports.
