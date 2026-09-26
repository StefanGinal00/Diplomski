extends "res://tests/shaft_guard_combat_smoke.gd"

var art: Sprite2D
var attack_events := 0


func _performed(_weapon: String, _direction: Vector2) -> void:
	attack_events += 1


func _clear_attack() -> void:
	player.attack_cooldown_timer.stop()
	player.attack_visual_timer.stop()
	player._on_attack_visual_timer_timeout()
	art._process(0)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_attack_art_save.json"
	state.start_new_game("normal")
	player = _player()
	player.position = Vector2.ZERO
	player.get_node("Camera2D").enabled = false
	player.attack_performed.connect(_performed)
	art = player.get_node("Appearance")
	art.set_process(false)
	art._reset_motion()
	for weapon in ["worn_sword", "spiritglass_blade", "hunter_bow", "thorn_bow", "apprentice_staff", "sunder_staff"]:
		state.add_item(weapon)
		_check(state.equip_item(weapon, "primary_weapon"), "Cannot equip attack-art test weapon")
		var kind: String = state.get_item_definition(weapon).get("weapon_class", "sword")
		for side in [-1.0, 1.0]:
			for vertical in ([0.0] if kind == "sword" else [-1.0, 0.0, 1.0]):
				await _attack_case(kind, side, vertical)
	_clear_attack()
	state.equip_item("apprentice_staff", "primary_weapon")
	player.current_mana = 0
	var count_before := attack_events
	_check(not player.try_attack(), "Empty mana unexpectedly casts")
	art._process(0)
	_check(attack_events == count_before and art.attack_class.is_empty(), "Rejected cast animates")
	player.current_mana = player.max_mana
	var spell_scene: PackedScene = player.magic_projectile_scene
	player.magic_projectile_scene = null
	_check(not player.try_attack() and attack_events == count_before, "Missing spell resource emits attack")
	player.magic_projectile_scene = spell_scene
	state.equip_item("hunter_bow", "primary_weapon")
	var arrow_scene: PackedScene = player.arrow_scene
	player.arrow_scene = null
	_check(not player.try_attack() and attack_events == count_before, "Missing arrow resource emits attack")
	player.arrow_scene = arrow_scene
	state.equip_item("worn_sword", "primary_weapon")
	_check(player.try_attack(), "Cancellation setup attack failed")
	var cooldown: float = player.attack_cooldown_timer.time_left
	state.equip_item("hunter_bow", "primary_weapon")
	art._process(0)
	_check(art.attack_class.is_empty() and art.current_pose != art.Pose.ATTACK and not player.attack_visual.visible, "Inventory equip leaves old sword pose/effect")
	_check(player.attack_cooldown_timer.time_left == cooldown and not player.try_attack(), "Equip cancellation bypasses cooldown")
	_clear_attack()
	_check(player.try_attack(), "Hidden setup attack failed")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.hide()
	player.show()
	art._process(0)
	_check(art.attack_class.is_empty() and art.current_pose != art.Pose.ATTACK, "Hidden player replays attack")
	player.process_mode = Node.PROCESS_MODE_INHERIT
	_clear_attack()
	_check(player.try_attack(), "Hurt setup attack failed")
	player.is_invulnerable = false
	player.take_damage(1)
	art._process(0)
	_check(art.attack_class.is_empty() and art.current_pose == art.Pose.HURT, "Hurt does not supersede attack")
	player.die()
	await process_frame
	player.respawn()
	player.set_physics_process(false)
	art._process(0)
	_check(art.attack_class.is_empty(), "Respawn retained attack snapshot")
	var pixels: Image = art.COMBAT_SHEET.get_image()
	_check(pixels.get_size() == Vector2i(1536, 1024), "Combat atlas dimensions changed")
	for point in [Vector2i(0, 0), Vector2i(512, 100), Vector2i(1024, 700), Vector2i(600, 20)]:
		_check(pixels.get_pixelv(point).a == 0, "Combat atlas contains background/cell bleed")
	for shot in get_nodes_in_group("player_projectile"):
		shot.queue_free()
	player.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("PLAYER ATTACK ART TEST PASSED: six weapons, real melee/projectile hits, both facings/diagonals, two phases, no fake attacks, cancellation and collision invariants")
		quit(0)
	else:
		quit(1)


func _attack_case(kind: String, side: float, vertical: float) -> void:
	_clear_attack()
	player.facing_direction = side
	player._update_attack_direction()
	player.current_mana = player.max_mana
	var direction := Vector2(side, vertical).normalized()
	if vertical != 0:
		Input.action_press("ui_up" if vertical < 0 else "ui_down")
	var target: StaticBody2D = load("res://RangedEnemy.tscn").instantiate()
	target.max_health = 30
	target.position = direction * (28 if kind == "sword" else 100)
	root.add_child(target)
	target.set_process(false)
	await physics_frame
	var body_before: Transform2D = player.player_collision.transform
	var cast_before: Transform2D = player.attack_cast.transform
	var cast_size: Vector2 = player.attack_cast.shape.size
	var count_before := attack_events
	_check(player.try_attack() and attack_events == count_before + 1, "Real attack did not emit exactly one event")
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	var cooldown: float = player.attack_cooldown_timer.time_left
	var duration: float = player.attack_visual_timer.time_left
	art._process(0)
	var column: int = ["sword", "bow", "staff"].find(kind)
	_check(art.texture == art.COMBAT_SHEET and art.frame == column and art.flip_h == (side < 0), "Initial attack pose/facing mismatch")
	_check(art.attack_class == kind and art.attack_direction.is_equal_approx(direction), "Successful attack snapshot mismatch")
	_check(player.attack_cooldown_timer.time_left == cooldown and player.attack_visual_timer.time_left == duration, "Art modified gameplay timers")
	_check(not player.try_attack() and attack_events == count_before + 1, "Cooldown rejection emits duplicate event")
	if kind != "sword":
		var shots := get_nodes_in_group("player_projectile")
		_check(not shots.is_empty(), "Real ranged attack did not spawn projectile")
		if not shots.is_empty():
			var shot: Area2D = shots.back()
			_check(shot.source == player and shot.direction.is_equal_approx(direction), "Sprite changed actual projectile direction/source")
	var follow_seen := false
	for tick in range(50):
		await physics_frame
		art._process(1.0 / 60.0)
		follow_seen = follow_seen or (art.texture == art.COMBAT_SHEET and art.frame == column + 3)
	_check(follow_seen and art.attack_class.is_empty() and art.current_pose != art.Pose.ATTACK, "Follow-through/timeout missing")
	_check(target.current_health < 30, "Presentation prevented real melee/projectile contact")
	_check(player.player_collision.transform == body_before and player.attack_cast.transform == cast_before and player.attack_cast.shape.size == cast_size, "Art modified collision/reach")
	target.queue_free()
	for shot in get_nodes_in_group("player_projectile"):
		shot.queue_free()
	await process_frame
