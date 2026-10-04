extends "res://tests/gameplay_review_smoke.gd"
const Envelope := preload("res://WorldTerrainEnvelope.gd")

func _solid(room: Node2D, named: String, at: Vector2, size: Vector2, one_way := false) -> void:
	var body := StaticBody2D.new()
	body.name=named
	body.position=at
	var shape := CollisionShape2D.new()
	shape.shape=RectangleShape2D.new()
	shape.shape.size=size
	shape.one_way_collision=one_way
	body.add_child(shape)
	room.add_child(body)

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_terrain_envelope.json"
	state.start_new_game("normal")
	var room := Node2D.new()
	root.add_child(room)
	_solid(room,"MainGround",Vector2(200,300),Vector2(400,20))
	_solid(room,"UpperWalk",Vector2(200,100),Vector2(400,20))
	_solid(room,"FreePlatform",Vector2(700,180),Vector2(120,12))
	_solid(room,"LongBridge",Vector2(1100,160),Vector2(400,12))
	_solid(room,"OneWay",Vector2(1600,160),Vector2(400,12),true)
	_solid(room,"WestWall",Vector2(-20,20),Vector2(40,600))
	_solid(room,"EastWall",Vector2(1320,20),Vector2(40,600))
	var before := _collision_snapshot(room.find_children("*","",true,false))
	var art := Envelope.install(room,"sunken_shaft",room.find_children("*","",true,false))
	_check(art.foundations.size()==1,"Bridge/platform filled as main ground")
	_check(art.foundations[0].position.y==308 and art.foundations[0].size.x==400,"Foundation obscures lower route")
	_check(art.boundaries.size()==2,"Closed map side left empty")
	var closed_edges := 0
	for node in art.get_children():
		if not node is Polygon2D or node.get_meta("terrain_mass_kind","")!="OuterRockMass": continue
		var bounds := Rect2(node.polygon[0],Vector2.ZERO)
		for point in node.polygon: bounds = bounds.expand(point)
		_check(is_equal_approx(bounds.end.x,0) if bounds.get_center().x<0 else is_equal_approx(bounds.position.x,1300),"Background slit at physical outer wall")
		closed_edges += 1
	_check(closed_edges==2,"Both opaque side closures must be tested")
	_check(Envelope.install(room,"sunken_shaft",[])==art,"Envelope duplicated on revisit")
	_check(before==_collision_snapshot(room.find_children("*","",true,false)),"Envelope alters native terrain")
	_check(not art.is_processing(),"Static envelope has frame callbacks")
	room.free()
	state.delete_save()
	print("TERRAIN ENVELOPE TEST PASSED" if failures.is_empty() else "TERRAIN ENVELOPE TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
