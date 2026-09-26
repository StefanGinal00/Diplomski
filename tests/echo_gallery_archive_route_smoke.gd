extends "res://tests/echo_followup_live_pilot.gd"

var echo_stage := ""
var archive_backtrack := false


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_echo_gallery_archive_route_save.json"
	await _run_crossing()


func _echo_exit() -> Area2D:
	if echo_stage == "gallery":
		return room.get_node("ArchiveDoor")
	if echo_stage == "archive":
		return room.get_node("ShortcutDoor")
	return super._echo_exit()


func _after_echo_completed(game: Node) -> Node:
	var state := root.get_node("GameState")
	# Grotto -> Gallery is a real door crossing, with no relocation fixture.
	await _explicit_exit(room.get_node("GalleryDoor"), "echo_gallery")
	echo_stage = "gallery"
	_prepare_stage(game, "EchoGallery")
	_check(not _echo_exit()._requirements_met(), "Gallery gate opened without prism")
	var ok := await _gallery_entry()
	if ok:
		ok = await _echo_route()
	_check(ok and state.has_item("gallery_prism"), "Gallery physical prism/route failed")
	_check(_route_geometry().get_node("FieldDiscoveries").completed and _route_geometry().get_node("RouteDiscoveryCache").opened, "Gallery witness offering incomplete")
	_check_stage("ECHO GALLERY")
	if not failures.is_empty():
		return game
	game = await _snapshot_reload(game, "echo_gallery", "EchoGallery")
	_check(state.has_item("gallery_prism") and _route_geometry().get_node("FieldDiscoveries").completed, "Saved Gallery prism/witnesses reset")
	_refuse_duplicate(_route_geometry().get_node("RouteDiscoveryCache"))
	# First-time Archive approach intentionally leads to Resonant Depths.
	# This test verifies that policy, but does not claim to traverse Depths.
	await _explicit_exit(_echo_exit(), "echo_depths")
	if not failures.is_empty():
		return game
	state.set_current_room("echo_archive")
	await process_frame
	echo_stage = "archive"
	_prepare_stage(game, "PrismArchive")
	# Explicit Archive entrance fixture; keep the genuinely earned inventory,
	# health, build and currency from Gallery. No injected quest flags/items.
	player.global_position = room.get_node("ArchiveEntry").global_position
	player.velocity = Vector2.ZERO
	for frame in range(12):
		await physics_frame
	_check(not _echo_exit()._requirements_met(), "Archive shortcut opened before mirrors")
	ok = await _archive_entry()
	if ok:
		ok = await _echo_route()
	_check(ok and state.has_item("memory_sigil_echo") and room.solved, "Archive connected mirrors/route failed")
	_check(archive_backtrack and _route_geometry().get_node("FieldDiscoveries").completed and _route_geometry().get_node("RouteDiscoveryCache").opened, "Archive ordered records/offering incomplete")
	_check_stage("PRISM ARCHIVE", 5)
	if not failures.is_empty():
		return game
	game = await _snapshot_reload(game, "echo_archive", "PrismArchive")
	_check(room.solved and state.has_item("memory_sigil_echo") and _route_geometry().get_node("FieldDiscoveries").completed, "Saved Archive puzzle/records reset")
	_refuse_duplicate(_route_geometry().get_node("RouteDiscoveryCache"))
	await _explicit_exit(_echo_exit(), "echo_grotto")
	if failures.is_empty():
		print("ECHO GALLERY ARCHIVE ROUTE TEST PASSED: earned build, connected room traversals, prism, mirrors, ordered backtracking, real exits and exact saved rewards; Depths traversal excluded")
	return game


func _gallery_entry() -> bool:
	if not await _walk_on_floor(room.get_node("FirstStep").global_position.x, "Echo/gallery-entry"):
		return false
	for named in ["FirstStep", "MiddleStep", "UpperStep", "PrismLedge"]:
		if not await _connected_step(room.get_node(named), "Echo/prism-climb"):
			return false
	if not await _walk_on_floor(room.get_node("PrismLedge").global_position.x, "Echo/prism-pickup"):
		return false
	for frame in range(12):
		await physics_frame
	_check(root.get_node("GameState").has_item("gallery_prism"), "Actual overlap did not collect prism")
	if not await _connected_step(room.get_node("Floor"), "Echo/gallery-descent"):
		return false
	return await _walk_on_floor(_route_geometry().get_node("Chamber00Floor0").global_position.x, "Echo/enter-extension")


func _archive_entry() -> bool:
	if not await _walk_on_floor(room.get_node("RootMirror").global_position.x, "Echo/root-mirror"):
		return false
	await _interact(room.get_node("RootMirror"))
	for named in ["FirstStep", "SecondStep", "ThirdStep"]:
		if not await _connected_step(room.get_node(named), "Echo/star-mirror-climb"):
			return false
	if not await _walk_on_floor(room.get_node("StarMirror").global_position.x, "Echo/star-mirror"):
		return false
	await _interact(room.get_node("StarMirror"))
	if not await _connected_step(room.get_node("Floor"), "Echo/archive-descent"):
		return false
	if not await _walk_on_floor(room.get_node("EchoMirror").global_position.x, "Echo/echo-mirror"):
		return false
	await _interact(room.get_node("EchoMirror"))
	_check(room.solved, "Physical mirror sequence failed")
	return await _walk_on_floor(_route_geometry().get_node("Chamber00Floor0").global_position.x, "Echo/enter-extension")


func _visit_echo_post(post: Area2D, tier: int) -> bool:
	if echo_stage == "archive" and tier == 1 and not archive_backtrack:
		return true # Read clue; Zenith must be recorded before Dawn.
	if echo_stage != "archive":
		return await super._visit_echo_post(post, tier)
	# A patrolling shade can arrive below the balcony AFTER its first lane
	# clearance. Follow the listening post's live threat hint, descend, fight
	# that guard and climb back; never waive its interruption requirement.
	for attempt in range(3):
		if not await _record(post):
			return false
		for frame in range(100):
			_supplies()
			await physics_frame
		if post.attuned:
			return true
		if not post._has_threat():
			break
		var threat: Node2D = post._nearest_threat()
		var target_x: float = _route_geometry().to_local(threat.global_position).x
		if not await _connected_step(_echo_floor(tier, target_x), "Echo/listening-guard-descent"):
			return false
		if not await _echo_approach(tier, target_x):
			return false
		for named in ["BranchStep1", "BranchStep2", "HiddenShelfA", "HiddenShelfB"]:
			if not await _connected_step(_route_geometry().get_node("Tier%02d%s" % [tier, named]), "Echo/listening-return"):
				return false
	_check(false, "Archive listening failed after three physical attempts: " + str(post.name))
	return false


func _echo_branch(tier: int) -> bool:
	if not await super._echo_branch(tier):
		return false
	if echo_stage == "archive" and tier == 3 and not archive_backtrack:
		archive_backtrack = true
		# Walk both links backwards, revisit Dawn, then rejoin the same forward
		# route. No teleports, flags, direct callbacks or disabled actors.
		if not await _echo_link(3, 2) or not await _echo_link(2, 1):
			return false
		if not await _echo_branch(1):
			return false
		if not await _echo_link(1, 2) or not await _echo_link(2, 3):
			return false
	return true
