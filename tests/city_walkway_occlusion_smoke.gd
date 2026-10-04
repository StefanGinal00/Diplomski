extends "res://tests/visual_style_slice_smoke.gd"
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_city_walkway_occlusion.json";state.start_new_game("normal")
	var total:=0;var moved:=0;var canopies:=0;var bytes:=0
	for family in ["haven","hearth","street"]:
		var image: Texture2D=load("res://art/visual_slice/terrain_edge_%s_v1.png"%family)
		bytes+=image.get_image().get_data_size()
		_check(image.get_width()<=1024 and image.get_image().has_mipmaps() and image.get_image().get_pixel(0,0).a<0.01,"Town edge import budget/alpha")
	_check(bytes<12*1024*1024,"Three architectural ledge sheets exceed memory cap")
	for named in ["EchoHaven","EchoHavenOutskirts","CinderHearth"]:
		var room: Node2D=load("res://%s.tscn"%named).instantiate()
		room.position=Vector2(11000,-6000);root.add_child(room)
		for tick in 4: await process_frame
		room.process_mode=Node.PROCESS_MODE_DISABLED
		var painter:=room.get_node("PaintedBuildings")
		var before:=_physics_snapshot(room)
		_check(painter.window_art.size()==painter.window_frames.size(),"Window dropped instead of finding usable wall")
		for entry in painter.window_art:
			total+=1
			if entry.rect!=entry.preferred: moved+=1
			var rect: Rect2=painter.global_transform*entry.rect
			for floor_rect in painter.floors:
				_check(not rect.intersects(floor_rect.grow(2.9)),"Balcony still crosses window in "+named)
			if entry.home!=null:
				for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
					_check(Geometry2D.is_point_in_polygon(entry.home.to_local(point),entry.home.polygon),"Window outside home silhouette")
		for gable in painter.gables:
			_check(gable.polygon.size()==3 and gable.texture==painter.wall_texture,"Open/unpainted district roof gable")
		for entry in room.get_node("ResidentialFacadeDetails").entries:
			if entry.kind!="canopy": continue
			canopies+=1
			_check(entry.has("layout") and not entry.layout.is_empty(),"Canopy lost safe layout: " + named + " " + str(entry))
			var facade := room.get_node("ResidentialFacadeDetails")
			var rect:=Rect2(facade.to_global(entry.at)-Vector2(entry.width/2,entry.height),Vector2(entry.width,entry.height-1))
			for floor_rect in painter.floors:
				_check(not rect.intersects(floor_rect),"Balcony cuts canopy/posts")
			var image: Texture2D = preload("res://WorkplaceAtlas.gd").texture_for(entry.index)
			var cloth := Rect2(rect.position,image.get_size()*(entry.width/image.get_width()))
			for window in painter.window_art:
				var opening: Rect2 = painter.global_transform * window.rect.grow(2)
				_check(not cloth.intersects(opening),"Gate canopy hides a window: " + named)
			for opening in preload("res://SettlementCanopyPlacement.gd").openings(facade):
				for post in entry.layout.get("posts",[]):
					_check(not post.intersects(opening),"Gate canopy post blocks a door/window")
		var facade := room.get_node("ResidentialFacadeDetails")
		var fitted: Array = facade.entries.duplicate(true)
		facade._refit_canopies()
		_check(facade.entries==fitted,"Gate canopy refit changes placement on revisit")
		painter._build()
		_check(before==_physics_snapshot(room),"Window/gable painter changes collision")
		room.queue_free();await process_frame
	_check(total==91 and moved>8 and canopies==5,"City fixture coverage "+str([total,moved,canopies]))
	state.delete_save()
	print("CITY WALKWAY OCCLUSION TEST ","PASSED" if failures.is_empty() else "FAILED",": windows=",total," refitted=",moved," safe canopies=",canopies," texture_bytes=",bytes)
	quit(0 if failures.is_empty() else 1)
