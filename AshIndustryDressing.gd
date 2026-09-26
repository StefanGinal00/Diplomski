@tool
extends "res://AshRouteDressing.gd"

const INDUSTRY_SITES := {
	"forge": [
		[-1, 0.5, "camp", "THE FURNACE FITTER'S REST", "A MAINTENANCE SHELTER, NOT A CHECKPOINT"],
		[0, 0.62, "repair_panel", "SERVICE HOIST REGISTER", "REPAIR WINCH + GEARBOX; START THE ORIGINAL COOLING FAN"],
		[1, 0.30, "haul", "FURNACE PARTS CART", "THE WINCH AND GEARBOX ARE SEPARATE REPAIRS"],
		[3, 0.62, "fan_model", "COOLING DUCT WINDOW", "THE FAN CALMS HEAT LANES; IT DOES NOT CLEAR ENEMIES"],
		[4, 0.78, "garden", "SOOT FERN BED", "RESTING GRAZERS ARE NEUTRAL UNLESS STRUCK"],
		[5, 0.40, "pump", "OIL AND PUMP STORES", "THE RESTORED SERVICE HOIST SHORTENS BACKTRACKING"],
		[6, 0.68, "reserve_board", "FURNACE KEEPER'S RESERVE", "CLEAR THE UPPER GUARDIANS AFTER REPAIRING THE HOIST"],
	],
	"barracks": [
		[-1, 0.5, "camp", "THE ARMOURER'S SHELTER", "THE OLD DRILL SHELTER IS NOT A SAFE ZONE"],
		[0, 0.58, "drill_panel", "QUARTERMASTER'S TALLY", "FOUR MARKED TARGETS AND THE ORIGINAL BEACON WAVES"],
		[1, 0.26, "haul", "TRAINING SUPPLY CART", "ORDINARY CRATES ARE NOT MARKED DRILL TARGETS"],
		[3, 0.55, "armour_rack", "THE EMPTY ARMOUR RACK", "THE BEACON TRIAL IS SEPARATE FROM THE UPPER GUARDIANS"],
		[4, 0.25, "garden", "RAMPART MOSS", "RESTING GRAZERS NEED NOT BE FOUGHT"],
		[5, 0.55, "survey", "THE LAST MUSTER RECORD", "AFTER THE CASTELLAN, RETURN TO THE FINAL GALLERY"],
		[6, 0.68, "reserve_board", "QUARTERMASTER'S RESERVE", "FINISH THE INSPECTION AND DEFEAT THE UPPER GUARDIANS"],
	],
	"reservoir": [
		[-1, 0.5, "camp", "THE PRESSURE KEEPER'S REST", "A DRY SERVICE SHELTER, NOT A CHECKPOINT"],
		[0, 0.55, "valve_panel", "COOLANT BANK REGISTER", "OPEN BOTH ORIGINAL COOLANT VALVES BEFORE CALIBRATING"],
		[1, 0.35, "pump", "COOLANT SERVICE STORES", "VALVES AND CALIBRATION ARE SEPARATE STEPS"],
		[3, 0.65, "calibration_panel", "PRESSURE BALANCE DIAGRAM", "SET RETURN > INTAKE > EXHAUST AT THE THREE STATIONS"],
		[4, 0.74, "pool", "STILL COOLANT REEDS", "GRAZERS REST BETWEEN THE PRESSURE CHANNELS"],
		[5, 0.56, "haul", "PRESSURE CELL CARGO", "WRONG ORDER RESETS THE UNFINISHED CALIBRATION"],
		[6, 0.68, "reserve_board", "ENGINEER'S RESERVE", "CALIBRATION AND UPPER GUARDIANS UNSEAL THIS RESERVE"],
	],
	"outskirts": [
		[0, 0.52, "watch_map", "THE TWO WATCH REPORTS", "VISIT RELL AND SERA IN THE TWO SIDE WATCHES"],
		[1, 0.32, "haul", "OUTER WATCH SUPPLIES", "THESE CRATES DO NOT COUNT AS GATEKEEPER TARGETS"],
		[2, 0.55, "watch_banner", "THE LOWER WATCH STANDARD", "DEFEAT THE LOCAL PATROL, THEN COLLECT ITS REPORT"],
		[3, 0.58, "garden", "SCORIA WILDFLOWERS", "RESTING GRAZERS ARE NOT HOSTILE WATCH PATROLS"],
		[4, 0.65, "survey", "UPPER WATCH WAYSTONES", "THE UPPER REPORT REQUIRES THE UPPER GUARDIANS"],
		[5, 0.65, "haul", "ABANDONED SIEGE CART", "THE WATCH REPORTS DO NOT REPLACE THE TOWN GATE QUEST"],
		[6, 0.68, "reserve_board", "SCORIA WATCH RESERVE", "AFTER THE CASTELLAN, RETURN FOR THE SIEGE PATROL"],
	],
}


func _sites() -> Array:
	return INDUSTRY_SITES[region]


func _site_tone() -> Color:
	return {"forge": Color(0.83, 0.47, 0.28), "barracks": Color(0.67, 0.49, 0.43), "reservoir": Color(0.40, 0.65, 0.62), "outskirts": Color(0.73, 0.59, 0.36)}[region]


func _resident_name() -> String:
	return {"forge": "Varek, Furnace Fitter", "barracks": "Ilen, Old Armourer", "reservoir": "Senn, Pressure Keeper"}[region]


func _fauna_name() -> String:
	return {"forge": "Soot Fern Grazer", "barracks": "Rampart Moss Grazer", "reservoir": "Coolant Reed Grazer", "outskirts": "Scoria Flower Grazer"}[region]


func bind_operations() -> void:
	var ops := expansion.get_node_or_null("FieldOperations")
	if ops != null and not ops.progress_changed.is_connected(_refresh_ash):
		ops.progress_changed.connect(_refresh_ash)
	_refresh_ash()


func _build_site(index: int, data: Array, at: Vector2) -> void:
	super._build_site(index, data, at)
	var site := get_node("Site%d" % index)
	# Keep these read-only captions clear of original operation boards.
	if data[2] in ["repair_panel", "drill_panel", "valve_panel", "calibration_panel", "watch_map"]:
		site.get_node("RouteClue").position.y = 20
	match data[2]:
		"repair_panel", "drill_panel", "valve_panel", "calibration_panel", "watch_map":
			_line(site, "PanelFrame", [Vector2(-150, 0), Vector2(-150, -132), Vector2(150, -132), Vector2(150, 0)], tone.darkened(0.25), 6)
			var names: Array = {"repair_panel": ["WINCH", "GEAR", "FAN"], "drill_panel": ["1", "2", "3", "4", "WAVES"], "valve_panel": ["LOWER", "UPPER"], "calibration_panel": ["RETURN", "INTAKE", "EXHAUST"], "watch_map": ["LOWER", "UPPER"]}[data[2]]
			for i in range(names.size()):
				var x := (float(i) - (names.size() - 1) * 0.5) * (53 if names.size() == 5 else 84)
				_ring(site, "Socket%d" % i, Vector2(x, -82), 19, tone)
				_poly(site, "Light%d" % i, [Vector2(x - 11, -82), Vector2(x, -96), Vector2(x + 11, -82), Vector2(x, -68)], tone.darkened(0.55))
				var label := Label.new()
				label.position = Vector2(x - 31, -49)
				label.size.x = 62
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.text = names[i]
				label.add_theme_font_size_override("font_size", 10)
				site.add_child(label)
		"fan_model":
			_ring(site, "Duct", Vector2(0, -76), 70, tone.darkened(0.2))
			for i in range(4):
				var blade := Polygon2D.new()
				blade.name = "Blade%d" % i
				blade.position = Vector2(0, -76)
				blade.rotation = i * PI * 0.5
				blade.polygon = PackedVector2Array([Vector2(0, 0), Vector2(18, -55), Vector2(49, -34), Vector2(23, 3)])
				blade.color = tone.darkened(0.3)
				site.add_child(blade)
			_line(site, "DuctFeet", [Vector2(-74, 0), Vector2(-48, -31), Vector2(48, -31), Vector2(74, 0)], tone, 6)
		"armour_rack":
			_line(site, "Rack", [Vector2(-140, 0), Vector2(-140, -140), Vector2(140, -140), Vector2(140, 0)], tone, 6)
			for i in range(3):
				var x := float(i - 1) * 80
				_poly(site, "Armour%d" % i, [Vector2(x - 28, -110), Vector2(x - 12, -127), Vector2(x + 12, -127), Vector2(x + 28, -110), Vector2(x + 18, -52), Vector2(x - 18, -52)], tone.darkened(0.35))
				_line(site, "Belt%d" % i, [Vector2(x - 18, -67), Vector2(x + 18, -67)], tone.lightened(0.5), 3)
		"watch_banner":
			_line(site, "Standard", [Vector2(-82, 0), Vector2(-82, -155), Vector2(110, -155)], tone.lightened(0.15), 5)
			_poly(site, "Cloth", [Vector2(-75, -148), Vector2(105, -148), Vector2(105, -48), Vector2(70, -64), Vector2(22, -38), Vector2(-75, -64)], tone.darkened(0.3))
			_line(site, "WatchEye", [Vector2(-35, -101), Vector2(15, -129), Vector2(66, -101), Vector2(15, -82), Vector2(-35, -101)], tone.lightened(0.4), 3)


func _lights(site_index: int, values: Array) -> void:
	for i in range(values.size()):
		get_node("Site%d/Light%d" % [site_index, i]).color = Color(0.54, 0.96, 0.70) if values[i] else tone.darkened(0.55)


func _status(index: int, status: String) -> void:
	get_node("Site%d/RouteClue" % index).text = String(_sites()[index][3]) + "\n" + String(_sites()[index][4]) + "\n" + status


func _refresh_ash() -> void:
	var state := get_node("/root/GameState")
	var flags: Dictionary = state.unlocked_shortcuts
	var prefix := "ash_" + region + "_"
	var complete := bool(flags.get(prefix + "field_complete", false))
	var guarded := bool(flags.get(prefix + "guarded_niche_cleared", false))
	var returned := bool(flags.get(prefix + "field_return_complete", false))
	var advice := ""
	var ops := expansion.get_node_or_null("FieldOperations")
	match region:
		"forge":
			var winch := bool(flags.get("ash_forge_service_winch", false))
			var gear := bool(flags.get("ash_forge_service_gearbox", false))
			var fan := bool(flags.get("ash_forge_fan", false))
			_lights(1, [winch, gear, fan])
			_status(1, "HOIST READY" if complete else "SERVICE REQUIREMENTS %d/3" % (int(winch) + int(gear) + int(fan)))
			for i in range(4):
				get_node("Site3/Blade%d" % i).modulate = Color(1.6, 1.8, 1.4) if fan else Color.WHITE
			_status(3, "COOLING FAN ACTIVE" if fan else "COOLING FAN OFFLINE")
			advice = "Service repairs: %d/2. The cooling fan is %s. All three are needed for the service hoist." % [int(winch) + int(gear), "active" if fan else "still offline"]
		"barracks":
			var values: Array = []
			var count := 0
			for i in range(4):
				var done := bool(flags.get("ash_barracks_drill_%d" % i, false))
				values.append(done)
				count += int(done)
			var waves := bool(flags.get("ash_barracks_cleared", false))
			values.append(waves)
			_lights(1, values)
			_status(1, "TARGETS %d/4 | BEACON WAVES: %s" % [count, "DONE" if waves else "PENDING"])
			advice = "Marked targets: %d/4. The beacon waves are %s. Ordinary supply crates do not count as drill targets." % [count, "complete" if waves else "still pending"]
		"reservoir":
			var lower := bool(flags.get("ash_reservoir_lower", false))
			var upper := bool(flags.get("ash_reservoir_upper", false))
			var calibrated := bool(flags.get("ash_reservoir_calibrated", false))
			var sequence: Array = ops.sequence if ops != null else []
			_lights(1, [lower, upper])
			_lights(3, [calibrated or sequence.has(1), calibrated or sequence.has(0), calibrated or sequence.has(2)])
			_status(1, "COOLANT BANKS %d/2" % (int(lower) + int(upper)))
			_status(3, "CALIBRATED" if calibrated else "SEQUENCE %d/3 - UNFINISHED STEPS RESET ON LOAD" % sequence.size())
			advice = "Coolant valves: %d/2. Calibration: %d/3. Open both valves, then set return, intake, exhaust. Unfinished calibration resets on load." % [int(lower) + int(upper), 3 if calibrated else sequence.size()]
		"outskirts":
			var lower := bool(flags.get("ash_outskirts_report_0", false))
			var upper := bool(flags.get("ash_outskirts_report_1", false))
			_lights(0, [lower, upper])
			_status(0, "REPORTS COLLECTED %d/2" % (int(lower) + int(upper)))
			advice = "Watch reports: %d/2. Defeat each watch's own patrol, then collect its report at the post. These are not the town gatekeeper's targets." % (int(lower) + int(upper))
	var reserve := get_node("Site6")
	reserve.get_node("FieldSeal").modulate = Color(0.4, 1, 0.55) if complete else Color.WHITE
	reserve.get_node("GuardianSeal").modulate = Color(0.4, 1, 0.55) if guarded else Color.WHITE
	reserve.get_node("ReserveLatch").modulate = Color(0.4, 1, 0.55) if complete and guarded else Color.WHITE
	_status(6, "TASK: %s | UPPER GUARDIANS: %s" % ["DONE" if complete else "PENDING", "DONE" if guarded else "PENDING"])
	if returned:
		advice = "The returning guardians are quiet. Their reserve and the original upper cache are separate, one-time finds. Save at a lamp."
	elif complete and guarded:
		advice = "The upper reserve is unsealed. " + ("The final gallery's return trial is now awake." if state.get_zone_tier("ashen_bastion") >= 1 else "After the Castellan falls, revisit the final gallery for the return trial.")
	elif complete:
		advice = "The field task is complete. Defeat both upper-niche guardians before claiming the reserve or attempting the awakened return trial."
	var guide := get_node_or_null("FieldGuide")
	if guide != null:
		guide.dialogue_lines = PackedStringArray([advice, "This shelter is not a safe zone or checkpoint. Leave resting grazers alone for a quieter passage.", "The upper cache and final-gallery return reserve are separate. Rest at a lamp to keep your finds."])
		guide.next_line_index = 0
	if region == "outskirts" and ops != null:
		for i in range(2):
			var scout := ops.get_node("WatchScout%d" % i)
			scout.dialogue_lines = PackedStringArray([advice, "Rell holds the lower side watch; Sera holds the upper one. Return to Hearth's field board to review your discoveries."])
			scout.next_line_index = 0
