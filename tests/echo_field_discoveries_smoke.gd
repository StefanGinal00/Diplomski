extends SceneTree

var failures: Array[String] = []
const CASES := [["echo_grotto", "EchoGrotto", [0, 1, 2]], ["echo_gallery", "EchoGallery", [1, 0]], ["echo_archive", "PrismArchive", [1, 0, 2]]]


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _world() -> Node:
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	return game


func _listen(post: Area2D, player: Player) -> void:
	for enemy in get_nodes_in_group("enemy"):
		if enemy is Node2D and enemy.has_method("die") and enemy.global_position.distance_to(post.global_position) < 175:
			enemy.die()
	player.set_physics_process(false)
	player.global_position = post.global_position
	post._on_body_entered(player)
	_check(post.begin_listening(), "Listening could not start at " + post.station_title)
	post._process(1.3)
	post._on_body_exited(player)


func _check_floor(node: Node2D, player: Player) -> void:
	var query := PhysicsRayQueryParameters2D.create(node.global_position + Vector2(0, 5), node.global_position + Vector2(0, 55), 1)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	var hit := node.get_world_2d().direct_space_state.intersect_ray(query)
	_check(not hit.is_empty() and hit.get("collider") is StaticBody2D, "Unsupported discovery interaction: " + String(node.get_path()))


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_field_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	_check(not game.has_node("EchoGrotto/LongTraversal/FieldDiscoveries"), "Unvisited Echo room loaded its discoveries eagerly")
	var player: Player = game.get_node("Player")
	player.max_health = 1000
	player.current_health = 1000
	state.set_current_room("echo_grotto")
	await physics_frame
	await process_frame
	var grotto = game.get_node("EchoGrotto/LongTraversal/FieldDiscoveries")
	var post = grotto.posts[0]
	player.set_physics_process(false)
	player.global_position = post.global_position
	post._on_body_entered(player)
	for enemy in get_nodes_in_group("enemy"):
		if enemy is Node2D and enemy.has_method("die") and enemy.global_position.distance_to(post.global_position) < 175:
			enemy.die()
	_check(post.begin_listening(), "First listening channel did not start")
	player.global_position += Vector2(100, 0)
	post._process(1.3)
	_check(not post.listening and grotto.sequence.is_empty(), "Walking away completed a record")
	player.global_position = post.global_position
	post.begin_listening()
	player.current_health -= 1
	post._process(1.3)
	_check(not post.listening and grotto.sequence.is_empty(), "Damage did not interrupt listening")
	post.begin_listening()
	var threat := load("res://ShaftWisp.tscn").instantiate() as Node2D
	threat.position = game.get_node("EchoGrotto").to_local(post.global_position)
	game.get_node("EchoGrotto").add_child(threat)
	post._process(1.3)
	_check(not post.listening and grotto.sequence.is_empty() and not post.begin_listening(), "Nearby enemy did not interrupt and block listening")
	threat.set_physics_process(false)
	for example in [[Vector2(0, 115), "BELOW"], [Vector2(0, -115), "ABOVE"], [Vector2(-100, 0), "LEFT"], [Vector2(100, 0), "RIGHT"], [Vector2.ZERO, "NEARBY"]]:
		threat.global_position = post.global_position + example[0]
		post._refresh()
		_check(example[1] in post.prompt.text and not post.begin_listening(), "Listening threat direction/blocking mismatch: " + example[1])
	threat.global_position = post.global_position + Vector2(200, 0)
	post._refresh()
	_check(not post._has_threat() and "STAY CLOSE" in post.prompt.text, "Out-of-range foe left a stale listening warning")
	threat.die()
	post.begin_listening()
	state.set_current_room("training_passage")
	_check(not post.listening and post.nearby_player == null, "Room transition did not cancel listening")
	state.set_current_room("echo_grotto")
	_listen(grotto.posts[0], player)
	_listen(grotto.posts[2], player)
	_check(grotto.sequence.is_empty() and "WRONG ORDER" in grotto.signs[0].text, "Wrong choir tone did not reset the unfinished sequence")
	_listen(grotto.posts[0], player)
	_check(not game.get_node("EchoGrotto/LongTraversal/RouteDiscoveryCache").open(player), "Partial choir sequence unsealed discovery cache")
	state.set_current_room("echo_gallery")
	await process_frame
	var gallery = game.get_node("EchoGallery/LongTraversal/FieldDiscoveries")
	_listen(gallery.posts[1], player)
	_check(not gallery.completed and gallery.posts[1].attuned, "Gallery witness did not record independently")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "field_test", "Field Test", "echo_gallery"), "Could not save partial witness progress")
	# Completing the remaining records and rewards without saving must roll back.
	for entry in CASES:
		state.set_current_room(entry[0])
		await physics_frame
		await process_frame
		var route = game.get_node(entry[1] + "/LongTraversal")
		var fields = route.get_node("FieldDiscoveries")
		for station in fields.posts:
			_check_floor(station, player)
		_check_floor(fields.get_node("ReturnReward"), player)
		for index in entry[2]:
			if not fields.posts[index].attuned:
				_listen(fields.posts[index], player)
		_check(fields.completed and route.get_node("RouteDiscoveryCache").open(player) and not route.get_node("RouteDiscoveryCache").open(player), "Discovery reward did not unlock exactly once in " + entry[1])
		fields.get_node("ReturnEncounter")._on_body_entered(player)
		_check(not fields.get_node("ReturnEncounter").triggered and "MATRIARCH" in fields.get_node("ReturnEncounter").status_label.text, "Echo return trial activated early or names the wrong boss")
	state.set_zone_tier("echo_grotto", 1)
	for entry in CASES:
		state.set_current_room(entry[0])
		await process_frame
		var fields = game.get_node(entry[1] + "/LongTraversal/FieldDiscoveries")
		var trial = fields.get_node("ReturnEncounter")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Awakened Echo encounter did not spawn")
		trial.spawned_enemies[0].die()
		_check(not fields.get_node("ReturnReward").open(player), "One enemy released both-guardian reward")
		trial.spawned_enemies[1].die()
		_check(fields.get_node("ReturnReward").open(player) and not fields.get_node("ReturnReward").open(player), "Awakened Echo reserve did not pay exactly once")
	state.set_current_room("echo_haven")
	await process_frame
	var board = game.get_node("EchoHaven/NewDistricts/DiscoveryBoard")
	_check("RECORDS 3/8" in board.board.text and "RETURN ECHOES 3/8" in board.board.text, "Haven board did not show discoveries and return victories")
	_check(board.curator.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Record keeper dialogue is not connected")
	for enemy in get_nodes_in_group("enemy"):
		_check(not game.get_node("EchoHaven").is_ancestor_of(enemy), "Haven field records introduced a hostile in town")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial field snapshot could not load")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	gallery = game.get_node("EchoGallery/LongTraversal/FieldDiscoveries")
	_check(gallery.posts[1].attuned and not gallery.posts[0].attuned and not gallery.completed, "Gallery partial witness progress did not restore exactly")
	_check(not gallery.get_node("ReturnReward").opened and not gallery.get_node("ReturnEncounter").completed, "Unsaved return reward or victory survived rollback")
	state.set_current_room("echo_grotto")
	await process_frame
	grotto = game.get_node("EchoGrotto/LongTraversal/FieldDiscoveries")
	_check(grotto.sequence.is_empty() and not grotto.completed and not grotto.posts[0].attuned, "Unfinished tone sequence survived loading")
	state.set_zone_tier("echo_grotto", 1)
	grotto.get_node("ReturnEncounter")._on_body_entered(player)
	_check(not grotto.get_node("ReturnEncounter").triggered, "Awakening bypassed missing room records")
	for index in [0, 1, 2]:
		_listen(grotto.posts[index], player)
	var trial = grotto.get_node("ReturnEncounter")
	trial._on_body_entered(player)
	await process_frame
	for enemy in trial.spawned_enemies:
		enemy.die()
	_check(grotto.get_node("ReturnReward").open(player), "Return reserve could not be re-earned after rollback")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "field_test", "Field Test", "echo_grotto"), "Completed field records could not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed field records could not reload")
	game = _world()
	await process_frame
	grotto = game.get_node("EchoGrotto/LongTraversal/FieldDiscoveries")
	trial = grotto.get_node("ReturnEncounter")
	trial._on_body_entered(game.get_node("Player"))
	await process_frame
	_check(grotto.completed and trial.completed and trial.spawned_enemies.is_empty() and grotto.get_node("ReturnReward").opened, "Saved field completion or reward reset")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("ECHO FIELD DISCOVERIES TEST PASSED")
		quit(0)
	else:
		print("ECHO FIELD DISCOVERIES TEST FAILED: ", failures)
		quit(1)
