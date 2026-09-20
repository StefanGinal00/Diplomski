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
	state.save_path = "res://_tmp_weapon_identity_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var ui = game.get_node("UI")
	var player: Player = game.get_node("Player")
	_check(state.get_enemy_family(game.get_node("Enemy")) == "demon", "Passage demon family tag missing")
	_check(state.get_enemy_family(game.get_node("RangedEnemy")) == "construct", "Sentry construct family tag missing")
	var matriarch = game.get_node("ResonanceSanctum/EchoMatriarch")
	_check(state.get_enemy_family(matriarch) == "spirit" and matriarch.is_in_group("boss"), "Boss and Spirit tags must coexist")
	_check(state.get_weapon_target_bonus("spiritglass_blade", matriarch) == 1, "Spiritglass bonus did not affect Spirit boss")
	_check(state.get_weapon_target_bonus("spiritglass_blade", game.get_node("Enemy")) == 0, "Spiritglass bonus affected non-Spirit enemy")
	ui._open_shop(game.get_node("WayfarerMerchant"))
	_check(ui.shop_item_list.item_count == 10, "Spiritglass Blade appeared before Warden victory")
	state.add_gold(220)
	ui.selected_shop_item_id = "spiritglass_blade"
	ui._on_shop_buy_pressed()
	_check(not state.has_item("spiritglass_blade"), "Spiritglass Blade bypassed boss unlock")
	state.mark_boss_defeated("abyss_warden")
	ui._populate_shop()
	_check(ui.shop_item_list.item_count == 13, "Specialized weapons did not appear after Warden victory")
	var blade_index := -1
	for index in range(ui.shop_item_list.item_count):
		if str(ui.shop_item_list.get_item_metadata(index)) == "spiritglass_blade":
			blade_index = index
			break
	_check(blade_index >= 0, "Spiritglass shop entry is missing")
	if blade_index >= 0:
		ui.shop_item_list.select(blade_index)
		ui._on_shop_item_selected(blade_index)
		_check(ui.shop_item_description_label.get_minimum_size().y <= ui.shop_item_description_label.size.y, "Spiritglass shop description is clipped")
		ui._on_shop_buy_pressed()
	_check(state.has_item("spiritglass_blade") and state.gold == 65, "Spiritglass purchase charged incorrectly")
	_check(state.get_active_weapon_id() == "spiritglass_blade", "Purchased Spiritglass Blade did not equip")
	ui._close_shop()
	var attack_shape := player.attack_cast.shape as RectangleShape2D
	_check(attack_shape != null and is_equal_approx(attack_shape.size.x, 46.0), "Spiritglass reach was not applied to melee hitbox")
	_check(is_equal_approx(player.attack_visual.color.b, 1.0), "Spiritglass swing has no distinct tint")
	state.equip_item("worn_sword")
	_check(is_equal_approx(attack_shape.size.x, 34.0), "Switching to Basic Sword did not restore its reach")
	state.equip_item("spiritglass_blade")
	_check(is_equal_approx(attack_shape.size.x, 46.0), "Switching back to Spiritglass did not restore its reach")
	ui._toggle_inventory()
	for index in range(ui.inventory_item_list.item_count):
		if str(ui.inventory_item_list.get_item_metadata(index)) == "spiritglass_blade":
			ui.inventory_item_list.select(index)
			ui._on_inventory_item_selected(index)
			break
	_check("Spirits" in ui.item_description_label.text and ui.item_description_label.get_minimum_size().y <= ui.item_description_label.size.y, "Spiritglass inventory bonus is hidden or clipped")
	ui._close_inventory()
	var spirit = load("res://EchoShade.tscn").instantiate()
	spirit.max_health = 20
	spirit.position = player.position + Vector2(39.0, 0.0)
	game.add_child(spirit)
	player._try_melee_attack(state.get_item_definition("spiritglass_blade"))
	_check(spirit.current_health == 18, "Spiritglass melee strike did not apply Spirit bonus")
	spirit.queue_free()
	await process_frame
	var demon = load("res://Enemy.tscn").instantiate()
	demon.max_health = 20
	demon.position = player.position + Vector2(39.0, 0.0)
	game.add_child(demon)
	player._try_melee_attack(state.get_item_definition("spiritglass_blade"))
	_check(demon.current_health == 19, "Spiritglass bonus incorrectly affected Demon melee target")
	demon.queue_free()
	state.add_item("iron_fragment", 2)
	state.add_item("ether_dust")
	_check(state.upgrade_weapon("spiritglass_blade") and state.get_weapon_upgrade_level("spiritglass_blade") == 1, "Spiritglass independent forge rank failed")
	_check(state.get_weapon_upgrade_level("worn_sword") == 0, "Forging Spiritglass changed starter sword rank")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "identity_test", "Identity Test", "training_passage"), "Weapon identity progress did not save")
	state.inventory.erase("spiritglass_blade")
	state.weapon_upgrades.clear()
	state.defeated_bosses.clear()
	_check(state.load_game(), "Weapon identity save did not load")
	_check(state.has_item("spiritglass_blade") and state.get_weapon_upgrade_level("spiritglass_blade") == 1 and state.get_active_weapon_id() == "spiritglass_blade", "Spiritglass ownership, rank or equipment was not restored")
	_check(bool(state.defeated_bosses.get("abyss_warden", false)), "Warden shop unlock did not persist")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("WEAPON IDENTITY TEST PASSED")
		quit(0)
	else:
		print("WEAPON IDENTITY TEST FAILED: ", failures)
		quit(1)
