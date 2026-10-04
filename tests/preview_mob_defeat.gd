extends "res://tests/preview_characters.gd"
## Native defeat callbacks at deterministic times, not a full combat recording.
const ACTORS := ["Enemy", "AshFiend", "RootStalker", "ShaftSentry", "AshSentry", "ShaftCrawler", "ShaftWisp", "EchoShade", "EchoBroodling", "RangedEnemy"]

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2.ZERO)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_mob_defeat_preview.json"
	state.start_new_game("normal")
	var host := Node2D.new()
	host.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(host)
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([Vector2.ZERO, Vector2(384, 0), Vector2(384, 216), Vector2(0, 216)])
	backdrop.color = Color("172b38")
	host.add_child(backdrop)
	var captions := CanvasLayer.new()
	root.add_child(captions)
	_label(captions, "ORDINARY MOBS / native defeat samples / gameplay zoom 2.5", Vector2(22, 14), 20)
	var actors: Array[Node2D] = []
	for i in ACTORS.size():
		var actor: Node2D = load("res://%s.tscn" % ACTORS[i]).instantiate()
		host.add_child(actor)
		var floor_y := 88.0 + (i / 5) * 104.0
		var x := 38.0 + (i % 5) * 77.0
		var collider := actor.get_node("CollisionShape2D") as CollisionShape2D
		if collider.shape is RectangleShape2D:
			actor.position = Vector2(x, floor_y - collider.position.y - collider.shape.size.y * 0.5)
		else:
			actor.position = Vector2(x, floor_y - 30)
		var art := actor.get_node_or_null("PaintedMobAppearance") as Sprite2D
		if art == null: art = actor.get_node("Appearance")
		art.flip_h = i % 2 == 1
		actors.append(actor)
		var floor_line := Line2D.new()
		floor_line.points = PackedVector2Array([Vector2(x - 29, floor_y), Vector2(x + 29, floor_y)])
		floor_line.width = 0.6
		floor_line.default_color = Color("568492")
		host.add_child(floor_line)
		_label(captions, ACTORS[i], Vector2(x * 2.5 - 65, floor_y * 2.5 + 12), 14)
	await _capture("mob_defeat_before")
	for actor in actors:
		actor.take_damage(999)
	await _capture("mob_defeat_0")
	for stage in range(1, 4):
		for effect in get_nodes_in_group("boss_cosmetic_effect"):
			if not effect.is_queued_for_deletion():
				effect._process(0.085)
		await _capture("mob_defeat_%d" % stage)
	host.queue_free()
	captions.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
