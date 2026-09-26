extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_room_door_interaction_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var door = game.get_node("CastellanThrone/StarfallDoor")
	state.set_current_room("ash_throne")
	var denials := [0]
	door.access_denied.connect(func(_message: String) -> void: denials[0] += 1)
	door._on_body_entered(player)
	_check(state.current_room_id == "ash_throne" and door.interaction_prompt.visible, "Touching a door changed rooms or did not show its prompt")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	door._on_input_event(game.get_viewport(), click, 0)
	_check(denials[0] == 1 and state.current_room_id == "ash_throne" and door.nearby_player == player, "Locked door did not wait for explicit input and explain the lock")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	door._on_input_event(game.get_viewport(), tap, 0)
	_check(denials[0] == 2 and state.current_room_id == "ash_throne", "Touchscreen tap did not respect the locked gate")
	state.defeated_bosses["ash_castellan"] = true
	state.add_item("castellan_seal")
	var interact := InputEventAction.new()
	interact.action = "interact"
	interact.pressed = true
	door._unhandled_input(interact)
	await create_timer(0.55).timeout
	_check(state.current_room_id == "starfall_citadel" and not door.interaction_prompt.visible, "Pressing Interact did not cross an unlocked door")
	var return_door = game.get_node("StarfallCitadel/GateDistrict/ThroneReturnDoor")
	return_door._on_body_entered(player)
	_check(state.current_room_id == "starfall_citadel", "Touching the return door crossed without a click")
	return_door._on_body_exited(player)
	return_door._on_input_event(game.get_viewport(), click, 0)
	_check(state.current_room_id == "starfall_citadel" and not return_door.interaction_prompt.visible, "A distant click activated the door")
	return_door._on_body_entered(player)
	return_door._on_input_event(game.get_viewport(), click, 0)
	await create_timer(0.55).timeout
	_check(state.current_room_id == "ash_throne", "Clicking the nearby return door did not work")
	var prologue_exit = game.get_node("ExitPortal")
	prologue_exit._on_body_entered(player)
	_check(state.current_room_id == "ash_throne" and prologue_exit.interaction_prompt.visible, "Prologue portal still transitions on touch")
	if not prologue_exit.is_unlocked:
		var portal_denials := [0]
		prologue_exit.access_denied.connect(func(_message: String) -> void: portal_denials[0] += 1)
		prologue_exit._on_input_event(game.get_viewport(), click, 0)
		_check(portal_denials[0] == 1 and state.current_room_id == "ash_throne", "Locked prologue portal did not wait for a click")
	prologue_exit.unlock_exit()
	var sentinel = game.get_node("SentinelBoss")
	var battle_denials := [0]
	prologue_exit.access_denied.connect(func(_message: String) -> void: battle_denials[0] += 1)
	sentinel.active = true
	prologue_exit.activate(player)
	_check(state.current_room_id == "ash_throne" and battle_denials[0] == 1, "Level exit bypassed an active boss encounter")
	sentinel.active = false
	prologue_exit._on_input_event(game.get_viewport(), click, 0)
	await create_timer(0.55).timeout
	_check(state.current_room_id == "sunken_shaft", "Clicking the open prologue portal did not enter the Shaft")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ROOM DOOR INTERACTION TEST PASSED")
		quit(0)
	else:
		print("ROOM DOOR INTERACTION TEST FAILED: ", failures)
		quit(1)
