extends "res://tests/echo_grotto_live_pilot.gd"

# Shared follow-up setup. Shop purchases are an explicit remote preparation
# fixture, not a claimed journey to a merchant. All gold/build/HP are carried.
var stage_carried := 0
var stage_hp := 0
var stage_started := 0


func _prepare_stage(game: Node, room_name: String) -> void:
	var state := root.get_node("GameState")
	room = game.get_node(room_name)
	ui = game.get_node("UI")
	stage_carried = int(state.inventory.get("healing_herb", 0))
	stage_hp = player.current_health
	var gold: int = state.gold
	_check(gold >= 54, "Follow-up supplies exceed earned gold")
	ui._open_shop(game.get_node("WayfarerMerchant"))
	for purchase in range(3):
		ui.selected_shop_item_id = "healing_herb"
		ui._on_shop_buy_pressed()
	ui._close_shop()
	_check(state.gold == gold - 54 and int(state.inventory.get("healing_herb", 0)) == stage_carried + 3, "Follow-up purchases were not paid")
	_check(player.current_health == stage_hp and player.max_health == 5 and not player.double_jump_unlocked and not player.dash_unlocked, "Follow-up preparation changed HP/movement")
	defeats = 0
	herbs_used = 0
	herbs_found = 0
	cache_herbs = 0
	purchased_herb_allowance = 3
	legs = 0
	excursions = 0
	health_trace.clear()
	if not state.item_acquired.is_connected(_track_supplies):
		state.item_acquired.connect(_track_supplies)
	if not node_added.is_connected(_watch_foe):
		node_added.connect(_watch_foe)
	for foe in get_nodes_in_group("enemy"):
		_watch_foe(foe)
	if not player.health_changed.is_connected(_trace_health):
		player.health_changed.connect(_trace_health)
	stage_started = Engine.get_physics_frames()
	player.set_physics_process(true)


func _check_stage(label: String, expected_branches: int = 4) -> void:
	var state := root.get_node("GameState")
	_check(not player.is_dead and player.max_health == 5 and player.current_health > 0, label + " ordinary-health survival failed")
	_check(legs == 8 and excursions == expected_branches and defeats >= 15, label + " physical coverage incomplete")
	_check(herbs_used <= 3 + cache_herbs and int(state.inventory.get("healing_herb", 0)) == stage_carried + 3 + herbs_found - herbs_used, label + " finite supply ledger mismatch")
	print(label, " LIVE: ", defeats, " foes; entry ", stage_hp, "/5, end ", player.current_health, "/5; ", herbs_used, " herbs of 3 purchased + ", cache_herbs, " guaranteed; ", legs, " links / ", excursions, " branches; ", (Engine.get_physics_frames() - stage_started) / 60.0, " physics seconds")
	_release()
	player.set_physics_process(false)


func _snapshot_reload(game: Node, room_id: String, room_name: String) -> Node:
	var state := root.get_node("GameState")
	var hp: int = player.current_health
	var gold: int = state.gold
	var points: int = player.skill_points
	var inventory: Dictionary = state.inventory.duplicate(true)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "", "Echo follow-up snapshot", room_id), "Follow-up save failed")
	if state.item_acquired.is_connected(_track_supplies):
		state.item_acquired.disconnect(_track_supplies)
	if node_added.is_connected(_watch_foe):
		node_added.disconnect(_watch_foe)
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Follow-up load failed")
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	ui = game.get_node("UI")
	room = game.get_node(room_name)
	_check(state.current_room_id == room_id and player.current_health == hp and player.max_health == 5, "Follow-up saved location/health changed")
	_check(player.skill_points == points and player.sword_mastery_unlocked and player.sword_reach_unlocked, "Follow-up saved build changed")
	_check(state.gold == gold and state.inventory.size() == inventory.size(), "Follow-up saved rewards changed")
	for item_id in inventory:
		_check(float(state.inventory.get(item_id, -1)) == float(inventory[item_id]), "Follow-up saved quantity changed: " + str(item_id))
	return game


func _explicit_exit(door: Area2D, target_room: String) -> void:
	await _interact(door)
	for frame in range(180):
		await physics_frame
		if not root.get_node("RoomTransition").is_transitioning:
			break
	_check(root.get_node("GameState").current_room_id == target_room, "Follow-up explicit exit target mismatch")


func _refuse_duplicate(cache: Area2D) -> void:
	var state := root.get_node("GameState")
	var gold: int = state.gold
	var inventory: Dictionary = state.inventory.duplicate(true)
	_check(cache.opened and not cache.open(player), "Saved reward could be duplicated")
	_check(state.gold == gold and state.inventory == inventory, "Duplicate refusal changed rewards")
