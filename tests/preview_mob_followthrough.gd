extends "res://tests/preview_characters.gd"
const MOB_SCENES := ["ShaftCrawler", "ShaftWisp", "EchoShade", "EchoBroodling", "RootStalker"]

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_mob_followthrough_preview.json"
	state.start_new_game("normal")
	var host := Node2D.new()
	host.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(host)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(960, 0), Vector2(960, 540), Vector2(0, 540)])
	bg.color = Color("172b38")
	host.add_child(bg)
	_label(host, "MOB ATTACK FOLLOW-THROUGH / actual presenters, enlarged 2.5x", Vector2(20, 16), 20)
	_label(host, "Left: live attack    |    Middle: breakup 0 ms    |    Right: final particles 85 ms", Vector2(20, 48), 16)
	for row in MOB_SCENES.size():
		for column in range(3):
			var actor: Node2D = load("res://%s.tscn" % MOB_SCENES[row]).instantiate()
			host.add_child(actor)
			actor.position = Vector2(145 + column * 310, 126 + row * 87)
			actor.scale = Vector2.ONE * 2.5
			actor.get_node("HealthBar").hide()
			if row == 2:
				actor.dash_direction = -1
				actor.dash_remaining = 0.4
			elif row == 4:
				actor.facing = 1
				actor.phase = "burst"
				actor.strike_area.position.x = 51
			else:
				actor.state = 2
				if row == 1: actor.dive_direction = Vector2(1, 0.3).normalized()
				else: actor.direction = 1
			var fx := actor.get_node("AttackPresentation")
			fx._physics_process(0)
			fx._physics_process(0.1)
			var art := actor.get_node_or_null("Appearance")
			if art == null: art = actor.get_node("PaintedMobAppearance")
			# Sample the active body first, just as gameplay does before recovery.
			art._process(0)
			if column > 0:
				if row == 2:
					actor.dash_remaining = 0
					actor.recovery_remaining = 0.5
				elif row == 4:
					actor.phase = "recovery"
				else:
					actor.state = 3
				fx._physics_process(0)
				if column == 2: fx._physics_process(0.085)
			art._process(0)
		_label(host, MOB_SCENES[row], Vector2(12, 145 + row * 87), 13)
	await _capture("mob_followthrough")
	host.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
