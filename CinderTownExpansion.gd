@tool
extends Node2D

const RESIDENT_SCENE: PackedScene = preload("res://TownResident.tscn")
const FIELD_BOARD := preload("res://HearthFieldBoard.gd")
const EAST_EDGE := 4200.0

var town: Node2D
var population_loaded := false


func _ready() -> void:
	town = get_parent() as Node2D
	if town == null:
		return
	if Engine.is_editor_hint():
		var edited_root := get_tree().edited_scene_root
		if edited_root != null and edited_root != town:
			# Build the architecture and streets, but skip residents and their AI.
			_extend_old_street()
			_build_old_gate_square()
			_build_districts()
			_build_street_details()
			_move_far_gate()
			_populate()
			return
	_extend_old_street()
	_build_old_gate_square()
	_build_districts()
	_build_street_details()
	_move_far_gate()
	if not _uses_world_population_streaming():
		activate_room_population()


func _uses_world_population_streaming() -> bool:
	return town != null and town.get_parent() != null and town.get_parent().get_node_or_null("RoomActivityDirector") != null


func activate_room_population() -> void:
	if Engine.is_editor_hint() or population_loaded:
		return
	_populate()
	var board := Node2D.new()
	board.name = "FieldOffice"
	board.position = Vector2(3550, 35)
	board.set_script(FIELD_BOARD)
	add_child(board)
	population_loaded = true


func is_population_loaded() -> bool:
	return population_loaded


func _build_editor_preview() -> void:
	var main := Line2D.new()
	main.name = "TownMainStreetPreview"
	main.width = 18.0
	main.default_color = Color(0.72, 0.41, 0.28, 0.88)
	main.points = PackedVector2Array([Vector2(1210, 390), Vector2(EAST_EDGE, 390)])
	add_child(main)
	var rooftops := Line2D.new()
	rooftops.name = "TownRoofRoutePreview"
	rooftops.width = 10.0
	rooftops.default_color = Color(0.94, 0.61, 0.36, 0.72)
	rooftops.points = PackedVector2Array([Vector2(1270, 340), Vector2(1710, 78), Vector2(2500, 78), Vector2(2720, 340), Vector2(3260, 35), Vector2(3860, 35), Vector2(4100, -270)])
	add_child(rooftops)


func _extend_old_street() -> void:
	var wall := town.get_node("RightWall") as StaticBody2D
	wall.position.x = EAST_EDGE
	var sky := Polygon2D.new()
	sky.name = "EasternSky"
	sky.z_index = -9
	sky.color = Color(0.085, 0.074, 0.09)
	sky.polygon = PackedVector2Array([Vector2(1200, -390), Vector2(EAST_EDGE, -390), Vector2(EAST_EDGE, 420), Vector2(1200, 420)])
	add_child(sky)
	var ridge := Polygon2D.new()
	ridge.name = "ThreeDistrictRidge"
	ridge.z_index = -7
	ridge.color = Color(0.17, 0.11, 0.13)
	ridge.polygon = PackedVector2Array([Vector2(1200, 380), Vector2(1200, -70), Vector2(1520, -185), Vector2(1810, -60), Vector2(2110, -225), Vector2(2440, -50), Vector2(2810, -250), Vector2(3150, -110), Vector2(3590, -295), Vector2(EAST_EDGE, -45), Vector2(EAST_EDGE, 380)])
	add_child(ridge)
	_platform("EastMarketStreet", 1210, EAST_EDGE, 390, Color(0.38, 0.25, 0.23), false, 18)
	var street := Line2D.new()
	street.name = "OldRoadContinuation"
	street.width = 3.0
	street.default_color = Color(0.95, 0.60, 0.34, 0.45)
	street.points = PackedVector2Array([Vector2(1220, 378), Vector2(1780, 378), Vector2(2290, 378), Vector2(2880, 378), Vector2(3510, 378), Vector2(4120, 378)])
	add_child(street)


func _build_old_gate_square() -> void:
	# Join the authored starter street to the new eastern wards with a civic
	# threshold instead of letting the first large facade start abruptly.
	# Keep the plaza flush with both original and eastern street floors.
	_platform("HearthGatePlaza", 1030.0, 1540.0, 390.0, Color(0.44, 0.28, 0.24), false, 18.0)
	var arch := Polygon2D.new()
	arch.name = "HearthDistrictArch"
	arch.z_index = -1
	arch.color = Color(0.58, 0.34, 0.27)
	arch.polygon = PackedVector2Array([
		Vector2(1145, 381), Vector2(1145, 173), Vector2(1182, 127), Vector2(1275, 94),
		Vector2(1368, 127), Vector2(1405, 173), Vector2(1405, 381), Vector2(1356, 381),
		Vector2(1356, 201), Vector2(1275, 151), Vector2(1194, 201), Vector2(1194, 381),
	])
	add_child(arch)
	var sign := Label.new()
	sign.name = "HearthDistrictGateSign"
	sign.position = Vector2(1160, 55)
	sign.size = Vector2(230, 28)
	sign.text = "CINDER HEARTH DISTRICTS"
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", 11)
	sign.add_theme_color_override("font_color", Color(1.0, 0.72, 0.48, 0.9))
	add_child(sign)


func _build_districts() -> void:
	var masonry := Color(0.53, 0.32, 0.26)
	var bright := Color(0.66, 0.43, 0.30)
	# The lower caravan street is continuous; the roof and watch routes are
	# optional loops with short, base-jump-height stairs at both ends.
	_stair_run("WestRise", 1270, 340, 6, 90, -43, masonry)
	_platform("KilnArcade", 1710, 2500, 78, bright, true, 12)
	_stair_run("ArcadeDescent", 2540, 120, 6, 72, 43, masonry)
	_stair_run("LibraryRise", 2720, 340, 7, 82, -45, masonry)
	_platform("CopperLibraryWalk", 3260, 3860, 35, bright.lightened(0.04), true, 12)
	# Keep the whole stair inside the far wall and its final rise within a
	# basic jump, rather than leaving a near-100px jump from the street.
	_stair_run("LibraryDescent", 3870, 70, 7, 32, 45, masonry)
	_stair_run("WatchAscent", 3200, 0, 6, 72, -45, masonry)
	_platform("CinderWatch", 3590, 4100, -270, Color(0.68, 0.45, 0.37), true, 12)
	_house("BellFoundry", Vector2(1540, 350), Vector2(255, 195), Color(0.31, 0.18, 0.17), Color(1.0, 0.62, 0.36))
	_house("CaravanInn", Vector2(2040, 350), Vector2(340, 170), Color(0.32, 0.20, 0.19), Color(1.0, 0.74, 0.45))
	_house("KilnSchool", Vector2(2390, 350), Vector2(225, 140), Color(0.31, 0.22, 0.22), Color(0.90, 0.66, 0.44))
	_house("ArchiveHall", Vector2(3000, 350), Vector2(335, 245), Color(0.27, 0.20, 0.25), Color(1.0, 0.74, 0.54))
	_house("CopperLibrary", Vector2(3560, 350), Vector2(335, 300), Color(0.28, 0.20, 0.24), Color(0.98, 0.78, 0.48))
	_house("GateBarracks", Vector2(3980, 350), Vector2(210, 185), Color(0.33, 0.22, 0.22), Color(1.0, 0.57, 0.34))
	_house("KilnLoft", Vector2(1870, 68), Vector2(205, 122), Color(0.30, 0.18, 0.19), Color(1.0, 0.66, 0.38))
	_house("ArcadeShrine", Vector2(2290, 68), Vector2(175, 104), Color(0.34, 0.21, 0.23), Color(1.0, 0.79, 0.49))
	_house("ArchiveLoft", Vector2(3470, 25), Vector2(230, 135), Color(0.25, 0.18, 0.27), Color(0.88, 0.72, 0.58))
	_house("WatchHouse", Vector2(3830, -280), Vector2(190, 116), Color(0.29, 0.19, 0.23), Color(1.0, 0.63, 0.39))
	for district in range(3):
		var title := Label.new()
		title.name = "DistrictSign%d" % district
		title.position = Vector2(1490 + district * 1020, 260)
		title.add_theme_font_size_override("font_size", 10)
		title.add_theme_color_override("font_color", Color(1.0, 0.73, 0.49, 0.85))
		title.text = ["THE KILNS", "CARAVAN WARD", "COPPER ARCHIVE"][district]
		add_child(title)
	for flame in range(14):
		var x := 1330.0 + flame * 205.0
		var lamp := Polygon2D.new()
		lamp.name = "StreetLantern%d" % flame
		lamp.z_index = -1
		lamp.color = Color(1.0, 0.53 + 0.05 * (flame % 3), 0.23, 0.88)
		lamp.polygon = PackedVector2Array([Vector2(x - 4, 351), Vector2(x, 332), Vector2(x + 4, 351)])
		add_child(lamp)
	for garden in range(10):
		var patch := Node2D.new()
		patch.name = "AshGarden%d" % garden
		patch.position = Vector2(1450.0 + garden * 280.0, 379.0)
		add_child(patch)
		for leaf_index in range(5):
			var leaf := Polygon2D.new()
			leaf.name = "Leaf%d" % leaf_index
			leaf.z_index = -1
			leaf.color = Color(0.43 + 0.03 * (garden % 3), 0.58, 0.38 + 0.05 * (leaf_index % 2), 0.88)
			var stem_x := float(leaf_index - 2) * 12.0
			var leaf_height := 14.0 + float((garden * 7 + leaf_index * 5) % 14)
			leaf.polygon = PackedVector2Array([Vector2(stem_x - 6, 0), Vector2(stem_x, -leaf_height), Vector2(stem_x + 6, 0)])
			patch.add_child(leaf)


func _build_street_details() -> void:
	var awning_color := Color(0.72, 0.36, 0.24, 0.88)
	for index in range(6):
		var x: float = 1460.0 + float(index) * 490.0
		_decor_polygon("MarketAwning%d" % index, PackedVector2Array([
			Vector2(x - 72.0, 292.0), Vector2(x + 72.0, 292.0),
			Vector2(x + 55.0, 324.0), Vector2(x - 55.0, 324.0),
		]), awning_color.lightened(float(index % 3) * 0.05), -1)
		for side: float in [-52.0, 52.0]:
			_decor_polygon("MarketPost%d_%s" % [index, "L" if side < 0.0 else "R"], PackedVector2Array([
				Vector2(x + side - 4.0, 323.0), Vector2(x + side + 4.0, 323.0),
				Vector2(x + side + 4.0, 380.0), Vector2(x + side - 4.0, 380.0),
			]), Color(0.35, 0.22, 0.19), -1)
		_decor_polygon("StreetBench%d" % index, PackedVector2Array([
			Vector2(x + 122.0, 350.0), Vector2(x + 218.0, 350.0),
			Vector2(x + 211.0, 363.0), Vector2(x + 129.0, 363.0),
		]), Color(0.46, 0.29, 0.23), -1)
		_barrel_cluster("SupplyCluster%d" % index, Vector2(x - 118.0, 372.0), 2 + index % 2)
	for line_index in range(4):
		var left := Vector2(1580.0 + float(line_index) * 620.0, 194.0 - float(line_index % 2) * 45.0)
		var right := left + Vector2(360.0, -18.0)
		_decor_line("WardLaundry%d" % line_index, PackedVector2Array([left, (left + right) * 0.5 + Vector2(0.0, 20.0), right]), Color(0.92, 0.56, 0.35, 0.50), 2.0, -1)
		for cloth in range(3):
			var cx := lerpf(left.x, right.x, 0.25 + float(cloth) * 0.25)
			var cy := lerpf(left.y, right.y, 0.25 + float(cloth) * 0.25) + 8.0
			_decor_polygon("WardCloth%d_%d" % [line_index, cloth], PackedVector2Array([
				Vector2(cx - 13.0, cy), Vector2(cx + 13.0, cy), Vector2(cx + 9.0, cy + 35.0), Vector2(cx - 11.0, cy + 30.0),
			]), Color(0.70, 0.39 + float(cloth) * 0.06, 0.31, 0.72), -1)
	for cart_index in range(3):
		var cart_x := 1800.0 + float(cart_index) * 930.0
		_decor_polygon("CaravanCart%d" % cart_index, PackedVector2Array([
			Vector2(cart_x - 76.0, 333.0), Vector2(cart_x + 74.0, 333.0),
			Vector2(cart_x + 58.0, 371.0), Vector2(cart_x - 62.0, 371.0),
		]), Color(0.40, 0.25, 0.22), -1)
		for wheel_side: float in [-48.0, 48.0]:
			_decor_polygon("CartWheel%d_%s" % [cart_index, "L" if wheel_side < 0.0 else "R"], _circle(Vector2(cart_x + wheel_side, 374.0), 17.0, 10), Color(0.25, 0.18, 0.18), 0)


func _barrel_cluster(prefix: String, at: Vector2, count: int) -> void:
	for index in range(count):
		var center := at + Vector2(float(index) * 24.0, -float(index % 2) * 9.0)
		_decor_polygon("%sBarrel%d" % [prefix, index], _circle(center, 13.0, 10), Color(0.43, 0.27, 0.20), -1)


func _circle(center: Vector2, radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _decor_polygon(label: String, points: PackedVector2Array, tint: Color, layer: int) -> void:
	var visual := Polygon2D.new()
	visual.name = label
	visual.z_index = layer
	visual.color = tint
	visual.polygon = points
	add_child(visual)


func _decor_line(label: String, points: PackedVector2Array, tint: Color, width: float, layer: int) -> void:
	var visual := Line2D.new()
	visual.name = label
	visual.z_index = layer
	visual.default_color = tint
	visual.width = width
	visual.points = points
	add_child(visual)


func _move_far_gate() -> void:
	(town.get_node("ThroneShortcut") as Node2D).position = Vector2(4145, 357)
	(town.get_node("ThroneReturn") as Node2D).position = Vector2(4060, 357)


func _platform(label: String, left: float, right: float, y: float, color: Color, one_way: bool, depth: float) -> void:
	var body := StaticBody2D.new()
	body.name = label
	body.position = Vector2((left + right) * 0.5, y)
	add_child(body)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(right - left, depth)
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.name = "Stone"
	visual.color = color
	visual.polygon = PackedVector2Array([Vector2(-(right - left) * 0.5, -depth * 0.5), Vector2((right - left) * 0.5, -depth * 0.5), Vector2((right - left) * 0.5, depth * 0.5), Vector2(-(right - left) * 0.5, depth * 0.5)])
	body.add_child(visual)


func _stair_run(prefix: String, x: float, y: float, count: int, dx: float, dy: float, color: Color) -> void:
	for step in range(count):
		_platform("%s%d" % [prefix, step], x + step * dx, x + step * dx + 118, y + step * dy, color.lightened(float(step % 3) * 0.06), true, 10)


func _house(label: String, center: Vector2, size: Vector2, wall: Color, window_color: Color) -> void:
	var facade := Polygon2D.new()
	facade.name = label
	facade.z_index = -3
	facade.color = wall
	facade.polygon = PackedVector2Array([center + Vector2(-size.x * 0.5, 0), center + Vector2(-size.x * 0.5, -size.y + 24), center + Vector2(0, -size.y - 17), center + Vector2(size.x * 0.5, -size.y + 24), center + Vector2(size.x * 0.5, 0)])
	add_child(facade)
	for side in [-1, 1]:
		var window := Polygon2D.new()
		window.name = "%sWindow%d" % [label, side]
		window.z_index = -2
		window.color = window_color
		var px: float = center.x + side * size.x * 0.25
		window.polygon = PackedVector2Array([Vector2(px - 11, center.y - 76), Vector2(px + 11, center.y - 76), Vector2(px + 11, center.y - 43), Vector2(px - 11, center.y - 43)])
		add_child(window)


func _marker(label: String, at: Vector2, interior: bool = false) -> void:
	var marker := Marker2D.new()
	marker.name = label
	marker.position = at
	marker.add_to_group("town_interior" if interior else "town_social_spot")
	add_child(marker)


func _resident(label: String, at: Vector2, route: PackedStringArray, lines: PackedStringArray, coat: Color, accent: Color) -> void:
	var npc := RESIDENT_SCENE.instantiate()
	npc.name = label
	npc.position = at
	npc.resident_name = label
	npc.route_marker_names = route
	npc.dialogue_lines = lines
	npc.coat_color = coat
	npc.accent_color = accent
	npc.walk_speed = 22.0
	npc.get_node("NameLabel").text = label
	npc.get_node("Coat").color = coat
	npc.get_node("Accent").color = accent
	add_child(npc)


func _populate() -> void:
	_marker("KilnSquare", Vector2(1510, 357))
	_marker("FoundryDoor", Vector2(1680, 357), true)
	_marker("InnSquare", Vector2(1950, 357))
	_marker("InnDoor", Vector2(2160, 357), true)
	_marker("SchoolDoor", Vector2(2410, 357), true)
	_marker("CaravanCorner", Vector2(2700, 357))
	_marker("ArchiveDoor", Vector2(3000, 357), true)
	_marker("ArchiveSquare", Vector2(3220, 357))
	_marker("LibraryDoor", Vector2(3570, 357), true)
	_marker("GateWatch", Vector2(3910, 357))
	_marker("ArcadeWest", Vector2(1800, 45))
	_marker("ArcadeEast", Vector2(2390, 45))
	_marker("WatchWest", Vector2(3650, -303))
	_marker("WatchEast", Vector2(4020, -303))
	_marker("LowerMarketWest", Vector2(2620, 357))
	_marker("LowerMarketEast", Vector2(2860, 357))
	_marker("ArchiveBench", Vector2(3310, 357))
	_marker("BarracksYard", Vector2(3860, 357))
	_marker("LoftLanding", Vector2(2060, 45))
	_resident("Veyra", Vector2(1510, 357), PackedStringArray(["KilnSquare", "FoundryDoor", "InnSquare"]), PackedStringArray(["The foundry cools its iron here, where the caravan children can watch.", "There is a quiet walk above the kilns if you take the east stairs."]), Color(0.43, 0.31, 0.29), Color(1.0, 0.67, 0.4))
	_resident("Torren", Vector2(1950, 357), PackedStringArray(["InnSquare", "InnDoor", "SchoolDoor"]), PackedStringArray(["The inn keeps a bed ready for anyone who reaches the gate.", "I hear old songs from the Copper Archive at dusk."]), Color(0.37, 0.31, 0.32), Color(0.92, 0.76, 0.58))
	_resident("Elian", Vector2(2410, 357), PackedStringArray(["SchoolDoor", "CaravanCorner", "InnSquare"]), PackedStringArray(["The children draw maps of places they have never seen.", "Beyond this ward the old throne road is still sealed."]), Color(0.40, 0.33, 0.41), Color(0.91, 0.79, 0.61))
	_resident("Sariel", Vector2(3000, 357), PackedStringArray(["ArchiveDoor", "ArchiveSquare", "LibraryDoor"]), PackedStringArray(["Some days the archive receives more travelers than scrolls.", "The upper watch has the clearest view of the ash sky."]), Color(0.34, 0.29, 0.44), Color(0.94, 0.75, 0.59))
	_resident("Branik", Vector2(3570, 357), PackedStringArray(["LibraryDoor", "GateWatch", "ArchiveSquare"]), PackedStringArray(["I repair the gate lanterns before every storm.", "The smithy by the western entrance still trades the strongest blades."]), Color(0.43, 0.28, 0.32), Color(0.99, 0.61, 0.40))
	_resident("Neris", Vector2(1800, 45), PackedStringArray(["ArcadeWest", "ArcadeEast"]), PackedStringArray(["The arcade joins the inn and the kilns without crossing the street.", "From up here the whole town sounds like one big hearth."]), Color(0.37, 0.33, 0.46), Color(1.0, 0.78, 0.56))
	_resident("Avel", Vector2(3650, -303), PackedStringArray(["WatchWest", "WatchEast"]), PackedStringArray(["The watch has been quiet since the roads opened again.", "If danger comes from the far road, the bell will reach every district."]), Color(0.38, 0.36, 0.46), Color(1.0, 0.70, 0.46))
	_resident("Kessa", Vector2(2620, 357), PackedStringArray(["LowerMarketWest", "LowerMarketEast", "CaravanCorner"]), PackedStringArray(["I count every cart that passes under the district arch.", "The upper walk is quiet when the market is busiest."]), Color(0.45, 0.29, 0.31), Color(1.0, 0.68, 0.43))
	_resident("Halen", Vector2(2060, 45), PackedStringArray(["ArcadeWest", "LoftLanding", "ArcadeEast"]), PackedStringArray(["The kiln lofts stay warm long after the fires are banked.", "I mend roof tiles before the ash winds return."]), Color(0.35, 0.30, 0.39), Color(0.94, 0.72, 0.53))
	_resident("Marel", Vector2(3310, 357), PackedStringArray(["ArchiveBench", "ArchiveSquare", "LibraryDoor"]), PackedStringArray(["Travelers leave stories on this bench more often than in the archive.", "The eastern shelves hold maps of roads that no longer exist."]), Color(0.34, 0.31, 0.45), Color(0.88, 0.78, 0.63))
	_resident("Tovin", Vector2(3860, 357), PackedStringArray(["BarracksYard", "GateWatch", "LibraryDoor"]), PackedStringArray(["The gate watch trains here, but the square belongs to everyone.", "No enemy has crossed the hearth arch since the wards were renewed."]), Color(0.44, 0.28, 0.28), Color(1.0, 0.59, 0.37))
	(get_node("Veyra") as Area2D).set("talk_partner", NodePath("../Torren"))
	(get_node("Torren") as Area2D).set("talk_partner", NodePath("../Veyra"))
	(get_node("Sariel") as Area2D).set("talk_partner", NodePath("../Branik"))
	(get_node("Branik") as Area2D).set("talk_partner", NodePath("../Sariel"))
	(get_node("Veyra") as Area2D).set("social_lines", PackedStringArray(["The kiln can spare another lantern for the inn."]))
	(get_node("Torren") as Area2D).set("social_lines", PackedStringArray(["Keep it by the east door, Veyra. Travelers arrive late."]))
	(get_node("Sariel") as Area2D).set("social_lines", PackedStringArray(["Did the copper records survive the storm?"]))
	(get_node("Branik") as Area2D).set("social_lines", PackedStringArray(["Every page. I kept the library roof dry."]))
	(get_node("Kessa") as Area2D).set("talk_partner", NodePath("../Tovin"))
	(get_node("Tovin") as Area2D).set("talk_partner", NodePath("../Kessa"))
