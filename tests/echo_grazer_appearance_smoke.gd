extends "res://tests/shaft_guard_combat_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_grazer_art_save.json"
	state.start_new_game("normal")
	player = _player()
	player.collision_layer = 0
	player.get_node("Camera2D").enabled = false
	var floor_node := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1500, 20)
	collider.shape = shape
	floor_node.add_child(collider)
	floor_node.position.y = 30
	root.add_child(floor_node)
	for side in [-1, 1]:
		await _live_case(side)
	for zone in ["sunken_shaft", "ash_fields", "training_passage"]:
		var other: CharacterBody2D = load("res://NeutralCreature.tscn").instantiate()
		other.zone_id = zone
		root.add_child(other)
		var expected: bool = zone != "ash_fields"
		_check(other.get_node("EchoAppearance").enabled == expected and other.sprite.visible != expected, "Expanded grazer region scope wrong: " + zone)
		other.queue_free()
	for species in ["Brood Moth", "Whisper Bat", "Tide Skimmer", "Shard Crawler", "Undertow Newt", "Lumen Moth", "Ward Skimmer"]:
		var other: CharacterBody2D = load("res://NeutralCreature.tscn").instantiate()
		other.zone_id = "echo_grotto"
		other.creature_name = species
		root.add_child(other)
		_check(not other.get_node("EchoAppearance").enabled and not other.get_node("EchoAppearance").is_processing(), "Grazer art leaked to species " + species)
		_check(other.get_node("FaunaAppearance").enabled and not other.sprite.visible, "Species-specific fauna appearance missing")
		other.queue_free()
	floor_node.queue_free()
	player.queue_free()
	await process_frame
	await _streaming_case(state)
	state.delete_save()
	if failures.is_empty():
		print("ECHO GRAZER APPEARANCE TEST PASSED: live sleep/wander/provocation, both directions, warning grace, hit/restore, scope, alpha/mipmaps and unchanged collision")
		quit(0)
	else:
		quit(1)


func _live_case(side: int) -> void:
	player.position = Vector2(side * 110, 10)
	var grazer: CharacterBody2D = load("res://NeutralCreature.tscn").instantiate()
	grazer.zone_id = "echo_grotto"
	grazer.position = Vector2(0, 10)
	grazer.direction = side
	grazer.rest_seconds = 0.3
	grazer.wander_seconds = 0.7
	root.add_child(grazer)
	var art := grazer.get_node("EchoAppearance")
	art.set_process(false)
	var geometry := {}
	for path in ["CollisionShape2D", "DetectionArea/CollisionShape2D", "AwarenessArea/CollisionShape2D", "TopHitbox/CollisionShape2D"]:
		var node := grazer.get_node(path)
		geometry[path] = [node.transform, node.shape.get_rid()]
	_check(art.enabled and not grazer.sprite.visible and art.frame == 0, "Echo grazer not initialized asleep")
	_check(not grazer._damage_player_if_possible(player), "Art made neutral fauna attack first")
	grazer._on_awareness_area_body_entered(player)
	_check(grazer.target_player == null, "Art enabled sight aggro")
	var sleep_seen := false
	var strides := {}
	for tick in range(90):
		await physics_frame
		art._process(1.0 / 60.0)
		_check(art.flip_h == (grazer.direction < 0), "Grazer facing mismatch")
		if grazer.resting:
			sleep_seen = true
			_check(art.frame == 0 and grazer.sleep_label.visible and is_zero_approx(grazer.velocity.x), "Sleep presentation disagrees with AI")
		elif art.frame in [2, 3]:
			strides[art.frame] = true
			art._process(0.001)
			_check(art.frame in [2, 3], "Walk flickers between physics ticks")
	_check(sleep_seen and strides.size() == 2, "Live rest/wander failed to exercise both strides")
	grazer.take_damage(1)
	art._process(0)
	_check(art.frame == 5 and art.modulate.r > art.modulate.g and grazer.current_health == 2, "Native hit feedback lost")
	var warning_ticks := 0
	for tick in range(40):
		await physics_frame
		art._process(1.0 / 60.0)
		# Native warning hides at is_zero_approx, before float subtraction hits 0.
		if grazer.grace_remaining > 0 and not is_zero_approx(grazer.grace_remaining):
			warning_ticks += 1
			_check(grazer.sleep_label.visible and grazer.sleep_label.text == "!" and not grazer._damage_player_if_possible(player), "Provocation warning/contact grace changed")
			if grazer.hit_flash_remaining <= 0:
				_check(art.frame == 4, "Provoked pose missing after hit flash")
	_check(warning_ticks >= 31 and grazer.is_hostile and grazer.health_bar.visible, "Wake grace/hostility changed")
	grazer.set_physics_process(false)
	art._process(0.2)
	_check(art.frame == 4, "Stopped hostile grazer keeps walking")
	grazer.restore_streamed_state({"current_health": 2, "is_hostile": false, "resting": true, "direction": -side})
	art._process(0.1)
	_check(art.frame == 0 and art.flip_h == (-side < 0), "Restored sleeping state/facing not reflected")
	grazer.restore_streamed_state({"current_health": 2, "is_hostile": true, "resting": false, "grace_remaining": 0.2, "direction": side})
	art._process(0.1)
	_check(art.frame == 4 and grazer.sleep_label.text == "!", "Restored warning state not reflected")
	grazer.hide()
	var distance: float = art.stride_distance
	grazer.position.x += 1000
	art._process(1)
	_check(art.stride_distance == distance, "Hidden grazer animates")
	grazer.show()
	grazer.grace_remaining = 0
	art._process(1)
	_check(art.frame == 4, "Hidden relocation becomes walking")
	grazer.position.x += 1000
	art._process(0.01)
	_check(art.frame == 4, "Visible teleport becomes walking")
	for path in geometry:
		var node := grazer.get_node(path)
		_check(node.transform == geometry[path][0] and node.shape.get_rid() == geometry[path][1], "Grazer collision mutated: " + path)
	_check(grazer.get_node("CollisionShape2D").shape.size == Vector2(22, 18) and grazer.xp_reward == 1 and grazer.gold_reward == 3, "Body/rewards changed")
	_check(not grazer.is_in_group("enemy") and grazer.is_in_group("neutral_creature"), "Neutral quest membership changed")
	var pixels: Image = art.texture.get_image()
	_check(pixels.get_size() == Vector2i(1536, 1024) and pixels.get_pixel(0, 0).a == 0 and pixels.has_mipmaps(), "Source size/alpha/mipmaps incorrect")
	_check(art.scale.is_equal_approx(Vector2.ONE * art.PIXEL_SCALE) and art.position == Vector2(0, 9), "Grazer sprite scale/pivot incorrect")
	grazer.queue_free()
	await process_frame


func _streaming_case(state: Node) -> void:
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	var detail := game.get_node("EchoNest/LongTraversal/FieldDressing")
	_check(not detail.has_node("Grazer3_0"), "Art spawned unvisited fauna")
	state.set_current_room("echo_nest")
	var actor := detail.get_node("Grazer3_0")
	actor.set_physics_process(false)
	var identity: int = actor.get_instance_id()
	actor.take_damage(1)
	actor.get_node("EchoAppearance")._process(0)
	_check(actor.get_node("EchoAppearance").frame == 5, "Streamed fauna hit pose missing")
	state.set_current_room("training_passage")
	_check(not actor.get_node("EchoAppearance").can_process(), "Off-room fauna art remains active")
	game.get_node("WorldPopulation").unload_room_population("EchoNest")
	await process_frame
	_check(not detail.has_node("Grazer3_0"), "Fauna art prevents unloading")
	state.set_current_room("echo_nest")
	actor = detail.get_node("Grazer3_0")
	actor.set_physics_process(false)
	actor.get_node("EchoAppearance")._process(0)
	_check(actor.get_instance_id() != identity and actor.is_hostile and actor.current_health == 2, "Recreated fauna lost hostility/damage")
	_check(actor.get_node("EchoAppearance").enabled and actor.get_node("EchoAppearance").frame == 4 and not actor.sprite.visible, "Reloaded appearance lost warning state")
	_check(actor.find_children("EchoAppearance", "Sprite2D", false, false).size() == 1, "Streaming duplicated art")
	game.queue_free()
	await process_frame
