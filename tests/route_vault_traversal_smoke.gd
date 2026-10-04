extends "res://tests/gameplay_review_smoke.gd"
var player: Player
var checked := 0

func _release() -> void:
	for action in ["ui_left","ui_right","ui_accept"]: Input.action_release(action)

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_route_vault_traversal.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene = game
	for frame in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	player = game.get_node("Player"); player.test_invincible = true
	player.double_jump_unlocked = false; player.dash_unlocked = false
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for frame in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is CollisionObject2D:
				node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
				if node is Area2D or node.is_in_group("enemy") or node.is_in_group("breakable") or node.is_in_group("neutral_creature"):
					node.collision_layer = 0; node.collision_mask = 0
		for vault in room.get_node("RouteVaults").vaults:
			var plan: Dictionary = vault.get_meta("vault_plan")
			for fraction in [0.2,0.5,0.8]:
				_release(); player.process_mode = Node.PROCESS_MODE_DISABLED
				player.global_position = Vector2(plan.at.x+plan.width*fraction,plan.lower.position.y-player.player_collision.shape.size.y/2-1)
				player.velocity = Vector2.ZERO; player.jump_count = 0; player.jump_buffer_remaining = 0
				player.process_mode = Node.PROCESS_MODE_ALWAYS
				for tick in 12: await physics_frame
				_check(player.is_on_floor(),"Vault takeoff floor missing: "+id)
				var floor_at := player.global_position.y
				var highest := floor_at
				var hit_vault := false
				player.jump_buffer_remaining = 0.12
				for tick in 65:
					await physics_frame
					highest = minf(highest,player.global_position.y)
					for hit in player.get_slide_collision_count():
						if player.get_slide_collision(hit).get_collider() == vault: hit_vault = true
				_check(floor_at-highest>=75,"Normal jump shortened under new vault: "+id)
				_check(not hit_vault,"New vault blocks normal jump: "+id)
				# A native crossing ledge can catch a jump above the takeoff floor.
				_check(player.is_on_floor() and player.global_position.y<=floor_at+2,"Failed landing under new vault: %s fraction=%s y=%s start=%s on_floor=%s"%[id,fraction,room.to_local(player.global_position),floor_at-room.global_position.y,player.is_on_floor()])
				checked += 1
			# Walk the entire added silhouette in both directions on the real floor.
			for direction in [-1,1]:
				_release(); player.process_mode = Node.PROCESS_MODE_DISABLED
				var from_x: float = plan.at.x+plan.width+8 if direction < 0 else plan.at.x-8
				player.global_position = Vector2(from_x,plan.lower.position.y-player.player_collision.shape.size.y/2-1)
				player.velocity = Vector2.ZERO; player.process_mode = Node.PROCESS_MODE_ALWAYS
				for tick in 10: await physics_frame
				Input.action_press("ui_left" if direction < 0 else "ui_right")
				var target_x: float = plan.at.x-5 if direction < 0 else plan.at.x+plan.width+5
				for tick in 210:
					await physics_frame
					if (player.global_position.x-target_x)*direction >= 0: break
				_release()
				_check((player.global_position.x-target_x)*direction>=0,"Cannot walk under new vault: "+id)
				# Allow a few frames to descend from overlapping native stair ledges.
				for tick in 20: await physics_frame
				_check(player.is_on_floor() and player.global_position.y+player.player_collision.shape.size.y/2<=plan.lower.position.y+2,"Vault walk falls through floor: %s at=%s floor=%s"%[id,room.to_local(player.global_position),plan.lower.position.y-room.global_position.y])
				checked += 1
			print("VAULT_TRAVERSED ",id," ",vault.name)
		player.process_mode = Node.PROCESS_MODE_DISABLED
	_release(); game.free(); state.delete_save()
	_check(checked>=5,"No physical vault traversal exercised")
	print("VAULT_TRAVERSAL checks=",checked)
	if failures.is_empty(): print("ROUTE VAULT TRAVERSAL TEST PASSED"); quit(0)
	else: quit(1)
