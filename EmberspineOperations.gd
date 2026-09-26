extends Node2D

const VALVE := preload("res://SluiceValve.tscn")
const SURVEY := preload("res://AshSurveyStation.gd")
const TRIAL := preload("res://LocalizedEncounter.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const FIEND := preload("res://AshFiend.tscn")
const SENTRY := preload("res://AshSentry.tscn")
const COMPLETION := "ash_emberspine_field_complete"
const GUARD := "ash_emberspine_guarded_niche_cleared"
var route: Node2D
var state: Node
var controls: Array[Area2D] = []
var signs: Array[Label] = []


func _ready() -> void:
	state = get_node("/root/GameState")
	# Preserve a previously saved all-hazards shutdown as individual repairs.
	if bool(state.unlocked_shortcuts.get("ash_emberspine_hazard_disabled", false)):
		for index in range(2):
			state.unlock_shortcut("ash_emberspine_cooling_%d" % index)
	for index in range(2):
		var control := VALVE.instantiate() as Area2D
		control.set_script(SURVEY)
		control.name = "CoolingValve%d" % index
		control.position = floor_point(0 if index == 0 else 2, true)
		control.set("shortcut_id", "ash_emberspine_cooling_%d" % index)
		control.set("inactive_label", "INTAKE COOLING" if index == 0 else "DEEP COOLING")
		control.set("active_label", "COOLING RESTORED")
		control.set("inactive_prompt", "[E] OPEN COOLANT FEED")
		control.set("active_prompt", "FIRE LANE DISABLED")
		control.set("threat_root", route)
		add_child(control)
		controls.append(control)
		_sign(control.position + Vector2(-220, -210))
		# Fix the old span-centre placement as well: it could lie over a shaft.
		var hazard := route.get_node("LowerHazard%d" % index) as Node2D
		hazard.position = floor_point(2 + index * 2, false) + Vector2(0, 16)
	var guard := route.get_node_or_null("BranchGuard3") as Node2D
	if guard != null:
		# This authored guard owns the reserve, not another overlapping ambush.
		if not guard.is_connected("defeated", _on_guard_defeated):
			guard.connect("defeated", _on_guard_defeated, CONNECT_ONE_SHOT)
	var cache := route.get_node("RimCache") as Node2D
	cache.position = floor_point(3, true, 100)
	_sign(floor_point(0, false) + Vector2(-220, -210))
	_sign(cache.position + Vector2(-220, -210))
	_build_return()
	state.shortcut_changed.connect(_on_event)
	_refresh()


func floor_point(index: int, branch: bool, offset: float = 0) -> Vector2:
	var bounds: Rect2 = route.call("_branch_rect" if branch else "_main_rect", index)
	var prefix := ("BranchRoom" if branch else "MainRoom") + str(index) + "Floor"
	var best := Vector2.INF
	var distance := INF
	var desired := bounds.get_center().x + offset
	for child in route.get_children():
		if not child is StaticBody2D or not String(child.name).begins_with(prefix):
			continue
		var collision := child.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D or collision.shape.size.x < 260:
			continue
		var half: float = collision.shape.size.x * 0.5
		var x := clampf(desired, child.position.x - half + 130, child.position.x + half - 130)
		if absf(x - desired) < distance:
			distance = absf(x - desired)
			best = Vector2(x, child.position.y - 34)
	assert(best.is_finite(), "Missing Emberspine field floor: " + prefix)
	return best


func _build_return() -> void:
	var trial := TRIAL.instantiate() as Area2D
	trial.name = "ReturnEncounter"
	trial.position = floor_point(7, false) + Vector2(0, 34)
	trial.set("zone_id", "ashen_bastion")
	trial.set("encounter_id", "ash_emberspine_field_return")
	trial.set("completion_event_id", "ash_emberspine_field_return_complete")
	trial.set("minimum_zone_tier", 1)
	trial.set("required_event_ids", PackedStringArray([COMPLETION, GUARD]))
	trial.set("encounter_title", "THE COOLED HEART'S WATCH")
	trial.set("dormant_hint", "DORMANT - RETURN AFTER THE CASTELLAN")
	trial.set("locked_hint", "COOL BOTH LANES + DEFEAT THE DEEP RESERVE GUARD")
	trial.get("enemy_scenes").append(FIEND)
	trial.get("enemy_scenes").append(SENTRY)
	trial.get("spawn_offsets").append(Vector2(-85, -33))
	trial.get("spawn_offsets").append(Vector2(85, -33))
	add_child(trial)
	var reward := CACHE.instantiate() as Area2D
	reward.name = "ReturnReward"
	reward.position = floor_point(7, false, 200)
	reward.set("cache_id", "ash_emberspine_field_return_reserve")
	reward.set("cache_name", "Cooled Heart Reserve")
	reward.set("gold_reward", 25)
	reward.set("reward_item_id", "iron_fragment")
	reward.set("required_event_ids", PackedStringArray(["ash_emberspine_field_return_complete"]))
	add_child(reward)


func _on_guard_defeated() -> void:
	state.unlock_shortcut(GUARD)


func _on_event(event_id: String) -> void:
	if event_id.begins_with("ash_emberspine_"):
		_refresh()


func _sign(point: Vector2) -> void:
	var sign := Label.new()
	sign.position = point
	sign.size = Vector2(440, 110)
	sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", 11)
	add_child(sign)
	signs.append(sign)


func _refresh() -> void:
	var count := int(bool(state.unlocked_shortcuts.get("ash_emberspine_cooling_0", false))) + int(bool(state.unlocked_shortcuts.get("ash_emberspine_cooling_1", false)))
	if count == 2 and not bool(state.unlocked_shortcuts.get(COMPLETION, false)):
		state.unlock_shortcut(COMPLETION)
	var guard_cleared := bool(state.unlocked_shortcuts.get(GUARD, false))
	var return_hint := "AWAKENED WATCH CLEARED" if bool(state.unlocked_shortcuts.get("ash_emberspine_field_return_complete", false)) else "After the Castellan: revisit EMBER HEART."
	for sign in signs:
		sign.text = "THE COOLING SPINE\nSIDE FEEDS RESTORED %d/2; DEEP GUARD %s\nEach feed stops its own fire lane. The deepest branch holds the reserve.\n%s" % [count, "CLEARED" if guard_cleared else "REMAINS", return_hint]
