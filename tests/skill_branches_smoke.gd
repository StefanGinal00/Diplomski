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
	state.save_path = "res://_tmp_skill_branches_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var ui = game.get_node("UI")
	var player = game.get_node("Player")
	_check(not player.can_unlock_advanced_mastery("sword") and not player.try_unlock_advanced_mastery("sword"), "Sword tier two skipped its prerequisite")
	player.add_skill_points(6)
	ui._toggle_skills()
	await process_frame
	for button in [ui.sword_reach_button, ui.bow_piercing_button, ui.staff_flow_button]:
		_check(button.get_global_rect().intersection(ui.skill_panel.get_global_rect()).get_area() == button.get_global_rect().get_area(), "Advanced skill button %s is outside the skill panel: %s vs %s" % [button.name, button.get_global_rect(), ui.skill_panel.get_global_rect()])
	_check(not ui.sword_reach_button.get_global_rect().intersects(ui.bow_mastery_button.get_global_rect()), "Advanced skill buttons overlap")
	ui._toggle_skills()
	ui._on_sword_mastery_pressed()
	_check(player.sword_mastery_unlocked and not ui.sword_reach_button.disabled, "Sword reach did not unlock after mastery")
	ui._on_sword_reach_pressed()
	_check(player.sword_reach_unlocked and is_equal_approx((player.attack_cast.shape as RectangleShape2D).size.x, 50.0), "Sword reach did not extend the hitbox")
	_check(is_equal_approx(absf(player.attack_cast.position.x), player.attack_offset + 8.0), "Sword reach hitbox is misplaced")
	ui.selected_item_id = "worn_sword"
	ui._update_item_details()
	_check("RANGE: 50" in ui.item_description_label.text and "DAMAGE: 2" in ui.item_description_label.text, "Inventory does not show skill-adjusted sword stats")
	state.add_item("hunter_bow")
	_check(not player.can_unlock_advanced_mastery("bow"), "Bow tier two skipped its prerequisite")
	ui._on_bow_mastery_pressed()
	ui._on_bow_piercing_pressed()
	_check(player.bow_piercing_unlocked, "Bow piercing skill did not unlock")
	state.equip_item("hunter_bow")
	state.cycle_weapon()
	_check(player._try_bow_attack(state.get_item_definition("hunter_bow")), "Piercing bow could not fire")
	var arrow = get_nodes_in_group("player_projectile").back()
	_check(arrow.remaining_hits == 2 and arrow.arrow_type == "basic_arrow", "Basic arrow did not gain one pierce")
	_check("PIERCE 2" in ui.ammo_status_label.text, "Bow HUD did not explain piercing arrows")
	var first_target = game.get_node("VerticalChamber/UpperShaftSentry")
	var second_target = game.get_node("VerticalChamber/LowerShaftSentry")
	var first_health: int = first_target.current_health
	var second_health: int = second_target.current_health
	arrow._on_body_entered(first_target)
	await process_frame
	_check(first_target.current_health == first_health - arrow.damage and arrow.remaining_hits == 1 and not arrow.is_queued_for_deletion(), "Piercing arrow stopped at the first target")
	arrow._on_body_entered(second_target)
	await process_frame
	_check(second_target.current_health == second_health - 2, "Piercing arrow did not damage the second target")
	state.add_item("ember_arrow")
	state.select_arrow_type("ember_arrow")
	_check(player._try_bow_attack(state.get_item_definition("hunter_bow")), "Ember arrow could not fire")
	var ember_arrow = get_nodes_in_group("player_projectile").back()
	_check(ember_arrow.arrow_type == "ember_arrow" and ember_arrow.remaining_hits == 1, "Special arrow incorrectly gained free piercing")
	state.add_item("apprentice_staff")
	ui._on_staff_mastery_pressed()
	ui._on_staff_flow_pressed()
	_check(player.staff_flow_unlocked, "Staff mana flow did not unlock")
	state.equip_item("apprentice_staff")
	player.current_mana = 0
	player.mana_regen_delay_remaining = 0.0
	player.mana_regen_progress = 0.0
	player._update_mana(2.0)
	_check(player.current_mana == 3, "Staff mana flow did not accelerate regeneration")
	state.cycle_weapon()
	player.current_mana = 0
	player.mana_regen_progress = 0.0
	player._update_mana(2.0)
	_check(player.current_mana == 2, "Staff mana flow remained active with the sword")
	_check(player.skill_points == 0 and not player.try_unlock_advanced_mastery("sword"), "Advanced skills spent the wrong amount of points")
	ui._toggle_skills()
	await process_frame
	for button in [ui.sword_mastery_button, ui.sword_reach_button, ui.bow_mastery_button, ui.bow_piercing_button, ui.staff_mastery_button, ui.staff_flow_button]:
		_check(button.get_global_rect().intersection(ui.skill_panel.get_global_rect()).get_area() == button.get_global_rect().get_area(), "Unlocked skill button %s overflows the panel" % button.name)
	ui._toggle_skills()
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "skills_test", "Skills Test", "training_passage"), "Advanced skills did not save")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Advanced skills did not load")
	var resumed = load("res://Game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	await process_frame
	var resumed_player = resumed.get_node("Player")
	_check(resumed_player.sword_reach_unlocked and resumed_player.bow_piercing_unlocked and resumed_player.staff_flow_unlocked, "Advanced skill flags were not restored")
	_check(is_equal_approx((resumed_player.attack_cast.shape as RectangleShape2D).size.x, 50.0), "Saved sword reach did not restore its hitbox")
	state.delete_save()
	for projectile in get_nodes_in_group("player_projectile"):
		projectile.queue_free()
	resumed.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("SKILL BRANCHES TEST PASSED")
		quit(0)
	else:
		print("SKILL BRANCHES TEST FAILED: ", failures)
		quit(1)
