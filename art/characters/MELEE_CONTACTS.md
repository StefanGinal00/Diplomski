# Sword contact feedback - 2026-09-26

Worn Sword and Spiritglass now have a short cut/spark burst on accepted
melee contacts. Spiritglass retains its cyan weapon tint and a restrained
outer glow; breakable props use warmer, falling fragments. Both facings
mirror correctly. Empty swings, rejected cooldown attacks and noncombat
objects do not create contact effects. Invulnerable targets can still show
contact: the effect is not confirmation that health was reduced.

`player.gd` emits `melee_contacted` after the existing target filtering and
deduplication, before damage. `WeaponAppearance.gd` observes it independently
of the later body-pose event. The target origin is clamped into the current
ShapeCast rectangle in local space, then converted back to world space, so
large targets cannot move the effect beyond sword reach. This is a bounded
cosmetic estimate, not an exact surface-normal or material query. No new
terrain hits, damage, knockback, timing, hitbox size or cooldown logic.

`ProjectileImpact.gd` is reused for sword cuts and projectile bursts, with
the same **shared** cap of 24 and 0.22-second duration. The historical group
name remains `projectile_impact` for compatibility. No second budget, physics
node, particle system, timer, random draw or bitmap asset was introduced.
Existing pause, room/rest/transition/hidden-parent and expiry cleanup applies.

## Verification

`tests/melee_impact_smoke.gd` runs 48 actual ShapeCast combinations: two
swords, both facings, standing/crouching, base/extended reach, and enemy,
neutral or breakable targets. Two colliders on each target verify deduplication.
It also checks damage/knockback/body/shape invariants, cooldown rejection,
large target placement, invulnerability, queued target deletion, empty swings,
ignored objects and damage with the shared effect budget saturated.

Eight existing combat/art/restore regressions were rerun: **9/9 targeted
tests pass**, not a full-suite rerun. Exact local reports are in
`tests/LATEST_SMOKE_RESULTS.md`. Tests and previews use isolated saves.
An early fixture attempted to free itself synchronously during `take_damage`;
it was corrected to normal queued deletion before the accepted final run.

`tests/preview_melee_impacts.gd` generated three inspected D3D12 captures:

- `preview_melee_contact_phases.png`: early/middle/fade, both sword identities,
  mirrored direction and actor/prop variants at enlarged scale.
- `preview_player_melee_worn_sword.png`: actual right-facing standing hit.
- `preview_player_melee_spiritglass_blade.png`: actual left-facing crouched hit.

Both staged in-room hits reduced the target from 30 to 29 health and produced
one effect. These are frozen normal-zoom reviews, not a complete playthrough.
No script errors in the preview/import; known sandbox certificate and
editor-settings-write diagnostics remain.

## Remaining

Body atlas poses and hand anchors were not redrawn in this pass. Dedicated
diagonal/crouched limbs, walk passing frames, enemy-hit presentation,
service-NPC art and final painted effects remain separate milestones. Mobile
profiling and full-map pacing are not certified by these targeted checks.
