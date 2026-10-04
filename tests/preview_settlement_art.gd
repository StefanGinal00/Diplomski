extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_art_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var hero := game.get_node("Player")
	hero.get_node("Camera2D").enabled = false
	for data in [["CinderHearth/Mira", "ash_hearth", "mira"], ["CinderHearth/Tarin", "ash_hearth", "tarin"], ["CinderHearth/Quartermaster", "ash_hearth", "korin"], ["CinderHearth/Anvil", "ash_hearth", "selen"], ["EchoHaven/GlowmarketTrader", "echo_haven", "nalim"], ["EchoHaven/Ivara", "echo_haven", "ivara"], ["StarfallCitadel/MarketTrader", "starfall_citadel", "nalia"], ["StarfallCitadel/Apothecary", "starfall_citadel", "aurel"]]:
		state.set_current_room(data[1])
		var npc := game.get_node(data[0]) as Node2D
		hero.global_position = npc.global_position + Vector2(-35, -1)
		root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(480, 230) - npc.global_position * 2.5)
		var art := npc.get_parent().get_node_or_null("PaintedBackdrop")
		if art != null:
			art._process(0.1)
		ui._on_npc_interaction_requested(npc)
		if ui.zone_title_tween != null and ui.zone_title_tween.is_valid():
			ui.zone_title_tween.kill()
		ui.zone_title_panel.hide()
		await _capture(data[2] + "_settlement")
		ui._close_dialogue()
		ui._close_shop()
	ui.hide()
	hero.hide()
	for data in [["EchoHaven", "echo_haven", Vector2(3000, -190), "echo_haven_painted"], ["CinderHearth", "ash_hearth", Vector2(2680, 140), "cinder_hearth_painted"]]:
		state.set_current_room(data[1])
		var room := game.get_node(data[0]) as Node2D
		var center := room.to_global(data[2])
		root.canvas_transform = Transform2D(Vector2(1.0, 0), Vector2(0, 1.0), Vector2(480, 270) - center)
		room.get_node("PaintedBackdrop")._process(0.1)
		await _capture(data[3])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
