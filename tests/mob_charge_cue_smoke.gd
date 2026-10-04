extends "res://tests/enemy_attack_art_smoke.gd"
const Charge = preload("res://MobChargeArt.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_mob_charge_cue.json"
	state.start_new_game("normal")
	for actor_name in ["ShaftSentry", "AshSentry"]:
		for tier in [0, 1]:
			for rate in [30, 60, 120]:
				var room := Node2D.new()
				room.process_mode = Node.PROCESS_MODE_DISABLED
				root.add_child(room)
				var actor: Node2D = load("res://%s.tscn" % actor_name).instantiate()
				state.set_zone_tier(actor.zone_id, tier)
				room.add_child(actor)
				var cue := actor.get_node("SentryAttackCue")
				var collision := actor.get_node("CollisionShape2D") as CollisionShape2D
				var shape := collision.shape.get_rid()
				var muzzle: Vector2 = actor.muzzle.position
				var duration: float = actor.windup_time
				var last := -1.0
				var frames: Array[int] = []
				for tick in range(ceili(duration * rate)):
					actor.windup_remaining = maxf(0.0001, duration - float(tick) / rate)
					actor.aim_direction = Vector2(-1, -0.4).normalized()
					var remaining: float = actor.windup_remaining
					cue._physics_process(1.0 / rate)
					_check(cue.charging and cue.progress >= last and cue.progress <= 1, "Charge reverses or disappears")
					frames.append(Charge.frame(cue.progress))
					last = cue.progress
					_check(actor.windup_remaining == remaining, "Presentation advances native countdown")
				_check(0 in frames and 1 in frames, "Missing one of two anticipation frames")
				_check(cue.material_index == (13 if actor_name == "AshSentry" else 16), "Wrong charge family")
				actor.windup_remaining = 0
				actor._fire()
				cue._physics_process(0)
				_check(not cue.charging and cue.progress == 0, "Charge overlaps successful release")
				_check(get_nodes_in_group("enemy_projectile").size() == (3 if tier == 1 else 1), "Charge changed native fan size")
				actor.windup_remaining = duration
				cue._physics_process(0)
				actor._cancel_windup()
				cue._physics_process(0)
				_check(not cue.charging and not actor.warning_ray.visible, "Cancelled charge persisted")
				actor.windup_remaining = duration * 0.25
				cue._physics_process(0)
				room.hide()
				_check(not cue.charging and cue.progress == 0, "Disabled hidden room retained charge")
				room.show()
				actor.projectile_scene = null
				cue._physics_process(0)
				_check(not cue.charging, "Missing projectile produces charge")
				_check(actor.muzzle.position == muzzle and collision.shape.get_rid() == shape, "Charge moved collision/muzzle")
				room.free()
	var room := Node2D.new()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	room.rotation = 0.4
	root.add_child(room)
	var ranged: Node2D = load("res://RangedEnemy.tscn").instantiate()
	room.add_child(ranged)
	var target := Node2D.new()
	room.add_child(target)
	ranged.target_player = target
	var cue := ranged.get_node("AttackCue")
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2(-1, -1).normalized(), Vector2(1, 1).normalized()]:
		target.global_position = ranged.muzzle.global_position + direction * 100
		ranged._physics_process(0)
		_check(ranged.has_clear_shot,"Ranged did not acquire unobstructed target")
		target.global_position = ranged.muzzle.global_position + direction * 100
		for progress in [0.0, 0.25, 0.6, 0.99]:
			ranged.shot_cooldown_remaining = 0.35 * (1.0 - progress)
			cue._process(0)
			_check(cue.pose == 1 and is_equal_approx(cue.charge_progress, progress), "Ranged charge disagrees with native countdown")
			_check(cue.charge_direction.is_equal_approx(direction), "Ranged charge lost world-space aim")
	target.position = Vector2(1000, 0)
	cue._process(0)
	_check(cue.pose == 0 and cue.charge_progress == 0, "Lost target left stale charge")
	target.global_position = ranged.muzzle.global_position + Vector2(80, 0)
	cue._process(0)
	room.hide()
	_check(cue.pose == 0 and cue.charge_progress == 0, "Ranged hidden charge not cleared")
	room.free()
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 12 sentry charge cycles, 30/60/120 FPS, two tiers, native release/fan/cancel, hidden cleanup and four ranged aim directions")
	quit(0 if failures.is_empty() else 1)
