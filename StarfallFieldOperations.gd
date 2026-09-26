extends Node2D

# Optional discoveries only: never grant sigils or change the Sovereign gate.
const PROFILES := {
	"StarfallOutskirts": ["CARAVAN REPAIRS", "REPAIR BOTH SIDE-BRANCH WINCHES TO RAISE ROAD COVER", "THE LAST SIEGE"],
	"StarfallSilentGate": ["WARD CIRCUIT INSPECTION", "POWER THE ORIGINAL HIGH/LOW RELAYS; INSPECT BOTH SIDE TERMINALS", "THE HUSHED WATCH"],
	"StarfallMemoryVault": ["THE SCATTERED RECORDS", "BREAK THREE MARKED RECORD CASES IN THE SIDE BRANCHES", "THE ARCHIVE REMNANT"],
	"StarfallRootedHall": ["THE DORMANT GARDENS", "OPEN THE ORIGINAL ROOT CHANNEL; RESTORE BOTH SIDE-BRANCH SEEDBEDS", "THE THORN WATCH"],
	"StarfallSoulCrucible": ["CONTAINMENT CHAMBERS", "EACH ORIGINAL CHANNEL ENABLES ONE SIDE-BRANCH CONTAINMENT FIGHT", "THE UNBOUND REMNANT"],
	"StarfallSunlessPassage": ["THE PROCESSION LIGHTS", "LIGHT FIRST > MIDDLE > LAST BEACON IN THE THREE SIDE BRANCHES", "THE NIGHT PROCESSION"],
}
const VALVE := preload("res://SluiceValve.tscn")
const STATION := preload("res://AshSurveyStation.gd")
const ENCOUNTER := preload("res://LocalizedEncounter.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const SENTRY := preload("res://AshSentry.tscn")
const SHADE := preload("res://EchoShade.tscn")
const STALKER := preload("res://RootStalker.tscn")

var route: Node2D
var state: Node
var room_name: String
var prefix: String
var requirements := PackedStringArray()
var controls: Array[Area2D] = []
var signs: Array[Label] = []
var covers: Array[StaticBody2D] = []
var completed := false
var landmarks: Array[Polygon2D] = []


func _ready() -> void:
	state = get_node("/root/GameState")
	room_name = String(route.get_parent().name)
	prefix = String(route.get("plan")["id"])
	match room_name:
		"StarfallOutskirts":
			for index in range(2):
				requirements.append(prefix + "_winch_%d" % index)
				_control("CARAVAN WINCH %d" % (index + 1), 1 + index * 2, requirements[index], PackedStringArray(), "[E] REPAIR ROAD COVER")
				_build_cover(1 + index * 2)
		"StarfallSilentGate":
			for index in range(2):
				requirements.append(prefix + "_inspection_%d" % index)
				_control("HIGH WARD TERMINAL" if index == 0 else "LOW WARD TERMINAL", 1 if index == 0 else 5, requirements[index], PackedStringArray(["starfall_silent_high" if index == 0 else "starfall_silent_low"]), "[E] VERIFY WARD CIRCUIT")
		"StarfallMemoryVault":
			for index in range(3):
				requirements.append(prefix + "_record_%d" % index)
				_sign(branch_point(1 + index * 2) + Vector2(-230, -210))
		"StarfallRootedHall":
			for index in range(2):
				requirements.append(prefix + "_seedbed_%d" % index)
				_control("DORMANT SEEDBED %d" % (index + 1), 1 + index * 4, requirements[index], PackedStringArray(["starfall_root_channels"]), "[E] RESTORE SEEDBED", "SEEDBED BLOOMING", "OPEN THE ORIGINAL ROOT CHANNEL FIRST")
				_landmark(controls[index].position + Vector2(65, 22), true)
		"StarfallSoulCrucible":
			for index in range(2):
				requirements.append(prefix + "_containment_%d" % index)
				_build_containment(index)
			requirements.append("starfall_crucible_stabilized")
		"StarfallSunlessPassage":
			for index in range(3):
				requirements.append(prefix + "_beacon_%d" % index)
				var needed := PackedStringArray() if index == 0 else PackedStringArray([requirements[index - 1]])
				_control(["FIRST LIGHT", "MIDDLE LIGHT", "LAST LIGHT"][index], 1 + index * 2, requirements[index], needed, "[E] LIGHT PROCESSION BEACON", "BEACON LIT - TWO VOID LANES QUIET", "LIGHT THE PREVIOUS SIDE-BRANCH BEACON FIRST")
				_landmark(controls[index].position + Vector2(65, 10), false)
	_sign(floor_point(route, 0) + Vector2(-230, -215))
	# Keep the field instructions above, not on top of the guardian status.
	_sign((get_parent().get_node("Niche4_Crest") as Node2D).position + Vector2(-230, -355))
	_build_return()
	state.shortcut_changed.connect(_on_event)
	state.boss_progress_changed.connect(_on_boss)
	_refresh()


static func floor_point(route_node: Node2D, tier: int, offset: float = 0) -> Vector2:
	var bounds: Rect2 = route_node.call("_chamber_rect", tier)
	var desired := bounds.get_center().x + offset
	var best := Vector2.INF
	var distance := INF
	for body in route_node.get("generated").get_children():
		if not String(body.name).begins_with("Chamber%d_Floor" % tier):
			continue
		var collision := body.get_node("CollisionShape2D") as CollisionShape2D
		var size := (collision.shape as RectangleShape2D).size
		if size.x < 400:
			continue
		var x := clampf(desired, body.position.x - size.x * 0.5 + 190, body.position.x + size.x * 0.5 - 190)
		if absf(x - desired) < distance:
			distance = absf(x - desired)
			best = Vector2(x, body.position.y - 34)
	assert(best.is_finite(), "Missing Starfall field floor: %s/%d" % [route_node.get_parent().name, tier])
	return best


func branch_point(tier: int) -> Vector2:
	return (get_parent().get_node("Branch%d_Chamber" % tier) as Node2D).position + Vector2(0, -34)


func _control(title: String, tier: int, event_id: String, needed: PackedStringArray, prompt: String, ready_text: String = "", locked_text: String = "") -> void:
	var control := VALVE.instantiate() as Area2D
	control.set_script(STATION)
	control.name = "FieldStation%d" % controls.size()
	control.position = branch_point(tier)
	control.set("shortcut_id", event_id)
	control.set("required_event_ids", needed)
	control.set("locked_hint", locked_text if not locked_text.is_empty() else "POWER THE ORIGINAL %s RELAY FIRST" % ("HIGH" if tier == 1 else "LOW"))
	control.set("threat_root", route.get_parent())
	control.set("inactive_label", title)
	control.set("inactive_prompt", prompt)
	control.set("active_label", ready_text if not ready_text.is_empty() else ("COVER RAISED" if room_name == "StarfallOutskirts" else "WARD VERIFIED"))
	control.set("active_prompt", "WORK COMPLETE - SAVE AT A LAMP")
	add_child(control)
	controls.append(control)
	_sign(control.position + Vector2(-230, -280))


func _landmark(point: Vector2, plant: bool) -> void:
	var visual := Polygon2D.new()
	visual.name = "RestoredLandmark%d" % landmarks.size()
	visual.position = point
	visual.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(-23, -28), Vector2(-5, -14), Vector2(0, -60), Vector2(10, -23), Vector2(32, -41), Vector2(24, 0)]) if plant else PackedVector2Array([Vector2(-14, 0), Vector2(-8, -35), Vector2(-20, -49), Vector2(0, -78), Vector2(20, -49), Vector2(8, -35), Vector2(14, 0)])
	add_child(visual)
	landmarks.append(visual)


func _build_containment(index: int) -> void:
	var trial := ENCOUNTER.instantiate() as Area2D
	trial.name = "Containment%d" % index
	trial.position = branch_point(1 + index * 4) + Vector2(0, 34)
	trial.set("zone_id", "starfall_reach")
	trial.set("encounter_id", prefix + "_containment_%d" % index)
	trial.set("completion_event_id", requirements[index])
	trial.set("required_event_ids", PackedStringArray(["starfall_crucible_high" if index == 0 else "starfall_crucible_low"]))
	trial.set("locked_hint", "POWER THE ORIGINAL %s CHANNEL FIRST; RE-ENTER THIS CHAMBER" % ("HIGH" if index == 0 else "LOW"))
	trial.set("encounter_title", "HIGH CONTAINMENT" if index == 0 else "LOW CONTAINMENT")
	trial.get("enemy_scenes").append(SHADE if index == 0 else STALKER)
	trial.get("enemy_scenes").append(SENTRY)
	trial.get("spawn_offsets").append(Vector2(-85, -86 if index == 0 else -33))
	trial.get("spawn_offsets").append(Vector2(85, -33))
	add_child(trial)
	_sign(trial.position + Vector2(-230, -370))


func _build_cover(tier: int) -> void:
	var body := StaticBody2D.new()
	body.name = "RoadCover%d" % covers.size()
	body.position = floor_point(route, tier, 340) + Vector2(0, -3)
	body.collision_layer = 0
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 55)
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.name = "CoverVisual"
	visual.polygon = PackedVector2Array([Vector2(-24, 27.5), Vector2(-24, -27.5), Vector2(24, -27.5), Vector2(24, 27.5)])
	body.add_child(visual)
	add_child(body)
	covers.append(body)


func _build_return() -> void:
	var trial := ENCOUNTER.instantiate() as Area2D
	trial.name = "ReturnEncounter"
	trial.position = floor_point(route, 6) + Vector2(0, 34)
	trial.set("zone_id", "starfall_reach")
	trial.set("encounter_id", prefix + "_field_return")
	trial.set("completion_event_id", prefix + "_field_return_complete")
	trial.set("required_boss_id", "hollow_sovereign")
	trial.set("enemy_health_bonus", 2)
	trial.set("required_event_ids", PackedStringArray([prefix + "_field_complete", prefix + "_niche_cleared"]))
	trial.set("encounter_title", PROFILES[room_name][2])
	trial.set("dormant_hint", "DORMANT - RETURN AFTER THE HOLLOW SOVEREIGN")
	trial.set("locked_hint", "COMPLETE FIELD TASK + CLEAR UPPER RESERVE GUARDIANS")
	for index in range(2):
		var scene := SENTRY if room_name == "StarfallOutskirts" or (room_name == "StarfallSilentGate" and index == 1) else SHADE
		if room_name == "StarfallRootedHall":
			scene = STALKER
		elif room_name == "StarfallSoulCrucible":
			scene = SHADE if index == 0 else SENTRY
		elif room_name == "StarfallSunlessPassage":
			scene = SHADE if index == 0 else STALKER
		trial.get("enemy_scenes").append(scene)
		trial.get("spawn_offsets").append(Vector2(-85 + index * 170, -86 if scene == SHADE else -33))
	add_child(trial)
	var cache := CACHE.instantiate() as Area2D
	cache.name = "ReturnReward"
	cache.position = trial.position + Vector2(125, -34)
	cache.set("cache_id", prefix + "_field_return_reserve")
	cache.set("cache_name", String(PROFILES[room_name][2]).capitalize() + " Reserve")
	cache.set("gold_reward", 30)
	cache.set("reward_item_id", {"StarfallOutskirts": "iron_fragment", "StarfallRootedHall": "healing_herb", "StarfallSoulCrucible": "resonance_shard", "StarfallSunlessPassage": "resonance_shard"}.get(room_name, "ether_dust"))
	cache.set("required_event_ids", PackedStringArray([prefix + "_field_return_complete"]))
	add_child(cache)


func _sign(point: Vector2) -> void:
	var sign := Label.new()
	sign.position = point
	sign.size = Vector2(460, 170)
	sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", 11)
	add_child(sign)
	signs.append(sign)


func _on_event(event_id: String) -> void:
	if event_id.begins_with(prefix) or requirements.has(event_id):
		_refresh()


func _on_boss(_boss_id: String) -> void:
	_refresh()


func _refresh() -> void:
	var count := 0
	for event_id in requirements:
		count += int(bool(state.unlocked_shortcuts.get(event_id, false)))
	completed = count == requirements.size()
	if completed and not bool(state.unlocked_shortcuts.get(prefix + "_field_complete", false)):
		state.unlock_shortcut(prefix + "_field_complete")
	for index in range(covers.size()):
		var active := bool(state.unlocked_shortcuts.get(requirements[index], false))
		covers[index].collision_layer = 1 if active else 0
		covers[index].get_node("CoverVisual").color = Color(0.51, 0.48, 0.68) if active else Color(0.51, 0.48, 0.68, 0.15)
	for index in range(landmarks.size()):
		var active := bool(state.unlocked_shortcuts.get(requirements[index], false))
		landmarks[index].color = (Color(0.39, 0.85, 0.50) if room_name == "StarfallRootedHall" else Color(0.91, 0.83, 1.0)) if active else Color(0.28, 0.31, 0.38, 0.55)
	var detail := String(PROFILES[room_name][1]) + "\nPROGRESS %d/%d" % [count, requirements.size()]
	if completed:
		detail = "TASK COMPLETE - CLEAR THE UPPER RESERVE GUARDIANS" if not bool(state.unlocked_shortcuts.get(prefix + "_niche_cleared", false)) else "UPPER RESERVE UNSEALED"
	var return_text := "AFTER THE SOVEREIGN: REVISIT THE FINAL GALLERY"
	if bool(state.unlocked_shortcuts.get(prefix + "_field_return_complete", false)):
		return_text = "RETURN PATROL CLEARED - FINAL GALLERY RESERVE UNSEALED"
	elif bool(state.defeated_bosses.get("hollow_sovereign", false)):
		return_text = "RETURN PATROL AWAKE - FINISH LOCAL TASK/GUARDIANS, THEN VISIT FINAL GALLERY"
	for sign in signs:
		sign.text = String(PROFILES[room_name][0]) + "\n" + detail + "\n" + return_text + "\nOPTIONAL DISCOVERY; SAVE PROGRESS AT A LAMP"
		if room_name == "StarfallRootedHall":
			sign.text += "\nGRAZERS ARE NEUTRAL; NO NEED TO HARM THEM. THIS IS NOT A SAFE ZONE."
		elif room_name == "StarfallSunlessPassage":
			sign.text += "\nBEACONS QUIET VOID LANES; ONLY THE ORIGINAL ANCHOR STABILIZES BRIDGES."
