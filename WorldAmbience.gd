extends Node
## Room-scoped budget. Decoration never changes physics or hazard telegraphs.
const VINES := preload("res://art/visual_slice/regional_hanging_vines_v1.png")
const Machinery = preload("res://FieldMachineryArt.gd")
const LampFlame := preload("res://CheckpointLampArt.gd")
const IndustrialMachine := preload("res://IndustrialLandmarkArt.gd")
const Response := preload("res://FoliageResponse.gd")
const BRUSH_CELL := 96.0
var rooms := {}
var candidates: Array[Node2D] = []
var active: Array[Node2D] = []
var room_id := ""
var family := "cave"
var age := 0.0
var tick := 0.0
var selection_clock := 0.0
var low_quality := false
var updates := 0
var background: TextureRect
var air: Node2D
var parallax_architecture: Node2D
var brush_bins := {}
var brushing: Array[Node2D] = []
var brush_motes: Node2D
var player: Node2D
var player_previous := Vector2.ZERO
var player_sample_valid := false
var brush_queries := 0
var brush_contacts := 0
var brush_palette := "cave"
var ground_contacts: Node2D

func _ready() -> void:
	low_quality = OS.has_feature("mobile") or bool(ProjectSettings.get_setting("world/ambient/low_cost", false))
	var layer := CanvasLayer.new()
	layer.layer = -9
	add_child(layer)
	air = preload("res://WorldAmbientAir.gd").new()
	layer.add_child(air)
	brush_motes = preload("res://AmbientBrushMotes.gd").new()
	brush_motes.name = "ContactLeaves"
	add_child(brush_motes)
	brush_motes.top_level = true
	ground_contacts = preload("res://GroundContactFx.gd").new()
	ground_contacts.name = "GroundContacts"; add_child(ground_contacts)
	ground_contacts.set_low_quality(low_quality)
	player = get_tree().get_first_node_in_group("player") as Node2D

func register_room(id: String, nodes: Array[Node]) -> void:
	clear_brushing()
	brush_bins.clear()
	for node in active:
		if is_instance_valid(node) and node.has_meta("wind_vine"): node.rotation = 0
		elif is_instance_valid(node) and node.has_meta("ambient_motion"): node.rest()
	active.clear()
	room_id = id
	brush_palette = preload("res://RouteDressingPlacement.gd").family(id)
	family = "ash" if id.begins_with("ash_") else ("star" if id.begins_with("starfall_") else "cave")
	var found: Array[Node2D] = []
	parallax_architecture = null
	for node in nodes:
		if node is Node2D and node.name=="ParallaxArchitecture" and node.has_method("set_low_quality"):
			parallax_architecture = node
			parallax_architecture.set_low_quality(low_quality)
		if node is Sprite2D and node.name == "WallIvy":
			_prepare_vine(node)
			found.append(node)
		elif node is Machinery:
			found.append(node)
		elif node is Node2D and node.has_meta("ambient_motion"):
			found.append(node)
		if node is Node2D and node.has_meta("player_reactive") and node.has_method("reaction_bounds"):
			var bounds: Rect2 = node.reaction_bounds()
			for x in range(floori(bounds.position.x/BRUSH_CELL),floori(bounds.end.x/BRUSH_CELL)+1):
				for y in range(floori(bounds.position.y/BRUSH_CELL),floori(bounds.end.y/BRUSH_CELL)+1):
					var key := Vector2i(x,y)
					if not brush_bins.has(key): brush_bins[key] = []
					brush_bins[key].append(node)
	rooms[id] = found
	candidates.assign(rooms[id])
	selection_clock = 1.0
	_process(0)

func _prepare_vine(vine: Sprite2D) -> void:
	if vine.has_meta("wind_vine"): return
	var dimensions: Vector2 = vine.texture.get_size() * vine.scale.abs()
	var top: Vector2 = vine.position - Vector2(0, dimensions.y * 0.5)
	var cell := VINES.get_size() / Vector2(3, 1)
	var column := 1 if family == "ash" else (2 if family == "star" else 0)
	var atlas := AtlasTexture.new()
	atlas.atlas = VINES
	atlas.region = Rect2(Vector2(column * cell.x + cell.x * 0.08, cell.y * 0.02), cell * Vector2(0.84, 0.96))
	atlas.filter_clip = true
	vine.texture = atlas
	vine.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	vine.scale = Vector2.ONE * (dimensions.y / atlas.region.size.y)
	vine.position = top
	vine.offset.y = atlas.region.size.y * 0.5
	vine.set_meta("wind_vine", true)
	vine.set_meta("wind_phase", fposmod(vine.global_position.x * 0.037 + vine.global_position.y * 0.023, TAU))

func set_low_quality(value: bool) -> void:
	low_quality = value
	if is_instance_valid(ground_contacts): ground_contacts.set_low_quality(value)
	while brushing.size()>brush_budget():
		var retired: Node2D = brushing.pop_back()
		if is_instance_valid(retired): retired.reset_response()
	if is_instance_valid(parallax_architecture): parallax_architecture.set_low_quality(value)
	selection_clock = 1
	_process(0)

func animation_budget() -> int:
	return 8 if low_quality else 18

func brush_budget() -> int:
	return 6 if low_quality else 12

func clear_brushing() -> void:
	for prop in brushing:
		if is_instance_valid(prop): prop.reset_response()
	brushing.clear()
	player_sample_valid = false
	if is_instance_valid(brush_motes): brush_motes.clear()
	if is_instance_valid(ground_contacts): ground_contacts.clear()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player): return
	if player is Player and (player.is_dead or player.test_noclip):
		clear_brushing(); return
	var at := player.global_position
	if not player_sample_valid:
		player_previous = at; player_sample_valid = true
	sample_brushing(player_previous,at,(at-player_previous)/maxf(delta,0.0001),delta)
	player_previous = at
	if player is Player: ground_contacts.track(player,delta,brush_palette)

func sample_brushing(from: Vector2, to: Vector2, velocity: Vector2, delta: float) -> void:
	# A room warp/respawn is not a 10,000px gust through every intervening plant.
	if from.distance_to(to)>180:
		clear_brushing(); return
	if is_instance_valid(brush_motes): brush_motes.advance(delta)
	for index in range(brushing.size()-1,-1,-1):
		var prop := brushing[index]
		if not is_instance_valid(prop): brushing.remove_at(index); continue
		if not prop.is_visible_in_tree() or not prop.advance_response(delta):
			prop.reset_response(); brushing.remove_at(index)
	if velocity.length()<8: return
	var query := Rect2(from,Vector2.ZERO).expand(to).grow(30)
	var seen := {}
	var touched: Array[Node2D] = []
	for x in range(floori(query.position.x/BRUSH_CELL),floori(query.end.x/BRUSH_CELL)+1):
		for y in range(floori(query.position.y/BRUSH_CELL),floori(query.end.y/BRUSH_CELL)+1):
			for prop in brush_bins.get(Vector2i(x,y),[]):
				if not is_instance_valid(prop) or seen.has(prop.get_instance_id()): continue
				seen[prop.get_instance_id()] = true; brush_queries += 1
				if prop.is_visible_in_tree() and Response.crosses(prop.reaction_bounds(),from,to): touched.append(prop)
	touched.sort_custom(func(a: Node2D,b: Node2D): return a.global_position.distance_squared_to(to)<b.global_position.distance_squared_to(to))
	var touching_now: Array[Node2D] = []
	var forces: Array[float] = []
	for prop in touched:
		var force := clampf(velocity.x/165.0,-1.5,1.5)*0.25
		# Roots and cloth hanging from their top also respond to the player's
		# head on an upward jump. Grounded grass still needs a landing or pass.
		var hanging: bool = prop.reaction_bounds().get_center().y>prop.global_position.y
		if absf(velocity.x)<12 and (velocity.y>30 or (hanging and velocity.y < -30)):
			force = signf(prop.global_position.x-to.x+0.01)*minf(absf(velocity.y)/600,0.3)
		if absf(force)<0.01: continue
		touching_now.append(prop); forces.append(force)
		if touching_now.size()>=brush_budget(): break
	for index in touching_now.size():
		var prop := touching_now[index]
		var force := forces[index]
		_reserve_brush_slot(prop,touching_now,to)
		var fresh: bool = prop.brush(force)
		if not prop in brushing: brushing.append(prop)
		brush_contacts += 1
		if fresh and is_instance_valid(brush_motes) and not low_quality:
			brush_motes.burst(Vector2(clampf(to.x,prop.reaction_bounds().position.x,prop.reaction_bounds().end.x),prop.reaction_bounds().end.y),force,brush_palette)

func _reserve_brush_slot(prop: Node2D, touching_now: Array[Node2D], at: Vector2) -> void:
	if prop in brushing or brushing.size()<brush_budget(): return
	# A remote settling clump must not make the next plant unresponsive. Keep
	# the nearest current contacts, then use spare slots for the fading trail.
	var retired := -1
	var farthest := -1.0
	for index in brushing.size():
		var candidate := brushing[index]
		if candidate in touching_now: continue
		var distance := candidate.global_position.distance_squared_to(at)
		if distance>farthest: farthest = distance; retired = index
	if retired>=0:
		brushing[retired].reset_response()
		brushing.remove_at(retired)

func _animation_bounds(node: Node2D) -> Rect2:
	if node.has_method("reaction_bounds"): return node.reaction_bounds()
	if node.has_meta("ceiling_seep"): return node.footprint
	return Rect2(node.global_position,Vector2.ZERO)

func _animation_distance_squared(node: Node2D, point: Vector2) -> float:
	var bounds := _animation_bounds(node)
	return point.distance_squared_to(Vector2(clampf(point.x,bounds.position.x,bounds.end.x),clampf(point.y,bounds.position.y,bounds.end.y)))

func _animation_category(node: Node2D) -> int:
	if node is LampFlame and node.lamp.is_revealed and (node.lamp.is_active or node.lamp.is_resting): return 1
	if node is Machinery and is_instance_valid(node.wheel): return 2
	if node is IndustrialMachine and is_instance_valid(node.rotor) and node.enabled: return 2
	return 0

func select_visible(world_view: Rect2) -> void:
	var visible: Array[Node2D] = []
	var padded := world_view.grow(100)
	for node in candidates:
		if not is_instance_valid(node) or not node.is_visible_in_tree(): continue
		var bounds := _animation_bounds(node)
		if padded.has_point(node.global_position) or (bounds.has_area() and padded.intersects(bounds)):
			visible.append(node)
	var center := world_view.get_center()
	visible.sort_custom(func(a: Node2D, b: Node2D): return _animation_distance_squared(a,center) < _animation_distance_squared(b,center))
	var next_active: Array[Node2D] = []
	# A dense grass band must not monopolize every visible animation slot.
	# Lit lamps and moving rotors share small reservations, not extra budgets.
	for category in [1,2]:
		var reserved := 0
		for node in visible:
			if _animation_category(node)!=category: continue
			next_active.append(node); reserved += 1
			if reserved>=(1 if low_quality else 2): break
	for node in visible:
		if node in next_active: continue
		next_active.append(node)
		if next_active.size() >= animation_budget(): break
	# Camera selection runs every quarter-second, independently of the slower
	# low-cost paint tick. Rest only outgoing props; retained grass/cloth/vines
	# must not visibly snap to their first pose between animation updates.
	for node in active:
		if not is_instance_valid(node) or node in next_active: continue
		if node.has_meta("wind_vine"): node.rotation = 0
		elif node.has_meta("ambient_motion"): node.rest()
	active.assign(next_active)

func _process(delta: float) -> void:
	if background == null or not background.is_inside_tree(): return
	age += delta
	tick += delta
	selection_clock += delta
	var inverse := get_viewport().canvas_transform.affine_inverse()
	var view := get_viewport().get_visible_rect()
	var world_view: Rect2 = inverse * view
	if selection_clock >= 0.25:
		selection_clock = 0
		select_visible(world_view)
	if tick < (0.1 if low_quality else 0.05): return
	tick = 0
	updates += 1
	for node in active:
		if not is_instance_valid(node): continue
		if node.has_meta("wind_vine"):
			var phase: float = node.get_meta("wind_phase")
			var gust := 0.55 + 0.45 * sin(age * 0.31)
			node.rotation = (sin(age * 1.1 + phase) * 0.014 + sin(age * 2.3 + phase) * 0.006) * gust
		else:
			node.animate(age)
	background.material.set_shader_parameter("wind_time", age)
	air.update_air(family, age, low_quality, world_view.get_center(), view.size)
