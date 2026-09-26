extends "res://tests/shaft_guard_combat_smoke.gd"

# Physical overlap stress test: one real player shot enters three targets in
# the same physics tick. Single-hit shots must not accidentally pierce them.
func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_projectile_hit_budget_save.json"
	for case_index in range(20):
		var variant: String = ["basic_arrow", "ember_arrow", "piercing_arrow", "arc_bolt", "frost_orb"][case_index % 5]
		var layout: String = ["overlap", "line", "rear_cover", "front_cover"][case_index / 5]
		state.start_new_game("normal")
		var weapon := "hunter_bow" if variant.ends_with("arrow") else "apprentice_staff"
		state.add_item(weapon)
		state.equip_item(weapon)
		state.cycle_weapon()
		state.add_item("ember_arrow", 2)
		state.selected_arrow_type = "ember_arrow" if variant == "ember_arrow" else "basic_arrow"
		if weapon == "apprentice_staff":
			state.unlock_spell(variant)
			state.selected_spell = variant
		player = _player()
		player.global_position = Vector2(-100, 0)
		player.facing_direction = 1
		player.bow_piercing_unlocked = variant == "piercing_arrow"
		var foes: Array[Node] = []
		for index in range(3):
			var foe := load("res://ShaftSentry.tscn").instantiate() as StaticBody2D
			foe.max_health = 20
			foe.position = Vector2(0 if layout == "overlap" else index * 60, -3)
			root.add_child(foe)
			foe.set_physics_process(false)
			foes.append(foe)
		var wall: StaticBody2D
		if layout.ends_with("cover"):
			wall = StaticBody2D.new()
			wall.position = Vector2(-45 if layout == "front_cover" else 35, 0)
			var collision := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2(12, 100)
			collision.shape = shape
			wall.add_child(collision)
			root.add_child(wall)
		_check(player.try_attack(), variant + ": could not launch real shot")
		for frame in range(90):
			await physics_frame
		var damaged := 0
		var total_damage := 0
		for foe in foes:
			if foe.current_health < 20:
				damaged += 1
			total_damage += 20 - int(foe.current_health)
			foe.queue_free()
		var budget := 2 if variant in ["piercing_arrow", "frost_orb"] else 1
		if layout == "front_cover":
			budget = 0
		elif layout == "rear_cover":
			budget = 1
		var damage_per_hit := 2 if variant in ["ember_arrow", "arc_bolt"] else 1
		_check(damaged == budget and total_damage == budget * damage_per_hit, "%s / %s: hit %d targets for %d damage; expected %d targets for %d" % [variant, layout, damaged, total_damage, budget, budget * damage_per_hit])
		if wall != null:
			wall.queue_free()
		for projectile in get_nodes_in_group("player_projectile"):
			projectile.queue_free()
		player.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("PROJECTILE HIT BUDGET TEST PASSED: 20 real shots, overlapping/separated targets and cover before/after first hit")
		quit(0)
	else:
		print("PROJECTILE HIT BUDGET TEST FAILED: ", failures.size())
		quit(1)
