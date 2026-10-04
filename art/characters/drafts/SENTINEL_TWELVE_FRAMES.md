# Sentinel additional frames: draft, NOT integrated

Status update: user approved local processing; these raw RGB candidates were
cleaned and assembled into the active twelve-frame RGBA atlas. Raw files below
remain reference-only. See [completed seven-actor integration](../BOSS_TWELVE_FRAME_ANIMATIONS.md).

Generated with the built-in imagegen tool on 2026-09-28, using
`../boss_void_sentinel_v1.png` as the identity reference.

Saved candidates (1536 x 1024, 3 columns x 2 rows each):
- `sentinel_walk_six_v1_rgb.png`: six walking poses.
- `sentinel_cast_six_v1_rgb.png`: ready, anticipation, charge, release,
  follow-through and recovery.

Validation failed: both files are RGB, not RGBA. The checkerboard is painted
into the image. A targeted background-extraction retry also returned RGB with
alpha 255 at the corners. Do not use these raw files as gameplay textures.
Existing live textures and animation controller were deliberately preserved.

Local background processing permission has been requested from the user.
The imagegen skill requires explicit consent to switch image editing methods.
CLI/API generation is another fallback, but requires explicit user selection
and an OPENAI_API_KEY; it was not used or probed.

After an approved clean extraction, review cell bounds (the cast release hand
extends slightly across its nominal cell), align planted soles and torso
pivots, and verify six-pose gait order in motion before activating the sheets.
Candidate poses are not proof of a finished smooth walk cycle.

## Exact generation prompts

### Walk

Use case: stylized-concept. Asset type: production 2D side-view game animation sprite sheet, true transparent RGBA background. Input image 1 is the character identity/style reference, NOT the layout to copy. Preserve the exact Void Sentinel identity: dark indigo angular plate armor, horned helmet, small gold eye slit, violet chest core, three floating violet crown shards, bulky armored hands, pointed boots. Hand-painted 2D game sprite style like the reference, no 3D scene. All figures face RIGHT in the same 3/4 side view with identical proportions, armor shapes, palette and light. Create a new sheet arranged as EXACTLY THREE COLUMNS and TWO ROWS, six equally sized rectangular cells, read left to right then next row. Whole body and crown completely contained in EACH cell with generous transparent gutters and at least 8 percent blank padding. Same body scale and centerline in every cell; all planted soles align to the same baseline at 90 percent of cell height. No figure or shards crossing cell boundaries, no ground, no shadow oval, no writing, no borders, no checkerboard, no background. This will be played as sequential animation frames, so change only joints and small body weight shifts, not character design. Primary request: six sequential frames of ONE complete grounded heavy WALK CYCLE moving right, animated in place. Frame 1 right/front foot forward heel contact and left foot back. Frame 2 weight loads onto right foot, rear heel rises. Frame 3 left foot passes forward low to ground while right leg supports weight. Frame 4 left/back foot forward contact and right foot behind. Frame 5 weight loads left, right heel rises. Frame 6 right foot passes low toward its next heel contact, loops into frame 1. Arms swing subtly opposite legs; knees bend like walking, not running, jumping or floating. Keep upper torso and head stable; keep at least one planted foot every frame. Make the six foot placements distinctly different but coherent consecutive frames.

### Cast

Use case: stylized-concept. Asset type: production 2D side-view game animation sprite sheet, true transparent RGBA background. Input image 1 is the character identity/style reference, NOT the layout to copy. Preserve the exact Void Sentinel identity: dark indigo angular plate armor, horned helmet, small gold eye slit, violet chest core, three floating violet crown shards, bulky armored hands, pointed boots. Hand-painted 2D game sprite style like the reference, no 3D scene. All figures face RIGHT in the same 3/4 side view with identical proportions, armor shapes, palette and light. Create a new sheet arranged as EXACTLY THREE COLUMNS and TWO ROWS, six equally sized rectangular cells, read left to right then next row. Whole body and crown completely contained in EACH cell with generous transparent gutters and at least 8 percent blank padding. Same body scale and centerline in every cell; all planted soles align to the same baseline at 90 percent of cell height. No figure or shards crossing cell boundaries, no ground, no shadow oval, no writing, no borders, no checkerboard, no background. This will be played as sequential animation frames, so change only joints and small body weight shifts, not character design. Primary request: six sequential frames of ONE chest-core projectile CAST AND RECOVERY animation, standing rooted in one wide grounded stance throughout. Frame 1 neutral upright ready stance, arms low, chest core dim violet. Frame 2 anticipation: knees bend slightly, elbows draw back, chest tilts back a little. Frame 3 full windup: braced knees, forearms open beside glowing chest core, torso wound back. Frame 4 RELEASE: torso drives slightly forward, arms extend a little outward, chest core white-violet flash (compact, no detached projectile and no beam). Frame 5 follow-through: weight forward, hands settle, glow fades. Frame 6 recover upright almost identical to frame 1 ready stance. Both feet keep the SAME positions and common ground baseline across all six cells, no leaping, lunging or whole-body translation.

### Failed transparency correction (same prompt for each candidate)

Use case: background-extraction. Input image 1 is the EDIT TARGET. Remove ONLY the baked white and gray checkerboard background. Return a genuinely transparent RGBA PNG with alpha zero in ALL background areas, including between limbs and floating crown shards. The checkerboard is not transparency; it must be removed, not redrawn. Preserve the six existing character sprites pixel-faithfully: same exact designs, poses, arrangement, scale and 1536x1024 canvas. Do not add anything, do not repaint or redesign armor, no visible solid or checkerboard backdrop, no text. Preserve the violet luminous core and fine dark armor edges. Output actual transparent-background cutouts, not a preview of transparency.
