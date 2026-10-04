# Remaining world backgrounds — 2026-09-27

24 new opaque 1536 × 1024 PNG paintings were generated using the built-in
ImageGen tool and the imagegen skill, not a CLI or downloaded asset library.
Original pixels are preserved. Follow-up imports now retain the native 1536px
edge with mipmaps: see [visibility/detail repairs](BACKGROUND_QUALITY_REPAIR.md).
The initial 1024px cap and entry coverage were insufficient. These are 2D
distant scenery, not 3D models.

## Coverage

RemainingRoomArt.gd extends the existing painted-depth system: 342 background
masks across the following 24 profiles. Each room gets its own source picture,
with continuous UVs across its chambers and shafts. Existing Echo Grotto,
Blackwater Cistern, Prism Archive, Forge, six Starfall routes, Starfall arenas,
the two safe villages, Driftworks and Ramparts retain their previous art.
Starfall gets a sky over the upper city; its existing market artwork remains.

| Scene / location | New file in this directory | Masks |
| --- | --- | --- |
| VerticalChamber | [shaft_cutting_depth_v1.png](shaft_cutting_depth_v1.png) | 17 |
| ShaftHollow | [shaft_hollow_depth_v1.png](shaft_hollow_depth_v1.png) | 17 |
| DrownedCrossing | [drowned_crossing_depth_v1.png](drowned_crossing_depth_v1.png) | 17 |
| FloodedGallery | [flooded_gallery_depth_v1.png](flooded_gallery_depth_v1.png) | 17 |
| WardenApproach | [warden_approach_depth_v1.png](warden_approach_depth_v1.png) | 18 |
| VerticalChamber / Warden arena | [warden_arena_depth_v1.png](warden_arena_depth_v1.png) | 1 |
| EchoGallery | [echo_gallery_depth_v1.png](echo_gallery_depth_v1.png) | 22 |
| TideWell | [tide_well_depth_v1.png](tide_well_depth_v1.png) | 32 |
| EchoNest | [echo_nest_depth_v1.png](echo_nest_depth_v1.png) | 22 |
| CrystalCauseway | [crystal_causeway_depth_v1.png](crystal_causeway_depth_v1.png) | 22 |
| UndertowVault | [undertow_vault_depth_v1.png](undertow_vault_depth_v1.png) | 22 |
| ResonanceSanctum | [resonance_sanctum_depth_v1.png](resonance_sanctum_depth_v1.png) | 1 |
| EchoDepths | [echo_depths_depth_v1.png](echo_depths_depth_v1.png) | 24 |
| BrokenCauseway | [ash_causeway_depth_v1.png](ash_causeway_depth_v1.png) | 14 |
| EmberBarracks | [ember_barracks_depth_v1.png](ember_barracks_depth_v1.png) | 14 |
| SlagReservoir | [slag_reservoir_depth_v1.png](slag_reservoir_depth_v1.png) | 14 |
| AshChapel | [ash_chapel_depth_v1.png](ash_chapel_depth_v1.png) | 14 |
| AshArena | [ash_coliseum_depth_v1.png](ash_coliseum_depth_v1.png) | 1 |
| CastellanThrone | [castellan_throne_depth_v1.png](castellan_throne_depth_v1.png) | 1 |
| AshEmberspine | [emberspine_depth_v1.png](emberspine_depth_v1.png) | 24 |
| StarfallCitadel | [citadel_sky_depth_v1.png](citadel_sky_depth_v1.png) | 1 |
| TrainingPassageDecor | [training_aqueduct_depth_v1.png](training_aqueduct_depth_v1.png) | 1 |
| EchoHavenOutskirts | [echo_road_depth_v1.png](echo_road_depth_v1.png) | 12 |
| CinderHearthOutskirts | [ash_road_depth_v1.png](ash_road_depth_v1.png) | 14 |

## Integration and limits

- Two camera-relative depth speeds, horizontal and vertical; updates at up to
  20 Hz and skip hidden rooms. No per-frame image generation or loading.
- One shared shader material per profile. Art is clipped to existing background
  silhouettes; Ash galleries use the same silhouette function as the old fill.
- No changed collision, door, arrival, actor or quest positions. Named leaf-only
  prototype decorations are hidden in some mine routes and two Ash arenas so
  they no longer obscure the paintings. Arena torches and glow stay visible.
- Original PNGs remain full resolution; the import cap is not a mobile
  performance certification. Textures currently load with world art; on-demand
  texture streaming remains separate from existing actor activation.
- The background rollout is complete for these outstanding locations.
  Foreground walls/floors, many mob/boss sprites, some town houses and props
  still have prototype shapes. This is NOT a claim that all visual art is final.
  Timed traversal balancing and phone profiling are still needed.
- Some generated pictures include distant architectural ledges and tiny fish
  silhouettes. These are decorative pixels, not routes, exits or active fauna.

## Verification

16/16 unique targeted smoke tests passed; the whole 180-test suite was not run.
The new test checks all 24 images, 342 masks, texture/mipmap limits, shared UVs,
original physics/transforms/silhouettes, scoped decoration retirement,
parallax direction/depth, hidden-room sleep and idempotent construction.
The two Ash combat regressions and new art test were rerun after retirement
of the arena's old flat decorations.

48 full-world GPU captures (close/wide for each profile) were generated using
the project's D3D12 Forward Mobile renderer and visually reviewed as eight
contact sheets. Also individually reviewed the arena corrections and upper
city. Captures are in ../characters/preview_remaining_<key>_close.png and
_wide.png. Contact sheets 0–3 are close and 4–7 wide, in table order, six per
sheet (left-to-right, then next row).

Initial OpenGL captures had driver initialization warnings and are superseded
by the accepted D3D12 captures. Final GPU log .tmp-remaining-preview-final.log
contains only the known Windows certificate-store error, no script/shader
compilation failures. Final editor import .tmp-remaining-final-import.log has
the same certificate warning and sandbox-denied editor-settings writes.
This is not a full hands-on playthrough or a claim that the historical editor
crash is fixed. Detailed results: ../../tests/LATEST_SMOKE_RESULTS.md.

## Provenance and exact prompts

Source directory:
C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9

Every file below was copied unchanged into art/visual_slice. Full prompts
follow verbatim. All were new generations with no reference images.

### shaft_cutting

Source: exec-b619265b-790b-4f88-b867-7c25669d460c.png

Output: art/visual_slice/shaft_cutting_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Dry underground excavation: steep natural slate strata, distant wooden shoring frames, hanging rope hoists and small dull mineral seams. Petrol blue, deep teal, weathered umber. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### shaft_hollow

Source: exec-8f7f75b6-7c39-4049-866b-f994d2322111.png

Output: art/visual_slice/shaft_hollow_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Quiet cavern hollow with pale hanging roots and scattered tiny wisp-like mineral lights far in the mist, scalloped stone alcoves and weathered abandoned niches. Deep blue-green, faint cool turquoise. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### drowned_crossing

Source: exec-1eb7df4f-4a3a-416f-bb52-1e2b21470a17.png

Output: art/visual_slice/drowned_crossing_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Drowned mine crossing: distant broken stone arches reflected in a still subterranean pool, half-submerged iron drainage grates and layered misty rock. Dark cyan, cold slate. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### flooded_gallery

Source: exec-e3c7e803-bac5-4ba0-b1e3-900748badeb8.png

Output: art/visual_slice/flooded_gallery_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Flooded gallery with rows of eroded narrow stone columns descending into deep water, dangling calcified cables, distant falls and sediment bands. Muted petrol blue and green-grey. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### warden_approach

Source: exec-4c296781-5894-49b0-921a-68aca378cdf7.png

Output: art/visual_slice/warden_approach_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Ancient submerged warden fortifications: massive blind stone buttresses, chains and weathered carved shields embedded in damp cavern walls. Dark blue slate and desaturated bronze. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### warden_arena

Source: exec-8d6b6d85-86d4-4fee-a3d2-c6486eeac031.png

Output: art/visual_slice/warden_arena_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Deep abyssal guardian chamber: monumental semicircular stone vault ribs, immense sealed ancient reliefs and dark water haze, no throne. Subdued midnight teal and steel blue. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### echo_gallery

Source: exec-1d310f9a-28a3-42f8-9b41-26f277b41f47.png

Output: art/visual_slice/echo_gallery_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Natural whispering grotto: layered curved mineral ribs resembling a sound chamber, tiny crystals along shallow ripples in stone, delicate mist. Dusky indigo and restrained turquoise. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### tide_well

Source: exec-57e547df-94dd-40f4-afb8-ad0502671aa3.png

Output: art/visual_slice/tide_well_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Vast tidal cave well: eroded vertical limestone, suspended wet roots, distant narrow streams cascading into shadow, deep cool water below. Midnight blue and desaturated sea green. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### echo_nest

Source: exec-4d669421-bf91-41fc-afe9-99f12daf1e1a.png

Output: art/visual_slice/echo_nest_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Ancient underground creature nursery: empty pearlescent shell husks and delicate silken veils fixed into rounded cavern pockets, no creatures or body parts. Dusky plum, blue-green and muted pearl. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### crystal_causeway

Source: exec-feb905ac-1362-4385-84ea-9aa79687974d.png

Output: art/visual_slice/crystal_causeway_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Fractured crystalline chasm: widely separated distant quartz masses, weathered mineral bridge remnants and fog obscuring the abyss. Charcoal violet, cool dusty cyan, no bright neon. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### undertow_vault

Source: exec-14c9c132-3cc8-4bb0-a5cb-d6d84a381afe.png

Output: art/visual_slice/undertow_vault_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Submerged forgotten vault: partly buried stone coffers, blind geometric recesses, water-carved stair ruins in the distant wall and suspended sediment haze. Midnight indigo and green-grey. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### resonance_sanctum

Source: exec-caa5da78-3892-42dc-a373-49e2cd941adb.png

Output: art/visual_slice/resonance_sanctum_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Solemn resonant guardian sanctuary: curved natural crystal columns framing a deep hollow, ancient rounded mineral reliefs and faint concentric mineral seams. Deep violet and dusty silver-blue. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### echo_depths

Source: exec-9596da7f-02a7-4636-8171-61747a97b9db.png

Output: art/visual_slice/echo_depths_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Remote cavern expedition: vast layered limestone shelves and branching dry river channels cut into distant mineral walls, little clusters of soft blue crystals and mist. Blue-black, dark turquoise, not a mine. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### ash_causeway

Source: exec-9ad2ec9d-068b-4deb-a0ab-aa980cb4cfff.png

Output: art/visual_slice/ash_causeway_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Ash-covered broken fortress causeway: distant jagged basalt escarpments, collapsed battlement fragments and ruined arched supports in smoky dusk. Dark wine-brown, dull copper and ash grey. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### ember_barracks

Source: exec-f622632a-aed9-4dcf-b4f3-9f5af5878392.png

Output: art/visual_slice/ember_barracks_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Abandoned fortress barracks interior: soot-dark brick vaults, recessed empty weapon racks, folded faded banners and distant narrow watch windows, no figures. Charcoal burgundy and muted copper. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### slag_reservoir

Source: exec-19108269-9b94-4db2-9571-fe0ad4b2625c.png

Output: art/visual_slice/slag_reservoir_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Ancient slag reservoir: vast soot-dark retaining walls and blackened channels, suspended iron sluices and dull cooled slag deposits, deep rust haze, no bright lava. Dark umber and muted orange-brown. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### ash_chapel

Source: exec-8a0ebecb-1ef9-4239-8f69-92b8b507b6b1.png

Output: art/visual_slice/ash_chapel_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Ruined cinder chapel: layered soot-stained gothic arches, cracked empty niches, extinguished hanging censers and faint warm light in distant dusty glass. Deep aubergine, ash grey, restrained amber. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### ash_coliseum

Source: exec-e1af0c79-0a2f-4ac2-9a4e-8f39f21c03f3.png

Output: art/visual_slice/ash_coliseum_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Deserted underground martial coliseum: distant tiered stone spectator galleries, blind arched openings, weathered hanging red cloth and dense ash haze, no audience. Charcoal red-brown and muted gold. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### castellan_throne

Source: exec-0f32f66e-12ae-46e8-a43f-f31de4e70d5c.png

Output: art/visual_slice/castellan_throne_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Ancient castellan audience chamber: enormous blackened brick vaults, heavy worn copper reliefs, distant tall narrow recessed windows and faded red drapery, no throne or characters. Burgundy black, muted copper. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### emberspine

Source: exec-6a66418b-26fc-4f11-b38a-a063edc9194f.png

Output: art/visual_slice/emberspine_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Volcanic cooling spine: deep irregular basalt chambers, old kiln vents, distant winding coolant pipes, hardened lava ribs and faint copper steam haze. Dark charcoal, muted rust and burgundy. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### citadel_sky

Source: exec-e1d7d0db-8224-4eea-a374-338475b2b823.png

Output: art/visual_slice/citadel_sky_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Peaceful fantasy city skyline at blue twilight: many distant slate rooftops, elegant thin bell towers, an observatory dome, tiny warm windows, airy layered cloud bands and faint stars. Slate blue and dusty violet with subtle amber; wide city panorama with ample upper sky. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### training_aqueduct

Source: exec-0ad785d6-324b-47f1-811d-c2a15745a1f1.png

Output: art/visual_slice/training_aqueduct_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Forgotten quiet aqueduct in a deep cavern: worn blue-grey stone arches and moss along distant water channels, soft shafts of cool diffuse light and serene haze. Desaturated turquoise and slate. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### echo_road

Source: exec-d1942a8f-9705-413a-aee3-b531bb91e56d.png

Output: art/visual_slice/echo_road_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Outer road below a hidden cave village: distant tiny warm windows high in the rock, moss-covered natural arches, hanging roots and shallow cave pools in shadow. Deep teal with restrained warm gold. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```

### ash_road

Source: exec-b344e99e-2704-47da-9054-acaa08bd8c9b.png

Output: art/visual_slice/ash_road_depth_v1.png

```text
Use case: stylized-concept. Asset type: opaque landscape 1536x1024 painted background for a strictly 2D side-scrolling dark fantasy game. Hand-painted broad shapes with subtle texture, layered atmospheric depth and low contrast so enemies remain readable. Subject: Road outside a sheltered forge village: distant low warm windows and chimney silhouettes behind crumbling basalt defensive walls, soft ash haze and dark weathered hills. Muted umber, dusty burgundy and gentle amber. Entire composition is distant non-playable scenery; no foreground floor, walkable platforms, apparent exit doors, characters, creatures, text, UI, logo, watermark, giant focal object or heavy vignette. No 3D render or photorealism. Even detail across the image, soft subdued illumination, no bright central spotlight.
```
