extends "res://tests/shaft_guard_combat_smoke.gd"

func _surface(at: Vector2, size: Vector2) -> StaticBody2D:
	var body:=StaticBody2D.new()
	body.position=at
	var collision:=CollisionShape2D.new()
	collision.shape=RectangleShape2D.new()
	collision.shape.size=size
	body.add_child(collision)
	root.add_child(body)
	return body

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_pickup_motion.json"
	state.start_new_game("normal")
	player=_player()
	player.position=Vector2(-1000,-1000)
	player.get_node("Camera2D").enabled=false
	var ground:=_surface(Vector2(0,205),Vector2(600,10))
	for kind in ["GoldPickup","XPOrb","ItemPickup"]:
		var pickup: Area2D=load("res://%s.tscn"%kind).instantiate()
		pickup.position=Vector2(0,60)
		if kind=="ItemPickup": pickup.item_id="iron_fragment"
		root.add_child(pickup)
		for tick in 100: await physics_frame
		_check(is_instance_valid(pickup) and absf(pickup.position.y-193)<0.1,kind+" did not settle on thin floor")
		if is_instance_valid(pickup):
			_check(pickup.travel.grounded,kind+" failed to sleep on ground")
			var painted: Sprite2D=pickup.get_node("Visual/PaintedPickup")
			_check(painted.texture is AtlasTexture and painted.has_meta("atlas_frame"),kind+" not animated")
			var first: int=painted.get_meta("atlas_frame")
			pickup._process(0.31)
			_check(int(painted.get_meta("atlas_frame"))!=first,kind+" stuck animation")
			player.position=Vector2(62,184)
			for tick in 45: await physics_frame
			_check(not is_instance_valid(pickup),kind+" required jump to collect")
		player.position=Vector2(-1000,-1000)
	var wall:=_surface(Vector2(32,150),Vector2(8,100))
	var blocked: Area2D=load("res://ItemPickup.tscn").instantiate()
	blocked.position=Vector2(0,193)
	root.add_child(blocked)
	player.position=Vector2(64,184)
	for tick in 50: await physics_frame
	_check(is_instance_valid(blocked) and blocked.position.x==0 and not blocked.travel.attracted,"Magnet pulls loot through walls")
	player.is_dead=true
	wall.queue_free()
	for tick in 15: await physics_frame
	_check(is_instance_valid(blocked) and blocked.position.x==0,"Loot pursues dead player")
	player.is_dead=false
	for tick in 45: await physics_frame
	_check(not is_instance_valid(blocked),"Loot failed to resume collection after cover removed")
	player.position=Vector2(-1000,-1000)
	var unique: Area2D=load("res://ItemPickup.tscn").instantiate()
	unique.unique=true
	unique.item_id="test_movement_seal"
	unique.position=Vector2(150,60)
	root.add_child(unique)
	for tick in 45: await physics_frame
	_check(unique.position.y==60,"Authored unique object fell out of its puzzle")
	_check(preload("res://PickupCollectArt.gd").active_count==0,"Collection effects leaked")
	unique.free();ground.free();player.free()
	state.delete_save()
	print("PICKUP MOTION TEST PASSED" if failures.is_empty() else "PICKUP MOTION TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
