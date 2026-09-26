extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_shaft_room_identity_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	await _check_hollow()
	await _check_crossing(state)
	await _check_gallery()
	await _check_cistern()
	await _check_approach()
	await _check_vertical_hub()
	await _check_current_physics(state)
	if failures.is_empty():
		print("SHAFT ROOM IDENTITY TEST PASSED")
		quit(0)
	else:
		print("SHAFT ROOM IDENTITY TEST FAILED: ", failures)
		quit(1)


func _spawn(scene_path: String) -> Node2D:
	var room := (load(scene_path) as PackedScene).instantiate() as Node2D
	root.add_child(room)
	return room


func _route(room: Node2D) -> Node2D:
	return room.get_node("ExpandedRoute/AuthoredDescent") as Node2D


func _check_hollow() -> void:
	var room := _spawn("res://ShaftHollow.tscn")
	await process_frame
	var route := _route(room)
	_check(route.has_node("HollowIdentity") and route.has_node("HollowTimber10"), "Wisp Hollow lacks its mine-support identity")
	_check(route.has_node("HollowRockfall04") and route.get_node("HollowRockfall04").hazard_kind == "rockfall", "Wisp Hollow lacks telegraphed rockfalls")
	_check(route.has_node("HollowMinecartSpurA") and route.has_node("HollowMinecartSpurB") and route.has_node("HollowOreLandmark"), "Wisp Hollow ore-face detour is missing")
	_check(route.has_node("OreCrawlerA") and route.has_node("RockfallWisp") and route.has_node("HollowOreMoth"), "Wisp Hollow identity encounter is incomplete")
	room.queue_free()
	await process_frame


func _check_crossing(state: Node) -> void:
	var room := _spawn("res://DrownedCrossing.tscn")
	await process_frame
	var route := _route(room)
	_check(route.has_node("CrossingIdentity") and route.has_node("CrossingAqueductArch5"), "Drowned Crossing lacks aqueduct landmarks")
	for index in range(7):
		var current = route.get_node_or_null("CrossingCurrent%02d" % index)
		_check(current != null and current.hazard_kind == "current" and current.disabled_by_shortcut_id == "shaft_sluice_valve", "Drowned Crossing current %d is missing or not linked to its valve" % index)
		_check(route.has_node("CrossingDryRoute%02d_2" % index), "Drowned Crossing current %d lacks a dry bypass" % index)
	state.unlock_shortcut("shaft_sluice_valve")
	await process_frame
	_check(route.get_node("CrossingCurrent00").disabled and not route.get_node("CrossingCurrent00").monitoring, "Crossing valve did not calm expanded currents")
	_check(route.get_node("CrossingCurrent00").warning_duration >= 1.0, "Shaft hazard warning is too short for the base-speed player")
	_check(route.has_node("CurrentWispA") and route.has_node("ChannelCrawlerA") and route.has_node("CrossingEel"), "Drowned Crossing identity encounter is incomplete")
	room.queue_free()
	await process_frame
	room = _spawn("res://DrownedCrossing.tscn")
	await process_frame
	_check(_route(room).get_node("CrossingCurrent06").disabled, "A saved sluice state does not restore calm expanded currents")
	room.queue_free()
	await process_frame


func _check_gallery() -> void:
	var room := _spawn("res://FloodedGallery.tscn")
	await process_frame
	var route := _route(room)
	_check(route.has_node("GalleryIdentity") and route.has_node("GalleryManifold06"), "Flooded Gallery lacks its pressure-pipe identity")
	var lower_count := 0
	var upper_count := 0
	for index in range(7):
		var jet = route.get_node_or_null("GalleryPressureJet%02d" % index)
		_check(jet != null and jet.hazard_kind == "pressure", "Flooded Gallery pressure jet %d is missing" % index)
		if jet != null and jet.disabled_by_shortcut_id == "shaft_gallery_lower":
			lower_count += 1
		elif jet != null and jet.disabled_by_shortcut_id == "shaft_gallery_upper":
			upper_count += 1
	_check(lower_count == 4 and upper_count == 3, "Gallery controls do not divide the pressure network")
	_check(room.get_node("LowerControl").position.y > 1200.0 and room.get_node("UpperControl").position.y > 600.0, "Gallery controls are not distributed through the route")
	_check(route.has_node("GalleryCatwalk06_2") and route.has_node("ValveSentryA") and route.has_node("GalleryNewt"), "Gallery bypass or encounter identity is incomplete")
	root.get_node("GameState").unlock_shortcut("shaft_gallery_lower")
	await process_frame
	_check(route.get_node("GalleryPressureJet00").disabled and not route.get_node("GalleryPressureJet04").disabled, "Lower Gallery control disabled the wrong pressure network")
	root.get_node("GameState").unlock_shortcut("shaft_gallery_upper")
	await process_frame
	_check(route.get_node("GalleryPressureJet06").disabled, "Upper Gallery control did not disable its pressure network")
	room.queue_free()
	await process_frame


func _check_cistern() -> void:
	var room := _spawn("res://BlackwaterCistern.tscn")
	await process_frame
	var route := _route(room)
	_check(route.has_node("CisternIdentity") and route.has_node("CisternPressureCell2"), "Blackwater Cistern lacks pressure-cell landmarks")
	for chamber in range(3):
		_check(route.has_node("CisternGauge%d_2" % chamber), "Cistern pressure cell %d lacks gauges" % chamber)
		var wave = route.get_node_or_null("CisternPressureWave%d" % chamber)
		_check(wave != null and wave.disabled_by_shortcut_id == "shaft_cistern_pump", "Cistern pressure wave %d is not linked to the pump" % chamber)
	_check(room.get_node("HighDial").position.y < room.get_node("FarDial").position.y - 1000.0, "Cistern dial sequence is not spread across its descent")
	_check(route.has_node("CisternOverflowLandmark") and route.has_node("GaugeWispB") and route.has_node("CisternGrazer"), "Cistern side landmark or encounter identity is incomplete")
	root.get_node("GameState").unlock_shortcut("shaft_cistern_pump")
	await process_frame
	_check(route.get_node("CisternPressureWave2").disabled and not route.get_node("CisternPressureWave2").monitoring, "Cistern pump did not disable expanded pressure waves")
	room.queue_free()
	await process_frame


func _check_approach() -> void:
	var room := _spawn("res://WardenApproach.tscn")
	await process_frame
	var route := _route(room)
	_check(route.has_node("ApproachIdentity") and route.has_node("ApproachSightline06"), "Warden Approach lacks readable sentry sightlines")
	for index in range(7):
		var cover := route.get_node_or_null("ApproachCover%02d" % index) as StaticBody2D
		_check(cover != null and _rectangle(cover).size.y <= 66.0, "Warden Approach cover %d blocks ordinary traversal" % index)
	_check(route.has_node("ApproachWatchNiche6") and route.has_node("WatchSentry2") and route.has_node("GuardCrawler"), "Warden Approach watch-post encounter is incomplete")
	room.queue_free()
	await process_frame


func _check_vertical_hub() -> void:
	var room := _spawn("res://VerticalChamber.tscn")
	await process_frame
	_check(room.has_node("DeepShaftTraversal/BrokenHoistCable") and room.has_node("DeepShaftTraversal/HoistIdentity"), "Vertical Chamber lacks its full-height broken-hoist landmark")
	for tier in range(3):
		_check(room.has_node("DeepShaftTraversal/HoistServiceBay%dB" % tier), "Vertical Chamber lacks hoist service bay %d" % tier)
	_check(room.has_node("DeepShaftTraversal/HoistBaySentry2"), "Vertical Chamber hoist bays have no authored encounter")
	room.queue_free()
	await process_frame


func _check_current_physics(state) -> void:
	state.start_new_game("normal")
	state.set_current_room("shaft_crossing")
	var game := (load("res://Game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	var player: Player = game.get_node("Player")
	var current = game.get_node("DrownedCrossing/ExpandedRoute/AuthoredDescent/CrossingCurrent00")
	player.global_position = current.global_position
	player.velocity = Vector2.ZERO
	await physics_frame
	var start_x := player.global_position.x
	for frame in range(8):
		await physics_frame
	_check(player.global_position.x < start_x - 4.0, "Drowned current is visible but does not physically move an idle player")
	game.queue_free()
	await process_frame


func _rectangle(body: StaticBody2D) -> RectangleShape2D:
	return (body.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
