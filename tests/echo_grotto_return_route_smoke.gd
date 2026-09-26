extends "res://tests/echo_followup_live_pilot.gd"

var returning := false


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_echo_grotto_return_route_save.json"
	await _run_crossing()


func _after_echo_completed(game: Node) -> Node:
	var state := root.get_node("GameState")
	# Explicit post-clear tier fixture, not a claim that the Matriarch was
	# defeated in this test. The preceding real first-clear progress is saved.
	state.set_zone_tier("echo_grotto", 1)
	game = await _snapshot_reload(game, "echo_grotto", "EchoGrotto")
	_check(state.get_zone_tier("echo_grotto") == 1, "Awakened tier did not survive reload")
	returning = true
	_prepare_stage(game, "EchoGrotto")
	# One explicit entrance placement for the saved return expedition.
	player.global_position = room.get_node("GrottoEntry").global_position
	player.velocity = Vector2.ZERO
	for frame in range(12):
		await physics_frame
	_check(await _echo_route(), "Awakened Grotto connected return failed")
	_check_stage("ECHO GROTTO RETURN")
	if not failures.is_empty():
		return game
	game = await _snapshot_reload(game, "echo_grotto", "EchoGrotto")
	var fields := _route_geometry().get_node("FieldDiscoveries")
	_check(fields.completed and fields.get_node("ReturnEncounter").completed and fields.get_node("ReturnEncounter").spawned_enemies.is_empty(), "Saved return encounter respawned/reset")
	_refuse_duplicate(fields.get_node("ReturnReward"))
	_refuse_duplicate(_route_geometry().get_node("RouteDiscoveryCache"))
	await _explicit_exit(_echo_exit(), "echo_gallery")
	if failures.is_empty():
		print("ECHO GROTTO RETURN TEST PASSED: saved tier fixture, nine connected galleries, live guardians, finite supplies, persistent one-time rewards")
	return game


func _echo_tier_objective(tier: int) -> bool:
	if not returning or tier != 6:
		return true
	var route := _route_geometry()
	var shelf: StaticBody2D = route.get_node("Tier06SideAlcove")
	if not await _echo_approach(tier, shelf.position.x) or not await _connected_step(shelf, "Echo/return-trial"):
		return false
	var fields := route.get_node("FieldDiscoveries")
	var trial := fields.get_node("ReturnEncounter")
	for attempt in range(8):
		if trial.completed:
			break
		if not await _walk_on_floor(shelf.global_position.x + (100 if attempt % 2 == 0 else -100), "Hollow/side-destination-clear"):
			return false
		for frame in range(45):
			_supplies()
			await physics_frame
	_check(trial.triggered and trial.completed and trial.remaining_foes.is_empty(), "Return guardians were not defeated by live combat")
	if not trial.completed or not await _record(fields.get_node("ReturnReward")):
		return false
	_check(fields.get_node("ReturnReward").opened, "Return cache remained locked")
	var chamber: Rect2 = route._chamber_rect(tier)
	return await _connected_step(_floor_at(route, chamber.end.y, shelf.position.x), "Echo/return-trial-descent")
