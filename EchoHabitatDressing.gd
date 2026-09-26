@tool
extends "res://RouteFieldDressing.gd"

# Read-only environmental feedback for the existing well/nursery objectives.
# Ordinary props share the same lazy loading and within-run state registry as
# the other field scenes; no new reward flags, gates or combat rules live here.
const HABITATS := {
	"tide": [
		[0, 0.57, "camp", "THE WELL KEEPER'S POST", "THE TWO REGULATORS ARE IN RAISED SIDE CHAMBERS"],
		[1, 0.30, "haul", "STRANDED SUPPLY CART", "BREAKABLE SUPPLIES MAY BE EMPTY"],
		[2, 0.62, "pool", "REEDWATER POOL", "RESTING GRAZERS DO NOT ATTACK FIRST"],
		[3, 0.62, "pressure", "LOWER FLOW GAUGE", "CLIMB THE SIDE BRANCH TO THE LOWER REGULATOR"],
		[4, 0.54, "archive", "OLD FLOOD MARKS", "THE FIRST REGULATOR CALMS THE FIRST TWO CURRENTS"],
		[5, 0.34, "pump", "ABANDONED PUMP STORES", "THE UPPER REGULATOR CONTROLS THE OTHER CURRENT BANK"],
		[6, 0.44, "garden", "MOSS FILTER BED", "RETURN TRIAL: THE NEARBY SIDE ALCOVE, AFTER AWAKENING"],
		[7, 0.52, "archive", "PEARL SEEKER'S MARKS", "THE FIRST DISCOVERY CACHE IS IN THIS TIER'S HIGH BRANCH"],
		[8, 0.60, "haul", "SALVAGED WATER GEAR", "FOLLOW THE CLIMB TO THE UPPER REGULATOR"],
		[9, 0.25, "pressure", "UPPER FLOW GAUGE", "BOTH REGULATORS UNSEAL THE DISCOVERY CACHE"],
		[10, 0.57, "pool", "CLEARWATER GROVE", "THIS POOL IS SCENERY, NOT A HEALING SPRING"],
		[11, 0.55, "survey", "HIGH WATER MARK", "THE FINAL CLIMB LEADS TO THE RETURN DOOR"],
		[12, 0.58, "survey", "WELL RIM LOOKOUT", "RETURN TO THE ENTRANCE THROUGH THE END DOOR"],
	],
	"nest": [
		[0, 0.53, "camp", "THE SILK WATCH", "THE SIDE NURSERIES ARE SEPARATE FROM THE MAIN NEST VEIL"],
		[1, 0.30, "nursery", "WESTERN SILK CHAMBER", "GUARDED OUTER NURSERY: CLIMB THE RAISED BRANCH"],
		[2, 0.64, "haul", "WEBBOUND PROVISIONS", "OLD SUPPLY CRATES MAY HOLD NOTHING"],
		[3, 0.48, "garden", "SPORE FERN POCKET", "THESE GRAZERS ARE NEUTRAL; BROODLINGS ARE NOT"],
		[4, 0.55, "archive", "WARDEN'S SILK MARKS", "TWO SIDE NURSERIES, TWO GUARDIANS IN EACH"],
		[5, 0.27, "nursery", "EASTERN SILK CHAMBER", "CLEAR BOTH OUTER NURSERIES FOR THE DISCOVERY CACHE"],
		[6, 0.63, "pool", "HUSHED ROOT POOL", "AFTER THE MATRIARCH, THE LAST HATCH WAKES NEARBY"],
		[7, 0.40, "haul", "ABANDONED SILK DELIVERY", "SEARCH THE HIGH SIDE CHAMBER FOR THE BROOD TRIBUTE"],
		[8, 0.60, "survey", "NURSERY WATCH EXIT", "THE RETURN DOOR LEADS BACK TO THE ENTRANCE"],
	],
}
const HABITAT_ANCHORS := {
	"tide": [Vector2(945.74, 656), Vector2(1496.5, 336), Vector2(2097.58, 16), Vector2(2566, -304), Vector2(2001, -685), Vector2(1532.24, -304), Vector2(1067.5, -624), Vector2(707, -944), Vector2(1414, -1325), Vector2(1633, -944), Vector2(2382, -1264), Vector2(2662, -1584), Vector2(2018, -1904)],
	"nest": [Vector2(1511.056, 157), Vector2(2205.6, -203), Vector2(2816, -563), Vector2(3441.664, -203), Vector2(3944.6, -923), Vector2(2960, -1283), Vector2(2344.176, -923), Vector2(1326.72, -1283), Vector2(2500.96, -1643)],
}


func _sites() -> Array:
	return HABITATS[region]


func _preview_anchors() -> Array:
	return HABITAT_ANCHORS[region]


func _site_anchor(index: int) -> Vector2:
	if region == "tide" and index in [4, 8]:
		# These main ledges are too narrow for cargo. Dress the existing broad
		# side alcoves instead of putting supplies over a shaft or adding floor.
		var shelf := expansion.get_node_or_null("Tier%02dSideAlcove" % index) as Node2D
		if shelf != null:
			return FLOOR.on_floor(expansion, String(shelf.name), shelf.position.x, 8, 190)
		return _preview_anchors()[index]
	return super._site_anchor(index)


func _site_tone() -> Color:
	return Color(0.24, 0.64, 0.67) if region == "tide" else Color(0.64, 0.40, 0.65)


func _site_margin(index: int) -> float:
	return 125 if _sites()[index][2] in ["archive", "survey"] else 190


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.shortcut_changed.connect(_on_habitat_event)
		state.zone_tier_changed.connect(_on_habitat_tier)
	_refresh_habitat()


func _build_site(index: int, data: Array, at: Vector2) -> void:
	super._build_site(index, data, at)
	var site := get_node("Site%d" % index)
	if data[2] == "pressure":
		_line(site, "GaugePipe", [Vector2(-135, 0), Vector2(-135, -55), Vector2(0, -55), Vector2(0, -111), Vector2(132, -111), Vector2(132, 0)], tone.darkened(0.2), 9)
		_ring(site, "GaugeFace", Vector2(0, -98), 42, tone.lightened(0.4))
		_line(site, "GaugeNeedle", [Vector2(0, -98), Vector2(23, -121)], Color(0.98, 0.64, 0.3), 5)
		_poly(site, "FlowSignal", [Vector2(76, -11), Vector2(76, -81), Vector2(107, -81), Vector2(107, -11)], Color(0.30, 0.88, 0.95, 0.6))
		for mark in range(4):
			_line(site, "GaugeTick%d" % mark, [Vector2(111, -20 - mark * 17), Vector2(122, -20 - mark * 17)], tone.lightened(0.5), 2)
	elif data[2] == "nursery":
		var pods := Node2D.new()
		pods.name = "DormantPods"
		site.add_child(pods)
		for i in range(3):
			var x := float(i - 1) * 70
			var h := 90.0 + i % 2 * 35
			_poly(pods, "Pod%d" % i, [Vector2(x - 27, -14), Vector2(x - 37, -h * 0.55), Vector2(x - 15, -h), Vector2(x + 14, -h), Vector2(x + 34, -h * 0.55), Vector2(x + 24, -14)], tone.lightened(0.15))
			_line(pods, "SilkSeam%d" % i, [Vector2(x - 15, -h + 10), Vector2(x + 13, -h * 0.5), Vector2(x - 8, -20)], tone.darkened(0.4), 3)
		var shed := Node2D.new()
		shed.name = "SpentSilk"
		shed.visible = false
		site.add_child(shed)
		for i in range(3):
			var x := float(i - 1) * 70
			_poly(shed, "Shell%d" % i, [Vector2(x - 30, -3), Vector2(x - 23, -30), Vector2(x, -8), Vector2(x + 25, -27), Vector2(x + 32, -3)], tone.darkened(0.25))
		_line(site, "SilkHammock", [Vector2(-140, -137), Vector2(-83, -155), Vector2(0, -136), Vector2(83, -155), Vector2(140, -137)], Color(tone.lightened(0.5), 0.5), 3)
	elif data[2] == "camp":
		# The existing objective board sits above the entrance alcove.
		# Keep this local caption below it, clear of the shelter's awning.
		site.get_node("RouteClue").position.y = -188
		if region == "tide":
			_line(site, "WaterStaff", [Vector2(-128, 0), Vector2(-128, -141), Vector2(-101, -141)], tone.lightened(0.25), 4)
			_ring(site, "RescueRing", Vector2(-128, -79), 20, Color(0.93, 0.72, 0.4))
		else:
			_line(site, "SilkAwning", [Vector2(-143, 0), Vector2(-143, -132), Vector2(-34, -151), Vector2(101, -132), Vector2(149, -64)], Color(tone.lightened(0.4), 0.65), 4)


func activate_room_population() -> void:
	super.activate_room_population()
	if not Engine.is_editor_hint():
		_refresh_habitat()


func _add_streamed(actor: Node2D, kind: String) -> void:
	if kind == "neutral":
		actor.creature_name = "Reedwater Grazer" if region == "tide" else "Spore Fern Grazer"
	super._add_streamed(actor, kind)


func _build_resident(at: Vector2) -> void:
	super._build_resident(at)
	var guide := get_node("FieldGuide")
	guide.resident_name = "Rill, Well Keeper" if region == "tide" else "Senn, Silk Watcher"
	guide.name_label.text = guide.resident_name
	guide.coat_color = tone.darkened(0.2)
	guide.coat.color = guide.coat_color
	guide.victory_dialogue_lines = PackedStringArray()


func _on_habitat_event(event_id: String) -> void:
	if event_id.begins_with("echo_%s_field_" % region):
		_refresh_habitat()


func _on_habitat_tier(zone: String, _tier: int) -> void:
	if zone == "echo_grotto":
		_refresh_habitat()


func _refresh_habitat() -> void:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return
	var cleared := 0
	for station in range(2):
		var active := bool(state.unlocked_shortcuts.get("echo_%s_field_station_%d" % [region, station], false))
		cleared += int(active)
		var index := (3 if station == 0 else 9) if region == "tide" else (1 if station == 0 else 5)
		var site := get_node("Site%d" % index)
		if region == "tide":
			site.get_node("FlowSignal").modulate = Color(0.45, 1, 0.65, 0.5) if active else Color.WHITE
			site.get_node("GaugeNeedle").points = PackedVector2Array([Vector2(0, -98), Vector2(-23, -91) if active else Vector2(23, -121)])
		else:
			site.get_node("DormantPods").visible = not active
			site.get_node("SpentSilk").visible = active
		var data: Array = _sites()[index]
		var status := ("CURRENT BANK CALMED" if active else "CURRENT BANK ACTIVE") if region == "tide" else ("SIDE NURSERY CLEARED" if active else "SIDE NURSERY OCCUPIED")
		site.get_node("RouteClue").text = String(data[3]) + "\n" + String(data[4]) + "\n" + status
	var guide := get_node_or_null("FieldGuide")
	if guide == null:
		return
	var complete := bool(state.unlocked_shortcuts.get("echo_%s_field_complete" % region, false))
	var returned := bool(state.unlocked_shortcuts.get("echo_%s_field_return_complete" % region, false))
	var lines: Array[String] = []
	if returned:
		lines.append("The return trial is quiet. Its reserve and the original discovery cache are separate one-time finds. Save them at a lamp.")
	elif complete and state.get_zone_tier("echo_grotto") >= 1:
		lines.append("The caves have awakened. Your field task is complete: seek the return trial in the side alcove by the %s for its separate reserve." % ("moss filter bed" if region == "tide" else "hushed root pool"))
	elif complete:
		lines.append("The discovery cache is unsealed. Search the high branch near the %s, not just the room's final exit. Return after the Matriarch for another trial." % ("pearl seeker's marks" if region == "tide" else "abandoned silk delivery"))
	elif region == "tide":
		lines.append("Regulators ready: %d/2. Climb the side chambers beside the lower and upper flow gauges. Each regulator calms a different pair of currents." % cleared)
		lines.append("The gauges show what the regulators have done; they are not extra switches. Both regulators unlock the pearl cache in a high side branch.")
	else:
		lines.append("Outer nurseries cleared: %d/2. Two guardians protect each raised side nursery. The silk markers shed their pods when a nursery is cleared." % cleared)
		lines.append("Those side nurseries unlock the tribute cache, not the main Nest Veil. The original brood still guards that passage.")
	lines.append("This shelter is not a safe zone or checkpoint. Crates may be empty; the resting grazers are neutral until attacked.")
	guide.dialogue_lines = PackedStringArray(lines)
	guide.next_line_index = 0
