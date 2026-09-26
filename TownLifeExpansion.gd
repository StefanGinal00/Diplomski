@tool
extends Node2D

const RESIDENT_SCENE: PackedScene = preload("res://TownResident.tscn")

@export_enum("echo", "ash", "starfall") var settlement: String = "echo"

var population_loaded := false
var _defer_population := false
var _pending_residents: Array[Dictionary] = []
var _pending_partner_pairs: Array[PackedStringArray] = []


func _ready() -> void:
	_defer_population = _uses_world_population_streaming()
	match settlement:
		"echo":
			_build_echo_haven()
		"ash":
			_build_cinder_hearth()
		"starfall":
			_build_starfall_library()
	if not _defer_population:
		population_loaded = true
		_wire_partner_pairs()


func _uses_world_population_streaming() -> bool:
	if Engine.is_editor_hint():
		return false
	var room := get_parent()
	return room != null and room.get_parent() != null and room.get_parent().get_node_or_null("RoomActivityDirector") != null


func activate_room_population() -> void:
	if Engine.is_editor_hint() or population_loaded:
		return
	for data in _pending_residents:
		_spawn_resident(
			String(data["name"]),
			data["position"],
			data["stops"],
			data["lines"],
			data["coat"],
			data["accent"],
			data["social"],
		)
	_pending_residents.clear()
	population_loaded = true
	_wire_partner_pairs()


func is_population_loaded() -> bool:
	return population_loaded


func _build_echo_haven() -> void:
	var stone := Color(0.2, 0.5, 0.54)
	_platform("WestStair", Vector2(165, 98), 125, stone)
	_platform("UpperStair", Vector2(262, 32), 125, stone)
	_platform("WestBalcony", Vector2(468, -30), 315, stone.lightened(0.12))
	_platform("EastBalcony", Vector2(811, -30), 300, stone.lightened(0.12))
	_platform("EastStair", Vector2(1030, 35), 125, stone)
	_platform("GateStair", Vector2(1115, 100), 115, stone)
	_facade("LanternHouse", Vector2(405, 32), Vector2(185, 90), Color(0.12, 0.26, 0.32), Color(0.37, 0.78, 0.76))
	_facade("SurveyLoft", Vector2(780, 32), Vector2(175, 95), Color(0.12, 0.27, 0.34), Color(0.52, 0.88, 0.84))
	_marker("WestLookout", Vector2(365, -63), true)
	_marker("LoftDoor", Vector2(535, -63), false, true)
	_marker("EastLookout", Vector2(720, -63), true)
	_marker("SurveyDoor", Vector2(910, -63), false, true)
	_resident("Tessan", Vector2(396, -63), ["WestLookout", "LoftDoor"], ["I keep the upper lanterns lit so the lower path never disappears.", "The view is safest from here, even when the Grotto is restless."], Color(0.31, 0.46, 0.55), Color(0.55, 0.91, 0.86), ["The loft still has room for one more traveler."])
	_resident("Lumen", Vector2(780, -63), ["EastLookout", "SurveyDoor"], ["Our surveyors mark every new passage on the cavern wall.", "The stair at either end brings you back to the market."], Color(0.35, 0.38, 0.55), Color(0.7, 0.91, 0.95), ["I found another vein beyond the old shelf."])
	_marker("LowerGardenWest", Vector2(325, 129), true)
	_marker("LowerGardenEast", Vector2(545, 129), true)
	_marker("GardenHouseDoor", Vector2(585, 129), false, true)
	_resident("Selis", Vector2(335, 129), ["LowerGardenWest", "LowerGardenEast", "GardenHouseDoor"], ["The small cave flowers only open when the lamps grow warm.", "We planted these beds to make the walk home feel shorter."], Color(0.33, 0.46, 0.4), Color(0.72, 0.93, 0.7), ["Tovan, the new shoots survived the night."])
	_resident("Tovan", Vector2(515, 129), ["LowerGardenEast", "LowerGardenWest"], ["I carry water from the well to the garden every morning.", "The people up on the balcony can see all the way to the gate."], Color(0.35, 0.43, 0.5), Color(0.83, 0.85, 0.68), ["The water jar is full, Selis."])
	_partner_pair("Selis", "Tovan")
	_flora_patch("HavenGarden", Vector2(400, 149), Color(0.3, 0.84, 0.66), 9)


func _build_cinder_hearth() -> void:
	var stone := Color(0.57, 0.32, 0.23)
	_platform("GateStair", Vector2(170, 318), 125, stone)
	_platform("HearthStair", Vector2(272, 253), 125, stone)
	_platform("SmithyWalk", Vector2(460, 189), 300, stone.lightened(0.12))
	_platform("MarketWalk", Vector2(790, 189), 275, stone.lightened(0.12))
	_platform("EastStair", Vector2(990, 254), 125, stone)
	_platform("ThroneStair", Vector2(1090, 319), 125, stone)
	_facade("BellKeeperHouse", Vector2(450, 250), Vector2(180, 90), Color(0.31, 0.16, 0.14), Color(0.97, 0.62, 0.3))
	_facade("CaravanLoft", Vector2(782, 250), Vector2(170, 92), Color(0.32, 0.17, 0.14), Color(1.0, 0.68, 0.36))
	_marker("BellLookout", Vector2(360, 156), true)
	_marker("KeeperDoor", Vector2(550, 156), false, true)
	_marker("CaravanLookout", Vector2(690, 156), true)
	_marker("CaravanDoor", Vector2(870, 156), false, true)
	_resident("Kael", Vector2(405, 156), ["BellLookout", "KeeperDoor"], ["I listen for the Chapel bells from the upper walk.", "The stair is steep, but it keeps our supply carts off the hot road."], Color(0.42, 0.29, 0.33), Color(1.0, 0.71, 0.4), ["The bell is quiet today. I like it that way."])
	_resident("Soren", Vector2(775, 156), ["CaravanLookout", "CaravanDoor"], ["Caravans use this balcony to watch for ash storms.", "Down below is the smithy; beyond the gate the road is still dangerous."], Color(0.38, 0.33, 0.37), Color(0.97, 0.79, 0.48), ["A caravan made it through before dawn."])
	_marker("KilnSquareWest", Vector2(390, 357), true)
	_marker("KilnSquareEast", Vector2(810, 357), true)
	_marker("KilnHouseDoor", Vector2(535, 357), false, true)
	_resident("Rellan", Vector2(400, 357), ["KilnSquareWest", "KilnHouseDoor", "KilnSquareEast"], ["The smithy sends its spare tools to every watch post.", "I sort the crates so the guards can travel light."], Color(0.44, 0.34, 0.29), Color(0.91, 0.68, 0.43), ["I left the lightest bundle for you, Yara."])
	_resident("Yara", Vector2(800, 357), ["KilnSquareEast", "KilnSquareWest"], ["The small houses stay warm even when the outer road goes cold.", "I help the caravans find a safe place to sleep."], Color(0.45, 0.33, 0.39), Color(0.97, 0.76, 0.55), ["Another caravan made it through, Rellan."])
	_partner_pair("Rellan", "Yara")
	_flora_patch("HearthPlanters", Vector2(1040, 374), Color(0.72, 0.46, 0.27), 7)


func _build_starfall_library() -> void:
	var stone := Color(0.62, 0.6, 0.73)
	_platform("LibraryClimb", Vector2(4770, 169), 130, stone)
	_platform("LibraryRoofWalk", Vector2(4560, 111), 415, stone.lightened(0.06))
	_facade("RoofArchive", Vector2(4550, 176), Vector2(230, 90), Color(0.29, 0.3, 0.43), Color(0.9, 0.78, 0.58))
	_marker("RoofWest", Vector2(4400, 78), true)
	_marker("RoofEast", Vector2(4720, 78), true)
	_resident("Erian", Vector2(4530, 78), ["RoofWest", "RoofEast"], ["The library has a roof path too. I come up to read by the first light.", "From here the Citadel looks like several cities joined by bridges."], Color(0.38, 0.4, 0.55), Color(0.93, 0.82, 0.67), ["The chart has changed again. I should tell Atley."])
	_marker("CivicWest", Vector2(2540, 367), true)
	_marker("CivicEast", Vector2(2820, 367), true)
	_resident("Marwen", Vector2(2670, 367), ["CivicWest", "CivicEast"], ["I mend the road signs between the Ward and the market.", "A city is more than its walls. It is everyone who keeps the paths open."], Color(0.45, 0.37, 0.5), Color(0.83, 0.8, 0.97), ["The market signs can wait until morning."])
	_marker("RoofMiddle", Vector2(4560, 78), true)
	_resident("Caelis", Vector2(4700, 78), ["RoofEast", "RoofMiddle", "RoofWest"], ["I count the garden lanterns from the library roof.", "There are paths above the streets for anyone willing to climb."], Color(0.38, 0.48, 0.52), Color(0.82, 0.94, 0.86), ["The eastern lanterns are lit, Erian."])
	_partner_pair("Erian", "Caelis")
	_marker("CivicMid", Vector2(2680, 367), true)
	_resident("Dorian", Vector2(2780, 367), ["CivicEast", "CivicMid", "CivicWest"], ["Every morning I carry fresh bread toward the market.", "The city seems endless when you know all its side streets."], Color(0.43, 0.39, 0.53), Color(0.95, 0.82, 0.67), ["I saved you a loaf, Marwen."])
	_partner_pair("Marwen", "Dorian")
	_flora_patch("LibraryVines", Vector2(4890, 387), Color(0.46, 0.73, 0.58), 11)


func _platform(node_name: String, center: Vector2, width: float, tint: Color) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 10)
	collision.shape = shape
	collision.one_way_collision = true
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.color = tint
	visual.polygon = PackedVector2Array([Vector2(-width * 0.5, -5), Vector2(width * 0.5, -5), Vector2(width * 0.5, 5), Vector2(-width * 0.5, 5)])
	body.add_child(visual)
	add_child(body)


func _facade(node_name: String, center: Vector2, size: Vector2, body_color: Color, window_color: Color) -> void:
	var house := Polygon2D.new()
	house.name = node_name
	house.z_index = -3
	house.color = body_color
	house.polygon = PackedVector2Array([center + Vector2(-size.x * 0.5, size.y * 0.5), center + Vector2(-size.x * 0.5, -size.y * 0.5 + 20), center + Vector2(0, -size.y * 0.5 - 20), center + Vector2(size.x * 0.5, -size.y * 0.5 + 20), center + Vector2(size.x * 0.5, size.y * 0.5)])
	add_child(house)
	var window := Polygon2D.new()
	window.name = node_name + "Window"
	window.z_index = -2
	window.color = window_color
	window.polygon = PackedVector2Array([center + Vector2(-15, -15), center + Vector2(15, -15), center + Vector2(15, 12), center + Vector2(-15, 12)])
	add_child(window)


func _flora_patch(node_name: String, center: Vector2, tint: Color, stems: int) -> void:
	var patch := Node2D.new()
	patch.name = node_name
	for index in range(stems):
		var x := center.x + float(index - stems / 2) * 12.0
		var height := 13.0 + float((index * 7) % 13)
		var leaf := Polygon2D.new()
		leaf.name = "Leaf%d" % index
		leaf.z_index = -1
		leaf.color = tint.lightened(float(index % 3) * 0.09)
		leaf.polygon = PackedVector2Array([Vector2(x - 5, center.y), Vector2(x, center.y - height), Vector2(x + 5, center.y)])
		patch.add_child(leaf)
	add_child(patch)


func _marker(node_name: String, at: Vector2, social: bool = false, interior: bool = false) -> void:
	var marker := Marker2D.new()
	marker.name = node_name
	marker.position = at
	if social:
		marker.add_to_group("town_social_spot")
	if interior:
		marker.add_to_group("town_interior")
	add_child(marker)


func _resident(node_name: String, at: Vector2, stops: Array[String], lines: Array[String], coat: Color, accent: Color, social: Array[String]) -> void:
	if _defer_population and not population_loaded:
		_pending_residents.append({
			"name": node_name,
			"position": at,
			"stops": stops.duplicate(),
			"lines": lines.duplicate(),
			"coat": coat,
			"accent": accent,
			"social": social.duplicate(),
		})
		return
	_spawn_resident(node_name, at, stops, lines, coat, accent, social)


func _spawn_resident(node_name: String, at: Vector2, stops: Array, lines: Array, coat: Color, accent: Color, social: Array) -> void:
	var npc := RESIDENT_SCENE.instantiate()
	npc.name = node_name
	npc.position = at
	npc.resident_name = node_name
	npc.route_marker_names = PackedStringArray(stops)
	npc.dialogue_lines = PackedStringArray(lines)
	npc.social_lines = PackedStringArray(social)
	npc.coat_color = coat
	npc.accent_color = accent
	npc.walk_speed = 20.0
	# TownResident is runtime-driven; set its preview visuals for the editor too.
	npc.get_node("NameLabel").text = node_name
	npc.get_node("Coat").color = coat
	npc.get_node("Accent").color = accent
	add_child(npc)


func _partner_pair(first_name: String, second_name: String) -> void:
	_pending_partner_pairs.append(PackedStringArray([first_name, second_name]))


func _wire_partner_pairs() -> void:
	for pair in _pending_partner_pairs:
		var first := get_node_or_null(String(pair[0]))
		var second := get_node_or_null(String(pair[1]))
		if first == null or second == null:
			continue
		first.talk_partner = NodePath("../%s" % String(pair[1]))
		second.talk_partner = NodePath("../%s" % String(pair[0]))
