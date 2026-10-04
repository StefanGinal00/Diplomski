extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")

func _render() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_tunnel_vault_preview.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false; game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["shaft_gallery","shaft_drift","echo_depths","starfall_rooted_hall"]:
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
		if vaults.plans.is_empty(): push_error("No tunnel preview site: "+id); quit(1); return
		var plan: Dictionary = vaults.plans[-1]
		for tier in ["below","above"]:
			var surface: Rect2 = plan.lower if tier=="below" else plan.upper
			player.global_position = Vector2(plan.at.x+plan.width*.5,surface.position.y-25)
			player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
			for tick in 30: await physics_frame
			if not player.is_on_floor(): push_error("Tunnel preview has no real floor: "+id+"/"+tier); quit(1); return
			player.process_mode = Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
			# Look up into the buried roof, then inspect its still-playable upper
			# surface. The camera change is preview-only, not a gameplay zoom.
			camera.offset = Vector2(0,-88 if tier=="below" else 35)
			camera.reset_smoothing(); camera.force_update_scroll()
			finish.background._process(0); finish._process(.15); finish.ambience._process(.15)
			await _capture("tunnel_vault_"+id+"_"+tier)
			print("TUNNEL_VIEW ",id," ",tier," local=",room.to_local(player.global_position))
	game.free(); state.delete_save(); quit(0)
