"""User-approved local matte extraction/registration, not image generation.

Keep source sheets intact. The manifest names exact reviewed input files.
Requires Pillow only. Outputs are new versioned RGBA animation atlases.
"""
import argparse
import json
from collections import deque
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CELL = (512, 448)


def matte(source):
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    pixels = list(image.get_flattened_data())
    if image.getchannel("A").getextrema()[0] == 0:
        return image, "preserved source alpha"
    green = pixels[0][1] > pixels[0][0] + 80 and pixels[0][1] > pixels[0][2] + 80
    candidate = bytearray(width * height)
    for i, (r, g, b, a) in enumerate(pixels):
        candidate[i] = (g > max(r, b) + 35 and g > 100) if green else (min(r, g, b) > 155 and max(r, g, b) - min(r, g, b) < 32)
    # Exterior-connected neutral background only: do not punch out white eyes,
    # chest cores or pale fur enclosed by the dark painted character outline.
    removed = bytearray(width * height)
    queue = deque()
    for x in range(width):
        for i in (x, (height - 1) * width + x):
            if candidate[i] and not removed[i]:
                removed[i] = 1
                queue.append(i)
    for y in range(height):
        for i in (y * width, y * width + width - 1):
            if candidate[i] and not removed[i]:
                removed[i] = 1
                queue.append(i)
    while queue:
        i = queue.popleft()
        x = i % width
        for n in (i - width if i >= width else -1, i + width if i < width * (height - 1) else -1,
                  i - 1 if x else -1, i + 1 if x + 1 < width else -1):
            if n >= 0 and candidate[n] and not removed[n]:
                removed[n] = 1
                queue.append(n)
    if green:
        removed = candidate  # Also key enclosed green gaps in fists/capes.
    else:
        # Enclosed checker pockets between an arm and torso are not connected
        # to the outside. Distinguish the alternating neutral tiles from white
        # character highlights by their neutral fraction and brightness range.
        visited = bytearray(removed)
        for start in range(width * height):
            if not candidate[start] or visited[start]:
                continue
            stack, component = [start], []
            visited[start] = 1
            neutral, dark, bright = 0, 255, 0
            while stack:
                i = stack.pop()
                component.append(i)
                r, g, b, _ = pixels[i]
                neutral += int(max(r, g, b) - min(r, g, b) <= 6)
                dark, bright = min(dark, min(r, g, b)), max(bright, min(r, g, b))
                x, y = i % width, i // width
                for n in (i - width if y else -1, i + width if y + 1 < height else -1,
                          i - 1 if x else -1, i + 1 if x + 1 < width else -1):
                    if n >= 0 and candidate[n] and not visited[n]:
                        visited[n] = 1
                        stack.append(n)
            if len(component) > 10 and neutral / len(component) > 0.6 and bright >= 248 and dark <= 230:
                for i in component:
                    removed[i] = 1
    result = []
    for i, (r, g, b, a) in enumerate(pixels):
        if removed[i]:
            result.append((r, g, b, 0))
        elif green and g > max(r, b) + 10:
            # Only chroma-contaminated fringe, not the teal/white armor interior.
            result.append((r, min(g, max(r, b) + 10), b, a))
        else:
            result.append((r, g, b, a))
    image.putdata(result)
    return image, "green chroma key" if green else "exterior checker matte"


def split_components(image, columns, rows):
    """Component-based slicing preserves hands/wings over nominal grid edges."""
    width, height = image.size
    alpha = image.getchannel("A").tobytes()
    seen = bytearray(width * height)
    groups = [[] for _ in range(columns * rows)]
    for start, a in enumerate(alpha):
        if a < 32 or seen[start]:
            continue
        stack = [start]
        seen[start] = 1
        component = []
        xmin, xmax, ymin, ymax = width, 0, height, 0
        while stack:
            i = stack.pop()
            component.append(i)
            x, y = i % width, i // width
            xmin, xmax, ymin, ymax = min(xmin, x), max(xmax, x), min(ymin, y), max(ymax, y)
            for n in (i - width if y else -1, i + width if y + 1 < height else -1,
                      i - 1 if x else -1, i + 1 if x + 1 < width else -1):
                if n >= 0 and alpha[n] >= 32 and not seen[n]:
                    seen[n] = 1
                    stack.append(n)
        if len(component) < 18:
            continue
        col = min(columns - 1, int((xmin + xmax) * 0.5 / (width / columns)))
        row = min(rows - 1, int((ymin + ymax) * 0.5 / (height / rows)))
        groups[row * columns + col].append((component, (xmin, ymin, xmax + 1, ymax + 1)))
    result = []
    for index, components in enumerate(groups):
        if not components or max(len(c[0]) for c in components) < 1500:
            raise ValueError(f"Missing substantial sprite in cell {index}")
        bounds = (min(c[1][0] for c in components), min(c[1][1] for c in components),
                  max(c[1][2] for c in components), max(c[1][3] for c in components))
        mask = Image.new("L", image.size)
        data = bytearray(width * height)
        for component, _ in components:
            for i in component:
                data[i] = alpha[i]
        mask.frombytes(bytes(data))
        isolated = image.copy()
        isolated.putalpha(mask)
        result.append((isolated.crop(bounds), bounds))
    return result


def register(frames, hovering=False, spectral=False):
    # One scale for the entire actor: do not stretch crouches to idle height.
    factor = 300.0 / frames[0][0].height
    cells = []
    for index, (image, bounds) in enumerate(frames):
        alpha = image.getchannel("A")
        if hovering:
            anchor = (image.width - frames[0][0].width * 0.18, image.height - frames[0][0].height * 0.22)
        elif spectral:
            head = alpha.crop((0, 0, image.width, int(image.height * 0.25)))
            points = [(i % head.width) for i, a in enumerate(head.tobytes()) if a > 100]
            anchor = (sum(points) / len(points) - 12, image.height)
        elif index >= 7:
            anchor = (image.width * 0.5, image.height)
        else:
            feet = alpha.crop((0, max(0, image.height - 18), image.width, image.height))
            points = [(i % feet.width) for i, a in enumerate(feet.tobytes()) if a > 100]
            anchor = ((min(points) + max(points)) * 0.5, image.height)
        resized = image.resize((round(image.width * factor), round(image.height * factor)), Image.Resampling.LANCZOS)
        destination = (round(256 - anchor[0] * factor), round((320 if hovering else 400) - anchor[1] * factor))
        cells.append((resized, destination, bounds))
    # Preserve every limb using uniform wider cells when necessary.
    reach = max(max(-at[0], at[0] + im.width - CELL[0], 0) for im, at, _ in cells)
    padding = max(0, reach + 12) if reach > 0 else 0
    cell_width = CELL[0] + padding * 2
    sheet = Image.new("RGBA", (cell_width * 4, CELL[1] * 3))
    metadata = []
    for i, (im, at, source_bounds) in enumerate(cells):
        x, y = at[0] + padding, at[1]
        if y < 0 or y + im.height > CELL[1]:
            raise ValueError(f"Vertical registration overflow in frame {i}")
        sheet.alpha_composite(im, (i % 4 * cell_width + x, i // 4 * CELL[1] + y))
        metadata.append({"source_bounds": source_bounds, "bounds": [x, y, im.width, im.height]})
    return sheet, {"cell": [cell_width, CELL[1]], "pivot": [256 + padding, 320 if hovering else 400], "scale_reference_height": 300, "frames": metadata}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest")
    parser.add_argument("--only")
    args = parser.parse_args()
    manifest = json.loads((ROOT / args.manifest).read_text(encoding="utf-8"))
    for actor, specification in manifest.items():
        if args.only and args.only != actor:
            continue
        frames, methods = [], []
        sheets = []
        for src in specification["sources"]:
            rgba, method = matte(ROOT / src["path"])
            sheets.append(split_components(rgba, src["columns"], src["rows"]))
            methods.append(method)
        for sheet, frame in specification["order"]:
            frames.append(sheets[sheet][frame])
        assert len(frames) == 12
        atlas, metadata = register(frames, actor == "echo_matriarch", actor == "hollow_sovereign")
        output = ROOT / f"art/characters/boss_{actor}_animation_v2.png"
        atlas.save(output)
        metadata["matte_methods"] = methods
        output.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
        # Color-background preview reveals matte halos and clipped extremities.
        preview = Image.new("RGBA", atlas.size, "#203348")
        preview.alpha_composite(atlas)
        preview.thumbnail((1400, 1050))
        preview.convert("RGB").save(ROOT / f"art/characters/drafts/review_{actor}_v2.jpg")
        print(actor, atlas.size, methods, flush=True)
    # Compile metadata into a referenced Godot script as well: exported games
    # must not depend on loose JSON files or export include-filter settings.
    compiled = {}
    for actor in manifest:
        metadata_path = ROOT / f"art/characters/boss_{actor}_animation_v2.json"
        if metadata_path.exists():
            compiled[actor] = json.loads(metadata_path.read_text(encoding="utf-8"))
    (ROOT / "BossFrameData.gd").write_text(
        "extends RefCounted\n# Generated by tests/prepare_boss_frames.py; do not hand-edit.\nconst DATA := "
        + json.dumps(compiled, indent="\t") + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
