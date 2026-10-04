extends RefCounted
const SHEET := preload("res://art/visual_slice/ledge_supports_v1.png")
const SOURCE_SIZE := Vector2(1536, 1024)
const RECTS := [Rect2(12, 166, 518, 698), Rect2(539, 163, 500, 637), Rect2(1047, 156, 479, 714)]

static func attach(parent: Node2D, style: int, width: float) -> void:
	if parent.has_node("UnderLedge"): return
	var art := Sprite2D.new()
	art.name = "UnderLedge"
	preload("res://StructureAtlas.gd").configure(art, SHEET, SOURCE_SIZE, RECTS[style], width)
	# The top of this separate corbel meets the existing platform underside.
	art.position = Vector2(0, art.texture.get_height() * art.scale.y / 2 + 5)
	art.modulate = Color("748481")
	parent.add_child(art)
