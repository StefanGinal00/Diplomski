extends "res://tests/gameplay_review_smoke.gd"

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_corridor_dressing.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 5: await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish:=game.get_node("WorldPresentationFinish")
	var counts:=[]
	var total:=0
	var vault_lips:=0
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for i in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var art:=room.get_node("CorridorDressing")
		var before:=_collision_snapshot(finish._members(room))
		var child_count:=art.get_child_count()
		finish.finish_room(id)
		_check(child_count==art.get_child_count(),"Repeated corridor installation in "+id)
		_check(before==_collision_snapshot(finish._members(room)),"Dressing changed collisions in "+id)
		_check(art.find_children("*","CollisionObject2D",true,false).is_empty() and not art.is_processing(),"Decor owns physics/processors in "+id)
		_check(art.clusters.size()<=120 and art.canopies.size()<=40,"Unbounded corridor dressing in "+id)
		var visible:=0
		for prop in art.clusters:
			var foot: Vector2=prop.get_meta("ground_contact")
			var bottom: float=prop.to_global(Vector2(0,-prop.texture.get_height()*0.5+float(prop.get_meta("contact_row")))).y
			_check(absf(bottom-foot.y)<1,"Floating ground cluster in "+id)
			_check(prop.texture.get_width()*prop.scale.x<=53,"Oversized corridor prop in "+id)
			if prop.visible: visible+=1
		for prop in art.canopies:
			vault_lips+=1
			var floor_rect: Rect2=prop.get_meta("clearance_floor")
			var bottom: float=prop.global_position.y+prop.texture.get_height()*prop.scale.y*0.5
			_check(floor_rect.position.y-bottom>=95,"Low lip obstructs travel in "+id)
		var growth:=room.get_node("ForegroundGrowth")
		counts.append({"room":id,"clusters":art.clusters.size(),"visible_clusters":visible,"growth":growth.plants.size(),"ceiling_lips":art.canopies.size()})
		total+=visible
		finish.ambience.set_low_quality(true)
		finish.ambience.select_visible(Rect2(room.global_position-Vector2(9000,9000),Vector2(18000,18000)))
		_check(finish.ambience.active.size()<=8,"Mobile motion cap exceeded")
	_check(total>200 and vault_lips>20,"World-wide corridor coverage too sparse")
	var shaft:=game.get_node("VerticalChamber")
	_check(shaft.get_node("DeepShaftTraversal/LowerGalleryVaults").get_child_count()==2,"Lower Gallery low ceilings missing")
	for id in preload("res://CorridorAtlas.gd").DATA:
		var tex: Texture2D=load("res://art/visual_slice/%s.png"%id)
		_check(tex.get_width()<=1024 and tex.get_image().has_mipmaps(),"Unbounded raster import "+id)
	print("CORRIDOR_COUNTS ",JSON.stringify(counts))
	game.free()
	state.delete_save()
	print("CORRIDOR DRESSING TEST PASSED" if failures.is_empty() else "CORRIDOR DRESSING TEST FAILED "+str(failures))
	quit(0 if failures.is_empty() else 1)
