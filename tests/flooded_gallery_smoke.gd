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
	state.save_path = "res://_tmp_flooded_gallery_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var shaft = game.get_node("VerticalChamber")
	var crossing = game.get_node("DrownedCrossing")
	var gallery = game.get_node("FloodedGallery")
	var approach = game.get_node("WardenApproach")
	var lower = gallery.get_node("LowerControl")
	var upper = gallery.get_node("UpperControl")
	var far_door = gallery.get_node("WardenShortcutDoor")
	var reverse_door = shaft.get_node("GalleryShortcutDoor")
	_check(not far_door._requirements_met() and not reverse_door._requirements_met(), "Gallery shortcut opened before both controls")
	state.set_current_room("shaft_crossing")
	crossing.get_node("GalleryDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_gallery" and bool(state.discovered_rooms.get("shaft_gallery", false)), "Crossing did not discover Flooded Gallery")
	_check(player.global_position.distance_to(gallery.get_node("CrossingEntry").global_position) < 45.0, "Gallery entry marker is wrong")
	_check(game.get_node("AmbientSoundscape").current_track == "shaft_gallery", "Gallery ambience did not start")
	_check("0/2" in game.get_node("UI").objective_label.text, "Gallery control objective did not start at zero")
	_check(lower.activate(player), "Lower Gallery control did not activate")
	_check(not far_door._requirements_met() and "1/2" in game.get_node("UI").objective_label.text, "One Gallery control opened the shortcut early")
	_check(upper.activate(player), "Upper Gallery control did not activate")
	_check(far_door._requirements_met() and reverse_door._requirements_met(), "Both Gallery controls did not open the two-way shortcut")
	_check("WARDEN SHORTCUT OPEN" in game.get_node("UI").objective_label.text, "Gallery objective did not show opened shortcut")
	var supply = gallery.get_node("GalleryCache")
	var gold_before: int = state.gold
	_check(supply.open(player), "Gallery supply cache did not open")
	_check(state.gold >= gold_before + 27 and state.has_item("ether_dust"), "Gallery supply payout is missing")
	_check(not supply.open(player), "Gallery supply cache paid twice")
	far_door.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_approach" and player.global_position.distance_to(approach.get_node("GalleryEntry").global_position) < 45.0, "Gallery did not reach Warden Approach")
	approach.get_node("ArenaDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "sunken_shaft" and player.global_position.distance_to(shaft.get_node("GalleryReturn").global_position) < 45.0, "Approach did not reach Warden arena")
	reverse_door.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_approach" and player.global_position.distance_to(approach.get_node("ShaftEntry").global_position) < 45.0, "Warden arena could not return to Approach")
	approach.get_node("GalleryReturnDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_gallery" and player.global_position.distance_to(gallery.get_node("ShaftEntry").global_position) < 45.0, "Warden Approach could not return to Gallery")
	state.set_zone_tier("sunken_shaft", 1)
	_check(gallery.has_node("Cache_gallery_afterglow"), "Awakened Gallery cache is missing")
	far_door.activate(player)
	await create_timer(0.5).timeout
	approach.get_node("GalleryReturnDoor").activate(player)
	await create_timer(0.5).timeout
	_check(gallery.has_node("gallery_echo_wisp"), "Awakened Gallery encounter did not spawn on return")
	var awakened_cache = gallery.get_node("Cache_gallery_afterglow")
	_check(awakened_cache.open(player), "Awakened Gallery cache did not open")
	_check(game.get_node("QuestManager")._get_return_cache_count("sunken_shaft") == 1, "Awakened Gallery cache did not count for Shaft Vigil")
	state.set_current_room("shaft_crossing")
	var lamp_position: Vector2 = crossing.get_node("CrossingLamp/RespawnPoint").global_position
	player.global_position = lamp_position
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), lamp_position, "drowned_crossing_lamp", "Drowned Crossing Lamp", "shaft_crossing"), "Gallery progress did not save")
	state.unlocked_shortcuts.clear()
	state.opened_caches.clear()
	state.discovered_rooms.erase("shaft_gallery")
	_check(state.load_game(), "Gallery progress did not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	gallery = game.get_node("FloodedGallery")
	_check(gallery.get_node("LowerControl").is_active and gallery.get_node("UpperControl").is_active, "Saved Gallery controls did not relight")
	_check(gallery.get_node("WardenShortcutDoor")._requirements_met() and game.get_node("VerticalChamber/GalleryShortcutDoor")._requirements_met(), "Saved Gallery shortcut closed")
	_check(gallery.get_node("GalleryCache").opened and gallery.get_node("Cache_gallery_afterglow").opened, "Saved Gallery caches reopened")
	game.get_node("UI")._update_route_summary()
	_check("4/7 PLAYABLE ROOMS" in game.get_node("UI").map_route_label.text and "CACHES 2/14" in game.get_node("UI").map_route_label.text, "Map did not track Gallery progress")
	_check(game.get_node("UI/WorldMapPanel/RouteScroll").get_global_rect().intersection(game.get_node("UI").map_travel_button.get_global_rect()).get_area() <= 0.0, "World-map route viewport overlaps travel button")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("FLOODED GALLERY TEST PASSED")
		quit(0)
	else:
		print("FLOODED GALLERY TEST FAILED: ", failures)
		quit(1)
