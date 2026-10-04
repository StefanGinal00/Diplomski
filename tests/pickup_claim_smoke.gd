extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_pickup_claim.json"
	state.start_new_game("normal")
	var game: Node = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Node = game.get_node("Player")
	for kind in ["GoldPickup", "ItemPickup", "XPOrb"]:
		var pickup: Node2D = load("res://%s.tscn" % kind).instantiate()
		pickup.position = Vector2(-9000, -9000)
		game.add_child(pickup)
		var before_gold: int = state.gold
		var before_item: int = state.inventory.get("healing_herb", 0)
		player.xp = 0
		# Rejected contacts must leave the pickup available for a living player.
		pickup.body_entered.emit(game)
		player.is_dead = true
		pickup.body_entered.emit(player)
		_check(not pickup.claimed and not pickup.is_queued_for_deletion(), kind + " consumed by dead/non-player body")
		_check(state.gold == before_gold and state.inventory.get("healing_herb", 0) == before_item and player.xp == 0, kind + " rewarded a dead player")
		player.is_dead = false
		var field: String = {"GoldPickup": "gold_value", "ItemPickup": "amount", "XPOrb": "xp_value"}[kind]
		pickup.set(field, 0)
		pickup.body_entered.emit(player)
		_check(not pickup.claimed and not pickup.is_queued_for_deletion(), kind + " latched on a rejected reward")
		pickup.set(field, 1)
		var callbacks := [0]
		var reward_signal: Signal
		var callback: Callable
		if kind == "GoldPickup":
			reward_signal = state.gold_changed
			callback = func(_amount: int):
				callbacks[0] += 1
				if callbacks[0] == 1: pickup.body_entered.emit(player)
		elif kind == "ItemPickup":
			reward_signal = state.item_acquired
			callback = func(_item: String, _amount: int):
				callbacks[0] += 1
				if callbacks[0] == 1: pickup.body_entered.emit(player)
		else:
			reward_signal = player.progression_changed
			callback = func(_xp: int, _required: int, _points: int):
				callbacks[0] += 1
				if callbacks[0] == 1: pickup.body_entered.emit(player)
		reward_signal.connect(callback)
		pickup.body_entered.emit(player)
		pickup.body_entered.emit(player) # Same frame, before queue_free is flushed.
		reward_signal.disconnect(callback)
		_check(callbacks[0] == 1 and pickup.claimed and pickup.is_queued_for_deletion(), kind + " rewarded more than once")
		_check(state.gold == before_gold + (1 if kind == "GoldPickup" else 0), kind + " changed gold incorrectly")
		_check(int(state.inventory.get("healing_herb", 0)) == before_item + (1 if kind == "ItemPickup" else 0), kind + " changed inventory incorrectly")
		_check(player.xp == (1 if kind == "XPOrb" else 0), kind + " changed XP incorrectly")
		if pickup.has_method("_enable_pickup"):
			pickup.monitoring = false
			pickup._enable_pickup()
			_check(not pickup.monitoring, kind + " late timer reenabled a claimed pickup")
		await process_frame
	# Already-owned unique objects cannot give a second copy on contact/reload.
	state.add_item("nest_crest")
	var unique: Node = load("res://ItemPickup.tscn").instantiate()
	unique.unique = true
	unique.item_id = "nest_crest"
	game.add_child(unique)
	unique._on_body_entered(player)
	_check(state.inventory.get("nest_crest", 0) == 1 and unique.is_queued_for_deletion(), "Owned unique item duplicated")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("PICKUP CLAIM TEST PASSED")
		quit(0)
	else:
		print("PICKUP CLAIM TEST FAILED: ", failures)
		quit(1)
