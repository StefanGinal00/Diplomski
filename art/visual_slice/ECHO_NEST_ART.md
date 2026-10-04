# Echo Nest silk props — 2026-09-28

## Assets and generation

Two original 2D sprites generated using the built-in imagegen tool, following
the imagegen skill; no CLI/API, Blender or scripted pixel edits.

- [Closed cocoon](echo_closed_cocoon_v1.png): 1024 × 1536 RGBA.
- [Spent husk](echo_spent_husk_v1.png): 1774 × 887 RGBA.

Native source resolution is retained; imports use mipmaps. AtlasTexture regions
exclude empty margins and negligible stray alpha. Inspection found that the
apparent broad halo in the raw closed-cocoon preview consists of RGB values
under zero alpha, not a visible in-game glow. The final transparent render was
checked against the actual cave background. An earlier closed-cocoon generation
was not integrated; the second closed source and first spent source are used.

## Integration and scope

EchoNestArt attaches only to Echo Nest's two authored nursery sites (1 and 5).
Three closed cocoons and three spent husks per site replace 18 decorative
polygon/line leaves. There are 12 state-variant sprites, six visible at a time.
Sprites are children of existing DormantPods and SpentSilk containers, so the
habitat controller remains the sole authority for visibility, including restored
progress. No additional state signals, frame polling, spawning, collision,
interaction, save flags or rewards. Missing resources/unsafe leaves preserve
the native decoration. Repeated attachment/build calls do not duplicate art.

Closed cocoons are 34/38/36 game pixels high; empty husks are 42/45/48 pixels wide.
Uniform scale and floor-aligned atlas pivots preserve their silhouettes.
An initial 42px center cocoon intersected each nursery's low branch step;
it was reduced to 38px and explicit all-platform clearance checks now pass.

This is a nursery-prop pass, not completion of all Echo art. Nearby creature
silhouettes, purple geometric scenery and the angular silk line remain separate
follow-up work. Native gameplay labels have not been rewritten.

## Visual QA

Four D3D12 runtime captures inspected at 2× camera zoom, final preview exit 0:

- [West occupied](../characters/preview_echo_nest_west_occupied.png)
- [East occupied](../characters/preview_echo_nest_east_occupied.png)
- [West cleared](../characters/preview_echo_nest_west_cleared.png)
- [East cleared](../characters/preview_echo_nest_east_cleared.png)

Runner: tests/preview_echo_nest_art.gd; log: .tmp-echo-nest-preview.log.
Captures use an isolated temporary save and disabled player/room processing,
not a manual gameplay or editor acceptance test. The renderer reports only the
known root-certificate warning. Editor import additionally cannot save global
AppData editor settings in the sandbox; project assets import successfully.

Targeted regression evidence is recorded in tests/LATEST_SMOKE_RESULTS.md.
Existing habitat tests exercise actual nursery kills, lazy actor streaming,
independent progress, lamp save/reload and separation from the main Nest Veil.

## Exact accepted prompts

### Closed cocoon (second generation)

Use case: stylized-concept. Create a single isolated 2D hand-painted game sprite of an upright closed silk cocoon, organic plump oval with a short tapered tip and broad bottom, dusty purple-gray woven papery fibers wrapped in matte cream thread. Entire object fully visible, roughly 1.5 times as tall as wide, frontal side-view elevation for a platform game. Flat bottom baseline. Sharp cutout silhouette against genuinely TRANSPARENT ALPHA, including all surrounding space. Absolutely NO halo, NO aura, NO glow, NO fog, NO blur around the edges, NO illumination of the background, NO gradient, NO shadow outside the object, NO painted checkerboard. Only the solid fibrous cocoon and a few close surface threads, no hanging strings, no insect, no ground or other object. Matte flat ambient lighting across the object itself; detailed texture but readable small silhouette. Centered with 12 percent empty transparent margins. High-resolution 2D raster, no text or watermark.

### Spent husk (first generation)

Use case: stylized-concept. Asset type: finished transparent PNG environment sprite for an original dark fantasy 2D side-scrolling cave game. One empty, collapsed moth-silk cocoon husk, low and broad with two curled torn papery flaps opening outward and a clearly empty dark hollow between them. Frayed woven silk fibers and subtle ribbed layered bands. Muted dusty lilac, slate gray and faded cream, matte painterly texture and soft upper-left light. About twice as wide as tall. Flat bottom baseline, strict frontal side-scroller elevation, no isometric view. Entire isolated object centered with generous transparent margins, genuinely transparent alpha background and holes between loose fibers. No insect or body, no gore, no floor, no external cast shadow, no scene, no glow, no painted checkerboard, no text or watermark. High-resolution source readable reduced to 50 game pixels wide, not a basic geometric placeholder.
