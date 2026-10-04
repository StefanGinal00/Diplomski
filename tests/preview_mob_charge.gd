extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_mob_charge_preview.json"
	state.start_new_game("normal")
	var host := Node2D.new()
	host.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(host)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(960, 0), Vector2(960, 540), Vector2(0, 540)])
	bg.color = Color("172b38")
	host.add_child(bg)
	_label(host, "RANGED ATTACKS / native muzzle, painted anticipation / enlarged 3x", Vector2(20, 18), 20)
	_label(host, "Early charge                         Late charge                            Native release", Vector2(74, 61), 18)
	var scenes := ["RangedEnemy", "ShaftSentry", "AshSentry"]
	for row in scenes.size():
		for column in range(3):
			var cell := Node2D.new()
			host.add_child(cell)
			cell.position = Vector2(155 + column * 310, 200 + row * 135)
			cell.scale = Vector2.ONE * 3
			var actor: Node2D = load("res://%s.tscn" % scenes[row]).instantiate()
			cell.add_child(actor)
			actor.get_node("HealthBar").hide()
			var target := Node2D.new()
			cell.add_child(target)
			var direction := Vector2(1, -0.25).normalized() if row != 1 else Vector2(-1, -0.25).normalized()
			target.global_position = actor.muzzle.global_position + direction * 100
			var progress := 0.15 if column == 0 else 0.8
			if row == 0:
				actor.target_player = target
				actor.muzzle.position.x = 13
				actor.shot_cooldown_remaining = 0.35 * (1.0 - progress)
				if column == 2: actor._shoot_at_player()
				actor.get_node("AttackCue")._process(0)
				actor.get_node("Appearance")._process(0)
			else:
				actor.aim_direction = direction
				actor.windup_remaining = actor.windup_time * (1.0 - progress)
				actor._update_warning_rays()
				actor.warning_ray.show()
				if column == 2:
					actor.windup_remaining = 0
					actor._fire()
				actor.get_node("SentryAttackCue")._physics_process(0)
				actor.get_node("PaintedMobAppearance")._process(0)
		_label(host, scenes[row], Vector2(20, 230 + row * 135), 15)
	await _capture("mob_charge")
	host.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
