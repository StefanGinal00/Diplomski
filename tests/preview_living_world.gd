extends "res://tests/preview_characters.gd"
const Layout:=preload("res://WorldLayout.gd")
func _render() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=root.size
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_living_world_preview.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var player: Player=game.get_node("Player")
	var camera: Camera2D=player.get_node("Camera2D")
	var finish:=game.get_node("WorldPresentationFinish")
	for data in [
		["shaft_hollow","ExpandedRoute/FieldDressing/Site4/PaintedReserve","reserve_shaft"],
		["ash_forge","AshSwitchback/FieldDressing/Site6/PaintedReserve","reserve_ash"],
		["starfall_outskirts","ExpandedRoute/FieldDressing/Site6/PaintedReserve","reserve_star"],
		["shaft_crossing","ExpandedRoute/FieldDressing/Site0/Boat","boat"],
		["ash_forge","AshSwitchback/AshIdentity/SixFurnaces/KilnHousing0","kiln"],
		["starfall_rooted_hall","ExpandedRoute/FieldDressing/Site4/SeedPot0","planter"],
		["shaft_drift","NaturalContours/ShallowRubble0","slope_cave"],
		["ash_emberspine","NaturalContours/ShallowRubble0","slope_ash"],
		["starfall_memory_vault","NaturalContours/ShallowRubble0","slope_star"]]:
		player.process_mode=Node.PROCESS_MODE_DISABLED
		state.set_current_room(data[0])
		for i in 4: await process_frame
		finish.finish_room(data[0])
		var room: Node2D=game.get_node(Layout.ROOM_NODES[data[0]])
		var target: Node2D=room.get_node_or_null(data[1])
		if target==null: print("LIVING VIEW MISSING ",data);continue
		for n in finish._members(room):
			if n is StaticBody2D: n.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		var focus:=target.global_position
		if target is Polygon2D:
			var rect:=Rect2(target.polygon[0],Vector2.ZERO)
			for point in target.polygon: rect=rect.expand(point)
			focus=target.to_global(Vector2(rect.get_center().x,rect.end.y))
		var floor_rect:=preload("res://WorldSupport.gd").below(focus-Vector2(0,20),finish.current_surfaces,180)
		if not floor_rect.has_area(): print("LIVING VIEW NO FLOOR ",data);continue
		player.global_position=Vector2(clampf(focus.x-55,floor_rect.position.x+15,floor_rect.end.x-15),floor_rect.position.y-20)
		player.velocity=Vector2.ZERO
		player.process_mode=Node.PROCESS_MODE_ALWAYS
		for tick in 40: await physics_frame
		player.get_node("Appearance")._process(0.1)
		print("LIVING VIEW GROUNDED ",data[2]," ",player.is_on_floor())
		player.process_mode=Node.PROCESS_MODE_DISABLED
		camera.offset=Vector2(48,-36)
		camera.reset_smoothing()
		camera.force_update_scroll()
		finish.background._process(0)
		finish._process(0.2)
		finish.ambience._process(0.2)
		game.get_node("UI")._dismiss_zone_title()
		await _capture("living_world_"+data[2])
	state.delete_save()
	quit()
