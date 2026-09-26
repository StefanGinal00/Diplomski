extends Node2D

const VALVE := preload("res://SluiceValve.tscn")
const STATION := preload("res://AshSurveyStation.gd")
const ENCOUNTER := preload("res://LocalizedEncounter.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const SHADE := preload("res://EchoShade.tscn")
const SENTRY := preload("res://AshSentry.tscn")
const PREFIX := "starfall_ramparts"
const GUARD_EVENTS := {0: PREFIX + "_west_watch_cleared", 2: PREFIX + "_east_watch_cleared", 3: PREFIX + "_niche_cleared"}
var route: Node2D
var state: Node
var controls: Array[Area2D] = []
var signs: Array[Label] = []
var completed := false


func _ready() -> void:
	state = get_node("/root/GameState")
	for branch in range(4):
		var guard := route.get_node_or_null("BranchGuard%d" % branch) as Node2D
		if guard != null:
			# ExpeditionWing places guards before _ready initializes patrol origins.
			if GUARD_EVENTS.has(branch):
				guard.connect("defeated", Callable(state, "unlock_shortcut").bind(GUARD_EVENTS[branch]), CONNECT_ONE_SHOT)
	for index in range(2):
		_control("WEST WATCH PLATE" if index == 0 else "EAST WATCH PLATE", index * 2, PREFIX + "_plate_%d" % index, PackedStringArray([GUARD_EVENTS[index * 2]]), "[E] RECOVER SIGNAL PLATE", "PLATE RECOVERED", "DEFEAT THIS WATCH'S GUARD FIRST")
		var hazard := route.get_node("LowerHazard%d" % index) as Node2D
		hazard.position = floor_point(2 + index * 2, false) + Vector2(0, 16)
	_control("RAMPART SIGNAL DESK", 1, PREFIX + "_relay_restored", PackedStringArray([PREFIX + "_plate_0", PREFIX + "_plate_1"]), "[E] RESTORE SIGNAL NETWORK", "SIGNAL RESTORED - ROOT LANES QUIET", "RECOVER BOTH WATCH PLATES FIRST")
	# Original caches, doors and return lift keep their IDs and connections.
	route.get_node("MidCache").position = floor_point(1, true, -150)
	route.get_node("RimCache").position = floor_point(3, true, 150)
	_sign(floor_point(0, false) + Vector2(-230, -225))
	_sign(route.get_node("RimCache").position + Vector2(-230, -225))
	_build_return()
	state.shortcut_changed.connect(_on_event)
	state.cache_opened.connect(_on_event)
	state.boss_progress_changed.connect(_on_boss)
	_refresh()


func floor_point(index: int, branch: bool, offset: float = 0) -> Vector2:
	var bounds: Rect2 = route.call("_branch_rect" if branch else "_main_rect", index)
	var floor_prefix := ("BranchRoom" if branch else "MainRoom") + str(index) + "Floor"
	var best := Vector2.INF
	var distance := INF
	var desired := bounds.get_center().x + offset
	for body in route.get_children():
		if not body is StaticBody2D or not String(body.name).begins_with(floor_prefix):
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D or collision.shape.size.x < 360:
			continue
		var half: float = collision.shape.size.x * 0.5
		var x := clampf(desired, body.position.x - half + 175, body.position.x + half - 175)
		if absf(x - desired) < distance:
			distance = absf(x - desired)
			best = Vector2(x, body.position.y - 34)
	assert(best.is_finite(), "Missing Rampart field floor: " + floor_prefix)
	return best


func _control(title: String, branch: int, event_id: String, required: PackedStringArray, prompt: String, ready_text: String, locked_text: String) -> void:
	var control := VALVE.instantiate() as Area2D
	control.set_script(STATION)
	control.name = "FieldStation%d" % controls.size()
	control.position = floor_point(branch, true, 120)
	control.set("shortcut_id", event_id)
	control.set("required_event_ids", required)
	control.set("threat_root", route)
	control.set("inactive_label", title)
	control.set("active_label", ready_text)
	control.set("inactive_prompt", prompt)
	control.set("active_prompt", "WORK RECORDED - SAVE AT A LAMP")
	control.set("locked_hint", locked_text)
	var plate := control.get_node("Core") as Polygon2D
	plate.polygon = PackedVector2Array([Vector2(-17, 17), Vector2(-17, -18), Vector2(11, -18), Vector2(19, -10), Vector2(19, 17)]) if branch != 1 else PackedVector2Array([Vector2(-24, 17), Vector2(-24, -8), Vector2(24, -8), Vector2(24, 17)])
	for label_name in ["StatusLabel", "InteractionPrompt"]:
		var label := control.get_node(label_name) as Label
		label.position.x = -190
		label.size.x = 380
	add_child(control)
	controls.append(control)
	_sign(control.position + Vector2(-230, -225))


func _build_return() -> void:
	var trial := ENCOUNTER.instantiate() as Area2D
	trial.name = "ReturnEncounter"
	trial.position = floor_point(7, false) + Vector2(0, 34)
	trial.set("zone_id", "starfall_reach")
	trial.set("encounter_id", PREFIX + "_field_return")
	trial.set("completion_event_id", PREFIX + "_field_return_complete")
	trial.set("required_event_ids", PackedStringArray([PREFIX + "_field_complete", GUARD_EVENTS[3]]))
	trial.set("required_boss_id", "hollow_sovereign")
	trial.set("enemy_health_bonus", 2)
	trial.set("encounter_title", "THE LAST SIGNAL WATCH")
	trial.set("dormant_hint", "DORMANT - RETURN AFTER THE HOLLOW SOVEREIGN")
	trial.set("locked_hint", "RESTORE SIGNALS + DEFEAT THE DEEP RESERVE GUARD")
	trial.get("enemy_scenes").append(SHADE)
	trial.get("enemy_scenes").append(SENTRY)
	trial.get("spawn_offsets").append(Vector2(-85, -86))
	trial.get("spawn_offsets").append(Vector2(85, -33))
	add_child(trial)
	var reward := CACHE.instantiate() as Area2D
	reward.name = "ReturnReward"
	reward.position = floor_point(7, false, 200)
	reward.set("cache_id", PREFIX + "_field_return_reserve")
	reward.set("cache_name", "Last Signal Reserve")
	reward.set("gold_reward", 30)
	reward.set("reward_item_id", "resonance_shard")
	reward.set("required_event_ids", PackedStringArray([PREFIX + "_field_return_complete"]))
	add_child(reward)


func _sign(point: Vector2) -> void:
	var sign := Label.new()
	sign.position = point
	sign.size = Vector2(460, 150)
	sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", 11)
	add_child(sign)
	signs.append(sign)


func _on_event(event_id: String) -> void:
	if event_id.begins_with(PREFIX):
		_refresh()


func _on_boss(boss_id: String) -> void:
	if boss_id == "hollow_sovereign":
		_refresh()


func _refresh() -> void:
	completed = bool(state.unlocked_shortcuts.get(PREFIX + "_relay_restored", false))
	if completed:
		# A legacy shutdown stays valid, but never fabricates recovered plates.
		state.unlock_shortcut(PREFIX + "_hazard_disabled")
		state.unlock_shortcut(PREFIX + "_field_complete")
	var count := int(bool(state.unlocked_shortcuts.get(PREFIX + "_plate_0", false))) + int(bool(state.unlocked_shortcuts.get(PREFIX + "_plate_1", false)))
	var return_text := "AFTER THE SOVEREIGN: REVISIT WESTERN GATE"
	if bool(state.defeated_bosses.get("hollow_sovereign", false)):
		return_text = "WESTERN GATE: CLEAR RETURN PATROL, THEN OPEN ITS RESERVE"
	if bool(state.unlocked_shortcuts.get(PREFIX + "_field_return_complete", false)):
		return_text = "RETURN PATROL CLEARED - COLLECT ITS WESTERN GATE RESERVE"
	if bool(state.opened_caches.get(PREFIX + "_field_return_reserve", false)):
		return_text = "WESTERN GATE RETURN RESERVE COLLECTED"
	for sign in signs:
		sign.text = "THE BROKEN SIGNAL NETWORK\nPLATES %d/2 - SIGNAL %s\nClear west/east side watches; recover both plates.\nRestore the desk in the high archive branch to quiet both root lanes.\nSignals + deepest-branch guard unseal the Rim Cache.\n%s\nOptional task; save progress at a lamp." % [count, "RESTORED" if completed else "OFFLINE", return_text]
