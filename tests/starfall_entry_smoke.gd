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
	state.save_path = "res://_tmp_starfall_entry_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var player: Player = game.get_node("Player")
	var throne: Node2D = game.get_node("CastellanThrone")
	var city: Node2D = game.get_node("StarfallCitadel")
	var gate: Node2D = city.get_node("GateDistrict")
	var ward: Node2D = city.get_node("WardDistrict")
	var ui = game.get_node("UI")
	var soundscape = game.get_node("AmbientSoundscape")
	var city_door = throne.get_node("StarfallDoor")
	_check(not city_door._requirements_met(), "Starfall opened before the Castellan was defeated")
	state.add_item("castellan_seal")
	_check(not city_door._requirements_met(), "Castellan seal alone bypassed the boss flag")
	state.inventory.erase("castellan_seal")
	state.defeated_bosses["ash_castellan"] = true
	_check(not city_door._requirements_met(), "Boss flag alone bypassed the Castellan seal")
	state.add_item("castellan_seal")
	_check(city_door._requirements_met(), "Starfall did not open after both Castellan requirements")
	_check(city_door.position.y < throne.get_node("HearthShortcut").position.y - 150.0, "Starfall and Hearth exits are clustered")
	_check(throne.get_node("StarfallStep1/CollisionShape2D").one_way_collision and throne.get_node("StarfallStep2/CollisionShape2D").one_way_collision, "Starfall upper entrance cannot be climbed")
	_check(throne.get_node("StarfallReturn").position.distance_to(city_door.position) > 45.0, "Returning from Starfall would bounce back into its entrance")
	_check(get_first_node_in_group("starfall_citadel_entry") == gate.get_node("GateEntry"), "Citadel entry marker is missing")
	_check(city.get_node("Floor/CollisionShape2D").shape.size.x >= 6200.0, "City has no long continuous walking floor")
	_check(not gate.has_node("WardDoor") and not gate.has_node("RightWall") and not ward.has_node("GateReturnDoor") and not ward.has_node("LeftWall"), "The city still has a room-door or wall between districts")
	var city_doors := 0
	var residents := 0
	var services := 0
	for node in city.find_children("*", "Node", true, false):
		city_doors += int(node.is_in_group("room_door"))
		residents += int(node.is_in_group("town_resident"))
		services += int(node.is_in_group("town_service"))
		_check(not node.is_in_group("enemy") and not node.is_in_group("boss"), "The peaceful Citadel contains a hostile spawn")
	_check(city_doors == 2 and city.has_node("OuterWatchGate"), "The city should have one throne return and one far-edge outer gate")
	_check(residents >= 17 and services >= 4, "The city has too few residents or services")
	for landmark in ["MarketHall", "ApothecaryHouse", "GardenLibrary", "ObservatoryTower", "WestPromenade", "MarketBalcony", "GardenBalcony", "LayeredRearDistricts", "SkyTower3595", "DistantSkybridge2860"]:
		_check(city.has_node(landmark), "A city landmark or upper route is missing: " + landmark)
	var district_details := city.get_node("CityDistrictDetails")
	_check(int(district_details.get_meta("district_count", 0)) == 4, "The connected city does not distinguish its four eastern districts")
	for district_name in ["CivicSquareDetails", "MarketLifeDetails", "CelestialGardenDetails", "ObservatoryDetails"]:
		var district := district_details.get_node_or_null(district_name)
		_check(district != null and district.get_child_count() >= 6 and district.has_meta("district_identity"), "A Starfall district is still visually empty: " + district_name)
	_check(district_details.has_node("CivicSquareDetails/StarFountainBasin") and district_details.has_node("MarketLifeDetails/DeliveryCart") and district_details.has_node("CelestialGardenDetails/CelestialDial") and district_details.has_node("ObservatoryDetails/ArmillaryRing2"), "A distinct Starfall district landmark is missing")
	for platform in ["WestPromenade", "MarketBalcony", "GardenBalcony"]:
		_check(city.get_node(platform + "/CollisionShape2D").one_way_collision, "An upper city path cannot be jumped through: " + platform)
	_check(gate.get_node("Step4/CollisionShape2D").one_way_collision and city.get_node("WestPromenade").position.y == gate.get_node("Step4").position.y, "Gate stairs do not reach the upper promenade")
	_check(city.get_node("MarketStep1").position.y < city.get_node("Floor").position.y - 50.0 and city.get_node("GardenStep1").position.y < city.get_node("Floor").position.y - 50.0, "Market or garden lacks a climb to its upper level")
	for lamp in [gate.get_node("GateLamp"), ward.get_node("WardLamp"), city.get_node("MarketLamp"), city.get_node("GardenLamp")]:
		_check(lamp.room_id == "starfall_citadel", "A city lamp would split the connected room")
	_check(gate.get_node("ThroneReturnDoor")._requirements_met(), "City-to-Throne return door must stay open")
	_check(ward.get_node("SupplyStall").service_id == "starfall_ward_shop" and ward.get_node("WardAnvil").service_kind == "anvil", "Lantern Ward services are missing")
	_check(city.get_node("MarketTrader").service_id == "starfall_market_shop" and city.get_node("Apothecary").service_id == "starfall_apothecary_shop", "Market shops are missing")

	state.set_current_room("ash_throne")
	await city_door.activate(player)
	_check(state.current_room_id == "starfall_citadel" and bool(state.discovered_rooms.get("starfall_citadel", false)), "City entry did not register as one room")
	_check(player.global_position.distance_to(gate.get_node("GateEntry").global_position) < 45.0, "City arrival marker is wrong")
	_check(ui.zone_title_label.text == "STARFALL CITADEL" and "SAFE CITY" in ui.objective_label.text, "City title or safe objective is missing")
	_check(soundscape.current_track == "starfall_citadel", "City ambience did not start")
	player.global_position = ward.global_position + Vector2(600, 367)
	await physics_frame
	_check(state.current_room_id == "starfall_citadel" and soundscape.current_track == "starfall_citadel", "Walking into Lantern Ward changed room or music")
	player.global_position = city.global_position + Vector2(3500, 367)
	await physics_frame
	_check(state.current_room_id == "starfall_citadel", "Walking to the market triggered a room transition")
	player.global_position = city.global_position + Vector2(5200, 367)
	await physics_frame
	_check(state.current_room_id == "starfall_citadel", "Walking to the garden triggered a room transition")
	ui._update_route_summary()
	_check("STARFALL CITADEL  DISCOVERED" in ui.map_route_label.text and "CACHES 0/4" in ui.map_route_label.text, "Map did not identify the connected city")
	_check(gate.get_node("OverlookCache").open(player) and city.get_node("MarketBalconyCache").open(player), "Upper city caches cannot be claimed")
	var resident = city.get_node("Rook")
	resident.interaction_requested.emit(resident)
	_check(ui.speaker_label.text == "ROOK", "City resident dialogue is not connected")
	ui._close_dialogue()
	state.add_gold(200)
	var trader = city.get_node("MarketTrader")
	trader.interaction_requested.emit(trader)
	_check(ui.shop_mode == "buy" and state.get_town_stock_remaining("starfall_market_shop", "healing_herb") == 2, "Market stock is wrong")
	ui.selected_shop_item_id = "healing_herb"
	ui._on_shop_buy_pressed()
	_check(state.get_town_stock_remaining("starfall_market_shop", "healing_herb") == 1, "Market purchase did not reduce capped stock")
	ui._close_shop()
	city.get_node("Apothecary").interaction_requested.emit(city.get_node("Apothecary"))
	_check(ui.shop_mode == "buy" and state.get_town_stock_remaining("starfall_apothecary_shop", "ether_dust") == 4, "Apothecary stock is missing")
	ui._close_shop()
	ward.get_node("WardAnvil").interaction_requested.emit(ward.get_node("WardAnvil"))
	_check(ui.shop_mode == "forge", "Ward anvil did not open forging")
	ui._close_shop()
	for lamp in [gate.get_node("GateLamp"), ward.get_node("WardLamp"), city.get_node("MarketLamp"), city.get_node("GardenLamp")]:
		player.global_position = lamp.get_node("RespawnPoint").global_position
		_check(lamp._save_progress(player), "A city lamp did not save")
	_check(state.get_discovered_lamps().has("starfall_gate_lamp") and state.get_discovered_lamps().has("starfall_ward_lamp") and state.get_discovered_lamps().has("starfall_market_lamp") and state.get_discovered_lamps().has("starfall_garden_lamp"), "All city lamps did not join fast travel")
	_check(state.current_room_id == "starfall_citadel" and state.checkpoint_lamp_id == "starfall_garden_lamp", "Garden lamp did not set the city respawn")
	_check(city.get_node("GardenCache").open(player), "Garden cache cannot be opened")
	_check(state.load_game(), "City lamp save did not reload")
	_check(state.current_room_id == "starfall_citadel" and state.get_town_stock_remaining("starfall_market_shop", "healing_herb") == 1, "Saved city room or vendor stock was lost")
	_check(not bool(state.opened_caches.get("starfall_garden_skywalk", false)) and bool(state.opened_caches.get("starfall_market_balcony", false)), "Unsaved Garden cache did not roll back")
	var legacy_data: Dictionary = state._build_save_data().duplicate(true)
	legacy_data["current_room_id"] = "starfall_ward"
	legacy_data["discovered_rooms"] = {"training_passage": true, "starfall_ward": true}
	var legacy_lamps: Dictionary = legacy_data["discovered_lamps"]
	var legacy_ward_lamp: Dictionary = legacy_lamps["starfall_ward_lamp"]
	legacy_ward_lamp["room_id"] = "starfall_ward"
	state._apply_save_data(legacy_data)
	_check(state.current_room_id == "starfall_citadel" and bool(state.discovered_rooms.get("starfall_citadel", false)), "An older Starfall save did not migrate to one city")
	_check(str(state.get_discovered_lamps()["starfall_ward_lamp"]["room_id"]) == "starfall_citadel", "Legacy Ward lamp did not migrate")
	_check(state.load_game(), "City save could not be restored after migration check")
	await gate.get_node("ThroneReturnDoor").activate(player)
	_check(state.current_room_id == "ash_throne" and player.global_position.distance_to(throne.get_node("StarfallReturn").global_position) < 45.0, "City-to-Throne return route failed")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL ENTRY TEST PASSED")
		quit(0)
	else:
		print("STARFALL ENTRY TEST FAILED: ", failures)
		quit(1)
