extends "res://tests/biome_population_support_smoke.gd"

const HUB_SCENES := ["VerticalChamber", "EchoHaven", "EchoHavenOutskirts", "CinderHearth", "CinderHearthOutskirts", "StarfallCitadel"]
const HUB_SCRIPTS := ["res://TownService.gd", "res://LifeBloom.gd", "res://MemorySigil.gd"]
var routes_audited := 0


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hub_settlement_support_save.json"
	state.start_new_game("normal")
	for scene_name in HUB_SCENES:
		var room := load("res://%s.tscn" % scene_name).instantiate() as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		await process_frame
		if scene_name == "VerticalChamber":
			_check_shaft_origins(room)
		if scene_name == "EchoHaven":
			var district := room.get_node("NewDistricts")
			for tier in [1, 3, 5]:
				var door := district.get_node("Home%02dDoor" % tier) as Marker2D
				_check(is_equal_approx(door.position.x, district.ledges[tier][1].x), "Resident interior stop does not match the house doorway")
		for node in room.find_children("*", "Node2D", true, false):
			var script: Script = node.get_script()
			if script != null and script.resource_path == "res://ShaftWisp.gd":
				continue
			var targeted: bool = node is Marker2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature") or node.is_in_group("breakable") or (script != null and (FIXED_SCRIPTS.has(script.resource_path) or PUZZLE_SCRIPTS.has(script.resource_path) or HUB_SCRIPTS.has(script.resource_path)))
			if not targeted:
				continue
			audited += 1
			_check(_supported(node, room), "Unsupported hub/settlement placement: %s/%s at %s" % [scene_name, room.get_path_to(node), node.position])
			if script != null and script.resource_path == "res://TownResident.gd":
				_check_walk_route(node, room)
		room.queue_free()
		await process_frame
	state.delete_save()
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("HUB SETTLEMENT SUPPORT TEST PASSED: ", audited, " placements, ", routes_audited, " walking segments")
		quit(0)
	else:
		print("HUB SETTLEMENT SUPPORT TEST FAILED: ", failures.size(), " / ", audited)
		quit(1)


func _check_shaft_origins(room: Node2D) -> void:
	var deep := room.get_node("DeepShaftTraversal")
	for tier in range(5):
		for index in range(3):
			var actor := deep.get_node("DeepPatrol%02d_%02d" % [tier, index]) as Node2D
			if actor.get_script().resource_path == "res://ShaftCrawler.gd":
				_check(is_equal_approx(actor.start_x, actor.global_position.x), "Crawler patrol origin was recorded before its floor placement")
			for other in range(index):
				var sibling := deep.get_node("DeepPatrol%02d_%02d" % [tier, other]) as Node2D
				_check(actor.position.distance_to(sibling.position) >= 65, "Floor correction stacked Shaft patrols %s %s: %s / %s" % [actor.name, sibling.name, actor.position, sibling.position])


func _check_walk_route(resident: Node2D, room: Node2D) -> void:
	var stops: Array[Vector2] = [resident.global_position]
	for marker in resident.route_markers:
		stops.append(marker.global_position)
	if stops.size() < 2:
		return
	stops.append(stops[1]) # Include the last-to-first route wrap.
	var floors: Array[CollisionShape2D] = []
	for body in room.find_children("*", "StaticBody2D", true, false):
		if body.is_in_group("breakable"):
			continue
		for shape in body.get_children():
			if shape is CollisionShape2D and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size.y <= 40:
				floors.append(shape)
	for index in range(stops.size() - 1):
		routes_audited += 1
		var samples := maxi(1, ceili(stops[index].distance_to(stops[index + 1]) / 12.0))
		for sample in range(samples + 1):
			var point := stops[index].lerp(stops[index + 1], float(sample) / samples)
			var supported := false
			for floor_shape in floors:
				var relative := floor_shape.to_local(point)
				var size: Vector2 = floor_shape.shape.size
				if absf(relative.x) <= size.x * 0.5 and relative.y < -size.y * 0.5 and relative.y >= -55:
					supported = true
					break
			if not supported:
				_check(false, "Resident walks over a gap: %s/%s segment %d at %s" % [room.name, room.get_path_to(resident), index, room.to_local(point)])
				break
