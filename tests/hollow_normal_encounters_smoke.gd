extends "res://tests/shaft_mixed_combat_smoke.gd"

# Ordinary-health local fights, not a whole-room combat run. Each encounter
# starts fresh at its existing arena with 5 HP, starter sword and no supplies.
func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hollow_normal_encounters_save.json"
	health_budget = 5
	combat_warmup_frames = 0
	node_added.connect(_on_test_node_added)
	for tier in [0, 1]:
		state.start_new_game("normal")
		state.set_zone_tier("sunken_shaft", tier)
		await _battle("ShaftHollow", tier)
	state.start_new_game("normal")
	state.set_zone_tier("sunken_shaft", 1)
	await _battle("ShaftHollow", 1, true)
	state.delete_save()
	if failures.is_empty():
		print("HOLLOW NORMAL ENCOUNTERS TEST PASSED: first/awakened niche and awakened return trial; each starts at 5 HP, starter sword, no healing")
		quit(0)
	else:
		print("HOLLOW NORMAL ENCOUNTERS TEST FAILED: ", failures.size())
		quit(1)


func _drive_attack(target: Node2D, floor_node: Node2D) -> void:
	super._drive_attack(target, floor_node)
	if target.get_script() == load("res://ShaftCrawler.gd") and target.state == target.State.WARNING and target.state_remaining < 0.2 and player.is_on_floor():
		player._try_jump()
