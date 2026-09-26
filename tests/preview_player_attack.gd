extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1920, 900)
	root.content_scale_size = Vector2i(1920, 900)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_attack_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1920, 0), Vector2(1920, 900), Vector2(0, 900)])
	background.color = Color("172b38")
	gallery.add_child(background)
	_label(gallery, "WAYFARER - attached weapons / follow-through, both directions (enlarged)", Vector2(30, 25), 23)
	for row in range(2):
		for index in range(6):
			var kind: String = ["sword", "bow", "staff"][index % 3]
			var presenter := Sprite2D.new()
			presenter.set_script(load("res://PlayerAppearance.gd"))
			presenter._apply_attack_pose(kind, index >= 3, row == 1, false)
			var sprite := Sprite2D.new()
			sprite.texture = presenter.texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.hframes = 3
			sprite.vframes = 2
			sprite.frame = presenter.frame
			sprite.flip_h = presenter.flip_h
			sprite.offset = presenter.offset
			sprite.scale = presenter.scale * 5
			sprite.position = Vector2(235 + index * 300, 290 + row * 390)
			gallery.add_child(sprite)
			# Staged registration review; no invented attack events or collisions.
			var weapon := Node2D.new()
			weapon.set_script(load("res://WeaponAppearance.gd"))
			gallery.add_child(weapon)
			weapon.set_process(false)
			weapon.active = true
			weapon.weapon_class = kind
			weapon.weapon_id = {"sword": "worn_sword", "bow": "hunter_bow", "staff": "apprentice_staff"}[kind]
			weapon.side = -1.0 if row == 1 else 1.0
			weapon.direction = Vector2(weapon.side, 0)
			var grip: Vector2 = (weapon.GRIPS[presenter.frame] - presenter.COMBAT_PIVOTS[presenter.frame]) * presenter.scale
			grip.x *= weapon.side
			weapon.hand = Vector2(0, 10) + grip
			weapon.progress = 0.7 if index >= 3 else 0.1
			weapon.accent = Color("b8a3f2") if kind == "staff" else Color("edcf90")
			weapon.position = sprite.position - Vector2(0, 50)
			weapon.scale = Vector2.ONE * 5
			weapon.queue_redraw()
			presenter.free()
			_label(gallery, kind.capitalize() + (" finish" if index >= 3 else " release"), Vector2(165 + index * 300, 330 + row * 390), 21)
	await _capture("player_weapon_poses")
	gallery.queue_free()
	await process_frame
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var room: Node2D = load("res://EchoGrotto.tscn").instantiate()
	root.add_child(room)
	await process_frame
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var template := load("res://Game.tscn").instantiate() as Node
	var actor := template.get_node("Player") as Player
	template.remove_child(actor)
	template.free()
	root.add_child(actor)
	actor.get_node("Camera2D").enabled = false
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.position = Vector2(455, 148)
	actor.facing_direction = 1
	actor.get_node("Appearance")._reset_motion()
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(460, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	_label(overlay, "STAGED WEAPON ART: successful attack + registered weapon, normal zoom", Vector2(30, 20), 20)
	for weapon in ["worn_sword", "hunter_bow", "apprentice_staff"]:
		state.add_item(weapon)
		state.equip_item(weapon, "primary_weapon")
		actor.attack_cooldown_timer.stop()
		actor.attack_visual_timer.stop()
		actor.try_attack()
		actor.get_node("Appearance")._process(0)
		actor.get_node("WeaponAppearance")._process(0)
		for projectile in get_nodes_in_group("player_projectile"):
			projectile.process_mode = Node.PROCESS_MODE_DISABLED
		await _capture("player_weapon_" + weapon)
		for projectile in get_nodes_in_group("player_projectile"):
			projectile.queue_free()
		await process_frame
	actor.queue_free()
	room.queue_free()
	overlay.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
