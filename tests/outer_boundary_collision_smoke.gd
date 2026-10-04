extends "res://tests/terrain_envelope_smoke.gd"
const Boundary := preload("res://WorldOuterBoundary.gd")

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_outer_boundary.json";state.start_new_game("normal")
	var room:=Node2D.new();room.position=Vector2(7200,-1900);root.add_child(room)
	_solid(room,"BaseFloor",Vector2(200,300),Vector2(400,20))
	_solid(room,"HighFloor",Vector2(200,-550),Vector2(400,20),true)
	_solid(room,"EastWall",Vector2(416,260),Vector2(32,220))
	_solid(room,"InteriorWall",Vector2(180,-100),Vector2(22,170))
	var members: Array[Node]=[];members.assign(room.find_children("*","",true,false))
	var floors:=preload("res://WorldSupport.gd").floors(members)
	var added:=Boundary.install(room,members,floors)
	_check(added.size()==1,"Boundary closure touched an interior pillar")
	var shape: CollisionShape2D=added[0].get_node("CollisionShape2D")
	var rect: Rect2=shape.global_transform*Rect2(-shape.shape.size/2,shape.shape.size)
	_check(rect.position.y<room.global_position.y-1000 and rect.end.y>room.global_position.y+600,"Wall fails to span highest/lowest routes")
	_check(not shape.one_way_collision,"Map wall remains one-way")
	_check(Boundary.install(room,members,floors).is_empty(),"Duplicate closure")
	var old_face:=Polygon2D.new();old_face.name="Visual"
	old_face.polygon=PackedVector2Array([Vector2(-16,-110),Vector2(16,-110),Vector2(16,110),Vector2(-16,110)])
	room.get_node("EastWall").add_child(old_face)
	members.assign(room.find_children("*","",true,false))
	var envelope:=preload("res://WorldTerrainEnvelope.gd").install(room,"echo_haven",members)
	_check(not old_face.visible and envelope.boundaries.size()==1,"Original tiled wall face overlays extended cliff")
	var actor:=CharacterBody2D.new();actor.collision_layer=0;actor.collision_mask=1
	var actor_shape:=CollisionShape2D.new();actor_shape.shape=RectangleShape2D.new();actor_shape.shape.size=Vector2(16,28)
	actor.add_child(actor_shape);root.add_child(actor)
	for y in [200,-120,-600,-1000]:
		actor.global_position=room.to_global(Vector2(375,y))
		await physics_frame;await physics_frame
		actor.move_and_collide(Vector2(150,0))
		_check(room.to_local(actor.global_position).x<393,"Actor crossed side wall above old cap at "+str(y))
	# Dash-sized and upward-diagonal movement still collides, without cheats.
	actor.global_position=room.to_global(Vector2(365,-320))
	await physics_frame
	actor.move_and_collide(Vector2(180,-130))
	_check(room.to_local(actor.global_position).x<393,"Diagonal jump crossed side mass")
	room.queue_free();await process_frame
	# Also collide against the actual Haven cliff above its authored short cap,
	# not just a synthetic wall. Existing interior street gaps remain open.
	state.set_current_room("echo_haven")
	var haven: Node2D=load("res://EchoHaven.tscn").instantiate()
	haven.position=Vector2(24000,-18000);root.add_child(haven)
	for tick in 4: await process_frame
	haven.process_mode=Node.PROCESS_MODE_DISABLED
	var haven_nodes: Array[Node]=[];haven_nodes.assign(haven.find_children("*","",true,false))
	for node in haven_nodes:
		if node is StaticBody2D: node.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	var real_closures:=Boundary.install(haven,haven_nodes,preload("res://WorldSupport.gd").floors(haven_nodes))
	var tested_haven_cliff:=false
	for body in real_closures:
		body.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		if body.name!=&"ClosedMapBoundaryEast": continue
		var col: CollisionShape2D=body.get_node("CollisionShape2D")
		var cliff: Rect2=col.global_transform*Rect2(-col.shape.size/2,col.shape.size)
		actor.global_position=Vector2(cliff.position.x-35,cliff.position.y+140)
		await physics_frame;await physics_frame
		var contact:=actor.move_and_collide(Vector2(150,-35))
		_check(contact!=null and contact.get_collider()==body,"Native Haven jump crosses upper side cliff")
		_check(actor.global_position.x<cliff.position.x-7.8,"Actor enters native exterior mass")
		tested_haven_cliff=true
	_check(tested_haven_cliff,"Native Haven outer cliff was not surveyed")
	actor.queue_free();haven.queue_free();state.delete_save()
	print("OUTER BOUNDARY COLLISION TEST ","PASSED" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
