extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_npc_portraits_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var ui := game.get_node("UI")
	var hero := game.get_node("Player")
	hero.get_node("Camera2D").enabled = false
	state.set_current_room("echo_haven")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var resident := game.get_node("EchoHaven/Neris")
	hero.global_position = resident.global_position + Vector2(-32, -1)
	resident._on_body_entered(hero)
	resident.get_node("ResidentMotion")._process(0.1)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(480, 230) - resident.global_position * 2.5)
	ui._on_npc_interaction_requested(resident)
	ui.active_town_line = resident.timeline_dialogue_lines[0]
	ui._update_dialogue_content()
	if ui.zone_title_tween != null and ui.zone_title_tween.is_valid():
		ui.zone_title_tween.kill()
	ui.zone_title_panel.hide()
	await _capture("neris_dialogue")
	ui._close_dialogue()
	state.set_current_room("training_passage")
	var merchant := game.get_node("WayfarerMerchant")
	hero.global_position = merchant.global_position + Vector2(30, -1)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(480, 270) - merchant.global_position * 2.5)
	state.merchant_discount_unlocked = true
	ui._open_shop(merchant)
	await _capture("orin_shop")
	ui.shop_item_description_scroll.scroll_vertical = 10000
	await process_frame
	await _capture("orin_shop_details")
	ui._on_shop_forge_tab_pressed()
	await _capture("orin_forge")
	ui._close_shop()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
