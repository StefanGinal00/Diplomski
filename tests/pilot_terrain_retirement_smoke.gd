extends "res://tests/visual_style_slice_smoke.gd"
func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_pilot_terrain_retirement.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 4: await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var total:=0
	for data in [["echo_grotto","EchoGrotto"],["starfall_citadel","StarfallCitadel"]]:
		state.set_current_room(data[0])
		for i in 4: await process_frame
		var finish:=game.get_node("WorldPresentationFinish")
		finish.finish_room(data[0])
		var room:=game.get_node(data[1])
		var art:=room.get_node("VisualStyleSlice")
		var before:=_physics_snapshot(room)
		_check(art.surface_bodies.size()==art.surfaces.size(),"Pilot surfaces lost collider association")
		for index in art.surfaces.size():
			total+=1
			_check(art._has_finished_edge(index),"Old skirt still draws below finished platform: "+str(art.surface_bodies[index].get_path()))
		finish.finish_room(data[0])
		_check(before==_physics_snapshot(room),"Retiring old art changed collision")
	print("PILOT SKIRTS RETIRED ",total)
	for data in [["echo_haven","EchoHaven"],["echo_haven_outskirts","EchoHavenOutskirts"]]:
		state.set_current_room(data[0])
		for i in 4: await process_frame
		game.get_node("WorldPresentationFinish").finish_room(data[0])
		var room:=game.get_node(data[1])
		for named in (["WalkwayInlay"] if data[0]=="echo_haven" else ["CrystalSeam","RoadInlay","DistantCrystals"]):
			_check(not room.get_node(named).visible,"Old luminous room sketch still covers finished art")
		if data[0]=="echo_haven":
			var materials:=room.get_node("MaterialExpansion")
			_check(materials.edge_bodies.size()==materials.edges.size(),"Luminous edge retirement lost body association")
			for body in materials.edge_bodies:
				_check(body.has_node("TerrainEdgeArt"),"Finished Echo surface still has a bright pilot line")
	game.free()
	state.delete_save()
	print("PILOT TERRAIN RETIREMENT TEST PASSED" if failures.is_empty() else "PILOT TERRAIN RETIREMENT TEST FAILED "+str(failures))
	quit(0 if failures.is_empty() else 1)
