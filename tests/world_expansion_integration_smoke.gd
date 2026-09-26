extends SceneTree

const LAYOUT = preload("res://WorldLayout.gd")

var failures: Array[String] = []
var watch_room: String = ""
var watch_player: Player
var watch_director: Node
var saw_frozen_switch := false


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _watch_room_change(room_id: String) -> void:
	if room_id != watch_room:
		return
	var room: Node2D = watch_director.rooms.get(room_id)
	saw_frozen_switch = room != null and room.visible and room.process_mode == Node.PROCESS_MODE_INHERIT and not watch_player.is_physics_processing()


func _bounds(room: Node2D) -> Rect2:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for node in room.find_children("*", "Node2D", true, false):
		var points: Array[Vector2] = []
		if node is Polygon2D:
			for point in node.polygon:
				points.append(node.to_global(point))
		elif node is Line2D:
			for point in node.points:
				points.append(node.to_global(point))
		elif node is CollisionShape2D and node.get_parent() is StaticBody2D and node.shape is RectangleShape2D:
			var half: Vector2 = node.shape.size * 0.5
			for point in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
				points.append(node.to_global(point))
		elif node is Marker2D:
			points.append(node.global_position)
		for point in points:
			low = low.min(point)
			high = high.max(point)
	if is_inf(low.x):
		return Rect2(room.global_position, Vector2.ZERO)
	return Rect2(low, high - low)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_expansion_integration_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var director: Node = game.get_node("RoomActivityDirector")
	var player: Player = game.get_node("Player")
	_check(director.rooms.size() == LAYOUT.ROOM_ORIGINS.size(), "RoomActivityDirector did not map every room origin")
	for room_id in LAYOUT.ROOM_ORIGINS:
		var room: Node2D = director.rooms.get(room_id)
		_check(room != null, "Activity director cannot find %s" % room_id)
		if room != null:
			_check(room.position == LAYOUT.ROOM_ORIGINS[room_id][1], "%s origin differs from WorldLayout" % room_id)
			_check(not room.visible and room.process_mode == Node.PROCESS_MODE_DISABLED, "%s was active in the starting passage" % room_id)
	state.set_current_room("sunken_shaft")
	var shaft: Node2D = director.rooms["sunken_shaft"]
	_check(shaft.visible and shaft.process_mode == Node.PROCESS_MODE_INHERIT, "Synchronous room signal did not activate the Shaft")
	_check(not director.rooms["echo_haven"].visible and director.rooms["echo_haven"].process_mode == Node.PROCESS_MODE_DISABLED, "Old room stayed active")
	await physics_frame
	# RoomTransition freezes physics before moving the player, and emits the
	# room change while still frozen. Observe after the director's own listener.
	watch_player = player
	watch_director = director
	watch_room = "echo_haven"
	state.room_changed.connect(_watch_room_change)
	var haven_lamp: Node2D = game.get_node("EchoHaven/HavenLamp/RespawnPoint")
	var transition = root.get_node("RoomTransition")
	var traveled: bool = await transition.transition_player(player, haven_lamp.global_position, "echo_haven")
	_check(traveled and saw_frozen_switch, "Door transition did not activate destination while player physics was frozen")
	_check(player.is_physics_processing() and player.global_position.distance_to(haven_lamp.global_position) < 35.0, "Player resumed before or away from the activated room")
	# Exercise the actual world-map fast-travel callback, not only its helper.
	var shaft_lamp: Node2D = game.get_node("VerticalChamber/UpperCheckpoint/RespawnPoint")
	state.register_lamp("sunken_shaft_lamp", "Sunken Shaft Lamp", "sunken_shaft", shaft_lamp.global_position)
	state.register_lamp("echo_haven_lamp", "Whisperlight Haven Lamp", "echo_haven", haven_lamp.global_position)
	var ui = game.get_node("UI")
	ui.map_allows_travel = true
	ui.selected_lamp_id = "sunken_shaft_lamp"
	watch_room = "sunken_shaft"
	saw_frozen_switch = false
	await ui._on_map_travel_pressed()
	_check(saw_frozen_switch and state.current_room_id == "sunken_shaft", "Fast travel did not synchronously activate the Shaft")
	_check(player.global_position.distance_to(shaft_lamp.global_position) < 35.0, "Fast travel missed its migrated lamp coordinate")
	# Calculate placed geometry, including @tool-generated platforms and
	# decorative polygons. Every independent room must have its own world cell.
	var rectangles: Dictionary = {}
	for room_id in director.rooms:
		rectangles[room_id] = _bounds(director.rooms[room_id])
	var closest_gap := INF
	var closest_pair := ""
	for a_id in rectangles:
		for b_id in rectangles:
			if str(a_id) >= str(b_id):
				continue
			_check(not rectangles[a_id].intersects(rectangles[b_id]), "%s geometry overlaps %s" % [a_id, b_id])
			var a: Rect2 = rectangles[a_id]
			var b: Rect2 = rectangles[b_id]
			var horizontal_gap := maxf(maxf(a.position.x - b.end.x, b.position.x - a.end.x), 0.0)
			var vertical_gap := maxf(maxf(a.position.y - b.end.y, b.position.y - a.end.y), 0.0)
			var gap_distance := Vector2(horizontal_gap, vertical_gap).length()
			if gap_distance < closest_gap:
				closest_gap = gap_distance
				closest_pair = "%s / %s" % [a_id, b_id]
	print("ROOM BOUNDS: %d rooms, nearest gap %.1f px (%s)" % [rectangles.size(), closest_gap, closest_pair])
	# Synthetic version-9 saves cover a moved Shaft lamp, an Echo town lamp,
	# both lamps with local offsets, and a Starfall city lamp.
	var lamps := [
		["sunken_shaft", "sunken_shaft_lamp", "VerticalChamber/UpperCheckpoint/RespawnPoint"],
		["echo_haven", "echo_haven_lamp", "EchoHaven/HavenLamp/RespawnPoint"],
		["shaft_cistern", "blackwater_cistern_lamp", "BlackwaterCistern/CisternLamp/RespawnPoint"],
		["shaft_approach", "warden_approach_lamp", "WardenApproach/ApproachLamp/RespawnPoint"],
		["starfall_citadel", "starfall_market_lamp", "StarfallCitadel/MarketLamp/RespawnPoint"],
	]
	for entry in lamps:
		var room_id: String = entry[0]
		var lamp_id: String = entry[1]
		var marker: Node2D = game.get_node(entry[2])
		var new_position: Vector2 = marker.global_position
		var old_local: Vector2 = new_position - LAYOUT.ROOM_ORIGINS[room_id][1] - LAYOUT.LAMP_LOCAL_OFFSETS.get(lamp_id, Vector2.ZERO)
		var old_position: Vector2 = LAYOUT.ROOM_ORIGINS[room_id][0] + old_local
		var legacy := {
			"version": 9,
			"current_room_id": room_id,
			"has_checkpoint": true,
			"checkpoint_lamp_id": lamp_id,
			"checkpoint_lamp_name": lamp_id,
			"checkpoint_position": [old_position.x, old_position.y],
			"discovered_lamps": {lamp_id: {"room_id": room_id, "name": lamp_id, "position": [old_position.x, old_position.y]}},
			"player_state": {"max_health": 10, "current_health": 10},
		}
		var save_file := FileAccess.open(state.save_path, FileAccess.WRITE)
		_check(save_file != null, "Could not write synthetic v9 save")
		if save_file == null:
			continue
		save_file.store_string(JSON.stringify(legacy))
		save_file.close()
		_check(state.load_game(), "%s v9 save could not load" % room_id)
		_check(state.checkpoint_position.distance_to(new_position) < 1.0, "%s v9 checkpoint did not migrate to current lamp" % room_id)
		_check(state.get_lamp_position(lamp_id).distance_to(new_position) < 1.0, "%s v9 discovered lamp did not migrate" % room_id)
		var active: Node2D = director.rooms.get(room_id)
		_check(active != null and active.visible and active.process_mode == Node.PROCESS_MODE_INHERIT, "%s v9 load did not activate its room immediately" % room_id)
	# The first physics frame in a fresh loaded scene must see the migrated
	# coordinate and the correct destination room already active.
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	director = game.get_node("RoomActivityDirector")
	player = game.get_node("Player")
	_check(state.current_room_id == "starfall_citadel" and director.rooms["starfall_citadel"].visible, "Fresh load did not activate the saved Starfall room before physics")
	_check(player.global_position.distance_to(state.checkpoint_position) < 1.0, "Fresh load did not place player at migrated checkpoint before physics")
	await physics_frame
	_check(player.global_position.distance_to(state.checkpoint_position) < 35.0, "Loaded player fell out of the active room on the first physics frame")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("WORLD EXPANSION INTEGRATION TEST PASSED")
		quit(0)
	else:
		print("WORLD EXPANSION INTEGRATION TEST FAILED: ", failures)
		quit(1)
