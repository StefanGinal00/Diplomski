# Echo fauna batch and entry flora - 2026-09-28

## Assets and mode

Five selected native 1254 x 1254 RGBA sheets, four 627 x 627 cells each.
Generated with the built-in imagegen tool under the imagegen skill, one call
per distinct asset. No CLI/API fallback, Blender or scripted pixel edits.
The requested 1024 square became 1254 square in the outputs; native resolution
is retained and the renderer uses the actual cell size. Godot mipmaps enabled.

- [Moth](echo_fauna_moth_v1.png)
- [Bat](echo_fauna_bat_v1.png)
- [Skimmer - selected v3](echo_fauna_skimmer_v3.png)
- [Mineral crawler](echo_fauna_crawler_v1.png)
- [Newt](echo_fauna_newt_v1.png)

Actual alpha was checked in source pixels and GPU-composited previews. Initial
skimmer v1 crossed a cell boundary; an attempted spacing edit returned an opaque
checkerboard. Neither is referenced by runtime code. The unreferenced v1 source
is retained in this folder; the rejected checkerboard stays outside the project.
A fresh transparent v3 with separated legs is the accepted sprite.

## Integration

EchoFaunaAppearance selects Moth, Bat, Skimmer, Crawler and Newt name suffixes
only within the existing echo_grotto biome. This covers 49 distinct actors
observed while visiting ten Echo rooms/districts. Grazer/Mossling appearance
stays separate; other biomes and unknown species retain their existing art.

Each family has rest, motion A, motion B and startled/hit poses. The four poses
are driven by real travel and native rest/provocation/hit state. This is basic
state-driven animation, not a full flight simulation. Bats and moths retain
the existing ground-based neutral AI; no artificial flight path is introduced.
The hidden original Sprite2D still receives authoritative hit and biome tints.

Body/contact geometry, neutral behavior, wake grace, rewards and saved state
are unchanged. Inactive processing follows room population; no additional
actors are created. Textures are shared preloaded resources, not newly streamed
textures. Label layout is unchanged; some names still overlap nearby platforms
and need a broader nameplate pass.

The first QuietCaveLife actor was spawning directly behind the return portal
on all seven Echo routes. Its initial point now searches existing supported
floor segments away from direct portal/crate siblings. Native patrol limits
are initialized at that point; doors, map geometry, names and save keys are
unchanged. Tests verify portal clearance and full patrol floor support.
Previously saved actor positions remain authoritative on restore.

## Entry flora

EchoEntryGrowthArt replaces 50 childless WildGrowth triangles with ten grounded
fern/mushroom/mineral clusters across EchoGrotto, EchoGallery, PrismArchive,
EchoNest and EchoHavenOutskirts. It reuses existing generated scenery textures,
rather than introducing duplicate background paintings.

Source anchors are preserved. Only artwork shifts to a nearby real floor:
up to 60px horizontally and 32px vertically, full-width support, uniform scale
and no platform intersections. Original leaves remain hidden, not deleted.
Static draw layer, five nodes total, no per-prop nodes or frame processing.
WorldPopulation only attaches the cosmetic layer; actor spawning is unchanged.

## Validation

Ten live neutral cycles (five families x two directions) cover resting, both
motion poses, provocation grace, native hit feedback, restored state, hidden
relocation and teleport handling. Actual room unload/recreation preserves
hostility and health. Scope, alpha, gutters, mipmaps, collider and reward
invariants are checked. Entry tests cover five rooms, all ten supports,
clearance, 50 hidden leaves, idempotence and unchanged physics/shortcut state.

See [latest smoke results](../../tests/LATEST_SMOKE_RESULTS.md) for accepted
reports and the Gallery listening-pilot repair. The initial fauna test had a
test-only untyped instantiate declaration, corrected before accepted runs.

Twelve final GPU captures were reviewed with an isolated save:
two pose galleries, five live-settled/frozen fauna locations and five entry
flora views. Preview .tmp-echo-fauna-preview.log exited 0 with the known root
certificate warning. Editor imports exited 0; global AppData settings saves
were blocked by sandbox. Not a manual playthrough or editor visual acceptance.

- [Right-facing poses](preview_echo_fauna_poses_right.png)
- [Left-facing poses](preview_echo_fauna_poses_left.png)
- [Gallery bat](preview_echo_fauna_EchoGallery.png)
- [Tide skimmer](preview_echo_fauna_TideWell.png)
- [Causeway crawler](preview_echo_fauna_CrystalCauseway.png)
- [Vault newt](preview_echo_fauna_UndertowVault.png)
- [Nest moth](preview_echo_fauna_EchoNest.png)
- [Grotto entry](preview_echo_entry_growth_EchoGrotto.png)
- [Gallery entry](preview_echo_entry_growth_EchoGallery.png)
- [Archive entry](preview_echo_entry_growth_PrismArchive.png)
- [Nest entry](preview_echo_entry_growth_EchoNest.png)
- [Haven outskirts entry](preview_echo_entry_growth_EchoHavenOutskirts.png)

Remaining visual work includes field NPC bodies, some geometric devices and
root-room scenery (e.g. Nest glow and outskirts pillar), tiny platform grass,
and contextual label readability. This batch does not complete all map art.

## Exact accepted generation prompts

### moth

Use case: stylized-concept. Asset type: production 2D neutral fauna sprite sheet on genuinely transparent alpha for a hand-painted dark fantasy cave platformer. Subject: a small cavern moth with fuzzy pearl-gray body, feathered antennae, rounded dusty lavender wings with restrained teal eyespots, delicate legs; rest wings folded roof-like; movement poses wings raised then lowered. Same individual in all four poses, facing RIGHT, strict side-scroller elevation, not isometric. Detailed matte painterly texture, clear silhouette readable at 25-32 game pixels wide, natural anatomy, not a logo, not pixel art, not glossy 3D. Layout exactly 2 columns by 2 rows on a 1024x1024 canvas, four equal 512x512 cells, no visible grid. Row-major: 1 resting compact pose; 2 movement pose A; 3 movement pose B; 4 startled defensive pose with head raised, no attack effects. Full animal centered in each cell, consistent body scale, feet baseline local y=410. Whole silhouette within x=65..447 and y=85..420 including wings and tail, ample transparent gutters. No floor, external shadow, fog, glow cloud, scenery, text, numbers, borders, painted checkerboard or extra objects. Only the four isolated animal poses should be visible.

### bat

Use case: stylized-concept. Asset type: production 2D neutral fauna sprite sheet on genuinely transparent alpha for a hand-painted dark fantasy cave platformer. Subject: a small cave bat with soft slate-gray fur, large pointed ears, warm tiny eyes, dusty mauve leathery wing membranes and small clawed feet; rest crouching with folded wings; movement poses one raised wingbeat then lowered wingbeat. Same individual in all four poses, facing RIGHT, strict side-scroller elevation, not isometric. Detailed matte painterly texture, clear silhouette readable at 25-32 game pixels wide, natural anatomy, not a logo, not pixel art, not glossy 3D. Layout exactly 2 columns by 2 rows on a 1024x1024 canvas, four equal 512x512 cells, no visible grid. Row-major: 1 resting compact pose; 2 movement pose A; 3 movement pose B; 4 startled defensive pose with head raised, no attack effects. Full animal centered in each cell, consistent body scale, feet baseline local y=410. Whole silhouette within x=65..447 and y=85..420 including wings and tail, ample transparent gutters. No floor, external shadow, fog, glow cloud, scenery, text, numbers, borders, painted checkerboard or extra objects. Only the four isolated animal poses should be visible.

### crawler

Use case: stylized-concept. Asset type: production 2D neutral fauna sprite sheet on genuinely transparent alpha for a hand-painted dark fantasy cave platformer. Subject: a small harmless mineral beetle with overlapping rough slate-blue shell plates, three tiny pale quartz outcrops on its back, six short jointed legs and two short feelers; rest tucked legs; movement poses alternating leg strides. Same individual in all four poses, facing RIGHT, strict side-scroller elevation, not isometric. Detailed matte painterly texture, clear silhouette readable at 25-32 game pixels wide, natural anatomy, not a logo, not pixel art, not glossy 3D. Layout exactly 2 columns by 2 rows on a 1024x1024 canvas, four equal 512x512 cells, no visible grid. Row-major: 1 resting compact pose; 2 movement pose A; 3 movement pose B; 4 startled defensive pose with head raised, no attack effects. Full animal centered in each cell, consistent body scale, feet baseline local y=410. Whole silhouette within x=65..447 and y=85..420 including wings and tail, ample transparent gutters. No floor, external shadow, fog, glow cloud, scenery, text, numbers, borders, painted checkerboard or extra objects. Only the four isolated animal poses should be visible.

### newt

Use case: stylized-concept. Asset type: production 2D neutral fauna sprite sheet on genuinely transparent alpha for a hand-painted dark fantasy cave platformer. Subject: a small cave salamander with smooth muted teal-gray skin and pale speckles, rounded gentle face, four stubby legs, long curled lavender tail and subtle ribbed dorsal fin; rest curled tail with low head; movement poses alternating leg strides. Same individual in all four poses, facing RIGHT, strict side-scroller elevation, not isometric. Detailed matte painterly texture, clear silhouette readable at 25-32 game pixels wide, natural anatomy, not a logo, not pixel art, not glossy 3D. Layout exactly 2 columns by 2 rows on a 1024x1024 canvas, four equal 512x512 cells, no visible grid. Row-major: 1 resting compact pose; 2 movement pose A; 3 movement pose B; 4 startled defensive pose with head raised, no attack effects. Full animal centered in each cell, consistent body scale, feet baseline local y=410. Whole silhouette within x=65..447 and y=85..420 including wings and tail, ample transparent gutters. No floor, external shadow, fog, glow cloud, scenery, text, numbers, borders, painted checkerboard or extra objects. Only the four isolated animal poses should be visible.

### skimmer v3

Use case: stylized-concept. Create a genuinely transparent RGBA sprite sheet with FOUR small side-view blue-green water strider insects. NO painted checkerboard. Exact 2x2 layout square canvas, equal cells. Each full insect only occupies the central 60 percent of its own cell so legs and antennae are separated by very generous TRANSPARENT gutters. Same creature in each pose, facing right. Six fine articulated legs, long oval teal wing cases with pale ivory vein markings, black eyes, short thin antennae, matte painterly 2D dark fantasy game style. Top left: compact resting pose. Top right: stride A. Bottom left: stride B. Bottom right: raised head startled pose. Whole animal fits inside each cell with at least 20 percent empty margin on every side. No floor, no shadows, no gray squares, no backdrop, no fog, no labels or numbers. This is an exported game sprite sheet; every pixel outside the four isolated insect silhouettes must have alpha zero, not a flat colored background. Preserve natural anatomy, readable at small scale.

## Rejected skimmer attempts

### Original v1

Use case: stylized-concept. Asset type: production 2D neutral fauna sprite sheet on genuinely transparent alpha for a hand-painted dark fantasy cave platformer. Subject: a small amphibious cave water-strider insect with slender blue-green segmented body, six delicate but clearly readable articulated legs, small transparent folded wing cases and ivory markings; rest crouched legs; movement poses alternating leg strides. Same individual in all four poses, facing RIGHT, strict side-scroller elevation, not isometric. Detailed matte painterly texture, clear silhouette readable at 25-32 game pixels wide, natural anatomy, not a logo, not pixel art, not glossy 3D. Layout exactly 2 columns by 2 rows on a 1024x1024 canvas, four equal 512x512 cells, no visible grid. Row-major: 1 resting compact pose; 2 movement pose A; 3 movement pose B; 4 startled defensive pose with head raised, no attack effects. Full animal centered in each cell, consistent body scale, feet baseline local y=410. Whole silhouette within x=65..447 and y=85..420 including wings and tail, ample transparent gutters. No floor, external shadow, fog, glow cloud, scenery, text, numbers, borders, painted checkerboard or extra objects. Only the four isolated animal poses should be visible.

### Spacing edit (opaque checkerboard rejected)

Edit target: echo_fauna_skimmer_v1.png.

Edit this sprite sheet only to correct sprite cell spacing. Preserve the same four water-strider insects, their design, colors, painterly texture, poses and genuine transparent alpha. Keep an exact 2 by 2 equal-cell square sprite sheet. Make each insect INCLUDING EVERY LEG AND ANTENNA 20 percent smaller inside its own cell, centered, with at least 60 transparent pixels on all four sides of each cell at 1024x1024 canvas size. No leg may cross a center grid boundary. No cropping. All four full animals must be separated. No visible grid, text, floor, background or effects. Preserve original four poses and right-facing direction.
