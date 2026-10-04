# Echo field guides and painted instruments — 2026-09-28

## Delivery

Built-in imagegen mode, new generation, five independent calls; no CLI/API fallback, references, pixel editing or overwritten originals. Native 1254x1254 RGBA PNGs copied into the project. Alpha inspected with System.Drawing and in GPU composites; mipmaps enabled for game-scale rendering. Original sources retained in `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/`.

| Asset | Project path | Generated original |
| --- | --- | --- |
| venn | `art/characters/echo_venn_v1.png` | `exec-ebf8158b-5ad9-455e-93b4-cfea8ac085d9.png` |
| oris | `art/characters/echo_oris_v1.png` | `exec-86b6555b-2959-44cc-bea4-b2f35ea9d2c2.png` |
| senn | `art/characters/echo_senn_v1.png` | `exec-caa83cdd-fa82-4c75-b360-f2b6332e2bdb.png` |
| resonator | `art/visual_slice/echo_resonator_v1.png` | `exec-54249c38-f477-4628-bdbe-a7df7d7f3a68.png` |
| receiver | `art/visual_slice/echo_receiver_v1.png` | `exec-87e7e6c1-a9b3-448c-b308-b25d7043bd81.png` |

## Integration and limits

- Venn (Gallery), Oris (Archive), Senn (Nest): 3 distinct four-pose sheets, idle/two walking keys/conversation, both facings. Simple two-key walking presentation, not a complete hand-authored animation set. Runtime animation observes native displacement and attention/dialogue; never moves actors or changes dialogue.
- `EchoGuideAppearance.gd` attaches only for these three field regions. Original coat/face/accent and polygon animator are hidden, not deleted. Original animator is disabled. Painted feet registered at local y=24; actor origin, route markers and 34 px talk reach unchanged. Names and talk prompts sit above the low camp walkway.
- Guides retain existing lazy entry population and off-room process disabling; textures are shared preloads, not texture streaming. Other guides/residents and dialogue portraits are unchanged. NPCs are not eagerly instantiated for the editor preview.
- `EchoDeviceArt.gd`: 2 Grotto resonators and 10 route listening/signal receivers now use native transparent paintings with uniform scaling. Existing controllers still own attunement, recording, sequence resets and rewards. Status markers remain code-drawn for readability and redraw only on changes. Receiver art AND listening arc fit low shelf clearance. Three other device kinds keep prior code-native artwork.
- Original Grotto resonator images were 6/3 px above support: one deferred read-only rectangle-support pass grounds only their painted bounds, without changing the interaction transform.
- Duplicate childless `SilkAwning` contour retired only after the painted Nest tent exists. Camps, clues, platform collision and path topology unchanged.

## QA

10 unique targeted smoke tests pass; see `tests/LATEST_SMOKE_RESULTS.md` for reports. New guide regression exercises stepped native patrol in both directions, talk/attention/pause, hidden relocation, unchanged reach, mipmapped alpha, actual floor support and label/terrain separation in three rooms, lazy spawn/reentry/inactive processing, scope exclusion and tent-contour removal. Device regression retains all 18-device interaction/state checks and adds painted alpha/aspect/ground registration.

`tests/preview_echo_guides.gd`: nine isolated-save GPU captures: two 12-pose galleries, one six-state cosmetic device gallery, three actual guide camps, Grotto resonator, Gallery receiver, Depths receiver. The device gallery intentionally demonstrates cosmetic setters (a resonator has no gameplay listening phase). Latest accepted GPU log `.tmp-echo-guides-preview-final.log`. Full suite and manual end-to-end playthrough not run. Existing root-certificate warning remains; headless editor import also cannot save sandboxed global AppData editor settings. No project parse errors in accepted runs.

Initial preview referenced a nonexistent Depths child and exited 1; fixed to its actual `FieldOperations/Signal0`. First extended label regression used a Node2D-only property on a Label; fixed to `get_global_transform()` and rerun. These were verification-script errors, not shipped runtime changes.

Remaining: other guide identities, valve/anchor/drain paintings, root geometric props/terrain faces and additional contextual label cleanup. This batch does not declare the map's visual pass complete.

## Exact prompts

### venn

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game character sprite sheet, genuinely transparent RGBA background. Painted crisp readable silhouette, restrained detail, NOT 3D, NOT pixel art. Exact square 2x2 grid, FOUR full-body poses of SAME human adult character. Every quadrant has generous transparent margins. Face and body oriented RIGHT in all poses, boots grounded on same local baseline at 88% of cell height; character height 76% of each cell. Top-left: relaxed standing. Top-right: walking with left foot forward. Bottom-left: walking with right foot forward. Bottom-right: standing conversation, one hand gesturing toward right. Maintain identity, outfit and proportions across cells. No backgrounds, cast shadows, floor, particles, frame borders, grid lines, labels or text; no weapons or detached objects; never cross cell boundaries. Subject: Venn the cavern whisper keeper, a middle-aged human with short silver hair, dark navy layered coat with muted teal scarf, practical dark boots, small brass listening tube attached at belt. Calm observant face, readable blue-gray fabric folds and subtle cyan edge light. Compact travel clothing not oversized robes.
```

### oris

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game character sprite sheet, genuinely transparent RGBA background. Painted crisp readable silhouette, restrained detail, NOT 3D, NOT pixel art. Exact square 2x2 grid, FOUR full-body poses of SAME human adult character. Every quadrant has generous transparent margins. Face and body oriented RIGHT in all poses, boots grounded on same local baseline at 88% of cell height; character height 76% of each cell. Top-left: relaxed standing. Top-right: walking with left foot forward. Bottom-left: walking with right foot forward. Bottom-right: standing conversation, one hand gesturing toward right. Maintain identity, outfit and proportions across cells. No backgrounds, cast shadows, floor, particles, frame borders, grid lines, labels or text; no weapons or detached objects; never cross cell boundaries. Subject: Oris the record mender, an older human archivist with warm brown skin, short gray hair, round spectacles, plum-purple knee-length coat, faded parchment shoulder sash, small closed book pouch on hip, practical dark boots. Scholarly kind face. Muted violet and warm brass highlights, compact silhouette.
```

### senn

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game character sprite sheet, genuinely transparent RGBA background. Painted crisp readable silhouette, restrained detail, NOT 3D, NOT pixel art. Exact square 2x2 grid, FOUR full-body poses of SAME human adult character. Every quadrant has generous transparent margins. Face and body oriented RIGHT in all poses, boots grounded on same local baseline at 88% of cell height; character height 76% of each cell. Top-left: relaxed standing. Top-right: walking with left foot forward. Bottom-left: walking with right foot forward. Bottom-right: standing conversation, one hand gesturing toward right. Maintain identity, outfit and proportions across cells. No backgrounds, cast shadows, floor, particles, frame borders, grid lines, labels or text; no weapons or detached objects; never cross cell boundaries. Subject: Senn the silk watcher, a young adult human with dark hair tied back, muted moss-green hood folded behind neck, short layered teal-green coat, cream woven scarf, small silk spool attached at belt, dark practical boots. Gentle vigilant expression. Organic fabric textures, compact silhouette.
```

### resonator

```text
Use case: stylized-concept. Asset type: 2D side-scrolling game interactive prop cutout. ONE full object centered, orthographic front view, hand-painted dark-fantasy style, crisp readable edges, weathered metal details. Genuinely transparent RGBA background, no ground shadow, no room, no floor, no text, no border. Whole object visible with 10% transparent margins. Small sturdy flat foot/base at bottom. Muted blue-gray metal and aged brass, subtle cyan glass, no bloom outside silhouette. Object: a waist-high cavern listening resonator, one tall faceted cyan crystal clamped between two short curved brass tuning forks on a low rectangular stone plinth. Clear separate silhouette, roughly square footprint, crafted ancient acoustic instrument. Inactive quiet crystal, not an explosive magical effect.
```

### receiver

```text
Use case: stylized-concept. Asset type: 2D side-scrolling game interactive prop cutout. ONE full object centered, orthographic front view, hand-painted dark-fantasy style, crisp readable edges, weathered metal details. Genuinely transparent RGBA background, no ground shadow, no room, no floor, no text, no border. Whole object visible with 10% transparent margins. Small sturdy flat foot/base at bottom. Muted blue-gray metal and aged brass, subtle cyan glass, no bloom outside silhouette. Object: a small ancient acoustic receiver instrument, a shallow concave brass listening dish facing diagonally up on a short stem, compact rectangular blue-gray control box beneath with four dark glass meter slits and a small round indicator, low flat foot. Roughly square silhouette, believable carefully crafted mechanical parts. No cables trailing outside the object.
```
