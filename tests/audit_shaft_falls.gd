extends "res://tests/gameplay_review_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_audit_shaft_falls.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 4: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	state.set_current_room("sunken_shaft")
	for i in 6: await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var room := game.get_node("VerticalChamber")
	var nodes: Array[Node]=game.get_node("WorldPresentationFinish")._members(room)
	var floors := preload("res://WorldSupport.gd").floors(nodes)
	for n in nodes:
		if n is StaticBody2D: n.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	await physics_frame
	var bottom_coverage: Array[Rect2]=[]
	for rect in floors:
		var local: Rect2=room.global_transform.affine_inverse()*rect
		if local.position.y>600: bottom_coverage.append(local)
	print("BOTTOM FLOORS ",bottom_coverage)
	var p: Player=game.get_node("Player")
	var space := p.get_world_2d().direct_space_state
	var misses: Array[float]=[]
	for x in range(-3390,830,10):
		var from: Vector2=room.global_position+Vector2(x,740)
		var query:=PhysicsRayQueryParameters2D.create(from-Vector2(0,140),from+Vector2(0,1000),1,[p.get_rid()])
		if space.intersect_ray(query).is_empty(): misses.append(x)
	print("UNSUPPORTED BOTTOM X ",misses)
	print("FLOOR COUNT ",floors.size())
	game.free()
	state.delete_save()
	quit()
