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
	state.save_path = "res://_tmp_zone_upgrade_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player = game.get_node("Player")
	var sentry = game.get_node("VerticalChamber/UpperShaftSentry")
	var crawler = game.get_node("VerticalChamber/ShaftCrawler")
	var wisp = game.get_node("VerticalChamber/UpperShaftWisp")
	state.set_current_room("echo_gallery")
	await process_frame
	var shade = game.get_node("EchoGallery/NearShade")
	state.set_current_room("echo_nest")
	await process_frame
	var brood = game.get_node("EchoNest/BroodlingOne")
	_check(sentry.zone_tier == 0 and sentry.spread_rays.is_empty(), "Base sentry started upgraded")
	_check(shade.zone_tier == 0 and brood.zone_tier == 0, "Base Echo enemies started upgraded")
	state.set_zone_tier("sunken_shaft", 1)
	_check(sentry.zone_tier == 1 and sentry.spread_rays.size() == 2, "Sentry did not gain warning rays immediately")
	_check(sentry.max_health == 4 and crawler.max_health == 5 and wisp.max_health == 4, "Shaft health did not update immediately")
	_check(crawler.charge_speed == 275.0 and wisp.dive_speed == 270.0, "Shaft attack patterns did not upgrade")
	var projectile_count: int = get_nodes_in_group("enemy_projectile").size()
	sentry._fire()
	_check(get_nodes_in_group("enemy_projectile").size() >= projectile_count + 3, "Upgraded sentry spread attack missing")
	state.set_zone_tier("echo_grotto", 1)
	_check(shade.zone_tier == 1 and shade.max_health == 5, "Echo Shade did not upgrade immediately")
	_check(brood.zone_tier == 1 and brood.max_health == 4 and brood.leap_force == -350.0, "Broodling vertical leap did not upgrade")
	shade._start_dash(100.0)
	_check(shade.echo_followup_ready, "Echo Shade follow-up dash missing")
	shade._start_dash(100.0, true)
	_check(not shade.echo_followup_ready, "Echo Shade follow-up could loop forever")
	for room_id in ["echo_grotto", "echo_gallery", "echo_archive", "echo_tide_well", "echo_nest", "echo_sanctum"]:
		state.set_current_room(room_id)
	var ui = game.get_node("UI")
	ui._open_world_map(false)
	_check("6/11 PLAYABLE ROOMS" in ui.map_route_label.text, "World map did not record the six visited Echo rooms")
	_check(ui.get_node("WorldMapPanel/RouteScroll").get_global_rect().intersection(ui.map_travel_button.get_global_rect()).get_area() <= 0.0, "Route summary viewport overlaps travel button")
	ui._close_world_map()
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "upgrade_test", "Upgrade Test", "echo_sanctum"), "Upgrade progress save failed")
	state.discovered_rooms.clear()
	_check(state.load_game(), "Upgrade progress load failed")
	_check(state.discovered_rooms.size() >= 7 and bool(state.discovered_rooms.get("echo_sanctum", false)), "Discovered rooms did not survive save/load")
	state.delete_save()
	for projectile in get_nodes_in_group("enemy_projectile"):
		projectile.queue_free()
	await process_frame
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("ZONE UPGRADE TEST PASSED")
		quit(0)
	else:
		print("ZONE UPGRADE TEST FAILED: ", failures)
		quit(1)
