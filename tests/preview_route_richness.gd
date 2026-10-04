extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")
const Support := preload("res://WorldSupport.gd")

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_route_richness_preview.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene = game
	for frame in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	var views := ["training_passage","sunken_shaft","shaft_drift","echo_grotto","echo_gallery","ash_forge","ash_barracks","starfall_rooted_hall","starfall_sunless_passage","echo_haven","ash_hearth","starfall_citadel"]
	for id in views:
		if "--vault-only" in OS.get_cmdline_user_args() and not id in ["shaft_drift","ash_barracks","starfall_sunless_passage"]: continue
		state.set_current_room(id)
		for frame in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		for node in nodes:
			if node is StaticBody2D: node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if node is CharacterBody2D and node != player: node.process_mode = Node.PROCESS_MODE_ALWAYS; node.set_physics_process(true)
		for tick in 70: await physics_frame
		for node in nodes:
			if is_instance_valid(node) and node is CharacterBody2D and node != player: node.process_mode = Node.PROCESS_MODE_DISABLED
		var vaults := room.get_node("RouteVaults")
		var at := Vector2.ZERO
		if not vaults.plans.is_empty():
			var plan: Dictionary = vaults.plans[0]
			at = Vector2(plan.at.x+plan.width/2-50,plan.lower.position.y-25)
			print("VAULT_PREVIEW ",id," upper=",room.global_transform.affine_inverse()*plan.upper," lower=",room.global_transform.affine_inverse()*plan.lower," face=",room.global_transform.affine_inverse()*vaults.vaults[0].get_meta("visual_bounds"))
		else:
			var candidates: Array = []
			for prop in room.get_node("PathDressing").details:
				if prop.kind == "floor" and prop.visible and prop.support.size.x>400: candidates.append(prop)
			if candidates.is_empty(): push_error("No grounded preview for "+id); state.delete_save(); quit(1); return
			var choice: Node2D = candidates[candidates.size()/3]
			at = Vector2(choice.global_position.x,choice.support.position.y-25)
		if id == "sunken_shaft": at = room.to_global(Vector2(-2230,632))
		player.global_position = at; player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 40: await physics_frame
		player.process_mode = Node.PROCESS_MODE_DISABLED
		if not player.is_on_floor(): push_error("Preview lacks real floor: "+id); state.delete_save(); quit(1); return
		player.get_node("Appearance")._process(0.1)
		camera.offset = Vector2(36,-36); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(0.15); finish.ambience._process(0.15)
		await _capture("route_richness_"+id)
		print("RICHNESS_VIEW ",id," at=",room.to_local(player.global_position)," vaults=",vaults.plans.size())
	game.free(); state.delete_save(); quit(0)
