extends "res://tests/shaft_hollow_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_projectile_sweep_save.json"
	state.start_new_game("normal")
	for kind in ["PlayerArrow", "PlayerMagicProjectile", "EnemyProjectile"]:
		for aim in [Vector2.RIGHT, Vector2.LEFT, Vector2(1, -0.4).normalized()]:
			var holder := Node2D.new()
			root.add_child(holder)
			holder.position.y = -4500
			var wall := StaticBody2D.new()
			wall.position = aim * 55
			var collider := CollisionShape2D.new()
			collider.shape = RectangleShape2D.new()
			collider.shape.size = Vector2(1, 50)
			wall.add_child(collider)
			holder.add_child(wall)
			# Non-solid interaction/pickup volumes must not intercept player shots.
			var trigger:=Area2D.new()
			trigger.position=aim*25
			var trigger_shape:=CollisionShape2D.new()
			trigger_shape.shape=RectangleShape2D.new();trigger_shape.shape.size=Vector2(12,55)
			trigger.add_child(trigger_shape);holder.add_child(trigger)
			var shot: Area2D = load("res://%s.tscn" % kind).instantiate()
			holder.add_child(shot)
			shot.set_physics_process(false)
			if kind == "PlayerMagicProjectile": shot.setup(aim, null, "arc_bolt")
			else: shot.setup(aim, null)
			shot.speed = 1200
			await physics_frame
			await physics_frame
			shot._physics_process(0.12)
			_check(shot.is_queued_for_deletion(), kind + " passed through 1px cover")
			_check(shot.position.distance_to(aim * 55) < 2, kind + " impact is not at the first wall")
			holder.queue_free()
			await process_frame
	for kind in ["PlayerArrow", "PlayerMagicProjectile", "EnemyProjectile"]:
		var shot: Area2D = load("res://%s.tscn" % kind).instantiate()
		root.add_child(shot)
		shot.position = Vector2(0, -5000)
		shot.set_physics_process(false)
		if kind == "PlayerMagicProjectile": shot.setup(Vector2.RIGHT, null, "arc_bolt")
		else: shot.setup(Vector2.RIGHT, null)
		shot._physics_process(100)
		_check(shot.is_queued_for_deletion(), kind + " survives range exhaustion")
		_check(shot.position.x <= 400.01, kind + " exceeds camera-scale maximum")
		await process_frame
	state.delete_save()
	print("PROJECTILE SWEEP TEST ", "PASSED" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
