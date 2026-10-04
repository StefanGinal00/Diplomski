extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_attack_damage_range.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Node = game.get_node("Player")
	player.max_health = 100
	var boss := game.get_node("SentinelBoss")
	boss.target_player = player
	boss.locked_shot_direction = Vector2.LEFT
	for phase in [1, 2]:
		boss.phase = phase
		var previous := game.get_children()
		boss._fire_volley()
		var values: Array[int] = []
		for shot in game.get_children():
			if previous.has(shot) or shot.get_script() != preload("res://EnemyProjectile.gd"): continue
			_check(shot.max_range == 460, "Sentinel shot range wrong")
			player.current_health = 100
			player.is_invulnerable = false
			shot._on_body_entered(player)
			values.append(100 - player.current_health)
		_check(values == ([2] if phase == 1 else [1, 3, 1]), "Sentinel actual damage wrong: " + str(values))
		await process_frame
	state.add_item("guardian_band", 1)
	_check(state.equip_item("guardian_band", "defense"), "Could not equip defense fixture")
	for amount in [1, 2, 3]:
		player.current_health = 100
		player.is_invulnerable = false
		player.take_damage(amount)
		_check(100 - player.current_health == maxi(amount - 1, 1), "Defense no longer mitigates attacks correctly")
	state.unequip_defense()
	for scene_name in ["PlayerArrow", "PlayerMagicProjectile", "EnemyProjectile"]:
		var shot: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		game.add_child(shot)
		shot.position = Vector2(0, -4000)
		if scene_name == "PlayerArrow": shot.setup(Vector2.RIGHT, player, "basic_arrow", 0, 2, "hunter_bow", 1, 97.0)
		elif scene_name == "PlayerMagicProjectile": shot.setup(Vector2.RIGHT, player, "frost_orb", 0, "apprentice_staff", 2, 97.0)
		else:
			shot.setup(Vector2.RIGHT, boss)
			shot.max_range = 97
		shot.lifetime = 1000
		shot._physics_process(10)
		_check(is_equal_approx(shot.position.x, 97) and shot.is_queued_for_deletion(), scene_name + " exceeded finite range")
		await process_frame
	game.queue_free()
	await process_frame
	state.delete_save()
	print("ATTACK DAMAGE RANGE TEST PASSED" if failures.is_empty() else "TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
