@tool
extends Node2D

# Authored local scenes, not another map generator. Scenery previews in the
# editor; residents, salvage encounters and ordinary props wait for room entry.
const FLOOR := preload("res://RouteFloorPlacement.gd")
const CRATE := preload("res://DestructibleCrate.tscn")
const NEUTRAL := preload("res://NeutralCreature.tscn")
const RESIDENT := preload("res://TownResident.tscn")
const ENCOUNTER := preload("res://LocalizedEncounter.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const SENTRY := preload("res://ShaftSentry.tscn")
const WISP := preload("res://ShaftWisp.tscn")
const SHADE := preload("res://EchoShade.tscn")
# chamber, horizontal preference, scenery, local title, useful route clue.
# Negative Shaft indices select side caves (-1 is side cave zero).
const SITES := {
	"shaft": [
		[0, 0.53, "haul", "ABANDONED SORTING LINE", "WESTERN SIDE CAVES: WINCH + COUNTERWEIGHT"],
		[1, 0.20, "pump", "PUMP STORES", "THE REPAIRED HOIST JOINS PUMP HALL AND THE RESERVOIR"],
		[-1, 0.05, "camp", "SURVEYOR'S SHELTER", "A FIELD CAMP, NOT A SAFE ZONE OR CHECKPOINT"],
		[3, 0.80, "garden", "RESERVOIR MOSS", "GRAZERS ARE PEACEFUL UNLESS STRUCK"],
		[4, 0.42, "salvage", "SEALED WATCH SUPPLIES", "OPTIONAL SALVAGE - CLEAR ITS TWO GUARDIANS"],
	],
	"echo": [
		[0, 0.62, "camp", "CHOIR SURVEY CAMP", "LISTENING POSTS LIE IN RAISED SIDE CHAMBERS"],
		[1, 0.34, "bell", "LOW CHOIR MARK", "THE LOST CHOIR: LOW, THEN MIDDLE, THEN HIGH"],
		[2, 0.64, "pool", "STILLWATER SHELF", "RESTING CREATURES NEED NOT BE FOUGHT"],
		[3, 0.64, "haul", "LOST COURIER BUNDLES", "SUPPLIES MAY BE EMPTY; THE CHOIR CACHE IS SEPARATE"],
		[4, 0.48, "garden", "GLASS FERN BEDS", "FOLLOW THE CLIMB TO THE LAST LISTENING POST"],
		[5, 0.30, "bell", "HIGH CHOIR MARK", "AFTER ALL THREE TONES, SEEK THE FINAL HIDDEN CHAMBER"],
		[6, 0.44, "salvage", "BROKEN CRYSTAL CART", "OPTIONAL SALVAGE - CLEAR ITS TWO GUARDIANS"],
		[7, 0.30, "archive", "PILGRIM MARKS", "THE CHOIR'S OFFERING LIES OFF THE MAIN CORRIDOR"],
		[8, 0.40, "survey", "GALLERY TRAIL", "GALLERY AHEAD; ENTRY RETURN LEADS BACK DOWN"],
	],
	"gallery": [
		[0, 0.54, "camp", "THE LISTENER'S REST", "TWO WITNESSES WAIT IN RAISED SIDE CHAMBERS"],
		[1, 0.22, "lens", "WESTERN SOUND LENS", "WESTERN WITNESS: CLIMB THE SIDE LEDGES"],
		[2, 0.67, "pool", "QUIET DRIP POOL", "A RESTING GRAZER IS NOT AN ENEMY"],
		[3, 0.72, "haul", "FALLEN INSTRUMENT CARGO", "THE UPPER DETOUR IS GUARDED; SUPPLIES MAY BE EMPTY"],
		[4, 0.52, "archive", "WHISPER PILGRIMS' MARKS", "BOTH WITNESSES COUNT, IN EITHER ORDER"],
		[5, 0.26, "lens", "EASTERN SOUND LENS", "EASTERN WITNESS: SEARCH THE RAISED BRANCH"],
		[6, 0.60, "garden", "SILVER FERN GROVE", "AFTER THE MATRIARCH, THE RETURN TRIAL WAKES NEARBY"],
		[7, 0.52, "archive", "OFFERING WAYSTONES", "RECORDED BOTH WITNESSES? SEARCH THE HIGH DEAD END"],
		[8, 0.40, "survey", "LISTENER'S OVERLOOK", "THE RETURN DOOR LEADS TO THIS ROOM'S ENTRANCE"],
	],
	"archive": [
		[0, 0.56, "reading", "THE INDEXER'S DESK", "THE RECORDS FOLLOW LIGHT, NOT THE ORDER YOU FIND THEM"],
		[1, 0.25, "lens", "DAWN REFLECTOR", "DAWN IS THE SECOND RECORD"],
		[2, 0.62, "stacks", "BROKEN CATALOGUE", "LOOSE SUPPLIES ARE NOT THE UNINDEXED MEMORY"],
		[3, 0.62, "lens", "ZENITH REFLECTOR", "BEGIN WITH ZENITH, THEN DAWN, THEN DUSK"],
		[4, 0.40, "haul", "ARCHIVIST'S DELIVERY", "THE BOOK CART HOLDS ORDINARY BREAKABLE SUPPLIES"],
		[5, 0.25, "lens", "DUSK REFLECTOR", "DUSK CLOSES THE SEQUENCE"],
		[6, 0.52, "pool", "INKWATER GARDEN", "COMPLETE THE RECORDS BEFORE THE AWAKENED TRIAL"],
		[7, 0.43, "stacks", "UNINDEXED SHELVES", "THE MEMORY CACHE WAITS IN THE HIGH SIDE CHAMBER"],
		[8, 0.65, "survey", "PRISM EXIT TABLE", "RETURN TO THE ENTRANCE WITHOUT REPEATING THE CLIMB"],
	],
}
# The schematic editor deliberately has no physics floors. These audited
# anchors keep its scenery at the same positions as the live room; the content
# regression test flags drift whenever the authored terrain changes.
const PREVIEW_ANCHORS := {
	"shaft": [Vector2(-1151.5, 656), Vector2(-2140, 296), Vector2(-3210, -34), Vector2(-1875, -584), Vector2(-375, -914)],
	"echo": [Vector2(1678.74, 157), Vector2(2296.2, -203), Vector2(3238, -563), Vector2(3875.424, -203), Vector2(3141.4, -923), Vector2(2425, -1283), Vector2(1676.808, -923), Vector2(1209.4, -1643), Vector2(2126.32, -2003)],
	"gallery": [Vector2(1385.724, 157), Vector2(2021.9, -203), Vector2(2940.418, -563), Vector2(3695.76, -923), Vector2(3864, -1283), Vector2(2676.032, -923), Vector2(2200.9, -1283), Vector2(1402.2, -1643), Vector2(2104.88, -2003)],
	"archive": [Vector2(1643.52, 157), Vector2(2400.8, -203), Vector2(3506.584, -563), Vector2(3902.75, -923), Vector2(2804.55, -1283), Vector2(1775.95, -923), Vector2(1344.9, -1283), Vector2(1978.471, -1643), Vector2(3434.555, -2003)],
}
var region := "shaft"
var population_loaded := false
var anchors: Array[Vector2] = []
var tone: Color
var room: Node2D
var expansion: Node2D


func _sites() -> Array:
	return SITES[region]


func _preview_anchors() -> Array:
	return PREVIEW_ANCHORS[region]


func _site_margin(index: int) -> float:
	# Small waystones fit this ledge; full camps/carts need more clearance.
	return 125 if region == "gallery" and index == 4 else 190


func _site_tone() -> Color:
	if region == "gallery":
		return Color(0.40, 0.63, 0.80)
	if region == "archive":
		return Color(0.60, 0.53, 0.80)
	return Color(0.28, 0.64, 0.64) if region == "shaft" else Color(0.39, 0.70, 0.85)


func _site_anchor(index: int) -> Vector2:
	var data: Array = _sites()[index]
	var side_cave: bool = region == "shaft" and int(data[0]) < 0
	var chamber: Rect2 = expansion._side_room(-int(data[0]) - 1) if side_cave else (expansion._main_room(data[0]) if region == "shaft" else expansion._chamber_rect(data[0]))
	var prefix := "SideRoom%dFloor" % (-int(data[0]) - 1) if side_cave else ("MineRoom%dFloor" % data[0] if region == "shaft" else "Chamber%02dFloor" % data[0])
	var desired := lerpf(chamber.position.x, chamber.end.x, data[1])
	# Schematic previews do not need collision or actor instances.
	if expansion.has_node(prefix + "0"):
		return FLOOR.on_floor(expansion, prefix, desired, 9, _site_margin(index))
	return _preview_anchors()[index]


func _ready() -> void:
	expansion = get_parent()
	room = _room_root()
	tone = _site_tone()
	for index in range(_sites().size()):
		var data: Array = _sites()[index]
		var at := _site_anchor(index)
		anchors.append(at)
		_build_site(index, data, at)
	if not Engine.is_editor_hint() and region in ["gallery", "archive"]:
		var state := get_node_or_null("/root/GameState")
		if state != null:
			state.shortcut_changed.connect(_on_record_changed)
			state.zone_tier_changed.connect(_on_record_tier_changed)
		_refresh_records()
	if not Engine.is_editor_hint() and room.get_parent().get_node_or_null("RoomActivityDirector") == null:
		call_deferred("activate_room_population")


func _room_root() -> Node2D:
	return expansion.get_parent()


func _build_site(index: int, data: Array, at: Vector2) -> void:
	var site := Node2D.new()
	site.name = "Site%d" % index
	site.position = at
	site.z_index = -2
	add_child(site)
	var kind: String = data[2]
	match kind:
		"reading", "stacks":
			for shelf in range(3):
				var y := -28.0 - shelf * 42
				_line(site, "Shelf%d" % shelf, [Vector2(-116, y), Vector2(116, y)], tone.darkened(0.1), 7)
				for book in range(7):
					var x := -96.0 + book * 30
					var height := 19.0 + (book * 7 + shelf * 11) % 17
					_poly(site, "Book%d_%d" % [shelf, book], [Vector2(x, y), Vector2(x, y - height), Vector2(x + 17, y - height), Vector2(x + 17, y)], tone.lightened(0.12 + book % 3 * 0.13))
			_line(site, "Cabinet", [Vector2(-120, 0), Vector2(-120, -149), Vector2(120, -149), Vector2(120, 0)], tone.darkened(0.3), 8)
			if kind == "reading":
				_line(site, "ReadingDesk", [Vector2(-48, 0), Vector2(-48, -46), Vector2(88, -46), Vector2(88, 0)], tone.lightened(0.3), 6)
		"lens":
			_line(site, "LensStand", [Vector2(-68, 0), Vector2(0, -43), Vector2(68, 0)], tone, 7)
			_ring(site, "LensFrame", Vector2(0, -95), 53, tone.lightened(0.15))
			_poly(site, "RecordLight", [Vector2(-34, -95), Vector2(0, -132), Vector2(34, -95), Vector2(0, -58)], tone.lightened(0.65))
			_line(site, "OpticalTrace", [Vector2(-142, -95), Vector2(-54, -95), Vector2(0, -58), Vector2(54, -95), Vector2(142, -95)], Color(tone, 0.38), 3)
		"camp":
			_poly(site, "Tent", [Vector2(-95, 0), Vector2(-25, -106), Vector2(28, -106), Vector2(105, 0)], tone.darkened(0.40))
			_poly(site, "TentDoor", [Vector2(-15, 0), Vector2(9, -70), Vector2(38, 0)], tone.darkened(0.80))
			_line(site, "FieldTable", [Vector2(70, -12), Vector2(70, -38), Vector2(148, -38), Vector2(148, -12)], tone.lightened(0.25), 5)
		"haul", "salvage":
			_line(site, "Rails", [Vector2(-152, -2), Vector2(152, -2)], tone.darkened(0.1), 4)
			_poly(site, "Cart", [Vector2(-78, -19), Vector2(-95, -63), Vector2(64, -63), Vector2(78, -19)], tone.darkened(0.35))
			for x in [-54, 47]:
				_ring(site, "Wheel%d" % x, Vector2(x, -12), 12, tone.lightened(0.16))
			for x in [-46, 0, 37]:
				if region == "archive":
					_poly(site, "Manuscripts%d" % x, [Vector2(x - 16, -64), Vector2(x - 16, -88), Vector2(x + 16, -88), Vector2(x + 16, -64)], tone.lightened(0.45))
				else:
					_poly(site, "Ore%d" % x, [Vector2(x - 13, -64), Vector2(x, -91 - abs(x) * 0.2), Vector2(x + 17, -64)], tone.lightened(0.30))
		"pump":
			_line(site, "Pipe", [Vector2(-140, -14), Vector2(-66, -14), Vector2(-66, -89), Vector2(105, -89), Vector2(105, 0)], tone.darkened(0.05), 12)
			_ring(site, "Gauge", Vector2(0, -89), 26, tone.lightened(0.45))
			_line(site, "GaugeNeedle", [Vector2(0, -89), Vector2(13, -104)], Color(0.93, 0.77, 0.47), 3)
		"garden", "pool":
			_poly(site, "Basin", [Vector2(-155, -3), Vector2(-112, -16), Vector2(86, -16), Vector2(154, -3)], Color(0.21, 0.59, 0.64, 0.45))
			for i in range(7):
				var x := -126.0 + i * 40
				var h := 27.0 + (i * 17 % 31)
				_poly(site, "Fern%d" % i, [Vector2(x - 11, 0), Vector2(x - 17, -h * 0.7), Vector2(x, -h), Vector2(x + 17, -h * 0.6), Vector2(x + 9, 0)], tone.lightened(0.12 + i % 2 * 0.13))
		"bell":
			_line(site, "ChoirFrame", [Vector2(-118, 0), Vector2(-118, -131), Vector2(118, -131), Vector2(118, 0)], tone.darkened(0.15), 7)
			for i in range(3):
				var x := float(i - 1) * 63
				_line(site, "Chain%d" % i, [Vector2(x, -131), Vector2(x, -99)], tone, 2)
				_poly(site, "Resonator%d" % i, [Vector2(x - 13, -99), Vector2(x + 13, -99), Vector2(x + 24, -52 + i * 8), Vector2(x - 24, -52 + i * 8)], tone.lightened(0.24))
		"archive", "survey":
			for i in range(3):
				var x := float(i - 1) * 65
				_poly(site, "Waystone%d" % i, [Vector2(x - 25, 0), Vector2(x - 22, -75 - i * 12), Vector2(x + 23, -87 - i * 12), Vector2(x + 28, 0)], tone.darkened(0.35))
				_line(site, "Mark%d" % i, [Vector2(x - 12, -50), Vector2(x + 11, -62), Vector2(x + 11, -35)], tone.lightened(0.45), 3)
	var sign := Label.new()
	sign.name = "RouteClue"
	sign.position = Vector2(-180, -202)
	sign.size = Vector2(360, 62)
	sign.text = data[3] + "\n" + data[4]
	sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", 11)
	sign.modulate = tone.lightened(0.5)
	site.add_child(sign)


func activate_room_population() -> void:
	if Engine.is_editor_hint():
		return
	for index in range(_sites().size()):
		var kind: String = _sites()[index][2]
		var at := anchors[index]
		if kind in ["haul", "pump", "archive", "survey", "stacks"]:
			for item in range(2 if kind == "haul" else 1):
				var crate := CRATE.instantiate()
				crate.name = "Supply%d_%d" % [index, item]
				crate.position = at + Vector2(-100 + item * 155, -18)
				crate.min_gold = 1
				crate.max_gold = 4
				crate.empty_drop_chance = 0.55
				crate.item_drop_chance = 0.15
				_add_streamed(crate, "crate")
		if kind in ["garden", "pool"]:
			for item in range(2 if region == "shaft" else 1):
				var fauna := NEUTRAL.instantiate()
				fauna.name = "Grazer%d_%d" % [index, item]
				fauna.position = at + Vector2(-65 + item * 110, -22)
				fauna.zone_id = _zone()
				fauna.creature_name = "Moss Grazer" if region == "shaft" else "Glass Fern Grazer"
				if region == "archive":
					fauna.creature_name = "Inkwater Grazer"
				fauna.passive_tint = tone.lightened(0.25)
				fauna.get_node("LeftPoint").position.x = -30
				fauna.get_node("RightPoint").position.x = 30
				fauna.start_resting = true
				_add_streamed(fauna, "neutral")
		if not population_loaded and kind in ["camp", "reading"]:
			_build_resident(at)
		if not population_loaded and kind == "salvage":
			_build_salvage(at)
	population_loaded = true
	if region in ["gallery", "archive"]:
		_refresh_records()


func _zone() -> String:
	return "sunken_shaft" if region == "shaft" else "echo_grotto"


func _add_streamed(actor: Node2D, kind: String) -> void:
	var key := "FieldDressing/" + String(actor.name)
	var registry := room.get_parent().get_node_or_null("WorldPopulation")
	if has_node(NodePath(actor.name)) or (registry != null and not registry.should_spawn_authored_actor(String(room.name), key)):
		actor.free()
		return
	actor.set_meta("authored_streamed_population", true)
	actor.set_meta("streamed_population_kind", kind)
	actor.set_meta("streamed_population_key", key)
	add_child(actor)
	if registry != null:
		registry.register_authored_actor(String(room.name), actor, key)


func _build_resident(at: Vector2) -> void:
	var center := at + Vector2(-90 if region == "shaft" else 0, 0)
	for side in [-1, 1]:
		var marker := Marker2D.new()
		marker.name = "CampStop%d" % side
		marker.position = center + Vector2(side * 28, -24)
		add_child(marker)
	var npc := RESIDENT.instantiate()
	npc.name = "FieldGuide"
	npc.position = center + Vector2(-28, -24)
	npc.resident_name = "Dena, Mine Surveyor" if region == "shaft" else "Leth, Choir Listener"
	npc.route_marker_names = PackedStringArray(["CampStop-1", "CampStop1"])
	npc.walk_speed = 16
	npc.dialogue_lines = PackedStringArray([
		"The winch and counterweight are in the two western side caves. Ivo can explain the repairs.",
		"The watch left sealed supplies near the Warden passage. Their guardians are not the Warden; clearing them does not open his gate.",
		"This shelter is only a survey stop. Save at a lamp before pushing farther."
	] if region == "shaft" else [
		"The Lost Choir answers low, then middle, then high. Climb into the raised side chambers to find its listening posts.",
		"The broken cart holds separate salvage. It cannot replace the choir's offering or the Matriarch's seals.",
		"After the Matriarch awakens the caves, return to the choir's trial above. Leave the resting grazers alone if you want a quiet walk."
	])
	npc.victory_dialogue_lines = PackedStringArray(["The old route is still here. Check the field board in town for unfinished discoveries and return encounters."])
	if region in ["gallery", "archive"]:
		npc.resident_name = "Venn, Whisper Keeper" if region == "gallery" else "Oris, Record Mender"
		npc.coat_color = Color(0.30, 0.45, 0.64) if region == "gallery" else Color(0.48, 0.39, 0.65)
		# The record-specific advice remains useful even after the final boss.
		npc.victory_dialogue_lines = PackedStringArray()
	add_child(npc)
	npc.get_node("NameLabel").position.x = -130
	npc.get_node("NameLabel").size.x = 260
	npc.get_node("NameLabel").z_index = 2
	npc.get_node("NameLabel").add_theme_color_override("font_outline_color", Color(0.025, 0.035, 0.07))
	npc.get_node("NameLabel").add_theme_constant_override("outline_size", 4)


func _on_record_changed(event_id: String) -> void:
	if event_id.begins_with("echo_" + region + "_"):
		_refresh_records()


func _on_record_tier_changed(zone: String, _tier: int) -> void:
	if zone == "echo_grotto":
		_refresh_records()


func _refresh_records() -> void:
	# These are read-only cues for the existing discovery system, not a second
	# quest or a second reward. Only saved flags can illuminate the reflectors.
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return
	var complete := bool(state.unlocked_shortcuts.get("echo_%s_field_complete" % region, false))
	var returned := bool(state.unlocked_shortcuts.get("echo_%s_field_return_complete" % region, false))
	var awakened: bool = state.get_zone_tier("echo_grotto") >= 1
	var witness_count := 0
	for index in range(2):
		witness_count += int(bool(state.unlocked_shortcuts.get("echo_gallery_witness_%d" % index, false)))
	for index in range(_sites().size()):
		var site := get_node("Site%d" % index)
		var light := site.get_node_or_null("RecordLight") as Polygon2D
		if light == null:
			continue
		var recorded := complete
		if region == "gallery":
			var witness := 0 if index == 1 else 1
			recorded = recorded or bool(state.unlocked_shortcuts.get("echo_gallery_witness_%d" % witness, false))
		light.modulate = Color(1, 1, 1, 1) if recorded else Color(0.35, 0.35, 0.45, 0.45)
		var data: Array = _sites()[index]
		var status := "RECORD RESTORED" if recorded else ("WITNESS NOT RECORDED" if region == "gallery" else "SEQUENCE INCOMPLETE")
		site.get_node("RouteClue").text = String(data[3]) + "\n" + String(data[4]) + "\n" + status
	var guide := get_node_or_null("FieldGuide")
	if guide == null:
		return
	var lines: Array[String] = []
	if returned:
		lines.append("The awakened guardians are quiet. Their reserve and the original discovery cache are separate; neither refills on a visit. Save your finds at a lamp.")
	elif complete and awakened:
		lines.append("The records are complete, and the caves have awakened. Seek the return trial in the side alcove by the grove above, then claim its separate reserve.")
	elif complete:
		lines.append("The records are complete. The discovery cache is unsealed in the high dead-end chamber. After the Matriarch falls, return for the awakened trial.")
	elif region == "gallery":
		lines.append("Witnesses recorded: %d/2. Listen to the western and eastern witnesses in either order. Their sound lenses brighten when each record is kept." % witness_count)
		lines.append("Both listening posts are in raised side chambers. Follow the sound lenses, clear nearby foes, then stand still while listening.")
	else:
		lines.append("Begin with Zenith, then Dawn, then Dusk. You will pass Dawn first, but finding a record is not the same as playing it in order.")
		lines.append("Climb the side ledges to the three records. A wrong note resets the unfinished sequence; the reflectors brighten only when the entire record is restored.")
	lines.append("This is a field stop, not a safe settlement or a checkpoint. The crates may be empty, and the resting grazers only fight if struck.")
	guide.dialogue_lines = PackedStringArray(lines)
	guide.next_line_index = 0


func _build_salvage(at: Vector2) -> void:
	var event_id := _zone() + "_field_salvage_cleared"
	var trial := ENCOUNTER.instantiate()
	trial.name = "SalvageEncounter"
	trial.position = at + Vector2(0, 9)
	trial.zone_id = _zone()
	trial.encounter_id = _zone() + "_field_salvage"
	trial.completion_event_id = event_id
	trial.encounter_title = "WATCH SUPPLIES" if region == "shaft" else "CRYSTAL CART SALVAGE"
	trial.enemy_scenes.append(SENTRY if region == "shaft" else SHADE)
	trial.enemy_scenes.append(WISP)
	trial.spawn_offsets.append(Vector2(-70, -32))
	trial.spawn_offsets.append(Vector2(70, -95))
	add_child(trial)
	var cache := CACHE.instantiate()
	cache.name = "SalvageCache"
	# Keep the Shaft reward away from the Warden doorway's interact radius.
	cache.position = at + Vector2(-115 if region == "shaft" else 115, -24)
	cache.cache_id = _zone() + "_field_salvage_cache"
	cache.cache_name = "Watch Supply Satchel" if region == "shaft" else "Lost Courier's Satchel"
	cache.gold_reward = 12
	cache.reward_item_id = "iron_fragment" if region == "shaft" else "ether_dust"
	cache.required_event_ids = PackedStringArray([event_id])
	add_child(cache)


func _poly(parent: Node, label: String, points: Array, color: Color) -> void:
	var node := Polygon2D.new()
	node.name = label
	node.polygon = PackedVector2Array(points)
	node.color = color
	parent.add_child(node)


func _line(parent: Node, label: String, points: Array, color: Color, width: float) -> void:
	var node := Line2D.new()
	node.name = label
	node.points = PackedVector2Array(points)
	node.default_color = color
	node.width = width
	parent.add_child(node)


func _ring(parent: Node, label: String, at: Vector2, radius: float, color: Color) -> void:
	var points: Array = []
	for index in range(17):
		points.append(at + Vector2.from_angle(TAU * index / 16.0) * radius)
	_line(parent, label, points, color, 3)
