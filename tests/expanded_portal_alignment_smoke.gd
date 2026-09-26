extends SceneTree

var failures: Array[String] = []

const ROOMS := {
	"EchoGrotto": ["LongTraversal", 9],
	"EchoGallery": ["LongTraversal", 9],
	"PrismArchive": ["LongTraversal", 9],
	"TideWell": ["LongTraversal", 13],
	"EchoNest": ["LongTraversal", 9],
	"CrystalCauseway": ["LongTraversal", 9],
	"UndertowVault": ["LongTraversal", 9],
	"ShaftHollow": ["ExpandedRoute", 7],
	"DrownedCrossing": ["ExpandedRoute", 7],
	"FloodedGallery": ["ExpandedRoute", 7],
	"BlackwaterCistern": ["ExpandedRoute", 7],
	"WardenApproach": ["ExpandedRoute", 7],
	"StarfallOutskirts": ["ExpandedRoute", 7],
	"StarfallSilentGate": ["ExpandedRoute", 7],
	"StarfallMemoryVault": ["ExpandedRoute", 7],
	"StarfallRootedHall": ["ExpandedRoute", 7],
	"StarfallSoulCrucible": ["ExpandedRoute", 7],
	"StarfallSunlessPassage": ["ExpandedRoute", 7],
}


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_expanded_portal_alignment_suite_save.json"
	for scene_name: String in ROOMS:
		var packed := load("res://%s.tscn" % scene_name) as PackedScene
		var room := packed.instantiate() as Node2D
		root.add_child(room)
		await process_frame
		var config: Array = ROOMS[scene_name]
		var expansion := room.get_node(String(config[0]))
		for child in room.get_children():
			if not child.is_in_group("room_door"):
				continue
			var aligned := false
			for tier in range(int(config[1])):
				var chamber: Rect2 = expansion.call("_chamber_rect", tier)
				if child.position.x >= chamber.position.x - 8.0 and child.position.x <= chamber.end.x + 8.0 and absf(child.position.y - (chamber.end.y - 33.0)) <= 4.0:
					aligned = true
					break
			_check(aligned, "%s/%s is not attached to an expanded chamber floor" % [scene_name, child.name])
		room.queue_free()
		await process_frame
	if failures.is_empty():
		print("EXPANDED PORTAL ALIGNMENT TEST PASSED")
		quit(0)
	else:
		print("EXPANDED PORTAL ALIGNMENT TEST FAILED: ", failures)
		quit(1)
