"""Package the six unmodified Godot review captures into an animated preview."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
frames = [Image.open(root / f'art/characters/preview_combat_flipbook_{n:02d}.png').convert('RGB') for n in range(6)]
output = root / 'art/characters/drafts/combat_flipbook_review.webp'
frames[0].save(output, save_all=True, append_images=frames[1:], duration=[180, 140, 140, 140, 140, 220], loop=0, quality=88)
print(output)
