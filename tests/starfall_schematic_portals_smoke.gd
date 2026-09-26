extends SceneTree

const PREVIEW := preload("res://tests/starfall_schematic_fixture.gd")
const ROOMS := ["StarfallOutskirts", "StarfallSilentGate", "StarfallMemoryVault", "StarfallRootedHall", "StarfallSoulCrucible", "StarfallSunlessPassage"]
const ARRIVALS := ["Entry", "RampartsReturn", "SilentGateReturn", "VaultReturn", "RootShortcutReturn", "RootedReturn", "ShortcutReturn", "CourtReturn", "SunlessReturn", "ThroneReturn"]
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _anchors(room: Node) -> Dictionary:
	var result := {}
	for node in room.get_children():
		if node is Marker2D or node.is_in_group("room_door"):
			result[String(node.name)] = node.position
	return result


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_schematic_portals_save.json"
	state.start_new_game("normal")
	var checked := 0
	var arrivals_checked := 0
	for scene_name in ROOMS:
		var live: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		live.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(live)
		await process_frame
		var expected := _anchors(live)
		var preview: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		preview.get_node("ExpandedRoute").set_script(PREVIEW)
		preview.process_mode = Node.PROCESS_MODE_DISABLED
		# Preserve the authored room name: automatic duplicate-name renaming
		# would bypass the production room-profile lookup entirely.
		var preview_holder := Node2D.new()
		root.add_child(preview_holder)
		preview_holder.add_child(preview)
		await process_frame
		var actual := _anchors(preview)
		for key in expected:
			# Compare doors and their named arrival markers, not unrelated puzzle
			# markers relocated only during the full gameplay population pass.
			var node := live.get_node(NodePath(key))
			if node is Marker2D and key in ARRIVALS:
				_check(actual[key].is_equal_approx(expected[key]), scene_name + "/" + key + " preview arrival differs from live")
				arrivals_checked += 1
			if not node.is_in_group("room_door"):
				continue
			_check(actual[key].is_equal_approx(expected[key]), scene_name + "/" + key + " preview portal differs from live")
			checked += 1
		var route := preview.get_node("ExpandedRoute")
		for tier in range(route.plan["levels"].size()):
			for ratio in [0.03, 0.5, 0.94]:
				var point: Vector2 = route._portal_anchor(tier, ratio)
				var live_point: Vector2 = live.get_node("ExpandedRoute")._portal_anchor(tier, ratio)
				_check(point.is_equal_approx(live_point), scene_name + " preview support differs from live floor")
		_check(route.generated.has_node("TopologyRoom0"), "Did not exercise schematic branch")
		_check(not route.generated.has_node("Overlook1A"), "Schematic built the complete live terrain")
		live.queue_free()
		preview_holder.queue_free()
		await process_frame
	_check(checked == 15, "Review Starfall door coverage: " + str(checked))
	_check(arrivals_checked == 15, "Review Starfall arrival coverage: " + str(arrivals_checked))
	state.delete_save()
	if failures.is_empty():
		print("STARFALL SCHEMATIC PORTALS TEST PASSED: six previews, 15 doors, 15 arrivals, 126 supported anchors matching live terrain")
		quit(0)
	else:
		quit(1)
