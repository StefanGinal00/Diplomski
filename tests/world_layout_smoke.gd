extends SceneTree

const WORLD_LAYOUT = preload("res://WorldLayout.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_world_layout_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	_check(not game.get_node("ShaftHollow").visible and game.get_node("ShaftHollow").process_mode == Node.PROCESS_MODE_DISABLED, "Inactive rooms still run AI/rendering")
	var shaft_expansion = game.get_node("ShaftHollow/ExpandedRoute")
	var starfall_expansion = game.get_node("StarfallOutskirts/ExpandedRoute")
	var echo_expansion = game.get_node("EchoGrotto/LongTraversal")
	var ash_expansion = game.get_node("BrokenCauseway/AshSwitchback")
	var expedition = game.get_node("ShaftDriftworks")
	var echo_settlement = game.get_node("EchoHaven/NewDistricts")
	var cinder_settlement = game.get_node("CinderHearth/EasternDistricts")
	var echo_town_life = game.get_node("EchoHaven/UpperVillage")
	var cinder_town_life = game.get_node("CinderHearth/UpperVillage")
	var starfall_town_life = game.get_node("StarfallCitadel/LibraryRooftop")
	_check(not shaft_expansion.is_population_loaded() and not shaft_expansion.get_node("AuthoredDescent").has_node("HiddenDepthAmbush"), "An inactive Shaft expansion eagerly built its population")
	_check(not starfall_expansion.is_population_loaded() and not starfall_expansion.get_node("StarfallDescent").has_node("HiddenStarAmbush"), "An inactive Starfall expansion eagerly built its population")
	_check(not echo_expansion.is_population_loaded() and not echo_expansion.has_node("OptionalAmbush"), "An inactive Echo expansion eagerly built its population")
	_check(not ash_expansion.is_population_loaded() and not ash_expansion.has_node("GuardedNicheAmbush"), "An inactive Ash expansion eagerly built its population")
	_check(not expedition.is_population_loaded() and not expedition.has_node("Patrol0"), "An inactive expedition eagerly built its combat population")
	_check(not echo_settlement.is_population_loaded() and not echo_settlement.has_node("Elen"), "The inactive Haven eagerly built its added residents")
	_check(not cinder_settlement.is_population_loaded() and not cinder_settlement.has_node("Veyra"), "The inactive Hearth eagerly built its added residents")
	_check(not echo_town_life.is_population_loaded() and not echo_town_life.has_node("Tessan"), "The inactive Haven eagerly built its ambient residents")
	_check(not cinder_town_life.is_population_loaded() and not cinder_town_life.has_node("Kael"), "The inactive Hearth eagerly built its ambient residents")
	_check(not starfall_town_life.is_population_loaded() and not starfall_town_life.has_node("Erian"), "The inactive Citadel eagerly built its rooftop residents")
	for authored_info in [["ShaftHollow", "HollowWispNear"], ["DrownedCrossing", "ChannelCrawler"], ["FloodedGallery", "GalleryCrawler"], ["BlackwaterCistern", "ChannelCrawler"], ["WardenApproach", "EntryCrawler"]]:
		_check(not game.get_node(String(authored_info[0])).has_node(String(authored_info[1])), "%s eagerly instantiated its authored manifest" % String(authored_info[0]))
	for authored_info in [["EchoGrotto", "EchoWisp"], ["EchoGallery", "NearShade"], ["PrismArchive", "ArchiveShade"], ["TideWell", "MidWisp"], ["EchoNest", "BroodlingOne"], ["CrystalCauseway", "CausewayWisp"], ["UndertowVault", "VaultWisp"]]:
		_check(not game.get_node(String(authored_info[0])).has_node(String(authored_info[1])), "%s eagerly instantiated its Echo manifest" % String(authored_info[0]))
	for authored_info in [["BrokenCauseway", "NearFiend"], ["CinderForge", "EntryFiend"], ["EmberBarracks", "EntryFiend"], ["SlagReservoir", "NearFiend"], ["AshChapel", "NaveFiend"], ["CinderHearthOutskirts", "GateFiend"]]:
		_check(not game.get_node(String(authored_info[0])).has_node(String(authored_info[1])), "%s eagerly instantiated its Ashen manifest" % String(authored_info[0]))
	for authored_info in [["StarfallOutskirts", "DuskShade"], ["StarfallSilentGate", "HushedShade"], ["StarfallMemoryVault", "PitShade"], ["StarfallRootedHall", "FirstStalker"], ["StarfallSoulCrucible", "BoundShade"], ["StarfallSunlessPassage", "LostShade"]]:
		_check(not game.get_node(String(authored_info[0])).has_node(String(authored_info[1])), "%s eagerly instantiated its Starfall manifest" % String(authored_info[0]))
	state.set_current_room("shaft_hollow")
	_check(game.get_node("ShaftHollow").visible and game.get_node("ShaftHollow").process_mode == Node.PROCESS_MODE_INHERIT, "Entering a room did not activate it")
	_check(shaft_expansion.is_population_loaded() and shaft_expansion.get_node("AuthoredDescent").has_node("HiddenDepthAmbush"), "Entering Shaft Hollow did not stream its expanded population")
	_check(game.get_node("ShaftHollow").has_node("HollowWispNear") and game.get_node("ShaftHollow").has_node("HollowCrate"), "Entering Shaft Hollow did not instantiate its authored manifest")
	_check(not game.get_node("EchoGrotto").visible, "Entering one room activated a different room")
	state.set_current_room("starfall_outskirts")
	_check(starfall_expansion.is_population_loaded() and starfall_expansion.get_node("StarfallDescent").has_node("HiddenStarAmbush"), "Entering Outer Watch did not stream its expanded population")
	_check(game.get_node("StarfallOutskirts").has_node("DuskShade") and game.get_node("StarfallOutskirts").has_node("LostWatch"), "Entering Outer Watch did not instantiate its authored manifest")
	var starfall_child_count := starfall_expansion.get_node("StarfallDescent").get_child_count()
	state.set_current_room("shaft_hollow")
	state.set_current_room("starfall_outskirts")
	_check(starfall_expansion.get_node("StarfallDescent").get_child_count() == starfall_child_count, "Re-entering Outer Watch duplicated its expanded population")
	state.set_current_room("echo_grotto")
	_check(echo_expansion.is_population_loaded() and echo_expansion.has_node("OptionalAmbush") and echo_expansion.has_node("QuietCaveLife0"), "Entering Echo Grotto did not stream its traversal population")
	_check(game.get_node("EchoGrotto").has_node("EchoWisp") and game.get_node("EchoGrotto").has_node("ForgottenCrate"), "Entering Echo Grotto did not instantiate its authored manifest")
	state.set_current_room("ash_causeway")
	_check(ash_expansion.is_population_loaded() and ash_expansion.has_node("GuardedNicheAmbush") and ash_expansion.has_node("AshRouteFoe0_0"), "Entering Broken Causeway did not stream its traversal population")
	_check(game.get_node("BrokenCauseway").has_node("NearFiend") and game.get_node("BrokenCauseway").has_node("FinalWatchSentry"), "Entering Broken Causeway did not instantiate its authored manifest")
	state.set_current_room("shaft_drift")
	_check(expedition.is_population_loaded() and expedition.has_node("Patrol0") and expedition.has_node("BranchGuard0"), "Entering Driftworks did not stream its expedition encounters")
	state.set_current_room("echo_haven")
	_check(echo_settlement.is_population_loaded() and echo_settlement.has_node("Elen") and echo_settlement.has_node("CanalTrader"), "Entering Whisperlight Haven did not stream its added residents and services")
	_check(echo_town_life.is_population_loaded() and echo_town_life.has_node("Tessan") and echo_town_life.has_node("Tovan"), "Entering Whisperlight Haven did not stream its ambient residents")
	state.set_current_room("ash_hearth")
	_check(cinder_settlement.is_population_loaded() and cinder_settlement.has_node("Veyra"), "Entering Cinder Hearth did not stream its added residents")
	_check(cinder_town_life.is_population_loaded() and cinder_town_life.has_node("Kael") and cinder_town_life.has_node("Yara"), "Entering Cinder Hearth did not stream its ambient residents")
	state.set_current_room("starfall_citadel")
	_check(starfall_town_life.is_population_loaded() and starfall_town_life.has_node("Erian") and starfall_town_life.has_node("Dorian"), "Entering Starfall Citadel did not stream its rooftop residents")
	for authored_info in [["shaft_crossing", "DrownedCrossing", "ChannelCrawler"], ["shaft_gallery", "FloodedGallery", "GalleryCrawler"], ["shaft_cistern", "BlackwaterCistern", "ChannelCrawler"], ["shaft_approach", "WardenApproach", "EntryCrawler"]]:
		state.set_current_room(String(authored_info[0]))
		_check(game.get_node(String(authored_info[1])).has_node(String(authored_info[2])), "Entering %s did not instantiate its authored manifest" % String(authored_info[1]))
	for authored_info in [["echo_gallery", "EchoGallery", "NearShade"], ["echo_archive", "PrismArchive", "ArchiveShade"], ["echo_tide_well", "TideWell", "MidWisp"], ["echo_nest", "EchoNest", "BroodlingOne"], ["echo_causeway", "CrystalCauseway", "CausewayWisp"], ["echo_vault", "UndertowVault", "VaultWisp"]]:
		state.set_current_room(String(authored_info[0]))
		_check(game.get_node(String(authored_info[1])).has_node(String(authored_info[2])), "Entering %s did not instantiate its Echo manifest" % String(authored_info[1]))
	for authored_info in [["ash_forge", "CinderForge", "EntryFiend"], ["ash_barracks", "EmberBarracks", "EntryFiend"], ["ash_reservoir", "SlagReservoir", "NearFiend"], ["ash_chapel", "AshChapel", "NaveFiend"], ["ash_hearth_outskirts", "CinderHearthOutskirts", "GateFiend"]]:
		state.set_current_room(String(authored_info[0]))
		_check(game.get_node(String(authored_info[1])).has_node(String(authored_info[2])), "Entering %s did not instantiate its Ashen manifest" % String(authored_info[1]))
	for authored_info in [["starfall_silent_gate", "StarfallSilentGate", "HushedShade"], ["starfall_memory_vault", "StarfallMemoryVault", "PitShade"], ["starfall_rooted_hall", "StarfallRootedHall", "FirstStalker"], ["starfall_soul_crucible", "StarfallSoulCrucible", "BoundShade"], ["starfall_sunless_passage", "StarfallSunlessPassage", "LostShade"]]:
		state.set_current_room(String(authored_info[0]))
		_check(game.get_node(String(authored_info[1])).has_node(String(authored_info[2])), "Entering %s did not instantiate its Starfall manifest" % String(authored_info[1]))
	state.start_new_game("normal")
	_check(not game.get_node("ShaftHollow").visible, "Starting a new run left the previous room active")
	for room_id in WORLD_LAYOUT.ROOM_ORIGINS:
		var new_origin: Vector2 = WORLD_LAYOUT.ROOM_ORIGINS[room_id][1]
		var matches := 0
		for child in game.get_children():
			if child is Node2D and child.position == new_origin:
				matches += 1
		_check(matches == 1, "Room origin missing or reused for %s" % room_id)
	for lamp_info in [
		["shaft_cistern", "blackwater_cistern_lamp", "BlackwaterCistern/CisternLamp", Vector2(905, 369)],
		["shaft_approach", "warden_approach_lamp", "WardenApproach/ApproachLamp", Vector2(1080, 419)],
		["echo_grotto", "echo_grotto_lamp", "EchoGrotto/GrottoLamp", Vector2(262, 130)],
	]:
		var room_id: String = lamp_info[0]
		var lamp_id: String = lamp_info[1]
		var old_global: Vector2 = WORLD_LAYOUT.ROOM_ORIGINS[room_id][0] + lamp_info[3]
		var old_save: Dictionary = state._build_save_data()
		old_save["version"] = 9
		old_save["has_checkpoint"] = true
		old_save["checkpoint_lamp_id"] = lamp_id
		old_save["checkpoint_position"] = [old_global.x, old_global.y]
		old_save["discovered_lamps"] = {lamp_id: {"room_id": room_id, "position": [old_global.x, old_global.y]}}
		state._apply_save_data(old_save)
		var target: Vector2 = game.get_node(lamp_info[2] + "/RespawnPoint").global_position
		_check(state.checkpoint_position.distance_to(target) < 1.0, "Checkpoint migration failed for %s" % lamp_id)
		_check(state.get_lamp_position(lamp_id).distance_to(target) < 1.0, "Fast-travel migration failed for %s" % lamp_id)
		state._apply_save_data(state._build_save_data())
		_check(state.checkpoint_position.distance_to(target) < 1.0, "New save migrated twice for %s" % lamp_id)
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("WORLD LAYOUT TEST PASSED")
		quit(0)
	else:
		print("WORLD LAYOUT TEST FAILED: ", failures)
		quit(1)
