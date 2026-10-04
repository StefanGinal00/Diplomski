@tool
extends Node2D
## Small, static supply props. Health changes explicitly request a redraw;
## cosmetic variation never consumes the crate's loot RNG.

var family := "travel"
var damage_fraction := 0.0
var timber := Color("806044")
var iron := Color("87918d")
const INK := Color("22252c")
const LAYOUT := preload("res://WorldLayout.gd")


func _ready() -> void:
	set_process(false)
	var ancestor := get_parent().get_parent()
	while ancestor != null:
		var room_id = LAYOUT.ROOM_NODES.find_key(String(ancestor.name))
		if room_id != null:
			family = "starfall" if String(room_id).begins_with("starfall_") else ("ash" if String(room_id).begins_with("ash_") else "echo")
			break
		ancestor = ancestor.get_parent()
	match family:
		"echo":
			timber = Color("42676b")
			iron = Color("97ada0")
		"ash":
			timber = Color("8a5340")
			iron = Color("c49668")
		"starfall":
			timber = Color("625a77")
			iron = Color("afa0b3")
	# Keep original leaf nodes/paths for authored scene compatibility.
	for leaf_name in ["Box", "Border", "Mark"]:
		var leaf := get_node_or_null(leaf_name) as CanvasItem
		if leaf != null:
			leaf.hide()
	queue_redraw()


func set_integrity(health: int, maximum: int) -> void:
	damage_fraction = 1.0 - clampf(float(health) / maxi(maximum, 1), 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var tint := Color("c1b5a2")
	if family == "echo": tint = Color("90b1ae")
	elif family == "ash": tint = Color("c6a087")
	elif family == "starfall": tint = Color("aba5c3")
	var atlas := preload("res://FacadePropAtlas.gd").texture_for(1, 1)
	var size := atlas.get_size() * (24.0 / atlas.get_width())
	draw_texture_rect(atlas, Rect2(Vector2(-12, 12 - size.y), size), false, tint)
	if damage_fraction > 0.0:
		var crack := PackedVector2Array([Vector2(-2, -10), Vector2(1, -5), Vector2(-2, -1), Vector2(2, 3), Vector2(0, 10)])
		draw_polyline(crack, INK, 1.4, true)
		draw_line(Vector2(-2, -1), Vector2(-6, 2), INK, 1, true)
		if damage_fraction >= 0.6:
			draw_colored_polygon(PackedVector2Array([Vector2(2, 3), Vector2(6, 1), Vector2(5, 7), Vector2(0, 9)]), INK)
