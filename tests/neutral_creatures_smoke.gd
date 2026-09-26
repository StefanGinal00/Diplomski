extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_neutral_creatures_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	# Authored Ash fauna now load on room entry, not when Game is created.
	state.set_current_room("ash_hearth_outskirts")
	await process_frame
	game.get_node("CinderHearthOutskirts").process_mode = Node.PROCESS_MODE_DISABLED
	var mossling = game.get_node("EchoHavenOutskirts/Mossling")
	var grazer = game.get_node("CinderHearthOutskirts/AshGrazer")
	var quests = game.get_node("QuestManager")

	_check(mossling.is_in_group("neutral_creature") and not mossling.is_in_group("enemy"), "Mossling is counted as an aggressive enemy")
	_check(grazer.is_in_group("neutral_creature") and not grazer.is_in_group("enemy"), "Ash Grazer is counted as an aggressive enemy")
	_check(not mossling.is_hostile and not grazer.is_hostile, "Neutral creature begins hostile")
	_check(not mossling._damage_player_if_possible(player) and not grazer._damage_player_if_possible(player), "Neutral creature dealt unprovoked contact damage")
	mossling._on_awareness_area_body_entered(player)
	_check(mossling.target_player == null, "Neutral creature aggroed on sight")
	_check(grazer.resting and grazer.sleep_label.visible, "Ash Grazer did not begin asleep")
	grazer._update_horizontal_movement()
	_check(is_zero_approx(grazer.velocity.x), "Sleeping creature moved")
	grazer.resting = false
	grazer._update_horizontal_movement()
	_check(absf(grazer.velocity.x) > 0.0, "Awake neutral creature cannot roam")

	var arrow = load("res://PlayerArrow.tscn").instantiate()
	game.add_child(arrow)
	arrow.source = player
	arrow.damage = 1
	arrow._on_body_entered(mossling)
	await process_frame
	_check(mossling.is_hostile and mossling.current_health == 2, "Attack did not wake and anger Mossling")
	_check(mossling.health_bar.visible and mossling.sleep_label.text == "!", "Hostile creature warning is missing")
	_check(not mossling._damage_player_if_possible(player), "Provoked creature attacked without a warning window")
	mossling._on_awareness_area_body_entered(player)
	_check(mossling.target_player == player, "Provoked creature does not pursue the player")
	var spell = load("res://PlayerMagicProjectile.tscn").instantiate()
	game.add_child(spell)
	spell.source = player
	spell._on_body_entered(grazer)
	await process_frame
	_check(grazer.is_hostile and grazer.current_health == 1, "Staff spell did not provoke the neutral Ash Grazer")
	var defeats_before: int = quests.defeated_enemies
	grazer.die()
	_check(quests.defeated_enemies == defeats_before, "Neutral creature kill advanced a mandatory enemy quest")

	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("NEUTRAL CREATURES TEST PASSED")
		quit(0)
	else:
		print("NEUTRAL CREATURES TEST FAILED: ", failures)
		quit(1)
