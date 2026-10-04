extends "res://tests/gameplay_review_smoke.gd"

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_shaft_fall_recovery.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	state.set_current_room("sunken_shaft")
	for i in 7: await process_frame
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var room: Node2D=game.get_node("VerticalChamber")
	var p: Player=game.get_node("Player")
	var recovery:=game.get_node("WorldFallRecovery")
	for n in game.get_node("WorldPresentationFinish")._members(room):
		if n is StaticBody2D: n.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	p.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	await physics_frame
	var space:=p.get_world_2d().direct_space_state
	for x in range(-3390,820,10):
		var query:=PhysicsRayQueryParameters2D.create(room.global_position+Vector2(x,600),room.global_position+Vector2(x,1800),1,[p.get_rid()])
		_check(not space.intersect_ray(query).is_empty(),"Unsealed lower-world gap at x="+str(x))
	# Real moving player, at each point that used to fall through the west gap.
	for x in [-3380,-3350,-3310]:
		p.global_position=room.global_position+Vector2(x,640)
		p.velocity=Vector2.ZERO
		p.process_mode=Node.PROCESS_MODE_ALWAYS
		for tick in 40: await physics_frame
		p.process_mode=Node.PROCESS_MODE_DISABLED
		_check(p.is_on_floor() and p.position.y<room.position.y+716,"Player fell through patched west terminus")
		_check(recovery.is_safe(p.global_position),"Grounded west terminus rejected as safe")
	var safe:=p.global_position
	recovery.safe_positions["sunken_shaft"]=safe
	var health:=p.current_health
	var checkpoint:=p.respawn_position
	p.global_position=room.global_position+Vector2(-3350,2800)
	p.velocity=Vector2(0,1200)
	recovery.grace=0
	recovery._physics_process(0.1)
	_check(p.global_position.distance_to(safe)<1 and p.velocity==Vector2.ZERO,"Out-of-world recovery fails")
	_check(p.current_health==health and p.respawn_position==checkpoint,"Recovery healed or moved checkpoint")
	var count: int=recovery.recoveries
	p.set_test_flight(true,true)
	p.global_position=room.global_position+Vector2(-3350,2800)
	recovery.grace=0
	recovery._physics_process(0.1)
	_check(recovery.recoveries==count,"Safety prevents intentional debug flight")
	p.set_test_flight(false)
	_check(recovery.recover(),"Manual recovery after noclip failed")
	_check(not p.get_collision_exceptions().size(),"Recovery retained floor exceptions")
	# Lower ceilings must preserve normal ground passage and native jumps.
	for x in [-2380,-2250,-1470,-1380]:
		p.global_position=room.global_position+Vector2(x,636)
		p.velocity=Vector2.ZERO
		p.process_mode=Node.PROCESS_MODE_ALWAYS
		for tick in 12: await physics_frame
		_check(p.is_on_floor(),"Cannot stand under low ceiling at "+str(x))
		Input.action_press("ui_accept")
		await physics_frame
		Input.action_release("ui_accept")
		for tick in 60: await physics_frame
		_check(p.is_on_floor() and p.global_position.y<room.global_position.y+660,"Jump under lowered ceiling broke route")
		p.process_mode=Node.PROCESS_MODE_DISABLED
	game.free()
	state.delete_save()
	print("SHAFT FALL RECOVERY TEST PASSED" if failures.is_empty() else "SHAFT FALL RECOVERY TEST FAILED "+str(failures))
	quit(0 if failures.is_empty() else 1)
