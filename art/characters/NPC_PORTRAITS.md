# First NPC portrait package — 2026-09-26

## Accepted artwork and integration

Mode: built-in imagegen skill/tool, two separate generation calls. No CLI/API
fallback, no external asset download and no local pixel editing. These are
intentionally opaque UI portraits, not transparent walking sprites.

- `art/characters/neris_portrait_v1.png`: Neris of Echo Haven, assigned explicitly
  in EchoHaven.tscn; displayed in her dialogue panel (96x96 logical pixels).
- `art/characters/orin_portrait_v1.png`: Orin, assigned in MerchantNPC.tscn;
  displayed in his shop/forge header (64x64 logical pixels).

Each source is an unmodified 1254x1254 generated PNG. The Godot import size
limit is 256 to avoid loading full-resolution art for these small insets.
Source images remain intact for future UI sizes. New filenames are versioned;
no earlier art was overwritten. Other speakers/services retain the original
no-portrait layout rather than borrowing the wrong character's face.

NPC scripts expose an optional portrait texture. The dialogue reserves a
separate image column and extra text height; the shop reserves header space.
Portraits ignore pointer input and clear on close/speaker changes. Images do
not change world sprites, routes, collisions, dialogue content, item prices,
stock, forge costs or save format.

Visual review also exposed pre-existing shop description overflow. A bounded
ScrollContainer now keeps the full description reachable without drawing over
the buy button; selecting a different item/tab resets scrolling to the top.

## Validation

10/10 targeted smoke scripts pass on final runtime code; not a full-suite run.
The new npc_portrait_smoke test covers exact identity mapping, missing-art
fallback, texture import dimensions, every Neris dialogue line, all shop item
descriptions including scrolling to their end, the discount header, forge tab,
input focus, pause/close cleanup and collision invariants at three headless
viewport sizes (960x540, 1280x720, 1920x1080). This is not physical-device testing.

D3D12 staged captures at the project's 960x540 baseline were inspected:

- [Neris dialogue](preview_neris_dialogue.png)
- [Orin shop](preview_orin_shop.png)
- [Scrolled item details](preview_orin_shop_details.png)
- [Orin forge](preview_orin_forge.png)

Reproduce with tests/preview_npc_portraits.gd and a local --log-file; it uses
an isolated temporary save. Both portraits and text/buttons are readable.
The ordinary world NPCs still have prototype vector bodies; existing crowding
and overlapping nameplates remain visible in the town background and pending.
The failed transparent walk-sheet attempt is not resolved by these portraits.

## Provenance

Generated beneath:
`C:/Users/Stefan/.codex/generated_images/01a0b098-652a-7fc3-9fac-c3b350bd7ba9/`

- Neris: `exec-7cc2897b-47ef-4c93-a845-647281a1809a.png`
  SHA256: `0C471A7982B005E1ECC85261220CB8AFFA65C38EE114A5EDC5C5E73463E4C0BB`
- Orin: `exec-ca6214bd-a389-492a-8b2f-9e69f0cf623d.png`
  SHA256: `1296D0FFBCB6E297A8EA086801F62CAE4B8D2B7D8BF62FB4376FAF5909E82DF1`

Both selected outputs were copied into the project, leaving the originals
untouched. No sprite extraction/chroma-key workaround was used.

## Exact generation prompts

### neris

Use case: stylized-concept. Asset type: square illustrated NPC dialogue portrait for an original 2D hand-painted dark-fantasy exploration game. Primary request: a single warm, observant adult woman named Neris, a peaceful crystal-cavern town resident, head and shoulders in gentle three-quarter view, looking toward the viewer. Dark brown hair swept back into a practical low braid, medium warm skin, expressive dark eyes, slate-blue everyday coat with muted turquoise scarf and small worn brass clasp. Friendly calm expression, no weapon. Style: clean ink-edged painterly 2D illustration, broad readable shapes, subtle worn cloth texture, restrained detail, not photorealistic and not 3D. Portrait should read clearly as a small 96-pixel dialogue inset. Composition: face and hair centered, all of head inside canvas, shoulders cropped along lower edge, generous space above hair. Lighting: soft cool teal rim light and warm subtle face illumination. Background: opaque deep midnight-teal softly painted vignette, faint unfocused crystal glow, very low detail. One character only. No text, labels, border, watermark, grid, checkerboard or UI mockup. This is a finished opaque square portrait, not a transparent sprite sheet.

### orin

Use case: stylized-concept. Asset type: square illustrated merchant portrait for an original 2D hand-painted dark-fantasy exploration game. Primary request: a single approachable middle-aged male traveling merchant named Orin, head and shoulders in gentle three-quarter view looking toward viewer, warm tan skin, short dark hair with a little gray at the temples, neat short beard, thoughtful welcoming expression. Wears a muted deep-violet travel cloak over an ochre tunic, simple antique brass clasp and brown leather pack strap crossing one shoulder. No weapon, no crown. Style: clean ink-edged painterly 2D illustration, broad readable shapes, subtle worn fabric, restrained detail, not photorealistic and not 3D. Portrait should read clearly as a small 96-pixel shop inset. Composition: face and hair centered, all of head inside canvas, shoulders cropped along lower edge, generous space above hair. Lighting: warm amber lantern light with subtle cool rim light. Background: opaque deep midnight-teal softly painted vignette with very faint warm glow, low detail. One character only. No text, labels, border, watermark, grid, checkerboard, extra objects or UI mockup. This is a finished opaque square portrait, not a transparent sprite sheet.
