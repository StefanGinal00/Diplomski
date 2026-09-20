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
	state.save_path = "res://_tmp_defense_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var ui = game.get_node("UI")
	var player = game.get_node("Player")
	state.add_gold(250)
	ui._open_shop(game.get_node("WayfarerMerchant"))
	ui.selected_shop_item_id = "guardian_band"
	ui._update_shop_item_details()
	_check(not ui.shop_buy_button.disabled, "Guardian Band cannot be bought")
	ui._on_shop_buy_pressed()
	_check(state.gold == 160 and state.has_item("guardian_band"), "Guardian Band purchase charged incorrectly")
	_check(state.get_equipped_defense_id() == "guardian_band", "Guardian Band did not auto-equip")
	ui._on_shop_buy_pressed()
	_check(state.gold == 160 and int(state.inventory.get("guardian_band", 0)) == 1, "Defense gear can be bought twice")
	_check(not state.equip_item("guardian_band", "primary_weapon"), "Defense gear equipped as a weapon")
	_check(not state.equip_item("worn_sword", "defense"), "Weapon equipped as defense")
	ui._close_shop()
	player.current_health = player.max_health
	player.is_invulnerable = false
	player.take_damage(2)
	_check(player.current_health == player.max_health - 1, "Guardian Band did not mitigate a heavy hit")
	player.invulnerability_timer.stop()
	player.is_invulnerable = false
	ui.selected_item_id = "guardian_band"
	ui._update_item_details()
	_check(ui.item_action_button.text == "Unequip", "Equipped defense cannot be removed from inventory")
	ui._on_inventory_action_pressed()
	_check(state.get_equipped_defense_id().is_empty(), "Inventory did not unequip defensive gear")
	player.take_damage(2)
	_check(player.current_health == player.max_health - 3, "Unequipped Guardian Band still mitigates damage")
	ui._open_shop(game.get_node("WayfarerMerchant"))
	ui.selected_shop_item_id = "wind_cloak"
	ui._update_shop_item_details()
	ui._on_shop_buy_pressed()
	_check(state.gold == 50 and state.get_equipped_defense_id() == "wind_cloak", "Wind Cloak purchase or equip failed")
	ui._close_shop()
	player.dash_unlocked = true
	_check(is_equal_approx(player.get_effective_dash_cooldown(), player.dash_cooldown * 0.75), "Wind Cloak cooldown bonus missing")
	_check(player.try_dash() and is_equal_approx(player.dash_cooldown_remaining, player.dash_cooldown * 0.75), "Dash did not use Wind Cloak cooldown")
	ui._update_dash_status()
	_check(is_equal_approx(ui.dash_cooldown_bar.max_value, player.get_effective_dash_cooldown()), "Dash HUD does not reflect Wind Cloak")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "defense_test", "Defense Test", "training_passage"), "Defensive loadout did not save")
	state.equipped_items["defense"] = ""
	_check(state.load_game(), "Defensive loadout did not load")
	_check(state.get_equipped_defense_id() == "wind_cloak" and state.has_item("guardian_band"), "Defensive gear was not restored from save")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("DEFENSE TEST PASSED")
		quit(0)
	else:
		print("DEFENSE TEST FAILED: ", failures)
		quit(1)
