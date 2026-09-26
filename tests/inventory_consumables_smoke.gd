extends "res://tests/shaft_hollow_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_inventory_consumables_save.json"
	state.start_new_game("normal")
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	var ui := game.get_node("UI")
	state.add_item("healing_herb", 2)
	ui.selected_item_id = "healing_herb"
	ui._update_item_details()
	_check(ui.item_action_button.disabled, "Full-health herb button enabled")
	ui._on_inventory_action_pressed()
	_check(state.inventory.get("healing_herb", 0) == 2, "Full-health click wasted an herb")
	player.take_damage(1)
	ui.selected_item_id = "healing_herb"
	ui._update_item_details()
	_check(not ui.item_action_button.disabled, "Injured player cannot use an herb")
	ui._on_inventory_action_pressed()
	_check(player.current_health == 5 and state.inventory.get("healing_herb", 0) == 1, "Herb did not heal up to the cap and consume exactly one")
	# A stale selection must not apply a consumable absent from the inventory.
	ui.selected_item_id = "life_bloom"
	ui._on_inventory_action_pressed()
	_check(not player.second_breath_active, "Unowned Life Bloom granted Second Breath")
	# Reset only the fixture if the regression above reproduced the old defect.
	player.second_breath_active = false
	state.add_item("life_bloom", 2)
	ui.selected_item_id = "life_bloom"
	ui._on_inventory_action_pressed()
	_check(player.second_breath_active and state.inventory.get("life_bloom", 0) == 1, "Life Bloom activation did not cost exactly one item")
	ui.selected_item_id = "life_bloom"
	ui._update_item_details()
	_check(ui.item_action_button.disabled, "Active Second Breath allows another activation")
	ui._on_inventory_action_pressed()
	_check(state.inventory.get("life_bloom", 0) == 1, "Repeated activation consumed another bloom")
	# Real fatal damage triggers Second Breath once, then the next fatal hit kills.
	player.is_invulnerable = false
	player.take_damage(99)
	_check(not player.is_dead and player.current_health == 1 and not player.second_breath_active, "Second Breath did not protect one lethal hit")
	player.is_invulnerable = false
	player.take_damage(99)
	_check(player.is_dead, "Death fixture failed")
	for item_id in ["healing_herb", "life_bloom"]:
		ui.selected_item_id = item_id
		ui._update_item_details()
		_check(ui.item_action_button.disabled, item_id + ": dead-player action enabled")
		_check(ui.item_drop_button.disabled, item_id + ": dead-player drop enabled")
		ui._on_inventory_action_pressed()
		_check(state.inventory.get(item_id, 0) == 1, item_id + ": stale click consumed item after death")
		ui.selected_item_id = item_id
		ui._on_inventory_drop_pressed()
		_check(state.inventory.get(item_id, 0) == 1, item_id + ": stale click dropped item after death")
	_check(player.current_health == 0 and not player.second_breath_active, "Consumable revived a dead player")
	paused = false
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("INVENTORY CONSUMABLES TEST PASSED: health cap, ownership, one-time Second Breath and dead-player action/drop guards")
		quit(0)
	else:
		print("INVENTORY CONSUMABLES TEST FAILED: ", failures.size())
		quit(1)
