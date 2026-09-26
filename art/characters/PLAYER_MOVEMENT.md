# Wayfarer movement continuation - 2026-09-26

## Delivered

`wayfarer_movement_v1.png` adds four registered movement poses: crouch,
downward fall, horizontal dash and landing compression. The original
`wayfarer_v1.png` remains unchanged for idle, walking, jump, attack and hurt.

`PlayerAppearance.gd` observes the existing Player state. Falling begins
above 30px/s downward; a real floor transition after falling gives 0.09s
visual compression when stationary. Attacks/hurt/dash take precedence.
Landing does not lock input or change physics, stamina, damage or timers.
The authored crouch is not vertically squashed again. Attacking/hurt while
crouched retains the old compressed base pose until dedicated art exists.

Walking now uses actual horizontal displacement (18px per stride), not
elapsed time. A 0.04s hold avoids flicker between physics ticks. Blocked
movement settles to idle; relocations of 80px or more and visibility changes
reset travel/landing history. Respawn clears presentation state. Hidden
actors do not animate; this does not add world streaming.

## Imagegen provenance

Mode: built-in imagegen, not CLI/API fallback or Blender. First generated a
companion sheet with `art/characters/wayfarer_v1.png` as the identity/style
reference. That draft had an opaque painted checkerboard and was rejected.
A targeted built-in background-extraction edit supplied real transparency.
The accepted PNG was copied unchanged into the project; no local bitmap
editing, cropping or background-removal script was used.

Rejected draft:
`C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-cb1bcfee-b8b3-460d-8148-83e33fb61b42.png`

Accepted source:
`C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-8996cfc7-5d48-4925-b587-b9db0e47496e.png`

Saved asset: `art/characters/wayfarer_movement_v1.png`.
Actual size is 1254x1254, not requested 1024x1024; four 627px cells.
The presenter uses those actual dimensions, foot pivots and 0.05 uniform
scale. Alpha checks include interior empty samples, not only the corner.
Import uses mipmaps and linear filtering.

### Exact first prompt (generation with identity reference)

Use case: stylized-concept. Generate a NEW companion 2D game sprite sheet using Image 1 only as the character identity/style reference, not as the layout to preserve. Exactly 2 columns and 2 rows on a 1024x1024 transparent canvas, four equal 512px cells. SAME hooded human wayfarer as reference, slate-blue hood and muted teal short travel coat/scarf, brown gloves and boots, small brass clasp, empty hands, facing RIGHT in strict side view. Keep the reference's head size, outfit, proportions and painterly outlined style, no new accessories or weapons. Four different full-body poses: top left GROUNDED CROUCH with deeply bent knees, feet planted, torso forward, compact silhouette height about 220px; top right FALLING downward, upright torso, boots dangling, scarf lifted upward, arms slightly out, height about 330px; bottom left HORIZONTAL DASH forward, torso leaning far forward, legs trailing bent backward, scarf streaming left, height about 230px; bottom right LANDING compression, both boots planted, knees bent moderately, head above crouch height, height about 275px. Every pose has the same anatomical scale, foot baseline at local y440, body center near x256; keep full figure and scarf within x55..457 and y60..445 with generous transparent cell gutters. Genuine transparent alpha everywhere outside character; NO painted glow/haze, no floor, no shadow, no text, no labels, no lines, no grid, no checkerboard.

### Exact correction prompt (edit of rejected draft)

Use case: background-extraction. Image 1 is the edit target. Remove ALL of the drawn gray-and-white checkerboard background and the gray/white haze between the four characters. Replace the background with actual alpha=0 transparent pixels in the PNG, not a white, black or checkerboard picture. Keep the four character sprites exactly as shown: same design, painterly edges, pose, size, placement, 2x2 equal cell layout, no cropping or rearranging. Preserve opaque character colors. No new scene, text, shadow, glow or checkerboard. Output a genuinely transparent cutout sprite sheet.

## Verification and limits

`tests/player_movement_art_smoke.gd` exercises real floor/wall travel,
left/right facing, extra render ticks, buffered jump, fall, landing,
dash and attack during visual compression. It also checks teleport,
disabled-and-hidden reset, all ten poses/sheet switches, transparency and
unchanged body/melee resources. Character, ranged, weapon, mixed combat,
platform-descent and save/restore regressions are recorded separately in
`tests/LATEST_SMOKE_RESULTS.md`.

`tests/preview_player_movement.gd` renders both directions beside the
original idle/jump and a staged Grotto at normal 2.5 zoom. Captures:
`preview_player_movement_poses.png` and
`preview_player_movement_gameplay.png`. Both were inspected in-engine
(D3D12 Forward Mobile renderer). No script errors in accepted import or
preview; sandbox certificate/editor-settings write errors remain.

This is limited pose animation, not a polished frame-by-frame cycle. The
existing two walk strides still need stronger opposite-leg/passing poses;
crouch-walk has a static crouch pose. Dedicated sword/bow/staff sequences
and death art remain pending. Staged screenshots and smoke tests do not
replace a manual live readability/pacing pass or mobile-device profiling.
