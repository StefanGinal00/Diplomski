extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_echo_haven_suite_save.json"
	var haven: Node2D = load("res://EchoHaven.tscn").instantiate()
	root.add_child(haven)
	await process_frame
	_check(haven.get_node("Entry").is_in_group("echo_haven_entry"), "Haven entry marker missing")
	var door := haven.get_node("ReturnDoor")
	_check(door.target_marker_group == &"echo_haven_gate_return" and door.target_room_id == "echo_haven_outskirts", "Haven gate route is incorrect")
	_check(door._requirements_met(), "Haven return is not freely accessible")
	var lamp := haven.get_node("HavenLamp")
	_check(lamp.lamp_id == "echo_haven_lamp" and lamp.room_id == "echo_haven", "Haven lamp identity is incorrect")
	_check(haven.get_node("Floor/CollisionShape2D").shape.size.x >= 1100.0, "Haven walkway is too short")
	var residents: Array[Node] = []
	for child in haven.get_children():
		if child.is_in_group("town_resident"):
			residents.append(child)
	_check(residents.size() == 4, "Haven should have four ambient residents")
	var names: Dictionary = {}
	for resident in residents:
		_check(resident.is_in_group("friendly_npc"), "Haven resident cannot use shared dialogue")
		_check(resident.has_signal("interaction_requested"), "Haven resident has no interaction signal")
		_check(resident.dialogue_lines.size() >= 2, "Haven resident needs varied dialogue")
		_check(not names.has(resident.resident_name), "Haven resident names should be unique")
		names[resident.resident_name] = true
		_check(resident.position.y > 100.0 and resident.position.y < 155.0, "Haven resident is not on the walkway")
	for node in haven.find_children("*", "Node", true, false):
		_check(not node.is_in_group("enemy") and not node.is_in_group("boss"), "Haven is not peaceful")
	haven.queue_free()
	await process_frame
	if failures.is_empty():
		print("ECHO HAVEN TEST PASSED")
		quit(0)
	else:
		print("ECHO HAVEN TEST FAILED: ", failures)
		quit(1)
