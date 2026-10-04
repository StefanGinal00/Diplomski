extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_field_records_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	state.set_current_room("shaft_gallery")
	await process_frame
	var cache: Node2D
	for node in game.find_children("*", "Area2D", true, false):
		if node.get_script() == preload("res://ResonanceCache.gd") and node.cache_id == "gallery_supply": cache = node
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.global_position = cache.global_position + Vector2(0, -50)
	camera.zoom = Vector2(1.6, 1.6)
	camera.make_current()
	camera.force_update_scroll()
	var player: Player = game.get_node("Player")
	player.global_position = cache.global_position + Vector2(-45, -16)
	cache._on_body_entered(player)
	var ui := game.get_node("UI")
	ui._dismiss_zone_title()
	await _capture("records_cache")
	for event in cache.required_event_ids: state.unlock_shortcut(event)
	cache.open(player)
	await create_timer(0.3).timeout
	await _capture("records_discovery")
	ui._clear_memory_reveals()
	ui._toggle_quests()
	await process_frame
	ui.quest_tracker_label.get_parent().scroll_vertical = 10000
	await _capture("records_journal")
	ui._close_side_panels()
	state.opened_caches["archive_shelf"] = true
	ui._on_npc_interaction_requested(game.get_node("EchoHaven/Ivara"))
	await _capture("records_ivara")
	ui._close_dialogue()
	game.queue_free()
	camera.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
