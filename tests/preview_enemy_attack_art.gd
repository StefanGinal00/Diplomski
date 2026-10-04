extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(1440, 900)
	root.content_scale_size = Vector2i(1440, 900)
	root.get_node("GameState").save_path = "res://_tmp_attack_preview.json"
	root.get_node("GameState").start_new_game("normal")
	var stage := Node2D.new()
	root.add_child(stage)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1440, 0), Vector2(1440, 900), Vector2(0, 900)])
	bg.color = Color("17202e")
	stage.add_child(bg)
	_label(stage, "ATTACK MATERIALS / actual presenters enlarged for inspection", Vector2(30, 20), 25)
	var ids := ["void_sentinel", "abyss_warden", "echo_matriarch", "ash_castellan", "hollow_sovereign", "starfall_guardian", "ember_marshal", "ranged", "sentry"]
	for i in range(ids.size()):
		var bolt: Node2D = load("res://EnemyProjectile.tscn").instantiate()
		stage.add_child(bolt)
		bolt.set_physics_process(false)
		bolt.position = Vector2(100 + i * 157, 145)
		bolt.scale = Vector2.ONE * 3.6
		var effect := preload("res://BossProjectileAppearance.gd").new()
		effect.style = ids[i]
		effect.tint = preload("res://BossCombatPresentation.gd").COLORS.get(ids[i], Color("7abbb3"))
		bolt.add_child(effect)
		_label(stage, ids[i].replace("_", "\n"), Vector2(30 + i * 157, 210), 17)
	var actors := ["ShaftCrawler", "ShaftWisp", "EchoShade", "EchoBroodling", "RootStalker"]
	for i in range(actors.size()):
		var actor: Node2D = load("res://%s.tscn" % actors[i]).instantiate()
		stage.add_child(actor)
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		actor.position = Vector2(120 + i * 265, 415)
		actor.scale = Vector2.ONE * 2
		if i in [0, 1, 3]:
			actor.state = 2
		elif i == 2:
			actor.dash_remaining = 0.3
		else:
			actor.phase = "burst"
			actor.strike_area.position.x = 51
		actor.get_node("AttackPresentation")._physics_process(0.016)
		if actor.has_node("Appearance"):
			actor.get_node("Appearance")._process(0.016)
		_label(stage, actors[i], Vector2(35 + i * 265, 510), 18)
	for i in range(4):
		var effect := preload("res://BossBurst.gd").spawn(stage, Vector2(190 + i * 350, 810), Color("bfc9e3"), "pillar" if i < 3 else "ring", Vector2(72, 165) if i < 3 else Vector2(80, 80), 0.4, [13, 14, 17, 15][i])
		effect.set_process(false)
		effect.age = 0.06
	_label(stage, "Eruption                     Starfall column                      Root strike                       Runic shockwave", Vector2(115, 850), 20)
	await _capture("enemy_attack_materials")
	quit()
