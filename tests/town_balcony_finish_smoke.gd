extends "res://tests/gameplay_review_smoke.gd"
const Trim := preload("res://TownBalconyFinish.gd")
const Support := preload("res://WorldSupport.gd")

func _verify(room: Node2D,finish: Node) -> void:
	var nodes: Array[Node]=finish._members(room)
	var native := _collision_snapshot(nodes)
	var art: Node2D=room.get_node("BalconyFinish")
	print("BALCONY_COUNTS ",room.global_position," rails=",art.rails.size()," retired=",art.retired.size()," windows=",art.window_bounds)
	_check(art.built and art.rails.size()==2 and art.retired.size()==3,"Missing authored balcony/window replacement")
	_check(not art.is_processing() and not art.is_physics_processing() and art.global_transform.is_equal_approx(Transform2D.IDENTITY),"Trim adds callbacks or inherits room scale")
	var floors := Support.floors(nodes)
	for rail in art.rails:
		_check(rail.support in floors,"Balcony posts lack real support")
		var rect: Rect2=art.global_transform*rail.rect
		_check(absf(rect.end.y-rail.support.position.y)<.01 and rect.position.x>=rail.support.position.x and rect.end.x<=rail.support.end.x,"Rail extends into a shaft/air")
		_check(rect.size.y<=20.01,"Rail is oversized")
	var home: Polygon2D=room.get_node("LibraryRooftop/RoofArchive")
	var window: Rect2=art.window_bounds
	for point in [window.position,window.position+Vector2(window.size.x,0),window.end,window.position+Vector2(0,window.size.y)]:
		_check(Geometry2D.is_point_in_polygon(home.to_local(art.to_global(point)),home.polygon),"Painted archive window leaves facade")
	_check(art.window_art.texture is AtlasTexture and art.window_art.texture.filter_clip,"Archive lacks textured window")
	for old in art.retired: _check(not old.visible,"Flat prototype rail/window still visible")
	var original_id := art.get_instance_id()
	_check(Trim.install(room).get_instance_id()==original_id,"Trim installation duplicates")
	_check(_collision_snapshot(finish._members(room))==native,"Trim alters gameplay collision")

func _run() -> void:
	var state := root.get_node("GameState"); state.save_path="res://_tmp_town_balcony_finish.json"; state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate(); root.add_child(game); current_scene=game
	for frame in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false; game.process_mode=Node.PROCESS_MODE_DISABLED
	state.set_current_room("starfall_citadel")
	for frame in 4: await process_frame
	var finish := game.get_node("WorldPresentationFinish"); finish.finish_room("starfall_citadel")
	_verify(game.get_node("StarfallCitadel"),finish)
	# A separately translated/scaled native room must keep world-size rails.
	var room: Node2D=load("res://StarfallCitadel.tscn").instantiate()
	room.position=Vector2(17000,-8000); room.scale=Vector2(1.4,1.2); root.add_child(room)
	for frame in 4: await process_frame
	_verify(room,finish)
	room.free(); game.free(); state.delete_save()
	print("TOWN BALCONY FINISH TEST PASSED" if failures.is_empty() else "TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
