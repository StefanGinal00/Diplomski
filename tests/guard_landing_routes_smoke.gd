extends "res://tests/basic_jump_routes_smoke.gd"

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_guard_landing_routes.json"
	state.start_new_game("normal")
	var template: Node=load("res://Game.tscn").instantiate()
	player=template.get_node("Player"); template.remove_child(player); template.free()
	root.add_child(player)
	player.double_jump_unlocked=false; player.dash_unlocked=false
	player.set_physics_process(false)
	for named in ["CinderHearth","StarfallCitadel"]:
		var room: Node2D=load("res://%s.tscn"%named).instantiate()
		room.process_mode=Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		for tick in 3: await process_frame
		for actor in room.find_children("*","CollisionObject2D",true,false):
			actor.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
			if not actor is StaticBody2D or actor.is_in_group("enemy") or actor.is_in_group("breakable"):
				actor.collision_layer=0; actor.collision_mask=0
		var route: Array[StaticBody2D]=[]
		if named=="CinderHearth":
			route=[room.get_node("EasternDistricts/EastMarketStreet"),room.get_node("EasternDistricts/LibraryDescent6"),room.get_node("EasternDistricts/LibraryDescent5"),room.get_node("EasternDistricts/LibraryDescent4")]
		else:
			route=[room.get_node("Floor"),room.get_node("UpperCity/GardenGrandStairStep01"),room.get_node("UpperCity/GardenGrandStairStep02")]
		for step in range(route.size()-1): await _hop(route[step],route[step+1],named)
		room.queue_free(); await process_frame
	_release(); player.queue_free(); await process_frame; state.delete_save()
	print("GUARD LANDING ROUTES TEST PASSED: ",jumps," real-controller unupgraded jumps") if failures.is_empty() else print("GUARD LANDING ROUTES TEST FAILED ",failures)
	quit(0 if failures.is_empty() else 1)
