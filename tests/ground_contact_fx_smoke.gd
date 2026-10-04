extends "res://tests/pickup_motion_smoke.gd"
const ContactFx := preload("res://GroundContactFx.gd")

func _ticks(fx: Node2D,count: int) -> void:
	for tick in count:
		await physics_frame; fx.track(player,1.0/60,"cave")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ground_contact_fx.json"; state.start_new_game("normal")
	player = _player(); player.get_node("Camera2D").enabled = false; player.test_invincible = true
	var ground := _surface(Vector2(0,310),Vector2(1200,20))
	var stage := Node2D.new(); stage.position = Vector2(400,70); root.add_child(stage)
	var fx := ContactFx.new(); stage.add_child(fx)
	_check(fx.global_transform.is_equal_approx(Transform2D.IDENTITY),"Dust inherits translated room origin")
	_check(not fx.is_processing() and not fx.is_physics_processing(),"FX runs outside shared ambience tick")
	player.position = Vector2(-180,278); player.velocity = Vector2.ZERO; player.set_physics_process(true)
	await _ticks(fx,90)
	_check(fx.step_events==0 and fx.landing_events==0 and fx.grains.is_empty() and fx.puffs.is_empty(),"Idle/shallow spawn creates a dust fountain")
	Input.action_press("ui_right"); await _ticks(fx,90); Input.action_release("ui_right")
	_check(fx.step_events>=7 and fx.step_events<=15,"Walking stride dust is missing or spams every tick")
	_check(absf(fx.last_contact.position.y-300)<.1,"Footsteps detach from real floor")
	await _ticks(fx,20)
	var stopped := fx.step_events; await _ticks(fx,90)
	_check(fx.step_events==stopped and fx.grains.is_empty() and fx.puffs.is_empty(),"Dust continues when player stops")
	var landings := fx.landing_events
	player.jump_buffer_remaining = .12; await _ticks(fx,85)
	_check(fx.landing_events==landings+1,"A real jump should have one landing burst")
	# A sloping support uses the real ray intersection and its material, not
	# the old rectangular floor below it or the biome fallback colour.
	player.set_physics_process(false)
	var slope := preload("res://WalkableRouteRelief.gd").new(); root.add_child(slope)
	slope.configure({"floor":Rect2(-600,300,1200,20),"at":Vector2(-140,300),"width":280.0,"rise":30.0,"variant":1,"material":"shale","family":"mine"},ground.get_child(0))
	player.position = Vector2(-30,slope.height_at(-30)-25); player.velocity = Vector2.ZERO; player.set_physics_process(true)
	fx.clear(); await _ticks(fx,20)
	var contact: Dictionary = fx._support(player,"ash")
	_check(not contact.is_empty() and contact.material=="shale","Ground material fallback overrides actual slope")
	_check(absf(contact.position.y-slope.height_at(player.position.x))<.15,"Dust floats above slope or originates inside it")
	_check(absf(contact.normal.x)>.01,"Slope contact normal lost")
	Input.action_press("ui_left"); await _ticks(fx,65); Input.action_release("ui_left")
	await _ticks(fx,20)
	# Moving with a carrier/teleport without walking is not a footstep.
	player.set_physics_process(false); player.velocity = Vector2.ZERO; fx.clear(); fx.track(player,1.0/60,"cave")
	stopped = fx.step_events
	for tick in 50: player.position.x += 1; fx.track(player,1.0/60,"cave")
	_check(fx.step_events==stopped,"Passive platform transport emits steps")
	fx.emit_contact(player.position,Vector2.UP,"moss",100,1,true)
	player.position.x += 900; fx.track(player,1.0/60,"cave")
	_check(fx.grains.is_empty() and fx.puffs.is_empty() and not fx.sampled,"Teleport leaves a trail of effects")
	for mode in ["is_dead","test_flight","test_noclip"]:
		fx.emit_contact(Vector2.ZERO,Vector2.UP,"moss",100,1,true)
		player.set(mode,true); fx.track(player,1.0/60,"cave")
		_check(fx.grains.is_empty() and fx.puffs.is_empty(),"FX remains active during "+mode); player.set(mode,false)
	for material in ContactFx.COLORS:
		fx.clear(); fx.emit_contact(Vector2.ZERO,Vector2.UP,material,100,1,true)
		_check(fx.grains[0].color==ContactFx.COLORS[material],"Material dust palette mismatch")
		if material in ["iron","timber"]: _check(fx.grains.size()<=2,"Manufactured floor emits a rubble explosion")
	for tick in 80: fx.emit_contact(Vector2.ZERO,Vector2.UP,"moss",100,1,true)
	_check(fx.grains.size()==40,"Full quality pool limit exceeded")
	fx.set_low_quality(true); _check(fx.grains.size()==12,"Low quality pool not trimmed")
	for tick in 100: fx.advance(1.0/60)
	_check(fx.grains.is_empty(),"Contact grains never expire")
	_check(fx.find_children("*","CollisionObject2D",true,false).is_empty(),"Cosmetic FX creates colliders")
	slope.free(); ground.free(); stage.free(); player.free(); state.delete_save()
	print("GROUND CONTACT FX TEST PASSED: real steps, landing, slope contacts, six materials, silence/warp/death guards, 40/12 pool" if failures.is_empty() else "GROUND CONTACT FX TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
