"""Read-only registration of six isolated cutouts; never modifies source PNGs."""
import hashlib
import json
from pathlib import Path

from PIL import Image

root = Path(__file__).resolve().parents[1]
result = {}
for family in ("cave", "mine", "ash", "star"):
    for kind in ("floor", "ceiling"):
        name = f"route_{family}_{kind}_v1"
        path = root / "art" / "visual_slice" / f"{name}.png"
        if not path.exists():
            continue
        with Image.open(path) as source:
            rgba = source.convert("RGBA")
            alpha = rgba.getchannel("A")
            width, height = rgba.size
            boxes, contacts, gutters, profiles = [], [], [], []
            columns = [0, 600, 1180, width] if kind == "floor" else [0, 512, 1024, width]
            splits = []
            for column in range(3):
                if kind == "floor":
                    splits.append(round(height / 2))
                    continue
                empty = [y for y in range(300, 510) if alpha.crop((columns[column], y, columns[column + 1], y + 1)).getextrema()[1] < 12]
                if not empty:
                    raise ValueError(f"No alpha gutter between ceiling pieces: {name}:{column}")
                splits.append(empty[len(empty) // 2])
            for index in range(6):
                col, row = index % 3, index // 3
                cell = (columns[col], 0 if row == 0 else splits[col],
                        columns[col + 1], splits[col] if row == 0 else height)
                pixels = alpha.crop(cell)
                bounds = pixels.point(lambda a: 255 if a >= 12 else 0).getbbox()
                opaque = pixels.point(lambda a: 255 if a >= 166 else 0).getbbox()
                if bounds is None or opaque is None:
                    raise ValueError(f"Empty cutout {name}:{index}")
                x0, y0, x1, y1 = bounds
                boxes.append([cell[0] + x0, cell[1] + y0, x1 - x0, y1 - y0])
                contacts.append([opaque[1] - y0, opaque[3] - 1 - y0])
                gutters.append([x0, y0, pixels.width - x1, pixels.height - y1])
                if kind == "ceiling" and index < 3:
                    cutout = pixels.crop(bounds)
                    profile = []
                    for stripe in range(12):
                        left, right = round(stripe * cutout.width / 12), round((stripe + 1) * cutout.width / 12)
                        rows = [y for y in range(cutout.height) if sum(a >= 166 for a in cutout.crop((left, y, right, y + 1)).getdata()) >= (right - left) * 0.45]
                        profile.append([((left + right) / 2) / cutout.width, max(rows, default=0) / cutout.height])
                    profiles.append(profile)
            result[name] = {
                "size": [width, height], "boxes": boxes, "contacts": contacts,
                "gutters": gutters, "corner_alpha": alpha.getpixel((0, 0)),
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "profiles": profiles,
            }
print(json.dumps(result, indent=2))
