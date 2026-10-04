# Boss/miniboss defeat presentation - 2026-09-28

The seven existing boss bodies now use a detached, masked dissolve snapshot
instead of a plain Sprite2D with an unmanaged fade tween. Existing generated
textures are reused; no new image generation in this pass.

- The snapshot retains the current atlas frame, facing, offset, texture filter
  and complete world transform, including scaled/rotated room parents.
- A separate shader material preserves atlas isolation while dissolving the
  silhouette from the feet upward over 0.55 seconds. The edge uses the boss's
  color; a short family-specific breakup uses existing attack frames 4/5.
- The snapshot drifts upward 14 world pixels. This moves only the visual;
  native boss deletion, hitboxes, defeat signals, lamps and rewards are not
  delayed or recreated.
- Room changes, checkpoint rest, transition start and hidden parents retire
  it immediately, even when room processing has been disabled. Pause freezes
  the visual lifetime. Signal connections belong to the short-lived snapshot,
  so freed effects do not leave callbacks holding deleted actors.
- Snapshots share the existing 64-node boss cosmetic budget with attack bursts.
  Full budget or a hidden/transitioning context can suppress art, never defeat.

## Visual review

Native defeat callbacks, then staged samples at 0 / 0.19 / 0.38 / 0.57 seconds.
Captured in actual arenas at 960x540, 2.5 camera zoom:

- [Ash Castellan dissolve](preview_defeat_AshCastellan_1.png)
- [Echo Matriarch dissolve](preview_defeat_EchoMatriarch_1.png)
- [Ember Marshal late dissolve](preview_defeat_EmberMarshal_2.png)
- [Castellan fully cleared](preview_defeat_AshCastellan_3.png)

These are deterministic visual checks, not full manual fight recordings.
The new shader compiled and rendered in D3D12; known host shader-cache write
and root-certificate warnings remain, without project script/shader errors.

## Verification

boss_defeat_echo_smoke.gd checks all seven native defeats, immediate deletion
and single defeat signal, exact snapshot registration under transformed rooms,
independent material/mask, dissolve lifetime, pause, disabled-room visibility,
rest/room/transition cleanup, freed receivers and shared cap/parent disposal.

The initial new test omitted the required current-room setup for the Hollow
Sovereign, whose native damage handler correctly rejects outside-arena damage.
The fixture now enters the matching test room; that gameplay guard is unchanged.
An initial invalid static type assertion was also corrected in the test only.
See tests/LATEST_SMOKE_RESULTS.md for final runs. No full repository suite,
export or complete manual fight has been claimed.
