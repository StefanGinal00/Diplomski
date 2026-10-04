# Settlement building materials — 2026-09-27

Six original images generated with built-in ImageGen, one call per material, no input reference images or CLI fallback. Source PNGs copied without pixel edits. The images are opaque surface materials intentionally clipped by existing Godot geometry, not transparent cutouts. 512px mipmapped imports are shared across buildings.

Scope: Echo Haven's three original houses, two UpperVillage houses and fifteen NewDistricts homes; Cinder Hearth's three original houses, two UpperVillage houses and ten EasternDistricts buildings. Static window mullions/sills and decorative gable caps complement the materials. In total 98 polygons carry materials and 59 windows have trim. Original geometry, colliders, actors, NPC route markers and functional room doors are unchanged. This does not complete world art, replace NPC/mob sprites or add building interiors. Seamless edges were requested; generated textures are not guaranteed mathematically seamless.

Validation: 10 targeted smoke tests pass; four staged 960x540 in-engine GPU views reviewed (original and expanded districts of both towns). Sources are 1254px square; Godot imports them at 512px with mipmaps. Visual QA added the previously plain UpperVillage houses to the same pass. Known sandbox certificate/editor-settings and GPU shader-cache diagnostics remain; no script errors or shader compile errors. No mobile hardware profiling claimed.

## Exact prompts and source files

### echo_masonry

- Project: `art/visual_slice/echo_masonry_v1.png`
- Original: `C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-72fb7f20-fa7a-4b4a-90f3-6260accb922b.png`

```text
Use case: stylized-concept. Asset type: opaque reusable surface texture for a hand-painted 2D side-scrolling fantasy game, NOT a complete building or scene. Square 1024x1024, orthographic straight-on flat surface filling every pixel edge to edge. Painterly brushwork with crisp readable broad forms and restrained fine grain, not photorealism, not 3D render. Even low-contrast illumination, no vignette, no dramatic shadows. No text, symbols, watermarks, frame, empty margins, ground, sky, characters or checkerboard. Weathered cool blue-gray limestone blocks of an underground refuge, irregular but orderly horizontal masonry, faint moss-green mineral seams, small stone chips. Seamless repeating edges. No windows or doors. Muted teal and slate palette matching an inhabited crystal cavern.
```

### cinder_masonry

- Project: `art/visual_slice/cinder_masonry_v1.png`
- Original: `C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-80250ad1-2e58-4bfd-9712-41d4776ba237.png`

```text
Use case: stylized-concept. Asset type: opaque reusable surface texture for a hand-painted 2D side-scrolling fantasy game, NOT a complete building or scene. Square 1024x1024, orthographic straight-on flat surface filling every pixel edge to edge. Painterly brushwork with crisp readable broad forms and restrained fine grain, not photorealism, not 3D render. Even low-contrast illumination, no vignette, no dramatic shadows. No text, symbols, watermarks, frame, empty margins, ground, sky, characters or checkerboard. Warm soot-darkened red-brown brick and volcanic stone masonry of a safe fortress town, staggered brick courses, mortar and gentle hand-painted wear, muted charcoal plum and earthy terracotta. Seamless repeating edges. No windows or doors, no fire or lava.
```

### echo_roof

- Project: `art/visual_slice/echo_roof_v1.png`
- Original: `C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-5de192c7-16a9-4814-95eb-7f63d03b985f.png`

```text
Use case: stylized-concept. Asset type: opaque reusable surface texture for a hand-painted 2D side-scrolling fantasy game, NOT a complete building or scene. Square 1024x1024, orthographic straight-on flat surface filling every pixel edge to edge. Painterly brushwork with crisp readable broad forms and restrained fine grain, not photorealism, not 3D render. Even low-contrast illumination, no vignette, no dramatic shadows. No text, symbols, watermarks, frame, empty margins, ground, sky, characters or checkerboard. Overlapping broad blue-black slate roof tiles in staggered horizontal rows, slightly scalloped edges, subtle cool teal rim wear and small lichen patches, medieval cavern-town roofing. Seamless repeating edges. Roof surface only, no building outline, no ridge perspective.
```

### cinder_roof

- Project: `art/visual_slice/cinder_roof_v1.png`
- Original: `C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-53c577e3-4ada-408c-a5a4-cbf2ba5b0ae0.png`

```text
Use case: stylized-concept. Asset type: opaque reusable surface texture for a hand-painted 2D side-scrolling fantasy game, NOT a complete building or scene. Square 1024x1024, orthographic straight-on flat surface filling every pixel edge to edge. Painterly brushwork with crisp readable broad forms and restrained fine grain, not photorealism, not 3D render. Even low-contrast illumination, no vignette, no dramatic shadows. No text, symbols, watermarks, frame, empty margins, ground, sky, characters or checkerboard. Overlapping weathered burnt-sienna clay roof tiles in staggered horizontal courses, dark plum shadow under each course, small pale ash deposits, welcoming medieval fortress roof material. Seamless repeating edges. Roof surface only, no building outline, no ridge perspective.
```

### echo_door

- Project: `art/visual_slice/echo_door_v1.png`
- Original: `C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-4c200026-488b-40ce-9c04-b9f940f0feca.png`

```text
Use case: stylized-concept. Asset type: opaque reusable surface texture for a hand-painted 2D side-scrolling fantasy game, NOT a complete building or scene. Square 1024x1024, orthographic straight-on flat surface filling every pixel edge to edge. Painterly brushwork with crisp readable broad forms and restrained fine grain, not photorealism, not 3D render. Even low-contrast illumination, no vignette, no dramatic shadows. No text, symbols, watermarks, frame, empty margins, ground, sky, characters or checkerboard. One CLOSED flat rectangular teal-stained old oak door surface filling the entire square canvas, vertical planks, two dark iron strap hinges crossing the left side, small brass circular pull at three-quarters width and middle height. Faint cool mineral weathering. No arch, no surrounding wall or door frame, no openings. Intended to fit a narrow rectangular existing game doorway.
```

### cinder_door

- Project: `art/visual_slice/cinder_door_v1.png`
- Original: `C:\Users\Stefan\.codex\generated_images\01a0b098-652a-7fc3-9fac-c3b350bd7ba9\exec-413c581b-8adc-4bc7-9872-97547dba1247.png`

```text
Use case: stylized-concept. Asset type: opaque reusable surface texture for a hand-painted 2D side-scrolling fantasy game, NOT a complete building or scene. Square 1024x1024, orthographic straight-on flat surface filling every pixel edge to edge. Painterly brushwork with crisp readable broad forms and restrained fine grain, not photorealism, not 3D render. Even low-contrast illumination, no vignette, no dramatic shadows. No text, symbols, watermarks, frame, empty margins, ground, sky, characters or checkerboard. One CLOSED flat rectangular warm chestnut oak door surface filling the entire square canvas, vertical planks, two forged charcoal iron horizontal straps with rivets, small dark round ring pull at three-quarters width and middle height. Subtle soot wear. No arch, no surrounding wall or frame, no openings. Intended to fit a narrow rectangular existing game doorway.
```
