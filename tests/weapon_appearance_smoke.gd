extends "res://tests/shaft_guard_combat_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_weapon_appearance_save.json"
	state.start_new_game("normal")
	player = _player()
	player.position = Vector2.ZERO
	player.get_node("Camera2D").enabled = false
	var body := player.get_node("Appearance")
	var weapon := player.get_node("WeaponAppearance")
	body.set_process(false)
	weapon.set_process(false)
	body._reset_motion()
	var collision: RID = player.player_collision.shape.get_rid()
	var body_transform: Transform2D = player.player_collision.transform
	var grips := [Vector2(12.772, -5.81), Vector2(10.974, -8.476), Vector2(-2.046, -5.128), Vector2(12.028, -0.788), Vector2(10.85, -6.616), Vector2(-1.86, -1.904)]
	for item in ["worn_sword", "spiritglass_blade", "hunter_bow", "thorn_bow", "apprentice_staff", "sunder_staff"]:
		state.add_item(item)
		state.equip_item(item, "primary_weapon")
		var kind: String = state.get_item_definition(item).get("weapon_class", "sword")
		for side in [-1.0, 1.0]:
			player.facing_direction = side
			player._update_attack_direction()
			player.current_mana = player.max_mana
			player.attack_cooldown_timer.stop()
			player.attack_visual_timer.stop()
			if kind != "sword":
				Input.action_press("ui_up")
			_check(player.try_attack(), "Weapon-art setup attack failed")
			Input.action_release("ui_up")
			var cooldown: float = player.attack_cooldown_timer.time_left
			var cast_transform: Transform2D = player.attack_cast.transform
			var reach: float = player.attack_cast.shape.size.x
			for crouch in [false, true]:
				for finish in [false, true]:
					body._apply_attack_pose(kind, finish, side < 0, crouch)
					weapon._process(0)
					var expected: Vector2 = grips[body.frame]
					expected.x *= side
					if crouch:
						expected.y = 10 + (expected.y - 10) * 0.65
					_check(weapon.active and weapon.weapon_id == item and weapon.weapon_class == kind, "Wrong equipped weapon rendering")
					_check(weapon.hand.is_equal_approx(expected) and weapon.side == side, "Grip drifted from measured atlas hand")
					_check(weapon.direction.is_equal_approx(Vector2(side, -1 if kind != "sword" else 0).normalized()), "Weapon lost actual shot direction")
					_check(weapon.reach == reach and player.attack_cast.transform == cast_transform, "Weapon changed/recomputed collision reach")
					_check(player.attack_cooldown_timer.time_left == cooldown, "Weapon art changes cooldown")
			# Moving facing after release must not teleport this weapon across the body.
			var committed_hand: Vector2 = weapon.hand
			player.facing_direction = -side
			weapon._process(0)
			_check(weapon.hand == committed_hand and weapon.side == side, "Turning retargeted the released weapon")
			player.attack_visual_timer.stop()
			weapon._process(0)
			_check(not weapon.active, "Expired attack leaves a weapon effect")
			for projectile in get_nodes_in_group("player_projectile"):
				projectile.queue_free()
			await process_frame
	for prototype in [player.attack_visual, player.bow_visual, player.staff_visual]:
		_check(prototype.self_modulate.a == 0, "Legacy placeholder overlaps new weapon")
	_check(player.player_collision.shape.get_rid() == collision and player.player_collision.transform == body_transform, "Weapon presenter changed player collider")
	_check(weapon.find_children("*", "CollisionObject2D", true, false).is_empty(), "Weapon artwork introduced collision")
	player.attack_cooldown_timer.stop()
	player.current_mana = player.max_mana
	_check(player.try_attack(), "Hidden-weapon setup failed")
	body._process(0)
	weapon._process(0)
	_check(weapon.active, "Setup weapon invisible")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.hide()
	_check(not weapon.active, "Disabled hidden actor retains weapon art")
	player.show()
	body._process(0)
	weapon._process(0)
	_check(not weapon.active, "Room re-entry replays weapon art")
	player.queue_free()
	for projectile in get_nodes_in_group("player_projectile"):
		projectile.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("WEAPON APPEARANCE TEST PASSED: six variants, both facings, measured hand anchors, crouch, phases, aim, timeout/hidden reset and collision invariants")
		quit(0)
	else:
		quit(1)
