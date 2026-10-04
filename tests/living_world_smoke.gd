extends "res://tests/gameplay_review_smoke.gd"

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_living_world.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for tick in 5: await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish:=game.get_node("WorldPresentationFinish")
	var plant_count:=0
	var mound_count:=0
	var shoulder_count:=0
	var rooms: Array=["training_passage"]
	rooms.append_array(Layout.ROOM_NODES.keys())
	for id in rooms:
		state.set_current_room(id)
		for frame in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var growth:=room.get_node("ForegroundGrowth")
		var contours:=room.get_node("NaturalContours")
		_check(growth.plants.size()<=growth.MAX_GROWTH,"Unbounded foreground in "+id)
		_check(contours.mounds.size()<=2,"Unbounded ground reshaping in "+id)
		_check(growth.find_children("*","CollisionObject2D",true,false).is_empty(),"Foreground blocks traversal in "+id)
		var before:=growth.get_child_count()
		finish.finish_room(id)
		_check(growth.get_child_count()==before,"Revisit duplicates foliage in "+id)
		for plant in growth.plants:
			plant_count+=1
			_check(plant.height<=14 and plant.z_index>0 and not plant.is_processing(),"Foreground size/layer/budget invalid")
			_check(absf(plant.global_position.y-plant.support.position.y)<=1,"Floating foreground")
			plant.animate(1.7)
			_check(plant.art.texture is AtlasTexture and plant.echo.texture is AtlasTexture,"Missing breeze frames")
			plant.rest()
			_check(plant.rotation==0 and plant.echo.self_modulate.a==0,"Offscreen plant kept animation")
		mound_count+=contours.mounds.size()
		shoulder_count+=contours.edge_details.size()
		for mound in contours.mounds:
			_check(mound.has_meta("natural_mound") and mound.surface.size()==33,"Mound missing registered collider")
		finish.ambience.set_low_quality(true)
		finish.ambience.select_visible(Rect2(room.global_position-Vector2(9000,9000),Vector2(18000,18000)))
		_check(finish.ambience.active.size()<=8,"Mobile ambient budget exceeded")
	_check(plant_count>300,"Foreground missing across mapped world")
	_check(mound_count>6,"Natural slopes missing from broad main floors")
	_check(shoulder_count>20,"Modular earth joins missing")
	print("LIVING_WORLD_COUNTS ",JSON.stringify({"rooms":rooms.size(),"plants":plant_count,"mounds":mound_count,"shoulders":shoulder_count}))
	game.queue_free()
	await process_frame
	state.delete_save()
	print("LIVING WORLD TEST PASSED" if failures.is_empty() else "LIVING WORLD TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
