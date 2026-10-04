extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_living_routes_preview.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false; game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["shaft_gallery","shaft_drift","echo_depths","starfall_rooted_hall","ash_barracks"]:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is CollisionObject2D:
				node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
				if node is Area2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature"):
					node.collision_layer = 0; node.collision_mask = 0
		var vaults: Node2D = room.get_node("RouteVaults")
		var patches: Array = room.get_node("RouteRelief").patches
		var at := Vector2.ZERO
		if not vaults.plans.is_empty():
			var plan: Dictionary = vaults.plans[-1]
			at = Vector2(plan.at.x+plan.width*.5,plan.lower.position.y-25)
		elif not patches.is_empty():
			var patch: Node2D = patches[-1]
			at = Vector2(patch.global_position.x+patch.plan.width*.48,patch.height_at(patch.global_position.x+patch.plan.width*.48)-25)
		else: push_error("No live route preview site: "+id); quit(1); return
		player.global_position = at; player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
		for tick in 30: await physics_frame
		if not player.is_on_floor(): push_error("Preview has no real floor: "+id); quit(1); return
		player.process_mode = Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
		camera.offset = Vector2(0,-42); camera.reset_smoothing(); camera.force_update_scroll()
		finish.background._process(0); finish._process(.15); finish.ambience._process(.15)
		await _capture("living_routes_"+id)
		print("LIVING_ROUTE_VIEW ",id," local=",room.to_local(player.global_position)," vaults=",vaults.vaults.size()," understory=",room.get_node("PathDressing").understory.size()," seeps=",room.get_node("PathDressing").seeps.size())
		if id=="shaft_gallery":
			var rear: Node2D
			for plant in room.get_node("PathDressing").understory:
				if plant.visible and plant.z_index<0 and plant.support.size.x>400:
					rear = plant; break
			if rear==null: push_error("Missing rear foliage for live brush"); quit(1); return
			player.global_position = rear.global_position-Vector2(38,22); player.velocity = Vector2.ZERO
			player.process_mode = Node.PROCESS_MODE_ALWAYS
			for tick in 15: await physics_frame
			finish.ambience.clear_brushing(); finish.ambience._physics_process(1.0/60)
			Input.action_press("ui_right")
			for tick in 18: await physics_frame; finish.ambience._physics_process(1.0/60)
			Input.action_release("ui_right"); player.process_mode = Node.PROCESS_MODE_DISABLED
			camera.reset_smoothing(); camera.force_update_scroll(); finish.background._process(0)
			await _capture("living_routes_brush")
			print("UNDERSTORY_LIVE_BRUSH bend=",rear.response.bend," contacts=",finish.ambience.brush_contacts)
			if rear.response.bend<.03: push_error("Live controller fails to brush rear grass"); quit(1); return
			for tick in 220: finish.ambience._physics_process(1.0/60)
			await _capture("living_routes_recovered")
			if rear.response.bend!=0: push_error("Rear grass fails to settle"); quit(1); return
	game.free(); state.delete_save(); quit(0)
