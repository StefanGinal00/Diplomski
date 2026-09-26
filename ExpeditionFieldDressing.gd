@tool
extends "res://RouteFieldDressing.gd"

# Expedition-specific landmarks observe the existing operations. They neither
# finish objectives nor spawn extra reward encounters or change collision.
const LOCAL_SITES := {
	"drift": [
		[0, 0.72, "survey", "THE ENGINEER'S SURVEY", "TOVA NEAR THE ENTRANCE CAN EXPLAIN THE TWO PUMPS"],
		[1, 0.65, "pump_board", "DRIFTWORKS PRESSURE REGISTER", "INTAKE: WESTERN LOW BRANCH; CROWN: FAR EASTERN UPPER BRANCH"],
		[2, 0.22, "haul", "THE LOST ORE CONSIGNMENT", "SUPPLY CRATES MAY BE EMPTY; SERVICE RESERVES ARE SEPARATE"],
		[3, 0.54, "manifold", "THE DIVIDED PRESSURE MAIN", "EACH REPAIRED PUMP QUIETS ITS OWN PRESSURE LEAK"],
		[4, 0.57, "pool", "TURBINE MOSS POOL", "GRAZERS ARE NEUTRAL UNLESS STRUCK"],
		[5, 0.22, "flywheel", "THE CROWN FLYWHEEL", "BOTH PUMPS UNSEAL THE ENGINEER RESERVE BESIDE THE CROWN PUMP"],
		[6, 0.76, "pump", "UPPER ENGINE SPARES", "THE NORTHWESTERN ENGINE BRANCH HOLDS THE AWAKENED TRIAL"],
		[7, 0.70, "return_board", "THE RESTARTED ENGINE", "AFTER THE WARDEN, REVISIT THE NORTHWESTERN ENGINE BRANCH"],
	],
	"depths": [
		[7, 0.72, "reading", "THE EXPEDITION'S LISTENER", "THE SIGNALS ARE RECORDS, NOT A CHOIR SEQUENCE"],
		[1, 0.24, "signal_board", "THE TWO DISTANT VOICES", "RECORD BOTH SIGNALS IN THE WESTERN AND EASTERN SIDE BRANCHES"],
		[2, 0.73, "haul", "THE ABANDONED SOUND CART", "MARKED SIGNALS COUNT; ORDINARY CRATES ARE ONLY SUPPLIES"],
		[3, 0.43, "tuning_forks", "THE ANSWERING GALLERY", "EITHER SIGNAL CAN BE RECORDED FIRST; CLEAR NEARBY FOES"],
		[4, 0.70, "pool", "STILL ECHO POOL", "A RESTING GRAZER IS NOT AN EXPEDITION GUARD"],
		[5, 0.24, "signal_lens", "THE MEMORY BASIN LENS", "BOTH SIGNALS UNSEAL THE CACHE IN THE DEEPEST SIDE BRANCH"],
		[6, 0.76, "stacks", "WATER-STAINED FIELD BOOKS", "THE RETURN TRIAL IS IN THE RAISED PRISM RISE BRANCH"],
		[0, 0.70, "return_board", "THE EXPEDITION'S ECHO", "AFTER THE MATRIARCH, REVISIT THE RAISED PRISM RISE BRANCH"],
	],
	"emberspine": [
		[7, 0.80, "camp", "THE COOLING SPINE TENDER", "THIS SHELTER IS NOT A SAFE ZONE OR CHECKPOINT"],
		[1, 0.24, "cooling_board", "THE TWO COOLANT FEEDS", "OPEN INTAKE AND DEEP COOLING IN THEIR SEPARATE SIDE BRANCHES"],
		[2, 0.73, "haul", "KILN DELIVERY CART", "ORDINARY SUPPLIES DO NOT REPLACE THE DEEP RESERVE"],
		[3, 0.41, "garden", "COOLING SPINE REEDS", "NEUTRAL CREATURES NEED NOT BE FOUGHT"],
		[4, 0.76, "kiln", "THE COOLED FURNACE", "EACH FEED STOPS ONE FIRE LANE; THE DEEP GUARD IS SEPARATE"],
		[5, 0.23, "pump", "COOLANT PIPE STORES", "BOTH FEEDS AND THE DEEPEST BRANCH GUARD UNSEAL THE RIM CACHE"],
		[6, 0.74, "survey", "THE TENDER'S WAYSTONES", "RETURN TO EMBER HEART FOR THE AWAKENED WATCH"],
		[7, 0.25, "return_board", "THE COOLED HEART'S WATCH", "AFTER THE CASTELLAN, REVISIT EMBER HEART"],
	],
}
const PROFILES := {
	"drift": {"events": ["shaft_drift_pumps_a", "shaft_drift_pumps_b"], "complete": "shaft_drift_pumps_complete", "guard": "", "returned": "shaft_drift_pumps_trial_complete", "labels": ["INTAKE", "CROWN"], "guide": "", "fauna": "Turbine Moss Grazer", "destination": "NORTHWESTERN ENGINE BRANCH"},
	"depths": {"events": ["echo_depths_field_station_0", "echo_depths_field_station_1"], "complete": "echo_depths_field_complete", "guard": "", "returned": "echo_depths_field_return_complete", "labels": ["WEST", "EAST"], "guide": "Aven, Expedition Listener", "fauna": "Stillwater Grazer", "destination": "RAISED PRISM RISE BRANCH"},
	"emberspine": {"events": ["ash_emberspine_cooling_0", "ash_emberspine_cooling_1"], "complete": "ash_emberspine_field_complete", "guard": "ash_emberspine_guarded_niche_cleared", "returned": "ash_emberspine_field_return_complete", "labels": ["INTAKE", "DEEP"], "guide": "Rovan, Spine Tender", "fauna": "Cooling Reed Grazer", "destination": "EMBER HEART"},
}
# Physics-free world-editor previews use audited runtime anchors. The dressing
# regression checks these against real floor spans after terrain changes.
const PREVIEW_POINTS := {
	"drift": [Vector2(1575.792, 671), Vector2(2569.6, 1071), Vector2(3000.5, 1471), Vector2(4841.748, 1071), Vector2(6209.976, 671), Vector2(4420.972, 271), Vector2(4016.9, -129), Vector2(2033.28, 271)],
	"depths": [Vector2(1479.744, 2711), Vector2(1905.464, 1071), Vector2(4115.7, 711), Vector2(5298.012, 1111), Vector2(6877.58, 1511), Vector2(4398.7, 1911), Vector2(3643.576, 2311), Vector2(1363.2, 671)],
	"emberspine": [Vector2(4221.84, 1871), Vector2(2596.288, 271), Vector2(5419, 671), Vector2(5993.864, 1071), Vector2(5103.544, 1471), Vector2(1886.904, 1071), Vector2(1218.7, 1471), Vector2(2207.85, 1871)],
}


func _sites() -> Array:
	return LOCAL_SITES[region]


func _room_root() -> Node2D:
	return expansion


func _zone() -> String:
	return String(expansion.route["zone"])


func _site_tone() -> Color:
	return (expansion.route["color"] as Color).lightened(0.22)


func _site_anchor(index: int) -> Vector2:
	var data: Array = _sites()[index]
	var chamber: Rect2 = expansion._main_rect(data[0])
	var prefix := "MainRoom%dFloor" % data[0]
	if expansion.has_node(prefix + "0"):
		return FLOOR.on_floor(expansion, prefix, lerpf(chamber.position.x, chamber.end.x, data[1]), 9, 190)
	if PREVIEW_POINTS.has(region):
		return PREVIEW_POINTS[region][index]
	return Vector2(lerpf(chamber.position.x, chamber.end.x, data[1]), chamber.end.y - 9)


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		var state := get_node("/root/GameState")
		state.shortcut_changed.connect(_on_progress)
		state.zone_tier_changed.connect(_on_tier)
		_refresh()


func _build_site(index: int, data: Array, at: Vector2) -> void:
	super._build_site(index, data, at)
	var site := get_node("Site%d" % index)
	site.z_index = 0
	var clue := site.get_node("RouteClue") as Label
	clue.z_index = 3
	clue.size.y = 80
	if index in [1, 7]:
		clue.position.y = -232
	clue.add_theme_constant_override("outline_size", 4)
	clue.add_theme_color_override("font_outline_color", Color(0.025, 0.03, 0.045))
	match data[2]:
		"pump_board", "signal_board", "cooling_board":
			_line(site, "Support", [Vector2(-134, 0), Vector2(-134, -142), Vector2(134, -142), Vector2(134, 0)], tone.darkened(0.25), 8)
			for i in range(2):
				var x := -64.0 + i * 128
				if region == "depths":
					_ring(site, "SignalRing%d" % i, Vector2(x, -93), 38, tone)
					_poly(site, "Light%d" % i, [Vector2(x - 18, -93), Vector2(x, -122), Vector2(x + 18, -93), Vector2(x, -64)], tone.darkened(0.3))
				else:
					_line(site, "Feed%d" % i, [Vector2(x, -12), Vector2(x, -53)], tone, 9)
					_poly(site, "Light%d" % i, [Vector2(x - 28, -62), Vector2(x - 28, -123), Vector2(x + 28, -123), Vector2(x + 28, -62)], tone.darkened(0.3))
				var label := Label.new()
				label.position = Vector2(x - 55, -45)
				label.size.x = 110
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.add_theme_font_size_override("font_size", 11)
				label.text = PROFILES[region]["labels"][i]
				site.add_child(label)
		"manifold":
			for i in range(2):
				var y := -38.0 - i * 65
				_line(site, "Pipe%d" % i, [Vector2(-148, y), Vector2(-60, y), Vector2(0, y - 24), Vector2(67, y), Vector2(148, y)], tone.darkened(0.18), 13)
				_ring(site, "Valve%d" % i, Vector2(0, y - 24), 23, tone.lightened(0.15))
		"flywheel":
			_line(site, "Mount", [Vector2(-94, 0), Vector2(-40, -40), Vector2(40, -40), Vector2(94, 0)], tone, 9)
			_ring(site, "Wheel", Vector2(0, -94), 60, tone)
			for i in range(6):
				_line(site, "Spoke%d" % i, [Vector2(0, -94), Vector2(0, -94) + Vector2.from_angle(TAU * i / 6.0) * 56], tone.darkened(0.2), 6)
		"tuning_forks":
			for i in range(3):
				var x := -92.0 + i * 92
				_line(site, "Fork%d" % i, [Vector2(x - 24, -146 + i * 15), Vector2(x - 24, -60), Vector2(x + 24, -60), Vector2(x + 24, -146 + i * 15)], tone.lightened(0.15), 7)
				_line(site, "Stem%d" % i, [Vector2(x, -60), Vector2(x, 0)], tone, 7)
		"signal_lens":
			_ring(site, "OuterLens", Vector2(0, -93), 63, tone)
			_line(site, "LensStand", [Vector2(-85, 0), Vector2(0, -32), Vector2(85, 0)], tone, 8)
			for i in range(2):
				var x := -34.0 + i * 68
				_poly(site, "LensLight%d" % i, [Vector2(x - 18, -92), Vector2(x, -120), Vector2(x + 18, -92), Vector2(x, -65)], tone.darkened(0.3))
		"kiln":
			_poly(site, "KilnShell", [Vector2(-136, 0), Vector2(-136, -85), Vector2(-80, -150), Vector2(80, -150), Vector2(136, -85), Vector2(136, 0)], tone.darkened(0.35))
			for i in range(2):
				var x := -62.0 + i * 124
				_poly(site, "KilnWindow%d" % i, [Vector2(x - 30, -22), Vector2(x - 30, -89), Vector2(x + 30, -89), Vector2(x + 30, -22)], Color(0.95, 0.4, 0.15))
		"return_board":
			_poly(site, "ReturnStone", [Vector2(-142, 0), Vector2(-127, -128), Vector2(127, -128), Vector2(142, 0)], tone.darkened(0.55))
			_ring(site, "TaskSeal", Vector2(-65, -70), 24, tone)
			_ring(site, "ReturnSeal", Vector2(65, -70), 24, tone)
			_line(site, "ReturnTrace", [Vector2(-82, -26), Vector2(82, -26)], tone, 5)


func _build_resident(at: Vector2) -> void:
	for side in [-1, 1]:
		var marker := Marker2D.new()
		marker.name = "CampStop%d" % side
		marker.position = at + Vector2(side * 28, -24)
		add_child(marker)
	var npc := RESIDENT.instantiate()
	npc.name = "FieldGuide"
	npc.position = at + Vector2(-28, -24)
	npc.resident_name = PROFILES[region]["guide"]
	npc.coat_color = tone.darkened(0.3)
	npc.walk_speed = 16
	npc.route_marker_names = PackedStringArray(["CampStop-1", "CampStop1"])
	npc.victory_dialogue_lines = PackedStringArray()
	add_child(npc)
	var label := npc.get_node("NameLabel") as Label
	label.position = Vector2(-140, -70)
	label.size.x = 280
	label.z_index = 2
	label.add_theme_constant_override("outline_size", 4)


func _add_streamed(actor: Node2D, kind: String) -> void:
	if kind == "neutral":
		actor.creature_name = PROFILES[region]["fauna"]
	super._add_streamed(actor, kind)


func activate_room_population() -> void:
	super.activate_room_population()
	if not Engine.is_editor_hint():
		_refresh()


func _on_progress(_event: String) -> void:
	_refresh()


func _on_tier(zone: String, _tier: int) -> void:
	if zone == _zone():
		_refresh()


func _refresh() -> void:
	var state := get_node("/root/GameState")
	var flags: Dictionary = state.unlocked_shortcuts
	var profile: Dictionary = PROFILES[region]
	var count := 0
	for i in range(2):
		var active := bool(flags.get(profile["events"][i], false))
		count += int(active)
		var color := Color(0.5, 0.93, 0.75) if active else tone.darkened(0.3)
		get_node("Site1/Light%d" % i).color = color
		if region == "drift":
			get_node("Site3/Valve%d" % i).default_color = color
		elif region == "depths":
			get_node("Site5/LensLight%d" % i).color = color
		else:
			get_node("Site4/KilnWindow%d" % i).color = Color(0.33, 0.54, 0.58) if active else Color(0.95, 0.4, 0.15)
	if region == "drift":
		get_node("Site5/Wheel").default_color = tone.lightened(0.5) if flags.get(profile["events"][1], false) else tone
	get_node("Site1/RouteClue").text = String(_sites()[1][3]) + "\n" + String(_sites()[1][4]) + "\nRECORDED %d/2" % count
	var complete := bool(flags.get(profile["complete"], false))
	var guarded := String(profile["guard"]).is_empty() or bool(flags.get(profile["guard"], false))
	var returned := bool(flags.get(profile["returned"], false))
	var awake := int(state.get_zone_tier(_zone())) >= 1
	var status := "AWAKENED RETURN: DORMANT"
	if returned:
		status = "RETURN CLEARED - THE WATCH IS QUIET"
	elif awake:
		status = "AWAKENED RETURN: READY" if complete and guarded else "AWAKENED RETURN: FINISH LOCAL REQUIREMENTS"
	var detail := "TASK: " + ("DONE" if complete else "PENDING")
	if region == "emberspine":
		detail += " | DEEP GUARD: " + ("DONE" if guarded else "PENDING")
	get_node("Site7/TaskSeal").modulate = Color(0.5, 1, 0.65) if complete else Color.WHITE
	get_node("Site7/ReturnSeal").modulate = Color(0.5, 1, 0.65) if returned else Color.WHITE
	get_node("Site7/ReturnTrace").modulate = Color(0.5, 1, 0.65) if complete and guarded else Color.WHITE
	get_node("Site7/RouteClue").text = String(_sites()[7][3]) + "\n" + detail + "\n" + status + "\n" + profile["destination"]
	var guide := get_node_or_null("FieldGuide")
	if guide != null:
		guide.dialogue_lines = PackedStringArray([
			"Recorded %d/2. %s" % [count, String(_sites()[1][4]).capitalize()],
			"Both coolant feeds and the deep branch guard unseal the Rim Cache." if region == "emberspine" else "Both signals unseal the cache in the deepest side branch. They can be recorded in either order.",
			status.capitalize() + ". Return destination: " + String(profile["destination"]).capitalize() + ". Save discoveries at a lamp.",
		])
