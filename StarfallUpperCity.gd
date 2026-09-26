@tool
extends Node2D

const RESIDENT := preload("res://TownResident.tscn")
const PLAQUE := preload("res://SluiceValve.tscn")
const CACHE := preload("res://ResonanceCache.tscn")
const LIFT := preload("res://ShaftLift.tscn")
const EVENTS := ["starfall_city_artisans", "starfall_city_gardens", "starfall_city_bells", "starfall_city_stars"]
const DISTRICTS := [
	["ArtisanTerrace", "ARTISAN TERRACE", 920.0, 2680.0, -300.0, Color(0.48, 0.39, 0.53)],
	["HangingGardens", "HANGING GARDENS", 3650.0, 5900.0, -620.0, Color(0.30, 0.52, 0.47)],
	["BellSquare", "BELLS OF THE CITADEL", 2200.0, 4250.0, -1080.0, Color(0.49, 0.44, 0.60)],
	["CrownObservatory", "CROWN OBSERVATORY", 4300.0, 5850.0, -1600.0, Color(0.36, 0.44, 0.64)],
]

var population_loaded := false
var survey_label: Label
var stair_routes: Array[Array] = []


func _ready() -> void:
	_build_upper_skyline()
	_build_districts()
	_build_district_workplaces()
	_build_connections()
	_build_lift()
	if not Engine.is_editor_hint() and get_parent().get_parent().get_node_or_null("RoomActivityDirector") == null:
		call_deferred("activate_room_population")


func _build_upper_skyline() -> void:
	# Receding architecture joins the terraces visually into one metropolis.
	# These are broad buildings with cornices/windows, never collision pillars.
	for data in [[1580, 390, 510, 980], [2850, 390, 760, 1590], [4130, 390, 540, 1080], [5030, -580, 690, 1140]]:
		var x: float = data[0]
		var base: float = data[1]
		var width: float = data[2]
		var height: float = data[3]
		var top := base - height
		var building := Node2D.new()
		building.name = "UpperSkyline%d" % int(x)
		building.z_index = -7
		add_child(building)
		_poly(building, "SteppedSilhouette", PackedVector2Array([Vector2(x - width / 2, base), Vector2(x - width / 2, top + 125), Vector2(x - width * 0.29, top + 125), Vector2(x - width * 0.29, top + 45), Vector2(x, top - 35), Vector2(x + width * 0.29, top + 45), Vector2(x + width * 0.29, top + 125), Vector2(x + width / 2, top + 125), Vector2(x + width / 2, base)]), Color(0.105, 0.13, 0.21), 0)
		for row in range(int((height - 170) / 115)):
			var y := top + 185 + row * 115
			_rect(building, "Cornice%d" % row, Rect2(x - width / 2, y + 47, width, 8), Color(0.16, 0.18, 0.27), 1)
			for column in range(4):
				_rect(building, "Window%d_%d" % [row, column], Rect2(x - width * 0.34 + column * width * 0.22, y, 21, 34), Color(0.40, 0.42, 0.44, 0.55), 1)


func _build_districts() -> void:
	for index in range(DISTRICTS.size()):
		var data: Array = DISTRICTS[index]
		var district := Node2D.new()
		district.name = data[0]
		district.set_meta("district_identity", data[0])
		add_child(district)
		var left: float = data[2]
		var right: float = data[3]
		var y: float = data[4]
		var tone: Color = data[5]
		_deck(String(data[0]) + "Walk", Vector2((left + right) * 0.5, y), right - left, tone)
		# Masonry follows the terrace, not giant pillars stretching to street level.
		_poly(district, "TerraceArches", PackedVector2Array([Vector2(left, y), Vector2(right, y), Vector2(right - 75, y + 78), Vector2(right - 240, y + 38), Vector2(left + 300, y + 38), Vector2(left + 100, y + 85)]), tone.darkened(0.4), -4)
		_label(district, "DistrictName", data[1], Vector2(left + 80, y - 220), 430)
		var houses: Array = []
		match index:
			0: houses = [[1200, 210, 155], [1620, 300, 190], [2270, 240, 150]]
			1: houses = [[3850, 200, 160], [4750, 370, 200], [5580, 210, 135]]
			2: houses = [[2470, 250, 200], [3870, 300, 180]]
			3: houses = [[4520, 230, 160], [5520, 340, 210]]
		for h in houses:
			_house(district, Vector2(h[0], y - 10), Vector2(h[1], h[2]), tone)
		for lamp_x in [left + 45, (left + right) * 0.5, right - 45]:
			_rect(district, "LampPost%d" % int(lamp_x), Rect2(lamp_x - 3, y - 105, 6, 97), tone.lightened(0.2))
			_rect(district, "LampLight%d" % int(lamp_x), Rect2(lamp_x - 12, y - 115, 24, 19), Color(0.9, 0.81, 0.58))
		match index:
			0:
				for i in range(3):
					_rect(district, "WorkshopAwning%d" % i, Rect2(1320 + i * 290, y - 78, 120, 13), tone.lightened(0.3))
				_label(district, "WorkshopSign", "BOOKBINDERS  /  LANTERN MAKERS", Vector2(1450, y - 63), 370)
			1:
				for i in range(12):
					var x := 4050.0 + i * 120
					_rect(district, "Planter%d" % i, Rect2(x - 30, y - 28, 60, 20), tone.darkened(0.2))
					_poly(district, "GardenTree%d" % i, PackedVector2Array([Vector2(x - 35, y - 28), Vector2(x - 22, y - 65), Vector2(x, y - 115 - (i % 3) * 15), Vector2(x + 30, y - 55), Vector2(x + 35, y - 28)]), tone.lightened(0.22), -2)
			2:
				_rect(district, "BellArchWest", Rect2(3100, y - 260, 24, 250), tone.darkened(0.2))
				_rect(district, "BellArchEast", Rect2(3430, y - 260, 24, 250), tone.darkened(0.2))
				_rect(district, "BellArchLintel", Rect2(3080, y - 275, 400, 25), tone)
				for i in range(3):
					var x := 3190.0 + i * 82
					_rect(district, "BellChain%d" % i, Rect2(x - 2, y - 250, 4, 65), Color(0.8, 0.72, 0.53))
					_poly(district, "Bell%d" % i, PackedVector2Array([Vector2(x - 18, y - 185), Vector2(x + 18, y - 185), Vector2(x + 34, y - 135), Vector2(x - 34, y - 135)]), Color(0.77, 0.63, 0.39), -1)
			3:
				var ring := Line2D.new()
				ring.name = "CelestialLens"
				ring.width = 5
				ring.default_color = Color(0.69, 0.82, 0.96)
				for i in range(33):
					var angle := TAU * i / 32.0
					ring.add_point(Vector2(5090, y - 100) + Vector2(cos(angle) * 85, sin(angle) * 65))
				district.add_child(ring)
				_rect(district, "LensPedestal", Rect2(5070, y - 40, 40, 32), tone.lightened(0.25))
				_label(district, "CrownView", "THE CITY BELOW. THE STARS AHEAD.", Vector2(4860, y - 235), 470)


func _build_district_workplaces() -> void:
	# Distinct pedestrian-scale workplaces fill the quiet half of each terrace.
	# They are scenery, not new collision, shops or repeatable reward sources.
	for index in range(4):
		var data: Array = DISTRICTS[index]
		var at := Vector2([2270, 5580, 3870, 5520][index], float(data[4]) - 9)
		var tone: Color = data[5]
		var place := Node2D.new()
		place.name = "Workplace%d" % index
		place.position = at
		add_child(place)
		match index:
			0:
				_rect(place, "Worktop", Rect2(-90, -50, 180, 10), tone.lightened(0.25), 0)
				for x in [-75, 65]:
					_rect(place, "Leg%d" % x, Rect2(x, -40, 10, 40), tone, 0)
				for i in range(3):
					var x := -60 + i * 60
					_poly(place, "PaperLantern%d" % i, PackedVector2Array([Vector2(x - 17, -54), Vector2(x - 23, -85), Vector2(x, -103), Vector2(x + 23, -85), Vector2(x + 17, -54)]), Color(0.85, 0.69, 0.45), 0)
			1:
				_rect(place, "RainBarrel", Rect2(-95, -69, 62, 69), tone.darkened(0.22), 0)
				for y in [-55, -17]:
					_rect(place, "BarrelBand%d" % y, Rect2(-98, y, 68, 7), tone.lightened(0.3), 0)
				for i in range(3):
					var x := 8 + i * 42
					_poly(place, "SeedTray%d" % i, PackedVector2Array([Vector2(x - 16, 0), Vector2(x - 22, -24), Vector2(x + 22, -24), Vector2(x + 16, 0)]), tone.darkened(0.25), 0)
					_rect(place, "SeedStem%d" % i, Rect2(x - 3, -49 - i * 6, 6, 27 + i * 6), tone.lightened(0.35), 0)
			2:
				_rect(place, "OfferingBench", Rect2(-95, -36, 190, 11), tone.lightened(0.1), 0)
				for x in [-76, 66]:
					_rect(place, "BenchLeg%d" % x, Rect2(x, -25, 10, 25), tone, 0)
				for i in range(5):
					var x := -58 + i * 29
					_rect(place, "Votive%d" % i, Rect2(x - 4, -63, 8, 26), Color(0.85, 0.77, 0.6), 0)
			3:
				_poly(place, "Telescope", PackedVector2Array([Vector2(-52, -69), Vector2(71, -128), Vector2(84, -99), Vector2(-41, -45)]), tone.lightened(0.25), 0)
				_poly(place, "Tripod", PackedVector2Array([Vector2(-16, -64), Vector2(-65, 0), Vector2(-47, 0), Vector2(0, -45), Vector2(47, 0), Vector2(65, 0), Vector2(16, -64)]), tone, 0)
		var plaque := _label(place, "WorkplaceSign", ["PAPER LANTERN WORKSHOP", "THE SEED TENDER", "TRAVELERS' OFFERINGS", "NIGHT WATCH TELESCOPE"][index], Vector2(-160, -185), 320)
		plaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plaque.add_theme_font_size_override("font_size", 12)
		plaque.add_theme_constant_override("outline_size", 4)


func _build_connections() -> void:
	# Meet terrace rims, not their middles: the same stairs must be usable
	# going down without walking off a distant edge and missing the route.
	_stairs("WestGrandStair", Vector2(430, 400), Vector2(930, -300))
	_stairs("GardenGrandStair", Vector2(6090, 400), Vector2(5890, -620))
	_stairs("ArtisanSkyStair", Vector2(2380, -300), Vector2(2810, -620))
	_deck("CrossCitySkybridge", Vector2(3320, -620), 1040, Color(0.45, 0.46, 0.61))
	_stairs("ArchiveBellStair", Vector2(1450, -300), Vector2(2210, -1080))
	_stairs("GardenBellStair", Vector2(4820, -620), Vector2(4240, -1080))
	_stairs("CrownStair", Vector2(3700, -1080), Vector2(4310, -1600))
	_label(self, "WestWayfinding", "UPPER CITY  >\nARTISANS / BELLS / CROWN", Vector2(440, 242), 300)
	_label(self, "EastWayfinding", "<  HANGING GARDENS\nCROWN VIA BELL SQUARE", Vector2(5800, 245), 300)
	_label(self, "BridgeWayfinding", "<  ARTISANS     GARDENS  >", Vector2(3030, -684), 470)


func _stairs(stair_name: String, start: Vector2, finish: Vector2) -> void:
	var count := int(ceil(absf(finish.y - start.y) / 50.0))
	var route: Array = [start]
	var outline := PackedVector2Array([start + Vector2(-60, 12)])
	for i in range(1, count + 1):
		var point := start.lerp(finish, float(i) / count)
		_deck("%sStep%02d" % [stair_name, i], point, 132, Color(0.44, 0.45, 0.57))
		route.append(point)
		outline.append(point + Vector2(-60, 12))
	outline.append(finish + Vector2(60, 50))
	outline.append(start + Vector2(60, 50))
	_poly(self, stair_name + "Masonry", outline, Color(0.20, 0.23, 0.34), -5)
	stair_routes.append(route)


func _build_lift() -> void:
	for upper in [false, true]:
		var point := Vector2(5740, -1600) if upper else Vector2(5740, 400)
		var marker := Marker2D.new()
		marker.name = "CrownArrival" if upper else "StreetArrival"
		marker.position = point + Vector2(-85, -33)
		marker.add_to_group("citadel_crown_arrival" if upper else "citadel_street_arrival")
		add_child(marker)
		var lift := LIFT.instantiate()
		lift.name = "CrownLift" if upper else "StreetLift"
		lift.position = point + Vector2(0, -33)
		lift.shortcut_id = "starfall_city_crown_lift"
		lift.room_id = "starfall_citadel"
		lift.target_marker_group = &"citadel_street_arrival" if upper else &"citadel_crown_arrival"
		lift.activates_shortcut = upper
		lift.lift_label = "CROWN LIFT"
		lift.locked_prompt = "OPEN FROM THE CROWN"
		lift.locked_message = "Climb through Bell Square and release the lift at the Crown Observatory."
		add_child(lift)


func activate_room_population() -> void:
	if Engine.is_editor_hint() or population_loaded:
		return
	population_loaded = true
	_build_workplace_residents()
	var pairs := [["Iven", "Mara"], ["Orin", "Lysa"], ["Beren", "Nima"], ["Vey", "Aster"]]
	var stories := [
		["Lanterns and books: both are made to guide someone home.", "Take the western stair to Bell Square, or the skybridge to the gardens."],
		["These trees were carried up one seed at a time.", "The stair in the central garden climbs west to Bell Square. The east stair returns to the street."],
		["The three bells mark arrivals, departures and those we remember.", "The Crown Observatory is above the east end of this square."],
		["On a clear night, the lower market looks like another constellation.", "Release the crown lift before you leave. The lower station is beside the old observatory."],
	]
	for index in range(DISTRICTS.size()):
		var data: Array = DISTRICTS[index]
		var y: float = data[4]
		var x: float = [1200.0, 3850.0, 2470.0, 4520.0][index] - 140.0
		for stop in range(3):
			var marker := Marker2D.new()
			marker.name = "District%dStop%d" % [index, stop]
			marker.position = Vector2(x + [0, 90, 140][stop], y - 33)
			marker.add_to_group("town_interior" if stop == 2 else "town_social_spot")
			add_child(marker)
		for person in range(2):
			var npc := RESIDENT.instantiate()
			npc.name = pairs[index][person]
			npc.resident_name = pairs[index][person]
			npc.position = Vector2(x + person * 90, y - 33)
			npc.route_marker_names = PackedStringArray(["District%dStop%d" % [index, person], "District%dStop%d" % [index, 1 - person], "District%dStop2" % index])
			npc.talk_partner = NodePath("../" + pairs[index][1 - person])
			npc.dialogue_lines = PackedStringArray(stories[index])
			npc.social_lines = PackedStringArray([
				["The lantern frames are ready, Mara.", "I will bring the paper shades, Iven."],
				["The new seeds have taken root, Lysa.", "Leave some water for the eastern beds, Orin."],
				["One bell for every traveler, Nima.", "Then let us hope for a busy day, Beren."],
				["The northern star is clear tonight, Aster.", "I have marked it on the chart, Vey."],
			][index])
			npc.victory_dialogue_lines = PackedStringArray(["The Sovereign is gone. Tonight the upper city keeps every lantern lit."])
			npc.coat_color = data[5]
			npc.accent_color = Color(0.91, 0.81, 0.63)
			add_child(npc)
		var plaque := PLAQUE.instantiate()
		plaque.name = "Landmark%d" % index
		plaque.position = Vector2(float(data[3]) - 285, y - 33)
		plaque.shortcut_id = EVENTS[index]
		plaque.inactive_label = ["LANTERN MAKERS", "SEED GARDEN", "THREE BELLS", "CROWN STAR CHART"][index]
		plaque.active_label = plaque.inactive_label + " - RECORDED"
		plaque.inactive_prompt = "[E] RECORD CITY LANDMARK"
		plaque.active_prompt = "LANDMARK RECORDED"
		add_child(plaque)
	survey_label = _label(self, "CitySurvey", "", Vector2(4780, -1680), 410)
	var cache := CACHE.instantiate()
	cache.name = "CitySurveyReward"
	cache.position = Vector2(5230, -1633)
	cache.cache_id = "starfall_city_survey"
	cache.cache_name = "Citadel Cartographer's Gift"
	cache.gold_reward = 25
	cache.reward_item_id = "ether_dust"
	cache.required_event_ids = PackedStringArray(EVENTS)
	add_child(cache)
	var state := get_node("/root/GameState")
	state.shortcut_changed.connect(_update_survey)
	state.cache_opened.connect(_update_survey)
	_update_survey("")


func _build_workplace_residents() -> void:
	var names := ["Lune, Lantern Maker", "Sera, Seed Tender", "Daro, Bell Attendant", "Cael, Night Watch"]
	var lines := [
		["Every traveler gets a different lantern pattern. No two windows should tell the same story.", "Visit the eastern end of each upper district to record its landmark. The crown cartographer keeps the survey gift."],
		["A broken wall can shelter a seed. That is how these hanging gardens began.", "Beyond the city, the Rooted Hall has two dormant seedbeds. They need its original root channel before they can bloom."],
		["We leave a candle for those still on the road. You need not bring coin.", "Senna's field office on the lower street tracks tasks, guardians and reserves separately. Missing one does not erase the others."],
		["The telescope looks past the city's lights. Some stars only appear when you stop rushing.", "The sovereign's gate needs its original sigils. Field tasks and city landmarks are optional discoveries, not substitutes."],
	]
	for index in range(4):
		var place := get_node("Workplace%d" % index) as Node2D
		for stop in range(3):
			var marker := Marker2D.new()
			marker.name = "Workplace%dStop%d" % [index, stop]
			marker.position = place.position + Vector2([-125, -60, 0][stop], -24)
			marker.add_to_group("town_interior" if stop == 2 else "town_social_spot")
			add_child(marker)
		var npc := RESIDENT.instantiate()
		npc.name = "WorkplaceResident%d" % index
		npc.resident_name = names[index]
		npc.position = place.position + Vector2(-125, -24)
		npc.route_marker_names = PackedStringArray(["Workplace%dStop0" % index, "Workplace%dStop1" % index, "Workplace%dStop2" % index])
		npc.walk_speed = 17
		npc.dialogue_lines = PackedStringArray(lines[index])
		npc.victory_dialogue_lines = PackedStringArray(["Tonight the upper city keeps its lights on for those returning home.", lines[index][1]])
		npc.coat_color = DISTRICTS[index][5]
		add_child(npc)
		var label := npc.get_node("NameLabel") as Label
		label.position = Vector2(-130, -75)
		label.size.x = 260
		label.add_theme_constant_override("outline_size", 4)


func _update_survey(_event: String) -> void:
	var state := get_node("/root/GameState")
	var found := 0
	for event in EVENTS:
		found += int(bool(state.unlocked_shortcuts.get(event, false)))
	survey_label.text = "CITY LANDMARKS %d/4\n%s" % [found, "GIFT COLLECTED" if bool(state.opened_caches.get("starfall_city_survey", false)) else ("CARTOGRAPHER'S GIFT READY" if found == 4 else "VISIT ALL FOUR UPPER DISTRICTS")]


func _deck(deck_name: String, point: Vector2, width: float, tone: Color) -> void:
	var body := StaticBody2D.new()
	body.name = deck_name
	body.position = point
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 14)
	collision.shape = shape
	collision.one_way_collision = true
	body.add_child(collision)
	_rect(body, "Stone", Rect2(-width / 2, -7, width, 14), tone)
	add_child(body)


func _house(parent: Node2D, base: Vector2, size: Vector2, tone: Color) -> void:
	var house := Node2D.new()
	house.name = "House%d" % int(base.x)
	house.position = base
	parent.add_child(house)
	_rect(house, "Facade", Rect2(-size.x / 2, -size.y, size.x, size.y), tone.darkened(0.4))
	_poly(house, "Roof", PackedVector2Array([Vector2(-size.x / 2 - 18, -size.y), Vector2(-size.x * 0.22, -size.y - 50), Vector2(size.x * 0.31, -size.y - 35), Vector2(size.x / 2 + 18, -size.y)]), tone, -3)
	_rect(house, "Door", Rect2(-19, -58, 38, 58), Color(0.12, 0.16, 0.23))
	for side in [-1, 1]:
		for row in range(2):
			_rect(house, "Window%d_%d" % [side, row], Rect2(side * size.x * 0.28 - 12, -size.y + 25 + row * 45, 24, 30), Color(0.82, 0.76, 0.53, 0.85))


func _rect(parent: Node2D, node_name: String, rect: Rect2, color: Color, depth: int = -2) -> void:
	_poly(parent, node_name, PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), color, depth)


func _poly(parent: Node2D, node_name: String, points: PackedVector2Array, color: Color, depth: int) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = depth
	parent.add_child(polygon)


func _label(parent: Node2D, node_name: String, caption: String, point: Vector2, width: float) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = caption
	label.position = point
	label.size = Vector2(width, 54)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.modulate = Color(0.82, 0.88, 1)
	parent.add_child(label)
	return label
