@tool
extends Node2D
## Grounded static props replace the remaining expedition triangles/mushrooms.
const SOURCES := preload("res://EchoEntryGrowthArt.gd").SOURCES
var props: Array[Dictionary] = []
var floors: Array[Rect2] = []
var retired: Array[Polygon2D] = []
var built := false
var tint := Color.WHITE

func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")

func _build() -> void:
	if built: return
	var route := get_parent()
	for body in route.get_children():
		if not body is StaticBody2D: continue
		var col := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if col != null and not col.disabled and col.shape is RectangleShape2D:
			floors.append(global_transform.affine_inverse() * col.global_transform * Rect2(-col.shape.size * 0.5, col.shape.size))
	if floors.is_empty(): return # Schematic editor view has no authoritative floors.
	built = true
	tint = Color("bda98b") if route.region == "ash" else (Color("a7a6c4") if route.region == "starfall" else Color("93aaa3"))
	for node in route.get_children():
		if not node is Polygon2D or not node.visible or node.get_child_count() > 0: continue
		var named := String(node.name)
		if not named.begins_with("Flora") and not named.begins_with("RouteCrystal"): continue
		node.hide()
		retired.append(node)
		if named.begins_with("FloraCap"): continue
		var bounds := Rect2(node.polygon[0], Vector2.ZERO)
		for point in node.polygon: bounds = bounds.expand(point)
		var kind := "mineral" if named.begins_with("RouteCrystal") else ("fern" if props.size() % 3 == 0 and route.region != "ash" else "fungus")
		var source: Rect2 = SOURCES[kind][1]
		var height := 43.0 if kind == "mineral" else (26.0 + float(props.size() % 3) * 3.0)
		var size := source.size * (height / source.size.y)
		var desired: Vector2 = node.position + Vector2(bounds.get_center().x, bounds.end.y)
		var chosen := {}
		var best := INF
		for floor_rect in floors:
			if floor_rect.size.y > 32 or floor_rect.size.x < size.x + 4 or absf(floor_rect.position.y - desired.y) > 30: continue
			for shift in [0, -20, 20, -40, 40]:
				var foot := Vector2(clampf(desired.x + shift, floor_rect.position.x + size.x * 0.5 + 2, floor_rect.end.x - size.x * 0.5 - 2), floor_rect.position.y)
				if absf(foot.x - desired.x) > 45: continue
				var rect := Rect2(foot - Vector2(size.x * 0.5, size.y), size)
				var clear := true
				for obstacle in floors:
					if rect.grow(-0.05).intersects(obstacle): clear = false
				for prop in props:
					if rect.intersects(prop.rect.grow(3)): clear = false
				var distance := foot.distance_squared_to(desired)
				if clear and distance < best:
					chosen = {"kind": kind, "rect": rect, "support": floor_rect}
					best = distance
		if not chosen.is_empty(): props.append(chosen)
	queue_redraw()

func _draw() -> void:
	# Group by shared texture to avoid alternating materials for every plant.
	for kind in SOURCES:
		for prop in props:
			if prop.kind == kind:
				draw_texture_rect_region(SOURCES[kind][0], prop.rect, SOURCES[kind][1], tint)
