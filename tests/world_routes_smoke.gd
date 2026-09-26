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
	state.save_path = "res://_tmp_world_routes_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player = game.get_node("Player")
	var grotto = game.get_node("EchoGrotto")
	var gallery = game.get_node("EchoGallery")
	var shaft_gate = game.get_node("VerticalChamber/GrottoGate")
	var gallery_door = grotto.get_node("GalleryDoor")
	var shortcut = gallery.get_node("ShortcutDoor")
	var soundscape = game.get_node("AmbientSoundscape")
	_check(not shaft_gate._requirements_met(), "Shaft gate opened without its boss")
	state.add_item("warden_seal")
	_check(not shaft_gate._requirements_met(), "Shaft gate ignored boss requirement")
	state.mark_boss_defeated("abyss_warden")
	_check(shaft_gate._requirements_met(), "Shaft gate did not unlock after boss and seal")
	_check(not gallery_door._requirements_met(), "Gallery opened without resonators")
	state.add_item("echo_charm")
	_check(not gallery_door._requirements_met(), "Gallery ignored resonator events")
	state.unlock_shortcut("echo_resonator_lower")
	state.unlock_shortcut("echo_resonator_upper")
	_check(gallery_door._requirements_met(), "Gallery stayed locked after both resonators")
	_check(get_first_node_in_group("gallery_entry") != null, "Gallery entrance marker missing")
	_check(get_first_node_in_group("grotto_gallery_return") != null, "Gallery return marker missing")
	_check(get_first_node_in_group("grotto_shortcut_return") != null, "Shortcut return marker missing")
	gallery_door.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_gallery", "Gallery transition failed")
	_check(soundscape.current_track == "echo_gallery", "Gallery ambience missing")
	_check(not shortcut._requirements_met(), "Gallery shortcut opened without prism")
	var prism = gallery.get_node("GalleryPrism")
	prism._on_body_entered(player)
	await process_frame
	_check(state.has_item("gallery_prism"), "Gallery Prism not collected")
	_check(shortcut._requirements_met(), "Gallery shortcut stayed locked after prism")
	_check("ENTER THE ARCHIVE" in game.get_node("UI").objective_label.text, "Gallery objective did not update")
	shortcut.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_grotto", "Shortcut did not return to Grotto")
	_check(player.global_position.distance_to(grotto.get_node("ShortcutReturn").global_position) < 45.0, "Shortcut arrived at wrong marker")
	gallery_door.activate(player)
	await create_timer(0.5).timeout
	gallery.get_node("ReturnDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_grotto", "Gallery's near return door did not work")
	_check(player.global_position.distance_to(grotto.get_node("GalleryReturn").global_position) < 45.0, "Gallery's near return reached wrong marker")
	var lamp = grotto.get_node("GrottoLamp/RespawnPoint")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), lamp.global_position, "echo_grotto_lamp", "Echo Grotto Lamp", "echo_grotto"), "World route save failed")
	state.inventory.erase("gallery_prism")
	state.unlocked_shortcuts.clear()
	_check(state.load_game(), "World route load failed")
	_check(state.has_item("gallery_prism"), "Gallery Prism not restored")
	_check(gallery_door._requirements_met() and shortcut._requirements_met(), "Doors did not restore after load")
	var compound_gate = load("res://RoomDoor.tscn").instantiate()
	compound_gate.required_boss_ids = PackedStringArray(["abyss_warden", "void_sentinel"])
	compound_gate.required_item_ids = PackedStringArray(["warden_seal", "gallery_prism"])
	compound_gate.required_event_ids = PackedStringArray(["echo_resonator_lower", "echo_resonator_upper"])
	game.add_child(compound_gate)
	_check(not compound_gate._requirements_met(), "Compound gate ignored a missing boss")
	state.mark_boss_defeated("void_sentinel")
	_check(compound_gate._requirements_met(), "Compound boss, item and event gate stayed locked")
	compound_gate.queue_free()
	game.queue_free()
	await process_frame
	var reloaded_game = load("res://Game.tscn").instantiate()
	root.add_child(reloaded_game)
	current_scene = reloaded_game
	await process_frame
	await process_frame
	_check(not reloaded_game.get_node("EchoGallery").has_node("GalleryPrism"), "Unique prism respawned after loading")
	state.set_current_room("echo_gallery")
	await process_frame
	_check(reloaded_game.get_node("EchoGallery/NearShade").zone_id == "echo_grotto", "Gallery enemy belongs to wrong zone")
	state.delete_save()
	reloaded_game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("WORLD ROUTES TEST PASSED")
		quit(0)
	else:
		print("WORLD ROUTES TEST FAILED: ", failures)
		quit(1)
