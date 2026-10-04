extends "res://tests/preview_characters.gd"

const Layout := preload("res://WorldLayout.gd")
const Support := preload("res://WorldSupport.gd")

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_corridor_clearance_preview.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene = game
	for frame in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	var phase := "before" if "--before" in OS.get_cmdline_user_args() else ("final" if "--final" in OS.get_cmdline_user_args() else "after")
	var views := [
		["training_passage","",Vector2(78,360)],
		["sunken_shaft","",Vector2(-2230,632)],
		["shaft_drift","ReturnLiftBottom",Vector2.ZERO],
		["shaft_approach","ReturnLiftTop",Vector2.ZERO],
		["echo_tide_well","LowerLift",Vector2.ZERO],
		["starfall_citadel","StreetLift",Vector2.ZERO],
		["starfall_sunless_passage","ReturnLiftTop",Vector2.ZERO],
		["echo_tide_well","UpperLift",Vector2.ZERO]
	]
	for index in views.size():
		if "--upper-only" in OS.get_cmdline_user_args() and str(views[index][1]) != "UpperLift": continue
		var id: String = views[index][0]
		state.set_current_room(id)
		for frame in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		for node in nodes:
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if node is CharacterBody2D and node != player:
				node.process_mode = Node.PROCESS_MODE_ALWAYS; node.set_physics_process(true)
		for tick in 70: await physics_frame
		for node in nodes:
			if is_instance_valid(node) and node is CharacterBody2D and node != player: node.process_mode = Node.PROCESS_MODE_DISABLED
		var at: Vector2 = room.to_global(views[index][2])
		if not str(views[index][1]).is_empty():
			var lift: Node2D = room.find_child(views[index][1],true,false)
			if lift == null: push_error("Missing preview lift in " + id); state.delete_save(); quit(1); return
			var floor_rect: Rect2 = lift.get_node("LiftGantry").get_meta("support_rect")
			if str(views[index][1]) == "UpperLift":
				print("UPPER HOIST SITE actor=",room.to_local(lift.global_position)," support=",room.global_transform.affine_inverse()*floor_rect)
				var near := Rect2(lift.global_position.x-70,floor_rect.position.y-110,140,110)
				for solid in Support.solids(nodes):
					if near.intersects(solid): print("UPPER HOIST SOLID ",room.global_transform.affine_inverse()*solid)
			at = Vector2(clampf(lift.global_position.x - 43,floor_rect.position.x + 12,floor_rect.end.x - 12),floor_rect.position.y - 30)
		player.global_position = at; player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 40: await physics_frame
		player.process_mode = Node.PROCESS_MODE_DISABLED
		if not player.is_on_floor(): push_error("Clearance preview lacks real floor: " + id); state.delete_save(); quit(1); return
		player.get_node("Appearance")._process(0.1)
		camera.offset = Vector2(36,-30); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(0.15); finish.ambience._process(0.15)
		var suffix := "_upper" if str(views[index][1]) == "UpperLift" else ""
		await _capture("corridor_clearance_%s_%s%s" % [phase,id,suffix])
		print("CLEARANCE VIEW ",phase," ",id," grounded=",player.is_on_floor())
	game.free(); state.delete_save(); quit(0)
