extends "res://tests/boss_combat_presentation_smoke.gd"

func _return_trial(state: Node, game: Node) -> void:
	state.set_current_room("echo_nest")
	await process_frame
	var room := game.get_node("EchoNest")
	var player := game.get_node("Player")
	var trial: Node = load("res://LocalizedEncounter.tscn").instantiate()
	trial.encounter_id = "streaming_return_fixture"
	trial.completion_event_id = "streaming_return_fixture_cleared"
	trial.zone_id = "echo_grotto"
	trial.minimum_zone_tier = 1
	trial.required_boss_id = "echo_matriarch"
	trial.required_event_ids = PackedStringArray(["streaming_return_fixture_switch"])
	trial.enemy_health_bonus = 2
	trial.enemy_scenes.append(load("res://EchoBroodling.tscn"))
	trial.enemy_scenes.append(load("res://ShaftSentry.tscn"))
	room.add_child(trial)
	trial._on_body_entered(player)
	_check(not trial.triggered, "Return trial ignored tier/boss gating")
	state.set_zone_tier("echo_grotto", 1)
	trial._on_body_entered(player)
	_check(not trial.triggered, "Return trial ignored required boss")
	state.mark_boss_defeated("echo_matriarch")
	trial._on_body_entered(player)
	_check(not trial.triggered, "Return trial ignored required mechanism")
	state.unlock_shortcut("streaming_return_fixture_switch")
	player.is_dead = true
	trial._on_body_entered(player)
	_check(not trial.triggered, "Dead player started return encounter")
	player.is_dead = false
	trial._on_body_entered(player)
	await process_frame
	_check(trial.spawned_enemies.size() == 2, "Unlocked return encounter failed to spawn")
	if trial.spawned_enemies.size() != 2: return
	_check(not trial.spawned_enemies[0].counts_for_nest and not trial.spawned_enemies[0].is_in_group("nest_brood"), "Optional encounter changed Nest objective membership")
	trial.spawned_enemies[0].die()
	var sentry: Node = trial.spawned_enemies[1]
	sentry.take_damage(1)
	var hp: int = sentry.current_health
	var maximum: int = sentry.max_health
	var projectile: Node = load("res://EnemyProjectile.tscn").instantiate()
	room.add_child(projectile)
	projectile.setup(Vector2.RIGHT, sentry)
	var old_shot: WeakRef = weakref(projectile)
	state.set_current_room("training_passage")
	game.get_node("WorldPopulation").unload_room_population("EchoNest")
	await process_frame
	_check(old_shot.get_ref() == null, "Off-room encounter left a live projectile")
	state.set_current_room("echo_nest")
	await process_frame
	_check(trial.spawned_enemies.size() == 1, "Awakened return respawned slain Broodling")
	if trial.spawned_enemies.size() != 1: return
	sentry = trial.spawned_enemies[0]
	_check(sentry.current_health == hp and sentry.max_health == maximum, "Restored return enemy stacked/lost tier or bonus health")
	sentry.die()
	_check(trial.completed and state.unlocked_shortcuts.get(trial.completion_event_id, false), "Resumed return trial did not unlock its reward")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_encounter_streaming.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player := game.get_node("Player")
	var population := game.get_node("WorldPopulation")
	var starts: Array[String] = []
	var completions: Array[String] = []
	for spec in [["shaft_hollow", "ShaftHollow", "HiddenDepthAmbush"], ["ash_causeway", "BrokenCauseway", "GuardedNicheAmbush"], ["starfall_outskirts", "StarfallOutskirts", "HiddenStarAmbush"]]:
		state.set_current_room(spec[0])
		await process_frame
		var room := game.get_node(spec[1])
		var trial: Node = room.find_child(spec[2], true, false)
		_check(trial != null, "Missing authored ambush: " + spec[2])
		if trial == null: continue
		trial.encounter_started.connect(func(id: String): starts.append(id))
		trial.encounter_completed.connect(func(id: String): completions.append(id))
		trial._on_foe_defeated(999)
		_check(not trial.completed, "Untriggered/unknown kill completed an encounter")
		# No off-room trigger, and no late deferred spawn after crossing a door.
		state.set_current_room("training_passage")
		trial._on_body_entered(player)
		_check(not trial.triggered, "Off-room encounter accepted a trigger")
		state.set_current_room(spec[0])
		trial._on_body_entered(player)
		state.set_current_room("training_passage")
		await process_frame
		_check(not trial.triggered and trial.spawned_enemies.is_empty(), "Deferred ambush spawned after room exit")
		state.set_current_room(spec[0])
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Authored ambush did not spawn both foes")
		if trial.spawned_enemies.size() != 2: continue
		var first: Node = trial.spawned_enemies[0]
		var survivor: Node2D = trial.spawned_enemies[1]
		first.die()
		survivor.take_damage(1)
		var health: int = survivor.current_health
		var at: Vector2 = survivor.position + Vector2(17, -9)
		survivor.position = at
		_check(health > 0 and trial.remaining_foes.size() == 1, "Streaming survivor fixture invalid")
		trial._on_foe_defeated(0)
		_check(not trial.completed and trial.remaining_foes.size() == 1, "Duplicate defeat unsealed reward")
		var survivor_ref: WeakRef = weakref(survivor)
		var gold: int = state.gold
		var event_id: String = trial.completion_event_id
		state.set_current_room("training_passage")
		_check(population.pending_unloads.has(spec[1]), "Encounter room not scheduled for unloading")
		state.set_current_room(spec[0])
		_check(not population.pending_unloads.has(spec[1]) and survivor_ref.get_ref() == survivor and not trial.suspended, "Quick revisit failed to cancel unload grace")
		state.set_current_room("training_passage")
		# Exercise the manager's expiry path deterministically, without a 10s wait.
		population.pending_unloads[spec[1]] = 0
		population._process(0.0)
		await process_frame
		_check(survivor_ref.get_ref() == null and trial.spawned_enemies.is_empty() and trial.suspended, "Ambush foe remained loaded after room unload")
		_check(not trial.completed and not state.unlocked_shortcuts.get(event_id, false), "Unloading falsely completed combat")
		state.set_current_room(spec[0])
		await process_frame
		_check(trial.spawned_enemies.size() == 1 and not trial.suspended, "Revisit respawned dead foe or lost survivor")
		if trial.spawned_enemies.size() != 1: continue
		survivor = trial.spawned_enemies[0]
		_check(survivor.current_health == health and survivor.position == at, "Revisit reset enemy health/position")
		_check(starts.count(trial.encounter_id) == 1 and state.gold == gold, "Streaming replayed start/reward")
		# Repeated room activation cannot add another copy.
		trial.activate_room_population()
		trial.activate_room_population()
		_check(trial.spawned_enemies.size() == 1, "Repeated activation duplicated survivor")
		survivor.die()
		_check(trial.completed and bool(state.unlocked_shortcuts.get(event_id, false)), "Resumed victory failed to unlock reward")
		trial._on_foe_defeated(1)
		_check(completions.count(trial.encounter_id) == 1, "Resumed encounter paid completion twice")
		state.set_current_room("training_passage")
		population.unload_room_population(spec[1])
		await process_frame
		state.set_current_room(spec[0])
		await process_frame
		_check(trial.completed and trial.live_foes.is_empty(), "Completed ambush respawned on return")
	await _return_trial(state, game)
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ENCOUNTER STREAMING TEST PASSED: three authored ambushes plus gated return trial, lazy/deferred room guards, unload, survivor state, tier health, Nest exclusion, projectile cleanup and reward authority")
		quit(0)
	else: quit(1)
