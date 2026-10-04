extends "res://tests/preview_characters.gd"
const Book = preload("res://CombatFlipbook.gd")
var review_phase := 0

func _render() -> void:
	root.size = Vector2i(1500, 1000)
	root.content_scale_size = Vector2i(1500, 1000)
	root.get_node("GameState").save_path = "res://_tmp_flipbook_preview.json"
	root.get_node("GameState").start_new_game("normal")
	var stage := Node2D.new()
	root.add_child(stage)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1500, 0), Vector2(1500, 1000), Vector2(0, 1000)])
	bg.color = Color("17222e")
	stage.add_child(bg)
	_label(stage, "PAINTED COMBAT FLIPBOOKS / six genuinely different frames", Vector2(25, 15), 24)
	var effects := Node2D.new()
	stage.add_child(effects)
	effects.draw.connect(func():
		for identity in range(20):
			Book.stamp(effects, identity, review_phase, Rect2(25 + identity % 10 * 148, 75 + identity / 10 * 195, 140, 170))
	)
	var actors: Array[Node2D] = []
	for i in range(5):
		var actor: Node2D = load("res://%s.tscn" % ["Enemy", "AshFiend", "RootStalker", "ShaftSentry", "AshSentry"][i]).instantiate()
		stage.add_child(actor)
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		actor.scale = Vector2.ONE * 4
		actor.position = Vector2(150 + i * 290, 760)
		actor.get_node("HealthBar").hide()
		actors.append(actor)
		_label(stage, String(actor.name), Vector2(65 + i * 290, 835), 20)
	for step in range(6):
		review_phase = step
		effects.queue_redraw()
		for actor in actors:
			actor.get_node("PaintedMobAppearance")._apply_pose(step)
		await _capture("combat_flipbook_%02d" % step)
	stage.queue_free()
	await process_frame
	quit()
