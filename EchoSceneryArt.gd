@tool
extends Node2D
## Static cosmetic replacements, clipped to authored chambers. No actors/physics.
const STONE := preload("res://art/visual_slice/echo_path_stone_v1.png")
const ORGANIC := {
	"stone": [preload("res://art/visual_slice/ambient_cave_props_v1.png"),Rect2(13,73,567,389),Vector2(1536,1024)],
	"fungus": [preload("res://art/visual_slice/echo_mushrooms_v1.png"), Rect2(258, 112, 873, 927)],
	"crystal": [preload("res://art/visual_slice/echo_mineral_cluster_v1.png"), Rect2(132, 128, 627, 1548)],
}
const PALETTES := {
	"grotto": Color("549b9d"), "gallery": Color("718faa"),
	"archive": Color("8985af"), "tide": Color("548f9a"),
	"nest": Color("9b799e"), "causeway": Color("7796af"),
	"vault": Color("618b89"), "depths": Color("617eaa"),
}
var retired: Array[CanvasItem] = []
var masks: Array[PackedVector2Array] = []
var mask_bounds: Array[Rect2] = []
var shapes: Array[Dictionary] = []
var counts := {"stone": 0, "crystal": 0, "fungus": 0, "backdrop": 0}
var theme := ""
var built := false
var raster_props: Array[Dictionary] = []
var floor_rects: Array[Rect2] = []


func _ready() -> void:
	z_index = -3
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	raster_props.clear()
	floor_rects.clear()
	var route := get_parent()
	var expedition: bool = route.get_script().resource_path == "res://ExpeditionWing.gd"
	theme = "depths" if expedition else String(route.route_id)
	if not PALETTES.has(theme):
		return
	for body in route.get_children():
		if not body is StaticBody2D:
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.disabled or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = collision.shape.size
		floor_rects.append(global_transform.affine_inverse() * collision.global_transform * Rect2(-size * 0.5, size))
	for node in route.get_children():
		if not node is Polygon2D:
			continue
		var named := String(node.name)
		if named.begins_with("ChamberPocket") or named.begins_with("RouteShaft") or (named.begins_with("Tier") and named.ends_with("BranchChamber")) or ((named.begins_with("MainChamber") or named.begins_with("BranchChamber")) and named.ends_with("Backdrop")) or named.begins_with("MainShaft") or named.begins_with("BranchPassage") or named == "OptionalLoop":
			var points := _points(node)
			masks.append(points)
			mask_bounds.append(_bounds(points))
	if masks.is_empty():
		return
	var tint: Color = PALETTES[theme]
	for node in route.get_children():
		if node.get_child_count() != 0:
			continue
		var named := String(node.name)
		if node is Polygon2D:
			var rect := _bounds(_points(node))
			if named.begins_with("Rib_") or (expedition and named.contains("Prism")):
				_rock(rect, tint)
				counts.stone += 1
			elif named.begins_with("EchoCrystal") or named.begins_with("ChoirCrystal") or named.begins_with("FaultShard") or named.begins_with("RouteCrystal"):
				_crystal(rect, tint)
				counts.crystal += 1
			elif named.begins_with("LumenGrowth") or (named.begins_with("Flora") and not named.begins_with("FloraCap")):
				_fungus(rect, tint, counts.fungus)
				counts.fungus += 1
			elif named.begins_with("Pendant_") or named.begins_with("LumenCap") or named.begins_with("FloraCap"):
				# The painting supplies ceiling detail; no floating cone tips.
				pass
			elif named.begins_with("Tier") and named.ends_with("AlcoveMouth"):
				# Neither the solid overview mouth nor its 93px diagonal jamb
				# strokes represent terrain. Native ledges remain visible/solid.
				counts.backdrop += 1
			elif named.begins_with("LocalFault") or named.begins_with("MirrorTower") or named.begins_with("SluiceGate") or named.begins_with("SluiceBrace"):
				# Overview column silhouettes are already in the room painting.
				# A translucent stretched quad is not a real wall or machine.
				counts.backdrop += 1
			elif named.begins_with("ChoirHalo") or named.begins_with("Reservoir") or named.begins_with("BroodChamber") or named.begins_with("SoundBell"):
				# Retire blueprint circles, not paint their outlines over scenery.
				counts.backdrop += 1
			else:
				continue
		elif node is Line2D and named.begins_with("ResonanceRibbon"):
			# Overview route guides are not attacks or scenery. Retire the source
			# AND its replacement, rather than repainting the same angular ribbon.
			pass
		elif node is Line2D and (named.begins_with("WhisperArch") or named.begins_with("MirrorSeam") or named.begins_with("Overflow") or named.begins_with("Silk")):
			# Decorative, route-owned overview lines only; real currents and
			# enemy telegraphs are different nodes/controllers and remain live.
			counts.backdrop += 1
		else:
			continue
		node.hide()
		retired.append(node)
	built = true
	queue_redraw()


func _points(plate: Polygon2D) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in plate.polygon:
		result.append(to_local(plate.to_global(point)))
	return result


func _bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect


func _fill(points: PackedVector2Array, tint: Color, textured := false) -> void:
	var rect := _bounds(points)
	for index in range(masks.size()):
		if not rect.intersects(mask_bounds[index]):
			continue
		for clipped in Geometry2D.intersect_polygons(points, masks[index]):
			if clipped.size() < 3 or Geometry2D.triangulate_polygon(clipped).is_empty():
				continue
			var uv := PackedVector2Array()
			for point in clipped:
				uv.append(point * 2.0 / STONE.get_size())
			shapes.append({"points": clipped, "tint": tint, "textured": textured, "uv": uv, "mask": index})


func _stroke(a: Vector2, b: Vector2, tint: Color, width: float) -> void:
	if a.is_equal_approx(b):
		return
	var normal := (b - a).normalized().orthogonal() * width * 0.5
	_fill(PackedVector2Array([a + normal, b + normal, b - normal, a - normal]), tint)


func _rock(rect: Rect2, tint: Color) -> void:
	# A short planted rubble/fern silhouette, not a tall triangle textured to
	# disguise the old primitive. Unsupported rear anchors are simply retired.
	_raster("stone",rect,tint,minf(rect.size.y*0.3,32),counts.stone%2==1,minf(72,rect.size.x))


func _crystal(rect: Rect2, tint: Color) -> void:
	_raster("crystal", rect, tint, minf(rect.size.y * 0.8, 100), counts.crystal % 2 == 1, maxf(20, rect.size.x))


func _fungus(rect: Rect2, tint: Color, index: int) -> void:
	_raster("fungus", rect, tint, minf(rect.size.y * 0.65, 29), index % 2 == 1, 32)


func _raster(kind: String, original: Rect2, tint: Color, height: float, flip: bool, max_width: float) -> void:
	var texture: Texture2D = ORGANIC[kind][0]
	var source: Rect2 = ORGANIC[kind][1]
	if ORGANIC[kind].size() > 2:
		# Alpha crops are recorded on the unchanged original. Imported atlas
		# resolution can be smaller without sampling a neighbouring cell.
		var registration: Vector2 = texture.get_size() / ORGANIC[kind][2]
		source = Rect2(source.position * registration, source.size * registration)
	var ratio := minf(height / source.size.y, max_width / source.size.x)
	var dimensions := source.size * ratio
	var foot := Vector2(original.get_center().x, original.end.y)
	var original_foot := foot
	var support := _support(foot, dimensions)
	if not support.is_empty():
		foot = support.foot
	var rect := Rect2(foot - Vector2(dimensions.x * 0.5, dimensions.y), dimensions)
	var quad := PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])
	var prop := {"kind": kind, "rect": rect, "source": source, "foot": foot, "original_foot": original_foot, "support": support, "flip": flip, "pieces": 0}
	if support.is_empty():
		raster_props.append(prop)
		return # Retired decorative anchors can lie over shafts or outside the route.
	for index in range(masks.size()):
		if not rect.intersects(mask_bounds[index]):
			continue
		for clipped in Geometry2D.intersect_polygons(quad, masks[index]):
			if clipped.size() < 3 or Geometry2D.triangulate_polygon(clipped).is_empty():
				continue
			var uv := PackedVector2Array()
			for point in clipped:
				var fraction := (point - rect.position) / rect.size
				if flip:
					fraction.x = 1.0 - fraction.x
				uv.append((source.position + fraction * source.size) / texture.get_size())
			shapes.append({"points": clipped, "uv": uv, "mask": index, "raster": kind, "prop": prop, "tint": Color.WHITE.lerp(tint, 0.22)})
			prop.pieces += 1
	raster_props.append(prop)


func _support(desired: Vector2, dimensions: Vector2) -> Dictionary:
	var best := {}
	var best_distance := INF
	for floor_rect in floor_rects:
		if floor_rect.size.x < dimensions.x + 4 or floor_rect.size.y > 40 or absf(floor_rect.position.y - desired.y) > 12:
			continue
		var x := clampf(desired.x, floor_rect.position.x + dimensions.x * 0.5 + 2, floor_rect.end.x - dimensions.x * 0.5 - 2)
		var distance := absf(x - desired.x)
		if distance > 140 or distance >= best_distance:
			continue
		var foot := Vector2(x, floor_rect.position.y)
		var area := Rect2(foot - Vector2(dimensions.x * 0.5, dimensions.y), dimensions)
		var obstructed := false
		for obstacle in floor_rects:
			if area.grow(-0.05).intersects(obstacle):
				obstructed = true
				break
		for prior in raster_props:
			if prior.pieces > 0 and area.intersects(prior.rect.grow(2)):
				obstructed = true
				break
		if not obstructed:
			best = {"foot": foot, "floor": floor_rect}
			best_distance = distance
	return best


func _draw() -> void:
	for shape in shapes:
		if shape.has("raster"):
			draw_polygon(shape.points, PackedColorArray([shape.tint]), shape.uv, ORGANIC[shape.raster][0])
		elif shape.textured:
			draw_polygon(shape.points, PackedColorArray([shape.tint]), shape.uv, STONE)
		else:
			draw_colored_polygon(shape.points, shape.tint)
