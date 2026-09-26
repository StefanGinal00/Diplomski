@tool
extends "res://RouteFieldDressing.gd"

# Local field scenes for the ordinary Shaft rooms. Existing exploration
# residents and encounters remain the only guide/reward owners.
# Full IDs distinguish the pressure gallery from the base class's Echo Gallery.
const ROUTE_SITES := {
	"shaft_gallery": [
		[0, 0.58, "pressure_lower", "LOWER PRESSURE MAIN", "THE LOWER CONTROL QUIETS THE FIRST FOUR JETS"],
		[1, 0.32, "pump", "PIPE TENDER'S STORES", "PELL'S SHELTER IS IN THE SIDE MAINTENANCE CUTTING"],
		[2, 0.18, "garden", "CONDENSATION FERN BED", "THE GRAZER RESTS BETWEEN THE PRESSURE BANKS"],
		[3, 0.42, "pressure_upper", "UPPER PRESSURE MAIN", "BOTH CONTROLS ARE NEEDED FOR THE WARDEN SHORTCUT"],
		[4, 0.36, "cache_board", "MAINTENANCE RESERVE", "CLIMB THE HIGH NICHE AND DEFEAT ITS TWO GUARDIANS"],
		[5, 0.60, "haul", "PIPE REPAIR CARGO", "RETURN TO THE LOW SIDE BRANCH AFTER THE WARDEN FALLS"],
		[6, 0.45, "survey", "FINAL PRESSURE SURVEY", "THE RETURN LIFT IS A SHORTCUT, NOT A CHECKPOINT"],
	],
	"shaft_cistern": [
		[0, 0.52, "dial_guide", "THE PUMP KEEPER'S DIAGRAM", "PRESSURE ORDER: NEAR > HIGH > FAR"],
		[1, 0.34, "pool", "BLACKWATER REED POOL", "SELA WAITS IN THE SIDE GAUGE-KEEPER'S REFUGE"],
		[2, 0.60, "pump", "DRAINAGE STORES", "A WRONG DIAL RESETS THE UNFINISHED SEQUENCE"],
		[3, 0.46, "tank", "PRESSURE RESERVOIR WINDOW", "COMPLETE THE PUMP SEQUENCE TO CALM THE PRESSURE CELLS"],
		[4, 0.38, "cache_board", "OVERFLOW RESERVE", "THIS GUARDED NICHE IS SEPARATE FROM THE PUMP REWARD"],
		[5, 0.60, "haul", "SUNKEN MAINTENANCE CARGO", "AFTER THE WARDEN, CHECK THE LOW OVERFLOW BRANCH"],
		[6, 0.44, "garden", "SILT FERN SANCTUARY", "RESTING GRAZERS ARE NEUTRAL UNLESS STRUCK"],
	],
	"shaft_approach": [
		[0, 0.50, "watch_rack", "THE ABANDONED WATCH", "USE THE EXISTING LOW BARRICADES AGAINST SENTRIES"],
		[1, 0.32, "haul", "WATCH SUPPLY CART", "BRAM'S SHELTER IS IN THE FIRST SIDE CUTTING"],
		[2, 0.58, "garden", "QUIET WATCH GARDEN", "A RESTING GRAZER IS NOT AN ENEMY PATROL"],
		[3, 0.42, "counterweight", "COUNTERWEIGHT INDICATOR", "THE FAR CRANK LOWERS THE ORIGINAL RETURN BRIDGE"],
		[4, 0.36, "cache_board", "SEALED WATCH RESERVE", "HIGH-NICHE GUARDIANS ARE NOT THE WARDEN"],
		[5, 0.58, "survey", "THE LAST WATCH RECORD", "AFTER THE WARDEN, RETURN TO THE LOW WATCH BRANCH"],
		[6, 0.44, "memorial", "NAMES OF THE OLD WATCH", "SAVE AT A LAMP BEFORE ENTERING THE WARDEN'S ARENA"],
	],
	"hollow": [
		[0, 0.54, "relay_board", "THE OLD SIGNAL LINE", "CLEAR THE HOLLOW GUARDIAN WISPS, THEN ACTIVATE THE RELAY"],
		[1, 0.30, "haul", "ORE SORTING BAY", "THE SURVEYOR'S SHELTER IS IN THIS TIER'S SIDE CUTTING"],
		[2, 0.58, "garden", "LANTERN MOSS BEDS", "GRAZERS ARE NEUTRAL; WATCH THE CEILING FOR FALLING STONE"],
		[3, 0.58, "haul", "ABANDONED HAULAGE", "THE TRACKS LEAD PAST THE SEALED ORE FACE"],
		[4, 0.38, "cache_board", "ORE RESERVE MARKER", "THE TWO-GUARDIAN CACHE IS IN THE HIGH NICHE"],
		[5, 0.38, "pool", "SILENT ORE SEEP", "THE LOW SIDE CUTTING WAKES AFTER THE WARDEN FALLS"],
		[6, 0.55, "survey", "DEEP SHAFT SURVEY", "RELEASE THE RETURN LIFT FROM BELOW TO SHORTEN BACKTRACKING"],
	],
	"crossing": [
		[0, 0.56, "moor", "THE DRY MOORING", "RAISED BYPASSES LEAD ABOVE THE AQUEDUCT CURRENTS"],
		[1, 0.34, "haul", "AQUEDUCT SUPPLY LANDING", "NERA'S DRY CAMP IS IN THIS TIER'S SIDE CHANNEL"],
		[2, 0.55, "water", "SLUICE OBSERVATION WINDOW", "THE SLUICE VALVE CALMS THE CROSSING'S CURRENTS"],
		[3, 0.62, "pool", "REED SHELTER", "THE RESTING GRAZERS NEED NOT BE FOUGHT"],
		[4, 0.36, "cache_board", "AQUEDUCT RESERVE MARKER", "CLIMB THE HIGH NICHE AND DEFEAT ITS TWO GUARDIANS"],
		[5, 0.48, "garden", "SEDIMENT GARDEN", "AFTER THE WARDEN, RETURN TO THE LOWEST SIDE CHANNEL"],
		[6, 0.58, "survey", "LOWER CHANNEL WAYSTONES", "THE RETURN LIFT IS A SHORTCUT, NOT A CHECKPOINT"],
	],
}
# Collision-free editor previews use these audited runtime floor positions.
const ROUTE_ANCHORS := {
	"shaft_gallery": [Vector2(922.2, 371), Vector2(1623.92, 731), Vector2(2487.82, 1091), Vector2(4254.84, 1451), Vector2(3266.5, 1091), Vector2(2245.5, 1811), Vector2(3397.3, 2171)],
	"shaft_cistern": [Vector2(1047.28, 391), Vector2(2238.72, 751), Vector2(4155.2, 1111), Vector2(3929, 751), Vector2(1662.5, 1471), Vector2(2204.8, 1916), Vector2(3485.28, 2191)],
	"shaft_approach": [Vector2(901, 441), Vector2(1903.76, 801), Vector2(3549.94, 1161), Vector2(4377.8, 801), Vector2(3430.16, 1521), Vector2(2440.12, 1966), Vector2(3514.96, 2241)],
	"hollow": [Vector2(1001.7, 321), Vector2(1923.9, 681), Vector2(3544, 1041), Vector2(4609.94, 1401), Vector2(3128.06, 1041), Vector2(1699.18, 1761), Vector2(3657, 2121)],
	"crossing": [Vector2(949.76, 351), Vector2(1848.64, 711), Vector2(1052.05, 1071), Vector2(2348.96, 1431), Vector2(3192.72, 1071), Vector2(4473.2, 1791), Vector2(3182.12, 2151)],
}


func _sites() -> Array:
	return ROUTE_SITES[region]


func _zone() -> String:
	return "sunken_shaft"


func _site_tone() -> Color:
	if region == "shaft_gallery":
		return Color(0.38, 0.68, 0.65)
	if region == "shaft_cistern":
		return Color(0.40, 0.62, 0.59)
	if region == "shaft_approach":
		return Color(0.60, 0.62, 0.69)
	return Color(0.35, 0.57, 0.45) if region == "hollow" else Color(0.30, 0.61, 0.72)


func _preview_anchors() -> Array:
	return ROUTE_ANCHORS[region]


func _site_anchor(index: int) -> Vector2:
	var data: Array = _sites()[index]
	var chamber: Rect2 = expansion._chamber_rect(data[0])
	var prefix := "Chamber%d_Floor" % data[0]
	if expansion.generated.has_node(prefix + "0"):
		return FLOOR.on_floor(expansion.generated, prefix, lerpf(chamber.position.x, chamber.end.x, data[1]), 9, 190)
	return _preview_anchors()[index]


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		var state := get_node_or_null("/root/GameState")
		if state != null:
			state.shortcut_changed.connect(_on_route_event)
		if region == "shaft_cistern":
			room.sequence_changed.connect(_refresh_route)
		_refresh_route()


func _build_site(index: int, data: Array, at: Vector2) -> void:
	super._build_site(index, data, at)
	var site := get_node("Site%d" % index)
	var clue := site.get_node("RouteClue") as Label
	clue.z_index = 3
	clue.add_theme_color_override("font_outline_color", Color(0.025, 0.045, 0.055, 0.95))
	clue.add_theme_constant_override("outline_size", 3)
	if data[2] == "tank":
		clue.position.y = -230
	match data[2]:
		"pressure_lower", "pressure_upper":
			_line(site, "MainPipe", [Vector2(-145, 0), Vector2(-145, -105), Vector2(140, -105), Vector2(140, 0)], tone.darkened(0.25), 14)
			_ring(site, "PressureGauge", Vector2(0, -105), 31, tone.lightened(0.4))
			_line(site, "Needle", [Vector2(0, -105), Vector2(20, -124)], Color(1, 0.7, 0.32), 4)
			_poly(site, "StatusLight", [Vector2(84, -75), Vector2(102, -75), Vector2(102, -57), Vector2(84, -57)], Color(1, 0.7, 0.32))
		"dial_guide":
			_line(site, "DiagramStand", [Vector2(-130, 0), Vector2(-130, -128), Vector2(130, -128), Vector2(130, 0)], tone, 6)
			for i in range(3):
				var x := -85.0 + i * 85
				_ring(site, "Dial%d" % i, Vector2(x, -82), 25, tone.lightened(0.3))
				_poly(site, "DialLight%d" % i, [Vector2(x - 12, -82), Vector2(x, -97), Vector2(x + 12, -82), Vector2(x, -67)], tone.darkened(0.3))
				var caption := Label.new()
				caption.name = "DialName%d" % i
				caption.position = Vector2(x - 37, -49)
				caption.size.x = 74
				caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				caption.text = ["1 NEAR", "2 HIGH", "3 FAR"][i]
				caption.add_theme_font_size_override("font_size", 11)
				site.add_child(caption)
		"tank":
			_poly(site, "TankShell", [Vector2(-140, 0), Vector2(-140, -135), Vector2(-95, -157), Vector2(95, -157), Vector2(140, -135), Vector2(140, 0)], tone.darkened(0.62))
			_poly(site, "Water", [Vector2(-118, -5), Vector2(-118, -122), Vector2(118, -122), Vector2(118, -5)], Color(0.2, 0.62, 0.62, 0.55))
			for i in range(4):
				var y := -28.0 - i * 28
				_line(site, "LevelMark%d" % i, [Vector2(105, y), Vector2(135, y)], tone.lightened(0.4), 3)
		"watch_rack":
			_line(site, "Rack", [Vector2(-125, 0), Vector2(-125, -120), Vector2(125, -120), Vector2(125, 0)], tone.darkened(0.2), 7)
			for i in range(3):
				var x := -75.0 + i * 75
				_poly(site, "Shield%d" % i, [Vector2(x - 24, -106), Vector2(x + 24, -106), Vector2(x + 20, -54), Vector2(x, -33), Vector2(x - 20, -54)], tone.darkened(0.4))
				_line(site, "Insignia%d" % i, [Vector2(x - 12, -84), Vector2(x + 12, -84), Vector2(x, -60), Vector2(x - 12, -84)], tone.lightened(0.5), 2)
		"counterweight":
			_line(site, "Gantry", [Vector2(-132, 0), Vector2(-132, -140), Vector2(132, -140), Vector2(132, 0)], tone.darkened(0.25), 7)
			_line(site, "Chain", [Vector2(-74, -130), Vector2(-74, -63)], tone, 3)
			_poly(site, "Weight", [Vector2(-104, -63), Vector2(-44, -63), Vector2(-44, -18), Vector2(-104, -18)], tone.lightened(0.15))
			_line(site, "BridgeDiagram", [Vector2(0, -25), Vector2(82, -105)], Color(1, 0.72, 0.38), 5)
		"memorial":
			for i in range(4):
				var x := -117.0 + i * 78
				_poly(site, "Tablet%d" % i, [Vector2(x - 28, 0), Vector2(x - 23, -94), Vector2(x, -109), Vector2(x + 23, -94), Vector2(x + 28, 0)], tone.darkened(0.48))
				for mark in range(3):
					var y := -70.0 + mark * 17
					_line(site, "Inscription%d_%d" % [i, mark], [Vector2(x - 12, y), Vector2(x + 12 - mark * 3, y)], tone.lightened(0.25), 2)
		"relay_board":
			_line(site, "SignalPosts", [Vector2(-118, 0), Vector2(-118, -125), Vector2(118, -125), Vector2(118, 0)], tone.darkened(0.3), 8)
			_ring(site, "SignalHousing", Vector2(0, -83), 36, tone.lightened(0.25))
			_poly(site, "RelayLight", [Vector2(-21, -83), Vector2(0, -109), Vector2(21, -83), Vector2(0, -57)], Color(0.3, 0.37, 0.4))
			_line(site, "Cable", [Vector2(-118, -110), Vector2(-53, -100), Vector2(-35, -83)], tone, 3)
		"water":
			_line(site, "ChannelFrame", [Vector2(-133, 0), Vector2(-133, -145), Vector2(133, -145), Vector2(133, 0)], tone.darkened(0.1), 7)
			_poly(site, "Water", [Vector2(-127, -4), Vector2(-127, -124), Vector2(127, -124), Vector2(127, -4)], Color(0.2, 0.61, 0.73, 0.45))
			for i in range(5):
				var x := -102.0 + i * 51
				_line(site, "Grate%d" % i, [Vector2(x, 0), Vector2(x, -141)], tone.darkened(0.3), 5)
		"cache_board":
			_poly(site, "Plaque", [Vector2(-109, 0), Vector2(-109, -132), Vector2(109, -132), Vector2(109, 0)], tone.darkened(0.58))
			_line(site, "ClimbArrow", [Vector2(-82, -50), Vector2(-82, -98), Vector2(-100, -80), Vector2(-82, -98), Vector2(-64, -80)], tone.lightened(0.6), 3)
			for guard in range(2):
				var x := -21.0 + guard * 67
				_ring(site, "GuardianSeal%d" % guard, Vector2(x, -77), 20, Color(0.97, 0.7, 0.37))
			_line(site, "ReserveSeal", [Vector2(-48, -30), Vector2(70, -30)], Color(0.8, 0.46, 0.27), 4)
		"moor":
			_poly(site, "Boat", [Vector2(-141, -44), Vector2(-103, -6), Vector2(90, -6), Vector2(142, -44)], tone.darkened(0.28))
			_line(site, "Oar", [Vector2(-83, -23), Vector2(86, -93)], tone.lightened(0.3), 6)
			_line(site, "Mooring", [Vector2(-155, 0), Vector2(-155, -80)], tone, 7)
			_line(site, "Rope", [Vector2(-155, -67), Vector2(-119, -55), Vector2(-95, -43)], tone.lightened(0.18), 3)


func _add_streamed(actor: Node2D, kind: String) -> void:
	if kind == "neutral":
		actor.creature_name = {"hollow": "Lantern Moss Grazer", "crossing": "Aqueduct Grazer", "shaft_gallery": "Condensation Grazer", "shaft_cistern": "Silt Reed Grazer", "shaft_approach": "Watch Garden Grazer"}[region]
	super._add_streamed(actor, kind)


func _on_route_event(event_id: String) -> void:
	if event_id.begins_with(_event_prefix()) or event_id == "shaft_sluice_valve":
		_refresh_route()


func _event_prefix() -> String:
	return (region if region.begins_with("shaft_") else "shaft_" + region) + "_"


func _refresh_route() -> void:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return
	_refresh_reserve(state)
	if region.begins_with("shaft_"):
		_refresh_deep_route(state)
		return
	var index := 0 if region == "hollow" else 2
	var site := get_node("Site%d" % index)
	var active := bool(state.unlocked_shortcuts.get("shaft_hollow_relay" if region == "hollow" else "shaft_sluice_valve", false))
	if region == "hollow":
		site.get_node("RelayLight").color = Color(0.47, 0.98, 0.71) if active else Color(0.3, 0.37, 0.4)
	else:
		site.get_node("Water").scale.y = 0.22 if active else 1.0
	var data: Array = _sites()[index]
	var status := ("RELAY ACTIVE - LOWER LINKS OPEN" if active else "RELAY NOT YET ACTIVATED") if region == "hollow" else ("SLUICE DRAINED - CURRENTS CALMED" if active else "SLUICE STILL FLOWING")
	site.get_node("RouteClue").text = String(data[3]) + "\n" + String(data[4]) + "\n" + status


func _refresh_reserve(state: Node) -> void:
	var cleared := bool(state.unlocked_shortcuts.get(_event_prefix() + "hidden_depth_cleared", false))
	var plaque := get_node("Site4")
	plaque.get_node("ReserveSeal").modulate = Color(0.4, 1, 0.6) if cleared else Color.WHITE
	for guard in range(2):
		plaque.get_node("GuardianSeal%d" % guard).visible = not cleared
	plaque.get_node("RouteClue").text = String(_sites()[4][3]) + "\n" + ("HIGH NICHE: GUARDIANS CLEARED, CACHE UNSEALED" if cleared else "HIGH NICHE: DEFEAT BOTH GUARDIANS FOR ITS CACHE")


func _refresh_deep_route(state: Node) -> void:
	if region == "shaft_gallery":
		for index in [0, 3]:
			var active := bool(state.unlocked_shortcuts.get("shaft_gallery_lower" if index == 0 else "shaft_gallery_upper", false))
			var site := get_node("Site%d" % index)
			site.get_node("Needle").points = PackedVector2Array([Vector2(0, -105), Vector2(-20, -116) if active else Vector2(20, -124)])
			site.get_node("StatusLight").color = Color(0.45, 1, 0.7) if active else Color(1, 0.7, 0.32)
			_status(index, "THIS BANK IS CALMED" if active else "THIS BANK IS PRESSURIZED")
	elif region == "shaft_cistern":
		var active := bool(state.unlocked_shortcuts.get("shaft_cistern_pump", false))
		# Unfinished dial progress is deliberately transient, like the puzzle.
		var progress: int = 3 if active else int(room.puzzle_progress)
		for index in range(3):
			get_node("Site0/DialLight%d" % index).color = Color(0.45, 1, 0.7) if index < progress else tone.darkened(0.3)
		get_node("Site3/Water").scale.y = 0.2 if active else 1.0
		_status(0, "PUMP ACTIVE - GALLERY PASSAGE OPEN" if active else "SEQUENCE %d/3 - UNFINISHED DIALS RESET ON LOAD" % progress)
		_status(3, "PRESSURE CELLS CALMED" if active else "PRESSURE CELLS STILL ACTIVE")
	else:
		var active := bool(state.unlocked_shortcuts.get("shaft_approach_bridge", false))
		get_node("Site3/Weight").position.y = -45 if active else 0
		get_node("Site3/BridgeDiagram").points = PackedVector2Array([Vector2(0, -25), Vector2(82, -25) if active else Vector2(82, -105)])
		_status(3, "ORIGINAL RETURN BRIDGE LOWERED" if active else "FAR COUNTERWEIGHT NOT RELEASED")


func _status(index: int, status: String) -> void:
	get_node("Site%d/RouteClue" % index).text = String(_sites()[index][3]) + "\n" + String(_sites()[index][4]) + "\n" + status
