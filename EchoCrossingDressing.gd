@tool
extends "res://RouteFieldDressing.gd"

# Scenery and advice read the existing bridge/drain/seal flags. The original
# controls own gameplay, rewards and saves; this layer never grants progress.
const CROSSINGS := {
	"causeway": [
		[0, 0.55, "camp", "THE BRIDGE MENDER'S POST", "SIDE ANCHORS STABILIZE THE EXPANDED CROSSING"],
		[1, 0.30, "tether", "WESTERN TETHER ARRAY", "CLIMB THE SIDE BRANCH TO THE WEST BRIDGE ANCHOR"],
		[2, 0.55, "haul", "FRACTURED CRYSTAL CARGO", "BREAKABLE SUPPLIES MAY BE EMPTY"],
		[3, 0.50, "survey", "THE SURVEYOR'S LEDGE", "THE TIDE LOOP STILL NEEDS ITS SEPARATE MAIN ANCHOR"],
		[4, 0.50, "garden", "SHARD FERN GARDEN", "RESTING GRAZERS NEED NOT BE FOUGHT"],
		[5, 0.35, "tether", "EASTERN TETHER ARRAY", "THE OTHER SIDE ANCHOR STABILIZES THE SECOND BRIDGE PAIR"],
		[6, 0.48, "pool", "STILL CRYSTAL BASIN", "RETURN TRIAL: NEARBY SIDE ALCOVE, AFTER AWAKENING"],
		[7, 0.60, "haul", "PHASEWALKER'S DELIVERY", "THE DISCOVERY SATCHEL WAITS IN THIS HIGH SIDE BRANCH"],
		[8, 0.48, "survey", "CROSSING OVERLOOK", "USE THE END DOOR TO RETURN TO THIS ROOM'S ENTRANCE"],
	],
	"vault": [
		[0, 0.56, "camp", "THE RESERVOIR WATCH", "DRAINS CALM CURRENTS; SEALS RELEASE THE RELIQUARY"],
		[1, 0.30, "drain", "INTAKE CHANNEL WINDOW", "CLIMB THE RAISED SIDE BRANCH TO THE INTAKE DRAIN"],
		[2, 0.60, "haul", "WATERLOGGED STORES", "OLD SUPPLY CRATES MAY CONTAIN NOTHING"],
		[3, 0.55, "seal_board", "RESERVOIR STATUS TABLE", "THE DISCOVERY CACHE NEEDS TWO DRAINS AND TWO SEALS"],
		[4, 0.60, "garden", "SALT FERN FILTER", "THE GREEN POCKET IS NOT A SAFE ZONE OR HEALING SPRING"],
		[5, 0.30, "drain", "OUTLET CHANNEL WINDOW", "FIND THE SECOND DRAIN IN THE RAISED SIDE BRANCH"],
		[6, 0.50, "pump", "RESERVOIR MAINTENANCE", "THE RESERVOIR WATCH RETURNS IN THE NEARBY SIDE ALCOVE"],
		[7, 0.48, "archive", "DRY RESERVE WAYSTONES", "THE FIELD DISCOVERY CACHE WAITS IN THE HIGH SIDE BRANCH"],
		[8, 0.60, "pool", "RELIQUARY BASIN", "THE ORIGINAL RELIQUARY AND FIELD CACHE ARE SEPARATE REWARDS"],
	],
}
const CROSSING_ANCHORS := {
	"causeway": [Vector2(1662.3, 381), Vector2(2472, 21), Vector2(3635.7, -339), Vector2(3168.25, -807), Vector2(2776.5, -339), Vector2(1908.15, -699), Vector2(1327.68, -1059), Vector2(2246.4, -1419), Vector2(3276, -1059)],
	"vault": [Vector2(1744.12, 401), Vector2(2456.75, 41), Vector2(3609.4, -319), Vector2(4081.5, -679), Vector2(3261.25, -1039), Vector2(2222.25, -1399), Vector2(1569.25, -1039), Vector2(2329.7, -1759), Vector2(3683.1, -2119)],
}


func _sites() -> Array:
	return CROSSINGS[region]


func _preview_anchors() -> Array:
	return CROSSING_ANCHORS[region]


func _site_tone() -> Color:
	return Color(0.34, 0.73, 0.82) if region == "causeway" else Color(0.29, 0.57, 0.65)


func _site_margin(index: int) -> float:
	return 125 if _sites()[index][2] in ["archive", "survey"] else 190


func _site_anchor(index: int) -> Vector2:
	if region == "causeway" and index == 3:
		# The fractured main shelf has a short patrol, not room for a display.
		var shelf := expansion.get_node_or_null("Tier03HiddenShelfA") as Node2D
		if shelf != null:
			return FLOOR.on_floor(expansion, String(shelf.name), shelf.position.x, 9, 100)
		assert(Engine.is_editor_hint(), "Missing Causeway survey shelf")
		return _preview_anchors()[index]
	return super._site_anchor(index)


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.shortcut_changed.connect(_on_crossing_event)
		state.zone_tier_changed.connect(_on_crossing_tier)
	_refresh_crossing()


func _build_site(index: int, data: Array, at: Vector2) -> void:
	super._build_site(index, data, at)
	var site := get_node("Site%d" % index)
	match data[2]:
		"tether":
			for side in [-1, 1]:
				var x: float = side * 113.0
				_poly(site, "AnchorPylon%d" % side, [Vector2(x - 18, 0), Vector2(x - 18, -97), Vector2(x, -131), Vector2(x + 18, -97), Vector2(x + 18, 0)], tone.darkened(0.23))
				_ring(site, "TetherRing%d" % side, Vector2(x, -83), 22, tone.lightened(0.4))
			_line(site, "BrokenTether", [Vector2(-113, -83), Vector2(-46, -63), Vector2(-21, -99), Vector2(0, -48)], tone.lightened(0.15), 5)
			# A sagging cable reads as scenery, not another walkable platform.
			_line(site, "StableTether", [Vector2(-113, -83), Vector2(-63, -55), Vector2(0, -46), Vector2(63, -55), Vector2(113, -83)], Color(0.46, 0.98, 0.83), 3)
			site.get_node("StableTether").hide()
		"drain":
			_line(site, "WindowFrame", [Vector2(-135, 0), Vector2(-135, -145), Vector2(135, -145), Vector2(135, 0)], tone.lightened(0.2), 8)
			_poly(site, "ChannelWater", [Vector2(-128, -5), Vector2(-128, -125), Vector2(128, -125), Vector2(128, -5)], Color(0.18, 0.62, 0.79, 0.48))
			for bar in range(5):
				var x := -100.0 + bar * 50
				_line(site, "Grate%d" % bar, [Vector2(x, -5), Vector2(x, -143)], tone.darkened(0.25), 6)
			_line(site, "Waterline", [Vector2(-125, -125), Vector2(125, -125)], tone.lightened(0.5), 3)
		"seal_board":
			_line(site, "TableFrame", [Vector2(-140, 0), Vector2(-140, -134), Vector2(140, -134), Vector2(140, 0)], tone.darkened(0.2), 7)
			for lamp in range(4):
				var x := -102.0 + lamp * 68
				_poly(site, "StatusLamp%d" % lamp, [Vector2(x - 19, -48), Vector2(x - 19, -98), Vector2(x + 19, -98), Vector2(x + 19, -48)], Color(0.25, 0.3, 0.4))
				var label := Label.new()
				label.name = "StatusName%d" % lamp
				label.position = Vector2(x - 32, -37)
				label.size = Vector2(64, 18)
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.text = ["IN", "OUT", "UPPER", "FAR"][lamp]
				label.add_theme_font_size_override("font_size", 10)
				site.add_child(label)
		"camp":
			site.get_node("RouteClue").position.y = -188
			if region == "causeway":
				_line(site, "SurveyTripod", [Vector2(-149, 0), Vector2(-123, -107), Vector2(-98, 0)], tone, 4)
				_line(site, "SurveyScope", [Vector2(-156, -107), Vector2(-98, -121)], tone.lightened(0.4), 10)
			else:
				_line(site, "DivingRack", [Vector2(-151, 0), Vector2(-151, -125), Vector2(-111, -125), Vector2(-111, 0)], tone, 5)
				_ring(site, "DivingHelmet", Vector2(-131, -92), 18, tone.lightened(0.45))


func activate_room_population() -> void:
	super.activate_room_population()
	if not Engine.is_editor_hint():
		_refresh_crossing()


func _add_streamed(actor: Node2D, kind: String) -> void:
	if region == "causeway" and actor.name == "Supply3_0":
		# Keep the small survey supply inward on its 212px branch shelf.
		actor.position.x += 40
	if kind == "neutral":
		actor.creature_name = "Shard Fern Grazer" if region == "causeway" else "Saltwater Grazer"
	super._add_streamed(actor, kind)


func _build_resident(at: Vector2) -> void:
	super._build_resident(at)
	var guide := get_node("FieldGuide")
	guide.resident_name = "Taren, Bridge Mender" if region == "causeway" else "Odel, Reservoir Keeper"
	guide.name_label.text = guide.resident_name
	guide.coat_color = tone.darkened(0.2)
	guide.coat.color = guide.coat_color
	guide.victory_dialogue_lines = PackedStringArray()


func _on_crossing_event(event_id: String) -> void:
	if event_id.begins_with("echo_%s_" % region):
		_refresh_crossing()


func _on_crossing_tier(zone: String, _tier: int) -> void:
	if zone == "echo_grotto":
		_refresh_crossing()


func _refresh_crossing() -> void:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return
	var progress: Array[bool] = []
	for station in range(2):
		var active := bool(state.unlocked_shortcuts.get("echo_%s_field_station_%d" % [region, station], false))
		progress.append(active)
		var index := 1 if station == 0 else 5
		var site := get_node("Site%d" % index)
		var status: String
		if region == "causeway":
			site.get_node("StableTether").visible = active
			site.get_node("BrokenTether").visible = not active
			status = "BRIDGE PAIR STABLE" if active else "BRIDGE PAIR STILL CYCLING"
		else:
			site.get_node("ChannelWater").scale.y = 0.25 if active else 1.0
			var y := -31.25 if active else -125.0
			site.get_node("Waterline").points = PackedVector2Array([Vector2(-125, y), Vector2(125, y)])
			status = "CHANNEL DRAINED" if active else "CHANNEL FLOWING"
		var data: Array = _sites()[index]
		site.get_node("RouteClue").text = String(data[3]) + "\n" + String(data[4]) + "\n" + status
	var station_count := int(progress[0]) + int(progress[1])
	var seal_count := 0
	if region == "vault":
		for flag in ["echo_vault_upper", "echo_vault_far"]:
			var active := bool(state.unlocked_shortcuts.get(flag, false))
			progress.append(active)
			seal_count += int(active)
		for index in range(4):
			get_node("Site3/StatusLamp%d" % index).color = Color(0.44, 0.98, 0.73) if progress[index] else Color(0.25, 0.3, 0.4)
		get_node("Site3/RouteClue").text = "RESERVOIR STATUS TABLE\nDRAINS %d/2 - SEALS %d/2\nBOTH PAIRS REQUIRED FOR THE FIELD DISCOVERY CACHE" % [station_count, seal_count]
	var guide := get_node_or_null("FieldGuide")
	if guide == null:
		return
	var complete := bool(state.unlocked_shortcuts.get("echo_%s_field_complete" % region, false))
	var returned := bool(state.unlocked_shortcuts.get("echo_%s_field_return_complete" % region, false))
	var lines: Array[String] = []
	if returned:
		lines.append("The return trial is quiet. Its reserve and the original discovery cache are separate one-time finds. Save your progress at a lamp.")
	elif complete and state.get_zone_tier("echo_grotto") >= 1:
		lines.append("Your field task is complete and the caves have awakened. Seek the return trial in the side alcove by the %s for a separate reserve." % ("still crystal basin" if region == "causeway" else "reservoir maintenance stores"))
	elif complete:
		lines.append("The discovery cache is unsealed in the high branch by the %s. Return after the Matriarch to face the separate awakened trial." % ("phasewalker's delivery" if region == "causeway" else "dry reserve waystones"))
	elif region == "causeway":
		lines.append("Side anchors ready: %d/2. Find the west and east controls in the raised side branches. Each stabilizes a different pair of bridges." % station_count)
		lines.append("The tether displays show the controls' state. They are not switches or solid bridges themselves.")
	else:
		lines.append("Drains ready: %d/2. Seals open: %d/2. Use both side drains and the original Upper and Far seals to unlock the field discovery cache." % [station_count, seal_count])
		lines.append("The original reliquary only needs the two seals. Drains calm currents; they do not replace the seals or stop every tidal surge.")
	if region == "causeway":
		lines.append("The main anchor has opened the Tide loop." if state.unlocked_shortcuts.get("echo_causeway_anchor", false) else "The Tide loop still needs the separate main anchor. The two side anchors do not open that door.")
	lines.append("This post is not a safe zone or checkpoint. Crates may be empty, and the resting grazers are neutral until attacked.")
	guide.dialogue_lines = PackedStringArray(lines)
	guide.next_line_index = 0
