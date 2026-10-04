extends "res://tests/enemy_attack_art_smoke.gd"
const MOB_SCENES := ["ShaftCrawler", "ShaftWisp", "EchoShade", "EchoBroodling", "RootStalker"]

func _phase(actor: Node, phase: int) -> void:
	if actor.get("phase") != null:
		actor.phase = ["patrol", "warning", "burst", "recovery"][phase]
	elif actor.has_method("_start_dash"):
		actor.telegraph_remaining = 0.5 if phase == 1 else 0.0
		actor.dash_remaining = 0.4 if phase == 2 else 0.0
		actor.recovery_remaining = 0.5 if phase == 3 else 0.0
	else:
		actor.state = phase

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_mob_followthrough.json"
	state.start_new_game("normal")
	for name in MOB_SCENES:
		for rate in [30, 60, 120]:
			var room := Node2D.new()
			room.process_mode = Node.PROCESS_MODE_DISABLED
			root.add_child(room)
			var actor: Node2D = load("res://%s.tscn" % name).instantiate()
			room.add_child(actor)
			var fx := actor.get_node("AttackPresentation")
			var collider := actor.get_node("CollisionShape2D") as CollisionShape2D
			var original := collider.transform
			var shape := collider.shape.get_rid()
			_phase(actor, 2)
			fx._physics_process(0)
			var heading: Vector2 = fx.heading
			var art := actor.get_node_or_null("Appearance")
			if art == null: art = actor.get_node("PaintedMobAppearance")
			art._process(0)
			var facing: bool = art.flip_h
			for tick in range(rate):
				fx._physics_process(1.0 / rate)
				_check(fx.attacking and not fx.recovering and fx.animation_frame < 4, name + ": live trail breaks up")
			_phase(actor, 3)
			fx._physics_process(0)
			_check(fx.recovering and not fx.attacking and fx.animation_frame == 4, name + ": missing recovery start")
			if name == "ShaftWisp": actor.dive_direction = -heading
			elif name == "EchoShade": actor.dash_direction = -heading.x
			elif name == "RootStalker": actor.facing = -heading.x
			else: actor.direction = -heading.x
			var frames: Array[int] = []
			for tick in range(ceili(0.18 * rate)):
				fx._physics_process(1.0 / rate)
				if fx.recovering:
					frames.append(fx.animation_frame)
					_check(fx.heading.is_equal_approx(heading), name + ": recovery direction flipped")
					if name == "EchoShade":
						art._process(1.0 / rate)
						_check(art.flip_h == facing, "Shade body flips during recovery")
			_check(5 in frames and not fx.recovering, name + ": missing final particles/expiry")
			# A follow-up warning must replace the old trail, not blend with it.
			_phase(actor, 2)
			fx._physics_process(0)
			_phase(actor, 1)
			fx._physics_process(0)
			_check(fx.preparing and not fx.recovering, name + ": old trail covers follow-up warning")
			_phase(actor, 0)
			fx._physics_process(0)
			_phase(actor, 3)
			fx._physics_process(0)
			_check(not fx.recovering, name + ": fake recovery without an attack")
			_phase(actor, 2)
			fx._physics_process(0)
			_phase(actor, 3)
			fx._physics_process(0)
			room.hide()
			_check(not fx.recovering and fx.animation_frame == 0, name + ": hidden recovery retained")
			_check(collider.transform == original and collider.shape.get_rid() == shape, name + ": collider changed")
			room.free()
	await _muzzles()
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: five mob follow-throughs at 30/60/120 FPS, committed headings, native phase precedence, hidden resets and 12 aimed native muzzle launches")
	quit(0 if failures.is_empty() else 1)

func _muzzles() -> void:
	for name in ["RangedEnemy", "ShaftSentry", "AshSentry"]:
		for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2(1, -1).normalized(), Vector2(-1, 1).normalized()]:
			var room := Node2D.new()
			room.process_mode = Node.PROCESS_MODE_DISABLED
			room.rotation = 0.31
			root.add_child(room)
			var actor: Node2D = load("res://%s.tscn" % name).instantiate()
			room.add_child(actor)
			var original: Vector2 = actor.muzzle.position
			var expected_frame := 7 if name == "RangedEnemy" else (13 if name == "AshSentry" else 16)
			if name == "RangedEnemy":
				var target := Node2D.new()
				room.add_child(target)
				target.global_position = actor.muzzle.global_position + direction * 100
				actor.target_player = target
				actor._shoot_at_player()
			else:
				actor.aim_direction = direction
				actor._fire()
			var effects := get_nodes_in_group("boss_cosmetic_effect")
			_check(effects.size() == 1, name + ": missing/duplicate muzzle")
			if effects.size() == 1:
				var burst := effects[0] as Node2D
				_check(Vector2.RIGHT.rotated(burst.global_rotation).is_equal_approx(direction), name + ": muzzle disagrees with world aim")
				_check(burst.global_position.is_equal_approx(actor.muzzle.global_position) and burst.texture_frame == expected_frame, name + ": wrong muzzle position/material")
				_check(is_equal_approx(burst.paint_rotation, PI * 0.5 if name == "AshSentry" else 0.0), name + ": flame atlas axis")
			var shots := get_nodes_in_group("enemy_projectile")
			_check(shots.size() == 1 and shots[0].direction.is_equal_approx(direction), name + ": native projectile changed")
			_check(actor.muzzle.position == original, name + ": presentation moved native muzzle")
			room.free()
