"""Register generated frames with one scale per sequence, retaining alpha.

Original images remain intact. Source cuts follow inspected row/column gutters,
not an assumed perfect generator grid. No synthetic in-between frames.
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DRAFTS = ROOT / 'art/characters/drafts'
CELL = 256
SOURCES = {
    'arcane': ([0, 190, 445, 765, 1070, 1325, 1536], [0, 285, 515, 745, 1024]),
    'spectral': ([0, 190, 445, 765, 1070, 1325, 1536], [0, 285, 520, 775, 1024]),
    'contact': ([0, 185, 425, 720, 1030, 1300, 1536], [0, 270, 505, 760, 1024]),
    'ground': ([0, 195, 455, 765, 1070, 1315, 1536], [0, 217, 488, 783, 1024]),
    'wild': ([0, 190, 460, 780, 1080, 1320, 1536], [0, 204, 485, 730, 1024]),
    'mobs': ([0, 256, 512, 768, 1024, 1330, 1536], [0, 255, 515, 780, 1024]),
}
metadata = {}
for name, (xs, ys) in SOURCES.items():
    source = Image.open(DRAFTS / f'combat_{name}_source_v2.png')
    assert source.mode == 'RGBA', f'{name}: actual alpha required'
    source = source.convert('RGBA')
    # A few generated empty pixels have alpha 1-7. Remove only invisible noise.
    source.putalpha(source.getchannel('A').point(lambda a: 0 if a < 8 else a))
    atlas = Image.new('RGBA', (6 * CELL, 4 * CELL))
    rows = []
    for row in range(4):
        frames = []
        for col in range(6):
            cut = tuple(round(v * factor) for v, factor in zip(
                (xs[col], ys[row], xs[col + 1], ys[row + 1]),
                (source.width / 1536, source.height / 1024) * 2))
            image = source.crop(cut)
            if name == 'wild' and row == 1:
                # Isolate root sprites from detached cyan flecks spilling out
                # of the preceding generated needle row; source stays intact.
                image.putdata([(r, g, b, 0 if b > r * 1.25 and g > r * 1.2 else a)
                               for r, g, b, a in image.get_flattened_data()])
            bounds = image.getchannel('A').getbbox()
            assert bounds, (name, row, col)
            frames.append(image.crop(bounds))
        factor = min(224 / max(f.width for f in frames), 224 / max(f.height for f in frames))
        # Foot anchors for bodies and common bases for ground eruptions.
        grounded = name == 'mobs' or (name == 'ground' and row in (1, 2)) or (name == 'wild' and row == 1)
        row_data = []
        for col, frame in enumerate(frames):
            frame = frame.resize((max(1, round(frame.width * factor)), max(1, round(frame.height * factor))), Image.Resampling.LANCZOS)
            x = (CELL - frame.width) // 2
            y = CELL - 16 - frame.height if grounded else (CELL - frame.height) // 2
            atlas.alpha_composite(frame, (col * CELL + x, row * CELL + y))
            row_data.append({'bounds': [x, y, frame.width, frame.height], 'pivot': [128, 240 if grounded else 128]})
        rows.append(row_data)
    path = ROOT / f'art/characters/combat_{name}_frames_v2.png'
    atlas.save(path)
    # Dark compositing review reveals alpha defects hidden by imagegen previews.
    review = Image.new('RGBA', atlas.size, '#202b36')
    review.alpha_composite(atlas)
    review.convert('RGB').save(DRAFTS / f'review_combat_{name}_v2.jpg')
    metadata[name] = rows
    print(name, source.size, '=>', atlas.size, '24 genuine frames')
(DRAFTS / 'combat_flipbook_registration_v2.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
