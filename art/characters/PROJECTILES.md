# Native projectile presentation - 2026-09-26

`ProjectileAppearance.gd` extends the existing code-native 2D weapon style.
No bitmap generation, external assets or additional particles were needed.
Hunter arrows have a wood shaft, metal point and pale fletching; Thorn Bow
adds green barbs; ember arrows have a hot point and small flickering tail.
Arc bolts use a crystal core and zigzag tail, retaining the Sunder Staff's
pink palette. Frost orbs use an icy ring, six-spoke core and trailing flecks.

The noncolliding child draws in projectile-local space: root rotation follows
the actual shot direction, including left/down/up diagonal aim. Frost's
existing 1.25 scale is retained. Static arrows redraw on style changes;
animated magic/ember art redraws at most 30 times per second. Hidden shots
reset immediately even under disabled room processing; stopped or queued
shots clear their drawing. No tail/particle nodes survive projectile cleanup.

The old Head/Trail and Core/Aura nodes remain available to the original
gameplay scripts as palette/state metadata, with zero self-modulate alpha
to avoid duplicate drawing. Projectile scripts now emit an observational
contact signal; damage, range, lifetime, speed, source, collision shapes and
piercing budget retain their existing values. The trail is not a hitbox.

## Contact feedback continuation

`ProjectileImpact.gd` draws a 0.22-second, noncolliding burst at the reported
projectile position. Actor contacts use the weapon's palette; terrain uses
smaller, muted sparks fanning back toward the incoming shot; breakable props
use warmer, falling fragments. Magic adds a ring and frost uses shards. This
indicates contact, not guaranteed damage against an invulnerable target.
It does not classify individual wall materials or raycast an exact surface
normal: the contact position is the projectile center at its overlap event.

One childless Node2D per accepted contact, globally capped at 24 active
effects, redraws at most 30 times per second. At the cap, cosmetic effects
are dropped without dropping damage. No physics nodes, timers, particles or
global random-number consumption are added. Effects survive their projectile
long enough to fade, pause with the game, and retire on room change,
transition start, checkpoint rest, hidden parent, parent deletion or expiry.
New bursts are suppressed during transitions.

`tests/projectile_impact_smoke.gd` covers 36 direct contact cases and seven
real physics shots, including damage with the visual budget saturated. It
also checks duplicate contacts, source exclusion, parent transforms, pause,
all cleanup paths and the global cap. Six existing regressions were rerun.
Two inspected D3D12 captures from `tests/preview_projectile_impacts.gd` show
the enlarged comparison and a frozen normal-zoom Grotto staging:
`preview_projectile_impacts.png` and `preview_projectile_impacts_grotto.png`.

## Verification

`tests/projectile_appearance_smoke.gd` checks six variants across six aim
directions (36 cases), setup colors, collision/resource/transform invariants,
damage, range, speed, piercing, trajectory and hidden/stopped/deletion cleanup.
Eight existing regressions also pass, including actual attack contact,
overlapping-target hit budgets, mixed combat and biome spawn/restore. See
`tests/LATEST_SMOKE_RESULTS.md` for exact local result paths.

`tests/preview_projectiles.gd` creates two D3D12 captures, both inspected:

- `preview_projectile_variants.png`: enlarged 6x and normal 2.5x zoom.
- `preview_projectiles_grotto.png`: staged, frozen projectiles in Echo Grotto.

These are staged visual reviews, not a full playthrough or mobile benchmark.
Editor import and preview have no script errors; sandbox root-certificate
and editor-settings-write diagnostics remain. All tests/previews use isolated
temporary saves, not the player's save.

## Next

These are readable native shapes, not final painted effects. Exact material
contacts, enemy impact effects, richer attack/diagonal limb animation, persistent
equipped/holstered art and service-NPC art remain separate work. No gameplay
balance, map layout, streaming or mobile-control changes in this pass.

The subsequent [melee pass](MELEE_CONTACTS.md) reuses the same effect lifetime,
cleanup and shared cap for sword contact cuts; no separate effect budget.
