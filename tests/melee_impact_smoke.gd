extends "res://tests/shaft_guard_combat_smoke.gd"

const Impact = preload("res://ProjectileImpact.gd")
var contacts := 0

class Target extends StaticBody2D:
	var damage_received := 0
	var hits := 0
	var force := Vector2.ZERO
	var invulnerable := false
	var delete_on_hit := false
	func take_damage(amount: int, knockback: Vector2) -> void:
		hits += 1
		force = knockback
		if not invulnerable:
			damage_received += amount
		if delete_on_hit:
			queue_free()


func _target(at: Vector2, group_name: String, size := Vector2(8, 16)) -> Target:
	var target := Target.new()
	target.position = at
	if not group_name.is_empty():
		target.add_to_group(group_name)
	for index in range(2):
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = size
		collider.shape = shape
		collider.position.x = index
		target.add_child(collider)
	root.add_child(target)
	return target


func _clear_effects() -> void:
	for effect in get_nodes_in_group(Impact.GROUP):
		effect.queue_free()
	await process_frame


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_melee_impact_save.json"
	state.start_new_game("normal")
	player = _player()
	player.position = Vector2(300, 100)
	player.get_node("Camera2D").enabled = false
	player.melee_contacted.connect(func(_point: Vector2, _kind: String, _aim: Vector2, _item: String): contacts += 1)
	for item in ["worn_sword", "spiritglass_blade"]:
		state.add_item(item)
		state.equip_item(item, "primary_weapon")
		for side in [-1.0, 1.0]:
			for crouch in [false, true]:
				for extended in [false, true]:
					player.facing_direction = side
					player.sword_reach_unlocked = extended
					player._set_crouching(crouch)
					player._update_attack_direction()
					for group_name in ["enemy", "neutral_creature", "breakable"]:
						var target := _target(player.attack_cast.global_position, group_name)
						await physics_frame
						var cast_transform := player.attack_cast.transform
						var shape_size: Vector2 = player.attack_cast.shape.size
						var body_shape: RID = player.player_collision.shape.get_rid()
						var before := contacts
						player.attack_cooldown_timer.stop()
						_check(player.try_attack(), "Melee setup attack rejected")
						_check(contacts == before + 1 and target.hits == 1, "Multiple target colliders duplicate hit/impact")
						var expected_damage: int = state.get_item_definition(item).get("damage", 1)
						_check(target.damage_received == expected_damage and target.force.x * side > 0, "Impact changes melee damage/knockback")
						var effects := get_nodes_in_group(Impact.GROUP)
						_check(effects.size() == 1, "Melee contact has missing/extra effects")
						if effects.size() == 1:
							var effect: Node2D = effects[0]
							_check(effect.global_position.is_equal_approx(target.global_position), "Contact effect misplaced")
							_check(effect.global_transform.x.normalized().is_equal_approx(Vector2(side, 0)), "Contact effect not mirrored")
							_check(effect.style == ("spirit_slash" if item == "spiritglass_blade" else "slash") and effect.tint == player.attack_visual.color, "Wrong sword identity/tint")
							_check(effect.contact_kind == ("breakable" if group_name == "breakable" else "actor"), "Wrong contact kind")
						_check(player.attack_cast.transform == cast_transform and player.attack_cast.shape.size == shape_size and player.player_collision.shape.get_rid() == body_shape, "Melee art changes collision")
						var cooldown := player.attack_cooldown_timer.time_left
						_check(not player.try_attack() and contacts == before + 1 and player.attack_cooldown_timer.time_left == cooldown, "Cooldown rejection creates contact or resets timer")
						target.queue_free()
						await _clear_effects()
	# Large targets overlap the sword even though their origin is outside it.
	player.sword_reach_unlocked = false
	player.facing_direction = 1
	player._set_crouching(false)
	player._update_attack_direction()
	var large := _target(player.position + Vector2(85, 0), "enemy", Vector2(100, 16))
	await physics_frame
	player.attack_cooldown_timer.stop()
	_check(player.try_attack() and large.hits == 1, "Large target setup failed")
	var effects := get_nodes_in_group(Impact.GROUP)
	_check(effects.size() == 1, "Large target effect missing")
	if effects.size() == 1:
		var expected := player.attack_cast.to_global(Vector2(player.attack_cast.shape.size.x * 0.5, 0))
		_check(effects[0].global_position.is_equal_approx(expected), "Effect escapes sword reach toward large target origin")
	large.queue_free()
	await _clear_effects()
	for mode in ["invulnerable", "deleted", "saturated", "ignored"]:
		var target := _target(player.attack_cast.global_position, "" if mode == "ignored" else "enemy")
		target.invulnerable = mode == "invulnerable"
		target.delete_on_hit = mode == "deleted"
		await physics_frame
		if mode == "saturated":
			for index in range(Impact.MAX_ACTIVE):
				Impact.spawn(player, Vector2.ZERO, Vector2.RIGHT, "arc", Color.WHITE, "actor")
		player.attack_cooldown_timer.stop()
		_check(player.try_attack(), "Special melee setup failed")
		effects = get_nodes_in_group(Impact.GROUP)
		_check(effects.size() == (Impact.MAX_ACTIVE if mode == "saturated" else (0 if mode == "ignored" else 1)), "Special contact effect count wrong: " + mode)
		if mode == "deleted":
			_check(target.is_queued_for_deletion(), "Lethal target cleanup setup failed")
		elif mode in ["ignored", "invulnerable"]:
			_check(target.damage_received == 0, "Visual feedback bypasses target immunity/filter")
		else:
			_check(target.damage_received > 0, "Visual cap suppresses melee damage")
		if is_instance_valid(target):
			target.queue_free()
		await _clear_effects()
	var before := contacts
	player.attack_cooldown_timer.stop()
	_check(player.try_attack() and contacts == before and get_nodes_in_group(Impact.GROUP).is_empty(), "Empty swing creates a fake contact")
	player.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("MELEE IMPACT TEST PASSED: 48 sword/facing/crouch/reach/group cases, actual ShapeCast, dedup, cooldown, large target, immunity, deletion, cap and empty swing")
		quit(0)
	else:
		quit(1)
