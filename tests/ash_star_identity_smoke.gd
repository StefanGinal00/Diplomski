extends SceneTree

## Verifies that the twelve late-game traversal rooms are not merely palette
## swaps: each has a named landmark family, a distinct encounter composition,
## a room-specific reward, and (where appropriate) its own gameplay props.

const ASH_ROOMS := [
	["BrokenCauseway", "causeway", "CollapsedViaduct", 8, 4, "March Survivor Cache", "", 0],
	["CinderForge", "forge", "SixFurnaces", 10, 2, "Furnace Keeper Cache", "ForgeHeatLane", 6],
	["EmberBarracks", "barracks", "TrainingYards", 2, 10, "Quartermaster Cache", "DrillTarget", 4],
	["SlagReservoir", "reservoir", "PressureTanks", 6, 6, "Pressure Engineer Cache", "PressureSurge", 4],
	["AshChapel", "chapel", "BellNave", 3, 9, "Votive Reliquary", "", 0],
	["CinderHearthOutskirts", "outskirts", "SiegeLine", 5, 7, "Scoria Watch Cache", "SiegeSupply", 5],
]

const STAR_ROOMS := [
	["StarfallOutskirts", "SiegeBarricades", 0, 2, 10, "Last Caravan Cache", "SiegeSupply", 5],
	["StarfallSilentGate", "WardedGateArches", 3, 0, 9, "Gatekeeper's Quiet Cache", "WardObstruction", 4],
	["StarfallMemoryVault", "MemoryMonoliths", 8, 2, 2, "Archivist's Memory Cache", "SealedRecord", 3],
	["StarfallRootedHall", "AncientRootNetwork", 2, 10, 0, "Rootkeeper's Cache", "RootSanctuaryFauna", 3],
	["StarfallSoulCrucible", "SoulVats", 4, 4, 4, "Crucible Tender Cache", "SoulSurge", 6],
	["StarfallSunlessPassage", "ShadowCurtains", 10, 2, 0, "Bearer's Last Light", "VoidPulse", 6],
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _count_prefix(parent: Node, prefix: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.name.begins_with(prefix):
			count += 1
	return count


func _script_count(parent: Node, prefix: String, script_path: String) -> int:
	var count := 0
	for child in parent.get_children():
		if not child.name.begins_with(prefix):
			continue
		var script: Script = child.get_script()
		if script != null and script.resource_path == script_path:
			count += 1
	return count


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_ash_star_identity_suite_save.json"
	var identity_titles := {}
	for info in ASH_ROOMS:
		var room_name: String = info[0]
		var scene := load("res://%s.tscn" % room_name) as PackedScene
		var room := scene.instantiate() as Node2D
		root.add_child(room)
		await process_frame
		var route := room.get_node("AshSwitchback") as Node2D
		var identity := route.get_node_or_null("AshIdentity") as Node2D
		_check(identity != null, "%s has no Ash identity layer" % room_name)
		if identity != null:
			var title := String(identity.get_meta("identity_name", ""))
			_check(not title.is_empty() and not identity_titles.has(title), "%s has a duplicate/empty identity title" % room_name)
			identity_titles[title] = true
			_check(identity.has_node(String(info[2])), "%s lacks landmark %s" % [room_name, info[2]])
		_check(String(route.course_id) == String(info[1]), "%s uses the wrong Ash course profile" % room_name)
		_check(_script_count(route, "AshRouteFoe", "res://AshFiend.gd") == int(info[3]), "%s has the wrong fiend composition" % room_name)
		_check(_script_count(route, "AshRouteFoe", "res://ShaftSentry.gd") == int(info[4]), "%s has the wrong sentry composition" % room_name)
		var cache := route.get_node_or_null("IdentityRewardCache")
		_check(cache != null and String(cache.get("cache_name")) == String(info[5]), "%s lacks its room-specific reward cache" % room_name)
		var prop_prefix: String = info[6]
		if not prop_prefix.is_empty():
			_check(_count_prefix(route, prop_prefix) == int(info[7]), "%s lacks its identity gameplay props" % room_name)
		room.queue_free()
		await process_frame
	_check(identity_titles.size() == ASH_ROOMS.size(), "Ash identity titles are not unique")

	identity_titles.clear()
	for info in STAR_ROOMS:
		var room_name: String = info[0]
		var scene := load("res://%s.tscn" % room_name) as PackedScene
		var room := scene.instantiate() as Node2D
		root.add_child(room)
		await process_frame
		var descent := room.get_node("ExpandedRoute/StarfallDescent") as Node2D
		var identity := descent.get_node_or_null("RoomIdentity") as Node2D
		_check(identity != null, "%s has no Starfall identity layer" % room_name)
		if identity != null:
			var title := String(identity.get_meta("identity_title", ""))
			_check(not title.is_empty() and not identity_titles.has(title), "%s has a duplicate/empty identity title" % room_name)
			identity_titles[title] = true
			_check(identity.has_node(String(info[1])), "%s lacks landmark %s" % [room_name, info[1]])
		_check(_script_count(descent, "DepthFoe", "res://EchoShade.gd") == int(info[2]), "%s has the wrong Shade composition" % room_name)
		_check(_script_count(descent, "DepthFoe", "res://RootStalker.gd") == int(info[3]), "%s has the wrong Stalker composition" % room_name)
		_check(_script_count(descent, "DepthFoe", "res://ShaftSentry.gd") == int(info[4]), "%s has the wrong Sentry composition" % room_name)
		var cache := descent.get_node_or_null("HiddenStarCache")
		_check(cache != null and String(cache.get("cache_name")) == String(info[5]), "%s lacks its room-specific reward cache" % room_name)
		_check(_count_prefix(descent, String(info[6])) == int(info[7]), "%s lacks its identity gameplay props" % room_name)
		room.queue_free()
		await process_frame
	_check(identity_titles.size() == STAR_ROOMS.size(), "Starfall identity titles are not unique")

	if failures.is_empty():
		print("ASH AND STARFALL IDENTITY TEST PASSED")
		quit(0)
	else:
		print("ASH AND STARFALL IDENTITY TEST FAILED: ", failures)
		quit(1)
