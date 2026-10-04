extends "res://tests/gameplay_review_smoke.gd"
const Atlas := preload("res://AmbientMothAtlas.gd")
const Roost := preload("res://AmbientMothRoost.gd")
const Fauna := preload("res://WorldAmbientFauna.gd")
const Placement := preload("res://RouteDressingPlacement.gd")
const Support := preload("res://WorldSupport.gd")

func _flight_bounds(roost: Node2D,context: String) -> void:
	for insect in roost.insects:
		if not insect.visible: continue
		_check(roost.footprint.encloses(insect.global_transform*insect.get_rect()),"Flight escapes validated volume: "+context)
		_check((insect.global_transform*insect.get_rect()).size.length()<9,"Oversized ambient insect: "+context)

func _fixtures() -> void:
	var stage := Node2D.new(); root.add_child(stage); stage.position=Vector2(-1400,900); stage.scale=Vector2(1.7,.8)
	var source := Node2D.new(); stage.add_child(source)
	var manager := preload("res://WorldAmbience.gd").new(); stage.add_child(manager)
	manager.set_process(false); manager.set_physics_process(false)
	var bytes := 0
	for family in Atlas.DATA:
		var image := Image.new(); image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/visual_slice/ambient_moth_%s_v1.png"%family))
		for index in 6:
			var crop: Rect2=Atlas.DATA[family].boxes[index]
			var pivot: Vector2=Atlas.DATA[family].pivots[index]
			_check(crop.has_point(pivot) and image.get_pixelv(Vector2i(pivot)).a>.5,"Registered thorax is not opaque: "+family+str(index))
			var cell := Vector2i(index%3,index/3)*Vector2i(512,512)
			for point in [cell,cell+Vector2i(511,0),cell+Vector2i(0,511),cell+Vector2i(511,511)]:
				_check(image.get_pixelv(point).a<.01,"Opaque sheet gutter: "+family)
		var roost := Roost.new(); stage.add_child(roost)
		roost.configure(family,source,Vector2(-200,300),Rect2(-500,345,600,20))
		_check(roost.global_scale.is_equal_approx(Vector2.ONE),"Scaled room deforms flight envelope")
		_check(not roost.is_processing() and not roost.is_physics_processing(),"Per-roost callback added")
		roost.animate(2.0)
		var before: Vector2=roost.insects[0].position
		roost.brush(0.35)
		_check(roost.flight==0 and before.is_equal_approx(roost.insects[0].position),"Contact teleports insects instead of easing")
		for direction in [-1,1]:
			roost.escape_direction=direction; roost.flight=1
			for sample in 240:
				roost.animate(sample*.073); _flight_bounds(roost,family)
		roost.reset_response(); roost.rest()
		manager.register_room("fauna_fixture",[roost])
		manager.select_visible(roost.footprint)
		manager.sample_brushing(Vector2(-210,332),Vector2(-190,332),Vector2(160,0),1.0/60)
		_check(roost in manager.brushing and roost.alarm==1,"Player passage fails to start fauna response")
		for tick in 18: manager.sample_brushing(Vector2(-190,332),Vector2(-190,332),Vector2.ZERO,1.0/60)
		_check(roost.flight>.5,"Fauna reaction remains invisible")
		manager.select_visible(Rect2(8000,8000,30,30))
		for tick in 180: manager.sample_brushing(Vector2(-190,332),Vector2(-190,332),Vector2.ZERO,1.0/60)
		_check(manager.brushing.is_empty() and roost.insects.all(func(sprite): return not sprite.visible),"Culled flock never settles/retire")
		manager.select_visible(roost.footprint); roost.animate(4)
		manager.set_low_quality(true)
		_check(roost.insects[0].visible and not roost.insects[2].visible,"Low-quality sprite cap ignored")
		manager.set_low_quality(false)
		_check(roost.insects[2].visible,"High-quality restoration loses third insect")
		manager.sample_brushing(Vector2.ZERO,Vector2(2000,0),Vector2(9000,0),1.0/60)
		_check(roost.alarm==0 and roost.flight==0,"Warp leaves scattering fauna")
		source.hide(); roost.animate(10)
		_check(roost.insects.all(func(sprite): return not sprite.visible),"Hidden habitat leaves flying moths")
		source.show(); manager.register_room("empty",[]); roost.free()
		bytes+=Atlas.sheets[family].get_image().get_data().size()
	_check(bytes<4*1024*1024,"Moth imports exceed 4 MiB decoded/mipmapped budget")
	print("FAUNA_SOURCE_BYTES ",bytes)
	stage.free()
	# Revalidate actual support and late geometry without touching colliders.
	stage=Node2D.new(); root.add_child(stage); stage.position=Vector2(1700,-500); stage.scale=Vector2(1.4,1.2)
	var body := StaticBody2D.new(); stage.add_child(body)
	var floor_shape := CollisionShape2D.new(); floor_shape.shape=RectangleShape2D.new(); floor_shape.shape.size=Vector2(1000,20); body.add_child(floor_shape)
	var floor_rect: Rect2=floor_shape.global_transform*Rect2(-floor_shape.shape.size/2,floor_shape.shape.size)
	var plant := preload("res://RouteDetail.gd").new(); stage.add_child(plant)
	plant.configure("cave","floor",5,65,14,Vector2(1700,floor_rect.position.y+.65),floor_rect,true)
	var nodes: Array[Node]=[body,floor_shape,plant]
	var snapshot := _collision_snapshot(nodes)
	var layer := Fauna.install(stage,"fixture",nodes)
	_check(layer.roosts.size()==1,"No scaled fixture habitat")
	var wall := StaticBody2D.new(); stage.add_child(wall); wall.global_position=plant.global_position-Vector2(0,45)
	var shape := CollisionShape2D.new(); shape.shape=RectangleShape2D.new(); shape.shape.size=Vector2(8,120); wall.add_child(shape); nodes.append(shape)
	Fauna.install(stage,"fixture",nodes); _check(layer.roosts.is_empty(),"Late wall leaves flight through rock")
	shape.disabled=true; Fauna.install(stage,"fixture",nodes); _check(layer.roosts.size()==1,"Removed wall fails to restore habitat")
	floor_shape.disabled=true; Fauna.install(stage,"fixture",nodes); _check(layer.roosts.is_empty(),"Missing support leaves orphan habitat")
	floor_shape.disabled=false; Fauna.install(stage,"fixture",nodes)
	_check(layer.roosts.size()==1 and _collision_snapshot([body,floor_shape,plant])==snapshot,"Fauna changes native ground")
	plant.free(); Fauna.install(stage,"fixture",[body,floor_shape]); _check(layer.roosts.is_empty(),"Freed plant leaves orphan habitat")
	stage.free()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_ambient_fauna.json"; state.start_new_game("normal")
	_fixtures()
	var game: Node2D=load("res://Game.tscn").instantiate(); root.add_child(game); current_scene=game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false; game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var totals := {"rooms":0,"roosts":0,"families":{},"maximum":0}
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		var snapshot := _collision_snapshot(nodes)
		var layer: Node2D=room.get_node("AmbientFauna")
		var ids: Array[int]=[]
		for roost in layer.roosts:
			ids.append(roost.get_instance_id()); totals.roosts+=1
			totals.families[roost.family]=totals.families.get(roost.family,0)+1
			_check(Placement.clear(roost.footprint,Support.solids(nodes)),"World flight intersects solid: "+id)
			_check(Placement.clear(roost.footprint,Placement.reservations(nodes)),"World flight obscures an interaction: "+id)
			_check(roost.support in Placement.floors(nodes) and is_instance_valid(roost.habitat) and roost.habitat.visible,"World habitat unsupported: "+id)
			roost.animate(1.3); roost.flight=1; roost._pose(); _flight_bounds(roost,id); roost.reset_response()
		_check(layer.roosts.size()<=6,"Room fauna cap exceeded")
		totals.maximum=maxi(totals.maximum,layer.roosts.size())
		Fauna.install(room,id,nodes)
		_check(layer.roosts.map(func(roost): return roost.get_instance_id())==ids,"Stable registration replaces/duplicates moth groups")
		_check(_collision_snapshot(finish._members(room))==snapshot,"Fauna mutates world physics: "+id)
		for low in [false,true]:
			finish.ambience.set_low_quality(low)
			if not layer.roosts.is_empty():
				finish.ambience.select_visible(layer.roosts[0].footprint.grow(160))
				_check(layer.roosts[0] in finish.ambience.active,"Nearby fauna starved by dense grass: "+id)
			_check(finish.ambience.active.size()<=finish.ambience.animation_budget(),"Fauna exceeds shared animation budget")
		totals.rooms+=1
	_check(totals.rooms==39 and totals.roosts>80 and totals.families.size()==4,"World fauna coverage regressed")
	print("FAUNA_WORLD_COUNTS ",JSON.stringify(totals))
	game.free(); state.delete_save()
	print("AMBIENT FAUNA TEST PASSED" if failures.is_empty() else "AMBIENT FAUNA TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
