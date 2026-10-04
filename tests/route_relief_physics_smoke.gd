extends "res://tests/pickup_motion_smoke.gd"
const Relief := preload("res://WalkableRouteRelief.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_route_relief_physics.json"; state.start_new_game("normal")
	player = _player(); player.test_invincible = true; player.get_node("Camera2D").enabled = false
	var ground := _surface(Vector2(0,310),Vector2(1200,20))
	var native := ground.get_child(0) as CollisionShape2D
	var runs := 0
	for variant in Relief.PROFILES.size():
		var relief := Relief.new(); root.add_child(relief)
		relief.configure({"floor":Rect2(-600,300,1200,20),"at":Vector2(-140,300),"width":280.0,"rise":30.0,"variant":variant,"material":"moss","family":"cave"},native)
		_check(Geometry2D.triangulate_polygon(relief.get_node("ReliefCollision").polygon).size()>0,"Invalid contour polygon")
		_check(relief.surface[0].y==0 and relief.surface[-1].y==0,"Terrain endpoint is a step")
		for i in range(1,relief.surface.size()):
			_check(absf((relief.surface[i].y-relief.surface[i-1].y)/(relief.surface[i].x-relief.surface[i-1].x))<=.551,"Relief slope exceeds safe walking angle")
		for crouched in [false,true]:
			for side in [-1.0,1.0]:
				player.set_physics_process(true); player.position = Vector2(-182*side,278); player.velocity = Vector2.ZERO
				for tick in 12: await physics_frame
				if crouched: Input.action_press("ui_down")
				Input.action_press("ui_right" if side>0 else "ui_left")
				var highest := player.position.y; var airborne := 0
				for tick in (340 if crouched else 155):
					await physics_frame
					highest = minf(highest,player.position.y)
					if not player.is_on_floor(): airborne += 1
				Input.action_release("ui_right"); Input.action_release("ui_left"); Input.action_release("ui_down")
				_check(player.position.x*side>180,"Real player stuck on contour %d crouch=%s side=%s"%[variant,crouched,side])
				_check(highest<270,"Player did not follow raised collision")
				_check(airborne<=2,"Downhill floor contact flickers: %d frames"%airborne)
				runs += 1
		for side in [-1.0,1.0]:
			player.position = Vector2(-138*side,278); player.velocity = Vector2.ZERO
			for tick in 12: await physics_frame
			var start_x := player.position.x
			player.dash_unlocked = true; player.current_mana = player.max_mana
			player.dash_cooldown_remaining = 0; player.facing_direction = side
			player.try_dash()
			for tick in 10: await physics_frame
			_check((player.position.x-start_x)*side>40,"Dash catches on uphill contour")
			for tick in 15: await physics_frame
		# Jump detaches cleanly from a sloped crest and returns onto it.
		player.position = Vector2(-40,relief.height_at(-40)-25); player.velocity = Vector2.ZERO
		for tick in 15: await physics_frame
		var takeoff := player.position.y; var apex := takeoff
		player.jump_buffer_remaining = .12
		for tick in 85: await physics_frame; apex = minf(apex,player.position.y)
		_check(takeoff-apex>75 and player.is_on_floor(),"Floor snap prevents jump/landing on slope")
		player.set_physics_process(false); player.position = Vector2(1000,-1000)
		for kind in ["GoldPickup","XPOrb","ItemPickup"]:
			var pickup: Area2D = load("res://%s.tscn"%kind).instantiate()
			pickup.position = Vector2(-40,relief.height_at(-40)-70); root.add_child(pickup)
			for tick in 100: await physics_frame
			_check(is_instance_valid(pickup) and pickup.travel.grounded,"Loot fails to settle on slope: "+kind)
			if is_instance_valid(pickup):
				_check(absf(pickup.position.y+7-relief.height_at(-40))<.2,"Loot rests inside/above new terrain: "+kind)
				pickup.free()
		relief.queue_free(); await physics_frame
	ground.free(); player.free(); state.delete_save()
	print("ROUTE RELIEF PHYSICS TEST PASSED: %d bidirectional standing/crouching walks, %d profiles with dash/jump/loot checks"%[runs,Relief.PROFILES.size()] if failures.is_empty() else "ROUTE RELIEF PHYSICS TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
