extends "res://tests/gameplay_review_smoke.gd"

const Support = preload("res://WorldSupport.gd")
const Dressing = preload("res://WorldCorridorDressing.gd")

func _fixture_solid(parent: Node2D, at: Vector2, size: Vector2) -> CollisionShape2D:
	var body := StaticBody2D.new(); parent.add_child(body); body.position = at
	var shape := CollisionShape2D.new(); shape.shape = RectangleShape2D.new(); shape.shape.size = size
	body.add_child(shape)
	return shape

func _fixture_clear(art: Node2D, nodes: Array[Node]) -> void:
	var solids := Support.solids(nodes)
	for prop in art.clusters:
		var bounds: Rect2 = prop.global_transform*prop.get_rect()
		var footprint: Rect2 = prop.get_meta("footprint")
		_check(bounds == footprint,"Scaled dressing used stale bounds")
		_check(bounds.size.x <= 53 and is_equal_approx(prop.global_scale.x,prop.global_scale.y),"Room transform enlarged/distorted small dressing")
		var floor_rect: Rect2 = prop.get_meta("supported_floor")
		_check(bounds.position.x >= floor_rect.position.x and bounds.end.x <= floor_rect.end.x,"Dressing extends beyond ledge")
		bounds.size.y = maxf(0,floor_rect.position.y-0.25-bounds.position.y)
		for solid in solids: _check(not bounds.intersects(solid),"Late wall/ceiling intersects dressing")

func _fixtures() -> void:
	var stage := Node2D.new(); root.add_child(stage)
	stage.position = Vector2(470,-410); stage.scale = Vector2(1.5,1.5)
	var ground := _fixture_solid(stage,Vector2(400,210),Vector2(800,20))
	var nodes: Array[Node] = [ground]
	var before := _collision_snapshot(nodes)
	var art := Dressing.install(stage,"fixture_cave",nodes)
	var floor_rect: Rect2 = Support.floors(nodes)[0]
	var count: int = art.clusters.size()
	_check(count >= 5,"Scaled fixture did not retain small grounded decoration")
	_fixture_clear(art,nodes)
	var first_id: int = art.clusters[0].get_instance_id()
	Dressing.install(stage,"fixture_cave",nodes)
	_check(art.clusters[0].get_instance_id() == first_id,"Unchanged terrain rebuilt decoration")
	var ceiling := _fixture_solid(stage,Vector2(400,184),Vector2(800,8))
	nodes.append(ceiling)
	Dressing.install(stage,"fixture_cave",nodes)
	var low_ground_count := 0
	for prop in art.clusters:
		if prop.get_meta("supported_floor") == floor_rect: low_ground_count += 1
	_check(low_ground_count < count,"Late low ceiling kept stale decoration on the original floor")
	_fixture_clear(art,nodes)
	ceiling.disabled = true
	Dressing.install(stage,"fixture_cave",nodes)
	_check(art.clusters.size() == count,"Disabled ceiling kept cleared floor empty")
	_fixture_clear(art,nodes)
	var wall := _fixture_solid(stage,Vector2(430,170),Vector2(30,180))
	nodes.append(wall); Dressing.install(stage,"fixture_cave",nodes)
	_fixture_clear(art,nodes)
	var one_way_pillar := _fixture_solid(stage,Vector2(150,70),Vector2(15,150))
	one_way_pillar.one_way_collision = true; nodes.append(one_way_pillar)
	Dressing.install(stage,"fixture_cave",nodes)
	for prop in art.crag_caps:
		_check(prop.get_meta("pillar_support") != one_way_pillar.global_transform*Rect2(-one_way_pillar.shape.size/2,one_way_pillar.shape.size),"One-way helper grew a fake solid crag")
	_fixture_clear(art,nodes)
	# A late facade can be much wider than the native 88-pixel reservation.
	var device := Node2D.new(); stage.add_child(device)
	device.global_position = art.clusters[0].get_meta("ground_contact") + Vector2(90,0)
	var sprite := preload("res://CorridorAtlas.gd").sprite("corridor_cave_clusters_v1",0,180)
	sprite.name = "FinishedDevice"; device.add_child(sprite)
	sprite.global_transform = Transform2D(0,Vector2.ONE*sprite.scale.x,0,device.global_position)
	Support.plant(sprite,sprite.get_meta("contact_row"),device.global_position.y)
	nodes.append(device); Dressing.install(stage,"fixture_cave",nodes)
	var reserved: Rect2 = (sprite.global_transform*sprite.get_rect()).grow(4)
	var hidden := 0
	for prop in art.clusters:
		if not prop.visible: hidden += 1
		else: _check(not prop.get_meta("footprint").intersects(reserved),"Late wide facade overlaps visible decoration")
	_check(hidden > 0,"Late wide facade failed to reserve its actual artwork")
	nodes.erase(device); device.free(); Dressing.install(stage,"fixture_cave",nodes)
	for prop in art.clusters: _check(prop.visible,"Removed device permanently erased decoration")
	_check(_collision_snapshot([ground]) == before,"Dressing refresh changed native ground")
	stage.free()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_corridor_clearance.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene = game
	for frame in 5: await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var totals := {"clusters":0,"lips":0,"caps":0,"lifts":0,"deck_only":0,"solid_overlap":0,"unsupported":0,"underestimated":0,"lift_overlap":0}
	var examples: Array = []
	for id in ["training_passage"] + Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for frame in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		var floors := Support.floors(nodes)
		var solids: Array[Rect2] = []
		for node in nodes:
			if node is CollisionShape2D and not node.disabled and node.shape is RectangleShape2D and node.get_parent() is StaticBody2D:
				if node.get_parent().is_in_group("breakable") or node.get_parent().is_in_group("enemy"): continue
				solids.append(node.global_transform * Rect2(-node.shape.size * 0.5,node.shape.size))
		var art := room.get_node("CorridorDressing")
		for prop in art.get_children():
			if not prop is Sprite2D or not prop.visible: continue
			var bounds: Rect2 = prop.global_transform * prop.get_rect()
			var support := Rect2()
			var kind := "caps"
			if prop.name.begins_with("GroundCluster"):
				kind = "clusters"
				var foot: Vector2 = prop.get_meta("ground_contact")
				for floor_rect in floors:
					if absf(floor_rect.position.y - (foot.y - 0.6)) < 0.1 and bounds.position.x >= floor_rect.position.x - 0.1 and bounds.end.x <= floor_rect.end.x + 0.1:
						support = floor_rect; break
				if not support.has_area() or bounds.position.x < support.position.x - 0.1 or bounds.end.x > support.end.x + 0.1:
					totals.unsupported += 1
					if examples.size() < 12: examples.append({"room":id,"prop":str(prop.name),"issue":"unsupported","bounds":str(room.global_transform.affine_inverse()*bounds)})
				var advertised: Rect2 = prop.get_meta("footprint")
				if bounds.position.y < advertised.position.y - 0.2 or bounds.position.x < advertised.position.x - 0.2 or bounds.end.x > advertised.end.x + 0.2:
					totals.underestimated += 1
				# Painted roots may enter the supporting surface by a pixel; that
				# intentional contact must not be confused with wall/ceiling overlap.
				bounds.size.y = maxf(0,(foot.y - 0.61) - bounds.position.y)
			elif prop.name.begins_with("CeilingLip"):
				kind = "lips"
				support = prop.get_meta("ceiling_support")
				_check(prop.get_meta("clearance_floor").position.y - bounds.end.y >= 95,"Low corridor lip: " + id)
			else:
				# A cap may intentionally enter its own narrow pillar.
				if prop.has_meta("pillar_support"): support = prop.get_meta("pillar_support")
				for solid in solids:
					if support.has_area(): break
					if solid.has_point(Vector2(bounds.get_center().x,bounds.get_center().y-5)) and solid.size.x <= 90 and solid.size.y >= 120:
						support = solid; break
			totals[kind] += 1
			for solid in solids:
				if solid == support: continue
				if bounds.grow(-0.2).intersects(solid):
					totals.solid_overlap += 1
					if examples.size() < 12: examples.append({"room":id,"prop":str(prop.name),"issue":"solid_overlap","bounds":str(room.global_transform.affine_inverse()*bounds),"solid":str(room.global_transform.affine_inverse()*solid)})
					break
		for node in nodes:
			if node is Sprite2D and node.name == "WinchHead" and node.get_parent().name == "LiftGantry":
				totals.lifts += 1
				if not node.visible:
					totals.deck_only += 1
					print("DECK ONLY HOIST ",id," ",node.get_parent().get_parent().name)
					continue
				var bounds: Rect2 = node.global_transform * node.get_rect()
				for solid in solids:
					if bounds.grow(-0.2).intersects(solid):
						totals.lift_overlap += 1
						print("HOIST CLEARANCE ISSUE ",id," actor=",str(node.get_parent().get_parent().name)," at=",room.to_local(node.get_parent().get_parent().global_position)," head=",room.global_transform.affine_inverse()*bounds," solid=",room.global_transform.affine_inverse()*solid)
						if examples.size() < 12: examples.append({"room":id,"prop":str(node.get_path()),"issue":"lift_overlap"})
						break
	print("CORRIDOR CLEARANCE TOTALS ",JSON.stringify(totals))
	print("CORRIDOR CLEARANCE EXAMPLES ",JSON.stringify(examples))
	_check(totals.solid_overlap == 0,"Corridor decoration intersects unrelated solid terrain: " + str(totals.solid_overlap))
	_check(totals.unsupported == 0,"Corridor decoration extends beyond its supporting floor: " + str(totals.unsupported))
	_check(totals.underestimated == 0,"Corridor placement uses undersized footprints: " + str(totals.underestimated))
	_check(totals.lift_overlap == 0,"Hoist head clips solid terrain: " + str(totals.lift_overlap))
	_check(totals.lifts >= 35 and totals.deck_only == 0,"Existing world hoist lost its complete clear gantry")
	_check(totals.clusters > 200 and totals.lips > 20,"Clearance filtering erased corridor decoration")
	_fixtures()
	game.free(); state.delete_save()
	print("CORRIDOR CLEARANCE TEST PASSED" if failures.is_empty() else "CORRIDOR CLEARANCE TEST FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
