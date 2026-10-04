extends "res://tests/gameplay_review_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_testing_tools.json"
	state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	for i in 6: await process_frame
	game.get_node("UI").story_player.cancel()
	paused=false
	var panel:=game.get_node("TestingTools")
	var p: Player=game.get_node("Player")
	p.set_physics_process(false)
	_check(OS.is_debug_build(),"Testing suite requires debug executable")
	_check(not panel.is_open() and not p.test_flight and not p.test_invincible,"Cheats enabled by default")
	var key:=InputEventKey.new()
	key.keycode=KEY_F2
	key.pressed=true
	Input.parse_input_event(key)
	await process_frame
	key=key.duplicate()
	key.pressed=false
	Input.parse_input_event(key)
	_check(panel.is_open() and paused,"F2 panel does not own pause")
	_check(game.get_node("UI")._hud_menu_blocked(),"HUD can open through testing window")
	panel.toggles[0].button_pressed=true
	var hp:=p.current_health
	p.is_invulnerable=false
	p.take_damage(100)
	_check(p.current_health==hp and not p.is_dead,"Debug invincibility fails")
	panel.toggles[2].button_pressed=true
	_check(p.test_flight and p.test_noclip,"Noclip does not enable flight")
	panel.toggles[1].button_pressed=false
	_check(not p.test_flight and not p.test_noclip,"Disabling flight leaves noclip enabled")
	panel._restore()
	_check(p.current_health==p.max_health and p.current_mana==p.max_mana,"Test refill fails")
	panel._reset()
	_check(not p.test_invincible and not p.test_flight and p.velocity==Vector2.ZERO,"Reset leaves cheats active")
	panel.toggle()
	_check(not panel.is_open() and not paused,"Closing test tools does not resume")
	paused=true
	panel.toggle()
	_check(not panel.is_open() and paused,"Tools stole another menu's pause")
	paused=false
	p.set_test_flight(true)
	Input.action_press("ui_up")
	var before:=p.global_position
	p._physics_process(0.1)
	Input.action_release("ui_up")
	_check(p.velocity.y<0 and p.global_position.y<before.y,"Flight does not move upward")
	p.set_test_flight(false)
	state.capture_player(p)
	var save_text:=JSON.stringify(state._build_save_data())
	_check(not "test_flight" in save_text and not "test_invincible" in save_text and not "test_noclip" in save_text,"Cheat flags leaked into save")
	game.free()
	state.delete_save()
	print("TESTING TOOLS TEST PASSED" if failures.is_empty() else "TESTING TOOLS TEST FAILED "+str(failures))
	quit(0 if failures.is_empty() else 1)
