extends "res://tests/preview_characters.gd"

const Impact = preload("res://ProjectileImpact.gd")


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_melee_impact_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	background.color = Color("172b38")
	gallery.add_child(background)
	_label(gallery, "SWORD CONTACT / 5x enlarged / early, middle, fade", Vector2(35, 25), 24)
	var emitter := Node2D.new()
	gallery.add_child(emitter)
	for row in range(2):
		_label(gallery, "ACTOR" if row == 0 else "BREAKABLE", Vector2(30, 95 + row * 300))
		for column in range(6):
			var spirit := column >= 3
			var age: float = [0.035, 0.1, 0.18][column % 3]
			var point := Vector2(110 + column * 210, 235 + row * 300)
			var effect := Impact.spawn(emitter, point, Vector2.LEFT if spirit else Vector2.RIGHT, "spirit_slash" if spirit else "slash", Color(0.35, 0.95, 1.0) if spirit else Color(1.0, 0.78, 0.16), "actor" if row == 0 else "breakable")
			effect.set_process(false)
			effect.age = age
			effect.scale = Vector2.ONE * 5
			effect.queue_redraw()
			_label(gallery, ("Spiritglass" if spirit else "Worn sword") + " / %dms" % int(age * 1000), point + Vector2(-85, 100), 16)
	await _capture("melee_contact_phases")
	gallery.queue_free()
	await process_frame
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
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(460, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	_label(overlay, "STAGED ACTUAL SWORD CONTACT / frozen after hit / normal camera zoom", Vector2(28, 20), 19)
	for item in ["worn_sword", "spiritglass_blade"]:
		state.add_item(item)
		state.equip_item(item, "primary_weapon")
		actor.facing_direction = -1 if item == "spiritglass_blade" else 1
		actor._set_crouching(item == "spiritglass_blade")
		actor._update_attack_direction()
		actor.get_node("Appearance")._reset_motion()
		var target: StaticBody2D = load("res://RangedEnemy.tscn").instantiate()
		target.max_health = 30
		target.position = actor.position + Vector2(actor.facing_direction * 32, 0)
		root.add_child(target)
		target.set_process(false)
		await physics_frame
		await physics_frame
		actor.attack_cooldown_timer.stop()
		actor.attack_visual_timer.stop()
		actor.try_attack()
		actor.get_node("Appearance")._process(0)
		actor.get_node("WeaponAppearance")._process(0)
		for effect in get_nodes_in_group(Impact.GROUP):
			effect.set_process(false)
			effect.age = 0.05
			effect.queue_redraw()
		print("MELEE PREVIEW ", item, " target health=", target.current_health, " impacts=", get_nodes_in_group(Impact.GROUP).size())
		await _capture("player_melee_" + item)
		target.queue_free()
		for effect in get_nodes_in_group(Impact.GROUP):
			effect.queue_free()
		await process_frame
	actor.queue_free()
	room.queue_free()
	overlay.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
