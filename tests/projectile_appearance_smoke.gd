extends "res://tests/shaft_guard_combat_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_projectile_appearance_save.json"
	state.start_new_game("normal")
	var variants := [
		[false, "basic_arrow", "hunter_bow", "arrow"],
		[false, "basic_arrow", "thorn_bow", "thorn"],
		[false, "ember_arrow", "hunter_bow", "ember"],
		[true, "arc_bolt", "apprentice_staff", "arc"],
		[true, "arc_bolt", "sunder_staff", "arc"],
		[true, "frost_orb", "apprentice_staff", "frost"],
	]
	for variant in variants:
		for aim in [Vector2.RIGHT, Vector2.LEFT, Vector2(1, -1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var shot: Node2D = load("res://PlayerMagicProjectile.tscn" if variant[0] else "res://PlayerArrow.tscn").instantiate()
			root.add_child(shot)
			shot.set_physics_process(false)
			if variant[0]:
				shot.setup(aim, null, variant[1], 2, variant[2], 3, 600.0)
			else:
				shot.setup(aim, null, variant[1], 2, 1, variant[2], 3, 600.0)
			var art := shot.get_node("Appearance")
			art.set_process(false)
			var transform_before := shot.transform
			var collider := shot.get_node("CollisionShape2D")
			var shape_rid: RID = collider.shape.get_rid()
			var collider_transform: Transform2D = collider.transform
			var lifetime: float = shot.lifetime
			var speed: float = shot.speed
			var damage: int = shot.damage
			var hits: int = shot.remaining_hits
			for tick in range(40):
				art._process(0.016)
			_check(art.active and art.style == variant[3], "Wrong projectile style: " + variant[2])
			var tint: Color = shot.get_node("Core" if variant[0] else "Head").color
			_check(art.core_color == tint, "Projectile loses weapon/spell tint")
			_check(shot.transform == transform_before and collider.transform == collider_transform and collider.shape.get_rid() == shape_rid, "Art changes projectile transform/collision")
			_check(shot.lifetime == lifetime and shot.speed == speed and shot.damage == damage and shot.remaining_hits == hits and shot.pending_hits == 0, "Art changes projectile combat state")
			_check(shot.transform.x.normalized().is_equal_approx(aim.normalized()), "Art axis does not follow shot aim")
			_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Art adds collision")
			for legacy in (["Core", "Aura"] if variant[0] else ["Head", "Trail"]):
				_check(shot.get_node(legacy).self_modulate.a == 0, "Duplicate legacy drawing")
			_check(damage == (4 if variant[1] == "frost_orb" else (6 if variant[1] == "ember_arrow" else 5)), "Unexpected base damage")
			var expected_speed: float = (230.0 if variant[1] == "frost_orb" else 345.0) if variant[0] else (470.0 if variant[1] == "ember_arrow" else 430.0)
			var capped_range := 380.0 if variant[0] else 420.0
			_check(speed == expected_speed and is_equal_approx(lifetime, capped_range / speed), "Appearance changed speed or the bounded projectile range")
			_check(hits == (1 if variant[1] in ["ember_arrow", "arc_bolt"] else 2), "Piercing budget changed")
			_check(shot.scale.is_equal_approx(Vector2.ONE * (1.25 if variant[1] == "frost_orb" else 1.0)), "Spell collision scale changed")
			shot._physics_process(0.05)
			_check(shot.position.is_equal_approx(aim.normalized() * speed * 0.05), "Trajectory changed")
			_check(is_equal_approx(shot.lifetime, lifetime - 0.05), "Lifetime no longer decreases")
			shot.process_mode = Node.PROCESS_MODE_DISABLED
			shot.hide()
			_check(not art.active and art.phase == 0 and art.redraw_clock == 0, "Disabled hidden shot retains effects")
			shot.show()
			art._process(0)
			_check(not art.active and shot.lifecycle_retired and shot.is_queued_for_deletion(), "Hidden projectile revived after retirement")
			shot.stopped = true
			art._process(0)
			_check(not art.active, "Stopped projectile retains effects")
			shot.stopped = false
			art._process(0)
			shot.queue_free()
			art._process(0)
			_check(not art.active, "Queued projectile retains effects")
			await process_frame
	state.delete_save()
	if failures.is_empty():
		print("PROJECTILE APPEARANCE TEST PASSED: six variants, six directions, tints, movement, range, damage, piercing, collision invariants and hidden/stopped/deletion reset")
		quit(0)
	else:
		quit(1)
