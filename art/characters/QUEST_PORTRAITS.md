# Eldric and Lyra quest portraits — 2026-09-26

## Delivered

Two new opaque dialogue portraits generated with the built-in imagegen tool,
one call per character. No CLI/API fallback or local pixel editing was used.
They extend the existing Neris/Orin painterly portrait package.

- `art/characters/eldric_portrait_v1.png` is assigned to Game.tscn/Caretaker.
- `art/characters/lyra_portrait_v1.png` is assigned to LyraSurveyor.tscn.

FriendlyNPC now exposes an optional portrait texture, like the other NPC
scripts. Assignments are explicit in scenes, not based on guesses about
names/groups. Both images use the existing 96px dialogue inset and a 256px
Godot import limit. The unmodified 1254px source PNGs remain in the project.
No earlier asset was overwritten; the original generated files remain intact.

The images appear during quest offers, progress reports, reward hand-ins and
completed dialogue. NPC world bodies, movement, collision shapes, quests,
rewards and save data were not changed. This does not resolve the separate
transparent walking-sprite artwork blocker.

## Validation

The dedicated test checks all 14 authored dialogue states (10 Eldric and
4 Lyra) at 960x540, 1280x720 and 1920x1080, image identity and import size,
portrait/text/button separation, fallback for speakers without artwork,
player pause/resume and close cleanup. It also drives the connected quest
button and normal quest APIs for acceptance, progression, rewards and
duplicate survey reward rejection. These checks are not combat playthroughs.

Two staged D3D12 captures at 960x540 were inspected:

- [Eldric's trial offer](preview_eldric_quest.png)
- [Lyra's survey reward](preview_lyra_quest.png)

Reproduce with tests/preview_quest_portraits.gd and a writable local
--log-file. Preview/tests use isolated temporary saves. Existing overlapping
NPCs/nameplates and prototype world bodies remain visible in the background;
this is portrait acceptance, not final town-layout/art acceptance.

Targeted results are recorded in tests/LATEST_SMOKE_RESULTS.md. No physical
mobile-device testing, new mobile controls or full-suite result is claimed.

## Provenance

Built-in outputs under:
`C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/`

- Eldric: `exec-314f4749-ac5c-4bf2-ad03-48e282293b94.png`
  SHA256: `E10BF69EDFD444E0D1BA47778930EB277F7A103504CFA33C792E83CD396C68F1`
- Lyra: `exec-5f375ec0-f764-49f5-a608-f8e96db0b12f.png`
  SHA256: `966C065F36E020F44565691D4E481D9DA955EBEAC5C123A910B7B5AD47B22F5B`

## Exact prompts

### eldric

Use case: stylized-concept. Asset type: square opaque NPC dialogue portrait for an original hand-painted 2D dark-fantasy exploration game. Style: clean ink-edged painterly illustration, broad readable shapes, subtly textured worn cloth, expressive illustrated features rather than photorealism, not 3D. Head-and-shoulders gentle three-quarter view looking toward viewer, entire head within canvas with breathing room above hair, shoulders cropped along lower edge. Readable at a small 96-pixel inset. Opaque midnight-teal painted vignette background with restrained lighting, low detail. One character only, no text, borders, watermark, checkerboard, UI mockup, sprite sheet or extra figures. Subject: Eldric, an elderly human caretaker and mentor of travelers. Kind but watchful lined face, warm medium-light skin, short silver-gray hair, thick gray eyebrows and a neatly trimmed silver beard. Weathered moss-green wool mantle over a dark teal robe, small plain antique-brass clasp at collar, practical and humble rather than royal. Gentle warm lantern lighting on his face, cool soft rim light, a barely visible distant stone arch blurred into the background. Calm welcoming expression with a little determination. No weapons, crown, wizard hat or ornate jewelry.

### lyra

Use case: stylized-concept. Asset type: square opaque NPC dialogue portrait for an original hand-painted 2D dark-fantasy exploration game. Style: clean ink-edged painterly illustration, broad readable shapes, subtly textured worn cloth, expressive illustrated features rather than photorealism, not 3D. Head-and-shoulders gentle three-quarter view looking toward viewer, entire head within canvas with breathing room above hair, shoulders cropped along lower edge. Readable at a small 96-pixel inset. Opaque midnight-teal painted vignette background with restrained lighting, low detail. One character only, no text, borders, watermark, checkerboard, UI mockup, sprite sheet or extra figures. Subject: Lyra, an adult human woman who surveys the crystal caverns and maps forgotten passages. Warm tan skin, focused curious hazel eyes, short dark auburn bob tucked behind one ear, distinct angular face and confident subtle smile. Worn indigo-blue surveyor cloak over simple gray clothing, pale turquoise scarf, leather map-case strap on one shoulder, a small rolled parchment edge visible near lower shoulder without hands. Cool crystal rim lighting and soft warm face lighting. A few indistinct blue crystal reflections in the background, no detailed scenery. Practical explorer, not royal. No weapons, crown, elaborate jewelry or glasses.
