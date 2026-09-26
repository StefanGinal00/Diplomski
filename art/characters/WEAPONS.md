# Native weapon presentation - 2026-09-26

`WeaponAppearance.gd` extends the project's existing Godot vector weapon
system. No new bitmap generation or external asset pack was needed here.
It draws a steel blade/hilt, bow limbs/string and wood/crystal staff over
the previously generated attack bodies. Spiritglass, Thorn Bow and Sunder
Staff have distinct material/accent colors; the sword sweep retains the
existing weapon tint. Existing upgrade aura behavior is unchanged.

Six measured pixel-space grip anchors follow each combat frame's registered
foot pivot, scale, crouch compression and facing. The renderer reads the
committed attack direction, not newly pressed movement input. Bow limbs
rotate around the grip for diagonal shots; the staff stays upright and
tilts away from the hood. A small native grip wrap bridges the open sword
follow-through palm; a final hand redraw is still desirable.

`PlayerAppearance` snapshots the current melee shape width at successful
attack time. The blade length and fading sweep use this snapshot; rendering
does not move the ShapeCast or recalculate damage/reach. Existing body,
cooldown, mana, projectile spawn/trajectory and save data remain unchanged.
The renderer uses the existing visual timer's progress, with no new timer.

The legacy AttackVisual/BowVisual/StaffVisual nodes remain in Game.tscn for
gameplay references, visibility state and color metadata. Their local
`self_modulate.a` is zero to suppress duplicate prototype drawing. The new
noncolliding Node2D renders after PlayerAppearance and stops when the attack
ends, is superseded, or the actor hides/dies. Visibility reset also works
when room processing was disabled before hiding.

## Verification

`tests/weapon_appearance_smoke.gd` checks six item IDs, both facings, both
attack phases, standing/crouching grip coordinates, diagonal aim, committed
facing, cooldown/reach/body invariants, hidden reset and placeholder opacity.
Existing six-weapon real-contact and combat regressions were rerun; accepted
reports are in `tests/LATEST_SMOKE_RESULTS.md`.

`tests/preview_player_attack.gd` now renders these current captures:

- `preview_player_weapon_poses.png`: enlarged both-facing registration review.
- `preview_player_weapon_worn_sword.png`: staged successful sword attack.
- `preview_player_weapon_hunter_bow.png`: staged successful bow attack.
- `preview_player_weapon_apprentice_staff.png`: staged successful staff cast.

All four were reviewed with D3D12; gallery spacing was increased to prevent
long blades crossing adjacent examples, and the staff was tilted after
review to reduce hood overlap. The final import and GPU preview had no
script errors. Sandbox certificate/editor-settings write errors remain.
Tests and previews use isolated temporary saves.

## Limits / next work

These are simple native weapon drawings, not final painted assets. Weapons
only appear during the current attack window, matching the previous behavior.
The bow rotates to diagonal aim but body arms still use horizontal poses.
Projectile graphics, persistent equipped/holstered art, more intermediate
animation frames and final hand-painted materials remain pending. Existing
NPC art, walk-cycle polish, full-map pacing and mobile-device profiling are
separate milestones; these targeted checks do not certify them.
