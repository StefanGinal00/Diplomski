extends "res://tests/gameplay_review_smoke.gd"
const Support := preload("res://WorldSupport.gd")
const Placement := preload("res://RouteDressingPlacement.gd")
const ReliefLayer := preload("res://WorldRouteRelief.gd")

func _late_support_fixture() -> void:
	var stage := Node2D.new(); root.add_child(stage); stage.position = Vector2(-1300,500); stage.scale = Vector2(1.3,1.3)
	var body := StaticBody2D.new(); stage.add_child(body)
	var floor_shape := CollisionShape2D.new(); floor_shape.shape = RectangleShape2D.new(); floor_shape.shape.size = Vector2(1500,20); body.add_child(floor_shape)
	var nodes: Array[Node] = [floor_shape]
	var native := _collision_snapshot(nodes)
	var layer := ReliefLayer.install(stage,"fixture",nodes)
	_check(layer.patches.size()>=2,"Scaled fixture lacks relief")
	if layer.patches.size()<2: stage.free(); return
	for patch in layer.patches: _check(patch.global_scale.is_equal_approx(Vector2.ONE),"Scaled fixture distorts slopes")
	var first: Node2D = layer.patches[0]
	var wall := StaticBody2D.new(); stage.add_child(wall)
	wall.global_position = first.global_position+Vector2(100,-40)
	var wall_shape := CollisionShape2D.new(); wall_shape.shape = RectangleShape2D.new(); wall_shape.shape.size = Vector2(20,80); wall.add_child(wall_shape); nodes.append(wall_shape)
	ReliefLayer.install(stage,"fixture",nodes)
	await physics_frame
	_check(not first.visible and first.get_node("ReliefCollision").disabled,"Late wall leaves invisible/unsafe slope")
	_check(not first.has_meta("natural_mound_bounds"),"Retired slope leaves stale reservations")
	_check(_collision_snapshot([floor_shape])==native,"Relief mutated original support")
	floor_shape.disabled = true
	ReliefLayer.install(stage,"fixture",nodes); await physics_frame
	for patch in layer.patches: _check(not patch.visible and patch.get_node("ReliefCollision").disabled,"Removed support leaves floating solid relief")
	floor_shape.disabled = false
	ReliefLayer.install(stage,"fixture",nodes)
	for patch in layer.patches: _check(not patch.visible,"Re-entry grows a slope underneath the player")
	stage.free()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_route_relief_world.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false; game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player"); player.test_invincible = true; player.get_node("Camera2D").enabled = false
	var finish := game.get_node("WorldPresentationFinish")
	var total := 0; var dressed := 0; var traversed := 0; var room_count := 0
	var profiles := {}
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var layer: Node2D = room.get_node("RouteRelief")
		var nodes: Array[Node] = finish._members(room)
		var external: Array[Node] = []
		for node in nodes:
			if not layer.is_ancestor_of(node) and not node.has_meta("natural_mound_bounds"): external.append(node)
		var solids := Support.solids(external)
		var reserved := Placement.reservations(external)
		for patch in layer.patches:
			profiles[patch.plan.variant] = true
			_check(patch.visible and not patch.get_node("ReliefCollision").disabled,"Contour retired on unchanged re-entry: "+id)
			_check(patch.global_scale.is_equal_approx(Vector2.ONE),"Room transform distorts contour: "+id)
			_check(Placement.clear(patch.plan.clearance,solids,patch.support),"Relief removes jump headroom: "+id)
			_check(Placement.clear(patch.get_meta("natural_mound_bounds"),reserved),"Relief buries an interaction: "+id)
			_check(patch.global_position.x>=patch.support.position.x+110 and patch.global_position.x+patch.plan.width<=patch.support.end.x-110,"Relief changes a jump mouth: "+id)
			for plant in patch.plants:
				_check(absf(plant.global_position.y-patch.height_at(plant.global_position.x)-.8)<.01,"Slope decoration floats: "+id)
				_check(not plant.is_processing() and not plant.is_physics_processing(),"Slope plant runs callback")
				dressed += 1
			total += 1
		var count := nodes.size(); var visible: int = layer.patches.filter(func(p): return p.visible).size()
		finish.finish_room(id)
		_check(finish._members(room).size()==count and layer.patches.filter(func(p): return p.visible).size()==visible,"Relief re-entry is unstable: "+id)
		# One real route per eligible room, both directions, with real world
		# geometry active (only combat/hazard triggers disabled for isolation).
		if not layer.patches.is_empty():
			room_count += 1
			for node in nodes:
				if node is CollisionObject2D:
					node.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
					if node is Area2D or node.is_in_group("enemy") or node.is_in_group("breakable") or node.is_in_group("neutral_creature"):
						node.collision_layer = 0; node.collision_mask = 0
			var patch: Node2D = layer.patches[0]
			for direction in [-1.0,1.0]:
				player.process_mode = Node.PROCESS_MODE_DISABLED
				var from_x: float = patch.global_position.x+patch.plan.width+24 if direction<0 else patch.global_position.x-24
				var target_x: float = patch.global_position.x-16 if direction<0 else patch.global_position.x+patch.plan.width+16
				player.global_position = Vector2(from_x,patch.support.position.y-20); player.velocity = Vector2.ZERO; player.jump_buffer_remaining = 0
				player.process_mode = Node.PROCESS_MODE_ALWAYS
				for tick in 12: await physics_frame
				Input.action_press("ui_left" if direction<0 else "ui_right")
				for tick in 175:
					await physics_frame
					if (player.global_position.x-target_x)*direction>=0: break
				Input.action_release("ui_left"); Input.action_release("ui_right")
				_check((player.global_position.x-target_x)*direction>=0,"World relief blocks player: "+id)
				for tick in 10: await physics_frame
				_check(player.is_on_floor() and player.global_position.y<patch.support.position.y,"World relief loses support: "+id)
				traversed += 1
			player.process_mode = Node.PROCESS_MODE_DISABLED
		print("RELIEF_ROOM ",id," contours=",layer.patches.size())
	_check(total>=30 and room_count>=12,"Relief is too sparse to change the world routes")
	_check(profiles.size()==6,"Expanded terrain profiles are not used in actual rooms")
	print("RELIEF_WORLD contours=",total," rooms=",room_count," slope_plants=",dressed," real_walks=",traversed," profiles=",profiles.size())
	game.free(); await _late_support_fixture(); state.delete_save()
	if failures.is_empty(): print("ROUTE RELIEF WORLD TEST PASSED"); quit(0)
	else: print("ROUTE RELIEF WORLD TEST FAILED ",failures); quit(1)
