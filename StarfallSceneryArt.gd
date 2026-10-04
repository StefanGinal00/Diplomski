@tool
extends Node2D
## Cosmetic leaves only. Never touches route masks, task devices or actors.

const STONE := preload("res://art/visual_slice/starfall_masonry_v1.png")
const IRON := preload("res://art/visual_slice/drift_iron_v1.png")
const BOTANY := preload("res://StarfallBotany.gd")
var retired: Array[CanvasItem] = []
var surfaces: Array[Polygon2D] = []
var quiet_lines: Array[Line2D] = []
var roots: Array[PackedVector2Array] = []
var masks: Array[PackedVector2Array] = []
var quiet_strokes: Array[Dictionary] = []
var built := false
var theme := ""


func _ready() -> void:
	z_index = -4
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	var route := get_parent()
	theme = String(route.get_parent().get_parent().name)
	for plate in route.get_children():
		if plate is Polygon2D:
			var named := String(plate.name)
			if named.begins_with("ChamberShadow") or named.begins_with("ChamberShaftShadow") or (named.begins_with("Branch") and named.ends_with("_Shadow")) or (named.begins_with("Niche") and named.ends_with("_Alcove")):
				var points := PackedVector2Array()
				for point in plate.polygon:
					points.append(to_local(plate.to_global(point)))
				masks.append(points)
	for node in route.get_children():
		if node.get_child_count() != 0:
			continue
		if node is Polygon2D and String(node.name).begins_with("Identity"):
			if theme == "StarfallRootedHall":
				var rect := _bounds(node)
				var base := Vector2(rect.get_center().x, rect.end.y)
				_root(PackedVector2Array([base, base + Vector2(-12, -rect.size.y * 0.35), Vector2(rect.get_center().x + 9, rect.position.y + 15)]))
				for side in [-1, 1]:
					_root(PackedVector2Array([base - Vector2(0, rect.size.y * 0.28), base + Vector2(side * 25, -rect.size.y * 0.55), Vector2(base.x + side * rect.size.x * 0.35, rect.position.y + 34)]))
				_retire(node)
			elif theme != "StarfallOutskirts":
				_paint(node, IRON if theme == "StarfallSoulCrucible" else STONE, Color("3b4053"))
		elif node is Line2D and String(node.name).begins_with("Tendril"):
			_quiet(node, Color("526963") if theme == "StarfallRootedHall" else Color("6e607d"), 1.7)
	var identity := route.get_node("RoomIdentity")
	for node in identity.find_children("*", "CanvasItem", true, false):
		if node.get_child_count() != 0:
			continue
		var parent_name := String(node.get_parent().name)
		if node is Line2D:
			if parent_name == "AncientRootNetwork":
				var points := PackedVector2Array()
				for point in node.points:
					points.append(to_local(node.to_global(point)))
				_root(points)
				_retire(node)
			elif parent_name in ["SoulConduits", "MemoryRibbons", "WardedGateArches"]:
				_quiet(node, Color("726580"), 2.0)
		elif node is Polygon2D:
			if parent_name in ["MemoryMonoliths", "WardedGateArches"]:
				_paint(node, STONE, Color("686279"))
			elif parent_name == "SoulVats":
				if String(node.name).begins_with("Crucible"):
					_paint(node, IRON, Color("6c6179"))
				else:
					node.color = Color("755582") * Color(1, 1, 1, 0.35)
			elif parent_name == "ShadowCurtains":
				# Dark hanging drapery remains, but no longer masks the painting.
				node.color = Color(0.07, 0.07, 0.13, 0.27)
			elif parent_name == "RootHearts":
				node.color = Color(0.25, 0.45, 0.36, 0.23)
	built = true
	queue_redraw()


func _bounds(plate: Polygon2D) -> Rect2:
	var rect := Rect2(to_local(plate.to_global(plate.polygon[0])), Vector2.ZERO)
	for point in plate.polygon:
		rect = rect.expand(to_local(plate.to_global(point)))
	return rect


func _paint(plate: Polygon2D, texture: Texture2D, tint: Color) -> void:
	plate.texture = texture
	plate.color = tint
	plate.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var uv := PackedVector2Array()
	for point in plate.polygon:
		uv.append(point * 3.0)
	plate.uv = uv
	surfaces.append(plate)


func _quiet(line: Line2D, tint: Color, width: float) -> void:
	var points := PackedVector2Array()
	for index in range(line.points.size() - 1):
		var start := to_local(line.to_global(line.points[index]))
		var end := to_local(line.to_global(line.points[index + 1]))
		var steps := maxi(1, ceili(start.distance_to(end) / 9.0))
		for step in range(steps):
			points.append(start.lerp(end, step / float(steps)))
	points.append(to_local(line.to_global(line.points[-1])))
	for stroke in _clip(points):
		quiet_strokes.append({"points": stroke, "color": Color(tint, 0.28), "width": width})
	_retire(line)
	quiet_lines.append(line)


func _retire(node: CanvasItem) -> void:
	node.hide()
	retired.append(node)


func _root(points: PackedVector2Array) -> void:
	var curve := Curve2D.new()
	curve.bake_interval = 9
	for index in range(points.size()):
		var before := points[maxi(0, index - 1)]
		var after := points[mini(points.size() - 1, index + 1)]
		var tangent := (after - before) * 0.15
		curve.add_point(points[index], -tangent, tangent)
	# Long overview strokes used to read as straight beams across the room.
	# Small deterministic curvature plus rear-layer contrast keeps them roots,
	# not false walkways. Endpoints remain attached to the authored network.
	var organic := curve.get_baked_points()
	for index in range(1,organic.size()-1):
		var tangent := (organic[index+1]-organic[index-1]).normalized()
		var normal := Vector2(-tangent.y,tangent.x)
		var phase := float(index)/float(organic.size()-1)
		organic[index] += normal*sin(phase*TAU*1.5+points[0].x*.017)*sin(phase*PI)*8
	for stroke in _clip(organic):
		roots.append(stroke)
		var ribbon:=Line2D.new()
		ribbon.name="PaintedRoot%d"%roots.size()
		ribbon.points=stroke
		add_child(ribbon)
		preload("res://RootRibbonArt.gd").paint(ribbon,4,false)
		ribbon.default_color = Color(.38,.46,.4,.43)


func _inside(point: Vector2) -> bool:
	for mask in masks:
		if Geometry2D.is_point_in_polygon(point, mask):
			return true
	return false


func _clip(points: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var segment := PackedVector2Array()
	for point in points:
		if _inside(point):
			segment.append(point)
		else:
			if segment.size() > 1:
				result.append(segment)
			segment = PackedVector2Array()
	if segment.size() > 1:
		result.append(segment)
	return result


func _draw() -> void:
	for stroke in quiet_strokes:
		draw_polyline(stroke.points, stroke.color, stroke.width, true)
