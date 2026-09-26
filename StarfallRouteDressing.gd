@tool
extends "res://RouteFieldDressing.gd"

# Local, read-only world feedback. No sigils, completion flags or payouts are
# granted here. Existing field operations remain the sole task authorities.
const LOCAL_SITES := {
	"StarfallOutskirts": [
		[6, 0.82, "camp", "THE CARAVAN'S LAST STOP", "A FIELD SHELTER, NOT A SAFE ZONE OR CHECKPOINT"],
		[1, 0.20, "task", "CARAVAN REPAIR REGISTER", "REPAIR BOTH SIDE-BRANCH WINCHES; EACH RAISES ROAD COVER"],
		[2, 0.78, "haul", "BROKEN WAGON TRAIN", "ORDINARY SUPPLIES MAY BE EMPTY; SEEK THE UPPER RESERVE"],
		[3, 0.50, "garden", "RAMPART WILDFLOWERS", "RESTING GRAZERS ARE NEUTRAL UNLESS STRUCK"],
		[4, 0.78, "siege", "THE FALLEN STANDARD", "THE UPPER NICHE HAS TWO RESERVE GUARDIANS"],
		[5, 0.22, "survey", "THE EVACUATION STONES", "THE RETURN LIFT SAVES THE CLIMB BACK"],
		[6, 0.25, "reserve", "LAST MUSTER", "RETURN TO THIS GALLERY AFTER THE SOVEREIGN"],
	],
	"StarfallSilentGate": [
		[6, 0.82, "camp", "THE WARD KEEPER'S SHELTER", "THE GATE RELAYS AND SIDE INSPECTIONS ARE DIFFERENT TASKS"],
		[1, 0.24, "task", "WARD CIRCUIT MODEL", "HIGH RELAY > HIGH INSPECTION; LOW RELAY > LOW INSPECTION"],
		[2, 0.72, "survey", "MUTE WATCH STORES", "THE MAIN EXIT ONLY NEEDS THE ORIGINAL RELAYS"],
		[3, 0.38, "ward", "THE BROKEN WARD ARCH", "SEEK BOTH TERMINALS IN THE FIRST AND LAST SIDE BRANCHES"],
		[4, 0.75, "pool", "QUIET WARD POOL", "THE QUIET CREATURES ARE NOT WATCH GUARDIANS"],
		[5, 0.23, "haul", "ABANDONED WATCH CHESTS", "THE UPPER RESERVE NEEDS INSPECTIONS AND GUARDIANS"],
		[6, 0.25, "reserve", "THE HUSHED WATCH", "RETURN TO THIS GALLERY AFTER THE SOVEREIGN"],
	],
	"StarfallMemoryVault": [
		[6, 0.82, "reading", "THE LAST INDEXER", "RECORD CASES ARE NOT THE THREE MEMORY SIGILS"],
		[1, 0.20, "task", "THE MISSING CATALOGUE", "BREAK THE THREE MARKED RECORD CASES IN THE SIDE BRANCHES"],
		[2, 0.76, "stacks", "THE UNCLAIMED SHELVES", "A MARKED CASE ALWAYS COUNTS EVEN WHEN ITS LOOT IS EMPTY"],
		[3, 0.43, "orrery", "MEMORY OF A SKY", "THE THREE RECORDS CAN BE RECOVERED IN ANY ORDER"],
		[4, 0.78, "pool", "INKWATER REEDS", "QUIET LIFE AMONG THE FORGOTTEN NAMES"],
		[5, 0.24, "haul", "ARCHIVE TRANSFER CART", "RECORDS + UPPER GUARDIANS UNSEAL THE EXISTING CACHE"],
		[6, 0.25, "reserve", "THE ARCHIVE REMNANT", "RETURN TO THIS GALLERY AFTER THE SOVEREIGN"],
	],
	"StarfallRootedHall": [
		[6, 0.82, "camp", "THE SEED KEEPER", "THE TWO SEEDBEDS NEED THE ORIGINAL ROOT CHANNEL"],
		[1, 0.22, "task", "THE GARDENER'S LEDGER", "RESTORE BOTH SEEDBEDS IN THE FIRST AND LAST SIDE BRANCHES"],
		[2, 0.76, "haul", "THE SEED CARRIERS", "OLD SUPPLIES, NOT A REPEATABLE HEALING FARM"],
		[3, 0.36, "garden", "PALE ANTLER GROVE", "PEACEFUL GRAZERS DO NOT BLOCK SEEDBED RESTORATION"],
		[4, 0.76, "roots", "THE ROOT NURSERY", "BOTH SIDE BEDS CAN BE RESTORED IN EITHER ORDER"],
		[5, 0.23, "survey", "ROOTKEEPER'S WAYSTONES", "THE UPPER NICHE STILL HAS ITS OWN GUARDIANS"],
		[6, 0.25, "reserve", "THE THORN WATCH", "RETURN TO THIS GALLERY AFTER THE SOVEREIGN"],
	],
	"StarfallSoulCrucible": [
		[6, 0.82, "camp", "THE CRUCIBLE TENDER", "CHANNELS ENABLE TRIALS; THEY DO NOT COMPLETE THEM"],
		[1, 0.22, "task", "CONTAINMENT REGISTER", "CLEAR HIGH + LOW CONTAINMENT AND STABILIZE THE CORE"],
		[2, 0.76, "pump", "COOLANT MAINTENANCE", "HIGH TRIAL: SHADE + SENTRY; LOW: STALKER + SENTRY"],
		[3, 0.40, "retort", "THE SOUL RETORT", "EACH TRIAL WAITS IN ITS MATCHING SIDE BRANCH"],
		[4, 0.77, "pool", "COOLANT BLOOM", "RESTING SPARK GRAZERS NEED NOT BE FOUGHT"],
		[5, 0.23, "haul", "TENDER'S SPARE PARTS", "STABILIZATION DOES NOT REPLACE THE UPPER GUARDIANS"],
		[6, 0.25, "reserve", "THE UNBOUND REMNANT", "RETURN TO THIS GALLERY AFTER THE SOVEREIGN"],
	],
	"StarfallSunlessPassage": [
		[6, 0.82, "camp", "THE LAST LIGHT BEARER", "THE THREE BEACONS AND DAWN ANCHOR HAVE SEPARATE ROLES"],
		[1, 0.20, "task", "THE PROCESSION ORDER", "LIGHT FIRST > MIDDLE > LAST IN THE THREE SIDE BRANCHES"],
		[2, 0.70, "haul", "ABANDONED LANTERN CARGO", "EACH BEACON QUIETS TWO VOID LANES"],
		[3, 0.38, "lanterns", "THE UNLIT PROCESSION", "ONLY THE ORIGINAL DAWN ANCHOR STABILIZES THE BRIDGES"],
		[4, 0.78, "garden", "NIGHT FERN REFUGE", "THE NIGHT GRAZERS ARE NEUTRAL UNLESS STRUCK"],
		[5, 0.23, "survey", "THE BEARER'S LAST MARK", "THREE LIGHTS AND THE UPPER GUARDIANS UNSEAL THE RESERVE"],
		[6, 0.25, "reserve", "THE NIGHT PROCESSION", "RETURN TO THIS GALLERY AFTER THE SOVEREIGN"],
	],
	"StarfallRamparts": [
		[6, 0.75, "camp", "THE SIGNAL RUNNER", "PLATES, SIGNAL DESK AND DEEP GUARD ARE SEPARATE STEPS"],
		[1, 0.24, "task", "THE TWO WATCH SIGNALS", "CLEAR WEST + EAST WATCHES; TAKE BOTH PLATES TO THE HIGH DESK"],
		[2, 0.75, "haul", "FALLEN WATCH CARGO", "RESTORED SIGNALS QUIET THE TWO ROOT LANES"],
		[3, 0.30, "ward", "THE BROKEN WATCH ARCH", "THE HIGH ARCHIVE BRANCH HOLDS THE SIGNAL DESK"],
		[4, 0.74, "garden", "THE RIM GARDEN", "THE DEEPEST SIDE-BRANCH GUARD PROTECTS THE RIM CACHE"],
		[5, 0.24, "survey", "THE SIGNAL COURIER'S MARK", "A RETURN LIFT LINKS THIS EXPEDITION BACK TO ITS ENTRANCE"],
		[7, 0.25, "reserve", "THE LAST SIGNAL WATCH", "RETURN TO THE FINAL GALLERY AFTER THE SOVEREIGN"],
	],
}
const PROFILES := {
	"StarfallOutskirts": ["starfall_outskirts", "Oren, Caravan Keeper", "Rampart Grazer", ["winch_0", "winch_1"], ["WEST", "EAST"]],
	"StarfallSilentGate": ["starfall_silent_gate", "Sile, Ward Keeper", "Mute Grazer", ["inspection_0", "inspection_1"], ["HIGH", "LOW"]],
	"StarfallMemoryVault": ["starfall_memory_vault", "Iria, Last Indexer", "Inkwater Grazer", ["record_0", "record_1", "record_2"], ["FIRST", "SECOND", "THIRD"]],
	"StarfallRootedHall": ["starfall_rooted_hall", "Thale, Seed Keeper", "Pale Antlerling", ["seedbed_0", "seedbed_1"], ["FIRST", "LAST"]],
	"StarfallSoulCrucible": ["starfall_soul_crucible", "Eris, Crucible Tender", "Spark Grazer", ["containment_0", "containment_1", "@starfall_crucible_stabilized"], ["HIGH", "LOW", "CORE"]],
	"StarfallSunlessPassage": ["starfall_sunless_passage", "Neri, Light Bearer", "Night Fern Grazer", ["beacon_0", "beacon_1", "beacon_2"], ["FIRST", "MIDDLE", "LAST"]],
	"StarfallRamparts": ["starfall_ramparts", "Vann, Signal Runner", "Rim Grazer", ["plate_0", "plate_1", "relay_restored"], ["WEST", "EAST", "DESK"]],
}


func _sites() -> Array:
	return LOCAL_SITES[region]


func _room_root() -> Node2D:
	return expansion if region == "StarfallRamparts" else expansion.get_parent()


func _zone() -> String:
	return "starfall_reach"


func _site_tone() -> Color:
	return Color(0.54, 0.59, 0.79) if region == "StarfallRamparts" else (expansion.plan["tone"] as Color).lightened(0.24)


func _site_anchor(index: int) -> Vector2:
	var data: Array = _sites()[index]
	var rampart := region == "StarfallRamparts"
	var chamber: Rect2 = expansion._main_rect(data[0]) if rampart else expansion._chamber_rect(data[0])
	var host: Node2D = expansion if rampart else expansion.generated
	var prefix := ("MainRoom%dFloor" if rampart else "Chamber%d_Floor") % data[0]
	var desired := lerpf(chamber.position.x, chamber.end.x, data[1])
	if host.has_node(prefix + "0"):
		return FLOOR.on_floor(host, prefix, desired, 9, 190)
	# Schematic scenes omit physics; these anchors are replaced by the audited
	# preview table below when present, never by spawning gameplay actors.
	if PREVIEW_POINTS.has(region):
		return PREVIEW_POINTS[region][index]
	return Vector2(desired, chamber.end.y - 9)


const PREVIEW_POINTS := {
	"StarfallOutskirts": [Vector2(3018.6, 2171), Vector2(1690, 751), Vector2(4287.4, 1111), Vector2(5265, 751), Vector2(6099.6, 1471), Vector2(3477.5, 1831), Vector2(1462.5, 2171)],
	"StarfallSilentGate": [Vector2(5673.2, 2171), Vector2(1882.4, 751), Vector2(4433, 1111), Vector2(5250.7, 1471), Vector2(4810, 1831), Vector2(2048.15, 1471), Vector2(3672.5, 2171)],
	"StarfallMemoryVault": [Vector2(5848.7, 2171), Vector2(1677, 751), Vector2(4440.8, 1111), Vector2(5017.35, 751), Vector2(6113.9, 1471), Vector2(3174.6, 1831), Vector2(4403.75, 2171)],
	"StarfallRootedHall": [Vector2(5626.4, 2171), Vector2(2117.7, 751), Vector2(5655, 1111), Vector2(5376.8, 1471), Vector2(4745, 1111), Vector2(1717.95, 1831), Vector2(3477.5, 2171)],
	"StarfallSoulCrucible": [Vector2(5556.2, 2191), Vector2(2219.1, 791), Vector2(5557.5, 1151), Vector2(5330, 1511), Vector2(4451.85, 1871), Vector2(1363.05, 1511), Vector2(3185, 2191)],
	"StarfallSunlessPassage": [Vector2(5649.8, 2191), Vector2(2080, 791), Vector2(1365, 1151), Vector2(2254.2, 1511), Vector2(5111.6, 1871), Vector2(5850, 1511), Vector2(3575, 2191)],
	"StarfallRamparts": [Vector2(4078.95, 1471), Vector2(2141.736, 1071), Vector2(4844.95, 671), Vector2(5438.6, 271), Vector2(7162.1, 671), Vector2(4767.8, 1071), Vector2(517.6, 1071)],
}


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		var state := get_node("/root/GameState")
		state.shortcut_changed.connect(_on_progress)
		state.boss_progress_changed.connect(_on_progress)
		_refresh()


func _build_site(index: int, data: Array, at: Vector2) -> void:
	super._build_site(index, data, at)
	var site := get_node("Site%d" % index)
	site.z_index = 0
	var clue := site.get_node("RouteClue") as Label
	clue.z_index = 3
	clue.add_theme_constant_override("outline_size", 4)
	clue.add_theme_color_override("font_outline_color", Color(0.035, 0.03, 0.07))
	match data[2]:
		"task":
			_line(site, "RegisterStand", [Vector2(-142, 0), Vector2(-142, -126), Vector2(142, -126), Vector2(142, 0)], tone.darkened(0.3), 8)
			var captions: Array = PROFILES[region][4]
			for i in range(captions.size()):
				var x := (i - (captions.size() - 1) * 0.5) * 90
				_poly(site, "Light%d" % i, [Vector2(x - 26, -72), Vector2(x - 21, -111), Vector2(x + 21, -111), Vector2(x + 26, -72)], tone.darkened(0.55))
				var label := Label.new()
				label.position = Vector2(x - 43, -60)
				label.size.x = 86
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.add_theme_font_size_override("font_size", 11)
				label.text = captions[i]
				site.add_child(label)
		"reserve":
			_poly(site, "ReserveStone", [Vector2(-132, 0), Vector2(-122, -126), Vector2(122, -126), Vector2(132, 0)], tone.darkened(0.55))
			_ring(site, "TaskSeal", Vector2(-60, -75), 24, tone)
			_ring(site, "GuardSeal", Vector2(60, -75), 24, tone)
			_line(site, "ReserveLatch", [Vector2(-83, -26), Vector2(83, -26)], tone, 5)
		"siege":
			_line(site, "BrokenSpar", [Vector2(-128, 0), Vector2(-70, -146), Vector2(98, -123)], tone.darkened(0.25), 10)
			_poly(site, "TornStandard", [Vector2(-52, -143), Vector2(76, -123), Vector2(50, -68), Vector2(17, -93), Vector2(-34, -60)], tone)
			_ring(site, "AbandonedWheel", Vector2(81, -32), 31, tone.lightened(0.15))
		"ward":
			_line(site, "WardArch", [Vector2(-124, 0), Vector2(-124, -95), Vector2(-61, -150), Vector2(61, -150), Vector2(124, -95), Vector2(124, 0)], tone.darkened(0.25), 17)
			_poly(site, "WardSeal", [Vector2(-24, -73), Vector2(0, -112), Vector2(24, -73), Vector2(0, -44)], tone.lightened(0.35))
		"orrery":
			_ring(site, "MemoryOrbit", Vector2(0, -90), 67, tone)
			_line(site, "Meridian", [Vector2(-100, -128), Vector2(100, -50)], tone.lightened(0.3), 4)
			_line(site, "Pedestal", [Vector2(-75, 0), Vector2(0, -33), Vector2(75, 0)], tone, 8)
			for i in range(3):
				_poly(site, "MemoryStar%d" % i, [Vector2(-70 + i * 65, -122 + i * 23), Vector2(-61 + i * 65, -138 + i * 23), Vector2(-52 + i * 65, -122 + i * 23)], tone.lightened(0.5))
		"roots":
			for i in range(3):
				var x := -90.0 + i * 90
				_poly(site, "SeedPot%d" % i, [Vector2(x - 30, -3), Vector2(x - 38, -39), Vector2(x + 38, -39), Vector2(x + 30, -3)], tone.darkened(0.3))
				_line(site, "Seedling%d" % i, [Vector2(x, -40), Vector2(x - 13, -87), Vector2(x + 16, -113)], tone.lightened(0.2), 6)
		"retort":
			_poly(site, "Vessel", [Vector2(-94, 0), Vector2(-94, -91), Vector2(-48, -142), Vector2(48, -142), Vector2(94, -91), Vector2(94, 0)], tone.darkened(0.4))
			_ring(site, "ContainmentRing", Vector2(0, -80), 42, tone.lightened(0.2))
			_line(site, "BleedPipe", [Vector2(-125, 0), Vector2(-125, -62), Vector2(122, -62), Vector2(122, 0)], tone, 6)
		"lanterns":
			_line(site, "BearerRail", [Vector2(-135, 0), Vector2(-135, -148), Vector2(135, -148), Vector2(135, 0)], tone.darkened(0.3), 7)
			for i in range(3):
				var x := -80.0 + i * 80
				_line(site, "Chain%d" % i, [Vector2(x, -148), Vector2(x, -112)], tone, 3)
				_poly(site, "Lantern%d" % i, [Vector2(x - 17, -108), Vector2(x, -124), Vector2(x + 17, -108), Vector2(x + 13, -68), Vector2(x - 13, -68)], tone.darkened(0.4))


func _build_resident(at: Vector2) -> void:
	for side in [-1, 1]:
		var marker := Marker2D.new()
		marker.name = "CampStop%d" % side
		marker.position = at + Vector2(side * 28, -24)
		add_child(marker)
	var npc := RESIDENT.instantiate()
	npc.name = "FieldGuide"
	npc.position = at + Vector2(-28, -24)
	npc.resident_name = PROFILES[region][1]
	npc.coat_color = tone.darkened(0.35)
	npc.route_marker_names = PackedStringArray(["CampStop-1", "CampStop1"])
	npc.walk_speed = 16
	npc.victory_dialogue_lines = PackedStringArray()
	add_child(npc)
	var label := npc.get_node("NameLabel") as Label
	label.position = Vector2(-140, -70)
	label.size.x = 280
	label.z_index = 2
	label.add_theme_constant_override("outline_size", 4)


func _add_streamed(actor: Node2D, kind: String) -> void:
	if kind == "neutral":
		actor.creature_name = PROFILES[region][2]
	super._add_streamed(actor, kind)


func activate_room_population() -> void:
	super.activate_room_population()
	if not Engine.is_editor_hint():
		_refresh()


func _on_progress(_id: String) -> void:
	_refresh()


func _events() -> Array[String]:
	var events: Array[String] = []
	for suffix in PROFILES[region][3]:
		events.append(String(suffix).substr(1) if String(suffix).begins_with("@") else String(PROFILES[region][0]) + "_" + suffix)
	return events


func _refresh() -> void:
	var state := get_node("/root/GameState")
	var flags: Dictionary = state.unlocked_shortcuts
	var events := _events()
	var prefix: String = PROFILES[region][0]
	var count := 0
	for i in range(events.size()):
		var active := bool(flags.get(events[i], false))
		count += int(active)
		get_node("Site1/Light%d" % i).color = Color(0.58, 0.95, 0.74) if active else tone.darkened(0.55)
	get_node("Site1/RouteClue").text = String(_sites()[1][3]) + "\n" + String(_sites()[1][4]) + "\nRECORDED %d/%d" % [count, events.size()]
	var complete := bool(flags.get(prefix + "_field_complete", false))
	var guarded := bool(flags.get(prefix + "_niche_cleared", false))
	var returned := bool(flags.get(prefix + "_field_return_complete", false))
	var victorious := bool(state.defeated_bosses.get("hollow_sovereign", false))
	var reserve := get_node("Site6")
	reserve.get_node("TaskSeal").modulate = Color(0.5, 1, 0.65) if complete else Color.WHITE
	reserve.get_node("GuardSeal").modulate = Color(0.5, 1, 0.65) if guarded else Color.WHITE
	reserve.get_node("ReserveLatch").modulate = Color(0.5, 1, 0.65) if complete and guarded else Color.WHITE
	var return_text := "RETURN AFTER THE SOVEREIGN"
	if returned:
		return_text = "RETURN PATROL CLEARED - THIS WATCH IS QUIET"
	elif victorious:
		return_text = "RETURN PATROL READY IN THE FINAL GALLERY" if complete and guarded else "RETURN PATROL NEEDS TASK + GUARDIANS"
	reserve.get_node("RouteClue").text = String(_sites()[6][3]) + "\nTASK: " + ("DONE" if complete else "PENDING") + " | GUARDIANS: " + ("DONE" if guarded else "PENDING") + "\n" + return_text
	_refresh_landmarks(flags, events)
	var guide := get_node_or_null("FieldGuide")
	if guide != null:
		guide.dialogue_lines = PackedStringArray([
			"Recorded %d/%d. %s" % [count, events.size(), String(_sites()[1][4]).capitalize()],
			"The local reserve needs the field task and its own guardians. It grants no memory sigil.",
			return_text.capitalize() + ". Save discoveries at a lamp; this shelter is not a checkpoint.",
		])


func _refresh_landmarks(flags: Dictionary, events: Array[String]) -> void:
	# These models reflect the actual systems, never the fact that a player
	# merely visited a room, spoke to its guide or claimed an older save's cache.
	match region:
		"StarfallOutskirts":
			get_node("Site4/TornStandard").color = tone.lightened(0.35) if flags.get(events[0], false) and flags.get(events[1], false) else tone
		"StarfallSilentGate":
			get_node("Site3/WardSeal").color = tone.lightened(0.55) if flags.get("starfall_silent_high", false) and flags.get("starfall_silent_low", false) else tone.darkened(0.4)
		"StarfallMemoryVault":
			for i in range(3):
				get_node("Site3/MemoryStar%d" % i).color = tone.lightened(0.55) if flags.get(events[i], false) else tone.darkened(0.4)
		"StarfallRootedHall":
			for i in range(3):
				var event: String = [events[0], "starfall_root_channels", events[1]][i]
				get_node("Site4/Seedling%d" % i).default_color = tone.lightened(0.4) if flags.get(event, false) else tone.darkened(0.4)
		"StarfallSoulCrucible":
			get_node("Site3/ContainmentRing").default_color = tone.lightened(0.55) if flags.get("starfall_crucible_stabilized", false) else tone.darkened(0.05)
		"StarfallRamparts":
			get_node("Site3/WardSeal").color = tone.lightened(0.55) if flags.get(events[2], false) else tone.darkened(0.4)
	if region == "StarfallSunlessPassage":
		for i in range(3):
			get_node("Site3/Lantern%d" % i).color = tone.lightened(0.5) if flags.get(events[i], false) else tone.darkened(0.4)
