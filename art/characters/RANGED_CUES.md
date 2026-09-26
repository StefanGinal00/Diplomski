# Ranged enemy cues — 2026-09-26

## Successful sprite continuation

The built-in imagegen retry succeeded on 2026-09-26. The earlier request
failed with 401; its cause has not been established. Read-only diagnosis
reported an active ChatGPT CLI login; no credentials, login state or client
configuration were changed. No CLI/API image-generation fallback was used.
This confirms a successful request, not a permanent service-side repair.

`stone_sentinel_v1.png` was copied unchanged from:
`C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-71e216ab-8ce0-4e16-80da-148c2fd32680.png`.
It has genuine transparent alpha and is actually 1254x1254 (four 627px
cells), not the requested 1024x1024. It is original generated prototype art,
not a downloaded asset pack. Import mipmaps are enabled.

`RangedAppearance.gd` maps the four cells to idle, charging, firing recoil
and hurt, reading the existing cue state after AI/cue processing. Facing
follows the actual muzzle. Per-frame foot registration and nonuniform
scale keep the squat pedestal at y=9 and mouth near the existing muzzle.
The old Sprite2D is retained for existing code references but is hidden.
No bitmap editing was used; registration happens in the Godot presenter.

### Exact successful prompt (built-in imagegen, new image; no references)

Original 2D game sprite sheet on genuine transparent background, 1024x1024, 2x2 equal cells. Same compact slate-violet stone and bronze stationary turret facing right: idle, warm coral charging, firing recoil without projectile, hurt. Painterly strong simple silhouette, all sprites fully within cells with generous padding, no text, no checkerboard or shadows. Same scale and pedestal baseline in every cell.

## Gameplay cues and verification

Independent native gameplay presentation is complete: `RangedAttackCue.gd`
adds a warm triangular warning above health and a growing muzzle ring in
the final min(0.35s, 40% of shot interval) of the existing cooldown. This is
an observation, not a new mandatory windup. Leaving range or a dead/missing
target cancels the cue; absent projectile resources cannot fake firing.

`RangedEnemy.shot_fired(direction)` is emitted only after successful spawn,
setup and the unchanged cooldown reset. The brief muzzle rays follow that
actual direction, including diagonals. The bitmap now supplies the hurt
pose; the old hidden Sprite2D's flash callback is retained for compatibility.
No body/muzzle positions, projectile stats, damage, detection rules, line of
sight, cooldowns or rewards changed. Hidden presentation drops transients;
this does not implement room streaming or suspend the enemy AI. Visibility
changes also clear transients when room processing was disabled first.

`preview_ranged_poses.png` shows all four poses in both directions, enlarged.
`preview_ranged_art.png` is a staged GPU screenshot in the Grotto at the
normal 2.5 zoom: idle / impending shot / actual launch. Both were inspected
after rendering with D3D12 and `tests/preview_ranged_cues.gd`, using an
isolated save. `preview_ranged_cues.png` is the earlier prototype capture.
No script errors occurred in the final import/preview. Sandbox certificate
and editor-settings write errors remain. These captures do not certify
animated combat readability across all maps or mobile performance.

`tests/ranged_attack_cue_smoke.gd` covers four directions/heights, three
launches per case with original timing, actual projectile spawn/aim/stats,
real physics contact damage, range/death cancellation, failed launch, hit
feedback, bitmap/cue agreement, disabled-room hidden reset, genuine alpha
and unchanged 18x18 collider/muzzle. Other character,
weapon, mixed-combat and restore regressions were rerun separately.

## Historical first specification (failed request, no output)

Built-in imagegen prompt:

Use case: stylized-concept. Asset type: original transparent 2D game enemy sprite sheet, 1024x1024 pixels, exactly 2 columns and 2 rows, four equal 512x512 cells. Genuinely transparent alpha background, no checkerboard drawing, no scenery or floor shadow, no text or borders. SAME small stationary ancient stone-and-bronze sentinel turret in every cell, facing RIGHT in strict side view. Compact squat pedestal, slate-violet stone casing, bronze barrel bands, one circular pale mint energy lens at the right barrel opening. Painterly 2D dark fantasy, clean strong outline and simple readable shapes, not modern military, not 3D, no copied character. Entire turret in each cell within x110..435 and y140..420. Pedestal center at x250; lowest foot y420, barrel mouth at x425 y265, same registration and scale in all four cells. Top left IDLE closed casing, dim mint lens. Top right CHARGING casing vents slightly open and warm coral lens/core brightening, poised to fire. Bottom left FIRING small barrel recoil to the left with bright pale lens, but NO projectile, no beam, no external muzzle flash baked into sprite. Bottom right HURT casing slightly tilted, dim lens with red internal cracks, same intact pedestal, no flying debris. Keep all four isolated with generous transparent padding and consistent silhouette, read at 22 pixels tall.
