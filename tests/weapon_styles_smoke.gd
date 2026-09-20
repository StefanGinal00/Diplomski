extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _select_shop_item(ui, item_id: String) -> bool:
	for index in range(ui.shop_item_list.item_count):
		if str(ui.shop_item_list.get_item_metadata(index)) == item_id:
			ui.shop_item_list.select(index)
			ui._on_shop_item_selected(index)
			return true
	return false


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_weapon_styles_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var ui = game.get_node("UI")
	var player: Player = game.get_node("Player")
	state.add_gold(1000)
	state.mark_boss_defeated("abyss_warden")
	ui._open_shop(game.get_node("WayfarerMerchant"))
	_check(ui.shop_item_list.item_count == 13, "Post-Warden weapon variants are missing from shop")
	_check(_select_shop_item(ui, "thorn_bow"), "Thorn Bow shop entry missing")
	_check(ui.shop_item_description_label.get_minimum_size().y <= ui.shop_item_description_label.size.y, "Thorn Bow shop description is clipped")
	ui._on_shop_buy_pressed()
	_check(state.has_item("thorn_bow") and str(state.equipped_items.get("secondary_weapon", "")) == "thorn_bow", "Thorn Bow purchase or equip failed")
	ui._close_shop()
	_check(state.cycle_weapon() and state.get_active_weapon_id() == "thorn_bow", "Could not switch to Thorn Bow")
	_check("THORN BOW" in ui.weapon_status_label.text and "AMMO" in ui.ammo_status_label.text, "Thorn Bow HUD does not show ammo")
	_check(player._try_bow_attack(state.get_item_definition("thorn_bow")), "Thorn Bow could not fire")
	var arrow = get_nodes_in_group("player_projectile").back()
	_check(arrow.weapon_id == "thorn_bow" and arrow.damage == 1 and is_equal_approx(arrow.lifetime, 420.0 / 430.0), "Thorn Bow damage or range stats were not applied")
	var beast = load("res://ShaftCrawler.tscn").instantiate()
	beast.max_health = 20
	beast.position = Vector2(-500, -500)
	game.add_child(beast)
	arrow._on_body_entered(beast)
	await process_frame
	_check(beast.current_health == 18, "Thorn Bow did not deal bonus damage to Beast")
	var demon = load("res://Enemy.tscn").instantiate()
	demon.max_health = 20
	demon.position = Vector2(-550, -500)
	game.add_child(demon)
	_check(player._try_bow_attack(state.get_item_definition("thorn_bow")), "Thorn Bow second shot failed")
	var plain_arrow = get_nodes_in_group("player_projectile").back()
	plain_arrow._on_body_entered(demon)
	await process_frame
	_check(demon.current_health == 19, "Thorn Bow bonus incorrectly affected Demon")
	state.add_item("ember_arrow")
	_check(player.toggle_arrow_type() and state.selected_arrow_type == "ember_arrow", "Thorn Bow could not select Ember Arrow")
	ui._toggle_inventory()
	for index in range(ui.inventory_item_list.item_count):
		if str(ui.inventory_item_list.get_item_metadata(index)) == "ember_arrow":
			ui.inventory_item_list.select(index)
			ui._on_inventory_item_selected(index)
			break
	_check("Selected" in ui.item_action_button.text, "Inventory did not recognize Ember Arrow on alternate bow")
	ui._close_inventory()
	ui._open_shop(game.get_node("WayfarerMerchant"))
	_check(_select_shop_item(ui, "sunder_staff"), "Sunder Staff shop entry missing")
	_check(ui.shop_item_description_label.get_minimum_size().y <= ui.shop_item_description_label.size.y, "Sunder Staff shop description is clipped")
	ui._on_shop_buy_pressed()
	_check(state.has_item("sunder_staff") and state.get_active_weapon_id() == "sunder_staff", "Sunder Staff purchase or equip failed")
	_check(state.unlocked_spells.has("arc_bolt"), "Sunder Staff did not teach Arc Bolt")
	_check(_select_shop_item(ui, "frost_rune") and not ui.shop_buy_button.disabled, "Frost Rune incorrectly requires the old staff")
	ui._on_shop_buy_pressed()
	_check(state.unlocked_spells.has("frost_orb"), "Sunder Staff could not learn Frost Orb")
	ui._close_shop()
	_check("SUNDER STAFF" in ui.weapon_status_label.text and "SPELL" in ui.ammo_status_label.text, "Sunder Staff HUD does not show spells")
	var construct = load("res://ShaftSentry.tscn").instantiate()
	construct.max_health = 20
	construct.position = Vector2(-600, -500)
	game.add_child(construct)
	_check(player._try_staff_attack(state.get_item_definition("sunder_staff")), "Sunder Staff could not cast Arc Bolt")
	var bolt = get_nodes_in_group("player_projectile").back()
	_check(bolt.weapon_id == "sunder_staff" and bolt.damage == 3 and is_equal_approx(bolt.lifetime, 350.0 / 345.0), "Sunder Staff damage or range stats were not applied")
	bolt._on_body_entered(construct)
	await process_frame
	_check(construct.current_health == 16, "Sunder Staff did not deal bonus damage to Construct")
	_check(state.cycle_spell() and state.selected_spell == "frost_orb", "Sunder Staff could not switch spells")
	_check(player._try_staff_attack(state.get_item_definition("sunder_staff")), "Sunder Staff could not cast Frost Orb")
	var frost = get_nodes_in_group("player_projectile").back()
	_check(frost.damage == 2 and frost.remaining_hits == 2 and is_equal_approx(frost.lifetime, 350.0 / 230.0), "Frost Orb damage or range did not scale with Sunder Staff")
	frost._on_body_entered(construct)
	await process_frame
	_check(construct.current_health == 13, "Sunder Staff Frost Orb missed Construct bonus")
	player.skill_points = 2
	_check(player.can_unlock_weapon_mastery("bow") and player.can_unlock_weapon_mastery("staff"), "Alternate weapons did not unlock their class skills")
	_check(player.try_unlock_weapon_mastery("bow") and player.try_unlock_weapon_mastery("staff"), "Could not learn class skills with alternate weapons only")
	player.skill_points = 1
	_check(player.try_unlock_advanced_mastery("staff"), "Mana Flow could not be learned with alternate staff")
	player.current_mana = 1
	player.mana_regen_delay_remaining = 0.0
	player.mana_regen_progress = 0.0
	player._update_mana(0.7)
	_check(player.current_mana == 2, "Mana Flow did not work with alternate staff")
	state.add_item("ether_dust", 2)
	state.add_item("iron_fragment")
	_check(state.upgrade_weapon("sunder_staff") and state.get_weapon_upgrade_level("sunder_staff") == 1, "Sunder Staff forge recipe failed")
	_check(state.get_weapon_upgrade_level("apprentice_staff") == 0, "Sunder Staff forge rank leaked to Runed Staff")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "styles_test", "Styles Test", "training_passage"), "Weapon styles did not save")
	state.inventory.erase("thorn_bow")
	state.inventory.erase("sunder_staff")
	state.weapon_upgrades.clear()
	_check(state.load_game(), "Weapon styles save did not load")
	_check(state.has_item("thorn_bow") and state.has_item("sunder_staff") and state.get_weapon_upgrade_level("sunder_staff") == 1, "Weapon styles did not survive save/load")
	_check(state.get_active_weapon_id() == "sunder_staff" and state.selected_spell == "frost_orb", "Active staff or selected spell did not survive save/load")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("WEAPON STYLES TEST PASSED")
		quit(0)
	else:
		print("WEAPON STYLES TEST FAILED: ", failures)
		quit(1)
