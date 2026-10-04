extends Node2D
## Deterministic small compositions on surveyed terrain, with protected gameplay
## space. No gameplay nodes, lights, particles, collision or save-state writes.
const Piece := preload("res://AmbientSetpiece.gd")
const MAX_CLUSTERS := 14
const MAX_HANGING := 8
var props: Array[Node2D] = []
var clusters: Array[Rect2] = []
var floors: Array[Rect2] = []
var solids: Array[Rect2] = []
var protected: Array[Rect2] = []
var retired: Array[Polygon2D] = []
var retired_lines: Array[Line2D] = []
var biome := 0

static func install(room: Node2D, id: String, nodes: Array[Node]) -> Node2D:
	if room.has_node("AmbientCompositions"): return room.get_node("AmbientCompositions")
	var dressing := new()
	dressing.name = "AmbientCompositions"
	room.add_child(dressing)
	dressing._build(id, nodes)
	return dressing

func _build(id: String, nodes: Array[Node]) -> void:
	set_process(false)
	biome = 1 if id.begins_with("ash_") else (2 if id.begins_with("starfall_") else 0)
	var walls: Array[Rect2] = []
	for node in nodes:
		if not is_instance_valid(node): continue
		if node is CollisionShape2D and not node.disabled and node.shape is RectangleShape2D and is_zero_approx(node.global_rotation):
			var body := node.get_parent()
			var rect: Rect2 = node.global_transform * Rect2(-node.shape.size * 0.5, node.shape.size)
			if body is StaticBody2D and not body.is_in_group("enemy") and not body.is_in_group("breakable"):
				solids.append(rect)
				var named := String(body.name).to_lower()
				if rect.size.x >= 95 and rect.size.y <= 40 and not ("ceiling" in named or "roof" in named or "topwall" in named): floors.append(rect)
				elif rect.size.y >= 90 and rect.size.x <= 85: walls.append(rect)
			elif body is Area2D:
				var script_path: String = body.get_script().resource_path if body.get_script() != null else ""
				# Room/encounter detector volumes are not visible obstacles. Real
				# hazards retain their whole footprint, including long spike beds.
				if (rect.size.x <= 180 and rect.size.y <= 140) or "Hazard" in script_path or "Spike" in script_path:
					protected.append(rect.grow(16))
		if node is Node2D and (node.has_node("FinishedDevice") or node.is_in_group("npc") or node.is_in_group("friendly_npc")):
			protected.append(Rect2(node.global_position - Vector2(65,95), Vector2(130,125)))
		elif node is Node2D and (node.is_in_group("enemy") or node.is_in_group("breakable")):
			protected.append(Rect2(node.global_position - Vector2(30,65), Vector2(60,85)))
		_retire_inert_geometry(node)
		_finish_legacy_detail(node)
	# Give the entrance court some detail, then sample the whole route rather
	# than exhaust the budget in the first tier. Deterministic across reloads.
	var ordered: Array[Rect2] = []
	for i in mini(4, floors.size()): ordered.append(floors[i])
	for i in floors.size():
		var index := (i * 37 + int(id.hash() % maxi(1, floors.size()))) % maxi(1, floors.size())
		if not floors[index] in ordered: ordered.append(floors[index])
	# A stride may share factors with the floor count: fill any unsampled tail.
	for floor_rect in floors:
		if not floor_rect in ordered: ordered.append(floor_rect)
	for floor_rect in ordered:
		if clusters.size() >= MAX_CLUSTERS: break
		for fraction in [0.24, 0.72, 0.48]:
			if clusters.size() >= MAX_CLUSTERS: break
			var x: float = lerpf(floor_rect.position.x + 40, floor_rect.end.x - 40, fraction)
			var bounds := Rect2(Vector2(x-36, floor_rect.position.y-34), Vector2(72,34))
			if not _clear(bounds): continue
			# Do not fill adjacent jump steps with scenery; keep quiet spaces.
			var near := false
			for previous in clusters:
				if previous.get_center().distance_to(bounds.get_center()) < 185: near = true
			if near: continue
			var index := clusters.size()
			clusters.append(bounds)
			var main_kind: int = [0,2,3,0,2][(index + int(id.hash() % 5)) % 5]
			var height: float = [20,22,27][index % 3]
			height = minf(height, 40.0 * Piece.CROPS[biome][main_kind].size.y / Piece.CROPS[biome][main_kind].size.x)
			_add(main_kind, Vector2(x-12, floor_rect.position.y), height, floor_rect, "floor")
			_add(1, Vector2(x+18, floor_rect.position.y), 19 + index % 4 * 2, floor_rect, "floor")
	# Hanging props must have a real masonry/timber attachment, not empty air.
	var hang_count := 0
	for wall in walls:
		if hang_count >= MAX_HANGING: break
		var at := Vector2(wall.get_center().x, wall.position.y + minf(32, wall.size.y * 0.18))
		var kind := 4 + hang_count % 2
		var height := minf(62, wall.size.y * 0.6)
		var width: float = Piece.CROPS[biome][kind].size.x / Piece.CROPS[biome][kind].size.y * height
		var bounds := Rect2(at - Vector2(width * 0.5, 0), Vector2(width, height))
		if not _clear(bounds, wall): continue
		_add(kind, at, height, wall, "wall")
		hang_count += 1
	# Vines on undersides fill horizontal stretches between rare vertical walls.
	for floor_rect in ordered:
		if hang_count >= MAX_HANGING: break
		var at := Vector2(floor_rect.get_center().x + floor_rect.size.x * 0.17, floor_rect.end.y - 1)
		var kind := 5 if biome == 0 else 4 + hang_count % 2
		var height := 32.0 + hang_count % 3 * 6
		var width: float = Piece.CROPS[biome][kind].size.x / Piece.CROPS[biome][kind].size.y * height
		var bounds := Rect2(at - Vector2(width * 0.5, -1), Vector2(width, height))
		if not _clear(bounds, floor_rect): continue
		_add(kind, at, height, floor_rect, "underside")
		hang_count += 1

func _clear(bounds: Rect2, attachment := Rect2()) -> bool:
	for solid in solids:
		if solid != attachment and bounds.grow(-0.1).intersects(solid): return false
	for reserved in protected:
		if bounds.grow(4).intersects(reserved): return false
	for prop in props:
		if bounds.grow(4).intersects(prop.footprint): return false
	return true

func _add(kind: int, anchor: Vector2, height: float, solid: Rect2, attachment: String) -> void:
	var prop := Piece.new()
	prop.name = "Detail%02d" % props.size()
	add_child(prop)
	prop.configure(biome, kind, anchor, height, solid, attachment)
	# Validate the exact imported cutout too, not only the nominal composition.
	for terrain in solids:
		if terrain != solid and prop.footprint.grow(-0.1).intersects(terrain):
			prop.free()
			return
	for reserved in protected:
		if prop.footprint.intersects(reserved):
			prop.free()
			return
	props.append(prop)

func _retire_inert_geometry(node: Node) -> void:
	if not node is Polygon2D or node.texture != null or node.get_child_count() != 0 or node.z_index >= 0: return
	var named := String(node.name)
	if not (named.begins_with("OreVein") or named.begins_with("HollowLooseRock")): return
	var parent := node.get_parent()
	while parent != null:
		if parent is CollisionObject2D: return # Never hide a hazard/actor cue.
		parent = parent.get_parent()
	node.hide()
	retired.append(node)

func _finish_legacy_detail(node: Node) -> void:
	if not node is Line2D or node.get_script() != null or node.texture != null: return
	var named := String(node.name)
	if named == "WetEdge" and node.get_parent() is StaticBody2D:
		node.hide()
		retired_lines.append(node)
	elif node.get_parent().name == "AuthoredDescent":
		if named.begins_with("Seep"):
			# Old oversized cyan drips were part of the retired background sketch.
			node.hide()
			retired_lines.append(node)
		elif named.begins_with("ShaftCrossing") and named.ends_with("Rope"):
			node.default_color = Color("796c53")
			node.width = 0.85
			node.antialiased = true

func refresh_devices(nodes: Array[Node]) -> void:
	# A newly streamed terminal can occupy formerly free space. Suppress only
	# intersecting decorative cutouts; never move the native object or rebuild.
	var reserves: Array[Rect2] = []
	for node in nodes:
		if is_instance_valid(node) and node is Node2D and node.has_node("FinishedDevice"):
			reserves.append(Rect2(node.global_position-Vector2(65,95),Vector2(130,125)))
	for prop in props:
		var clear := true
		for reserved in reserves:
			if prop.footprint.intersects(reserved): clear = false; break
		prop.visible = clear
		if not clear: prop.rest()
