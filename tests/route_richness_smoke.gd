extends "res://tests/gameplay_review_smoke.gd"
const Support := preload("res://WorldSupport.gd")
const Placement := preload("res://RouteDressingPlacement.gd")
const Atlas := preload("res://RouteDressingAtlas.gd")
const Dressing := preload("res://WorldPathDressing.gd")

func _solid(parent: Node2D, at: Vector2, size: Vector2) -> CollisionShape2D:
	var body := StaticBody2D.new(); parent.add_child(body); body.position = at
	var shape := CollisionShape2D.new(); shape.shape = RectangleShape2D.new(); shape.shape.size = size
	body.add_child(shape); return shape

func _fixture_clear(art: Node2D, nodes: Array[Node]) -> void:
	for prop in art.details:
		if prop.kind != "floor" or not prop.visible: continue
		var bounds: Rect2 = prop.art.global_transform*prop.art.get_rect()
		_check(bounds.is_equal_approx(prop.footprint),"Scaled fixture uses stale artwork bounds")
		_check(bounds.size.x <= 106 and is_equal_approx(prop.global_scale.x,prop.global_scale.y),"Room transform distorts route detail")
		bounds.size.y = maxf(0,prop.support.position.y-0.25-bounds.position.y)
		_check(Placement.clear(bounds,Support.solids(nodes)),"Late solid intersects route detail")

func _fixtures() -> void:
	var stage := Node2D.new(); root.add_child(stage); stage.position = Vector2(-600,820); stage.scale = Vector2(1.5,1.5)
	var ground := _solid(stage,Vector2(400,210),Vector2(800,20))
	var nodes: Array[Node] = [ground]
	var native := _collision_snapshot(nodes)
	var art := Dressing.install(stage,"fixture_cave",nodes)
	var total: int = art.details.size()
	_check(total > 8,"Scaled fixture lacks dense ground bands")
	_fixture_clear(art,nodes)
	var first_id: int = art.details[0].get_instance_id()
	Dressing.install(stage,"fixture_cave",nodes)
	_check(art.details[0].get_instance_id()==first_id,"Stable fixture recreated dressing")
	var wall := _solid(stage,Vector2(400,170),Vector2(40,140)); nodes.append(wall)
	Dressing.install(stage,"fixture_cave",nodes); _fixture_clear(art,nodes)
	_check(art.details.size()<total,"Late wall did not clear decoration")
	wall.disabled = true; Dressing.install(stage,"fixture_cave",nodes)
	_check(art.details.size()==total,"Disabled wall left a permanent decor gap")
	var device := Node2D.new(); stage.add_child(device)
	device.global_position = art.details[0].global_position
	var face := Sprite2D.new(); face.name = "FinishedDevice"; face.texture = Atlas.texture("route_cave_floor_v1",0)
	device.add_child(face); face.scale = Vector2.ONE*180/face.texture.get_width()
	face.position.y = -15; nodes.append(device)
	Dressing.install(stage,"fixture_cave",nodes)
	var hidden := 0
	for prop in art.details:
		if not prop.visible: hidden += 1
		else: _check(Placement.clear(prop.footprint,Placement.reservations(nodes)),"Late device not respected")
	_check(hidden>0,"Late interaction did not clear its visible footprint")
	nodes.erase(device); device.free(); Dressing.install(stage,"fixture_cave",nodes)
	for prop in art.details: _check(prop.visible,"Removed device left hidden route decorations")
	_check(_collision_snapshot([ground])==native,"Non-solid decoration changed fixture floor")
	stage.free()
	var vault_stage := Node2D.new(); root.add_child(vault_stage); vault_stage.position = Vector2(-400,-700); vault_stage.scale = Vector2(1.4,1.4)
	var upper := _solid(vault_stage,Vector2(500,0),Vector2(1100,20))
	var lower := _solid(vault_stage,Vector2(500,240),Vector2(1100,20))
	var vault_nodes: Array[Node] = [upper,lower]
	var vault_native := _collision_snapshot(vault_nodes)
	var vaults := preload("res://RouteVaults.gd").install(vault_stage,"fixture_cave",vault_nodes)
	_check(not vaults.vaults.is_empty(),"Safe fixture did not lower its ceiling")
	_check(_collision_snapshot(vault_nodes)==vault_native,"Vaults mutated native support geometry")
	for vault in vaults.vaults:
		_check(vault.global_scale.is_equal_approx(Vector2.ONE),"Scaled room distorts vault physics")
		var bounds: Rect2 = vault.get_meta("visual_bounds")
		for child in vault.get_children():
			if child is Sprite2D:
				var actual: Rect2 = child.global_transform*child.get_rect()
				_check(bounds.grow(0.1).encloses(actual),"Vault module escapes reserved mass")
	upper.disabled = true
	preload("res://RouteVaults.gd").install(vault_stage,"fixture_cave",vault_nodes)
	await physics_frame
	for vault in vaults.vaults:
		_check(not vault.visible and vault.get_node("VaultCollision").disabled,"Removed support leaves floating solid ceiling")
	upper.disabled = false
	preload("res://RouteVaults.gd").install(vault_stage,"fixture_cave",vault_nodes)
	for vault in vaults.vaults: _check(not vault.visible,"Re-entry grows a retired ceiling over the player")
	vault_stage.free()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_route_richness_smoke.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene = game
	for frame in 5: await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var totals := {"rooms":0,"floor":0,"hanging":0,"foreground":0,"vaults":0,"animated":0,"understory":0,"seeps":0}
	var variants := {}
	var source_variants := {}
	var texture_bytes := 0
	for sheet in Atlas.DATA:
		var texture: Texture2D = Atlas.texture(sheet,0).atlas
		var pixels := texture.get_image()
		_check(texture.get_width()<=1024 and pixels.has_mipmaps(),"Unbudgeted/missing mipmapped route texture: "+sheet)
		texture_bytes += pixels.get_data_size()
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for frame in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		var native := _collision_snapshot(nodes)
		var solids := Support.solids(nodes)
		var art: Node2D = room.get_node("PathDressing")
		var vaults: Node2D = room.get_node("RouteVaults")
		var reserved := Placement.reservations(nodes)
		var room_floor := 0
		for prop in art.details:
			if not prop.visible: continue
			var bounds: Rect2 = prop.art.global_transform*prop.art.get_rect()
			_check(bounds.is_equal_approx(prop.footprint),"Stale actual bounds: "+id)
			_check(is_equal_approx(prop.global_scale.x,prop.global_scale.y),"Stretched route decoration: "+id)
			_check(not prop.is_processing() and not prop.is_physics_processing(),"Per-object idle animation: "+id)
			_check(Placement.clear(bounds,reserved),"Interaction obscured: "+id)
			variants["%s/%s/%s"%[prop.family,prop.kind,prop.variant]] = true
			source_variants["%s/%s/%s"%[prop.family,"floor" if prop.kind=="floor" else "ceiling",prop.variant]]=true
			if prop.has_meta("ambient_motion"): totals.animated += 1
			if prop.has_meta("route_understory"):
				totals.understory += 1
				_check(prop.variant==5 and prop.has_meta("player_reactive"),"New understory is inert")
			if prop.kind=="floor" and prop.variant==5: _check(prop.has_meta("player_reactive"),"Rear soft foliage is not reactive")
			if prop.kind == "floor":
				room_floor += 1; totals.floor += 1
				if prop.z_index > 0: totals.foreground += 1
				_check(bounds.size.y <= (15.01 if prop.z_index > 0 else 30.01),"Oversized route detail: "+id)
				_check(bounds.position.x >= prop.support.position.x and bounds.end.x <= prop.support.end.x,"Unsupported ledge detail: "+id)
				var sheet := "route_%s_floor_v1"%prop.family
				var contact: float = Atlas.contact(sheet,prop.variant,false) if prop.town_family.is_empty() else preload("res://TownVergeAtlas.gd").contact(prop.town_family,prop.variant)
				var foot: Vector2 = prop.art.to_global(Vector2(0,prop.art.get_rect().position.y+contact))
				_check(absf(foot.y-prop.support.position.y-0.65)<0.01,"Floating route detail: "+id)
				bounds.size.y = maxf(0,prop.support.position.y-0.25-bounds.position.y)
				_check(Placement.clear(bounds,solids),"Route art inside solid: "+id)
			else:
				totals.hanging += 1
				if not prop.has_meta("vault_detail"): _check(Placement.clear(bounds,solids,prop.support),"Hanging art in unrelated solid: "+id)
		_check(room_floor > 0,"No new grounded route enrichment: "+id)
		_check(art.seeps.size()<=12,"Unbounded local seep sources")
		for seep in art.seeps:
			if not seep.visible: continue
			totals.seeps += 1
			_check(seep.source in art.details and seep.source.kind=="hanging","Drop has no actual hanging source")
			_check(seep.global_scale.is_equal_approx(Vector2.ONE),"Room scale distorts drops")
			_check(is_equal_approx(seep.global_position.y+seep.fall_distance,seep.support.position.y),"Drop misses first floor")
			_check(not seep.is_processing() and not seep.is_physics_processing(),"Drop runs a private callback")
			var probe: Rect2 = seep.footprint; probe.size.y -= 1.25
			_check(Placement.clear(probe,solids) and Placement.clear(probe,reserved),"Drop passes through solid/interaction: %s %s"%[id,probe])
			for sample in 40:
				seep.animate(sample*.1)
				_check(seep.drop_height()>=0 and seep.drop_height()<=seep.fall_distance,"Drop escapes its traced span")
			seep.rest(); _check(seep.cycle==-1,"Offscreen drop remains active")
		for vault in vaults.vaults:
			totals.vaults += 1
			_check(vault.visible and not vault.get_node("VaultCollision").disabled,"Valid vault retires on normal re-entry")
			var plan: Dictionary = vault.get_meta("vault_plan")
			var bounds: Rect2 = vault.get_meta("visual_bounds")
			_check(plan.lower.position.y-bounds.end.y >= 123,"Lowered vault lacks visual clearance: "+id)
			var collision: CollisionPolygon2D = vault.get_node("VaultCollision")
			for point in collision.polygon: _check(plan.lower.position.y-collision.to_global(point).y>=130,"Lowered vault obstructs normal jump: "+id)
			_check(bounds.position.x >= plan.upper.position.x+90 and bounds.end.x <= plan.upper.end.x-90,"Vault reaches a shaft mouth: "+id)
			_check(Geometry2D.triangulate_polygon(vault.get_node("VaultCollision").polygon).size()>0,"Invalid vault collision")
			variants["%s/cap/%s"%[plan.family,plan.variant]] = true
			print("VAULT_SITE ",id," ",room.to_local(Vector2(bounds.get_center().x,plan.lower.position.y-25)))
		var count := nodes.size()
		finish.finish_room(id)
		_check(finish._members(room).size()==count,"Re-entry duplicates route dressing: "+id)
		_check(_collision_snapshot(finish._members(room))==native,"Re-entry changes collision: "+id)
		finish.ambience.set_low_quality(true)
		_check(finish.ambience.active.size()<=8,"Low-cost wind budget exceeded")
		finish.ambience.set_low_quality(false)
		_check(finish.ambience.active.size()<=18,"Desktop wind budget exceeded")
		totals.rooms += 1
		print("ROUTE_ROOM ",id," floor=",room_floor," hanging=",art.details.size()-room_floor," vaults=",vaults.vaults.size())
	print("ROUTE_RICHNESS ",JSON.stringify(totals)," variants=",variants.size()," source_cutouts=",source_variants.size()," texture_bytes=",texture_bytes)
	_check(source_variants.size()==48,"Some of the 48 new cutouts are unused")
	_check(totals.rooms==39 and totals.floor>1000 and totals.hanging>150 and totals.vaults>5,"Incomplete world enrichment")
	_check(totals.understory>500 and totals.seeps>50 and totals.vaults>12,"Living route expansion is missing")
	await _fixtures()
	game.free(); state.delete_save()
	if failures.is_empty(): print("ROUTE RICHNESS TEST PASSED"); quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
