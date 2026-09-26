extends "res://tests/ash_field_operations_smoke.gd"

const STAR_SCENES := ["StarfallOutskirts", "StarfallSilentGate", "StarfallMemoryVault", "StarfallRootedHall", "StarfallSoulCrucible", "StarfallSunlessPassage"]
const FIXED_SCRIPTS := ["res://ResonanceCache.gd", "res://StarfallRelay.gd", "res://ShaftLift.gd", "res://TidePulse.gd", "res://RoomDoor.gd", "res://Checkpoint.gd"]
var audited := 0


func _supported(actor: Node2D, room: Node2D) -> bool:
	# Exclude crates and actors as support: a stack over an open shaft is not terrain.
	for floor_node in room.find_children("*", "StaticBody2D", true, false):
		if floor_node.is_in_group("breakable"):
			continue
		var collision := floor_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.disabled or not collision.shape is RectangleShape2D:
			continue
		var shape_size := (collision.shape as RectangleShape2D).size
		if shape_size.x < 35 or shape_size.y > 40:
			continue
		var relative: Vector2 = floor_node.to_local(actor.global_position) - collision.position
		if absf(relative.x) <= shape_size.x * 0.5 - 10 and relative.y < -shape_size.y * 0.5 and relative.y >= -125:
			return true
	return false


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_star_support_save.json"
	state.start_new_game("normal")
	for scene_name in STAR_SCENES:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		# First population is deferred in standalone scenes; inspect initial placement.
		await process_frame
		for node in room.find_children("*", "Node2D", true, false):
			var script: Script = node.get_script()
			var targeted: bool = node is Marker2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature") or node.is_in_group("breakable") or (script != null and FIXED_SCRIPTS.has(script.resource_path))
			if not targeted:
				continue
			node.set_physics_process(false)
			audited += 1
			_check(_supported(node, room), "Unsupported Starfall placement: %s/%s at %s" % [scene_name, room.get_path_to(node), node.position])
		room.queue_free()
		await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("STARFALL POPULATION SUPPORT TEST PASSED: ", audited, " placements")
		quit(0)
	else:
		print("STARFALL POPULATION SUPPORT TEST FAILED: ", failures.size(), " / ", audited)
		quit(1)
