# Character art pilot — 2026-09-26

Latest weapon pass: [native weapon art and hand registration](WEAPONS.md).
The old opaque attack polygons are now suppressed; a separate presenter
draws registered sword/bow/staff geometry over the existing body atlas.

Latest attack pass: [weapon-class body poses and exact prompts](PLAYER_ATTACKS.md).
Sword/bow/staff now have separate release/follow-through silhouettes driven
by successful attacks, not simply the equipped weapon or input button.

Latest: [Wayfarer movement poses and exact prompts](PLAYER_MOVEMENT.md).
Crouch, fall, dash and landing now have companion art. Walking follows
actual travel and stops against a wall; the original player atlas remains.

Continuation: [Shaft Crawler art and exact prompts](CRAWLER.md), including
idle/walk/warning/charge/recovery, facing and normal-zoom screenshots.

[Ranged sentinel art and cues](RANGED_CUES.md) now include the successfully
generated four-pose transparent sprite, native warnings and real-shot muzzle
effects. The earlier authorization failure did not recur on retry. That
document records the exact successful prompt, source and engine captures.

Original 2D bitmap assets generated with the built-in imagegen tool (not
the CLI, downloaded asset packs or Blender). Both PNG files are 1536x1024,
six 512x512 cells with genuine alpha; originals were copied unchanged from
the generation output into this project. Import mipmaps and linear filtering
reduce minification shimmer at the normal 2.5 camera zoom.

- `wayfarer_v1.png`: idle, two walk poses, air/dash, attack, recoil.
- `shaft_wisp_v1.png`: two hover poses, warning, dive, recovery, recoil.
- `preview_poses.png`: enlarged engine-rendered registration gallery.
- `preview_grotto_gameplay.png`: staged character placements in the actual
  Grotto at gameplay zoom, not a recorded fight or pacing test.

`PlayerAppearance.gd` and `WispAppearance.gd` select poses from existing
movement, attack timers, health signals and AI state. Prototype visuals are
hidden, not removed, because combat code retains references to them.
Attack casts, collisions, damage timing, projectiles, weapon colors, save
data and the existing weapon/dash effects are not replaced. Hero art is
weaponless so an equipped bow or staff does not leave a baked-in sword.
The dive sprite rotates about its registered core. Warm warning and red hit
flash remain distinct; awakened idle/recovery is cooler. Hidden actors do
not animate; this is not full area-streaming implementation.

This is a first playable art pass, not final animation production. The walk
cycle still has only two strides; passing/opposite-leg frames, crouch-walk,
death and longer weapon-specific sequences remain to be developed. The
movement companion separates fall, crouch, dash and landing; the attack
companion adds two body poses per weapon class. The 20x20 body collision stays
unchanged: the hood/scarf are decorative outside that body. Ordinary town
residents retain their native vector motion; other enemies and service NPCs
have not been reskinned in this pass. Seek style/readability feedback before
rolling it out to every biome. Mobile performance is not yet measured.

Reproduce screenshots with `tests/preview_characters.gd` using the Godot
Forward Mobile renderer. Preview and smoke tests use isolated temporary
saves. Known sandbox-only diagnostics: root certificate store; shader-cache
write during GPU capture; editor-settings write during editor import. Final
preview has no script errors or out-of-range frame accesses.

## Exact generation prompts

### hero

Use case: stylized-concept. Asset type: transparent 2D side-scroller character sprite sheet, precisely 3 columns by 2 rows on a 1536x1024 canvas, six equal 512x512 cells. Entire background genuinely transparent alpha, no checkerboard drawn, no floor, no shadow, no text, no borders. Same original compact hooded human wayfarer in every cell, facing RIGHT in side/three-quarter side view: pale face under slate-blue hood, short muted teal travel coat and small trailing scarf, leather gloves and dark boots, one tiny antique brass clasp. Painterly 2D clean outlined shapes with restrained detail readable at 24 pixels tall, not 3D, no horns, no insect mask, no copied character. NO weapon in any hand; weapons added separately by engine. Each figure fully contained in its cell with generous transparent padding; same body proportions and scale, head near local y100 and lowest boot near local y420, body center x256. Row 1 left-to-right: neutral standing idle; walk stride front leg extended; opposite walk stride. Row 2 left-to-right: airborne with knees bent; forward attack/casting lunge with empty lead hand extended; recoil/hurt leaning back. Keep all six silhouettes isolated and on the same ground baseline for engine registration.

### wisp

Use case: stylized-concept. Asset type: transparent 2D side-scroller enemy sprite sheet, precisely 3 columns by 2 rows on 1536x1024 canvas with equal 512x512 cells. Genuinely transparent alpha background, no checkerboard drawing, no ground, shadows, text, labels or borders. Six isolated poses of the SAME original flying cavern spirit: compact deep-violet crystalline seed body, two translucent teal moth-like wings, pale turquoise slit eye, tiny wispy trailing fins. Painterly clean 2D dark-fantasy game asset with strong outline and simple shapes readable at 24px, no 3D and no copied character. Center body exactly near x256 y256 in every cell, constant core size, whole wingspan inside x60..452 and y80..432. Row1 left-to-right: hover wings raised; hover wings lowered; attack warning wings drawn inward and eye/crown glowing warm coral. Row2 left-to-right: diving toward RIGHT, narrow swept-back wings; exhausted recovery drooping wings, cool dim eye; hit recoil wings splayed, brighter pale core. Keep core identity and proportions consistent, transparent padding all around every sprite, soft glow very restrained and contained within each cell.
