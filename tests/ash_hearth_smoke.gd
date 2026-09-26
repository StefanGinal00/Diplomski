extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_ash_hearth_suite_save.json"
	var hearth: Node2D = load("res://CinderHearth.tscn").instantiate()
	root.add_child(hearth)
	await process_frame
	_check(hearth.get_node("Entry").is_in_group("ash_hearth_entry"), "Cinder Hearth entry marker missing")
	var door := hearth.get_node("ReturnDoor")
	_check(door.target_marker_group == &"ash_hearth_gate_return" and door.target_room_id == "ash_hearth_outskirts", "Cinder Hearth gate route is incorrect")
	_check(door._requirements_met(), "Cinder Hearth return should be freely accessible")
	var lamp := hearth.get_node("HearthLamp")
	_check(lamp.lamp_id == "ash_hearth_lamp" and lamp.room_id == "ash_hearth", "Cinder Hearth lamp identity is incorrect")
	_check(hearth.get_node("Floor/CollisionShape2D").shape.size.x >= 1100.0, "Cinder Hearth walkway is too short")
	var residents: Array[Node] = []
	var services: Array[Node] = []
	for child in hearth.get_children():
		if child.is_in_group("town_resident"):
			residents.append(child)
		if child.is_in_group("town_service"):
			services.append(child)
	_check(residents.size() == 5, "Cinder Hearth should have five residents including the gate watch")
	_check(services.size() == 2, "Cinder Hearth should have a trader and an anvil")
	var names: Dictionary = {}
	for resident in residents:
		_check(resident.is_in_group("friendly_npc"), "Resident cannot use shared dialogue")
		_check(resident.has_signal("interaction_requested"), "Resident has no interaction signal")
		_check(resident.dialogue_lines.size() >= 2, "Resident needs varied dialogue")
		_check(not names.has(resident.resident_name), "Resident names should be unique")
		names[resident.resident_name] = true
		_check(resident.position.y > 330.0 and resident.position.y < 380.0, "Resident is not on the walkway")
	var service_kinds: Dictionary = {}
	for service in services:
		_check(service.has_signal("interaction_requested"), "Town service has no interaction signal")
		_check(not service_kinds.has(service.service_kind), "Town services should have distinct purposes")
		service_kinds[service.service_kind] = service
	_check(service_kinds.has("shop") and service_kinds.has("anvil"), "Trader or anvil is missing")
	if service_kinds.has("shop"):
		_check(service_kinds["shop"].service_id == "ash_haven_shop", "Town trader has incorrect stock identity")
	for node in hearth.find_children("*", "Node", true, false):
		_check(not node.is_in_group("enemy") and not node.is_in_group("boss"), "Cinder Hearth is not peaceful")
	hearth.queue_free()
	await process_frame
	if failures.is_empty():
		print("ASH HEARTH TEST PASSED")
		quit(0)
	else:
		print("ASH HEARTH TEST FAILED: ", failures)
		quit(1)
