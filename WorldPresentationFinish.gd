extends Node
## Runtime finish pass for real camera views. Existing collisions and native
## interactions stay intact; audited endpoint walls are explicit additions.
## The editor retains its overview background masks.
const Layout = preload("res://WorldLayout.gd")
const Depth = preload("res://RoomPaintedDepth.gd")
const Settlement = preload("res://PaintedSettlementBackdrop.gd")
const Slice = preload("res://VisualStyleSlice.gd")
const Props = preload("res://CavernDressingArt.gd")
const Support = preload("res://WorldSupport.gd")
const Portals = preload("res://PortalContextArt.gd")
var finished := {}
var background: TextureRect
var focused_labels: Array[Label] = []
var focus_clock := 0.0
var state: Node
var player: Node2D
var reader: CanvasLayer
var ambience: Node
var resident_contacts: Array[Sprite2D] = []
var current_surfaces: Array[Rect2] = []
var device_labels: Array[Label] = []
var current_room_id := ""
var devices_refresh_queued := false

func _ready() -> void:
	state = get_node("/root/GameState")
	player = get_parent().get_node("Player")
	reader = preload("res://WorldReadables.gd").new()
	add_child(reader)
	background = preload("res://CameraPaintedBackdrop.gd").new()
	background.name = "CameraPainting"
	get_parent().get_node("Background/BiomeBackdrop").add_child(background)
	ambience = preload("res://WorldAmbience.gd").new()
	ambience.name = "Ambience"
	ambience.background = background
	add_child(ambience)
	state.room_changed.connect(_request_room)
	state.mode_changed.connect(func(_mode): _request_room(state.current_room_id))
	get_tree().node_added.connect(_on_device_added)
	call_deferred("_initial_finish")

func _initial_finish() -> void:
	await get_tree().process_frame
	_opening_boundary()
	finish_room(state.current_room_id)

func _request_room(id: String) -> void:
	call_deferred("finish_room", id)

func _on_device_added(node: Node) -> void:
	if devices_refresh_queued or not finished.has(current_room_id): return
	if not (node is LevelExit or node.is_in_group("room_door") or node.is_in_group("checkpoint") or node.is_in_group("shaft_lift") or node.is_in_group("town_resident") or node.is_in_group("town_service") or node.get_script() == preload("res://ResonanceCache.gd")): return
	var room := get_parent() if current_room_id == "training_passage" else get_parent().get_node_or_null(str(Layout.ROOM_NODES.get(current_room_id, "")))
	if room == null or not room.is_ancestor_of(node): return
	if room == get_parent():
		var ancestor := node.get_parent()
		while ancestor != null and ancestor != room:
			if String(ancestor.name) in Layout.ROOM_NODES.values(): return
			ancestor = ancestor.get_parent()
	devices_refresh_queued = true
	call_deferred("_refresh_added_devices")

func _refresh_added_devices() -> void:
	# Let the native scene finish _ready/configuration before drawing it.
	await get_tree().process_frame
	devices_refresh_queued = false
	if is_inside_tree() and not is_queued_for_deletion(): finish_room(state.current_room_id)

func _members(room: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in room.get_children():
		if room == get_parent() and (String(child.name) in Layout.ROOM_NODES.values() or child.name in ["UI", "Background", "Player"]): continue
		result.append(child)
		result.append_array(_members(child))
	return result

func finish_room(id: String) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(background) or not background.is_inside_tree(): return
	var room := get_parent() if id == "training_passage" else get_parent().get_node_or_null(str(Layout.ROOM_NODES.get(id, "")))
	if room == null: return
	current_room_id = id
	_retire_room_sketch(room)
	if finished.has(id):
		background.use_paint(finished[id].paint, room.global_position, id)
		focused_labels.assign(finished[id].labels)
		var current_nodes := _members(room)
		_finish_streamed_devices(current_nodes, id)
		_register_contacts(current_nodes)
		for node in current_nodes:
			if not is_instance_valid(node): continue
			if node is LevelExit or node.is_in_group("room_door"): Portals.install(node, id, current_surfaces, current_nodes)
		current_nodes = _members(room)
		preload("res://RouteVaults.gd").install(room, id, current_nodes)
		preload("res://WorldRouteRelief.gd").install(room, id, current_nodes)
		current_nodes = _members(room)
		preload("res://WorldTerrainEnvelope.gd").install(room, id, current_nodes)
		preload("res://WorldNaturalContours.gd").install(room, id, current_nodes)
		var compositions := preload("res://RegionalAmbientDressing.gd").install(room, id, current_nodes)
		compositions.refresh_devices(current_nodes)
		preload("res://WorldForegroundDressing.gd").install(room, id, current_nodes)
		preload("res://WorldCorridorDressing.gd").install(room, id, current_nodes)
		preload("res://WorldPathDressing.gd").install(room, id, _members(room))
		preload("res://WorldTerrainJoints.gd").install(room, id, _members(room))
		preload("res://WorldAmbientFauna.gd").install(room, id, _members(room))
		current_nodes = _members(room)
		reader.register_room(id, current_nodes)
		ambience.register_room(id, current_nodes)
		return
	var nodes := _members(room)
	preload("res://IndustrialLandmarkArt.gd").finish_identity(nodes)
	nodes = _members(room)
	reader.register_room(id, nodes)
	if id == "training_passage": _finish_camp()
	var paint: Texture2D
	var labels: Array[Label] = []
	for node in nodes:
		if node.get_script()==preload("res://TownMaterialExpansion.gd"): node.queue_redraw()
		if node is Depth or node is Settlement or node is Slice:
			if node is Slice: node.queue_redraw() # Shared edge art retires its old pilot skirts this frame.
			for plate in node.plates:
				if paint == null and plate.texture != null: paint = plate.texture
				plate.hide()
				plate.set_meta("camera_painted_plate", true)
		# Distant prototype wedges must not occlude the camera-covering painting.
		if node is Polygon2D and node.get_child_count() == 0 and node.texture == null and node.z_index < 0:
			var named := String(node.name)
			if named in ["CentralGlow", "CrystalGlow", "CrystalCluster", "CrystalVein", "RelayGlow", "Arch", "InnerGlow"] or named.begins_with("Stalagmite") or named.begins_with("CaveTooth") or named.begins_with("CeilingShard"):
				node.hide()
		if node is Line2D and (node.name in ["SurfaceGlow", "MaterialRim", "StoneRim", "ShaftRimLight"] or String(node.name).ends_with("RimLight")):
			node.hide()
		if node is StaticBody2D and not node.is_in_group("enemy") and not node.is_in_group("breakable"):
			_finish_surface(node, id)
		if node is LevelExit or node.is_in_group("room_door"):
			_finish_device(node, "door", id)
		elif node.is_in_group("checkpoint"):
			_finish_device(node, "lamp", id)
		elif node.is_in_group("shaft_lift"):
			_finish_device(node, "lift", id)
		if node is Label:
			node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			if node.name == "AreaTitle": node.hide() # HUD already identifies the room.
			if (node.name in ["CampSign", "Title", "Hint", "RouteClue", "NameLabel", "SleepLabel", "AqueductSign", "CourtSign", "SurveyBoard"] or (node.name == "StatusLabel" and String(node.get_parent().name).begins_with("Sample")) or (node.name == "Label" and node.get_parent().is_in_group("item_pickup"))) and not _combat_label(node):
				labels.append(node)
				node.add_theme_color_override("font_outline_color", Color("08121b"))
				node.add_theme_constant_override("outline_size", 2)
	if paint == null:
		paint = load("res://art/visual_slice/training_aqueduct_depth_v1.png")
	finished[id] = {"paint": paint, "labels": labels}
	background.use_paint(paint, room.global_position, id)
	focused_labels.assign(labels)
	_register_contacts(nodes)
	Portals.close_outer_edges(room, nodes, current_surfaces, id)
	preload("res://WorldOuterBoundary.gd").install(room, _members(room), current_surfaces)
	var structural_nodes := _members(room)
	for node in structural_nodes:
		if not is_instance_valid(node): continue
		if node is LevelExit or node.is_in_group("room_door"):
			Portals.install(node, id, current_surfaces, structural_nodes)
	preload("res://RouteVaults.gd").install(room, id, _members(room))
	preload("res://WorldRouteRelief.gd").install(room, id, _members(room))
	preload("res://RegionalAmbientDressing.gd").install(room, id, _members(room))
	preload("res://WorldTerrainEnvelope.gd").install(room, id, _members(room))
	preload("res://WorldNaturalContours.gd").install(room, id, _members(room))
	preload("res://WorldForegroundDressing.gd").install(room, id, _members(room))
	preload("res://WorldCorridorDressing.gd").install(room, id, _members(room))
	preload("res://WorldPathDressing.gd").install(room, id, _members(room))
	preload("res://WorldTerrainJoints.gd").install(room, id, _members(room))
	preload("res://WorldAmbientFauna.gd").install(room, id, _members(room))
	# Early registration retires source labels before presentation fitting;
	# now validate their pedestals against the final portal/vault/relief solids.
	var final_nodes := _members(room)
	reader.register_room(id, final_nodes)
	ambience.register_room(id, final_nodes)

func _combat_label(label: Label) -> bool:
	var node: Node = label
	while node != get_parent() and node != null:
		if node.is_in_group("enemy") or node is LevelExit: return true
		node = node.get_parent()
	return false

func _retire_room_sketch(room: Node2D) -> void:
	for node in _members(room):
		if not (node is Polygon2D or node is Line2D) or node.get_child_count() != 0 or node.get_script() != null: continue
		var owner_script: Script = node.get_parent().get_script()
		var named := String(node.name)
		var old_hub: bool = owner_script == preload("res://VerticalHubExpansion.gd")
		var old_descent: bool = node.get_parent().name in ["AuthoredDescent", "StarfallDescent"] and (named.begins_with("ChamberShadow") or named.begins_with("ChamberShaftShadow") or named.begins_with("Pier") or named.begins_with("Seep") or named.begins_with("OreVein") or named.begins_with("Preview") or named.begins_with("HollowLooseRock") or named.begins_with("CrossingFlow") or named.begins_with("CrossingAqueductArch") or named.begins_with("ApproachSightline") or named == "BlackwaterBelow")
		var descent_outline: bool = node.get_parent().name in ["AuthoredDescent","StarfallDescent"] and (named.begins_with("HollowTimber") or (named.begins_with("Niche") and named.ends_with("_Alcove")) or (named.begins_with("Branch") and named.ends_with("_Shadow")))
		var echo_outline: bool = owner_script in [preload("res://EchoTraversal.gd"),preload("res://ExpeditionWing.gd")] and (named.begins_with("ChamberPocket") or named.begins_with("RouteShaft") or named.ends_with("Outline") or named.ends_with("Backdrop") or named.begins_with("MainShaft") or named.begins_with("BranchPassage") or named=="OptionalLoop")
		if old_hub or old_descent or descent_outline or echo_outline:
			node.hide()
			node.set_meta("camera_backdrop_retired", true)
	# Room-wide base rectangles belong to the editor overview. Some painters
	# texture FurnaceWall etc., leaving this separate Backdrop over the camera
	# painting. Hide only audited childless rear scenery, never a gameplay root.
	var names: Array = ["Backdrop"]
	names.append_array({
		"CinderForge": ["FurnaceCore", "VentDuct"],
		"CinderHearth": ["StoneWalk", "WalkwayLine", "HearthGlow", "DistantRamparts"],
		"EchoHaven": ["HavenGlow", "CrystalCanopy", "CrystalVeins", "WalkwayInlay"],
		"EchoHavenOutskirts": ["CrystalSeam", "RoadInlay", "DistantCrystals"],
		"ShaftHollow": ["DeepStone","CrystalVein","RelayGlow"],
		"DrownedCrossing": ["DeepWater","SluiceChannel","FlowLine"],
	}.get(String(room.name), []))
	for named in names:
		var sketch := room.get_node_or_null(NodePath(named))
		if (sketch is Polygon2D or sketch is Line2D) and sketch.get_child_count() == 0 and (sketch.z_index < 0 or named in ["WalkwayInlay","RoadInlay"]):
			sketch.hide()
			sketch.set_meta("camera_backdrop_retired", true)
	# These expansion masks were built after the original settlement painter.
	# Keep them in the editor overview, never over the camera-wide painting.
	for node in room.find_children("*","",true,false):
		if not (node is Polygon2D or node is Line2D) or node.get_child_count()!=0: continue
		if node.get_parent().get_script()!=preload("res://EchoSettlementExpansion.gd"): continue
		var named := String(node.name)
		if named.begins_with("DistrictPocket") or named.begins_with("CavernRib") or named.begins_with("DistrictShaft") or named.begins_with("AlleyCut") or named in ["HavenCurrent","SkyGardenCanopy"]:
			node.hide()
			node.set_meta("camera_backdrop_retired",true)

func _process(delta: float) -> void:
	focus_clock += delta
	if focus_clock < 0.12 or not is_instance_valid(player): return
	focus_clock = 0
	_ground_residents()
	_focus_devices()
	var nearest: Label
	var distance := 135.0
	for label in focused_labels:
		if not is_instance_valid(label) or label.has_meta("world_readable") or not label.is_visible_in_tree(): continue
		var at := label.global_position + label.size * 0.5
		var d := player.global_position.distance_to(at)
		if d < distance:
			nearest = label
			distance = d
	for label in focused_labels:
		if is_instance_valid(label): label.modulate.a = 1.0 if label == nearest and not label.has_meta("world_readable") else 0.0

func _finish_surface(body: StaticBody2D, id: String) -> void:
	if body.has_meta("world_surface_finished"): return
	var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		for child in body.get_children():
			if child is CollisionShape2D: collision = child; break
	if collision == null or not collision.shape is RectangleShape2D or collision.disabled: return
	var size: Vector2 = collision.shape.size
	if size.x < 8 or size.y < 4: return
	body.set_meta("world_surface_finished", true)
	var filename := "cinder_masonry_v1" if id.begins_with("ash_") else ("starfall_masonry_v1" if id.begins_with("starfall_") else "echo_path_stone_v1")
	var texture := load("res://art/visual_slice/%s.png" % filename) as Texture2D
	var visual: Polygon2D
	for child in body.get_children():
		if child is Polygon2D and child.get_script() == null:
			visual = child
			break
	if visual == null:
		visual = Polygon2D.new()
		visual.name = "FinishedWall"
		var r := Rect2(collision.position - size * 0.5, size)
		visual.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		body.add_child(visual)
	Support.align_rectangle(visual, collision)
	if visual.texture == null:
		preload("res://RoomArtFinish.gd")._material(visual, texture, Color("8a9597"))
	if size.x > 90 and size.y <= 32:
		# Roots and chipped undersides are decoration, never disguised collision.
		var count := clampi(int(size.x / 140), 1, 12)
		for index in range(count):
			var width := minf(100 + (index % 3) * 11, size.x / count)
			var x := collision.position.x - size.x * 0.5 + (index + 0.5) * size.x / count
			var art := Props.sprite(body, 4, "RootedLip%d" % index, Vector2(x, collision.position.y - size.y * 0.5 + 10), Vector2(width, 30))
			art.z_index = -1
			art.modulate = Color("8a9597")
	elif size.y > 80 and size.x <= 80:
		var vine := Props.sprite(body, 5, "WallIvy", collision.position + Vector2(size.x * 0.4, -size.y * 0.3), Vector2(25, minf(100, size.y * 0.5)))
		vine.modulate = Color("7b9093")
	preload("res://TerrainEdgeArt.gd").install(body, collision, visual, id)

func _finish_device(actor: Node2D, kind: String, room_id: String) -> void:
	if actor.has_node("FinishedDevice"): return
	var art: Sprite2D
	match kind:
		"door":
			var variant := 1 if room_id in ["sunken_shaft", "shaft_hollow", "shaft_drift", "shaft_approach", "ash_forge", "ash_emberspine"] else 0
			art = Props.sprite(actor, variant, "FinishedDevice", Vector2(0, -2), Vector2(62, 60))
		"lamp": art = Props.sprite(actor, 2, "FinishedDevice", Vector2(0, -8), Vector2(23, 38))
		"lift": art = Props.sprite(actor, 3, "FinishedDevice", Vector2(0, -9), Vector2(49, 48))
	for named in ["Frame", "Core", "Glow", "Rails"]:
		var original := actor.get_node_or_null(named)
		if original is CanvasItem: original.hide()
	# Native gate/lamp prompts remain authoritative for lock, save and travel.
	art.z_index = -1
	if room_id.begins_with("ash_"): art.modulate = Color("b3a197")
	elif room_id.begins_with("starfall_"): art.modulate = Color("aaa5c0")
	if kind == "lamp": preload("res://CheckpointLampArt.gd").attach(actor, art, room_id)

func _opening_boundary() -> void:
	var game := get_parent()
	if game.has_node("OpeningWestWall"): return
	var wall := StaticBody2D.new()
	wall.name = "OpeningWestWall"
	wall.position = Vector2(22, 100)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(28, 600)
	wall.add_child(collision)
	game.add_child(wall)

func _register_contacts(nodes: Array[Node]) -> void:
	current_surfaces = Support.floors(nodes)
	preload("res://WorldLegacyDetailFinish.gd").install(nodes,current_room_id,current_surfaces)
	preload("res://WorldSceneryCompletion.gd").install(nodes,current_room_id,current_surfaces)
	resident_contacts.clear()
	device_labels.clear()
	for node in nodes:
		if not is_instance_valid(node): continue
		if node.get_script() == preload("res://CachePaintedArt.gd"): node.supply_surfaces(current_surfaces)
		if node.get_script() == preload("res://ServicePaintedArt.gd"):
			node.supply_surfaces(current_surfaces)
			var service_label := node.get_parent().get_node_or_null("NameLabel") as Label
			if service_label != null and not focused_labels.has(service_label):
				focused_labels.append(service_label)
				if finished.has(current_room_id) and not finished[current_room_id].labels.has(service_label): finished[current_room_id].labels.append(service_label)
		if node.get_script() == preload("res://ResidentMotion.gd"):
			node.supply_surfaces(current_surfaces)
			var name_label := node.get_parent().get_node_or_null("NameLabel") as Label
			if name_label != null and node.visible and not node.surfaces.is_empty():
				# Foot correction lowers some old floating bodies; keep the nearest
				# name near the actual head rather than at its old overview height.
				name_label.position.y = node.foot_y - (29 if node.painted.role==0 else 31) - 18
				name_label.add_theme_font_size_override("font_size",8)
				name_label.add_theme_color_override("font_outline_color",Color("08121b"))
				name_label.add_theme_constant_override("outline_size",2)
			if name_label != null and not focused_labels.has(name_label):
				focused_labels.append(name_label)
				if finished.has(current_room_id) and not finished[current_room_id].labels.has(name_label): finished[current_room_id].labels.append(name_label)
		if node.get_script() == preload("res://IndustrialLandmarkArt.gd"):
			node.supply_surfaces(current_surfaces)
		if node.get_script() == preload("res://StarfallTaskArt.gd"):
			node.supply_surfaces(current_surfaces)
		if node is Sprite2D and (node.get_script() == preload("res://OpeningResidentArt.gd") or node.get_script() == preload("res://EchoGuideAppearance.gd")):
			resident_contacts.append(node)
		if node.has_node("DeviceArt") or node.has_node("TaskArt"):
			var device_label := node.get_node_or_null("StatusLabel") as Label
			if device_label!=null:
				device_labels.append(device_label)
				device_label.add_theme_font_size_override("font_size",8)
				device_label.add_theme_constant_override("outline_size",2)
				device_label.add_theme_color_override("font_outline_color",Color("08121a"))
		if not node.has_node("FinishedDevice"): continue
		var label := node.get_node_or_null("StatusLabel") as Label
		if label != null:
			device_labels.append(label)
			label.add_theme_font_size_override("font_size", 8)
			label.add_theme_constant_override("outline_size", 2)
			label.add_theme_color_override("font_outline_color", Color("08121a"))
		var floor_rect := Support.below(node.global_position, current_surfaces)
		if not floor_rect.has_area(): continue
		var art: Sprite2D = node.get_node("FinishedDevice")
		Support.plant(art, art.get_meta("contact_row"), floor_rect.position.y)
		if node.is_in_group("shaft_lift"): _frame_lift(node, floor_rect, nodes)
	_ground_residents()
	_focus_devices()

func _finish_streamed_devices(nodes: Array[Node], id: String) -> void:
	for node in nodes:
		if node is LevelExit or node.is_in_group("room_door"): _finish_device(node, "door", id)
		elif node.is_in_group("checkpoint"): _finish_device(node, "lamp", id)
		elif node.is_in_group("shaft_lift"): _finish_device(node, "lift", id)

func _focus_devices() -> void:
	if not is_instance_valid(player): return
	var closest: Label
	var distance := 100.0
	for label in device_labels:
		if not is_instance_valid(label) or not label.is_visible_in_tree(): continue
		var actor := label.get_parent() as Node2D
		var d := player.global_position.distance_to(actor.global_position)
		if d < distance: closest = label; distance = d
	for label in device_labels:
		if is_instance_valid(label): label.modulate.a = 1 if label == closest else 0

func _frame_lift(actor: Node2D, floor_rect: Rect2, nodes: Array[Node]) -> void:
	preload("res://LiftMechanismArt.gd").install(actor, floor_rect, current_room_id, current_surfaces, nodes)

func _ground_residents() -> void:
	for art in resident_contacts:
		if not is_instance_valid(art) or not art.is_visible_in_tree(): continue
		var floor_rect := Support.below(art.get_parent().global_position, current_surfaces)
		if not floor_rect.has_area(): continue
		# Guides already register frame offsets to their opaque boot row.
		var row: float = art.CONTACT_ROWS[art.role] if art.get_script() == preload("res://OpeningResidentArt.gd") else art.CONTACT_ROWS[art.region][art.frame]
		Support.plant(art, row, floor_rect.position.y)

func _finish_camp() -> void:
	var camp := get_parent().get_node("TrainingPassageDecor/GeneratedPassageDetails")
	if camp.has_node("PaintedCampShelter"): return
	for node in _members(camp):
		if node is Polygon2D and (node.name == "CampCanopy" or String(node.name).begins_with("CampLamp") or String(node.name).begins_with("Leaf")):
			node.hide()
		if node is Line2D and String(node.name).begins_with("CanopyPost"): node.hide()
	var shelter := Sprite2D.new()
	shelter.name = "PaintedCampShelter"
	var tex := AtlasTexture.new()
	tex.atlas = preload("res://art/visual_slice/echo_field_tent_v1.png")
	tex.region = Rect2(90, 132, 1522, 678)
	shelter.texture = tex
	shelter.scale = Vector2.ONE * (96.0 / 1522.0)
	shelter.position = Vector2(232, 390 - 678 * shelter.scale.y * 0.5)
	shelter.z_index = -2
	shelter.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	camp.add_child(shelter)
