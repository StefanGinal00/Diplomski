# Hostile projectile contact / direction pass - 2026-09-28

Uses existing generated six-frame materials; no new images were generated.

- All ten hostile projectile materials retain world-space heading at impact:
  seven boss/miniboss identities, thorn caster, crystal sentry and fire sentry.
  The upright fire atlas also retains its 90-degree paint rotation.
- Impact starts with breakup frame 4, then particles 5. It does not replay a
  full-power bolt after the real projectile has already collided.
- Boss volley muzzle flashes and painted preparation face the shot direction.
  The Sentinel uses its locked aim, not a player position changed after windup.
  Spawn positions, projectile speed, damage, cooldown and collision size remain.
- EnemyProjectile now reserves its single contact immediately, hides and stops
  moving on consumption. Multiple same-tick body-entered callbacks cannot apply
  extra damage or duplicate impact art. A terrain-consumed shot cannot then hit
  another actor before deferred deletion. This fixes a hit-budget bug, not a
  new damage/balance setting.
- Hostile shots and BossBurst hit/release effects retire on room change,
  checkpoint rest, transition start or hidden parent, including process-disabled
  rooms. Lifetime expiration hides them immediately. New bursts are refused
  during transitions or under hidden/deleting parents; the 64-effect cap remains.

## Visual checks

D3D12 captures at 2.5 display scale, using actual presenters for all ten
materials in right, left, northeast and southwest directions:

- [Flight](preview_enemy_contacts_flight.png)
- [Contact breakup](preview_enemy_contacts_breakup.png)
- [Final particles](preview_enemy_contacts_particles.png)

These are a deterministic material matrix, not a recording of a full fight.
The source actor profile mapping is covered by enemy_attack_art_smoke.gd.

## Tests

enemy_projectile_contact_smoke.gd checks 40 material/direction combinations,
14 boss muzzle directions including Sentinel aim lock, repeated callbacks,
terrain-first ordering, consumed motion, transformed-parent registration,
disabled-room cleanup, expiry and transition suppression. Four additional
live physics cases shoot into overlapping targets and verify one total hit.

Existing boss presentation/motion/frame/transition/lamp tests, compact combat
art/readability, live mixed and ranged encounters are rerun alongside it.
See tests/LATEST_SMOKE_RESULTS.md for exact final results and report paths.
No full repository suite, export or complete manual-fight claim.
