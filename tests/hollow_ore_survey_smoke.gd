extends "res://tests/shaft_hollow_smoke.gd"

# Save/reward integration. Initial placements are teleported here; continuous
# physical access is covered separately by hollow_full_navigation_smoke.gd.
const SURVEY_PATH := "ShaftHollow/ExpandedRoute/AuthoredDescent/ExplorationSites/OreSurvey"


func _world() -> Node:
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	return game


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hollow_ore_survey_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	_check(not game.has_node(SURVEY_PATH), "Survey populated before entering Hollow")
	state.set_current_room("shaft_hollow")
	await process_frame
	var room := game.get_node("ShaftHollow")
	_freeze_room(room)
	var survey := game.get_node(SURVEY_PATH)
	var reward := survey.get_node("SurveyReward")
	for index in range(3):
		var sample := survey.get_node("Sample%d" % index)
		var query := PhysicsRayQueryParameters2D.create(sample.global_position, sample.global_position + Vector2(0, 80), 1)
		var hit: Dictionary = sample.get_world_2d().direct_space_state.intersect_ray(query)
		_check(not hit.is_empty() and hit.collider is StaticBody2D, "Ore sample has no actual supporting floor")
		for label_name in ["StatusLabel", "InteractionPrompt"]:
			var label: Label = sample.get_node(label_name)
			var longest: String = sample.active_label if label_name == "StatusLabel" else sample.inactive_prompt
			_check(label.get_theme_font("font").get_string_size(longest, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x, "Survey marker text exceeds its bounds")
	_check(not survey.board.get_global_rect().intersects(reward.prompt.get_global_rect()), "Survey board overlaps the reward prompt")
	_check(survey.recorded_count() == 0 and not reward.open(player), "Survey reward opened without samples")
	_check(survey.get_guide_line().contains("upper ore alcove") and survey.get_guide_line().contains("lowest seep gallery"), "Survey guide does not explain the route")
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	survey.get_node("Sample0")._unhandled_input(event)
	_check(survey.recorded_count() == 0, "Sample recorded without physical proximity")
	player.is_dead = true
	_check(not survey.get_node("Sample0").activate(player), "Dead player recorded a sample")
	player.is_dead = false
	# Any order is legal; one or two records are not enough for the reserve.
	await _record_at(survey.get_node("Sample2"), player)
	_check(survey.recorded_count() == 1 and not reward.open(player), "One sample unlocked supplies")
	_check(not survey.get_guide_line().contains("lowest seep gallery"), "Recorded location remains on the missing-samples list")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "ore_survey_test", "Survey Test", "shaft_hollow"), "Partial survey snapshot failed")
	await _record_at(survey.get_node("Sample0"), player)
	_check(survey.recorded_count() == 2 and not reward.open(player), "Two samples unlocked supplies")
	await _record_at(survey.get_node("Sample1"), player)
	_check(survey.recorded_count() == 3 and game.get_node("UI").notification_label.text.contains("3/3"), "Survey completion feedback missing")
	_check(not room.get_node("Relay").is_active and not room.get_node("CrossingDoor")._requirements_met(), "Optional survey bypassed the relay")
	var gold_before: int = state.gold
	var herbs_before: int = state.inventory.get("healing_herb", 0)
	var iron_before: int = state.inventory.get("iron_fragment", 0)
	await _record_at(reward, player)
	_check(reward.opened and not reward.open(player), "Survey reward was not one-time")
	_check(state.gold == gold_before + 18 and state.inventory.get("healing_herb", 0) == herbs_before + 1 and state.inventory.get("iron_fragment", 0) == iron_before + 1, "Survey supplies payout is wrong")
	_check(survey.board.text.contains("CLAIMED") and survey.get_guide_line().contains("supplies are yours"), "Collected reward still advertised")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial survey save could not load")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	_freeze_room(game.get_node("ShaftHollow"))
	survey = game.get_node(SURVEY_PATH)
	reward = survey.get_node("SurveyReward")
	_check(survey.recorded_count() == 1 and survey.get_node("Sample2").is_active and not survey.get_node("Sample0").is_active and not reward.opened, "Unsaved records/reward survived rollback")
	await _record_at(survey.get_node("Sample1"), player)
	await _record_at(survey.get_node("Sample0"), player)
	await _record_at(reward, player)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "ore_survey_test", "Survey Test", "shaft_hollow"), "Completed survey snapshot failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed survey save could not load")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	survey = game.get_node(SURVEY_PATH)
	state.set_zone_tier("sunken_shaft", 1)
	_check(survey.recorded_count() == 3 and survey.get_node("SurveyReward").opened and not survey.get_node("SurveyReward").open(player), "Awakening reset/farmed the first-clear survey reward")
	_check(not game.get_node("ShaftHollow/ExpandedRoute/AuthoredDescent/ExplorationSites/AwakenedTrial").completed, "Survey bypassed the separate return trial")
	state.set_current_room("training_passage")
	state.set_current_room("shaft_hollow")
	await process_frame
	_check(game.get_node(SURVEY_PATH) == survey, "Re-entry duplicated the survey")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("HOLLOW ORE SURVEY TEST PASSED: physical interactions, arbitrary order, finite supplies, independent gates, partial/completed save and awakened return")
		quit(0)
	else:
		print("HOLLOW ORE SURVEY TEST FAILED: ", failures.size())
		quit(1)


func _record_at(object: Area2D, player: Player) -> void:
	player.global_position = object.global_position
	player.velocity = Vector2.ZERO
	for frame in range(3):
		await physics_frame
	_check(object.get_overlapping_bodies().has(player), str(object.name) + ": physical interaction setup failed")
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	object._unhandled_input(event)


func _freeze_room(room: Node) -> void:
	for actor in room.find_children("*", "CollisionObject2D", true, false):
		actor.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	room.process_mode = Node.PROCESS_MODE_DISABLED
