extends Node2D

# Optional room-specific objectives. Flags use the existing lamp snapshot;
# none replace the original core puzzles or block the main traversal route.
const VALVE := preload("res://SluiceValve.tscn")
const POST := preload("res://EchoListeningPost.gd")
const ENCOUNTER := preload("res://LocalizedEncounter.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const BROOD := preload("res://EchoBroodling.tscn")
const SHADE := preload("res://EchoShade.tscn")
const WISP := preload("res://ShaftWisp.tscn")
const PROFILES := {
	"tide": ["THE QUIET WELL", "CALM BOTH CURRENT BANKS", "THE RETURNING TIDE", [WISP, WISP]],
	"nest": ["THE OUTER NURSERIES", "CLEAR BOTH SIDE NURSERIES", "THE LAST HATCH", [BROOD, BROOD]],
	"causeway": ["THE STEADY CROSSING", "RESTORE BOTH BRIDGE ANCHORS", "FRACTURED SENTINELS", [SHADE, WISP]],
	"vault": ["THE DRY RESERVE", "DRAIN BOTH CHANNELS + OPEN BOTH VAULT SEALS", "THE RESERVOIR WATCH", [SHADE, BROOD]],
	"depths": ["THE LOST EXPEDITION", "RECORD BOTH DISTANT SIGNALS", "THE EXPEDITION'S ECHO", [SHADE, SHADE]],
}

var route: Node2D
var route_id := ""
var state: Node
var requirements := PackedStringArray()
var controls: Array[Area2D] = []
var signs: Array[Label] = []
var completed := false


func _ready() -> void:
	state = get_node("/root/GameState")
	for index in range(2):
		requirements.append("echo_%s_field_station_%d" % [route_id, index])
	if route_id == "vault":
		requirements.append_array(PackedStringArray(["echo_vault_upper", "echo_vault_far"]))
	for index in range(2):
		var point := _station_point(index)
		match route_id:
			"nest":
				_encounter("Nursery%d" % index, point + Vector2(0, 34), requirements[index], [BROOD, BROOD], 0, "OUTER NURSERY %d" % (index + 1))
			"depths":
				var post := VALVE.instantiate() as Area2D
				post.set_script(POST)
				post.name = "Signal%d" % index
				post.position = point
				post.set("station_index", index)
				post.set("station_title", "WESTERN SIGNAL" if index == 0 else "EASTERN SIGNAL")
				post.set("room_id", "echo_depths")
				post.set("threat_root", route)
				post.connect("heard", _on_signal)
				add_child(post)
				controls.append(post)
			_:
				var names: Array = {"tide": ["LOWER FLOW REGULATOR", "UPPER FLOW REGULATOR"], "causeway": ["WEST BRIDGE ANCHOR", "EAST BRIDGE ANCHOR"], "vault": ["INTAKE DRAIN", "OUTLET DRAIN"]}[route_id]
				var valve := VALVE.instantiate() as Area2D
				valve.name = "Control%d" % index
				valve.position = point
				valve.set("shortcut_id", requirements[index])
				valve.set("inactive_label", names[index])
				valve.set("inactive_prompt", "[E] " + ("STABILIZE BRIDGES" if route_id == "causeway" else "CALM THE CURRENT"))
				valve.set("active_label", String(names[index]) + " - READY")
				valve.set("active_prompt", "BRIDGES STABLE" if route_id == "causeway" else "CURRENT CALMED")
				add_child(valve)
				controls.append(valve)
		_sign(point + Vector2(-220, -235))
	# A clue at the entry makes the distant branches discoverable.
	var entry_point := _depth_floor(0, false) if route_id == "depths" else (route.get_node("Tier00SideAlcove") as Node2D).position + Vector2(0, -34)
	_sign(entry_point + Vector2(-220, -180))
	var return_point := _depth_floor(1, true) + Vector2(0, 34) if route_id == "depths" else (route.get_node("Tier06SideAlcove") as Node2D).position
	var trial := _encounter("ReturnEncounter", return_point, "echo_%s_field_return_complete" % route_id, PROFILES[route_id][3], 1, PROFILES[route_id][2])
	trial.set("required_event_ids", PackedStringArray([completion_id()]))
	trial.call("_refresh_status")
	var reward := CACHE.instantiate() as Area2D
	reward.name = "ReturnReward"
	reward.position = return_point + Vector2(145, -34)
	if route_id == "depths":
		reward.position = _depth_floor(1, true, 145)
	reward.set("cache_id", "echo_%s_field_return_reserve" % route_id)
	reward.set("cache_name", String(PROFILES[route_id][2]).capitalize() + " Reserve")
	reward.set("gold_reward", 20)
	reward.set("reward_item_id", "ether_dust")
	reward.set("required_event_ids", PackedStringArray(["echo_%s_field_return_complete" % route_id]))
	add_child(reward)
	state.shortcut_changed.connect(_on_event)
	_refresh()


func completion_id() -> String:
	return "echo_%s_field_complete" % route_id


func _station_point(index: int) -> Vector2:
	if route_id == "depths":
		return _depth_floor(0 if index == 0 else 2, true)
	var tier := (3 if index == 0 else 9) if route_id == "tide" else (1 if index == 0 else 5)
	return (route.get_node("Tier%02dHiddenShelfA" % tier) as Node2D).position + Vector2(0, -34)


func _depth_floor(index: int, branch: bool, x_offset: float = 0.0) -> Vector2:
	var bounds: Rect2 = route.call("_branch_rect" if branch else "_main_rect", index)
	var prefix := ("BranchRoom" if branch else "MainRoom") + str(index) + "Floor"
	var best := Vector2.INF
	var distance := INF
	var desired_x := bounds.get_center().x + x_offset
	for child in route.get_children():
		if not child is StaticBody2D or not String(child.name).begins_with(prefix):
			continue
		var collision := child.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D or collision.shape.size.x < 240:
			continue
		var half: float = collision.shape.size.x * 0.5
		var x := clampf(desired_x, child.position.x - half + 120, child.position.x + half - 120)
		if absf(x - desired_x) < distance:
			distance = absf(x - desired_x)
			best = Vector2(x, child.position.y - 34)
	assert(best.is_finite(), "Missing Echo Depths objective floor: " + prefix)
	return best


func _encounter(node_name: String, point: Vector2, event_id: String, foes: Array, tier: int, title: String) -> Area2D:
	var trial := ENCOUNTER.instantiate() as Area2D
	trial.name = node_name
	trial.position = point
	trial.set("zone_id", "echo_grotto")
	trial.set("encounter_id", event_id + "_encounter")
	trial.set("completion_event_id", event_id)
	trial.set("minimum_zone_tier", tier)
	trial.set("encounter_title", title)
	trial.set("locked_hint", "COMPLETE THIS ROOM'S FIELD TASK FIRST")
	trial.set("dormant_hint", "DORMANT - RETURN AFTER THE MATRIARCH")
	for index in range(foes.size()):
		trial.get("enemy_scenes").append(foes[index])
		trial.get("spawn_offsets").append(Vector2(-85 + index * 165, -92 if foes[index] == WISP else -32))
	add_child(trial)
	return trial


func _sign(point: Vector2) -> void:
	var sign := Label.new()
	sign.position = point
	sign.size = Vector2(440, 95)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign.add_theme_font_size_override("font_size", 11)
	add_child(sign)
	signs.append(sign)


func _on_signal(index: int) -> void:
	if index >= 0 and index < 2:
		state.unlock_shortcut(requirements[index])


func _on_event(event_id: String) -> void:
	if requirements.has(event_id) or event_id == "echo_%s_field_return_complete" % route_id:
		_refresh()


func _refresh() -> void:
	var count := 0
	for id in requirements:
		count += int(bool(state.unlocked_shortcuts.get(id, false)))
	completed = count == requirements.size()
	if completed:
		state.unlock_shortcut(completion_id())
	for index in range(2):
		var active := bool(state.unlocked_shortcuts.get(requirements[index], false))
		match route_id:
			"tide":
				for offset in range(2):
					var current := route.get_node("RisingCurrent%02d" % (index * 2 + offset))
					current.call("set_calmed", active)
					(route.get_node("CurrentMarker%02d" % (index * 2 + offset)) as Label).text = "CURRENT CALMED" if active else "RISING CURRENT"
			"causeway":
				for offset in range(2):
					route.get_node("TraversalPhaseBridge%02d" % (index * 2 + offset)).call("set_stabilized", active)
			"vault":
				route.get_node("UndertowCurrent%02d" % index).call("set_calmed", active)
			"depths":
				controls[index].call("set_attuned", active)
	var detail := "%s\nPROGRESS %d/%d" % [PROFILES[route_id][1], count, requirements.size()]
	if completed:
		detail = "DISCOVERY CACHE UNSEALED\nRETURN AFTER THE MATRIARCH FOR A SEPARATE TRIAL"
	if bool(state.unlocked_shortcuts.get("echo_%s_field_return_complete" % route_id, false)):
		detail = "DISCOVERY RECORDED\nRETURN TRIAL CLEARED"
	for sign in signs:
		var route_clue := "EXPLORE THE SIDE CHAMBERS; CACHE: FINAL HIDDEN SHELF"
		if route_id == "depths":
			route_clue = "SIGNALS: WEST + EAST BRANCHES; CACHE: DEEPEST BRANCH"
		elif route_id == "tide":
			route_clue = "SIDE CHAMBERS; CACHE: HIGH BRANCH BY PEARL MARKS"
		sign.text = String(PROFILES[route_id][0]) + "\n" + detail + "\n" + route_clue
