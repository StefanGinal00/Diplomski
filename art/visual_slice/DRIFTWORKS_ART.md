# Driftworks painted art — 2026-09-27

Three 2D bitmap assets created with the imagegen skill and built-in ImageGen (not CLI or Blender). Returned images were copied unchanged into this folder. The cart has genuine alpha; code reads its visible foot row for placement without modifying pixels.

## Integration

- `DriftworksPaintedArt.gd` specializes the shared `RampartPaintedArt.gd` treatment for Shaft only, enabled by `ExpeditionWing.painted_driftworks_enabled`.
- 24 painted backplates cover eight main chambers, four side chambers and twelve links. A shared material uses continuous room-wide UVs with mirrored sampling; these are crops of one painting, not 24 unique images.
- 73 existing horizontal surfaces receive iron texture and thin collision-aligned rims. Original geometry, transforms, collision, tasks and streamed actors are preserved.
- 132 explicitly scoped prototype PumpRib/PipeCap/outline leaves are hidden; working pump controllers and field boards remain.
- Four decorative ore carts reuse one sprite at main chambers 0, 3, 5 and 7. Supported-floor anchors avoid the large field boards. They are not obstacles, loot or interactables.
- Painting imports are capped at 1024px; iron and cart at 512px, all mipmapped. Camera-relative painting/haze reuse the existing 20 Hz update and hidden-room sleep. Static sprites do not animate.
- Editor schematic receives painted backgrounds; full floor texture/cart coverage is built with runtime terrain.

## Verification and limits

9/9 unique targeted smoke tests passed: new art invariants, shared Ramparts regression, Shaft infrastructure, expedition population support, live normal Driftworks route, earned return route, expedition dressing, jump routes and expanded layouts. Art invariants were rerun after the final decorative cart-position adjustment. Full suite (179 active scripts) was not run.

Five GPU views were captured and reviewed: intake, pressure main, side pump, outflow and wide. Intake/pressure/outflow were reviewed again after moving carts away from field boards. Final log: `_tmp_drift_art_preview2.log`. It contains only known host root-certificate and denied shader-cache-write diagnostics, no script/shader compilation failures. This is not mobile performance certification or a timed manual playthrough.

Other Shaft rooms, foreground walls, flora, field boards and machinery still need visual passes. The current prototype silhouettes remain visible alongside the new painting; this does not finish the entire zone or map.

## Exact generation prompts and provenance

### driftworks_depth_v1

Saved: [driftworks_depth_v1.png](driftworks_depth_v1.png)

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-8349fb79-920e-4a67-bcf6-d61b5c5ced74.png`

```text
Use case: stylized-concept. Asset type: opaque 1536x1024 painted parallax background for a 2D side-scrolling dark-fantasy game. Subject: deep abandoned underground mining pumpworks, naturally fractured damp rock walls, heavy timber support ribs, old iron lift cages and pulley wheels receding into blue-green mist, large oxidized drainage pipes and dim distant reservoir reflections. Mining engineering inside a cave, NOT a castle, cathedral, modern factory or sci-fi station. Hand-painted illustration with broad shapes, soft layered depth, low contrast behind combat, restrained petrol blue and charcoal teal with dull rust accents. Entire image distant scenery, no playable foreground floor or rails, no people, enemies, readable text, UI, logo, watermark, bright light or apparent exit doors. Even detail across composition, no central hero object or heavy vignette.
```

### drift_iron_v1

Saved: [drift_iron_v1.png](drift_iron_v1.png)

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-17cde634-aa72-4079-af95-f5798c8b64c6.png`

```text
Use case: stylized-concept. Asset type: opaque square 1024x1024 seamless game surface texture. Flat front-on orthographic material swatch of old horizontal iron structural plates in a flooded mine: staggered long rectangular iron panels, narrow recessed seams, small subdued rivets along their edges, worn charcoal-blue steel with sparse dull reddish oxidation and faint scratches. Painterly 2D illustration, broad restrained details readable when applied to thin platform sides. Uniform diffuse lighting, no perspective, no 3D render, no objects, floor, borders, lettering, logos, watermark or focal symbol. Seamless repeating edges, no dramatic highlights or dark vignette.
```

### drift_ore_cart_v1

Saved: [drift_ore_cart_v1.png](drift_ore_cart_v1.png)

Source: `C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/exec-adabc7b7-15c3-4f76-a2bf-6691fcd378a1.png`

```text
Use case: stylized-concept. Asset type: single transparent-background 2D game scenery sprite, 1024x1024. Exactly one old squat iron mining cart loaded with a modest pile of dull dark ore stones, side elevation with two clearly visible small metal wheels aligned on one horizontal ground line. Riveted weathered charcoal-teal metal tub with narrow rusted edging, readable wheel rims and simple axle. Hand-painted dark-fantasy illustration, clean silhouette and broad subtle shading, not photograph or 3D render. Entire object fully visible, generous transparent padding on every side. No rails, floor, cast shadow outside object, scenery, human, handles resembling weapons, glowing ore, letters, UI, logo, watermark or sheet. Genuine transparent alpha around cart, no painted checkerboard.
```
