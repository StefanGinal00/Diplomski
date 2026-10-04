# Echo neutral grazer art — 2026-09-28

## Asset and generation

[echo_grazer_v1.png](echo_grazer_v1.png): original 1536 × 1024 RGBA sprite sheet,
generated with the built-in imagegen tool under the imagegen skill. No CLI/API,
Blender, background-removal scripts or other scripted pixel modifications.
The native source is retained, with mipmaps enabled. Transparent background
and gutters were inspected in source pixels and alpha-composited GPU renders.

Six 512 × 512 cells, row-major: sleeping, idle, stride A, stride B, provoked,
hit. One gentle moss-backed herbivore, clearly distinct from the armored Echo
Broodling. Source faces right and is mirrored for left. Uniform scale 0.065,
per-pose foot pivots, anchor y=9. Silhouette about 28–29 game pixels wide and
13–18 pixels high. Collision remains 22 × 18 body, 25 × 19 contact.

## Integration

EchoGrazerAppearance is a child of NeutralCreature.tscn, enabled only when the
existing exported zone_id equals echo_grotto and creature_name is Mossling or
ends with ' Grazer'. A follow-up scenery review narrowed the original biome-only
gate to prevent land-grazer art appearing on moths, bats and other species.
This includes Echo habitat grazers and the Echo Haven outskirts Mossling.
Other species and biomes retain their
original sprite; the empty Echo appearance stays hidden and unprocessed.

The original Sprite2D stays alive, hidden, as the AI's authoritative tint/hit
feedback node. Native sleep/rest/grace/hit state drives the six art poses.
Actual grounded displacement drives walking; hidden/teleported actors do not
accumulate strides. Normal biome tints are softened for texture legibility;
damage flash is preserved. Art inherits room processing and actor lifetime.

No edits to NeutralCreature.gd or Enemy.gd, no extra creatures, collisions,
drops, quest membership or save flags. The original Z / ! indicators and health
bar remain. The Echo name label moves below the health bar, clear of the low
overhead platforms seen in QA; its content remains unchanged.

## Tests and QA

6/6 unique targeted regressions PASS; evidence in tests/LATEST_SMOKE_RESULTS.md.
New test runs real sleep/wander/provocation in both directions, verifies native
warning grace, hit feedback, both stride frames, restored facing/state, blocked
and hidden/teleport handling, collision invariants, source alpha/mipmaps and
non-Echo scope. A Game fixture verifies no pre-entry fauna, room-unload/recreate
with retained damage/hostility, one appearance child and off-room processing.

Initial test-only type-inference errors were corrected. Its warning assertion
was also aligned with the native is_zero_approx end-of-grace check; gameplay
timing was not changed to satisfy the test.

Four final D3D12 captures inspected, preview exit 0:
- [Six poses, both directions](preview_echo_grazer_poses.png)
- [Tide Well sleeping grazer](preview_echo_grazer_TideWell_sleeping.png)
- [Echo Nest sleeping grazer](preview_echo_grazer_EchoNest_sleeping.png)
- [Echo Nest provoked grazer](preview_echo_grazer_EchoNest_provoked.png)

Previews use an isolated temporary save and frozen room/player processing.
The provoked view stages an existing restored hostile state. These are visual
checks, not a manual gameplay or editor-visual acceptance pass. Initial Tide
view was obscured by an existing current indicator/enemy; final view uses the
Clearwater Grove grazer without moving any authored actor. Initial name labels
intersected overhead platforms; final views show the corrected placement.

Runtime logs contain only the known root-certificate warning. Editor import
finished with exit 0; global AppData editor settings cannot be saved in the
sandbox. Project imports succeeded. Remaining geometric flora and non-Echo
neutral fauna are outside this pass.

## Exact generation prompt

Use case: stylized-concept. Asset type: production 2D game animation sprite sheet. Six poses of ONE consistent original peaceful cave moss grazer, not an enemy beetle. Exact landscape canvas 1536x1024, three equal columns and two rows of 512x512 cells. One fully visible same-sized creature per cell facing RIGHT in strict side profile. Creature: small low rounded salamander-like herbivore with four short soft padded feet, smooth pale gray-green skin, oval moss-covered back, a few tiny broad fern leaves growing close to the shoulders, blunt rounded snout, one small warm dark eye, short stubby tail. NO armor, spines, horns, claws, tusks, weapons or equipment. Gentle natural animal, not a cartoon emoji. Hand-painted matte dark fantasy 2D game art, textured moss and subtle skin folds, soft ambient light, readable silhouette at 30 game pixels wide. Row 1 left to right: sleeping curled low with eye shut and feet tucked; awake relaxed standing idle with eye open; walking stride A with near front foot forward. Row 2 left to right: walking stride B with near front foot back; startled defensive stance with head lifted and body braced; hurt flinch with head tucked and eyes squinting, no wounds or gore. Same identity, leaf arrangement, colors and scale in every cell. Center each pose at local x256, feet/bottom near local y410, generous transparent margins; no pose crosses its cell. Genuine transparent alpha around all six cutouts, not black or painted checkerboard. No cast shadow, no floor, no scene, no glow or halo, no text, no labels, no grid lines or border.
