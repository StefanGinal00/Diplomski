extends RefCounted
const SHEET := preload("res://art/visual_slice/cavern_dressing_atlas_v1.png")
const RECTS := [Rect2(12, 8, 564, 492), Rect2(580, 8, 586, 492), Rect2(1200, 8, 320, 492), Rect2(14, 514, 440, 446), Rect2(456, 557, 743, 457), Rect2(1200, 508, 320, 516)]
# Baked from opaque pixels (alpha >= .65, at least 3 pixels in the row).
# Texture padding is not the foot; no image readback in the running game.
const CONTACT_ROWS := [486, 485, 482, 433, 439, 501]

static func sprite(parent: Node, kind: int, named: String, at: Vector2, size: Vector2) -> Sprite2D:
	var art := Sprite2D.new()
	art.name = named
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = RECTS[kind]
	atlas.filter_clip = true
	art.texture = atlas
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.scale = size / atlas.region.size
	art.position = at
	art.set_meta("contact_row", CONTACT_ROWS[kind])
	parent.add_child(art)
	return art
