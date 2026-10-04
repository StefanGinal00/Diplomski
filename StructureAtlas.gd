extends RefCounted
## Shared raster parts, source-space crops and uniform scale. No runtime readback.
const FACADES := preload("res://art/visual_slice/passage_facades_v1.png")
const HOISTS := preload("res://art/visual_slice/lift_mechanisms_v1.png")
const FACADE_SIZE := Vector2(2172, 724)
const HOIST_SIZE := Vector2(1254, 1254)
const FACADES_RECTS := [Rect2(12, 13, 704, 675), Rect2(738, 12, 700, 677), Rect2(1461, 13, 699, 677)]
const HOIST_RECTS := [Rect2(7, 210, 613, 278), Rect2(637, 355, 608, 139), Rect2(9, 792, 609, 307), Rect2(638, 975, 605, 154)]

static func configure(sprite: Sprite2D, sheet: Texture2D, source_size: Vector2, source_rect: Rect2, width: float) -> void:
	var ratio := sheet.get_size() / source_size
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(source_rect.position * ratio, source_rect.size * ratio)
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2.ONE * (width / atlas.region.size.x)
	sprite.set_meta("contact_row", (source_rect.size.y - 2) * ratio.y)

static func family(id: String) -> int:
	return 2 if id.begins_with("starfall_") else (1 if id.begins_with("ash_") else 0)
