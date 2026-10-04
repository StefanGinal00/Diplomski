# Player damage feedback - 2026-09-26

Accepted damage now emits a presentation-only `damage_received` event with
the post-defense amount, existing knockback and outcome (`hurt`,
`second_breath`, `fatal`). Rejected invulnerable/dead/nonpositive hits do not
emit it. Healing, safe rest and respawn do not masquerade as damage.
No health calculation, armor minimum, knockback, cooldown, immunity timer,
Second Breath recovery or death/respawn mechanics changed.

`PlayerAppearance.gd` gives ordinary hits a 0.12-second warm body tint and
the existing 0.16-second hurt pose, cancelling stale attack presentation.
The tint fades independently of gameplay timers. Its RGB gain helps the dark
sprite remain readable through the unchanged 0.5 invulnerability alpha.
Second Breath uses a gold tint and short expanding ring; it also works when
the restored HP equals the pre-hit HP, which health-delta-only art missed.

The small world-space burst reuses `ProjectileImpact.gd`, its shared cap of
24 and 0.22-second lifetime. Burst direction follows horizontal knockback;
zero-knockback hazards use an upward cue, not an inferred attacker location.
Body tint still works if the global burst budget is full. Pause freezes the
presentation. Hidden actors, respawn, room/transition/rest and player teardown
clear the tint and owned burst. Fatal hits retain existing hide/respawn
behavior; a death animation is still future work.

No camera shake, hit-stop, fullscreen flash, new atlas, particle system,
input lock or extra collision was added. This is native presentation work,
not image generation or a mobile performance approval.

## Verification

`tests/player_damage_feedback_smoke.gd` checks armor and three knockback
cases, accepted/rejected events, unchanged timers/velocity/collision,
heal/rest immunity, equal-HP rescue, shared-budget saturation, pause,
room/transition/hidden/teardown cleanup, a real enemy projectile collision,
and death/respawn. Existing appearance/movement/attack/melee/projectile,
guard/mixed-combat and biome-restore tests were rerun. Final accepted local
reports are in `tests/LATEST_SMOKE_RESULTS.md`; these are targeted checks,
not a complete-suite or full-map playthrough.

Three staged D3D12 captures from `tests/preview_player_damage.gd` were reviewed
at normal camera zoom: `preview_player_hurt_right.png`,
`preview_player_hurt_left.png`, `preview_player_second_breath.png`. Body
brightness was adjusted after the first review. Final preview/import have
no script errors; known sandbox certificate/editor-settings diagnostics
remain. All scripts use isolated temporary saves.

Next: movement/limb animation polish and service-NPC art; final death art,
enemy-specific effects, broad map pacing and device profiling remain open.
