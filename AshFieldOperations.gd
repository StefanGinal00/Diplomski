extends Node2D

# Read-only scenery can observe transient calibration without polling or
# persisting a sequence that intentionally resets when loading a save.
signal progress_changed

const PROFILES := {
	"outskirts": ["THE OUTER WATCH REPORTS", "CLEAR BOTH SIDE WATCHES; COLLECT BOTH SCOUT REPORTS", "THE RETURNING SIEGE"],
	"causeway": ["THE REFUGE SIGNALS", "LIGHT FOOT > SPAN > CROWN; CLEAR NEARBY FOES FIRST", "THE SIGNAL HUNTERS"],
	"chapel": ["THE LOST VOTIVE RECORDS", "READ BOTH SIDE-NICHE RECORDS + COMPLETE THE ORIGINAL BELLS", "THE VOTIVE WATCH"],
	"forge": ["FURNACE SERVICE HOIST", "REPAIR WINCH + GEARBOX; START THE COOLING FAN", "THE REKINDLED FURNACE"],
	"barracks": ["QUARTERMASTER'S INSPECTION", "BREAK FOUR MARKED DRILL TARGETS + COMPLETE THE BEACON WAVES", "THE LAST INSPECTION"],
	"reservoir": ["PRESSURE CALIBRATION", "OPEN BOTH COOLANT VALVES; SET RETURN > INTAKE > EXHAUST", "THE PRESSURE WATCH"],
}
const VALVE := preload("res://SluiceValve.tscn")
const STATION := preload("res://PressureCalibrationStation.gd")
const SURVEY_STATION := preload("res://AshSurveyStation.gd")
const LIFT := preload("res://ShaftLift.tscn")
const TRIAL := preload("res://LocalizedEncounter.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const FIEND := preload("res://AshFiend.tscn")
const SENTRY := preload("res://AshSentry.tscn")
const RESIDENT := preload("res://TownResident.tscn")

var route: Node2D
var course: String
var state: Node
var requirements := PackedStringArray()
var controls: Array[Area2D] = []
var signs: Array[Label] = []
var sequence: Array[int] = []
var completed := false


func _ready() -> void:
	course = String(route.get("course_id"))
	state = get_node("/root/GameState")
	match course:
		"outskirts":
			_build_watch_posts()
		"causeway":
			for index in range(3):
				requirements.append("ash_causeway_signal_%d" % index)
				var title: String = ["FOOT SIGNAL", "SPAN SIGNAL", "CROWN SIGNAL"][index]
				var required := PackedStringArray() if index == 0 else PackedStringArray([requirements[index - 1]])
				var control := _survey_control(title, floor_point(index * 2), requirements[index], required, "[E] LIGHT SIGNAL", "SIGNAL LIT")
				var beacon := route.get_node("AshIdentity/RefugeBeacons/Beacon%d" % index) as Polygon2D
				beacon.polygon = PackedVector2Array([Vector2(-18, 20), Vector2(-11, -37), Vector2(0, -63), Vector2(13, -33), Vector2(18, 20)])
				beacon.position = control.position + Vector2(60, 0)
		"chapel":
			for index in range(2):
				requirements.append("ash_chapel_record_%d" % index)
				var crest: Rect2 = route.get("_niche_crests")[index]
				_survey_control("KEEPERS' RECORD" if index == 0 else "PILGRIMS' RECORD", crest.get_center() + Vector2(-120, -34), requirements[index], PackedStringArray(), "[E] COPY VOTIVE RECORD", "RECORD COPIED")
			requirements.append("ash_chapel_bells")
		"forge":
			requirements = PackedStringArray(["ash_forge_service_winch", "ash_forge_service_gearbox", "ash_forge_fan"])
			for index in range(2):
				_control("Winch" if index == 0 else "Gearbox", floor_point(0 if index == 0 else 3), requirements[index])
			_build_hoist()
		"barracks":
			for index in range(4):
				requirements.append("ash_barracks_drill_%d" % index)
			requirements.append("ash_barracks_cleared")
		"reservoir":
			requirements = PackedStringArray(["ash_reservoir_calibrated"])
			for index in range(3):
				var control := _control(["INTAKE", "RETURN", "EXHAUST"][index], floor_point([0, 2, 4][index]), requirements[0], true)
				control.set("station_index", index)
	_sign(floor_point(-1) + Vector2(-225, -195))
	_build_return_trial()
	state.shortcut_changed.connect(_on_event)
	_refresh()


func completion_id() -> String:
	return "ash_%s_field_complete" % course


func _build_watch_posts() -> void:
	for index in range(2):
		var crest: Rect2 = route.get("_niche_crests")[index]
		var guard_event := "ash_outskirts_lower_watch_cleared" if index == 0 else "ash_outskirts_guarded_niche_cleared"
		if index == 0:
			var trial := TRIAL.instantiate() as Area2D
			trial.name = "LowerWatch"
			trial.position = crest.get_center()
			trial.set("zone_id", "ashen_bastion")
			trial.set("encounter_id", "ash_outskirts_lower_watch")
			trial.set("completion_event_id", guard_event)
			trial.set("encounter_title", "LOWER WATCH PATROL")
			trial.get("enemy_scenes").append(FIEND)
			trial.get("enemy_scenes").append(SENTRY)
			trial.get("spawn_offsets").append(Vector2(-85, -33))
			trial.get("spawn_offsets").append(Vector2(85, -33))
			add_child(trial)
		var report_id := "ash_outskirts_report_%d" % index
		requirements.append(report_id)
		var station := _survey_control("LOWER WATCH REPORT" if index == 0 else "UPPER WATCH REPORT", crest.get_center() + Vector2(-120, -34), report_id, PackedStringArray([guard_event]), "[E] COLLECT SCOUT REPORT", "REPORT COLLECTED")
		station.set("locked_hint", "DEFEAT THIS WATCH'S PATROL FIRST")
		for stop in range(2):
			var marker := Marker2D.new()
			marker.name = "Scout%dStop%d" % [index, stop]
			marker.position = crest.get_center() + Vector2(100 + stop * 35, -33)
			add_child(marker)
		var scout := RESIDENT.instantiate() as Area2D
		scout.name = "WatchScout%d" % index
		scout.position = crest.get_center() + Vector2(100, -33)
		scout.set("resident_name", "Rell, Lower Watch" if index == 0 else "Sera, Upper Watch")
		scout.set("route_marker_names", PackedStringArray(["Scout%dStop0" % index, "Scout%dStop1" % index]))
		scout.set("coat_color", Color(0.42, 0.31, 0.27))
		scout.set("dialogue_lines", PackedStringArray(["The patrol holds this side shelter. Defeat it before collecting our report at the post.", "The other watch is in the other side niche. Our reports unseal the upper supply cache; they do not open the town gate or replace the gatekeeper's task."]))
		add_child(scout)
		scout.get_node("NameLabel").text = "Rell" if index == 0 else "Sera"


func _survey_control(title: String, point: Vector2, event_id: String, required: PackedStringArray, prompt: String, ready_text: String) -> Area2D:
	var control := VALVE.instantiate() as Area2D
	control.set_script(SURVEY_STATION)
	control.name = "SurveyStation%d" % controls.size()
	control.position = point
	control.set("shortcut_id", event_id)
	control.set("required_event_ids", required)
	control.set("threat_root", route.get_parent())
	control.set("inactive_label", title)
	control.set("active_label", ready_text)
	control.set("inactive_prompt", prompt)
	control.set("active_prompt", ready_text)
	var core := control.get_node("Core") as Polygon2D
	core.polygon = PackedVector2Array([Vector2(-12, 16), Vector2(-12, -18), Vector2(12, -18), Vector2(12, 16)]) if course == "chapel" else PackedVector2Array([Vector2(-12, 16), Vector2(-17, -4), Vector2(0, -26), Vector2(17, -4), Vector2(12, 16)])
	add_child(control)
	controls.append(control)
	_sign(point + Vector2(-225, -235))
	return control


func floor_point(gallery: int, offset: float = 0.0) -> Vector2:
	return supported_floor(route, gallery, offset)


static func supported_floor(route_node: Node2D, gallery: int, offset: float = 0.0) -> Vector2:
	# Semantic track anchors can straddle open shafts; use actual solid floors.
	var bounds: Rect2 = route_node.call("_chamber_rect", gallery + 1)
	var desired := bounds.get_center().x + offset
	var best := Vector2.INF
	var distance := INF
	for floor_value in route_node.get("_solid_rects"):
		var floor_rect: Rect2 = floor_value
		if absf(floor_rect.get_center().y - bounds.end.y) > 1 or floor_rect.size.x < 360:
			continue
		if floor_rect.position.x < bounds.position.x - 1 or floor_rect.end.x > bounds.end.x + 1:
			continue
		var x := clampf(desired, floor_rect.position.x + 175, floor_rect.end.x - 175)
		if absf(x - desired) < distance:
			distance = absf(x - desired)
			best = Vector2(x, floor_rect.get_center().y - 34)
	assert(best.is_finite(), "Missing safe Ash field floor: %s/%d" % [route_node.get("course_id"), gallery])
	return best


func _control(title: String, point: Vector2, event_id: String, calibration: bool = false) -> Area2D:
	var control := VALVE.instantiate() as Area2D
	if calibration:
		control.set_script(STATION)
		control.set("controller", self)
	control.name = title.capitalize().replace(" ", "")
	control.position = point
	control.set("shortcut_id", event_id)
	control.set("inactive_label", title.to_upper())
	control.set("active_label", title.to_upper() + " - READY")
	control.set("inactive_prompt", "[E] CALIBRATE" if calibration else "[E] REPAIR " + title.to_upper())
	control.set("active_prompt", "CALIBRATED" if calibration else "REPAIRED")
	add_child(control)
	controls.append(control)
	_sign(point + Vector2(-225, -235))
	return control


func calibrate(index: int) -> bool:
	if course != "reservoir" or completed or index < 0 or index >= 3:
		return false
	if not bool(state.unlocked_shortcuts.get("ash_reservoir_lower", false)) or not bool(state.unlocked_shortcuts.get("ash_reservoir_upper", false)):
		_refresh("OPEN BOTH COOLANT VALVES BEFORE CALIBRATING")
		return false
	var order := [1, 0, 2]
	if index != order[sequence.size()]:
		sequence.clear()
		_refresh("WRONG ORDER - RETURN > INTAKE > EXHAUST")
		return false
	sequence.append(index)
	if sequence.size() == 3:
		state.unlock_shortcut("ash_reservoir_calibrated")
	_refresh()
	return true


func _build_hoist() -> void:
	for index in range(2):
		var point := floor_point(-1 if index == 0 else 4, -240)
		var marker := Marker2D.new()
		marker.name = "ServiceArrival%d" % index
		marker.position = point + Vector2(-55, 0)
		marker.add_to_group("ash_forge_service_arrival_%d" % index)
		add_child(marker)
		var lift := LIFT.instantiate() as Area2D
		lift.name = "ServiceHoist%d" % index
		lift.position = point
		lift.set("shortcut_id", completion_id())
		lift.set("room_id", "ash_forge")
		lift.set("enemy_group", &"enemy")
		lift.set("target_marker_group", StringName("ash_forge_service_arrival_%d" % (1 - index)))
		lift.set("lift_label", "FURNACE SERVICE HOIST")
		lift.set("locked_prompt", "REPAIR WINCH + GEARBOX; COOL THE FORGE")
		lift.set("locked_message", "Repair the two service mechanisms and start the original cooling fan.")
		add_child(lift)


func _build_return_trial() -> void:
	var trial := TRIAL.instantiate() as Area2D
	trial.name = "ReturnEncounter"
	trial.position = floor_point(5) + Vector2(0, 34)
	trial.set("zone_id", "ashen_bastion")
	trial.set("encounter_id", "ash_%s_field_return" % course)
	trial.set("completion_event_id", "ash_%s_field_return_complete" % course)
	trial.set("minimum_zone_tier", 1)
	trial.set("required_event_ids", PackedStringArray([completion_id(), "ash_%s_guarded_niche_cleared" % course]))
	trial.set("encounter_title", PROFILES[course][2])
	trial.set("dormant_hint", "DORMANT - RETURN AFTER THE CASTELLAN")
	trial.set("locked_hint", "FINISH FIELD TASK + CLEAR THE UPPER NICHE")
	var foes: Array = {"outskirts": [SENTRY, SENTRY], "causeway": [FIEND, SENTRY], "chapel": [SENTRY, FIEND], "forge": [FIEND, FIEND], "barracks": [SENTRY, SENTRY], "reservoir": [FIEND, SENTRY]}[course]
	for index in range(2):
		trial.get("enemy_scenes").append(foes[index])
		trial.get("spawn_offsets").append(Vector2(-85 + index * 170, -33))
	add_child(trial)
	var reward := CACHE.instantiate() as Area2D
	reward.name = "ReturnReward"
	reward.position = trial.position + Vector2(125, -34)
	reward.set("cache_id", "ash_%s_field_return_reserve" % course)
	reward.set("cache_name", String(PROFILES[course][2]).capitalize() + " Reserve")
	reward.set("gold_reward", 25)
	reward.set("reward_item_id", "ether_dust" if course in ["reservoir", "chapel"] else "iron_fragment")
	reward.set("required_event_ids", PackedStringArray(["ash_%s_field_return_complete" % course]))
	add_child(reward)


func _sign(point: Vector2) -> void:
	var sign := Label.new()
	sign.position = point
	sign.size = Vector2(450, 110)
	sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", 11)
	add_child(sign)
	signs.append(sign)


func _on_event(event_id: String) -> void:
	if event_id.begins_with("ash_" + course):
		_refresh()


func _refresh(feedback: String = "") -> void:
	var count := 0
	for event_id in requirements:
		count += int(bool(state.unlocked_shortcuts.get(event_id, false)))
	completed = count == requirements.size()
	if completed and not bool(state.unlocked_shortcuts.get(completion_id(), false)):
		state.unlock_shortcut(completion_id())
	if course == "reservoir":
		for index in range(controls.size()):
			controls[index].call("set_calibrated", completed or sequence.has(index))
	if course == "causeway":
		for index in range(controls.size()):
			var beacon := route.get_node("AshIdentity/RefugeBeacons/Beacon%d" % index) as Polygon2D
			beacon.color = Color(1.0, 0.76, 0.3, 0.95) if bool(state.unlocked_shortcuts.get(requirements[index], false)) else Color(0.30, 0.21, 0.21, 0.6)
	if course == "outskirts":
		for index in range(2):
			var scout := get_node("WatchScout%d" % index)
			if bool(state.unlocked_shortcuts.get(requirements[index], false)):
				scout.set("dialogue_lines", PackedStringArray(["You have our report. Oren's field board in Hearth tracks both watches and the upper supplies.", "After the Castellan falls, inspect the final gallery for the returning siege patrol. We will keep the watches supplied while you scout ahead."]))
				scout.set("next_line_index", 0)
	var detail := String(PROFILES[course][1]) + "\nPROGRESS %d/%d" % [sequence.size() if course == "reservoir" and not completed else count, 3 if course == "reservoir" and not completed else requirements.size()]
	if completed:
		detail = "FIELD TASK + UPPER GUARDIANS COMPLETE" if bool(state.unlocked_shortcuts.get("ash_%s_guarded_niche_cleared" % course, false)) else "FIELD TASK COMPLETE - CLEAR THE UPPER NICHE FOR ITS CACHE"
	if not feedback.is_empty():
		detail = feedback
	for sign in signs:
		sign.text = String(PROFILES[course][0]) + "\n" + detail + "\nAFTER THE CASTELLAN: REVISIT THE FINAL GALLERY"
		if course == "reservoir" and not completed:
			sign.text += "\nUNFINISHED CALIBRATION RESTARTS ON LOAD"
		elif course == "causeway":
			sign.text += "\nSIGNALS ARE LANDMARKS, NOT SAFE ZONES; SAVE AT A LAMP"
		elif course == "chapel":
			var both_records := bool(state.unlocked_shortcuts.get("ash_chapel_record_0", false)) and bool(state.unlocked_shortcuts.get("ash_chapel_record_1", false))
			sign.text += "\n" + ("KEEPERS: TEND THE ROAD. PILGRIMS: REMEMBER WHO WALKED IT." if both_records else "THE TWO RECORDS CAN BE COPIED IN EITHER ORDER")
	progress_changed.emit()
