extends "res://tests/gameplay_review_smoke.gd"
const VaultLayer := preload("res://RouteVaults.gd")
const EDGE_EPSILON := 0.025
var checked_masses := 0

func _solid(parent: Node2D, at: Vector2, size: Vector2) -> CollisionShape2D:
	var body := StaticBody2D.new(); parent.add_child(body); body.position = at
	var shape := CollisionShape2D.new(); shape.shape = RectangleShape2D.new(); shape.shape.size = size
	body.add_child(shape)
	return shape

func _inside_or_edge(point: Vector2, polygon: PackedVector2Array) -> bool:
	if Geometry2D.is_point_in_polygon(point,polygon): return true
	for index in polygon.size():
		var closest := Geometry2D.get_closest_point_to_segment(point,polygon[index],polygon[(index+1)%polygon.size()])
		if closest.distance_to(point)<=EDGE_EPSILON: return true
	return false

func _all_collision_snapshot(nodes: Array[Node]) -> Dictionary:
	var result := _collision_snapshot(nodes)
	for node in nodes:
		if node is CollisionPolygon2D:
			result[str(node.get_path())] = [node.transform,node.polygon.duplicate(),node.disabled,node.one_way_collision]
	return result

func _mass_check(vault: StaticBody2D, label: String) -> void:
	var mass := vault.get_node_or_null("TunnelMass") as Polygon2D
	var face := vault.get_node_or_null("VaultCore") as Polygon2D
	var collision := vault.get_node_or_null("VaultCollision") as CollisionPolygon2D
	_check(mass!=null and face!=null and collision!=null,"Missing tunnel mass, rim or collision: "+label)
	if mass==null or face==null or collision==null: return
	var plan: Dictionary = vault.get_meta("vault_plan")
	var visual_bounds: Rect2 = vault.get_meta("visual_bounds")
	_check(vault.visible and mass.visible and not collision.disabled,"Live tunnel has hidden paint or retired physics: "+label)
	_check(mass.get_parent()==vault and face.get_parent()==vault,"Tunnel paint escapes its lifecycle owner: "+label)
	_check(vault.global_scale.is_equal_approx(Vector2.ONE),"Room transform distorts tunnel geometry: "+label)
	_check(mass.color.is_equal_approx(Color("050a0d")) and is_equal_approx(mass.modulate.a,1.0) and is_equal_approx(mass.self_modulate.a,1.0),"Tunnel core is not opaque black rock: "+label)
	_check(mass.texture==null and mass.material==null,"Tunnel mass opacity depends on a texture or shader: "+label)
	_check(mass.z_index==-4 and face.z_index==-3 and mass.z_as_relative and face.z_as_relative,"Tunnel mass hides its painted edge: "+label)
	_check(not mass.is_processing() and not mass.is_physics_processing(),"Static tunnel fill runs per-frame callbacks: "+label)
	_check(not vault.get_parent().is_processing() and not vault.get_parent().is_physics_processing(),"Static tunnel layer runs per-frame callbacks: "+label)
	_check(mass.polygon==face.polygon and mass.transform.is_equal_approx(face.transform),"Tunnel backing does not match the existing inset rim: "+label)
	_check(Geometry2D.triangulate_polygon(mass.polygon).size()>0,"Invalid tunnel backing polygon: "+label)
	var world_collision := PackedVector2Array()
	for point in collision.polygon: world_collision.append(collision.to_global(point))
	for index in mass.polygon.size():
		var point: Vector2 = mass.to_global(mass.polygon[index])
		var next: Vector2 = mass.to_global(mass.polygon[(index+1)%mass.polygon.size()])
		_check(_inside_or_edge(point,world_collision) and _inside_or_edge((point+next)*0.5,world_collision),"Black roof leaks outside the physical vault: "+label)
		_check(visual_bounds.grow(EDGE_EPSILON).has_point(point),"Black roof extends beyond reserved visual bounds: "+label)
		_check(point.y>=plan.upper.position.y-EDGE_EPSILON,"Black roof obscures a route above its support: "+label)
		_check(point.x>=plan.upper.position.x+90-EDGE_EPSILON and point.x<=plan.upper.end.x-90+EDGE_EPSILON,"Black roof reaches a shaft or landing mouth: "+label)
		_check(plan.lower.position.y-point.y>=123-EDGE_EPSILON,"Black roof changes visual headroom: "+label)
	for child in vault.get_children():
		if child is Sprite2D and String(child.name).begins_with("Scallop"):
			_check(child.z_index==-2 and child.z_index>face.z_index,"Rock scallop is behind the black roof: "+label)
	checked_masses += 1

func _scaled_fixture(with_obstacle: bool) -> void:
	var stage := Node2D.new(); root.add_child(stage)
	stage.position = Vector2(-400,-700); stage.scale = Vector2(1.4,1.4)
	var upper := _solid(stage,Vector2(500,0),Vector2(1100,20))
	var lower := _solid(stage,Vector2(500,240),Vector2(1100,20))
	var nodes: Array[Node] = [upper,lower]
	var native := _all_collision_snapshot(nodes)
	var layer: Node2D = VaultLayer.install(stage,"fixture_cave",nodes)
	_check(not layer.vaults.is_empty(),"Scaled tunnel fixture did not create a safe vault")
	if layer.vaults.is_empty(): stage.free(); return
	var identities: Array[int] = []
	for vault in layer.vaults:
		_mass_check(vault,"scaled fixture")
		identities.append(vault.get_instance_id())
	var child_count: int = layer.find_children("*","",true,false).size()
	VaultLayer.install(stage,"fixture_cave",nodes)
	_check(layer.find_children("*","",true,false).size()==child_count,"Scaled fixture duplicates tunnel nodes on re-entry")
	_check(_all_collision_snapshot(nodes)==native,"Tunnel painting changes native support geometry")
	for index in layer.vaults.size(): _check(layer.vaults[index].get_instance_id()==identities[index],"Tunnel re-entry replaces its owner")
	var target: StaticBody2D = layer.vaults[0]
	if with_obstacle:
		var plan: Dictionary = target.get_meta("vault_plan")
		var wall := _solid(stage,stage.to_local(plan.volume.get_center()),Vector2(18,18)/stage.global_scale)
		nodes.append(wall)
		VaultLayer.install(stage,"fixture_cave",nodes)
		await physics_frame
		_check(not target.visible and target.get_node("VaultCollision").disabled,"Late obstacle leaves an unsafe opaque tunnel")
		_check(not target.get_node("TunnelMass").is_visible_in_tree(),"Late obstacle leaves a ghost black ceiling")
		nodes.erase(wall); wall.get_parent().free()
		VaultLayer.install(stage,"fixture_cave",nodes)
		_check(not target.visible and not target.get_node("TunnelMass").is_visible_in_tree(),"Removing an obstacle regrows a ceiling over a player")
		_check(_all_collision_snapshot(nodes)==native,"Obstacle retirement modifies native floor or upper support")
	else:
		upper.disabled = true
		VaultLayer.install(stage,"fixture_cave",nodes)
		await physics_frame
		for vault in layer.vaults:
			_check(not vault.visible and vault.get_node("VaultCollision").disabled,"Removed support leaves a floating solid tunnel")
			_check(not vault.get_node("TunnelMass").is_visible_in_tree(),"Removed support leaves a floating black roof")
			_check(vault.get_meta("hanging_anchors").is_empty(),"Retired tunnel leaves hanging decoration anchors")
		upper.disabled = false
		VaultLayer.install(stage,"fixture_cave",nodes)
		for vault in layer.vaults: _check(not vault.visible,"Re-enabled support regrows a retired tunnel")
	_check(layer.find_children("*","",true,false).size()==child_count,"Tunnel lifecycle adds orphaned paint nodes")
	stage.free()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_tunnel_vault_mass.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var rooms := 0
	var world_vaults := 0
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var layer: Node2D = room.get_node("RouteVaults")
		var nodes: Array[Node] = finish._members(room)
		var native := _all_collision_snapshot(nodes)
		var actors := {}
		for node in nodes:
			if node is Area2D or node is CharacterBody2D or node is Marker2D: actors[node] = node.global_transform
		var mass_ids: Array[int] = []
		for vault in layer.vaults:
			_mass_check(vault,"%s/%s"%[id,vault.name])
			world_vaults += 1
			var mass: Node = vault.get_node_or_null("TunnelMass")
			mass_ids.append(mass.get_instance_id() if mass!=null else 0)
		var count := nodes.size()
		finish.finish_room(id)
		_check(finish._members(room).size()==count,"World re-entry duplicates tunnel painting: "+id)
		_check(_all_collision_snapshot(finish._members(room))==native,"World re-entry changes geometry or collision: "+id)
		for actor in actors: _check(actor.global_transform==actors[actor],"Tunnel paint moves a player, NPC, door or arrival: "+id)
		for index in layer.vaults.size():
			var mass: Node = layer.vaults[index].get_node_or_null("TunnelMass")
			_check(mass!=null and mass.get_instance_id()==mass_ids[index],"World re-entry recreates tunnel fill: "+id)
		rooms += 1
		if not layer.vaults.is_empty(): print("TUNNEL_MASS_ROOM ",id," vaults=",layer.vaults.size())
	_check(rooms==39 and world_vaults>=20,"Tunnel backing is missing from live lowered ceilings")
	game.free()
	await _scaled_fixture(false)
	await _scaled_fixture(true)
	state.delete_save()
	print("TUNNEL_MASS_COVERAGE rooms=",rooms," live_vaults=",world_vaults," checked_masses=",checked_masses," lifecycle_fixtures=2")
	if failures.is_empty(): print("TUNNEL VAULT MASS TEST PASSED"); quit(0)
	else: print("TUNNEL VAULT MASS TEST FAILED ",failures); quit(1)
