@tool
extends Node2D

# Large expedition rooms are authored as chamber graphs. Broad traversable
# rooms are connected by narrow shafts, side tunnels and optional loops; only
# the shafts use small jump ledges.
const DOOR_SCENE: PackedScene = preload("res://RoomDoor.tscn")
const LAMP_SCENE: PackedScene = preload("res://Checkpoint.tscn")
const CACHE_SCENE: PackedScene = preload("res://ResonanceCache.tscn")
const CRATE_SCENE: PackedScene = preload("res://DestructibleCrate.tscn")
const NEUTRAL_SCENE: PackedScene = preload("res://NeutralCreature.tscn")
const VENT_SCENE: PackedScene = preload("res://HeatVent.tscn")
const ROOT_SNARE_SCENE: PackedScene = preload("res://RootSnare.tscn")
const LIFT_SCENE: PackedScene = preload("res://ShaftLift.tscn")
const INFRASTRUCTURE := preload("res://ShaftInfrastructure.gd")
const ECHO_OPERATIONS := preload("res://EchoFieldOperations.gd")
const EMBERSPINE_OPERATIONS := preload("res://EmberspineOperations.gd")
const RAMPART_OPERATIONS := preload("res://RampartFieldOperations.gd")
const FLOOR_PLACEMENT := preload("res://RouteFloorPlacement.gd")
const ENEMIES := {
	"crawler": preload("res://ShaftCrawler.tscn"),
	"wisp": preload("res://ShaftWisp.tscn"),
	"shaft_sentry": preload("res://ShaftSentry.tscn"),
	"shade": preload("res://EchoShade.tscn"),
	"fiend": preload("res://AshFiend.tscn"),
	"ash_sentry": preload("res://AshSentry.tscn"),
	"stalker": preload("res://RootStalker.tscn"),
}
const ROUTES := {
	"shaft": {
		"id": "shaft_drift", "title": "THE DRIFTWORKS", "subtitle": "Follow the descending pumps; the far lift returns to daylight",
		"width": 7060.0, "hub_id": "shaft_hollow", "hub_marker": "shaft_drift_return", "entry": "shaft_drift_entry",
		"next_id": "shaft_crossing", "next_marker": "crossing_hollow_entry", "exit_label": "DROWNED CROSSING",
		"zone": "sunken_shaft", "color": Color(0.12, 0.42, 0.46), "dark": Color(0.025, 0.078, 0.12),
		"ridge": [0, -33, -67, -29, 18, 58, 23, -17, -58, -23, 0],
		"bend": [0, 17, -12, 20, -8, 14, 0], "seed": 1,
		"foes": ["crawler", "wisp", "crawler", "shaft_sentry", "wisp", "crawler", "shaft_sentry"],
		"material": "iron_fragment",
	},
	"echo": {
		"id": "echo_depths", "title": "THE RESONANT DEPTHS", "subtitle": "Six answering galleries spiral towards the archive",
		"width": 7340.0, "hub_id": "echo_gallery", "hub_marker": "echo_depths_return", "entry": "echo_depths_entry",
		"next_id": "echo_archive", "next_marker": "archive_entry", "exit_label": "PRISM ARCHIVE",
		"zone": "echo_grotto", "color": Color(0.25, 0.57, 0.72), "dark": Color(0.025, 0.055, 0.13),
		"ridge": [0, 36, 67, 22, -24, -61, -21, 29, 64, 25, 0],
		"bend": [0, -13, 20, -17, 16, -10, 0], "seed": 3,
		"foes": ["shade", "wisp", "shade", "shaft_sentry", "shade", "wisp", "shade"],
		"material": "ether_dust",
	},
	"ash": {
		"id": "ash_emberspine", "title": "THE EMBERSPINE", "subtitle": "Circle the kilns and descend the cooling spine",
		"width": 7180.0, "hub_id": "ash_causeway", "hub_marker": "ash_emberspine_return", "entry": "ash_emberspine_entry",
		"next_id": "ash_forge", "next_marker": "ash_forge_entry", "exit_label": "CINDER FORGE",
		"zone": "ashen_bastion", "color": Color(0.69, 0.29, 0.16), "dark": Color(0.12, 0.042, 0.05),
		"ridge": [0, -27, 19, 60, 24, -22, -65, -27, 20, 49, 0],
		"bend": [0, 20, -17, 15, -13, 18, 0], "seed": 5,
		"foes": ["fiend", "ash_sentry", "fiend", "ash_sentry", "fiend", "fiend", "ash_sentry"],
		"material": "iron_fragment",
	},
	"starfall": {
		"id": "starfall_ramparts", "title": "THE BROKEN RAMPARTS", "subtitle": "Cross the fallen watches to the silent gate",
		"width": 7660.0, "hub_id": "starfall_outskirts", "hub_marker": "starfall_ramparts_return", "entry": "starfall_ramparts_entry",
		"next_id": "starfall_silent_gate", "next_marker": "starfall_silent_entry", "exit_label": "SILENT GATE",
		"zone": "starfall_reach", "color": Color(0.47, 0.43, 0.68), "dark": Color(0.04, 0.048, 0.1),
		"ridge": [0, 27, 70, 31, -20, -57, -16, 32, 65, 23, 0],
		"bend": [0, -18, 14, -20, 11, -16, 0], "seed": 7,
		"foes": ["stalker", "shade", "stalker", "ash_sentry", "shade", "stalker", "ash_sentry"],
		"material": "resonance_shard",
	},
}
const CHAMBER_LAYOUTS := {
	"shaft": {
		"main": [
			[0.00, 0.31, 355.0, 680.0], [0.23, 0.45, 755.0, 1080.0],
			[0.37, 0.62, 1155.0, 1480.0], [0.54, 0.81, 755.0, 1080.0],
			[0.72, 1.00, 355.0, 680.0], [0.58, 0.79, -45.0, 280.0],
			[0.32, 0.65, -445.0, -120.0], [0.05, 0.39, -45.0, 280.0],
		],
		"branches": [
			[0.02, 0.20, 755.0, 1080.0, 1], [0.64, 0.86, 1155.0, 1480.0, 2],
			[0.82, 0.99, -45.0, 280.0, 5], [0.07, 0.29, -445.0, -120.0, 6],
		],
		"loop": [0, 7],
	},
	"echo": {
		"main": [
			[0.00, 0.27, 355.0, 680.0], [0.19, 0.48, 755.0, 1080.0],
			[0.40, 0.69, 395.0, 720.0], [0.61, 0.87, 795.0, 1120.0],
			[0.79, 1.00, 1195.0, 1520.0], [0.52, 0.83, 1595.0, 1920.0],
			[0.20, 0.59, 1995.0, 2320.0], [0.00, 0.28, 2395.0, 2720.0],
		],
		"branches": [
			[0.06, 0.20, -45.0, 280.0, 0], [0.49, 0.62, -5.0, 320.0, 2],
			[0.87, 0.99, 795.0, 1120.0, 3], [0.29, 0.48, 2395.0, 2720.0, 7],
		],
		"loop": [2, 5],
	},
	"ash": {
		"main": [
			[0.00, 0.35, 355.0, 680.0], [0.28, 0.62, -45.0, 280.0],
			[0.55, 0.88, 355.0, 680.0], [0.72, 1.00, 755.0, 1080.0],
			[0.46, 0.79, 1155.0, 1480.0], [0.18, 0.54, 755.0, 1080.0],
			[0.02, 0.25, 1155.0, 1480.0], [0.18, 0.69, 1555.0, 1880.0],
		],
		"branches": [
			[0.04, 0.18, -45.0, 280.0, 0], [0.58, 0.76, -445.0, -120.0, 1],
			[0.82, 0.99, 1155.0, 1480.0, 3], [0.01, 0.16, 1555.0, 1880.0, 6],
		],
		"loop": [1, 5],
	},
	"starfall": {
		"main": [
			[0.00, 0.28, 355.0, 680.0], [0.21, 0.50, 755.0, 1080.0],
			[0.43, 0.70, 355.0, 680.0], [0.62, 0.92, -45.0, 280.0],
			[0.75, 1.00, 355.0, 680.0], [0.55, 0.82, 755.0, 1080.0],
			[0.30, 0.61, 1155.0, 1480.0], [0.02, 0.37, 755.0, 1080.0],
		],
		"branches": [
			[0.04, 0.18, -45.0, 280.0, 0], [0.47, 0.60, -445.0, -120.0, 2],
			[0.83, 0.99, -445.0, -120.0, 3], [0.02, 0.20, 1155.0, 1480.0, 7],
		],
		"loop": [1, 6],
	},
}
const ROOM_NAMES := {
	"shaft": ["INTAKE WORKS", "DROWNED PUMPS", "LOWER SUMP", "PRESSURE HALL", "EAST TURBINES", "HOIST CROWN", "UPPER ENGINE", "OLD OUTFLOW"],
	"echo": ["LISTENING MOUTH", "WHISPER GALLERY", "PRISM RISE", "ANSWERING HALL", "FAR CHOIR", "SUNKEN REFRAIN", "MEMORY BASIN", "DEEP ARCHIVE"],
	"ash": ["CINDER MOUTH", "UPPER KILN", "BELLOWS WALK", "FURNACE RIM", "SLAG DESCENT", "COOLING HALL", "ASHEN PIT", "EMBER HEART"],
	"starfall": ["FALLEN WATCH", "LOWER WALL", "MOON BRIDGE", "HIGH BATTLEMENT", "EAST TOWER", "ROOTED WALK", "BROKEN COURT", "WESTERN GATE"],
}

@export_enum("shaft", "echo", "ash", "starfall") var region: String = "shaft"

var route: Dictionary
const FLOOR_Y := 680.0
const TIER_COUNT := 8
const SPAN_COUNT := 11
var population_loaded := false


func _ready() -> void:
	route = ROUTES.get(region, ROUTES["shaft"])
	if _use_schematic_editor_preview():
		_build_backdrop()
		_build_route_preview()
		_build_landmarks()
		_build_field_dressing()
		return
	_build_backdrop()
	_build_terrain()
	_build_landmarks()
	_build_interactions()
	_build_return_lift()
	_build_field_dressing()
	if Engine.is_editor_hint():
		return
	if not _uses_world_population_streaming():
		activate_room_population()


func _build_field_dressing() -> void:
	var dressing := Node2D.new()
	dressing.set_script(preload("res://StarfallRouteDressing.gd") if region == "starfall" else preload("res://ExpeditionFieldDressing.gd"))
	dressing.name = "FieldDressing"
	dressing.set("region", {"shaft": "drift", "echo": "depths", "ash": "emberspine", "starfall": "StarfallRamparts"}[region])
	add_child(dressing)


func _uses_world_population_streaming() -> bool:
	return get_parent() != null and get_parent().get_node_or_null("RoomActivityDirector") != null


func activate_room_population() -> void:
	if Engine.is_editor_hint() or population_loaded:
		return
	_build_population_props()
	_build_encounters()
	population_loaded = true
	if region == "shaft":
		var infrastructure := Node2D.new()
		infrastructure.name = "Infrastructure"
		infrastructure.set_script(INFRASTRUCTURE)
		infrastructure.set("expansion", self)
		infrastructure.set("profile", "drift")
		add_child(infrastructure)
	if region == "echo":
		var operations := Node2D.new()
		operations.name = "FieldOperations"
		operations.set_script(ECHO_OPERATIONS)
		operations.set("route", self)
		operations.set("route_id", "depths")
		add_child(operations)
	if region == "ash":
		var operations := Node2D.new()
		operations.name = "FieldOperations"
		operations.set_script(EMBERSPINE_OPERATIONS)
		operations.set("route", self)
		add_child(operations)
	if region == "starfall":
		var operations := Node2D.new()
		operations.name = "FieldOperations"
		operations.set_script(RAMPART_OPERATIONS)
		operations.set("route", self)
		add_child(operations)


func is_population_loaded() -> bool:
	return population_loaded


func _main_data() -> Array:
	return CHAMBER_LAYOUTS[region]["main"]


func _branch_data() -> Array:
	return CHAMBER_LAYOUTS[region]["branches"]


func _room_rect(data: Array) -> Rect2:
	var width: float = route["width"]
	return Rect2(Vector2(float(data[0]) * width, float(data[2])), Vector2((float(data[1]) - float(data[0])) * width, float(data[3]) - float(data[2])))


func _main_rect(index: int) -> Rect2:
	return _room_rect(_main_data()[index])


func _branch_rect(index: int) -> Rect2:
	return _room_rect(_branch_data()[index])


func _path() -> Array:
	var result: Array = []
	for index in range(TIER_COUNT):
		result.append(_main_rect(index).get_center().x)
	return result


func _use_schematic_editor_preview() -> bool:
	if not Engine.is_editor_hint():
		return false
	var edited_root := get_tree().edited_scene_root
	return edited_root != null and edited_root != get_parent()


func _build_route_preview() -> void:
	for index in range(TIER_COUNT):
		_preview_room("MainRoomPreview%d" % index, _main_rect(index), (route["color"] as Color).lightened(0.2), 5.0, index)
		if index < TIER_COUNT - 1:
			_preview_link("MainLinkPreview%d" % index, _main_rect(index), _main_rect(index + 1), (route["color"] as Color).lightened(0.35))
	for index in range(_branch_data().size()):
		var branch := _branch_rect(index)
		var parent := _main_rect(int(_branch_data()[index][4]))
		_preview_room("BranchRoomPreview%d" % index, branch, Color(route["color"], 0.72), 4.0, index + 17)
		_preview_link("BranchLinkPreview%d" % index, parent, branch, Color(route["color"], 0.72))
	var loop_data: Array = CHAMBER_LAYOUTS[region]["loop"]
	_preview_link("LoopLinkPreview", _main_rect(int(loop_data[0])), _main_rect(int(loop_data[1])), Color(0.72, 0.92, 0.9, 0.62))


func _preview_room(node_name: String, room: Rect2, tint: Color, thickness: float, seed_offset: int = 0) -> void:
	var silhouette := _room_backdrop_silhouette(room, seed_offset)
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
	var link := Line2D.new()
	link.name = node_name
	link.width = 5.0
	link.default_color = tint
	var overlap_left := maxf(a.position.x, b.position.x)
	var overlap_right := minf(a.end.x, b.end.x)
	if overlap_right > overlap_left:
		var x := (overlap_left + overlap_right) * 0.5
		link.points = PackedVector2Array([Vector2(x, a.end.y), Vector2(x, b.end.y)])
	else:
		var from := Vector2(a.end.x if b.position.x > a.end.x else a.position.x, a.end.y - 55.0)
		var to := Vector2(b.position.x if b.position.x > a.end.x else b.end.x, b.end.y - 55.0)
		link.points = PackedVector2Array([from, Vector2(to.x, from.y), to])
	add_child(link)


func _tier_y(tier: int, span: int = 0) -> float:
	return _main_rect(tier).end.y


func _span_bounds(tier: int, span: int) -> Vector2:
	var room := _main_rect(tier)
	var stride := room.size.x / float(SPAN_COUNT)
	return Vector2(room.position.x + float(span) * stride, room.position.x + float(span + 1) * stride)


func _span_center(tier: int, span: int) -> Vector2:
	var bounds := _span_bounds(tier, span)
	return Vector2((bounds.x + bounds.y) * 0.5, _tier_y(tier, span))


func _supported_point(index: int, branch: bool, x: float, clearance: float = 33, margin: float = 125) -> Vector2:
	return FLOOR_PLACEMENT.on_floor(self, ("BranchRoom" if branch else "MainRoom") + str(index) + "Floor", x, clearance, margin)


func _build_backdrop() -> void:
	var tone: Color = route["color"]
	for index in range(TIER_COUNT):
		_draw_chamber_backdrop("MainChamber%d" % index, _main_rect(index), tone, index)
	for index in range(_branch_data().size()):
		_draw_chamber_backdrop("BranchChamber%d" % index, _branch_rect(index), tone.lightened(0.05), index + 10)
	for index in range(TIER_COUNT - 1):
		_draw_link_backdrop("MainShaft%d" % index, _main_rect(index), _main_rect(index + 1))
	for index in range(_branch_data().size()):
		_draw_link_backdrop("BranchPassage%d" % index, _main_rect(int(_branch_data()[index][4])), _branch_rect(index))
	var loop_data: Array = CHAMBER_LAYOUTS[region]["loop"]
	_draw_link_backdrop("OptionalLoop", _main_rect(int(loop_data[0])), _main_rect(int(loop_data[1])))


func _draw_chamber_backdrop(prefix: String, room: Rect2, tone: Color, seed_offset: int) -> void:
	_colored_polygon(prefix + "Backdrop", _room_backdrop_silhouette(room, seed_offset), route["dark"], -9)
	var count := clampi(int(room.size.x / 360.0), 3, 8)
	for index in range(count):
		var x := room.position.x + 90.0 + float(index) * (room.size.x - 180.0) / float(maxi(1, count - 1))
		var h := 75.0 + float((index * 41 + seed_offset * 29 + int(route["seed"]) * 13) % 155)
		match region:
			"shaft":
				_colored_polygon(prefix + "PumpRib%d" % index, PackedVector2Array([Vector2(x - 48, room.end.y), Vector2(x - 48, room.end.y - h), Vector2(x + 48, room.end.y - h), Vector2(x + 48, room.end.y)]), tone.darkened(0.65), -8)
				_colored_polygon(prefix + "PipeCap%d" % index, PackedVector2Array([Vector2(x - 68, room.end.y - h), Vector2(x + 68, room.end.y - h), Vector2(x + 68, room.end.y - h + 18), Vector2(x - 68, room.end.y - h + 18)]), tone.darkened(0.38), -7)
			"echo":
				_colored_polygon(prefix + "Prism%d" % index, PackedVector2Array([Vector2(x - 48, room.end.y), Vector2(x - 12, room.end.y - h), Vector2(x + 17, room.end.y - h - 48), Vector2(x + 52, room.end.y)]), tone.darkened(0.52), -8)
			"ash":
				_colored_polygon(prefix + "KilnArch%d" % index, PackedVector2Array([Vector2(x - 62, room.end.y), Vector2(x - 55, room.end.y - h), Vector2(x, room.end.y - h - 42), Vector2(x + 55, room.end.y - h), Vector2(x + 62, room.end.y)]), tone.darkened(0.61), -8)
			"starfall":
				_colored_polygon(prefix + "Ruin%d" % index, PackedVector2Array([Vector2(x - 58, room.end.y), Vector2(x - 43, room.end.y - h), Vector2(x - 4, room.end.y - h + 38), Vector2(x + 23, room.end.y - h - 25), Vector2(x + 57, room.end.y)]), tone.darkened(0.63), -8)
	_preview_room(prefix + "Outline", room, Color(tone.r, tone.g, tone.b, 0.30), 3.0, seed_offset)


func _room_backdrop_silhouette(room: Rect2, seed_offset: int) -> PackedVector2Array:
	var left := room.position.x
	var right := room.end.x
	var top := room.position.y
	var bottom := room.end.y
	var region_seed := int(route.get("seed", 1)) * 101 + seed_offset * 73
	var wall_inset := 18.0 + float(abs(region_seed) % 42)
	return PackedVector2Array([
		Vector2(left, bottom),
		Vector2(left - 15.0, bottom - 72.0),
		Vector2(left + wall_inset, top + 83.0 + float(abs(region_seed / 3) % 48)),
		Vector2(left + room.size.x * 0.19, top + 22.0 + float(abs(region_seed / 5) % 46)),
		Vector2(left + room.size.x * 0.41, top + 4.0 + float(abs(region_seed / 7) % 52)),
		Vector2(left + room.size.x * 0.63, top + 37.0 + float(abs(region_seed / 11) % 43)),
		Vector2(left + room.size.x * 0.82, top + 15.0 + float(abs(region_seed / 13) % 57)),
		Vector2(right - wall_inset, top + 74.0 + float(abs(region_seed / 17) % 42)),
		Vector2(right + 15.0, bottom - 76.0),
		Vector2(right, bottom),
	])


func _draw_link_backdrop(node_name: String, a: Rect2, b: Rect2) -> void:
	var overlap_left := maxf(a.position.x, b.position.x)
	var overlap_right := minf(a.end.x, b.end.x)
	if overlap_right > overlap_left:
		var x := (overlap_left + overlap_right) * 0.5
		var top := minf(a.end.y, b.end.y) - 45.0
		var bottom := maxf(a.end.y, b.end.y) + 20.0
		_colored_polygon(node_name, PackedVector2Array([Vector2(x - 145, top), Vector2(x + 145, top), Vector2(x + 145, bottom), Vector2(x - 145, bottom)]), route["dark"], -9)
	else:
		var left := minf(a.end.x, b.end.x)
		var right := maxf(a.position.x, b.position.x)
		var y := minf(a.end.y, b.end.y)
		_colored_polygon(node_name, PackedVector2Array([Vector2(left, y - 220), Vector2(right, y - 220), Vector2(right, y + 35), Vector2(left, y + 35)]), route["dark"], -9)


func _build_terrain() -> void:
	var width: float = route["width"]
	var tone: Color = route["color"]
	var openings: Dictionary = {}
	for index in range(TIER_COUNT):
		openings["m%d" % index] = []
	for index in range(_branch_data().size()):
		openings["b%d" % index] = []
	for index in range(TIER_COUNT - 1):
		_register_vertical_opening(openings, "m%d" % index, _main_rect(index), "m%d" % (index + 1), _main_rect(index + 1))
	for index in range(_branch_data().size()):
		var parent_index := int(_branch_data()[index][4])
		_register_vertical_opening(openings, "m%d" % parent_index, _main_rect(parent_index), "b%d" % index, _branch_rect(index))
	var loop_data: Array = CHAMBER_LAYOUTS[region]["loop"]
	_register_vertical_opening(openings, "m%d" % int(loop_data[0]), _main_rect(int(loop_data[0])), "m%d" % int(loop_data[1]), _main_rect(int(loop_data[1])))
	for index in range(TIER_COUNT):
		_build_chamber_floor("MainRoom%d" % index, _main_rect(index), openings["m%d" % index], tone.lightened(0.04 * float(index % 3)))
	for index in range(_branch_data().size()):
		_build_chamber_floor("BranchRoom%d" % index, _branch_rect(index), openings["b%d" % index], tone.lightened(0.18))
	for index in range(TIER_COUNT - 1):
		_build_link_terrain("MainLink%d" % index, _main_rect(index), _main_rect(index + 1), tone)
	for index in range(_branch_data().size()):
		_build_link_terrain("BranchLink%d" % index, _main_rect(int(_branch_data()[index][4])), _branch_rect(index), tone)
	_build_link_terrain("LoopLink", _main_rect(int(loop_data[0])), _main_rect(int(loop_data[1])), tone.lightened(0.15))
	var bottom := 3000.0
	_solid_rect("LeftBoundary", Vector2(-8, bottom * 0.5), Vector2(16, bottom + 500), tone.darkened(0.5))
	_solid_rect("RightBoundary", Vector2(width + 8, bottom * 0.5), Vector2(16, bottom + 500), tone.darkened(0.5))
	var final_room := _main_rect(TIER_COUNT - 1)
	_solid_rect("ReturnLiftLanding", Vector2(final_room.end.x - 230.0, final_room.end.y + 38.0), Vector2(390, 16), tone.lightened(0.22), true)


func _register_vertical_opening(openings: Dictionary, _key_a: String, a: Rect2, _key_b: String, b: Rect2) -> void:
	var overlap_left := maxf(a.position.x, b.position.x)
	var overlap_right := minf(a.end.x, b.end.x)
	if overlap_right <= overlap_left or absf(a.end.y - b.end.y) < 100.0:
		return
	var x := (overlap_left + overlap_right) * 0.5
	# Cut every floor crossed by the shaft, including overlapping galleries
	# and optional loops. A second chamber must not fill the opening back in.
	for key: String in openings:
		var index := int(key.substr(1))
		var crossing := _main_rect(index) if key.begins_with("m") else _branch_rect(index)
		if crossing.end.y >= minf(a.end.y, b.end.y) - 1 and crossing.end.y < maxf(a.end.y, b.end.y) - 1 and x + 135 > crossing.position.x and x - 135 < crossing.end.x:
			(openings[key] as Array).append(x)


func _build_chamber_floor(prefix: String, room: Rect2, raw_openings: Array, tone: Color) -> void:
	var room_openings: Array = raw_openings.duplicate()
	room_openings.sort()
	var cursor := room.position.x
	var segment := 0
	for opening_value in room_openings:
		var opening := float(opening_value)
		var stop := maxf(cursor, opening - 135.0)
		if stop - cursor > 30.0:
			_solid_rect(prefix + "Floor%d" % segment, Vector2((cursor + stop) * 0.5, room.end.y), Vector2(stop - cursor, 18.0), tone)
			segment += 1
		cursor = minf(room.end.x, opening + 135.0)
	if room.end.x - cursor > 30.0:
		_solid_rect(prefix + "Floor%d" % segment, Vector2((cursor + room.end.x) * 0.5, room.end.y), Vector2(room.end.x - cursor, 18.0), tone)


func _build_link_terrain(prefix: String, a: Rect2, b: Rect2, tone: Color) -> void:
	var overlap_left := maxf(a.position.x, b.position.x)
	var overlap_right := minf(a.end.x, b.end.x)
	if overlap_right > overlap_left and absf(a.end.y - b.end.y) >= 100.0:
		var x := (overlap_left + overlap_right) * 0.5
		var upper := minf(a.end.y, b.end.y)
		var lower := maxf(a.end.y, b.end.y)
		var step_count := maxi(1, int(ceil((lower - upper) / 58.0)) - 1)
		var step_width := 164.0 if region == "shaft" else (122.0 if region == "echo" else (184.0 if region == "ash" else 142.0))
		var rim_x := x
		var nearest := INF
		for body in get_children():
			if not body is StaticBody2D or not "Floor" in String(body.name) or absf(body.position.y - upper) > 1:
				continue
			var half: float = body.get_node("CollisionShape2D").shape.size.x * 0.5
			var candidate := clampf(x, body.position.x - half, body.position.x + half)
			if absf(candidate - x) < nearest:
				nearest = absf(candidate - x)
				rim_x = candidate
		assert(nearest < INF, "Expedition shaft has no supported upper landing: " + prefix)
		var side := -1.0 if rim_x < x else 1.0
		for step in range(step_count):
			var fraction := float(step + 1) / float(step_count + 1)
			var offset := side * (58.0 if region != "shaft" else 44.0) * (1.0 if step % 2 == 0 else -1.0)
			var left := x + offset - step_width * 0.5
			var right := x + offset + step_width * 0.5
			if step == 0:
				if side < 0:
					left = minf(left, rim_x + 32.0)
				else:
					right = maxf(right, rim_x - 32.0)
			_solid_rect(prefix + "ShaftStep%d" % step, Vector2((left + right) * 0.5, lerpf(upper, lower, fraction)), Vector2(right - left, 11), tone.lightened(0.2), true)
	else:
		var from_x := a.end.x if b.position.x >= a.end.x else b.end.x
		var to_x := b.position.x if b.position.x >= a.end.x else a.position.x
		var left := minf(from_x, to_x)
		var right := maxf(from_x, to_x)
		var y := minf(a.end.y, b.end.y)
		if right - left > 20.0:
			_solid_rect(prefix + "TunnelFloor", Vector2((left + right) * 0.5, y), Vector2(right - left + 20.0, 18.0), tone.lightened(0.1))
		else:
			_solid_rect(prefix + "PortalThreshold", Vector2((left + right) * 0.5, y), Vector2(72.0, 18.0), tone.lightened(0.1))


func _build_landmarks() -> void:
	var tone: Color = route["color"]
	var first_room := _main_rect(0)
	var final_room := _main_rect(TIER_COUNT - 1)
	_label("AreaTitle", route["title"], first_room.position + Vector2(120, 70), 520, 17, tone.lightened(0.55))
	_label("RouteHint", route["subtitle"], first_room.position + Vector2(120, 103), 650, 11, tone.lightened(0.35))
	_label("TopLiftHint", "RETURN LIFT LOCKED UNTIL THE FAR STATION", first_room.position + Vector2(330, 165), 470, 10, tone.lightened(0.31))
	_label("DeepExitSign", "FINAL PASSAGE  >  " + str(route["exit_label"]), Vector2(final_room.end.x - 620.0, final_room.end.y - 112.0), 560, 12, tone.lightened(0.58))
	_label("LowerLiftHint", "ACTIVATE RETURN LIFT HERE", Vector2(final_room.end.x - 560.0, final_room.end.y - 87.0), 390, 10, tone.lightened(0.34))
	if region != "starfall":
		# Keep route guidance above the new local shelters and reserve boards,
		# not across a resident's name or the machinery itself.
		get_node("DeepExitSign").position.y = final_room.end.y - 285
		get_node("LowerLiftHint").position.y = final_room.end.y - 255
	for tier in range(TIER_COUNT):
		var room := _main_rect(tier)
		_label("ChamberSign%d" % tier, str(ROOM_NAMES[region][tier]), room.position + Vector2(55, 55), 300, 12, tone.lightened(0.4))
		for index in range(8):
			var span := (index * 3 + tier * 2) % SPAN_COUNT
			var ground := _span_center(tier, span)
			var x := ground.x - 45.0 + float(index % 3) * 31.0
			var h := 16.0 + float((index * 13 + tier * 17) % 29)
			var stem := tone.darkened(0.12) if region in ["ash", "starfall"] else tone.lightened(0.12)
			_colored_polygon("Flora%d_%d" % [tier, index], PackedVector2Array([Vector2(x - 6, ground.y - 9), Vector2(x - 2, ground.y - h), Vector2(x + 1, ground.y - h - 8), Vector2(x + 7, ground.y - 9)]), stem, -1)
			_colored_polygon("FloraCap%d_%d" % [tier, index], PackedVector2Array([Vector2(x - 13, ground.y - h), Vector2(x, ground.y - h - 12), Vector2(x + 13, ground.y - h)]), tone.lightened(0.25), -1)
		for crystal in range(3):
			var anchor := _span_center(tier, crystal * 3 + 1)
			_colored_polygon("RouteCrystal%d_%d" % [tier, crystal], PackedVector2Array([anchor + Vector2(-16, -8), anchor + Vector2(0, -61 - float((tier + crystal) % 3) * 12), anchor + Vector2(16, -8)]), Color(tone.r, tone.g, tone.b, 0.72), -1)


func _build_interactions() -> void:
	var room_id: String = route["id"]
	var final_room := _main_rect(TIER_COUNT - 1)
	var entry := Marker2D.new()
	entry.name = "Entry"
	entry.position = Vector2(110, FLOOR_Y - 33.0)
	entry.add_to_group(route["entry"])
	add_child(entry)
	_door("LowerReturnDoor", Vector2(34, FLOOR_Y - 33.0), "RETURN PATH")
	var exit_door := _door("UpperShortcutDoor", Vector2(final_room.end.x - 45.0, final_room.end.y - 33.0), route["exit_label"])
	exit_door.target_marker_group = StringName(route["next_marker"])
	exit_door.target_room_id = route["next_id"]
	var lamp := LAMP_SCENE.instantiate()
	lamp.name = "TrailLamp"
	lamp.position = Vector2(245, FLOOR_Y - 33.0)
	lamp.lamp_id = room_id + "_lamp"
	lamp.lamp_name = str(route["title"]).capitalize() + " Lamp"
	lamp.room_id = room_id
	lamp.enemy_block_radius = 120.0
	add_child(lamp)
	_cache("MidCache", _supported_point(1, true, _branch_rect(1).get_center().x, 33, 40), room_id + "_mid", 35, route["material"])
	_cache("RimCache", _supported_point(3, true, _branch_rect(3).get_center().x, 33, 40), room_id + "_rim", 55, route["material"])


func _build_population_props() -> void:
	for index in range(16):
		var tier := index / 2
		var span := 2 if index % 2 == 0 else 7
		var ground := _span_center(tier, span)
		var crate := CRATE_SCENE.instantiate()
		crate.name = "SupplyCrate%d" % index
		crate.position = _supported_point(tier, false, ground.x + (-65.0 if index % 2 == 0 else 70.0), 31, 40)
		crate.empty_drop_chance = 0.28
		crate.item_drop_chance = 0.20
		crate.common_item_ids = PackedStringArray([route["material"], "healing_herb"])
		add_child(crate)
	for index in range(7):
		var ground := _span_center([0, 1, 2, 3, 5, 6, 7][index], [1, 4, 7, 3, 6, 8, 2][index])
		var creature := NEUTRAL_SCENE.instantiate()
		creature.name = "QuietGrazer%d" % index
		creature.position = _supported_point([0, 1, 2, 3, 5, 6, 7][index], false, ground.x + 55, 30)
		creature.creature_name = "Cinder Grazer" if region == "ash" else ("Dusk Moth" if region == "starfall" else ("Cave Grazer" if region == "shaft" else "Echo Moth"))
		creature.zone_id = route["zone"]
		creature.start_resting = index % 2 == 0
		creature.passive_tint = route["color"].lightened(0.34)
		add_child(creature)


func _build_encounters() -> void:
	for index in range(20):
		var tier := index % TIER_COUNT
		# Each pass through the eight chambers owns another part of the floor;
		# modulo-two span selection previously stacked up to three patrols.
		var span: int = [2, 5, 8][index / TIER_COUNT]
		var enemy_kind: String = route["foes"][index % route["foes"].size()]
		var enemy: Node2D = ENEMIES[enemy_kind].instantiate()
		enemy.name = "Patrol%d" % index
		enemy.position = _supported_point(tier, false, _span_center(tier, span).x, 103 if enemy_kind == "wisp" else 33)
		enemy.set("zone_id", route["zone"])
		if enemy_kind == "shade" or enemy_kind == "stalker":
			enemy.set("patrol_radius", 48.0)
		elif enemy_kind == "crawler":
			enemy.set("patrol_distance", 42.0)
		add_child(enemy)
	for branch_index in range(_branch_data().size()):
		var state := get_node_or_null("/root/GameState")
		if region == "ash" and branch_index == 3 and state != null and bool(state.unlocked_shortcuts.get("ash_emberspine_guarded_niche_cleared", false)):
			continue
		if region == "starfall" and state != null:
			var guard_event: String = RAMPART_OPERATIONS.GUARD_EVENTS.get(branch_index, "")
			if not guard_event.is_empty() and bool(state.unlocked_shortcuts.get(guard_event, false)):
				continue
		var branch := _branch_rect(branch_index)
		var enemy_kind: String = route["foes"][(branch_index + 2) % route["foes"].size()]
		var guard: Node2D = ENEMIES[enemy_kind].instantiate()
		guard.name = "BranchGuard%d" % branch_index
		var margin := 175 if region == "starfall" else 130
		var clearance := 100 if enemy_kind == "wisp" else (86 if region == "starfall" and enemy_kind == "shade" else 34)
		guard.position = _supported_point(branch_index, true, branch.get_center().x, clearance, margin)
		guard.set("zone_id", route["zone"])
		add_child(guard)
	if region == "ash" or region == "starfall":
		for index in range(2):
			var hazard := (VENT_SCENE if region == "ash" else ROOT_SNARE_SCENE).instantiate()
			hazard.name = "LowerHazard%d" % index
			hazard.position = _span_center(2 + index * 2, 5) + Vector2(0, -18.0)
			hazard.disabled_by_shortcut_id = route["id"] + "_hazard_disabled"
			if region == "ash":
				hazard.disabled_by_shortcut_id = "ash_emberspine_cooling_%d" % index
			hazard.initial_offset = float(index) * 1.1
			add_child(hazard)


func _build_return_lift() -> void:
	var room_id: String = route["id"]
	var final_room := _main_rect(TIER_COUNT - 1)
	var top_marker := Marker2D.new()
	top_marker.name = "ReturnLiftTopMarker"
	top_marker.position = Vector2(365, FLOOR_Y - 33.0)
	top_marker.add_to_group("%s_lift_top" % room_id)
	add_child(top_marker)
	var bottom_marker := Marker2D.new()
	bottom_marker.name = "ReturnLiftBottomMarker"
	bottom_marker.position = Vector2(final_room.end.x - 230.0, final_room.end.y - 33.0)
	bottom_marker.add_to_group("%s_lift_bottom" % room_id)
	add_child(bottom_marker)
	for below in [false, true]:
		var lift := LIFT_SCENE.instantiate()
		lift.name = "ReturnLiftBottom" if below else "ReturnLiftTop"
		lift.position = bottom_marker.position if below else top_marker.position
		lift.shortcut_id = "%s_return_lift" % room_id
		lift.room_id = room_id
		lift.enemy_group = &"enemy"
		lift.target_marker_group = StringName("%s_lift_top" % room_id) if below else StringName("%s_lift_bottom" % room_id)
		lift.activates_shortcut = below
		lift.lift_label = "RETURN LIFT"
		lift.enemy_block_radius = 80.0
		add_child(lift)


func _door(node_name: String, at: Vector2, label: String) -> Node:
	var door := DOOR_SCENE.instantiate()
	door.name = node_name
	door.position = at
	door.target_marker_group = StringName(route["hub_marker"])
	door.target_room_id = route["hub_id"]
	door.door_label = label
	add_child(door)
	return door


func _cache(node_name: String, at: Vector2, cache_id: String, gold: int, material: String) -> void:
	var cache := CACHE_SCENE.instantiate()
	cache.name = node_name
	cache.position = at
	cache.cache_id = cache_id
	cache.cache_name = "Trail Cache"
	cache.gold_reward = gold
	cache.reward_item_id = material
	if region == "echo" and node_name == "RimCache":
		cache.required_event_ids = PackedStringArray(["echo_depths_field_complete"])
	if region == "ash" and node_name == "RimCache":
		cache.required_event_ids = PackedStringArray(["ash_emberspine_field_complete", "ash_emberspine_guarded_niche_cleared"])
	if region == "starfall" and node_name == "RimCache":
		cache.required_event_ids = PackedStringArray(["starfall_ramparts_field_complete", "starfall_ramparts_niche_cleared"])
	add_child(cache)


func _solid_rect(node_name: String, at: Vector2, size: Vector2, tint: Color, one_way: bool = false) -> void:
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


func _colored_polygon(node_name: String, points: PackedVector2Array, tint: Color, layer: int) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.z_index = layer
	polygon.color = tint
	polygon.polygon = points
	add_child(polygon)


func _label(node_name: String, message: String, at: Vector2, width: float, font_size: int, tint: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.size = Vector2(width, 30)
	label.text = message
	label.add_theme_color_override("font_color", tint)
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
