# Echo water machinery - 2026-09-28

## Assets

Two original 2D sprites generated with the built-in imagegen tool, not the
API/CLI. No Blender or 3D dependency. Accepted files saved in this project:

- [Water pump](echo_water_pump_v1.png): 1774 x 887 RGBA.
- [Pressure dial](echo_pressure_dial_v1.png): 1254 x 1254 RGBA.

Both have actual alpha, verified from source pixels and imported textures.
Full source size retained, mipmaps enabled. AtlasTexture regions isolate
the objects; no pixels were edited or backgrounds removed by scripts.

## Integration

EchoMachineryArt replaces four authored assemblies: Tide Well pump stores,
Undertow Vault maintenance pump, and Tide Well's two flow gauges. Six sprites
are shared from the two source images (four pump bases, two dial faces).
Only decorative childless leaves are retired. Existing controllers keep
their original live needle/signal nodes and clue text.

Gauge needles read the native controller state and redraw only on relevant
events when their direction changes. A checkmark distinguishes calmed state
without relying solely on color. Gauges remain feedback, not additional
switches. No collision, actor spawn, progression, save or reward changes.

Small 135-pixel pumps are grounded at existing floor anchors. The upper
gauge face has an art-only rightward offset to avoid its old stair crossing;
the site and regulator interaction positions are unchanged.

## Verification and limits

The dedicated test checks transparent/mipmapped assets, four assemblies,
static/idempotent installation, leaf-only retirement, grounded uniform
scaling, dial/platform non-intersection, independent regulator state,
unrelated-event filtering and room re-entry. Related habitat, crossing,
field-operations, sign-layout and painted-prop regressions are also recorded
in tests/LATEST_SMOKE_RESULTS.md.

Five D3D12 views were captured and reviewed: both standalone pumps, both
active gauges and lower gauge calmed. The first upper-gauge preview revealed
a platform through its face; the revised offset is covered by the test.
Old current ribbons intentionally remain because they communicate existing
hazards. Actors, other machinery, foundation silhouettes and some label
categories still need work. This is not full-map art completion, full-suite,
manual traversal or editor acceptance.

Imports succeeded; the sandbox prevented writes to global Godot editor
settings outside the project. The known certificate-store warning remains.

## Final prompts (verbatim)

### Water pump

Use case: stylized-concept. Asset type: finished transparent PNG 2D environment sprite for an original dark fantasy side-scrolling cavern game. One low horizontal antique water pump assembly, about three times as wide as tall: cast iron cylindrical pump barrel, aged brass flanges with visible bolts, short bent intake/outlet pipes, small side flywheel, two mounting feet on the same flat horizontal baseline. Muted slate teal iron, tarnished warm brass, patches of rust and mineral wear, detailed hand-painted matte 2D game illustration. Strict straight frontal side elevation, no isometric angle, no perspective floor. Entire isolated object centered, transparent 8 percent margin on all sides. Genuinely transparent alpha background including holes between pipes and wheels, NOT a painted checkerboard. No ground, no exterior shadow, no person, no scenery, no glow, no gauge face or text, no watermark. High resolution, strong readable silhouette for reduction to 110-160 game pixels wide. Not a basic geometric placeholder or glossy 3D render.

### Pressure dial

Use case: stylized-concept. Asset type: finished transparent PNG 2D game sprite component. One circular old pressure-gauge dial viewed perfectly straight-on, worn brass rim with six small screws, thin tarnished teal outer iron lip, matte dark slate dial face with a few short pale etched tick marks around its inside perimeter. The center of the dial is empty: NO needle, NO pointer, NO central spindle, NO text, NO numbers, NO colored sector. A game engine will draw the moving needle. Hand-painted richly textured 2D dark fantasy environmental art, subtle soft upper-left illumination, no bloom. Perfectly circular shape centered on a square canvas with generous transparent margins. Genuinely transparent alpha outside the outer circular bezel, no background, no checkerboard, no ground, no stand, no cable or other objects, no watermark. Entire object fully visible, high-resolution source readable at 64 game pixels wide.
