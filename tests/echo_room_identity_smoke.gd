extends SceneTree

const WORLD_LAYOUT = preload("res://WorldLayout.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _count_prefix(parent: Node, prefix: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.name.begins_with(prefix):
			count += 1
	return count


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_identity_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var room_specs: Array[Dictionary] = [
		{"room": "EchoGrotto", "identity": "ResonanceChoir", "feature": "ChoirDais", "count": 3, "hint": "crystal choir"},
		{"room": "EchoGallery", "identity": "WhisperGalleries", "feature": "ListeningNiche", "count": 4, "hint": "whisper arches"},
		{"room": "PrismArchive", "identity": "MirrorStacks", "feature": "ReadingMirror", "count": 4, "hint": "Reflected light"},
		{"room": "TideWell", "identity": "TidalCurrents", "feature": "RisingCurrent", "count": 4, "hint": "ride its rising"},
		{"room": "EchoNest", "identity": "BroodNurseries", "feature": "NurseryPerch", "count": 4, "hint": "Brood chambers"},
		{"room": "CrystalCauseway", "identity": "PhaseCauseway", "feature": "TraversalPhaseBridge", "count": 4, "hint": "bridge disappears"},
		{"room": "UndertowVault", "identity": "SluiceVault", "feature": "SluiceSurge", "count": 3, "hint": "both seals"},
	]
	var hints: Dictionary = {}
	for spec in room_specs:
		var room_id := ""
		for candidate_id in WORLD_LAYOUT.ROOM_NODES:
			if WORLD_LAYOUT.ROOM_NODES[candidate_id] == spec["room"]:
				room_id = candidate_id
				break
		_check(not room_id.is_empty(), "%s has no world-layout room id" % spec["room"])
		state.set_current_room(room_id)
		await process_frame
		var room: Node2D = game.get_node(spec["room"])
		var route: Node2D = room.get_node("LongTraversal")
		_check(route.is_population_loaded(), "%s did not stream its traversal population on entry" % spec["room"])
		_check(route.has_node(spec["identity"]), "%s lacks its identity landmark" % spec["room"])
		_check(_count_prefix(route, spec["feature"]) == int(spec["count"]), "%s has an incomplete signature traversal feature" % spec["room"])
		var hint: String = route.get_node("RouteHint").text
		_check(spec["hint"] in hint, "%s route hint does not explain its identity" % spec["room"])
		_check(not hints.has(hint), "%s reused another room's identity text" % spec["room"])
		hints[hint] = true
		_check(_count_prefix(route, "QuietCaveLife") == 5, "%s lacks ambient fauna" % spec["room"])

	var tide_route: Node2D = game.get_node("TideWell/LongTraversal")
	for index in range(4):
		var current: Area2D = tide_route.get_node("RisingCurrent%02d" % index)
		_check(current.get("flow_velocity").y < 0.0, "Tide current %d is not an updraft" % index)
		_check(current.get_node("CollisionShape2D").shape.size == Vector2(360.0, 92.0), "Tide current %d has no readable field" % index)
		_check(current.has_node("DirectionArrow"), "Tide current %d lacks a direction indicator" % index)

	var causeway_route: Node2D = game.get_node("CrystalCauseway/LongTraversal")
	for index in range(4):
		var bridge: StaticBody2D = causeway_route.get_node("TraversalPhaseBridge%02d" % index)
		_check(bridge.get_node("CollisionShape2D").one_way_collision, "Causeway phase bridge %d blocks recovery jumps" % index)
		_check(is_equal_approx(bridge.scale.x, 1.55), "Causeway phase bridge %d is not a substantial crossing" % index)

	var vault_route: Node2D = game.get_node("UndertowVault/LongTraversal")
	_check(_count_prefix(vault_route, "UndertowCurrent") == 2, "Vault lacks reversible undertow fields")
	for index in range(3):
		var surge: Area2D = vault_route.get_node("SluiceSurge%02d" % index)
		var expected_seal := "echo_vault_upper" if index == 0 else "echo_vault_far"
		_check(surge.get("disabled_by_shortcut_id") == expected_seal, "Vault surge %d is not tied to seal progress" % index)

	# Currents stop during lamp rest, pause, and inactive-room streaming, then
	# resume without carrying a hidden impulse into the next room.
	state.set_current_room("echo_tide_well")
	await process_frame
	await physics_frame
	var player: Player = game.get_node("Player")
	var test_current: Area2D = tide_route.get_node("RisingCurrent00")
	player.set_physics_process(false)
	player.global_position = test_current.global_position
	player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	_check(test_current.get_overlapping_bodies().has(player), "Tide current integration probe did not overlap the player")
	test_current._physics_process(0.5)
	_check(player.velocity.length() > 0.1, "Active Tide current did not nudge the player")
	player.velocity = Vector2.ZERO
	player.is_safe_resting = true
	test_current._physics_process(0.5)
	_check(player.velocity == Vector2.ZERO, "Tide current moved the player during safe rest")
	player.is_safe_resting = false
	paused = true
	_check(not test_current.can_process(), "Tide current continues processing while the game is paused")
	paused = false
	var age_before_disable: float = test_current.get("age")
	state.set_current_room("echo_grotto")
	await process_frame
	_check(not test_current.can_process(), "Tide current continues processing while its room is disabled")
	await process_frame
	_check(is_equal_approx(float(test_current.get("age")), age_before_disable), "Disabled Tide current advanced its state")
	state.set_current_room("echo_tide_well")
	await process_frame
	await process_frame
	_check(test_current.can_process() and float(test_current.get("age")) > age_before_disable, "Tide current did not resume consistently after room reactivation")
	player.set_physics_process(true)

	# The established checkpoint network must not move while room interiors grow.
	_check(game.get_node("EchoGrotto/GrottoLamp").position == Vector2(262.0, 128.0), "Grotto lamp moved during identity pass")
	_check(game.get_node("EchoGallery/GalleryLamp").position == Vector2(116.0, 128.0), "Gallery lamp moved during identity pass")
	_check(game.get_node("TideWell/TideLamp").position == Vector2(92.0, 628.0), "Tide lamp moved during identity pass")
	_check(game.get_node("EchoNest/NestLamp").position == Vector2(91.0, 128.0), "Nest lamp moved during identity pass")
	_check(game.get_node("UndertowVault/VaultLamp").position == Vector2(916.0, 377.0), "Vault lamp moved during identity pass")
	var sanctum: Node2D = game.get_node("ResonanceSanctum")
	_check(sanctum.has_node("SanctumCrown") and sanctum.has_node("CoreShard"), "Sanctum lacks its resonance focal landmark")
	_check(sanctum.get_node("UpperLeftPerch/CollisionShape2D").one_way_collision and sanctum.get_node("UpperRightPerch/CollisionShape2D").one_way_collision, "Sanctum upper evasion perches block jumps")
	_check(sanctum.get_node("LeftPlatform").position.y - sanctum.get_node("UpperLeftPerch").position.y <= 70.0, "Sanctum upper perch exceeds the default jump")

	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO ROOM IDENTITY TEST PASSED")
		quit(0)
	else:
		print("ECHO ROOM IDENTITY TEST FAILED: ", failures)
		quit(1)
