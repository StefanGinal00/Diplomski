# Six boss sprite sheets - 2026-09-28

## Delivery and scope

Six independent built-in ImageGen generations. Each native 1254x1254 transparent RGBA sheet contains four 2D boss states and uses imported mipmaps. No external art or 3D assets. BossAppearance only switches paint/pose from existing movement, wind-up and charge state; contact shapes, combat scripts, attack warnings, phase transitions, rewards and unlocks remain owned by original boss code. GPU review is at [preview_boss_appearances.png](preview_boss_appearances.png).

| Boss | Project asset | Generated original |
| --- | --- | --- |
| Void Sentinel | art/characters/boss_void_sentinel_v1.png | exec-1a605c11-42a2-461b-928f-3a91e8315841.png |
| Abyss Warden | art/characters/boss_abyss_warden_v1.png | exec-41a97051-3189-4663-a262-433fa902cc05.png |
| Echo Matriarch | art/characters/boss_echo_matriarch_v1.png | exec-d0d0d1e7-64a6-4e3c-a935-31a8ba3859d7.png |
| Ash Castellan | art/characters/boss_ash_castellan_v1.png | exec-0349c89c-873c-404f-a084-15e8ab206ae3.png |
| Hollow Sovereign | art/characters/boss_hollow_sovereign_v1.png | exec-4e3e34e9-5499-454a-90f8-16e4d5ac5590.png |
| Starfall Guardian | art/characters/boss_starfall_guardian_v1.png | exec-147b873f-be26-4743-83a7-48863b408594.png |

## Exact prompts

### Void Sentinel

~~~text
Use case: stylized-concept
Asset type: production 2D side-scrolling action-game boss sprite sheet, transparent RGBA
Primary request: Void Sentinel, a compact but imposing first-chapter guardian construct, with a sharply faceted near-black indigo shell, broken floating crown shards close to its head, one hot amber eye and a violet core. It should be more compact and simpler than the monumental Starfall Guardian, an early-world sentinel. No weapon.
Style/medium: painterly hand-detailed 2D game illustration, strong silhouette and readable dark-fantasy material texture; NOT pixel art, NOT 3D, NOT photoreal.
Composition/framing: exact square 2x2 sheet, four equal isolated cells with transparent gutters. Same full-body Sentinel at same scale facing right in each; fill about 76% of cell height; lower silhouette at roughly 88%, clear margins.
Subject poses: upper left still idle, upper right slight float/turn, lower left compressed lunge wind-up, lower right braced recovery. Same shell, eye, crown shapes and proportions across frames.
Lighting/mood: restrained violet shadow with small amber eye light and a faint warm edge.
Constraints: genuinely transparent background, no environment, floor, ground shadow, particles, text, UI, logo, watermark, borders, dividers, detached crown debris, extra characters or props. No cell bleed.
~~~

### Abyss Warden

~~~text
Use case: stylized-concept
Asset type: production 2D side-scrolling action-game boss sprite sheet, transparent RGBA
Primary request: Abyss Warden, a towering ancient guardian in battered deep-sea plate, broad angular shoulder silhouette, dark blue-black iron, tideworn bronze fittings and a dim cyan eye; unmistakably a boss, not a human soldier. Full body, no weapon.
Style/medium: painterly hand-detailed 2D game illustration, clean readable outer contour, textured armor, restrained cinematic finish; NOT pixel art, NOT 3D, NOT photoreal.
Composition/framing: exact square 2x2 sprite sheet, four equal isolated cells with transparent gutters. Same boss at same scale facing right in each. Full body in every cell; foot/lowest silhouette at 88% cell height; use about 78% cell height with generous clear margins.
Subject poses: upper left steady idle, upper right slight breathing/weight shift, lower left forward charge wind-up with body leaning right, lower right heavy recovery/guard stance. Keep the same identity, armor, colors and proportions.
Lighting/mood: cool subterranean teal edge light over near-black iron.
Constraints: genuinely transparent background, no floor, environment, shadows, effects, text, labels, UI, frame, divider, extra character, detached props, watermark. Nothing crosses cell boundaries.
~~~

### Echo Matriarch

~~~text
Use case: stylized-concept
Asset type: production 2D side-scrolling action-game boss sprite sheet, transparent RGBA
Primary request: Echo Matriarch, a large cave moth sovereign with an eerie feminine creature silhouette, layered translucent indigo wings and segmented pale teal mantle, pearl-like luminous eyes and muted cyan vein patterns; elegant but dangerous, not humanoid armor. No held object.
Style/medium: painterly hand-detailed 2D game illustration, clean readable contour, organic wing texture, refined dark fantasy; NOT pixel art, NOT 3D, NOT photoreal.
Composition/framing: exact square 2x2 sprite sheet, four equal isolated cells with transparent gutters. Same Matriarch, fully visible, facing right, same scale; lowest wing/body point near 88% cell height, silhouette about 78% cell height.
Subject poses: upper left wings folded idle, upper right wings slightly lifted, lower left wings spread for an incoming pulse, lower right settled after the pulse. Same face, markings, wing design, palette, proportions in every cell.
Lighting/mood: dim teal cave light through translucent deep-blue wings with restrained glow.
Constraints: genuinely transparent background; no floor, scenery, ground shadow, particles, attack rings, text, labels, UI, borders, dividers, extra creatures, detached elements or watermark. Keep every wing in its own cell.
~~~

### Ash Castellan

~~~text
Use case: stylized-concept
Asset type: production 2D side-scrolling action-game boss sprite sheet, transparent RGBA
Primary request: Ash Castellan, a formidable volcanic fortress knight boss with a broad stone-and-forged-iron silhouette, cracked charcoal armor, subdued ember-orange seams, rust-red mantle and heavy greaves. Keep the face hidden except for a narrow hot amber visor; no sword or held prop.
Style/medium: painterly detailed 2D game illustration, substantial sculpted armor forms and clear clean silhouette; NOT pixel art, NOT 3D, NOT photoreal.
Composition/framing: exact square 2x2 sprite sheet, four equal isolated cells, transparent gutters. Full body, same scale and right-facing silhouette in all cells; boots near 88% cell height; about 78% cell height overall with margins.
Subject poses: upper left planted guard, upper right measured walk, lower left unmistakable forward charge telegraph, lower right braced recovery. Preserve identical armor identity and color in every frame.
Lighting/mood: low volcanic light, restrained ember seams against dark ash metal.
Constraints: genuinely transparent background; no floor, environment, cast shadow, fire, sparks, text, letters, labels, UI, borders, dividers, extra characters or props, watermark. No cell bleed.
~~~

### Hollow Sovereign

~~~text
Use case: stylized-concept
Asset type: production 2D side-scrolling action-game boss sprite sheet, transparent RGBA
Primary request: Hollow Sovereign, a frightening spectral monarch boss floating just above the ground, narrow crown-like horn silhouette, layered tattered midnight-violet mantle, pale stone mask with a single restrained blue-white eye. Distinct from armored human knights; no handheld weapon.
Style/medium: painterly hand-detailed 2D game illustration with elegant ghostly edges but solid readable silhouette, dark fantasy; NOT pixel art, NOT 3D, NOT photoreal.
Composition/framing: exact square 2x2 sprite sheet with four equal cells and transparent gutters. Same full-body creature in every cell, facing right, same scale; silhouette fills about 78% of cell and stays inside margins.
Subject poses: upper left quiet hover; upper right mantle drifting back; lower left charging lunge toward the right; lower right receding guard hover after strike. Keep crown, mask, mantle and proportions consistent.
Lighting/mood: restrained cold starlight and subtle violet-blue rim against dark fabric.
Constraints: genuinely transparent background; no floor, scenery, particles, spell effects, text, logo, watermark, frame, dividers, extra characters, props, or cell bleed.
~~~

### Starfall Guardian

~~~text
Use case: stylized-concept
Asset type: production 2D side-scrolling action-game boss sprite sheet, transparent RGBA
Primary request: Starfall Guardian, an ancient astral observatory construct boss: tall poised stone-and-brass sentinel, faceted dark amethyst chest, layered silver-lilac shoulder plates and a compact star-like cyan core. Its design should feel engineered and monumental, not a normal person in clothes. No held weapon.
Style/medium: painterly, precise 2D game illustration with believable stone and brushed metal texture, crisp recognisable silhouette; NOT pixel art, NOT 3D, NOT photoreal.
Composition/framing: exact square 2x2 sprite sheet, four equal isolated cells and transparent gutters. Same full-body Guardian facing right at same scale, occupying about 78% cell height, feet at roughly 88% with generous margins.
Subject poses: upper left sentinel idle, upper right core brightening while poised, lower left deliberate charge wind-up, lower right heavy recovery with one arm raised. Keep identical construct identity and palette.
Lighting/mood: cold dusk-violet ambient light with small cyan highlights on the core.
Constraints: genuinely transparent background, no environment, floor, ground shadow, particles, starbursts, text, labels, interface, borders, dividers, extra characters, detached parts or watermark. No cell bleed.
~~~
