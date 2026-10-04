# Illustrated story scenes - 2026-09-29

## Campaign-wide sequences

Ten sequences now cover the opening, seven principal boss/trial victories and
two main-quest milestones. Nine sequences have three images; the ending has four.
31 narrated shots use 30 unique illustrations; Eldric's original lamp is recalled
after the Sentinel. New generation prompts and filenames: `CAMPAIGN_PROMPTS.md`.
All narration remains native UI, not baked into artwork. These images describe
story meaning rather than literal map geometry or additional inventory rewards.

## Multi-shot narration update

Six additional original 1672x941 PNG illustrations generated with the built-in imagegen tool
(no CLI/API fallback). Each of the three scenes now pairs three narration pages
with three distinct images, nine illustrations total. Existing art is preserved.
Opening: broken road -> Eldric's lamp -> unknown passage.
Haven: flooded crossing -> inhabited village -> neighbors helping each other.
Memories: three symbols -> ordinary care -> carrying their answer onward.
These are illustrative story beats, not literal inventory or map screenshots.
New project paths and full prompts follow (one call per asset).

### intro_road_v1.png

Saved: `art/story/intro_road_v1.png`

Use case: illustration-story. Asset type: full-screen 16:9 narrative cutscene for a 2D dark fantasy game, high resolution. Painterly detailed illustration, midnight blue and muted teal stone, restrained warm amber light, grounded human hope amid ancient ruins. Not a screenshot, no UI, no text, no watermark, no panels, no 3D render. Wayfarer when present is an ordinary young silver-haired traveler in a slate-teal hooded cloak, brass clasp, brown gloves and boots, no crown, no royal armor. A wide establishing shot of a broken stone road deep beneath the earth. The small lone Wayfarer seen from behind stands before a collapsed bridge, dark cavern behind and a distant old arch ahead. Convey an uncertain beginning, not a victorious ending.

### intro_passage_v1.png

Saved: `art/story/intro_passage_v1.png`

Use case: illustration-story. Asset type: full-screen 16:9 narrative cutscene for a 2D dark fantasy game, high resolution. Painterly detailed illustration, midnight blue and muted teal stone, restrained warm amber light, grounded human hope amid ancient ruins. Not a screenshot, no UI, no text, no watermark, no panels, no 3D render. Wayfarer when present is an ordinary young silver-haired traveler in a slate-teal hooded cloak, brass clasp, brown gloves and boots, no crown, no royal armor. Continuation after receiving shelter from Eldric: over the shoulder of the cloaked Wayfarer looking from a modest camp lantern toward a narrow ruined stone passage disappearing into blue darkness. The camp is safe but the way ahead unknown. No boss visible, no battle, no prophecy.

### haven_crossing_v1.png

Saved: `art/story/haven_crossing_v1.png`

Use case: illustration-story. Asset type: full-screen 16:9 narrative cutscene for a 2D dark fantasy game, high resolution. Painterly detailed illustration, midnight blue and muted teal stone, restrained warm amber light, grounded human hope amid ancient ruins. Not a screenshot, no UI, no text, no watermark, no panels, no 3D render. Wayfarer when present is an ordinary young silver-haired traveler in a slate-teal hooded cloak, brass clasp, brown gloves and boots, no crown, no royal armor. An ancient flooded stone crossing newly passable, shallow still dark water around the bridge, a broken circular stone seal beside the path, tiny warm village lamps glowing far away beneath enormous blue crystals. Wayfarer viewed from behind stepping cautiously onto the crossing. A quiet arrival after the flood guardian, no monster corpse.

### haven_neighbors_v1.png

Saved: `art/story/haven_neighbors_v1.png`

Use case: illustration-story. Asset type: full-screen 16:9 narrative cutscene for a 2D dark fantasy game, high resolution. Painterly detailed illustration, midnight blue and muted teal stone, restrained warm amber light, grounded human hope amid ancient ruins. Not a screenshot, no UI, no text, no watermark, no panels, no 3D render. Wayfarer when present is an ordinary young silver-haired traveler in a slate-teal hooded cloak, brass clasp, brown gloves and boots, no crown, no royal armor. Intimate scene in a lived-in underground crystal village: ordinary residents repairing a small stone house roof and handing an amber lantern to a neighbor on a bridge. Wayfarer observing from the near side, back view. Warm windows, weathered timber, dark teal rock, community rather than royalty. This is the human meaning of reopening a road.

### memories_care_v1.png

Saved: `art/story/memories_care_v1.png`

Use case: illustration-story. Asset type: full-screen 16:9 narrative cutscene for a 2D dark fantasy game, high resolution. Painterly detailed illustration, midnight blue and muted teal stone, restrained warm amber light, grounded human hope amid ancient ruins. Not a screenshot, no UI, no text, no watermark, no panels, no 3D render. Wayfarer when present is an ordinary young silver-haired traveler in a slate-teal hooded cloak, brass clasp, brown gloves and boots, no crown, no royal armor. Close narrative painting of ordinary weathered hands in plain brown sleeves passing a small protected glowing ember in a clay cup to another pair of hands; an old bronze handbell and a tarnished hand mirror rest on worn stone nearby, subtle blurred silhouettes of travelers beyond. Memory of strangers caring for each other, grounded tenderness, anatomically plausible hands, no crown or throne.

### memories_passage_v1.png

Saved: `art/story/memories_passage_v1.png`

Use case: illustration-story. Asset type: full-screen 16:9 narrative cutscene for a 2D dark fantasy game, high resolution. Painterly detailed illustration, midnight blue and muted teal stone, restrained warm amber light, grounded human hope amid ancient ruins. Not a screenshot, no UI, no text, no watermark, no panels, no 3D render. Wayfarer when present is an ordinary young silver-haired traveler in a slate-teal hooded cloak, brass clasp, brown gloves and boots, no crown, no royal armor. The silver-haired slate-teal cloaked Wayfarer seen from behind walking from a distant inhabited lantern-lit city toward the mouth of a tall sunless stone passage. A bronze bell, small tarnished handmirror and covered amber ember vessel tied safely to travel satchel are subtle details. The three memories carried forward for people, distant small warm windows behind, blue darkness ahead. No final boss, no ending spoilers.

## Original three illustrations

Three original 1672x941 PNG illustrations generated with built-in imagegen,
copied into this workspace and consumed by `StoryScenes.gd`. No API/CLI fallback.
The originals remain in the tool's generated-images directory; the game uses
only these local project assets. No baked-in narration: all text is native UI.

- `intro_lamp_v1.png`: a stranded Wayfarer at Eldric's lamp, before any revelations.
- `haven_lamps_v1.png`: a inhabited Haven beyond the reopened flooded road.
- `three_memories_v1.png`: bell, reflected travelers and a shared ember.

Reviewed for composition, text-free art, regional palette and story consistency.
These are chapter illustrations, not exact renderings of playable map geometry.
The Wayfarer's hood is down in the distant Haven view; no gameplay outfit changed.

## Final prompts (one built-in call per asset)

### intro_lamp_v1.png

Use case: illustration-story. Asset type: painted 2D game cutscene, single wide 16:9 landscape illustration, high detail. Original melancholic dark-fantasy game The Road Remains. Scene: a broken stone travelers' road in a vast blue-grey cavern at night; a modest sheltered camp at an old arch. A young small silver-haired traveler with a weathered slate-teal hooded cloak, round brass clasp, brown gloves and boots stands beside elderly grey-bearded caretaker Eldric in worn brown and green clothes. Eldric tends a warm amber lantern, offering shelter, not handing over a royal artifact. Broken road fades into darkness behind them. Hand-painted storybook fantasy, fine textured brushwork, strong readable silhouettes; no 3D render, no photorealism. Quiet practical hope. Compose key characters and lantern centrally in upper two thirds; lower quarter dim open stone for overlaid narrative UI. No words, lettering, logo, border, watermark, crown, combat or extra panels.

### haven_lamps_v1.png

Use case: illustration-story. Asset type: painted 2D game chapter cutscene, single wide 16:9 landscape illustration, high detail. Original melancholic dark-fantasy game The Road Remains. Scene: from a reopened flooded stone crossing, a small lone silver-haired traveler in a worn slate-teal hooded cloak with a round brass clasp sees Whisperlight Haven: a modest inhabited cave village of stone and timber homes nestled beneath translucent blue crystals, many tiny warm amber windows and lamps linked by winding stairs and bridges. People are distant ordinary silhouettes tending lamps, not an army. Hand-painted storybook fantasy, fine textured brushwork, no 3D render or photorealism. Deep midnight teal and blue with warm gold accents. Sheltering, quietly hopeful, not a royal palace. Main village centered upper two thirds; bottom quarter dark water and rock suitable for narrative overlay. No text, letters, logos, watermark, panel divisions or crowns.

### three_memories_v1.png

Use case: illustration-story. Asset type: painted 2D game chapter cutscene, single wide 16:9 landscape illustration, high detail. Original melancholic dark-fantasy game The Road Remains. Poetic coherent scene of three memories rather than literal floating keys: an old bronze evacuation bell above flooded stone on the left, a weathered silver mirror reflecting several indistinct ordinary travelers at center, cupped worn gloved hands sharing one glowing ember on the right. Connect these naturally through cavern mist and reflected light with no hard panel borders. These symbolize guiding others, remembering people, sharing warmth. Hand-painted storybook fantasy, fine brushwork and material detail; midnight teal, silver-blue and restrained ember amber. No king, crown, boss, royal emblem or new prophecy. Main motifs in upper two thirds; lower quarter softly shadowed for narrative overlay. No words, runic text, logos, watermark; not photorealistic or 3D.
