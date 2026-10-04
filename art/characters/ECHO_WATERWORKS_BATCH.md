# Echo waterworks guides and instruments - 2026-09-28

## Delivery and provenance

Built-in imagegen, six independent new-generation calls; no input references, no CLI/API fallback, no image pixel manipulation. All originals retained under `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/`. Six native 1254x1254 RGBA PNGs copied into the project, alpha bounds inspected with System.Drawing, mipmaps enabled. Art uses native resolution regions and uniform scaling, not distorted resizing.

| Asset | Saved project path | Original filename |
| --- | --- | --- |
| rill | `art/characters/echo_rill_v1.png` | `exec-def6dcb0-3dfb-41a0-ae5f-89f474d2c1e6.png` |
| taren | `art/characters/echo_taren_v1.png` | `exec-5d6c6251-9db3-49bb-99f6-f61b10197b4d.png` |
| odel | `art/characters/echo_odel_v1.png` | `exec-8e30e0f0-f72f-4c40-adf1-ee07d93cc6ab.png` |
| valve | `art/visual_slice/echo_valve_v1.png` | `exec-cd1465fc-fc15-401a-9057-fe2a37b462bf.png` |
| anchor | `art/visual_slice/echo_anchor_v1.png` | `exec-09041412-04cd-4c9f-bfcb-9e8b2fadb370.png` |
| drain | `art/visual_slice/echo_drain_v1.png` | `exec-c978599b-087d-45c4-bb59-419a88cdc6d6.png` |

## Integration

- Rill (TideWell), Taren (CrystalCauseway), Odel (UndertowVault): three distinct four-pose sheets, twelve new poses. `EchoGuideAppearance.gd` now covers six specific field-guide regions including the earlier Venn/Oris/Senn. Simple two-key walk presentation, not a fully hand-authored animation cycle. Uses native displacement, facing, attention, talk/pause; native AI, dialogue, portraits and 34 px interaction reach unchanged.
- Feet remain registered to existing camp floor (local y=24); names/prompts retain clear bands above low camp walkways. All six guide regions pass true floor contact and label/terrain checks. Other guide regions still keep original bodies.
- Two flow valves, two bridge chain tensioners and two drain controls use new images via `EchoDeviceArt.gd`. All 18 explicitly dressed Echo devices (five kinds) now have paintings. Other unrelated SluiceValve instances are not opted in. Compact images fit y=-11..25 (36 px height). Original controller transform, floor geometry and reach unchanged.
- Status indication uses existing blue/green marker plus check shape, retaining readable non-colour feedback. These prop paintings are static; wheel/ratchet/lever and painted water do not mechanically animate. Actual current/bridge/channel scenery still follows existing controllers. The gallery's listening column is a cosmetic setter demonstration, not a new valve mechanic.
- Six device interaction prompts previously sat under their floors. A deferred, size-change-driven placement searches five bounded overhead bands against real route terrain and the status label. No per-frame polling, extra gameplay node, or changed text/input handling. All six have resolved placements without terrain overlap.
- Existing lazy guide population and inactive-room process disabling retained. PNGs are shared preloads, not on-demand texture streaming.

## Validation

10/10 unique targeted regressions passed; full suite not run. `tests/LATEST_SMOKE_RESULTS.md` links exact reports.

Expanded `echo_guide_appearance_smoke.gd` covers all six guides, twenty-four poses in both facings, stepped native patrol/talk, immutable shape/reach, hidden relocation, alpha/mipmaps, actual support and label clearance, lazy spawn/reentry/off-room processing and untouched Grotto guide. `echo_device_art_smoke.gd` retains all 18 device checks and adds six new devices' painted terrain clearance and clear instruction bands. `echo_field_operations_smoke.gd` now checks artwork activation along with real native controls at partial completion, full completion, save rollback and completed reload, including reward gates and deduplication.

The first added operations assertion had an untyped inferred local; the test parser rejected it. Fixed with `Node2D` and rerun successfully; no gameplay code was changed for this. Known certificate-store warning remains. Headless import exits 0 but cannot save sandboxed global AppData editor settings.

`tests/preview_echo_waterworks.gd` reuses the isolated-save GPU workflow: twelve inspected captures under `art/characters/preview_echo_waterworks_*.png` (two pose galleries, one cosmetic device-state gallery, three live guide camps, six live device alcoves). Log `.tmp-echo-waterworks-preview.log`, exit 0. The prior guide preview now explicitly selects its own three regions so expanded coverage cannot overflow its sheet. No manual end-to-end playthrough or whole-map visual acceptance claimed.

## Next visual priorities

Leth and expedition/Shaft guides; camp rescue poles, surveying tripods and other large geometric scenery; remaining root terrain faces and fauna labels under low ledges. This batch does not mark map artwork complete.

## Exact prompts

### rill

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game character sprite sheet, genuinely transparent RGBA background. Painted crisp readable silhouette, restrained detail, NOT 3D, NOT pixel art. Exact square 2x2 grid, FOUR full-body poses of SAME human adult character. Every quadrant has generous transparent margins. Face and body oriented RIGHT in all poses, boots grounded on same local baseline at 88% of cell height; character height 76% of each cell. Top-left: relaxed standing. Top-right: walking with LEFT foot forward. Bottom-left: walking with RIGHT foot forward (clearly opposite stride, not same pose). Bottom-right: standing conversation, one hand gesturing toward right. Maintain identity, outfit and proportions across cells. No backgrounds, cast shadows, floor, particles, frame borders, grid lines, labels or text; no weapons or detached objects; never cross cell boundaries. Subject: Rill the well keeper: adult woman with dark warm skin, cropped tightly curled hair, teal waterproof short coat over gray practical trousers, pale woven neck scarf, brass fasteners, short rubberized dark boots, small coil of thin rescue rope attached to belt. Calm practical friendly face; compact outfit with water-worn fabric, no big hat.
```

### taren

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game character sprite sheet, genuinely transparent RGBA background. Painted crisp readable silhouette, restrained detail, NOT 3D, NOT pixel art. Exact square 2x2 grid, FOUR full-body poses of SAME human adult character. Every quadrant has generous transparent margins. Face and body oriented RIGHT in all poses, boots grounded on same local baseline at 88% of cell height; character height 76% of each cell. Top-left: relaxed standing. Top-right: walking with LEFT foot forward. Bottom-left: walking with RIGHT foot forward (clearly opposite stride, not same pose). Bottom-right: standing conversation, one hand gesturing toward right. Maintain identity, outfit and proportions across cells. No backgrounds, cast shadows, floor, particles, frame borders, grid lines, labels or text; no weapons or detached objects; never cross cell boundaries. Subject: Taren the bridge mender: stocky adult man with auburn hair and short beard, rolled sleeves, weathered slate-blue work waistcoat over ochre shirt, dark leather work apron to knees, compact tool belt with a small wrench, reinforced dark boots. Friendly sturdy worker, no helmet; copper buckles and blue-gray cloth.
```

### odel

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game character sprite sheet, genuinely transparent RGBA background. Painted crisp readable silhouette, restrained detail, NOT 3D, NOT pixel art. Exact square 2x2 grid, FOUR full-body poses of SAME human adult character. Every quadrant has generous transparent margins. Face and body oriented RIGHT in all poses, boots grounded on same local baseline at 88% of cell height; character height 76% of each cell. Top-left: relaxed standing. Top-right: walking with LEFT foot forward. Bottom-left: walking with RIGHT foot forward (clearly opposite stride, not same pose). Bottom-right: standing conversation, one hand gesturing toward right. Maintain identity, outfit and proportions across cells. No backgrounds, cast shadows, floor, particles, frame borders, grid lines, labels or text; no weapons or detached objects; never cross cell boundaries. Subject: Odel the reservoir keeper: older slim human man with brown skin, gray hair under a close-fitting dark cap, long mustache, deep green waxed knee-length coat with worn tan trim, a small brass water-level measuring instrument at belt, dark trousers and worn leather boots. Patient kind face, distinct narrow silhouette, no staff.
```

### valve

```text
Use case: stylized-concept. Asset type: 2D side-scrolling game interactive prop cutout. ONE full object centered, orthographic front view, hand-painted dark-fantasy style, crisp readable edges, weathered metal details. Genuinely transparent RGBA background, no ground shadow, no room, no floor, no text, no border. Whole object visible with 10% transparent margins. Small sturdy flat foot/base at bottom. Muted blue-gray metal and aged brass, subtle cyan glass, no bloom outside silhouette. Compact, approximately square body silhouette suitable for a small low-ceiling alcove. Object: a compact free-standing ancient water regulator: prominent round brass five-spoke valve wheel mounted on a short vertical blue-gray pipe, two small horizontal pipe stubs at bottom attached to a low rectangular base, rivets, a tiny dark cyan indicator window. No disconnected pipes, no labels or digits. Make wheel and pipe equally legible at tiny game scale.
```

### anchor

```text
Use case: stylized-concept. Asset type: 2D side-scrolling game interactive prop cutout. ONE full object centered, orthographic front view, hand-painted dark-fantasy style, crisp readable edges, weathered metal details. Genuinely transparent RGBA background, no ground shadow, no room, no floor, no text, no border. Whole object visible with 10% transparent margins. Small sturdy flat foot/base at bottom. Muted blue-gray metal and aged brass, subtle cyan glass, no bloom outside silhouette. Compact, approximately square body silhouette suitable for a small low-ceiling alcove. Object: a compact free-standing mechanical bridge chain tensioner: two squat blue-gray iron upright supports bolted to a wide flat foot, crossbeam at top, central short hanging brass chain passing through a locking horizontal ratchet. Thick chunky links and aged metal plates, one small dark cyan indicator inset. Looks like actual bridge-maintenance hardware, not a nautical anchor. No cables extending outside base.
```

### drain

```text
Use case: stylized-concept. Asset type: 2D side-scrolling game interactive prop cutout. ONE full object centered, orthographic front view, hand-painted dark-fantasy style, crisp readable edges, weathered metal details. Genuinely transparent RGBA background, no ground shadow, no room, no floor, no text, no border. Whole object visible with 10% transparent margins. Small sturdy flat foot/base at bottom. Muted blue-gray metal and aged brass, subtle cyan glass, no bloom outside silhouette. Compact, approximately square body silhouette suitable for a small low-ceiling alcove. Object: a small free-standing sluice drain control housing: squat rectangular blue-gray riveted metal frame, central dark grated window with three clear vertical iron bars and a little turquoise water visible behind bottom half, short brass lever on right, low stone foot. Compact readable outline. Not a door, no wall and no surrounding pipes.
```
