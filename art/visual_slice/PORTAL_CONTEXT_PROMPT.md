# Portal cliff modules — 2026-09-30

Mode: built-in imagegen, new original raster generation; not CLI/API fallback.
Final asset: `art/visual_slice/portal_cliff_modules_v1.png`.
Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-be3c8d2f-40ae-4f2e-9d65-95de82733d6a.png`.
Copied unchanged with alpha preserved. Actual output is 1330 x 1182, not the
requested dimensions. Godot imports at a 1024 px maximum edge with mipmaps.
One shared texture, 4,968,604 decoded bytes including mipmaps; this is not a
measurement of total game memory or phone performance.

## Final prompt

Use case: stylized-concept. Asset type: original 2D side-scrolling dark fantasy modular cliff masonry atlas, transparent alpha. Exactly three equal vertical columns in one row with large transparent gutters, each object entirely inside its own column. Each column contains ONE tall, broad, solid vertical rock face / wall buttress, approximately twice as tall as wide. Left: rough damp slate cliff face with layered crags, scattered moss, thin trailing roots. Middle: weathered charcoal mine rock buttress with two embedded timber braces and rusty iron straps. Right: ancient ruined gothic masonry buttress, chipped pale gray blocks, carved narrow blind niches, silver-green ivy. These are SOLID cliff/wall segments which will be placed beside and above separate doorways, NOT isolated doors and NOT backgrounds. Jagged but substantial outer silhouette, opaque textured rock body, level rocky foot contact, no cast ground shadow. Straight-on side-scroller elevation, hand-painted detailed readable 2D game art, no pixel art, no 3D perspective. Muted teal gray slate, dark weathered wood, ivory-gray stone; restrained highlights. Genuine transparent background outside each wall segment, no landscape, no ground plane, NO doors or holes, NO signs, NO text or logos. Keep all three pieces separate with at least 40 px transparent gutters and 30 px canvas margins. Requested 1800x1600, retain crisp material detail.

## Integration

`PortalContextArt.gd` samples three bounded AtlasTexture regions: damp slate,
timber-braced mine rock, and ivy-clad gothic masonry. The artwork decorates
textured recess geometry and audited outer boundaries, not standalone doors.
No third-party graphic was downloaded or added in this pass.
Kenney's official New Platformer Pack was checked as a CC0 candidate:
https://kenney.nl/assets/new-platformer-pack . It is not incorporated here;
using it wholesale would introduce a different visual style.
