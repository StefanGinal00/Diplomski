extends Node2D

# Optional first-clear machinery objectives in two different room graphs.
# All persistent progress uses the existing lamp-snapshot event dictionary.
const VALVE := preload("res://SluiceValve.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const LIFT := preload("res://ShaftLift.tscn")
const HAZARD := preload("res://ShaftRouteHazard.tscn")
const RESIDENT := preload("res://TownResident.tscn")
const ENCOUNTER := preload("res://LocalizedEncounter.tscn")
const WISP := preload("res://ShaftWisp.tscn")
const CRAWLER := preload("res://ShaftCrawler.tscn")
const SENTRY := preload("res://ShaftSentry.tscn")

var expansion: Node2D
var profile := "hub"
var event_prefix: String
var repair_event: String
var control_events: PackedStringArray
var state: Node
var progress_sign: Label
var resident: Area2D


func _ready() -> void:
	event_prefix = "shaft_hoist_repair" if profile == "hub" else "shaft_drift_pumps"
	repair_event = event_prefix + "_complete"
	control_events = PackedStringArray([event_prefix + "_a", event_prefix + "_b"])
	state = get_node_or_null("/root/GameState")
	if profile == "hub":
		_build_hoist()
	else:
		_build_pumps()
	if state != null:
		state.shortcut_changed.connect(_on_progress_changed)
		state.zone_tier_changed.connect(_on_tier_changed)
	_sync_progress()


func _floor_point(prefix: String, desired_x: float) -> Vector2:
	# Use solid floor segments rather than rectangle centres: centres can be
	# open shaft mouths in these room graphs. Keep every interaction away from
	# the lip, including its lift arrival marker and a player's body width.
	var best := Vector2.INF
	var distance := INF
	for child in expansion.get_children():
		if not child is StaticBody2D or not String(child.name).begins_with(prefix + "Floor"):
			continue
		var collision := child.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var half: float = collision.shape.size.x * 0.5
		if half < 110.0:
			continue
		var x := clampf(desired_x, child.position.x - half + 90.0, child.position.x + half - 90.0)
		if absf(x - desired_x) < distance:
			distance = absf(x - desired_x)
			best = Vector2(x, child.position.y - 33.0)
	assert(best.is_finite(), "Missing safe machinery floor: " + prefix)
	return best


func _control(node_name: String, at: Vector2, index: int, label: String) -> void:
	var control := VALVE.instantiate() as Area2D
	control.name = node_name
	control.position = at
	control.set("shortcut_id", control_events[index])
	control.set("inactive_label", label)
	control.set("active_label", label + " - READY")
	control.set("inactive_prompt", "[E] RESTORE " + label)
	control.set("active_prompt", "MECHANISM RESTORED")
	add_child(control)


func _cache(node_name: String, at: Vector2, id: String, label: String, event_id: String, material: String) -> void:
	var cache := CACHE.instantiate() as Area2D
	cache.name = node_name
	cache.position = at
	cache.set("cache_id", id)
	cache.set("cache_name", label)
	cache.set("gold_reward", 20)
	cache.set("reward_item_id", material)
	cache.set("required_event_ids", PackedStringArray([event_id]))
	add_child(cache)


func _build_hoist() -> void:
	_control("CableWinch", _floor_point("SideRoom0", -3020), 0, "CABLE WINCH")
	_control("Counterweight", _floor_point("SideRoom1", -2990), 1, "COUNTERWEIGHT")
	_build_resident(_floor_point("MineRoom0", -330), "Ivo, Hoist Mechanic")
	var lower := _floor_point("MineRoom1", -1920)
	var upper := _floor_point("MineRoom3", -1800)
	for index in range(2):
		var marker := Marker2D.new()
		marker.name = "HoistArrival%d" % index
		marker.position = (lower if index == 0 else upper) + Vector2(-48, 0)
		marker.add_to_group("shaft_repaired_hoist_%d" % index)
		add_child(marker)
		var lift := LIFT.instantiate() as Area2D
		lift.name = "RepairedHoist%d" % index
		lift.position = lower if index == 0 else upper
		lift.set("shortcut_id", repair_event)
		lift.set("room_id", "sunken_shaft")
		lift.set("enemy_group", &"enemy")
		lift.set("target_marker_group", StringName("shaft_repaired_hoist_%d" % (1 - index)))
		lift.set("lift_label", "REPAIRED HOIST")
		lift.set("locked_prompt", "REPAIR WINCH + COUNTERWEIGHT")
		lift.set("locked_message", "Restore the cable winch and counterweight in the two western side caves.")
		add_child(lift)
	_cache("RepairReward", _floor_point("MineRoom3", -760), "shaft_hoist_service_reserve", "Hoist Service Reserve", repair_event, "iron_fragment")
	_build_return_trial(_floor_point("SideRoom2", -2860) + Vector2(0, 33), [WISP, SENTRY], "COUNTERWEIGHT ECHOES")


func _build_pumps() -> void:
	var first: Rect2 = expansion.call("_branch_rect", 0)
	var second: Rect2 = expansion.call("_branch_rect", 2)
	_control("IntakePump", _floor_point("BranchRoom0", first.position.x + 340), 0, "INTAKE PUMP")
	_control("CrownPump", _floor_point("BranchRoom2", second.end.x - 260), 1, "CROWN PUMP")
	_build_resident(_floor_point("MainRoom0", 600), "Tova, Pump Engineer")
	for index in range(2):
		var room_index := 1 if index == 0 else 5
		var bounds: Rect2 = expansion.call("_main_rect", room_index)
		var vent := HAZARD.instantiate() as Area2D
		vent.name = "PressureLeak%d" % index
		vent.position = _floor_point("MainRoom%d" % room_index, bounds.position.x + 430) + Vector2(0, -18)
		vent.scale.x = 0.5
		vent.set("hazard_kind", "pressure")
		vent.set("warning_duration", 1.4)
		vent.set("idle_duration", 2.7)
		vent.set("disabled_by_shortcut_id", control_events[index])
		vent.set("initial_offset", float(index) * 0.7)
		add_child(vent)
	_cache("RepairReward", _floor_point("BranchRoom2", second.end.x - 420), "shaft_drift_engineer_reserve", "Engineer Reserve", repair_event, "ether_dust")
	var last: Rect2 = expansion.call("_branch_rect", 3)
	_build_return_trial(_floor_point("BranchRoom3", last.position.x + 340) + Vector2(0, 33), [CRAWLER, WISP, CRAWLER], "THE RESTARTED ENGINE")


func _build_resident(at: Vector2, title: String) -> void:
	for index in range(2):
		var stop := Marker2D.new()
		stop.name = "MechanicStop%d" % index
		stop.position = at + Vector2(-35 + index * 70, 7)
		add_child(stop)
	resident = RESIDENT.instantiate() as Area2D
	resident.name = "Mechanic"
	resident.position = at + Vector2(0, 7)
	resident.set("resident_name", title)
	resident.set("route_marker_names", PackedStringArray(["MechanicStop0", "MechanicStop1"]))
	resident.set("coat_color", Color(0.24, 0.43, 0.43))
	add_child(resident)
	resident.get_node("NameLabel").position.x = -135
	resident.get_node("NameLabel").size.x = 270
	progress_sign = Label.new()
	progress_sign.name = "WorkOrder"
	progress_sign.position = at + Vector2(-200, -132)
	progress_sign.size = Vector2(400, 65)
	progress_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_sign.add_theme_font_size_override("font_size", 11)
	add_child(progress_sign)


func _build_return_trial(at: Vector2, foes: Array, title: String) -> void:
	var trial := ENCOUNTER.instantiate() as Area2D
	trial.name = "ReturnTrial"
	trial.position = at
	trial.set("encounter_id", event_prefix + "_trial")
	trial.set("completion_event_id", event_prefix + "_trial_complete")
	trial.set("minimum_zone_tier", 1)
	trial.set("required_event_ids", PackedStringArray([repair_event]))
	trial.set("encounter_title", title)
	for index in range(foes.size()):
		trial.get("enemy_scenes").append(foes[index])
		trial.get("spawn_offsets").append(Vector2(-90 + index * 100, -94 if foes[index] == WISP else -31))
	add_child(trial)
	_cache("ReturnReward", at + Vector2(-170, -36), event_prefix + "_return_reserve", "Awakened Service Reserve", event_prefix + "_trial_complete", "ether_dust")


func _on_progress_changed(event_id: String) -> void:
	if control_events.has(event_id) or event_id.begins_with(event_prefix):
		_sync_progress()


func _on_tier_changed(zone: String, _tier: int) -> void:
	if zone == "sunken_shaft":
		_sync_progress()


func _sync_progress() -> void:
	if state == null:
		return
	var count := 0
	for event_id in control_events:
		count += int(bool(state.unlocked_shortcuts.get(event_id, false)))
	if count == 2 and not bool(state.unlocked_shortcuts.get(repair_event, false)):
		state.unlock_shortcut(repair_event)
	if profile == "hub" and count == 2:
		expansion.get_node("BrokenHoistCable").default_color = Color(0.28, 0.88, 0.72, 0.85)
		expansion.get_node("HoistIdentity").text = "REPAIRED HOIST - TWO-WAY TRAVEL"
	var title := "RESTORE THE HOIST" if profile == "hub" else "RESTART THE DRIFTWORKS"
	progress_sign.text = "%s\nMECHANISMS %d/2\n%s" % [title, count, "SERVICE RESERVE UNSEALED" if count == 2 else "EXPLORE THE SIDE CHAMBERS"]
	var clue := "Restore the cable winch in the western cave above the Pump Hall, then the counterweight in the low western cave. The hoist will carry you between the Pump Hall and Upper Reservoir."
	if profile == "drift":
		clue = "The intake pump is in the western branch below the entrance. The crown pump is in the far eastern branch above the turbines. Each one quiets a pressure leak; restoring both unseals the engineer reserve beside the crown pump."
	var lines := PackedStringArray([clue, "The service reserve is a one-time reward. Save your repairs and supplies at a lamp."])
	if count == 2:
		lines[0] = "The hoist is running. Use either terminal to travel between the Pump Hall and Upper Reservoir." if profile == "hub" else "Both pressure leaks are quiet. The engineer reserve beside the crown pump is open."
	if profile == "drift":
		lines[0] = "Pumps restored %d/2. " % count + lines[0]
	if state.get_zone_tier("sunken_shaft") >= 1 and not bool(state.unlocked_shortcuts.get(event_prefix + "_trial_complete", false)):
		lines.append("After the repairs, investigate the high western side cave for an awakened encounter." if profile == "hub" else "After the repairs, return to the northwestern engine branch for an awakened encounter.")
	if bool(state.unlocked_shortcuts.get(event_prefix + "_trial_complete", false)):
		lines.append("The awakened guardians are gone. Their separate reserve is now yours.")
	resident.set("dialogue_lines", lines)
	resident.set("next_line_index", 0)
