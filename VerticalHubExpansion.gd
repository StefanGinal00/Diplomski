@tool
extends Node2D

# Connected mine chambers extending the original L-shaped room. Broad floors
# are used inside rooms; small platforms exist only in shafts and the hoist.
const WISP: PackedScene = preload("res://ShaftWisp.tscn")
const CRAWLER: PackedScene = preload("res://ShaftCrawler.tscn")
const SENTRY: PackedScene = preload("res://ShaftSentry.tscn")
const NEUTRAL: PackedScene = preload("res://NeutralCreature.tscn")
const CRATE: PackedScene = preload("res://DestructibleCrate.tscn")
const CACHE: PackedScene = preload("res://ResonanceCache.tscn")
const BLOOM: PackedScene = preload("res://LifeBloom.tscn")
const INFRASTRUCTURE := preload("res://ShaftInfrastructure.gd")
const FLOOR_PLACEMENT := preload("res://RouteFloorPlacement.gd")
const FIELD_DRESSING := preload("res://RouteFieldDressing.gd")

const WEST := -3400.0
const EAST := 0.0
const FLOOR_Y := 665.0
const TONE := Color(0.18, 0.55, 0.6)
const MAIN_CHAMBERS := [
	[-2450.0, 0.0, 340.0, 665.0],
	[-2450.0, -900.0, -20.0, 305.0],
	[-1450.0, -650.0, -450.0, -125.0],
	[-2200.0, -600.0, -900.0, -575.0],
	[-800.0, 0.0, -1230.0, -905.0],
]
const SIDE_CHAMBERS := [
	[-3400.0, -2250.0, -350.0, -25.0, 1],
	[-3300.0, -2050.0, 390.0, 715.0, 0],
	[-3150.0, -2100.0, -1050.0, -725.0, 3],
]
const LOOP_LINK := [1, 3]
var population_loaded := false


func _ready() -> void:
	if _use_schematic_editor_preview():
		_build_depth()
		_build_route_preview()
		_build_landmarks()
		return
	_build_depth()
	_build_route()
	_build_broken_hoist()
	_build_landmarks()
	if not Engine.is_editor_hint():
		var world := get_parent().get_parent()
		if world == null or world.get_node_or_null("RoomActivityDirector") == null:
			call_deferred("activate_room_population")


func activate_room_population() -> void:
	if Engine.is_editor_hint() or population_loaded:
		return
	population_loaded = true
	_build_encounters()
	var infrastructure := Node2D.new()
	infrastructure.name = "Infrastructure"
	infrastructure.set_script(INFRASTRUCTURE)
	infrastructure.set("expansion", self)
	infrastructure.set("profile", "hub")
	add_child(infrastructure)


func _use_schematic_editor_preview() -> bool:
	if not Engine.is_editor_hint():
		return false
	var edited_root := get_tree().edited_scene_root
	return edited_root != null and edited_root != get_parent()


func _main_room(index: int) -> Rect2:
	return _room_rect(MAIN_CHAMBERS[index])


func _side_room(index: int) -> Rect2:
	return _room_rect(SIDE_CHAMBERS[index])


func _room_rect(data: Array) -> Rect2:
	return Rect2(Vector2(float(data[0]), float(data[2])), Vector2(float(data[1]) - float(data[0]), float(data[3]) - float(data[2])))


func _build_route_preview() -> void:
	for index in range(MAIN_CHAMBERS.size()):
		_preview_room("MineRoomPreview%d" % index, _main_room(index), TONE.lightened(0.28), 5.0, index)
		if index < MAIN_CHAMBERS.size() - 1:
			_preview_link("MineLinkPreview%d" % index, _main_room(index), _main_room(index + 1), TONE.lightened(0.4))
	for index in range(SIDE_CHAMBERS.size()):
		var branch := _side_room(index)
		var parent := _main_room(int(SIDE_CHAMBERS[index][4]))
		_preview_room("SideRoomPreview%d" % index, branch, Color(TONE, 0.72), 4.0, index + 10)
		_preview_link("SideLinkPreview%d" % index, parent, branch, Color(TONE, 0.72))
	_preview_link("HoistLoopPreview", _main_room(int(LOOP_LINK[0])), _main_room(int(LOOP_LINK[1])), Color(0.7, 0.93, 0.88, 0.7))


func _preview_room(node_name: String, room: Rect2, tint: Color, thickness: float, seed_offset: int = 0) -> void:
	var silhouette := _depth_chamber_silhouette(room, seed_offset)
	var closed_silhouette: PackedVector2Array = silhouette.duplicate()
	closed_silhouette.append(silhouette[0])
	var outline := Line2D.new()
	outline.name = node_name
	outline.width = thickness
	outline.default_color = tint
	outline.points = closed_silhouette
	add_child(outline)
	var floor_line := Line2D.new()
	floor_line.name = node_name + "Floor"
	floor_line.width = 13.0
	floor_line.default_color = Color(tint.r, tint.g, tint.b, minf(1.0, tint.a + 0.16))
	floor_line.points = PackedVector2Array([Vector2(room.position.x + 12.0, room.end.y - 4.0), Vector2(room.end.x - 12.0, room.end.y - 4.0)])
	add_child(floor_line)


func _preview_link(node_name: String, a: Rect2, b: Rect2, tint: Color) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.width = 5.0
	line.default_color = tint
	var overlap_left := maxf(a.position.x, b.position.x)
	var overlap_right := minf(a.end.x, b.end.x)
	if overlap_right > overlap_left:
		var x := (overlap_left + overlap_right) * 0.5
		line.points = PackedVector2Array([Vector2(x, a.end.y), Vector2(x, b.end.y)])
	else:
		var from := Vector2(a.position.x if b.end.x <= a.position.x else a.end.x, a.end.y - 60.0)
		var to := Vector2(b.end.x if b.end.x <= a.position.x else b.position.x, b.end.y - 60.0)
		line.points = PackedVector2Array([from, Vector2(to.x, from.y), to])
	add_child(line)


func _build_depth() -> void:
	for index in range(MAIN_CHAMBERS.size()):
		_draw_room_backdrop("MineChamber%d" % index, _main_room(index), index)
	for index in range(SIDE_CHAMBERS.size()):
		_draw_room_backdrop("SideCave%d" % index, _side_room(index), index + 10)
	for index in range(MAIN_CHAMBERS.size() - 1):
		_draw_link_backdrop("MineShaft%d" % index, _main_room(index), _main_room(index + 1))
	for index in range(SIDE_CHAMBERS.size()):
		_draw_link_backdrop("SideTunnel%d" % index, _main_room(int(SIDE_CHAMBERS[index][4])), _side_room(index))
	_draw_link_backdrop("BrokenHoistVoid", _main_room(int(LOOP_LINK[0])), _main_room(int(LOOP_LINK[1])))


func _draw_room_backdrop(prefix: String, room: Rect2, seed_offset: int) -> void:
	_poly(prefix + "Backdrop", _depth_chamber_silhouette(room, seed_offset), Color(0.02, 0.055, 0.095), -9)
	# Layered strata and old timber frames give the large chambers readable
	# scale. They are scenery, not extra collision or giant blocking pillars.
	for band in range(2):
		var band_y := room.position.y + 78.0 + float(band) * 86.0
		if band_y >= room.end.y - 35.0:
			continue
		var stratum := Line2D.new()
		stratum.name = prefix + "Stratum%d" % band
		stratum.z_index = -7
		stratum.width = 3.0
		stratum.default_color = Color(0.12, 0.32, 0.42, 0.34)
		stratum.points = PackedVector2Array([
			Vector2(room.position.x + 28.0, band_y),
			Vector2(lerpf(room.position.x, room.end.x, 0.34), band_y - 12.0),
			Vector2(lerpf(room.position.x, room.end.x, 0.68), band_y + 9.0),
			Vector2(room.end.x - 28.0, band_y - 5.0),
		])
		add_child(stratum)
	var support_count := clampi(int(room.size.x / 560.0), 2, 5)
	for support in range(support_count):
		var support_x := room.position.x + 120.0 + float(support) * (room.size.x - 240.0) / float(maxi(1, support_count - 1))
		var top_y := room.position.y + 34.0 + float((support * 37 + seed_offset * 19) % 38)
		_poly(prefix + "Support%d" % support, PackedVector2Array([
			Vector2(support_x - 22.0, room.end.y), Vector2(support_x - 15.0, top_y),
			Vector2(support_x + 18.0, top_y), Vector2(support_x + 25.0, room.end.y),
		]), Color(0.075, 0.17, 0.21, 0.76), -6)
		_poly(prefix + "Brace%d" % support, PackedVector2Array([
			Vector2(support_x - 72.0, top_y), Vector2(support_x + 72.0, top_y),
			Vector2(support_x + 66.0, top_y + 17.0), Vector2(support_x - 66.0, top_y + 17.0),
		]), Color(0.11, 0.26, 0.29, 0.72), -5)
	var count := clampi(int(room.size.x / 310.0), 3, 8)
	for index in range(count):
		var x := room.position.x + 70.0 + float(index) * (room.size.x - 140.0) / float(maxi(1, count - 1))
		var height := 55.0 + float((index * 37 + seed_offset * 29) % 125)
		_poly(prefix + "Crystal%d" % index, PackedVector2Array([Vector2(x - 32, room.end.y), Vector2(x, room.end.y - height), Vector2(x + 28, room.end.y)]), TONE.darkened(0.39), -6)
		if index % 2 == 0:
			_poly(prefix + "OreGlow%d" % index, PackedVector2Array([Vector2(x - 9.0, room.end.y - 14.0), Vector2(x, room.end.y - height * 0.58), Vector2(x + 10.0, room.end.y - 14.0)]), Color(0.22, 0.72, 0.76, 0.38), -4)
	_preview_room(prefix + "Outline", room, Color(TONE.r, TONE.g, TONE.b, 0.3), 3.0, seed_offset)


func _depth_chamber_silhouette(room: Rect2, seed_offset: int) -> PackedVector2Array:
	var left := room.position.x
	var right := room.end.x
	var top := room.position.y
	var bottom := room.end.y
	var seed := 53 + seed_offset * 47
	return PackedVector2Array([
		Vector2(left, bottom), Vector2(left - 18.0, bottom - 83.0),
		Vector2(left + 31.0 + float(seed % 34), top + 94.0 + float(seed % 41)),
		Vector2(left + room.size.x * 0.20, top + 18.0 + float((seed * 3) % 51)),
		Vector2(left + room.size.x * 0.43, top + 4.0 + float((seed * 5) % 45)),
		Vector2(left + room.size.x * 0.66, top + 39.0 + float((seed * 7) % 47)),
		Vector2(left + room.size.x * 0.84, top + 13.0 + float((seed * 11) % 56)),
		Vector2(right - 28.0 - float(seed % 39), top + 82.0 + float((seed * 13) % 39)),
		Vector2(right + 18.0, bottom - 88.0), Vector2(right, bottom),
	])


func _draw_link_backdrop(node_name: String, a: Rect2, b: Rect2) -> void:
	var overlap_left := maxf(a.position.x, b.position.x)
	var overlap_right := minf(a.end.x, b.end.x)
	if overlap_right > overlap_left:
		var x := (overlap_left + overlap_right) * 0.5
		var top := minf(a.end.y, b.end.y) - 35.0
		var bottom := maxf(a.end.y, b.end.y) + 25.0
		_poly(node_name, PackedVector2Array([Vector2(x - 140, top), Vector2(x + 140, top), Vector2(x + 140, bottom), Vector2(x - 140, bottom)]), Color(0.02, 0.055, 0.095), -9)
	else:
		var left := minf(a.end.x, b.end.x)
		var right := maxf(a.position.x, b.position.x)
		var y := minf(a.end.y, b.end.y)
		_poly(node_name, PackedVector2Array([Vector2(left, y - 215), Vector2(right, y - 215), Vector2(right, y + 25), Vector2(left, y + 25)]), Color(0.02, 0.055, 0.095), -9)


func _build_route() -> void:
	var openings: Dictionary = {}
	for index in range(MAIN_CHAMBERS.size()):
		openings["m%d" % index] = []
	for index in range(SIDE_CHAMBERS.size()):
		openings["s%d" % index] = []
	for index in range(MAIN_CHAMBERS.size() - 1):
		_register_opening(openings, "m%d" % index, _main_room(index), "m%d" % (index + 1), _main_room(index + 1))
	for index in range(SIDE_CHAMBERS.size()):
		var parent := int(SIDE_CHAMBERS[index][4])
		_register_opening(openings, "m%d" % parent, _main_room(parent), "s%d" % index, _side_room(index))
	_register_opening(openings, "m%d" % int(LOOP_LINK[0]), _main_room(int(LOOP_LINK[0])), "m%d" % int(LOOP_LINK[1]), _main_room(int(LOOP_LINK[1])))
	for index in range(MAIN_CHAMBERS.size()):
		_build_floor("MineRoom%d" % index, _main_room(index), openings["m%d" % index], TONE.darkened(0.2))
	for index in range(SIDE_CHAMBERS.size()):
		_build_floor("SideRoom%d" % index, _side_room(index), openings["s%d" % index], TONE.lightened(0.08))
	for index in range(MAIN_CHAMBERS.size() - 1):
		_build_connection("MineLink%d" % index, _main_room(index), _main_room(index + 1), TONE)
	for index in range(SIDE_CHAMBERS.size()):
		_build_connection("SideLink%d" % index, _main_room(int(SIDE_CHAMBERS[index][4])), _side_room(index), TONE)
	_build_connection("HoistLoop", _main_room(int(LOOP_LINK[0])), _main_room(int(LOOP_LINK[1])), TONE.lightened(0.18))
	_rect("WestBoundary", Vector2(WEST, -175.0), Vector2(16.0, 2200.0), TONE.darkened(0.62))


func _register_opening(openings: Dictionary, key_a: String, a: Rect2, key_b: String, b: Rect2) -> void:
	var overlap_left := maxf(a.position.x, b.position.x)
	var overlap_right := minf(a.end.x, b.end.x)
	if overlap_right <= overlap_left or absf(a.end.y - b.end.y) < 100.0:
		return
	var x := (overlap_left + overlap_right) * 0.5
	var upper_key := key_a if a.end.y < b.end.y else key_b
	(openings[upper_key] as Array).append(x)


func _build_floor(prefix: String, room: Rect2, raw_openings: Array, tint: Color) -> void:
	var room_openings: Array = raw_openings.duplicate()
	room_openings.sort()
	var cursor := room.position.x
	var segment := 0
	for value in room_openings:
		var opening := float(value)
		var stop := maxf(cursor, opening - 135.0)
		if stop - cursor > 30.0:
			_rect(prefix + "Floor%d" % segment, Vector2((cursor + stop) * 0.5, room.end.y), Vector2(stop - cursor, 18.0), tint)
			segment += 1
		cursor = minf(room.end.x, opening + 135.0)
	if room.end.x - cursor > 30.0:
		_rect(prefix + "Floor%d" % segment, Vector2((cursor + room.end.x) * 0.5, room.end.y), Vector2(room.end.x - cursor, 18.0), tint)


func _build_connection(prefix: String, a: Rect2, b: Rect2, tint: Color) -> void:
	var overlap_left := maxf(a.position.x, b.position.x)
	var overlap_right := minf(a.end.x, b.end.x)
	if overlap_right > overlap_left and absf(a.end.y - b.end.y) >= 100.0:
		var x := (overlap_left + overlap_right) * 0.5
		var upper := minf(a.end.y, b.end.y)
		var lower := maxf(a.end.y, b.end.y)
		var upper_room := a if a.end.y < b.end.y else b
		# A narrow overlap can leave floor on only the right of the mouth.
		# The top landing must face that surviving floor, not the empty left edge.
		var top_side := 1.0 if x - 135.0 - upper_room.position.x <= 30.0 else -1.0
		var step_count := maxi(1, int(ceil((lower - upper) / 58.0)) - 1)
		for step in range(step_count):
			var fraction := float(step + 1) / float(step_count + 1)
			var offset := top_side * (62.0 if step % 2 == 0 else -62.0)
			_rect(prefix + "Step%d" % step, Vector2(x + offset, lerpf(upper, lower, fraction)), Vector2(136.0, 11.0), tint.lightened(0.2), true)
	else:
		var from_x := a.end.x if b.position.x >= a.end.x else b.end.x
		var to_x := b.position.x if b.position.x >= a.end.x else a.position.x
		var left := minf(from_x, to_x)
		var right := maxf(from_x, to_x)
		var y := minf(a.end.y, b.end.y)
		if right - left > 20.0:
			_rect(prefix + "TunnelFloor", Vector2((left + right) * 0.5, y), Vector2(right - left + 20.0, 18.0), tint.lightened(0.1))


func _build_landmarks() -> void:
	var dressing := Node2D.new()
	dressing.name = "FieldDressing"
	dressing.set_script(FIELD_DRESSING)
	dressing.set("region", "shaft")
	add_child(dressing)
	var names := ["LOWER GALLERY", "PUMP HALL", "BROKEN HOIST", "UPPER RESERVOIR", "WARDEN PASSAGE"]
	for index in range(MAIN_CHAMBERS.size()):
		var room := _main_room(index)
		_label("RoomSign%d" % index, names[index], room.position + Vector2(55, 48), 330, 12, TONE.lightened(0.48))
		var count := clampi(int(room.size.x / 260.0), 3, 8)
		for growth in range(count):
			var x := room.position.x + 65.0 + float(growth) * (room.size.x - 130.0) / float(maxi(1, count - 1))
			var h := 24.0 + float((index * 29 + growth * 17) % 55)
			_poly("Growth%d_%d" % [index, growth], PackedVector2Array([Vector2(x - 10, room.end.y - 8), Vector2(x, room.end.y - h), Vector2(x + 10, room.end.y - 8)]), Color(0.26, 0.79, 0.8, 0.57), -1)
	var warden := _main_room(4)
	_poly("WardenThreshold", PackedVector2Array([Vector2(-235.0, warden.end.y - 9.0), Vector2(-235.0, warden.end.y - 150.0), Vector2(-190.0, warden.end.y - 184.0), Vector2(-145.0, warden.end.y - 150.0), Vector2(-145.0, warden.end.y - 9.0)]), TONE.lightened(0.12), -1)
	_label("WardenSign", "WARDEN ANTECHAMBER", Vector2(-365.0, warden.end.y - 208.0), 285.0, 12, TONE.lightened(0.6))


func _build_broken_hoist() -> void:
	var lower := _main_room(1)
	var upper := _main_room(3)
	var center_x := (maxf(lower.position.x, upper.position.x) + minf(lower.end.x, upper.end.x)) * 0.5
	var top_y := upper.position.y + 35.0
	var cable := Line2D.new()
	cable.name = "BrokenHoistCable"
	cable.z_index = -2
	cable.width = 5.0
	cable.default_color = Color(0.31, 0.52, 0.55, 0.58)
	cable.points = PackedVector2Array([Vector2(center_x - 54, lower.end.y + 2), Vector2(center_x - 39, top_y), Vector2(center_x + 41, top_y), Vector2(center_x + 61, lower.end.y + 2)])
	add_child(cable)
	for pulley in range(3):
		var center := Vector2(center_x - 52.0 + float(pulley) * 52.0, top_y + 15.0)
		var ring := Line2D.new()
		ring.name = "HoistPulley%d" % pulley
		ring.z_index = -1
		ring.width = 4.0
		ring.default_color = Color(0.39, 0.7, 0.68, 0.68)
		var points := PackedVector2Array()
		for point in range(17):
			var angle := TAU * float(point) / 16.0
			points.append(center + Vector2(cos(angle), sin(angle)) * 24.0)
		ring.points = points
		add_child(ring)
	for bay in range(3):
		var anchor := Vector2(center_x, lerpf(lower.end.y, upper.end.y, float(bay + 1) / 4.0))
		_rect("HoistServiceBay%dA" % bay, anchor + Vector2(-92, -25), Vector2(126, 12), TONE.lightened(0.19), true)
		_rect("HoistServiceBay%dB" % bay, anchor + Vector2(61, -72), Vector2(136, 12), TONE.lightened(0.25), true)
		_poly("HoistCounterweight%d" % bay, PackedVector2Array([anchor + Vector2(-73, -108), anchor + Vector2(73, -108), anchor + Vector2(58, -21), anchor + Vector2(-58, -21)]), Color(0.11, 0.31, 0.34, 0.84), -1)
	_label("HoistIdentity", "THE BROKEN HOIST - OPTIONAL CLIMB", Vector2(center_x - 245, lower.end.y - 125), 490, 12, TONE.lightened(0.58))


func _patrol_point(room_index: int, index: int, clearance: float) -> Vector2:
	# Spread the trio across actual walkable floor, not across shaft openings.
	# Clamping three chamber fractions to the nearest floor can stack enemies.
	var spans: Array[Rect2] = []
	var total := 0.0
	for child in get_children():
		if not child is StaticBody2D or not String(child.name).begins_with("MineRoom%dFloor" % room_index):
			continue
		var shape := child.get_node("CollisionShape2D").shape as RectangleShape2D
		var usable := shape.size.x - 180.0
		if usable <= 0:
			continue
		spans.append(Rect2(child.position.x - shape.size.x * 0.5 + 90.0, child.position.y - clearance, usable, 0))
		total += usable
	assert(not spans.is_empty(), "Missing Shaft patrol floor")
	spans.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	var offset := total * float(index) / 2.0
	for span in spans:
		if offset <= span.size.x:
			return span.position + Vector2(offset, 0)
		offset -= span.size.x
	return spans.back().end


func _build_encounters() -> void:
	for room_index in range(MAIN_CHAMBERS.size()):
		var room := _main_room(room_index)
		for index in range(3):
			var kind := (room_index + index) % 3
			var foe: Node2D = (WISP if kind == 0 else (CRAWLER if kind == 1 else SENTRY)).instantiate()
			foe.name = "DeepPatrol%02d_%02d" % [room_index, index]
			foe.position = _patrol_point(room_index, index, 72.0 if kind == 0 else 31.0)
			foe.set("zone_id", "sunken_shaft")
			add_child(foe)
		var crate := CRATE.instantiate()
		crate.name = "DeepCrate%02d" % room_index
		crate.position = FLOOR_PLACEMENT.on_floor(self, "MineRoom%dFloor" % room_index, room.get_center().x, 27.0, 40.0)
		crate.empty_drop_chance = 0.28
		crate.item_drop_chance = 0.24
		crate.common_item_ids = PackedStringArray(["iron_fragment", "healing_herb", "ether_dust"])
		add_child(crate)
	for index in range(SIDE_CHAMBERS.size()):
		var room := _side_room(index)
		var guard := SENTRY.instantiate() as Node2D
		guard.name = "SideCaveGuard%d" % index
		guard.position = FLOOR_PLACEMENT.on_floor(self, "SideRoom%dFloor" % index, room.get_center().x, 31.0, 125.0)
		guard.set("zone_id", "sunken_shaft")
		add_child(guard)
		var alcove_crate := CRATE.instantiate()
		alcove_crate.name = "SideCaveCrate%d" % index
		alcove_crate.position = FLOOR_PLACEMENT.on_floor(self, "SideRoom%dFloor" % index, room.position.x + 150.0, 27.0, 40.0)
		alcove_crate.empty_drop_chance = 0.38
		alcove_crate.item_drop_chance = 0.23
		add_child(alcove_crate)
	for index in range(4):
		var creature := NEUTRAL.instantiate()
		creature.name = "DeepGrazer%d" % index
		var room := _main_room(index)
		creature.position = FLOOR_PLACEMENT.on_floor(self, "MineRoom%dFloor" % index, room.position.x + 95.0, 30.0, 100.0)
		creature.creature_name = "Cave Grazer"
		creature.zone_id = "sunken_shaft"
		creature.start_resting = index == 0
		creature.passive_tint = TONE.lightened(0.36)
		add_child(creature)
	var cache := CACHE.instantiate()
	cache.name = "DeepCuttingCache"
	cache.position = FLOOR_PLACEMENT.on_floor(self, "SideRoom2Floor", _side_room(2).get_center().x, 33.0, 40.0)
	cache.cache_id = "shaft_deep_cutting"
	cache.cache_name = "Deep Cutting Reliquary"
	cache.gold_reward = 38
	cache.reward_item_id = "iron_fragment"
	add_child(cache)
	var bloom := BLOOM.instantiate()
	bloom.name = "DeepBloom"
	bloom.position = FLOOR_PLACEMENT.on_floor(self, "SideRoom0Floor", _side_room(0).position.x + 220.0, 31.0, 40.0)
	add_child(bloom)
	var hoist_lower := _main_room(1)
	var hoist_upper := _main_room(3)
	var hoist_x := (maxf(hoist_lower.position.x, hoist_upper.position.x) + minf(hoist_lower.end.x, hoist_upper.end.x)) * 0.5
	for index in range(3):
		var sentry := SENTRY.instantiate() as Node2D
		sentry.name = "HoistBaySentry%d" % index
		sentry.position = Vector2(hoist_x + 61.0, lerpf(hoist_lower.end.y, hoist_upper.end.y, float(index + 1) / 4.0) - 103.0)
		sentry.set("zone_id", "sunken_shaft")
		add_child(sentry)


func _rect(node_name: String, at: Vector2, size: Vector2, tint: Color, one_way: bool = false) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = at
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = tint
	visual.polygon = PackedVector2Array([Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x * 0.5, -size.y * 0.5), Vector2(size.x * 0.5, size.y * 0.5), Vector2(-size.x * 0.5, size.y * 0.5)])
	body.add_child(visual)
	add_child(body)


func _poly(node_name: String, points: PackedVector2Array, tint: Color, layer: int) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.z_index = layer
	polygon.color = tint
	polygon.polygon = points
	add_child(polygon)


func _label(node_name: String, words: String, at: Vector2, width: float, size: int, tint: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.size = Vector2(width, 28.0)
	label.text = words
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
