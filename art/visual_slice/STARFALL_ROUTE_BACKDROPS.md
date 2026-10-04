# Starfall route backgrounds — 2026-09-27

Five opaque 1536×1024 paintings generated with built-in ImageGen (not the CLI).
Original pixels are preserved; Godot imports use a 1024px maximum edge and mipmaps.
These are 2D background assets, not 3D models or final foreground art.

| Scene | Saved asset | Surfaces |
| --- | --- | --- |
| StarfallOutskirts | [rampart_depth_v1.png](rampart_depth_v1.png) | 14 |
| StarfallSilentGate | [silent_gate_depth_v1.png](silent_gate_depth_v1.png) | 14 |
| StarfallRootedHall | [rooted_depth_v1.png](rooted_depth_v1.png) | 14 |
| StarfallSoulCrucible | [crucible_depth_v1.png](crucible_depth_v1.png) | 14 |
| StarfallSunlessPassage | [sunless_depth_v1.png](sunless_depth_v1.png) | 14 |

## Integration and limits

Each scene names its original entrance plate explicitly. That entrance and its
seven expanded chambers/six shafts share one painting/material and continuous
room-wide UVs. No geometry, collisions, doors, actors or progression changed.
Distinct palettes preserve exterior ramparts, sealed gates, living roots,
ritual machinery and dark processional architecture. Memory Vault retains its
own previously generated image: all six StarfallDescent routes are now covered.
Broken Ramparts' separate expedition wing, Empty Court, final boss arena and
the rest of the city's scenery are not newly painted by this pass.

Far imagery and procedural haze use different camera-relative offsets; updates
are capped at 20 Hz and stop in hidden rooms. Starfall's enormous bounds now use
scene_scale=max(1, bounds_width/2600) and mirrored continuation to reduce image
magnification without restarting UVs at chamber boundaries. Mirrored motifs
can recur across a long route; these are not individually painted chambers.
Other profiles keep scale 1. Platforms, large foreground pillars, roots and
puzzle props still visibly use prototype shapes and need separate art work.

## Validation

11/11 targeted regression tests pass after the scale adjustment; the full suite
was not run. Expanded painted-depth coverage checks nine distinct images across
135 surfaces, imported texture sizes/mipmaps, unchanged geometry/physics,
continuous UVs, Starfall scale, camera movement/zoom, translated room origins,
hidden-room sleep and idempotence. See tests/LATEST_SMOKE_RESULTS.md.

The preview script captured 19 GPU images. Close and wide views of the five new
routes, the adjusted Memory Vault, and a Cistern regression view were inspected.
Known host certificate and denied shader-cache-write diagnostics remain in the
preview log; no script or shader compilation error was found. This does not
certify final art quality, mobile performance or every camera position.

## Exact prompts and generated source files

Source directory for the filenames below:
`C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/`.

### rampart

Saved: `art/visual_slice/rampart_depth_v1.png`

Generated source: `exec-d13b7ed2-dcd4-43e9-8af6-f72dc20b9098.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game background, opaque landscape 1536x1024. Painterly illustrated scenery with restrained shapes and soft atmospheric depth, not a photoreal photograph or 3D render. Entire composition is distant background; no playable foreground platform or floor. Low contrast, dim midtones and sparse highlights so enemies and terrain remain readable over it. Broad composition suitable for continuous cropping across large irregular chambers. No text, readable glyphs, characters, enemies, UI, logos, watermark, or obvious exit doors; no central hero object or heavy vignette. Subject: Starfall's ruined outer defenses overlooking an abandoned moonless city: staggered broken battlements, collapsed distant siege towers, splintered parapets, torn faded military cloth and scattered stonework fading into dusty blue-violet dusk. Exterior open depth, distant skyline behind breached walls, not an indoor cathedral. Desaturated slate and dusty mauve.
```

### silent_gate

Saved: `art/visual_slice/silent_gate_depth_v1.png`

Generated source: `exec-7097f6ea-5158-4b9b-b554-f0a99a26de60.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game background, opaque landscape 1536x1024. Painterly illustrated scenery with restrained shapes and soft atmospheric depth, not a photoreal photograph or 3D render. Entire composition is distant background; no playable foreground platform or floor. Low contrast, dim midtones and sparse highlights so enemies and terrain remain readable over it. Broad composition suitable for continuous cropping across large irregular chambers. No text, readable glyphs, characters, enemies, UI, logos, watermark, or obvious exit doors; no central hero object or heavy vignette. Subject: Silent monumental gate circuit inside an abandoned stone fortress: thick interlocking sealed gate slabs viewed among receding buttresses and arch fragments, small worn circular ward ornaments with no writing, hanging chains disappearing into cool haze. Sealed architectural barrier motif, not a traversable glowing doorway. Somber dark indigo and muted pewter, minimal pale-violet light.
```

### rooted

Saved: `art/visual_slice/rooted_depth_v1.png`

Generated source: `exec-09ff90bd-439f-4501-8e8c-686dc8accee9.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game background, opaque landscape 1536x1024. Painterly illustrated scenery with restrained shapes and soft atmospheric depth, not a photoreal photograph or 3D render. Entire composition is distant background; no playable foreground platform or floor. Low contrast, dim midtones and sparse highlights so enemies and terrain remain readable over it. Broad composition suitable for continuous cropping across large irregular chambers. No text, readable glyphs, characters, enemies, UI, logos, watermark, or obvious exit doors; no central hero object or heavy vignette. Subject: An underground ruined hall slowly reclaimed by ancient vegetation: enormous twisting tree roots embedded in cracked masonry and winding between distant stone arches, layered root curtains, sparse ferns and lichen, drifting green-gray haze. Organic asymmetry and living growth, no castle skyline. Muted sage, blue-green and dark slate, sparse soft moss glow.
```

### crucible

Saved: `art/visual_slice/crucible_depth_v1.png`

Generated source: `exec-36ab5ded-aabe-46a6-9b81-3914092266ab.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game background, opaque landscape 1536x1024. Painterly illustrated scenery with restrained shapes and soft atmospheric depth, not a photoreal photograph or 3D render. Entire composition is distant background; no playable foreground platform or floor. Low contrast, dim midtones and sparse highlights so enemies and terrain remain readable over it. Broad composition suitable for continuous cropping across large irregular chambers. No text, readable glyphs, characters, enemies, UI, logos, watermark, or obvious exit doors; no central hero object or heavy vignette. Subject: An abandoned ritual soul-crucible chamber deep inside Starfall: multiple weathered stone and metal basins suspended at different distances, broken circular conduits and hanging chains, ash-coated ribbed vault masonry, faint violet ember light contained inside small bowls. Arcane industrial ruin, not a forge with orange lava, no sci-fi machines. Desaturated plum, charcoal and tarnished silver with restrained amethyst haze.
```

### sunless

Saved: `art/visual_slice/sunless_depth_v1.png`

Generated source: `exec-650b2222-1c56-44fe-a18a-8d6761f8aa99.png`

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling dark-fantasy game background, opaque landscape 1536x1024. Painterly illustrated scenery with restrained shapes and soft atmospheric depth, not a photoreal photograph or 3D render. Entire composition is distant background; no playable foreground platform or floor. Low contrast, dim midtones and sparse highlights so enemies and terrain remain readable over it. Broad composition suitable for continuous cropping across large irregular chambers. No text, readable glyphs, characters, enemies, UI, logos, watermark, or obvious exit doors; no central hero object or heavy vignette. Subject: A sunless processional passage descending into deep silence: successive tall worn funerary columns and empty niches, broken ceremonial screens, faded hanging cloth, a few tiny cold lanterns at varying depths, stone surfaces gradually swallowed by layered blue-black fog. Long solemn rhythm with empty negative space, no throne, no people or skeletons. Almost monochrome midnight blue and cool slate with faint pearl accents.
```
