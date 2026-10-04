# Boss/miniboss transition readability - 2026-09-28

Presentation-only follow-up for all seven twelve-frame boss sets. No new art
generation, AI timing, hitboxes, health, damage, rewards or encounter gates.

- Crossfades now bridge semantic animation states, not every painted gait
  frame. Rapid six-frame locomotion settles to an opaque silhouette instead
  of repeatedly restarting a 75ms double exposure. Shader copies are likewise
  made for state transitions rather than every walk-frame change.
- Charge entry displays the full strike frame immediately; it does not spend
  its first damaging frames fading out of the anticipation pose.
- Bosses without their own authoritative facing property keep their existing
  facing through recovery/follow-through, then resume normal target-facing.
  The Sentinel still follows its native turn state and facing property.
- Muzzle preparation uses native windup progress (0 then 1), not a repeating
  frame selection driven by world age.
- Visibility signals clear release clocks, afterimages, hurt/recoil, crossfade
  and hazard progress immediately. This also works when room processing is
  disabled; it does not depend on a later invisible process callback.

## Visual review

Actual Ember Marshal physics in the authored Ash Arena, at 960x540 / 2.5 zoom:

- [Preparation](preview_marshal_transition_prepare.png)
- [First charge frame](preview_marshal_transition_charge.png)
- [Recovery after player crossover](preview_marshal_transition_recover.png)
- [Return to movement](preview_marshal_transition_stride.png)

The charge sample selects frame 9 at alpha 1.0. The recovery sample remains
left-facing after the target has crossed to the right; movement then unlocks
facing. The player is repositioned by the preview and has test health, so this
is a scripted visual/physics review, not a manual fight or balance assessment.

## Verification

8/8 focused tests passed: boss_appearance, boss_combat_presentation,
boss_frame_sequence, boss_lamp_reveal, boss_motion,
boss_transition_readability, ash_arena, sentinel_combat_flow.

The new regression covers all seven actors at 30/60/120 FPS, immediate charge,
recovery-facing lock/unlock, monotonic preparation, hidden disabled rooms and
markers, and unchanged health/collision shapes. Existing tests cover rematch
auras, real attack hooks, lamp reveal, arena progression and Sentinel combat.

No full repository suite, exported build or complete manual boss fights were
run. D3D12 preview completed with no project script errors; host certificate
and shader-cache write warnings remain. See tests/LATEST_SMOKE_RESULTS.md.
