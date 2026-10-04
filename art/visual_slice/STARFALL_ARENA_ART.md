# Starfall arena art — 2026-09-27

Built-in ImageGen generated two new background paintings and one genuinely
transparent 2D throne sprite. No CLI, 3D model or Blender asset was used. Source
pixels were copied unchanged into the project, retaining the original sources.

| Saved asset | Use | Import maximum edge |
| --- | --- | --- |
| [empty_court_depth_v1.png](empty_court_depth_v1.png) | Guardian's abandoned open-air court | 1024px |
| [hollow_throne_depth_v1.png](hollow_throne_depth_v1.png) | Sovereign's ruined hall | 1024px |
| [hollow_seat_v1.png](hollow_seat_v1.png) | Separate alpha throne sprite | 512px |

Background sources are 1536×1024; the returned throne source is 1280×1280.
All three imports have mipmaps. The throne alpha bounds determine its scale and
ground contact (bottom y=425, height <=250). It is scenery, not an interaction.

## Integration

`StarfallArenaArt.gd` extends the existing room-depth component, reusing its
camera-relative painting/haze shader and 20 Hz update cap with hidden-room sleep.
Only the two explicit arena scenes opt in. The original Sky polygon is painted
without moving or changing its vertices. Eight explicitly named background
leaves are hidden (three Court / five Throne), not gameplay parents. Existing
boss art, attack warnings, doors, lamps, rewards and collision are untouched.

Sixteen original walking-surface polygons reuse the existing Starfall masonry
texture with thin rim/seam/end-strap details (166 static Line2D nodes total).
The broken central span retains its exact polygon. Rims remain inside the old
surface, with no changed jump edge. Two dark foundation polygons fill only the
space below the solid floor; neither has physics. Static details have no per-frame
animation. The throne draws at z=-5, behind combat and platforms.

## Verification and remaining work

8/8 targeted smoke tests pass: dedicated art invariants, Court combat, final boss,
boss-lamp reveal, arena navigation, Starfall route, room doors and the previous
nine-room painted-depth coverage. Full suite not run (177 active scripts).
The dedicated test validates genuine alpha, texture budgets, original geometry,
collision/one-way state, leaf-only hiding, grounded throne, separate camera depth
rates, camera zoom/origin handling, hidden sleep and idempotence.

Six GPU captures in `art/characters/preview_arena_*` were visually inspected:
close, wide and real boss attack warning for both arenas. The warnings remain
visible over the paintings. `_tmp_arena_art_preview2.log` has successful captures
and only known host root-certificate / denied shader-cache-write diagnostics.
No script or shader compilation errors were found. Mobile performance and a full
manual combat playthrough are not certified by these checks.

The first art smoke expected nine Throne surfaces; inspection confirmed eight,
so the count assertion was corrected. A test-only detached-owner warning was
also corrected before the accepted run. Gameplay code was not changed.

Boss bodies and some caches/doors remain prototype shapes. Next passes should
cover their 2D art, the separate Broken Ramparts expedition, city sky and remaining
Shaft/Echo/Ash room backgrounds without copying one image everywhere.

## Exact prompt set and source paths

### empty_court

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-11cfbe8e-f2a1-433c-8e27-7809219aa827.png`

```text
Use case: stylized-concept. Asset type: production opaque 1536x1024 background for a 2D side-scrolling dark-fantasy game. Painterly illustrated scenery, broad readable shapes, NOT photograph or 3D render. Low contrast and dim midtones behind gameplay, restrained highlights. Wide layered background viewed side-on, no playable foreground floor, no characters, no enemies, no text, UI, watermark or apparent exit doors. No heavy vignette. Subject: an abandoned open-air ceremonial courtyard of Starfall, distant weathered arcades and broken slender colonnades, a ruined circular stone frieze high in the rear wall, empty niches, receding outer-city roof silhouettes beyond breaches. Cold blue-gray and desaturated indigo, thin silver dusk haze, a quiet solemn sense of space. Avoid a throne or bright magic circles.
```

### hollow_throne

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-8949a144-b67f-4970-82b9-550b1ed9fef0.png`

```text
Use case: stylized-concept. Asset type: production opaque 1536x1024 background for a 2D side-scrolling dark-fantasy game. Painterly illustrated scenery, broad readable shapes, NOT photograph or 3D render. Low contrast and dim midtones behind gameplay, restrained highlights. Wide layered background viewed side-on, no playable foreground floor, no characters, no enemies, no text, UI, watermark or apparent exit doors. No heavy vignette. Subject: the rear architecture of a ruined final-boss royal hall, tall ribbed arches and fractured high windows, broken concentric masonry ornament in a collapsed vaulted apse, dim hanging faded plum cloth and layers of violet-gray atmospheric dust. Charcoal plum, dusty lavender and tarnished pewter. Lower middle is unobtrusive dark stone behind combat. No throne or furniture; the throne will be a separate game sprite. No glowing hazards.
```

### hollow_seat

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-1d15ddb7-33f7-45db-8adb-58ba8c62bbed.png`

```text
Use case: stylized-concept. Asset type: single transparent-background 2D environment prop sprite, 1024x1024. Subject: one empty ancient ruined royal stone throne for a dark-fantasy side-scrolling game. Front elevation, slightly visible seat plane, entirely visible with generous transparent padding around all sides. Tall narrow broken crown-shaped backrest, worn carved ribs, simple heavy armrests, two squat supports joined by a stone plinth. Muted slate-plum masonry, subtle chipped silver trim, fine worn cracks. Painterly hand-painted illustration with clear silhouette and broad shading, not a 3D render or photo. No character, cushion, skulls, plants, floor, cast shadow outside object, backdrop, text, watermark or glow. Genuinely transparent alpha background; no checkerboard painted into pixels. Exactly one throne, no sprite sheet.
```
