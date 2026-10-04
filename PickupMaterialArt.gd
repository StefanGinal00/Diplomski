extends RefCounted
const SHEET := preload("res://art/visual_slice/pickups_hazard_atlas_v1.png")
const LOOT := preload("res://art/visual_slice/loot_tokens_atlas_v1.png")
const LOOT_CROPS := [Rect2(60, 130, 650, 510), Rect2(780, 40, 610, 620), Rect2(1510, 106, 630, 540)]
# Explicit source crops, not destructive edits of generated raster art.
const CROPS := [Rect2(95, 90, 330, 550), Rect2(555, 94, 500, 530), Rect2(1110, 110, 460, 510), Rect2(1620, 200, 535, 420)]

static func attach(parent: Node2D, kind: int, size: Vector2, at: Vector2 = Vector2.ZERO) -> Sprite2D:
	return _sprite(parent, SHEET, CROPS[kind], size, at)

static func loot(parent: Node2D, kind: int, size: Vector2) -> Sprite2D:
	return _sprite(parent, LOOT, LOOT_CROPS[kind], size)

static func item(parent: Node2D, item_id: String) -> void:
	if item_id == "healing_herb": attach(parent, 1, Vector2(18, 19))
	elif item_id.ends_with("_fragment") or item_id.ends_with("_ore"): attach(parent, 2, Vector2(17, 19))
	elif item_id.contains("sigil") or item_id.contains("crest") or item_id.contains("seal"): loot(parent, 1, Vector2(20, 20))
	else: loot(parent, 2, Vector2(18, 16))
	retire_shapes(parent)

static func retire_shapes(parent: Node2D) -> void:
	for child in parent.get_children():
		if child is Polygon2D and child.get_child_count() == 0: child.hide()

static func _sprite(parent: Node2D, sheet: Texture2D, crop: Rect2, size: Vector2, at: Vector2 = Vector2.ZERO) -> Sprite2D:
	var art := parent.get_node_or_null("PaintedPickup") as Sprite2D
	var fresh := art == null
	if fresh:
		art = Sprite2D.new()
		art.name = "PaintedPickup"
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = crop
	atlas.filter_clip = true
	art.texture = atlas
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.position = at
	art.scale = size / atlas.region.size
	if fresh: parent.add_child(art)
	return art
