extends "res://tests/shaft_mixed_combat_smoke.gd"

# Reuse the same isolated live-AI battles, but steer normal horizontal/diagonal
# player shots. No direct hit callbacks, mana refill, or altered cooldowns.
var loadout := ""
var spent_mana := 0
var spent_arrows := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_ranged_combat_save.json"
	node_added.connect(_on_test_node_added)
	for variant in ["basic_arrow", "ember_arrow", "arc_bolt", "frost_orb"]:
		loadout = variant
		for return_trial in [false, true]:
			for scene_name in ROOMS:
				state.start_new_game("normal")
				var weapon := "hunter_bow" if variant.ends_with("arrow") else "apprentice_staff"
				state.add_item(weapon)
				_check(state.equip_item(weapon) and state.cycle_weapon(), "Ranged loadout failed")
				if weapon == "hunter_bow":
					state.add_item("ember_arrow", 100)
					state.selected_arrow_type = variant
				else:
					state.unlock_spell(variant)
					state.selected_spell = variant
				state.set_zone_tier("sunken_shaft", 1 if return_trial else 0)
				var failures_before := failures.size()
				await _battle(scene_name, 1 if return_trial else 0, return_trial)
				if failures.size() != failures_before:
					print("RANGED FAILURE LOADOUT: ", variant)
				Input.action_release("ui_up")
				Input.action_release("ui_down")
	_check(spent_mana > 0 and spent_arrows > 0, "No resource use exercised")
	state.delete_save()
	if failures.is_empty():
		print("SHAFT RANGED COMBAT TEST PASSED: ", battles, " live encounters, ", attacks, " shots, ", spent_mana, " mana, ", spent_arrows, " special arrows spent")
		quit(0)
	else:
		print("SHAFT RANGED COMBAT TEST FAILED: ", failures.size())
		quit(1)


func _drive_attack(target: Node2D, floor_node: Node2D) -> void:
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	var offset := target.global_position - player.global_position
	# Close to a useful firing angle without walking off the high niche.
	var side := signf(offset.x)
	var spacing := clampf(absf(offset.y + 3), 28, 95) if absf(offset.y + 3) > 20 else 65.0
	var desired_x := clampf(target.global_position.x - side * spacing, floor_node.global_position.x - 85, floor_node.global_position.x + 85)
	var dx := desired_x - player.global_position.x
	if absf(dx) > 22:
		Input.action_press("ui_right" if dx > 0 else "ui_left")
	elif side != player.facing_direction:
		Input.action_press("ui_right" if side > 0 else "ui_left")
	var speed := 230.0 if loadout == "frost_orb" else (345.0 if loadout == "arc_bolt" else 430.0)
	var aim_offset := offset
	if target is CharacterBody2D:
		aim_offset += target.velocity * (offset.length() / speed)
	var horizontal := absf(aim_offset.y + 3) < 18
	var diagonal := absf(absf(aim_offset.y + 3) - absf(aim_offset.x)) < 18
	if not horizontal and diagonal:
		Input.action_press("ui_up" if offset.y < 0 else "ui_down")
	# Do not waste regenerating mana repeatedly shooting the underside of a
	# plank. Change height only when needed, not after every small hover motion.
	var sight := PhysicsRayQueryParameters2D.create(player.global_position + Vector2(0, -3), target.global_position, 1, [player.get_rid()])
	var obstruction := player.get_world_2d().direct_space_state.intersect_ray(sight)
	var blocked: bool = not obstruction.is_empty() and not obstruction.collider.is_in_group("enemy")
	if offset.y < -35 and (blocked or offset.y < -95) and absf(offset.x) < 150 and player.is_on_floor():
		player._try_jump()
	if blocked or side != player.facing_direction or not (horizontal or diagonal):
		return
	var state := root.get_node("GameState")
	var mana_before := player.current_mana
	var ammo_before: int = state.inventory.get("ember_arrow", 0)
	if player.try_attack():
		attacks += 1
		var mana_cost := 2 if loadout == "frost_orb" else (1 if loadout == "arc_bolt" else 0)
		_check(player.current_mana == mana_before - mana_cost, "Incorrect mana charge for " + loadout)
		var ammo_cost := 1 if loadout == "ember_arrow" else 0
		_check(int(state.inventory.get("ember_arrow", 0)) == ammo_before - ammo_cost, "Incorrect arrow charge for " + loadout)
		spent_mana += mana_cost
		spent_arrows += ammo_cost
	else:
		_check(player.current_mana == mana_before and int(state.inventory.get("ember_arrow", 0)) == ammo_before, "Rejected attack consumed resources for " + loadout)
