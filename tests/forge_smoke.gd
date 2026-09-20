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
	state.save_path = "res://_tmp_forge_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var ui = game.get_node("UI")
	var player = game.get_node("Player")
	ui._open_shop(game.get_node("WayfarerMerchant"))
	_check(ui.shop_item_list.item_count == 10, "Forge materials or defensive gear are missing from the shop")
	ui._on_shop_forge_tab_pressed()
	_check(ui.shop_mode == "forge" and ui.shop_item_list.item_count == 1, "Forge did not list the starter sword")
	_check(not ui.shop_buy_tab_button.get_global_rect().intersects(ui.shop_forge_tab_button.get_global_rect()), "Forge tabs overlap")
	_check(ui.shop_quest_label.get_minimum_size().y <= ui.shop_quest_label.size.y, "Forge explanation is clipped")
	_check(ui.shop_buy_button.disabled, "Forge allowed an upgrade without materials")
	_check(not state.can_upgrade_weapon("hunter_bow") and not state.upgrade_weapon("hunter_bow"), "Forge upgraded a weapon not owned")
	state.add_gold(250)
	state.add_item("iron_fragment", 5)
	state.add_item("ether_dust", 1)
	_check(not ui.shop_buy_button.disabled, "Sword upgrade stayed disabled with enough resources")
	_check(ui.shop_item_description_label.get_minimum_size().y <= ui.shop_item_description_label.size.y, "Forge recipe text is clipped")
	ui._on_shop_buy_pressed()
	_check(state.get_weapon_upgrade_level("worn_sword") == 1, "Sword rank one missing")
	_check(state.gold == 200 and state.has_item("iron_fragment", 3), "Sword rank one charged incorrect resources")
	_check(state.get_weapon_damage_bonus("worn_sword") == 1 and state.get_weapon_cooldown_multiplier("worn_sword") == 1.0, "Rank one combat bonus incorrect")
	ui._on_shop_buy_pressed()
	_check(state.get_weapon_upgrade_level("worn_sword") == 2 and state.gold == 110, "Sword rank two missing or incorrectly priced")
	_check(not state.has_item("iron_fragment") and not state.has_item("ether_dust"), "Rank two did not consume materials")
	_check(is_equal_approx(state.get_weapon_cooldown_multiplier("worn_sword"), 0.88), "Rank two speed bonus missing")
	_check(not state.can_upgrade_weapon("worn_sword") and state.get_weapon_upgrade_cost("worn_sword").has("iron_fragment"), "Rank three must require new materials")
	state.merchant_discount_unlocked = true
	_check(int(state.get_weapon_upgrade_cost("hunter_bow").get("gold", 0)) == 48, "Forge did not honor Orin's discount")
	state.merchant_discount_unlocked = false
	_check("+2" in ui.weapon_status_label.text, "HUD did not show forged weapon rank")
	state.add_gold(700)
	state.add_item("iron_fragment", 13)
	state.add_item("ether_dust", 2)
	state.add_item("resonance_shard", 3)
	for rank in [3, 4, 5]:
		_check(not ui.shop_buy_button.disabled, "Forge rank %d stayed disabled with all materials" % rank)
		_check(ui.shop_item_description_label.get_minimum_size().y <= ui.shop_item_description_label.size.y, "Forge rank %d recipe text is clipped" % rank)
		ui._on_shop_buy_pressed()
		_check(state.get_weapon_upgrade_level("worn_sword") == rank, "Forge rank %d failed" % rank)
	_check(state.get_weapon_damage_bonus("worn_sword") == 3 and is_equal_approx(state.get_weapon_cooldown_multiplier("worn_sword"), 0.82), "Rank five combat bonuses incorrect")
	_check(player.weapon_aura.visible and "+5" in ui.weapon_status_label.text, "Rank five glow or HUD mark missing")
	_check(state.get_weapon_upgrade_cost("worn_sword").is_empty() and not state.upgrade_weapon("worn_sword"), "Maximum rank could be purchased twice")
	state.set_zone_tier("echo_grotto", 1)
	ui._on_shop_buy_tab_pressed()
	_check(ui.shop_item_list.item_count == 11, "Resonance Shard did not unlock in Orin's shop")
	var shard_index: int = ui.shop_item_list.item_count - 1
	_check(str(ui.shop_item_list.get_item_metadata(shard_index)) == "resonance_shard", "Resonance Shard shop entry missing")
	ui.shop_item_list.select(shard_index)
	ui._on_shop_item_selected(shard_index)
	var gold_before_shard: int = state.gold
	ui._on_shop_buy_pressed()
	_check(state.has_item("resonance_shard") and state.gold == gold_before_shard - 140, "Resonance Shard purchase failed")
	ui._close_shop()
	state.add_gold(200)
	state.add_item("hunter_bow")
	state.add_item("iron_fragment", 2)
	_check(state.upgrade_weapon("hunter_bow"), "Bow upgrade failed")
	state.equip_item("hunter_bow")
	state.cycle_weapon()
	_check(not player.weapon_aura.visible, "Sword glow stayed active after switching weapons")
	_check(player._try_bow_attack(state.get_item_definition("hunter_bow")), "Forged bow could not fire")
	var bow_projectile: Node = get_nodes_in_group("player_projectile").back()
	_check(bow_projectile.damage == 2, "Bow upgrade did not increase arrow damage")
	state.add_item("apprentice_staff")
	state.add_item("ether_dust", 2)
	_check(state.upgrade_weapon("apprentice_staff"), "Staff upgrade failed")
	state.equip_item("apprentice_staff")
	_check(player._try_staff_attack(state.get_item_definition("apprentice_staff")), "Forged staff could not cast")
	var staff_projectile: Node = get_nodes_in_group("player_projectile").back()
	_check(staff_projectile.damage == 3, "Staff upgrade did not increase spell damage")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "forge_test", "Forge Test", "training_passage"), "Forged progress did not save")
	state.weapon_upgrades.clear()
	_check(state.load_game(), "Forged progress did not load")
	_check(state.get_weapon_upgrade_level("worn_sword") == 5 and state.get_weapon_upgrade_level("hunter_bow") == 1 and state.get_weapon_upgrade_level("apprentice_staff") == 1, "Weapon upgrades did not survive save/load")
	state.delete_save()
	for projectile in get_nodes_in_group("player_projectile"):
		projectile.queue_free()
	await process_frame
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("FORGE TEST PASSED")
		quit(0)
	else:
		print("FORGE TEST FAILED: ", failures)
		quit(1)
