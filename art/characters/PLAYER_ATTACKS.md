# Wayfarer weapon-class attack poses - 2026-09-26

This documents the body-atlas checkpoint. The subsequent
[native weapon pass](WEAPONS.md) replaces the displayed prototype weapon
polygons. The preview script now writes `preview_player_weapon_*`; the
older `preview_player_attack_*` captures below remain historical evidence.

## Delivered

`art/characters/wayfarer_combat_v1.png`: six 512x512 cells on a 1536x1024
transparent PNG. Top row: sword strike, bow release, staff cast. Bottom row:
matching follow-through. Empty hands keep the body sheet independent from
equipped weapon variants; existing native weapon/effect polygons remain.

`Player.attack_performed(weapon_class, direction)` fires after the existing
melee resolution or successful projectile setup/timer reset. No pre-hit
windup was added. Damage, resource costs, projectile direction/spawn and
cooldowns are unchanged. The presentation snapshots class/direction and
uses the existing visual timer: release for the first 55%, follow-through
for the rest. It does not start a separate timer. The existing melee timer's
wait_time behavior is retained, including after other weapon classes.

`PlayerAppearance.gd` chooses the class-specific body sheet and foot pivot.
Turning does not flip an already launched attack body to the opposite
direction. Current crouch uses the existing scale multiplier; dedicated
crouched/diagonally aimed limb drawings are still pending.

Rejected attacks (cooldown, insufficient mana, missing projectile resource)
do not emit the event. Hurt, visibility/respawn, large relocations and a
different equipped weapon cancel the body snapshot. Direct inventory equip
also hides the previous weapon's effects without resetting its cooldown.
Bow attacks now explicitly hide a leftover staff effect. These are visual
changes, not new attack cancellation/damage mechanics.

A teardown check also exposed a stale-target error in RangedAttackCue:
the cached player is now checked before assignment to a typed Node2D.
The ranged smoke test explicitly frees a target and checks warning cleanup.

## Generation provenance

Built-in imagegen only; no CLI/API fallback or local bitmap editing.
Reference: `art/characters/wayfarer_v1.png`, used for identity/style.
First output and first correction had opaque painted backgrounds and were
not integrated. The final background-extraction edit has real alpha.
The final output was copied unchanged to the project. Import mipmaps are
enabled; per-pose registration is done in Godot, not by editing pixels.

All outputs are under:
`C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/`

1. Rejected draft: `exec-223ad374-9df2-40f8-99e8-fafb1ddf9f7b.png`.
2. Rejected opaque correction: `exec-bc362334-e340-4426-8d4d-7719eafca26d.png`.
3. Accepted alpha source: `exec-4144a5af-ba0f-4280-b484-14eaf91ec153.png`.

### Exact generation prompt (identity reference)

Use case: stylized-concept. Create a NEW 2D game animation companion sprite sheet. Image 1 is the character identity and painterly style reference only. Preserve the same hooded human wayfarer, slate-blue hood, muted teal coat and scarf, brown boots/gloves, tiny brass clasp, face, anatomy and scale. Six isolated full-body poses facing RIGHT on genuine transparent alpha, exactly 3 columns x 2 rows on 1536x1024, equal 512x512 cells. NO weapons, projectiles, effects or props painted in hands; engine adds them separately. Top row left-to-right: SWORD STRIKE body lunging forward, lead fist extended at waist/chest height as if holding a horizontal sword; BOW RELEASE lead arm extended straight forward at chest height, rear hand by cheek just after releasing an imaginary bowstring; STAFF CAST upright stance, lead closed hand at chest height holding an imaginary staff and other palm extended forward. Bottom row corresponding FOLLOW-THROUGH poses: sword arm lowered forward and weight settling; bow lead arm still forward but rear hand relaxed behind jaw; staff arms slightly lowered and shoulders relaxing. Show two clearly different but consecutive body silhouettes for each weapon class, not charging or a new windup. Keep character empty-handed in all cells. Constant scale, torso near local x260, feet on y450, hood around y110. Entire scarf, fingers, boots fully inside each cell with generous transparent gutters. No floor, no shadow, no glow, no haze, no text, no checkerboard drawing. Output real transparent PNG cutouts.

### Exact first edit prompt (draft as edit target)

Use case: background-extraction. Image 1 is the edit target: six empty-handed wayfarer sprites in a 3x2 grid. Prepare these as clean isolated transparent game sprites. Remove every gray/white checkerboard and haze pixel outside the characters; output genuine PNG alpha=0 background, not a painted background. Keep identity, outfit, six poses and painterly style. Keep 1536x1024 canvas, six equal 512px cells. Add clear cell gutters: scale each figure down uniformly to 85 percent of its original size about its cell center, keeping it in the same cell, so all hands/scarves/boots are at least 25 pixels away from the cell edges. Do not crop hands or fingers. No weapons, extra objects, text, glow, shadows, floor or checkerboard. Preserve opaque character colors and crisp transparent edges.

### Exact final edit prompt (previous correction as edit target)

Remove the background. Make the six characters transparent PNG cutouts. The gray checkerboard is painted into this image: delete it completely, including all spaces around arms and legs, and use actual transparent alpha instead. Preserve the six character drawings and their current positions. No other changes.

## Verification and remaining work

`tests/player_attack_art_smoke.gd` covers six actual weapons, both facings,
horizontal/diagonal ranged shots, real melee and projectile contact, both
pose phases and normal timer expiry. It checks rejected attacks, equipment
changes retaining cooldown, hurt, hidden disabled actors, respawn, alpha,
unchanged body transform and melee reach. Existing movement, projectile
hit-budget, weapon, mixed-combat and restore tests remain separate.

`tests/preview_player_attack.gd` renders both-facing six-pose comparisons
and three staged successful attacks in Echo Grotto at normal camera zoom.
Inspected captures: `preview_player_attack_poses.png`,
`preview_player_attack_worn_sword.png`,
`preview_player_attack_hunter_bow.png`,
`preview_player_attack_apprentice_staff.png`.
No script errors in final import/GPU preview; sandbox certificate and
editor-settings write errors remain.

This is a two-pose body animation per class, not a finished animation set.
Weapon polygons/slash/projectile shapes are still prototypes and need
matching weapon art, hand anchors and diagonal/crouched pose polish. The
sword follow-through drawing has an open hand, so final weapon attachment
will need that grip redrawn. Passing/opposite-leg walk frames, NPC art and
manual live readability/pacing/mobile checks remain pending.
