# Shaft Crawler art pass — 2026-09-26

`shaft_crawler_v1.png` is an original 2D sprite sheet created with the built-in
imagegen tool, not the CLI or a downloaded pack. The final generated PNG was
copied unchanged into this directory. It is 1536x1024, a 3x2 atlas: idle,
two strides, warning, charge, recovery. Recovery plus the existing red flash
also conveys a hit; a separate hurt/death sequence remains future work.

The first draft crossed a cell boundary. The padding edit fixed the layout
but returned an opaque checkerboard, which was rejected. A final targeted
background extraction restored genuine alpha. Only the final transparent
sheet is used by the project. Actual frame pivots are registered in
`CrawlerAppearance.gd` to the existing y=9 foot baseline. The short walk
cycle is distance-driven, with a 40ms hold between physics ticks to prevent
idle flicker on high-refresh displays. Hidden and relocated actors do not
accumulate walk distance. Mipmaps/linear filtering reduce minification noise.

The presenter follows actual PATROL/WARNING/CHARGE/RECOVER states, direction
and health signals. It never alters AI, warning duration, attacks, contact
damage, drops or save data. Original BodyVisual/Eye are hidden; BodyVisual
still supplies the existing hit-flash tween. Warm cracks signal warning and
charge; awakened idle/recovery is cooler. The existing pulsing warning icon
is moved above the health bar to prevent overlap. Body/contact rectangles
remain 25x18 and 29x19; decorative shell/claw tips can extend slightly beyond.

## Review and verification

- `preview_crawler_poses.png`: six poses in both directions, enlarged.
- `preview_crawler_gameplay.png`: staged idle/warning/recovery beside the
  player in the real Grotto at 2.5 camera zoom, not a recorded encounter.
- `tests/preview_crawler.gd`: reproduces both GPU screenshots with an
  isolated save. D3D12 Forward Mobile was used; that does not certify a phone.
- `tests/crawler_appearance_smoke.gd`: four live AI loops across both
  directions and tiers, complete warnings, awakened repeat, facing, stride,
  first-hit flash, warning/health-bar separation, hidden/teleport handling,
  transparent padding and unchanged collision. Its stationary player target
  has body collision disabled so it does not prematurely stop charges;
  existing melee/ranged/mixed combat tests verify actual damage separately.

This is a first art/animation pass, not a finished animation set. More stride
frames, distinct recoil/death poses and manual play-feel review remain.
No population, map progression, balance, streaming or mobile-control changes.

## Exact built-in prompts

### Initial generation

Use case: stylized-concept. Asset type: original transparent 2D side-scrolling game enemy sprite sheet. Exactly 1536x1024 pixels, 3 columns by 2 rows, six 512x512 cells, no lines or labels. Genuinely transparent alpha background, no scenery, no ground shadows, no opaque background, no checkerboard drawn. SAME squat armored cavern crawler in every cell, always facing RIGHT in clear side view. A compact four-legged beast with broad slate-violet overlapping rock shell plates, low blunt snout, one visible small pale mint eye, short teal-grey clawed legs, no wings, no long tail, no weapons. Painterly 2D strong outline, simple large readable shapes with restrained texture, not 3D, no copied character. Width about 350px from x80 to430 in each cell; height about220px from y185 to405; feet baseline y405; shell mass consistently centered x250. Six separate poses: row1 left idle with planted feet, middle walk with near front leg FORWARD and near hind leg BACK, right walk with near front leg BACK and near hind leg FORWARD. Row2 left WARNING anticipatory crouch, head drawn back and raised shell with restrained warm coral seams/eye; middle CHARGE low forward head and braced rear legs, clear stretched lunging silhouette, coral eye; right RECOVERY head sagging and tired legs, cold teal eye. Keep creature identity, scale and registration consistent across all six cells; entire creature fully contained with generous transparent margins; no motion trails. Must read well reduced to roughly 30 pixels wide.

### Atlas padding edit

Use case: precise-object-edit. Edit target: supplied six-pose crawler sprite sheet. Preserve the same creature identity, painterly 2D style, colors, all six pose meanings, and truly transparent background. Fix atlas padding and registration ONLY: 1536x1024 canvas with 3 columns and 2 rows, six equal512x512 cells. Reduce EACH creature's size so its entire body including claws stays within local x80..432, local y140..420 of its own cell. Especially the bottom-middle CHARGE pose must NOT cross the vertical line x1024 into the last cell. Leave at least60px completely transparent margin around every cell. Align lowest feet at local y420 for each pose. No text, no lines, no checkerboard, no shadows or background. Do not redesign or add new creatures.

### Transparent background correction

Use case: background-extraction. Input image: edit target sprite atlas. Remove the ENTIRE grey checkerboard background and make it genuinely transparent (alpha=0); this is not a request to draw a transparency checkerboard. Preserve ONLY the six opaque creatures and antialiased creature edges. No grey squares, no shadow, no glow outside the silhouettes. Keep all six creatures, every pose, size and position exactly unchanged on the same 1536x1024 canvas. Output actual transparent PNG.
