@tool
extends Node2D
## Static facing for existing walkable surfaces; collision is the source of truth.

const STAIR_RUNS := {"WestRise": 6, "ArcadeDescent": 6, "LibraryRise": 7, "LibraryDescent": 7, "WatchAscent": 6}
const UPPER_WALKS := ["GateStair", "HearthStair", "SmithyWalk", "MarketWalk", "EastStair", "ThroneStair"]
const STONE := preload("res://art/visual_slice/cinder_masonry_v1.png")
const JOINERY := preload("res://SettlementDetailAtlas.gd")
var surfaces: Array[Dictionary] = []
var retired: Array[Polygon2D] = []
var built := false


func _ready() -> void:
	# Above facade accents at the same layer, but behind actors and names (0).
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	var town := get_parent()
	town.move_child(self, town.get_child_count() - 1)
	_register(town.get_node("Floor"), "street")
	var district := town.get_node("EasternDistricts")
	for named in ["EastMarketStreet", "HearthGatePlaza"]:
		_register(district.get_node(named), "street")
	for named in ["KilnArcade", "CopperLibraryWalk", "CinderWatch"]:
		_register(district.get_node(named), "bridge")
	for prefix in STAIR_RUNS:
		for index in range(STAIR_RUNS[prefix]):
			_register(district.get_node(prefix + str(index)), "step")
	for named in UPPER_WALKS:
		_register(town.get_node("UpperVillage/" + named), "bridge" if named.ends_with("Walk") else "step")
	built = true
	queue_redraw()


func _register(body: StaticBody2D, kind: String) -> void:
	var collision := body.get_node("CollisionShape2D") as CollisionShape2D
	var shape := collision.shape as RectangleShape2D
	var top_left := to_local(collision.to_global(-shape.size * 0.5))
	var bottom_right := to_local(collision.to_global(shape.size * 0.5))
	var rect := Rect2(top_left, bottom_right - top_left)
	# Retire only the authored leaf plate. Never hide the body or its occupants.
	for child in body.get_children():
		if child is Polygon2D and child.get_child_count() == 0 and child.visible:
			child.hide()
			retired.append(child)
	surfaces.append({"body": body, "collision": collision, "rect": rect, "kind": kind})


func _draw() -> void:
	for surface in surfaces:
		var rect: Rect2 = surface.rect
		if surface.kind == "bridge":
			var timber := JOINERY.texture_for(2,1)
			var unit := timber.get_size()*(rect.size.y/timber.get_height())
			var x := rect.position.x
			while x<rect.end.x:
				var width := minf(unit.x,rect.end.x-x)
				draw_texture_rect_region(timber,Rect2(Vector2(x,rect.position.y),Vector2(width,unit.y)),Rect2(Vector2.ZERO,Vector2(width*timber.get_height()/unit.y,timber.get_height())))
				x += width
		else:
			# Texture follows the collider, with the same world texel density as
			# the surrounding masonry. No opaque debug-block overlay or neon rim.
			draw_texture_rect_region(STONE,rect,Rect2(rect.position*3,rect.size*3),Color("b6aaa2"))
