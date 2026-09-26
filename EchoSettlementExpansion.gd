@tool
extends Node2D

# The original Haven court and outer arch remain intact. These authored
# districts extend them into a climbable settlement and a long warded approach.
const RESIDENT: PackedScene = preload("res://TownResident.tscn")
const SERVICE: PackedScene = preload("res://TownService.tscn")
const DOOR: PackedScene = preload("res://RoomDoor.tscn")
const SHADE: PackedScene = preload("res://EchoShade.tscn")
const WISP: PackedScene = preload("res://ShaftWisp.tscn")
const NEUTRAL: PackedScene = preload("res://NeutralCreature.tscn")
const CRATE: PackedScene = preload("res://DestructibleCrate.tscn")
const CACHE: PackedScene = preload("res://ResonanceCache.tscn")
const DISCOVERY_BOARD := preload("res://EchoDiscoveryBoard.gd")

const RISE := 220.0
const DISTRICT_PATHS := {
	"haven": [1180.0, 3900.0, 2250.0, 4250.0, 2900.0, 1400.0, 4300.0],
	"outskirts": [1100.0, 3000.0, 1450.0, 3500.0, 2100.0, 1250.0, 3600.0],
}
@export_enum("haven", "outskirts") var district: String = "haven"

var start_x: float
var end_x: float
var base_y := 166.0
var accent: Color
var ledges: Dictionary = {}
var population_loaded := false


func _ready() -> void:
	if district == "haven":
		start_x = 1180.0
		end_x = 4300.0
		accent = Color(0.29, 0.71, 0.68)
	else:
		start_x = 1100.0
		end_x = 3600.0
		accent = Color(0.23, 0.66, 0.69)
	if _use_schematic_editor_preview():
		# Safe districts need to read as settlements in Game.tscn, not as a
		# wireframe traversal graph. Population remains runtime-only.
		_build_cavern()
		_build_streets()
		_build_transition_square()
		_build_neighborhoods()
		_build_street_details()
		if district == "haven":
			_build_haven_life()
		else:
			_build_outer_life()
		return
	_build_cavern()
	_build_streets()
	_build_transition_square()
	_build_neighborhoods()
	_build_street_details()
	if Engine.is_editor_hint():
		return
	if not _uses_world_population_streaming():
		activate_room_population()


func _uses_world_population_streaming() -> bool:
	var room := get_parent()
	return room != null and room.get_parent() != null and room.get_parent().get_node_or_null("RoomActivityDirector") != null


func activate_room_population() -> void:
	if Engine.is_editor_hint() or population_loaded:
		return
	if district == "haven":
		_build_haven_life()
		var records := Node2D.new()
		records.name = "DiscoveryBoard"
		records.set_script(DISCOVERY_BOARD)
		records.position = ledges[2][1]
		add_child(records)
	else:
		_build_outer_life()
	population_loaded = true


func is_population_loaded() -> bool:
	return population_loaded


func _path() -> Array:
	return (DISTRICT_PATHS[district] as Array).duplicate()


func _use_schematic_editor_preview() -> bool:
	if not Engine.is_editor_hint():
		return false
	var edited_root := get_tree().edited_scene_root
	return edited_root != null and edited_root != get_parent()


func _build_route_preview() -> void:
	var path := _path()
	var points := PackedVector2Array([Vector2(float(path[0]), base_y)])
	for tier in range(6):
		var y := base_y - float(tier) * RISE
		points.append(Vector2(float(path[tier + 1]), y))
		if tier < 5:
			points.append(Vector2(float(path[tier + 1]), y - RISE))
	var shadow := Line2D.new()
	shadow.name = "TownTopology"
	shadow.width = 46.0
	shadow.default_color = Color(0.025, 0.072, 0.115, 0.94)
	shadow.points = points
	add_child(shadow)
	var route_line := Line2D.new()
	route_line.name = "TownRoute"
	route_line.width = 6.0
	route_line.default_color = accent.lightened(0.28)
	route_line.points = points
	add_child(route_line)
	for tier in [2, 4]:
		var anchor := Vector2(lerpf(float(path[tier]), float(path[tier + 1]), 0.5), base_y - float(tier) * RISE)
		var side := -1.0 if anchor.x > (start_x + end_x) * 0.5 else 1.0
		var lane := Line2D.new()
		lane.name = "TownDeadEnd%d" % tier
		lane.width = 21.0
		lane.default_color = Color(accent, 0.60)
		lane.points = PackedVector2Array([anchor, anchor + Vector2(side * 145.0, -115.0), anchor + Vector2(side * 510.0, -115.0)])
		add_child(lane)


func _build_cavern() -> void:
	var dark := Color(0.025, 0.072, 0.115) if district == "haven" else Color(0.018, 0.047, 0.09)
	var path := _path()
	for tier in range(6):
		var y := base_y - float(tier) * RISE
		var left := minf(float(path[tier]), float(path[tier + 1]))
		var right := maxf(float(path[tier]), float(path[tier + 1]))
		var pocket_left := left - 110.0
		var pocket_right := right + 110.0
		var pocket_width := pocket_right - pocket_left
		_poly("DistrictPocket%02d" % tier, PackedVector2Array([
			Vector2(pocket_left, y + 55.0), Vector2(pocket_left - 18.0, y - 36.0),
			Vector2(pocket_left + pocket_width * 0.08, y - 139.0 - float((tier * 19) % 38)),
			Vector2(pocket_left + pocket_width * 0.27, y - 188.0 + float((tier * 13) % 31)),
			Vector2(pocket_left + pocket_width * 0.49, y - 158.0 - float((tier * 23) % 29)),
			Vector2(pocket_left + pocket_width * 0.71, y - 198.0 + float((tier * 17) % 37)),
			Vector2(pocket_left + pocket_width * 0.91, y - 142.0 - float((tier * 11) % 33)),
			Vector2(pocket_right + 18.0, y - 41.0), Vector2(pocket_right, y + 55.0),
		]), dark, -9)
		var rib_count := clampi(int((right - left) / 430.0), 2, 7)
		for index in range(rib_count):
			var x := left + 85.0 + float(index) * (right - left - 170.0) / float(maxi(1, rib_count - 1))
			var tip := y - 175.0 + float((index * 73 + tier * 37 + district.length() * 17) % 80)
			_poly("CavernRib%02d_%02d" % [tier, index], PackedVector2Array([Vector2(x - 92.0, y + 22.0), Vector2(x - 35.0, tip), Vector2(x + 18.0, tip + 75.0), Vector2(x + 94.0, y + 22.0)]), accent.darkened(0.78), -8)
		if tier < 5:
			var shaft_x: float = path[tier + 1]
			_poly("DistrictShaft%02d" % tier, PackedVector2Array([Vector2(shaft_x - 125.0, y - RISE - 25.0), Vector2(shaft_x + 125.0, y - RISE - 25.0), Vector2(shaft_x + 125.0, y + 35.0), Vector2(shaft_x - 125.0, y + 35.0)]), dark, -9)
	var current := Line2D.new()
	current.name = "HavenCurrent"
	current.z_index = -5
	current.width = 4.0
	current.default_color = Color(accent.r, accent.g, accent.b, 0.32)
	current.points = PackedVector2Array([Vector2(float(path[0]), base_y - 40.0), Vector2(float(path[2]), base_y - RISE - 75.0), Vector2(float(path[4]), base_y - RISE * 3.0 - 75.0), Vector2(float(path[6]), base_y - RISE * 5.0 - 80.0)])
	add_child(current)


func _build_streets() -> void:
	var path := _path()
	_rect("NewLowerStreet", Vector2(start_x + 100.0, base_y), Vector2(200.0, 18.0), accent.darkened(0.48))
	_rect("FarCavernWall", Vector2(float(path.back()), base_y - 5.0 * RISE - 85.0), Vector2(14.0, 310.0), accent.darkened(0.63))
	var shelf_count := 5 if district == "haven" else 6
	for tier in range(6):
		var y := base_y - float(tier) * RISE
		var leg_start: float = path[tier]
		var leg_finish: float = path[tier + 1]
		var direction := 1.0 if leg_finish > leg_start else -1.0
		var gap := 55.0 + float((tier * 7 + district.length()) % 10)
		var usable := absf(leg_finish - leg_start) - 56.0
		var width := (usable - gap * float(shelf_count - 1)) / float(shelf_count)
		var sites: Array[Vector2] = []
		for index in range(shelf_count):
			var center_x := leg_start + direction * (28.0 + width * 0.5 + float(index) * (width + gap))
			var contour: Array = [0.0, -28.0, 30.0, -22.0, 24.0, 0.0]
			var walk_y := y + (0.0 if index == 0 or index == shelf_count - 1 else float(contour[index]))
			if index == shelf_count / 2:
				walk_y = y + 45.0
			var center := Vector2(center_x, walk_y)
			var thickness := 18.0 if tier == 0 and index == 0 else 14.0
			_rect("Tier%02dStreet%02d" % [tier, index], center, Vector2(width, thickness), accent.darkened(0.2 - float(tier % 2) * 0.06), true)
			sites.append(center)
		ledges[tier] = sites
		if tier < 5:
			for step in range(1, 4):
				var x := leg_finish + (-1.0 if direction > 0.0 else 1.0) * (62.0 + float(step % 2) * 40.0)
				_rect("Tier%02dStair%02d" % [tier + 1, step], Vector2(x, y - float(step) * 55.0), Vector2(140.0, 12.0), accent.lightened(0.12), true)
		var pocket: Vector2 = sites[shelf_count / 2]
		_poly("AlleyCut%02d" % tier, PackedVector2Array([Vector2(pocket.x - 80.0, y - 148.0), Vector2(pocket.x - 45.0, y - 18.0), Vector2(pocket.x - 62.0, pocket.y + 8.0), Vector2(pocket.x + 55.0, pocket.y + 8.0), Vector2(pocket.x + 46.0, y - 40.0), Vector2(pocket.x + 103.0, y - 148.0)]), accent.darkened(0.61), -4)
		if tier % 2 == 0:
			_rect("Tier%02dRoofNook" % tier, sites[1] + Vector2(65.0, -70.0), Vector2(180.0, 12.0), accent.lightened(0.16), true)


func _build_transition_square() -> void:
	# The original 900px court is kept as the oldest quarter. A broad gate
	# square makes it read as the entrance to one continuous settlement instead
	# of a small old room with a new platform course pasted beside it.
	var old_edge: float = 900.0
	var plaza_end: float = start_x + 430.0
	# Match the original street's top surface; a thicker overlapping body
	# creates a tiny vertical lip that catches a walking CharacterBody2D.
	_rect("OldQuarterBridge", Vector2((old_edge + plaza_end) * 0.5, base_y), Vector2(plaza_end - old_edge, 18.0), accent.darkened(0.34))
	var gate_x: float = start_x + 45.0
	for side: float in [-1.0, 1.0]:
		var x: float = gate_x + side * 115.0
		_poly("QuarterGateTower%s" % ("L" if side < 0.0 else "R"), PackedVector2Array([
			Vector2(x - 48.0, base_y - 8.0), Vector2(x - 48.0, base_y - 184.0),
			Vector2(x - 63.0, base_y - 211.0), Vector2(x, base_y - 242.0),
			Vector2(x + 63.0, base_y - 211.0), Vector2(x + 48.0, base_y - 184.0),
			Vector2(x + 48.0, base_y - 8.0),
		]), accent.darkened(0.48), -2)
	_poly("QuarterGateArch", PackedVector2Array([
		Vector2(gate_x - 123.0, base_y - 188.0), Vector2(gate_x - 96.0, base_y - 224.0),
		Vector2(gate_x, base_y - 258.0), Vector2(gate_x + 96.0, base_y - 224.0),
		Vector2(gate_x + 123.0, base_y - 188.0), Vector2(gate_x + 94.0, base_y - 171.0),
		Vector2(gate_x, base_y - 204.0), Vector2(gate_x - 94.0, base_y - 171.0),
	]), accent.lightened(0.10), -1)
	_label("OldQuarterSign", "WHISPERLIGHT LOWER GATE" if district == "haven" else "WARD ROAD", Vector2(gate_x - 145.0, base_y - 296.0), 290.0, 11, accent.lightened(0.48))
	for stall in range(3):
		var stall_x: float = start_x + 235.0 + float(stall) * 145.0
		_poly("GateAwning%02d" % stall, PackedVector2Array([
			Vector2(stall_x - 58.0, base_y - 75.0), Vector2(stall_x + 58.0, base_y - 75.0),
			Vector2(stall_x + 43.0, base_y - 49.0), Vector2(stall_x - 43.0, base_y - 49.0),
		]), Color(accent.r, accent.g, accent.b, 0.72), -1)


func _build_neighborhoods() -> void:
	var lower_sites: Array = ledges[0]
	for index in range(lower_sites.size()):
		var home_site: Vector2 = lower_sites[index]
		_house("LowerHome%02d" % index, home_site + Vector2(0.0, -12.0), Vector2(190.0 + float(index % 2) * 28.0, 112.0), accent.darkened(0.53), accent.lightened(0.21))
	for tier in range(1, 6):
		var sites: Array = ledges[tier]
		for house_index in range(2):
			var site: Vector2 = sites[1 + house_index * (sites.size() - 3)]
			_house("TerraceHome%02d_%02d" % [tier, house_index], site + Vector2(0.0, -9.0), Vector2(175.0 + float((tier + house_index) % 3) * 22.0, 105.0 + float(tier % 2) * 18.0), accent.darkened(0.55), accent.lightened(0.19))
		_label("QuarterSign%02d" % tier, _quarter_name(tier), Vector2(sites[0].x - 95.0, sites[0].y - 92.0), 250.0, 11, accent.lightened(0.43))
		var first_site: Vector2 = ledges[tier][0]
		var last_site: Vector2 = ledges[tier][-1]
		var left := minf(first_site.x, last_site.x)
		var right := maxf(first_site.x, last_site.x)
		for garden in range(6):
			var x := left + 80.0 + (right - left - 160.0) * float(garden) / 5.0
			var gy := base_y - float(tier) * RISE
			_poly("Garden%02d_%02d" % [tier, garden], PackedVector2Array([Vector2(x - 15.0, gy - 8.0), Vector2(x - 4.0, gy - 47.0), Vector2(x + 3.0, gy - 59.0), Vector2(x + 12.0, gy - 8.0)]), Color(accent.r, accent.g, accent.b, 0.68), -1)
	if district == "outskirts":
		var ward_y := base_y - 5.0 * RISE
		_poly("GrandGateLeft", PackedVector2Array([Vector2(end_x - 185.0, ward_y - 10.0), Vector2(end_x - 185.0, ward_y - 171.0), Vector2(end_x - 162.0, ward_y - 200.0), Vector2(end_x - 136.0, ward_y - 171.0), Vector2(end_x - 136.0, ward_y - 10.0)]), accent.lightened(0.09), -1)
		_poly("GrandGateRight", PackedVector2Array([Vector2(end_x - 58.0, ward_y - 10.0), Vector2(end_x - 58.0, ward_y - 171.0), Vector2(end_x - 35.0, ward_y - 200.0), Vector2(end_x - 9.0, ward_y - 171.0), Vector2(end_x - 9.0, ward_y - 10.0)]), accent.lightened(0.09), -1)
		_poly("GrandGateLintel", PackedVector2Array([Vector2(end_x - 193.0, ward_y - 178.0), Vector2(end_x, ward_y - 178.0), Vector2(end_x - 14.0, ward_y - 151.0), Vector2(end_x - 180.0, ward_y - 151.0)]), accent.lightened(0.2), -1)
		_label("WardLabel", "WHISPERLIGHT GATE", Vector2(end_x - 267.0, ward_y - 243.0), 265.0, 13, accent.lightened(0.48))
		_label("DangerLimit", "WARD LIGHT AHEAD", Vector2(end_x - 540.0, ward_y + 62.0), 260.0, 10, accent.lightened(0.31))
	else:
		var sky: Vector2 = ledges[5][2]
		_poly("SkyGardenCanopy", PackedVector2Array([sky + Vector2(-188.0, -28.0), sky + Vector2(-133.0, -172.0), sky + Vector2(0.0, -219.0), sky + Vector2(137.0, -172.0), sky + Vector2(190.0, -28.0)]), Color(accent.r, accent.g, accent.b, 0.21), -3)
		_label("SkyGardenSign", "THE SKY GARDEN", sky + Vector2(-105.0, -99.0), 220.0, 13, accent.lightened(0.5))


func _build_street_details() -> void:
	# Houses establish scale; these smaller props make each route segment read
	# as a used street rather than empty traversal geometry.
	for tier in range(6):
		var sites: Array = ledges[tier]
		var street_y: float = base_y - float(tier) * RISE
		for lantern_index in range(3):
			var site: Vector2 = sites[clampi(lantern_index * 2, 0, sites.size() - 1)]
			var x: float = site.x + (-34.0 if lantern_index % 2 == 0 else 34.0)
			_poly("QuarterLantern%02d_%02d" % [tier, lantern_index], PackedVector2Array([
				Vector2(x - 4.0, site.y - 8.0), Vector2(x - 3.0, site.y - 73.0),
				Vector2(x + 3.0, site.y - 73.0), Vector2(x + 4.0, site.y - 8.0),
			]), accent.lightened(0.15), -1)
			_poly("QuarterGlow%02d_%02d" % [tier, lantern_index], PackedVector2Array([
				Vector2(x - 13.0, site.y - 74.0), Vector2(x, site.y - 91.0), Vector2(x + 13.0, site.y - 74.0), Vector2(x, site.y - 61.0),
			]), Color(accent.r, accent.g, accent.b, 0.78), 0)
		var bench: Vector2 = sites[sites.size() / 2]
		_poly("StreetBench%02d" % tier, PackedVector2Array([
			bench + Vector2(-52.0, -25.0), bench + Vector2(52.0, -25.0),
			bench + Vector2(48.0, -13.0), bench + Vector2(-48.0, -13.0),
		]), accent.darkened(0.38), -1)
		for foot in [-38.0, 38.0]:
			_poly("BenchFoot%02d_%s" % [tier, "L" if foot < 0.0 else "R"], PackedVector2Array([
				bench + Vector2(foot - 4.0, -14.0), bench + Vector2(foot + 4.0, -14.0),
				bench + Vector2(foot + 4.0, -5.0), bench + Vector2(foot - 4.0, -5.0),
			]), accent.darkened(0.48), -1)
		if tier in [1, 3, 5]:
			var left_home: Vector2 = sites[1]
			var right_home: Vector2 = sites[sites.size() - 2]
			var laundry := Line2D.new()
			laundry.name = "LaundryLine%02d" % tier
			laundry.z_index = -1
			laundry.width = 2.0
			laundry.default_color = Color(accent.r, accent.g, accent.b, 0.47)
			laundry.points = PackedVector2Array([left_home + Vector2(0.0, -115.0), Vector2((left_home.x + right_home.x) * 0.5, street_y - 142.0), right_home + Vector2(0.0, -115.0)])
			add_child(laundry)
			for cloth in range(4):
				var cx := lerpf(left_home.x, right_home.x, 0.2 + float(cloth) * 0.2)
				_poly("HangingCloth%02d_%02d" % [tier, cloth], PackedVector2Array([
					Vector2(cx - 14.0, street_y - 133.0), Vector2(cx + 14.0, street_y - 133.0),
					Vector2(cx + 10.0, street_y - 94.0), Vector2(cx - 11.0, street_y - 101.0),
				]), Color(accent.lightened(0.12), 0.58), -1)
		if tier % 2 == 0:
			var stall: Vector2 = sites[sites.size() - 2]
			_poly("QuarterStall%02d" % tier, PackedVector2Array([
				stall + Vector2(-62.0, -64.0), stall + Vector2(62.0, -64.0),
				stall + Vector2(49.0, -39.0), stall + Vector2(-49.0, -39.0),
			]), Color(accent.r, accent.g, accent.b, 0.64), -1)
			for post in [-46.0, 46.0]:
				_poly("StallPost%02d_%s" % [tier, "L" if post < 0.0 else "R"], PackedVector2Array([
					stall + Vector2(post - 3.0, -40.0), stall + Vector2(post + 3.0, -40.0),
					stall + Vector2(post + 3.0, -7.0), stall + Vector2(post - 3.0, -7.0),
				]), accent.darkened(0.42), -1)


func _build_haven_life() -> void:
	var lower: Array = ledges[0]
	var trader_site: Vector2 = lower[1]
	var smith_site: Vector2 = lower[3]
	_service("CanalTrader", trader_site + Vector2(0.0, -36.0), "shop", "Canal Trade", Color(0.42, 0.86, 0.77))
	_service("MoonSmith", smith_site + Vector2(0.0, -36.0), "anvil", "Moon Forge", Color(0.55, 0.82, 0.94))
	for tier in [1, 3, 5]:
		var sites: Array = ledges[tier]
		var site: Vector2 = sites[1]
		var names := ["Elen", "Rovan"] if tier == 1 else (["Pelis", "Aven"] if tier == 3 else ["Rika", "Sorel"])
		_marker("Social%02dWest" % tier, site + Vector2(-71.0, -33.0), true)
		_marker("Social%02dEast" % tier, site + Vector2(69.0, -33.0), true)
		_marker("Home%02dDoor" % tier, site + Vector2(0.0, -33.0), false, true)
		_resident(names[0], site + Vector2(-54.0, -33.0), ["Social%02dWest" % tier, "Home%02dDoor" % tier, "Social%02dEast" % tier], ["This terrace has its own paths and houses above the market.", "The lanterns make the climb feel like home."], Color(0.31, 0.43, 0.51), Color(0.59, 0.91, 0.83))
		_resident(names[1], site + Vector2(56.0, -33.0), ["Social%02dEast" % tier, "Social%02dWest" % tier], ["Each quarter sounds different when the crystals wake.", "I carry news between the roofs and the lower square."], Color(0.36, 0.39, 0.52), Color(0.74, 0.87, 0.91))
		get_node(names[0]).talk_partner = NodePath("../" + names[1])
		get_node(names[1]).talk_partner = NodePath("../" + names[0])
	var extra_residents := [
		["Mira", 0, 2, ["The lower gate never truly sleeps.", "I help arriving travelers find the right quarter."]],
		["Tovan", 2, 3, ["These roof gardens feed more homes than they appear to.", "Mind the wet stones near the canal rail."]],
		["Lio", 4, 1, ["I carry fresh lamp oil to the high homes.", "The quickest way down is not always the safest one."]],
	]
	for data in extra_residents:
		var tier: int = int(data[1])
		var site: Vector2 = ledges[tier][int(data[2])]
		var first_marker := "%sWalkA" % String(data[0])
		var second_marker := "%sWalkB" % String(data[0])
		_marker(first_marker, site + Vector2(-75.0, -33.0), tier % 2 == 0)
		_marker(second_marker, site + Vector2(75.0, -33.0), true)
		_resident(String(data[0]), site + Vector2(0.0, -33.0), [first_marker, second_marker], data[3], Color(0.32, 0.43, 0.50), accent.lightened(0.33))
	var garden: Vector2 = ledges[5][2]
	var cache := CACHE.instantiate()
	cache.name = "SkyGardenCache"
	cache.position = garden + Vector2(0.0, -34.0)
	cache.cache_id = "haven_sky_garden"
	cache.cache_name = "Sky Garden Offering"
	cache.gold_reward = 30
	cache.reward_item_id = "ether_dust"
	add_child(cache)


func _build_outer_life() -> void:
	for tier in range(4):
		var sites: Array = ledges.get(tier, [])
		var spot: Vector2 = sites[1]
		var enemy: Node2D = (SHADE if tier % 2 == 0 else WISP).instantiate()
		enemy.name = "OuterPatrol%02d" % tier
		enemy.position = spot + Vector2(0.0, -33.0 if tier % 2 == 0 else -85.0)
		enemy.set("zone_id", "echo_grotto")
		add_child(enemy)
		var crate := CRATE.instantiate()
		crate.name = "ApproachCrate%02d" % tier
		crate.position = sites[0] + Vector2(0.0, -27.0)
		crate.empty_drop_chance = 0.3
		crate.item_drop_chance = 0.2
		add_child(crate)
	for index in range(4):
		var moth := NEUTRAL.instantiate()
		moth.name = "OuterMoth%d" % index
		var moth_tier := mini(index * 2, 5)
		var street_index: int = 0 if index % 2 == 0 else ledges[moth_tier].size() - 1
		moth.position = ledges[moth_tier][street_index] + Vector2(0.0, -31.0)
		var roam := _street_walk_radius(moth_tier, street_index, 62.0)
		moth.get_node("LeftPoint").position.x = -roam
		moth.get_node("RightPoint").position.x = roam
		moth.creature_name = "Lumen Moth" if index < 2 else "Ward Skimmer"
		moth.zone_id = "echo_grotto"
		moth.start_resting = index == 0
		moth.passive_tint = accent.lightened(0.35)
		add_child(moth)
	var ward: Vector2 = ledges[5][5]
	_marker("WardGatherWest", ward + Vector2(-130.0, -33.0), true)
	_marker("WardGatherEast", ward + Vector2(-20.0, -33.0), true)
	_resident("WardKeeper", ward + Vector2(-120.0, -33.0), ["WardGatherWest", "WardGatherEast"], ["The echoes lose their teeth inside the gate light.", "Beyond this arch is the Haven. No blades are needed there."], Color(0.3, 0.47, 0.5), Color(0.6, 0.95, 0.86))
	_resident("GateCourier", ward + Vector2(-30.0, -33.0), ["WardGatherEast", "WardGatherWest"], ["I bring messages from the upper quarter.", "Follow the lit platforms if you need to return outside."], Color(0.37, 0.43, 0.57), Color(0.77, 0.9, 0.96))
	get_node("WardKeeper").talk_partner = NodePath("../GateCourier")
	get_node("GateCourier").talk_partner = NodePath("../WardKeeper")
	for traveler_data in [["RoadMender", 1], ["MossHerder", 3]]:
		var tier: int = int(traveler_data[1])
		var site: Vector2 = ledges[tier][ledges[tier].size() / 2]
		var west := "%sWest" % String(traveler_data[0])
		var east := "%sEast" % String(traveler_data[0])
		var walk_radius := _street_walk_radius(tier, ledges[tier].size() / 2, 95.0)
		_marker(west, site + Vector2(-walk_radius, -33.0), true)
		_marker(east, site + Vector2(walk_radius, -33.0), true)
		_resident(String(traveler_data[0]), site + Vector2(0.0, -33.0), [west, east], ["The ward road is safer when someone keeps its stones clear.", "I only travel while the gate lights are visible."], Color(0.28, 0.43, 0.47), accent.lightened(0.26))
	var return_door := DOOR.instantiate()
	return_door.name = "ApproachReturnDoor"
	return_door.position = Vector2(float(_path().back()) - 120.0, base_y - 5.0 * RISE - 33.0)
	return_door.target_room_id = "echo_haven_outskirts"
	return_door.target_marker_group = &"echo_haven_outskirts_entry"
	return_door.door_label = "OUTER RETURN"
	add_child(return_door)


func _street_walk_radius(tier: int, index: int, requested: float) -> float:
	# Residents walk without gravity. Keep both ends on the SAME solid terrace,
	# including a body-width margin, rather than snapping across a street gap.
	var street := get_node("Tier%02dStreet%02d/CollisionShape2D" % [tier, index]) as CollisionShape2D
	return minf(requested, (street.shape as RectangleShape2D).size.x * 0.5 - 25.0)


func _quarter_name(tier: int) -> String:
	if district == "outskirts":
		return ["", "SHARD ROAD", "BROKEN WATCH", "CRYSTAL CUT", "WARD APPROACH", "GATE QUARTER"][tier]
	return ["", "LANTERN WALK", "CANAL ROOFS", "MOON MARKET", "HIGH HOMES", "SKY GARDEN"][tier]


func _resident(node_name: String, at: Vector2, stops: Array, lines: Array, coat: Color, trim: Color) -> void:
	var npc := RESIDENT.instantiate()
	npc.name = node_name
	npc.position = at
	npc.resident_name = node_name
	npc.route_marker_names = PackedStringArray(stops)
	npc.dialogue_lines = PackedStringArray(lines)
	npc.social_lines = PackedStringArray(["The lamps are bright tonight.", "I can hear footsteps along the upper walk."])
	npc.coat_color = coat
	npc.accent_color = trim
	npc.walk_speed = 24.0
	npc.get_node("NameLabel").text = node_name
	npc.get_node("Coat").color = coat
	npc.get_node("Accent").color = trim
	add_child(npc)


func _service(node_name: String, at: Vector2, kind: String, label: String, tint: Color) -> void:
	var service := SERVICE.instantiate()
	service.name = node_name
	service.position = at
	service.service_kind = kind
	service.service_id = "echo_haven_shop" if kind == "shop" else "echo_haven_anvil"
	service.service_name = label
	service.service_color = tint
	service.get_node("NameLabel").text = label
	service.get_node("Sign").color = tint
	add_child(service)


func _marker(node_name: String, at: Vector2, social: bool = false, interior: bool = false) -> void:
	var marker := Marker2D.new()
	marker.name = node_name
	marker.position = at
	if social:
		marker.add_to_group("town_social_spot")
	if interior:
		marker.add_to_group("town_interior")
	add_child(marker)


func _house(node_name: String, foot: Vector2, size: Vector2, stone: Color, window: Color) -> void:
	var variant := absi(node_name.hash()) % 3
	var body := Polygon2D.new()
	body.name = node_name
	body.z_index = -3
	body.color = stone
	if variant == 0:
		body.polygon = PackedVector2Array([foot + Vector2(-size.x * 0.5, 0.0), foot + Vector2(-size.x * 0.5, -size.y + 24.0), foot + Vector2(0.0, -size.y - 22.0), foot + Vector2(size.x * 0.5, -size.y + 24.0), foot + Vector2(size.x * 0.5, 0.0)])
	elif variant == 1:
		body.polygon = PackedVector2Array([foot + Vector2(-size.x * 0.5, 0.0), foot + Vector2(-size.x * 0.5, -size.y), foot + Vector2(size.x * 0.28, -size.y), foot + Vector2(size.x * 0.5, -size.y + 31.0), foot + Vector2(size.x * 0.5, 0.0)])
	else:
		body.polygon = PackedVector2Array([foot + Vector2(-size.x * 0.5, 0.0), foot + Vector2(-size.x * 0.43, -size.y + 8.0), foot + Vector2(-size.x * 0.12, -size.y - 34.0), foot + Vector2(size.x * 0.43, -size.y + 8.0), foot + Vector2(size.x * 0.5, 0.0)])
	add_child(body)
	var roof := Polygon2D.new()
	roof.name = node_name + "Roof"
	roof.z_index = -2
	roof.color = stone.lightened(0.18)
	roof.polygon = PackedVector2Array([foot + Vector2(-size.x * 0.57, -size.y + 22.0), foot + Vector2(0.0, -size.y - 25.0), foot + Vector2(size.x * 0.57, -size.y + 22.0), foot + Vector2(size.x * 0.45, -size.y + 30.0), foot + Vector2(0.0, -size.y - 7.0), foot + Vector2(-size.x * 0.45, -size.y + 30.0)])
	add_child(roof)
	if variant == 1:
		_poly(node_name + "Balcony", PackedVector2Array([foot + Vector2(-size.x * 0.34, -size.y * 0.48), foot + Vector2(size.x * 0.34, -size.y * 0.48), foot + Vector2(size.x * 0.29, -size.y * 0.39), foot + Vector2(-size.x * 0.29, -size.y * 0.39)]), stone.lightened(0.24), -1)
	elif variant == 2:
		_poly(node_name + "Chimney", PackedVector2Array([foot + Vector2(size.x * 0.22, -size.y - 8.0), foot + Vector2(size.x * 0.22, -size.y - 76.0), foot + Vector2(size.x * 0.34, -size.y - 76.0), foot + Vector2(size.x * 0.34, -size.y + 4.0)]), stone.lightened(0.08), -2)
	for pane in range(2):
		var x := -size.x * 0.24 if pane == 0 else size.x * 0.1
		_poly(node_name + "Window%d" % pane, PackedVector2Array([foot + Vector2(x, -size.y * 0.58), foot + Vector2(x + 25.0, -size.y * 0.58), foot + Vector2(x + 25.0, -size.y * 0.58 + 28.0), foot + Vector2(x, -size.y * 0.58 + 28.0)]), window, -1)
	_poly(node_name + "Door", PackedVector2Array([foot + Vector2(-12.0, -48.0), foot + Vector2(12.0, -48.0), foot + Vector2(12.0, 0.0), foot + Vector2(-12.0, 0.0)]), stone.darkened(0.65), -1)


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
	label.size = Vector2(width, 27.0)
	label.text = words
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
