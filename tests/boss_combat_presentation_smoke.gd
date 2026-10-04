extends SceneTree

const CASES := [
	["Boss", "training_passage", "volley"],
	["AbyssWarden", "sunken_shaft", "volley"],
	["EchoMatriarch", "echo_sanctum", "ring"],
	["AshCastellan", "ash_throne", "eruption"],
	["StarfallGuardian", "starfall_empty_court", "pulse"],
	["HollowSovereign", "starfall_hollow_throne", "nova"],
	["EmberMarshal", "ash_arena", "volley"],
]
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_combat_presentation.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for path in ["TrainingPassageDecor/SentinelRelics", "VerticalChamber/ArenaRelics", "ResonanceSanctum/ArenaRelics", "CastellanThrone/ArenaRelics", "AshArena/ArenaRelics", "StarfallEmptyCourt/ArenaRelics", "StarfallHollowThrone/ArenaRelics"]:
		var relic := game.get_node(path)
		_check(relic.points.size() == 2 and relic.ATLAS.get_image().has_mipmaps(), path + ": missing persistent painted arena landmarks")
		_check(relic.get_child_count() == 0 and relic.z_index == -1, path + ": decorative relic unexpectedly owns gameplay nodes")
	var player: Player = game.get_node("Player")
	player.reparent(root)
	player.set_physics_process(false)
	player.set_process(false)
	for data in CASES:
		state.current_room_id = data[1]
		var room := Node2D.new()
		root.add_child(room)
		player.reparent(room)
		player.position = Vector2(200, 0)
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		room.add_child(boss)
		boss.set_physics_process(false)
		boss.target_player = player
		var art := boss.get_node("PaintedAppearance") as Sprite2D
		var effects := boss.get_node("CombatPresentation")
		if art.property_names.has("active"):
			boss.active = true
		_check(art.material is ShaderMaterial and effects.arena != null, data[0] + ": missing frame isolation / arena")
		_check(art.texture.get_image().has_mipmaps(), data[0] + ": missing mipmaps")
		var health: int = boss.current_health
		var collider := boss.get_node("CollisionShape2D") as CollisionShape2D
		var original_shape := collider.shape
		if art.property_names.has("charge_remaining"):
			boss.charge_direction = -1.0
			boss.charge_remaining = 0.4
			effects._process(0.07)
			art._process(0.07)
			_check(art.pose_index == 2 and art.frame == 9 and art.flip_h, data[0] + ": charge must use strike frame and committed facing")
			_check(effects.ghosts.size() == 1, data[0] + ": no bounded dash afterimage")
			for tick in range(10):
				effects._process(0.07)
			_check(effects.ghosts.size() <= 4, data[0] + ": dash effects unbounded")
			boss.charge_remaining = 0.0
			boss.recovery_remaining = 0.5
			effects._process(0.01)
			art._process(0.01)
			_check(art.pose_index == 3 and art.frame in [10, 11], data[0] + ": recovery did not use recovery frames")
			boss.recovery_remaining = 0.0
		if art.property_names.has("facing_direction"):
			boss.facing_direction = 1
		art._apply_pose(0)
		var right_offset := art.offset.x
		player.position.x = -200
		if art.property_names.has("facing_direction"):
			boss.facing_direction = -1
		art._apply_pose(0)
		_check(is_equal_approx(art.offset.x, -right_offset), data[0] + ": facing changes pivot registration")
		var before := get_nodes_in_group("boss_cosmetic_effect").size()
		match data[0]:
			"EchoMatriarch": boss._fire_ring()
			"AshCastellan":
				boss._start_eruption()
				_check(boss.get_node("EruptionMiddle/AnimatedWarning").is_visible_in_tree(), "Eruption warning must follow marker")
				boss._release_eruption()
			"StarfallGuardian":
				boss._start_pulse()
				boss._release_pulse()
			"HollowSovereign":
				for pattern in ["runes", "starfall", "nova", "soul_lock", "rift", "volley"]:
					boss._start_pattern(pattern)
					boss._release_pattern()
			_: boss._fire_volley()
		_check(effects.release_remaining > 0 and get_nodes_in_group("boss_cosmetic_effect").size() > before, data[0] + ": release has no synchronized effect")
		for projectile in get_nodes_in_group("enemy_projectile"):
			if projectile.source == boss:
				_check(projectile.has_node("BossProjectileArt") and not projectile.get_node("Core").visible, data[0] + ": bolt still uses placeholder art")
		for tick in range(8):
			art._process(0.016)
			_check(boss.current_health == health and collider.shape == original_shape, data[0] + ": visuals changed combat authority")
		boss.hide()
		effects._process(0.1)
		_check(effects.ghosts.is_empty(), data[0] + ": hidden encounter retained trail work")
		boss.show()
		boss.take_damage(999)
		await process_frame
		_check(not is_instance_valid(boss), data[0] + ": cosmetic death delayed gameplay cleanup")
		await create_timer(0.75).timeout
		_check(get_nodes_in_group("boss_cosmetic_effect").is_empty(), data[0] + ": burst lifetime leak")
		player.reparent(root)
		room.queue_free()
		await process_frame
	# Existing rematches must look awakened before the player accepts combat.
	for data in [["AbyssWarden", "abyss_warden"], ["EchoMatriarch", "echo_matriarch"], ["AshCastellan", "ash_castellan"]]:
		state.defeated_bosses[data[1]] = true
		state.boss_rematches.erase(data[1])
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		root.add_child(boss)
		boss.set_physics_process(false)
		_check(boss.is_rematch and not boss.active and boss.get_node("CombatPresentation").awakened, data[0] + ": rematch aura/consent broken")
		boss.queue_free()
		await process_frame
	state.set_zone_tier("ashen_bastion", 1)
	var marshal: CharacterBody2D = load("res://EmberMarshal.tscn").instantiate()
	root.add_child(marshal)
	marshal.set_physics_process(false)
	_check(marshal.is_rematch and marshal.get_node("CombatPresentation").awakened, "Higher-tier Marshal lacks awakened appearance")
	marshal.queue_free()
	player.queue_free()
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("BOSS COMBAT PRESENTATION TEST PASSED: seven actors, timing hooks, frame registration, hazards, trails, cleanup, rematch aura")
	quit(0 if failures.is_empty() else 1)
