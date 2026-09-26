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
	state.save_path = "res://_tmp_prism_archive_save.json"
	state.start_new_game("normal")
	state.add_item("gallery_prism")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player = game.get_node("Player")
	var gallery = game.get_node("EchoGallery")
	var archive = game.get_node("PrismArchive")
	var archive_door = gallery.get_node("ArchiveDoor")
	var shortcut = archive.get_node("ShortcutDoor")
	var ui = game.get_node("UI")
	_check(archive_door._requirements_met(), "Archive door did not accept Gallery Prism")
	_check(not shortcut._requirements_met(), "Archive shortcut opened before puzzle")
	_check(archive.get_node("FirstStep/CollisionShape2D").one_way_collision and archive.get_node("SecondStep/CollisionShape2D").one_way_collision and archive.get_node("ThirdStep/CollisionShape2D").one_way_collision, "Archive platforms block climbing from below")
	_check(archive.get_node("FirstStep").position.y - archive.get_node("SecondStep").position.y < 70.0 and archive.get_node("SecondStep").position.y - archive.get_node("ThirdStep").position.y < 70.0, "Archive jump heights exceed basic jump")
	state.set_current_room("echo_gallery")
	var gallery_lamp = gallery.get_node("GalleryLamp/RespawnPoint")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), gallery_lamp.global_position, "echo_gallery_lamp", "Whispering Gallery Lamp", "echo_gallery"), "Pre-puzzle save failed")
	archive_door.activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_depths", "First Archive approach skipped Resonant Depths")
	game.get_node("EchoDepths/UpperShortcutDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_archive", "Archive entry transition failed")
	_check(game.get_node("AmbientSoundscape").current_track == "echo_archive", "Archive ambience did not start")
	_check("ALIGN MIRRORS 0/3" in ui.objective_label.text, "Archive objective missing")
	_check(not archive.get_node("StarMirror").activate(player) and archive.step == 0, "Wrong first mirror did not reset")
	_check(archive.get_node("RootMirror").activate(player) and archive.step == 1, "Root mirror did not activate")
	_check(not archive.get_node("EchoMirror").activate(player) and archive.step == 0, "Wrong mirror did not reset progress")
	_check(archive.get_node("RootMirror").activate(player), "Root mirror failed on retry")
	_check(archive.get_node("StarMirror").activate(player) and archive.step == 2, "Star mirror did not activate")
	_check("2/3" in ui.objective_label.text, "Archive HUD did not track puzzle progress")
	_check(archive.get_node("EchoMirror").activate(player), "Echo mirror did not complete puzzle")
	_check(state.has_item("memory_sigil_echo"), "Echo Memory Sigil not awarded")
	_check(shortcut._requirements_met(), "Archive shortcut stayed locked")
	_check(not archive.get_node("EchoMirror").activate(player) and int(state.inventory.get("memory_sigil_echo", 0)) == 1, "Sigil can be farmed")
	_check(state.load_game(), "Pre-puzzle save could not load")
	_check(not state.has_item("memory_sigil_echo") and not bool(state.unlocked_shortcuts.get("prism_archive_solved", false)), "Unsaved puzzle completion survived load")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	gallery = game.get_node("EchoGallery")
	archive = game.get_node("PrismArchive")
	_check(not archive.solved and archive.step == 0, "Archive did not reset to last lamp state")
	gallery.get_node("ArchiveDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_depths", "Unsaved first-visit route did not reset with the lamp")
	game.get_node("EchoDepths/UpperShortcutDoor").activate(player)
	await create_timer(0.5).timeout
	_check(archive.get_node("RootMirror").activate(player), "Root mirror failed after reload")
	_check(archive.get_node("StarMirror").activate(player), "Star mirror failed after reload")
	_check(archive.get_node("EchoMirror").activate(player), "Echo mirror failed after reload")
	archive.get_node("ShortcutDoor").activate(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_grotto", "Archive shortcut did not return to Grotto")
	_check(player.global_position.distance_to(game.get_node("EchoGrotto/ArchiveReturn").global_position) < 45.0, "Archive shortcut reached wrong marker")
	var grotto_lamp = game.get_node("EchoGrotto/GrottoLamp/RespawnPoint")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), grotto_lamp.global_position, "echo_grotto_lamp", "Echo Grotto Lamp", "echo_grotto"), "Completed puzzle save failed")
	_check(state.load_game(), "Completed puzzle save could not load")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	archive = game.get_node("PrismArchive")
	_check(archive.solved and archive.step == 3, "Saved puzzle completion not restored")
	_check(state.has_item("memory_sigil_echo"), "Saved Memory Sigil not restored")
	_check(archive.get_node("ShortcutDoor")._requirements_met(), "Saved Archive shortcut not restored")
	_check(archive.get_node("RootMirror").is_lit and archive.get_node("StarMirror").is_lit and archive.get_node("EchoMirror").is_lit, "Saved mirror visuals not restored")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("PRISM ARCHIVE TEST PASSED")
		quit(0)
	else:
		print("PRISM ARCHIVE TEST FAILED: ", failures)
		quit(1)
