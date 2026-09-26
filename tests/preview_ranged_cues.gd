extends "res://tests/preview_crawler.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ranged_cue_preview_save.json"
	state.start_new_game("normal")
	await _pose_gallery()
	var room: Node2D = load("res://EchoGrotto.tscn").instantiate()
	root.add_child(room)
	await process_frame
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var template: Node = load("res://Game.tscn").instantiate()
	var player := template.get_node("Player") as Player
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.get_node("Camera2D").enabled = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.position = Vector2(410, 148)
	player.get_node("Appearance")._apply_pose(0, false, false)
	var actors: Array[Node] = []
	for index in range(3):
		var actor: StaticBody2D = load("res://RangedEnemy.tscn").instantiate()
		actor.position = Vector2(490 + index * 60, 149)
		root.add_child(actor)
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		actor.shot_cooldown_remaining = [0.6, 0.1, 0.0][index]
		actor._process(0.0)
		actor.get_node("AttackCue")._process(0.0)
		actor.get_node("Appearance")._process(0.0)
		actors.append(actor)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(525, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	_label(overlay, "STAGED ART REVIEW: idle / warning / actual launch - stone sentinel", Vector2(30, 20), 20)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	print("RANGED ART PREVIEW: ", root.get_texture().get_image().save_png("res://art/characters/preview_ranged_art.png"))
	for actor in actors:
		actor.queue_free()
	for shot in get_nodes_in_group("enemy_projectile"):
		shot.queue_free()
	room.queue_free()
	player.queue_free()
	overlay.queue_free()
	await process_frame
	state.delete_save()
	quit(0)


func _pose_gallery() -> void:
	var gallery := Node2D.new()
	root.add_child(gallery)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	background.color = Color("172b38")
	gallery.add_child(background)
	_label(gallery, "STONE SENTINEL - four poses, both directions (enlarged)", Vector2(40, 30), 25)
	var captions := ["Idle", "Charging", "Firing recoil", "Hurt"]
	for row in range(2):
		for pose in range(4):
			var sprite := Sprite2D.new()
			sprite.set_script(load("res://RangedAppearance.gd"))
			gallery.add_child(sprite)
			sprite.set_process(false)
			sprite._apply_pose(pose, row == 1)
			sprite.scale *= 7
			sprite.position = Vector2(150 + pose * 310, 280 + row * 280)
			_label(gallery, captions[pose], Vector2(95 + pose * 310, 310 + row * 280))
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	print("RANGED POSES PREVIEW: ", root.get_texture().get_image().save_png("res://art/characters/preview_ranged_poses.png"))
	gallery.queue_free()
	await process_frame
