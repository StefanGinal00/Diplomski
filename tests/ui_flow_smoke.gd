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
	state.save_path = "res://_tmp_ui_flow_save.json"
	state.reset_to_main_menu()
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var ui = game.get_node("UI")
	var soundscape = game.get_node("AmbientSoundscape")
	_check(ui.main_menu_panel.visible, "Start menu missing")
	_check(soundscape.current_track.is_empty(), "Music started before selecting a mode")
	_check(ui.main_menu_backdrop.visible, "Start menu backdrop missing")
	_check(not ui.hud_panel.visible, "HUD leaked through start menu")
	_check(not ui.skill_panel.visible and not ui.quest_panel.visible, "Side panels visible at start")
	var normal_description = ui.get_node("MainMenuPanel/NormalDescription")
	var hardcore_description = ui.get_node("MainMenuPanel/HardcoreDescription")
	var warning = ui.get_node("MainMenuPanel/WarningLabel")
	_check(normal_description.get_minimum_size().y <= normal_description.size.y, "Normal description is clipped")
	_check(hardcore_description.get_minimum_size().y <= hardcore_description.size.y, "Hardcore description is clipped")
	_check(normal_description.position.y + normal_description.size.y < warning.position.y, "Normal text overlaps footer")
	_check(hardcore_description.position.y + hardcore_description.size.y < warning.position.y, "Hardcore text overlaps footer")
	var ground = game.get_node("Ground")
	var collision = ground.get_node("CollisionShape2D")
	var left_edge: float = ground.position.x + collision.position.x - collision.shape.size.x / 2.0
	_check(left_edge < game.get_node("WayfarerMerchant").position.x - 30.0, "Ground does not reach merchant")
	ui._start_normal_mode()
	_check(soundscape.current_track == "training_passage", "Training ambience did not start")
	_check(not ui.main_menu_panel.visible and not ui.main_menu_backdrop.visible, "Start menu remained visible")
	_check(ui.hud_panel.visible and ui.menu_bar_panel.visible, "Compact HUD not visible")
	var hud_rect: Rect2 = ui.hud_panel.get_global_rect()
	var objective_rect: Rect2 = ui.objective_panel.get_global_rect()
	var menu_rect: Rect2 = ui.menu_bar_panel.get_global_rect()
	_check(not hud_rect.intersects(objective_rect), "HP HUD overlaps objective")
	_check(not objective_rect.intersects(menu_rect), "Objective overlaps menu buttons")
	_check(ui.zone_title_panel.visible and "TRAINING PASSAGE" in ui.zone_title_label.text, "Starting zone title missing")
	_check(not ui.skill_panel.visible and not ui.quest_panel.visible, "Side panels opened automatically")
	var xp_before: int = get_nodes_in_group("xp_orb").size()
	var gold_before: int = get_nodes_in_group("gold_pickup").size()
	game.get_node("Enemy").take_damage(999)
	await process_frame
	_check(get_nodes_in_group("xp_orb").size() >= xp_before + 1, "Enemy XP did not spawn after deferred drop")
	_check(get_nodes_in_group("gold_pickup").size() >= gold_before + 1, "Enemy gold did not spawn after deferred drop")
	var player = game.get_node("Player")
	player.global_position = game.get_node("WayfarerMerchant").global_position
	await create_timer(0.25).timeout
	_check(player.is_on_floor(), "Player cannot stand at Orin's position")
	_check(game.get_node("WayfarerMerchant").player_in_range == player, "Orin cannot be interacted with")
	ui._toggle_skills()
	_check(ui.skill_panel.visible and paused, "Skills button did not open and pause")
	ui._toggle_quests()
	_check(ui.quest_panel.visible and not ui.skill_panel.visible and paused, "Quest menu did not replace skills")
	ui._toggle_inventory()
	_check(ui.inventory_panel.visible and not ui.quest_panel.visible and paused, "Inventory did not replace quest menu")
	ui._close_inventory()
	_check(not paused, "Closing inventory did not resume")
	ui._toggle_map_button()
	_check(ui.world_map_panel.visible and paused, "Map button did not open")
	ui._close_world_map()
	_check(not paused, "Closing map did not resume")
	ui._pause_game()
	_check(ui.music_button.text == "Ambient Music: On", "Music switch was not available")
	ui._on_music_button_pressed()
	_check(not soundscape.enabled and not state.music_enabled and ui.music_button.text == "Ambient Music: Off", "Music did not mute")
	ui._on_music_button_pressed()
	_check(soundscape.enabled and state.music_enabled and soundscape.current_track == "training_passage", "Music did not resume")
	ui._resume_game()
	ui._open_shop(game.get_node("WayfarerMerchant"))
	_check(ui.shop_panel.visible and ui.shop_dimmer.visible and paused, "Shop overlay did not open cleanly")
	var last_item: int = ui.shop_item_list.item_count - 1
	ui.shop_item_list.select(last_item)
	ui._on_shop_item_selected(last_item)
	ui.shop_item_list.grab_focus()
	var down := InputEventKey.new()
	down.keycode = KEY_DOWN
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	_check(ui.shop_item_list.get_selected_items()[0] == 0, "Down from Ether Dust did not wrap to first item")
	_check(ui.get_viewport().gui_get_focus_owner() == ui.shop_item_list, "Shop list lost keyboard focus")
	var up := InputEventKey.new()
	up.keycode = KEY_UP
	up.pressed = true
	Input.parse_input_event(up)
	await process_frame
	_check(ui.shop_item_list.get_selected_items()[0] == last_item, "Up from first item did not wrap to Ether Dust")
	ui._close_shop()
	_check(not ui.shop_dimmer.visible and not paused, "Closing shop did not restore game")
	ui._open_shop(game.get_node("WayfarerMerchant"))
	var dimmer = ui.shop_dimmer
	ui.shop_dimmer = null
	ui._close_shop()
	_check(not dimmer.visible and not paused, "Shop did not recover a missing dimmer reference")
	dimmer.queue_free()
	await process_frame
	ui.shop_dimmer = null
	ui._open_shop(game.get_node("WayfarerMerchant"))
	ui._close_shop()
	_check(not ui.shop_panel.visible and not paused, "Shop could not close without a dimmer node")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("UI FLOW TEST PASSED")
		quit(0)
	else:
		print("UI FLOW TEST FAILED: ", failures)
		quit(1)
