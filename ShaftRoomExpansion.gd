@tool
extends Node2D

# The five small Shaft scenes retain their named doors, puzzles and original
# entrance pockets. This child builds the much larger, hand-paced descent in
# both the editor and the running game. All distances use the default jump:
# no mandatory upward step exceeds 55 px and open gaps stay below 80 px.
const ROOM_WIDTH := 5300.0
const ROOM_HEIGHT := 2500.0
const LIFT_SCENE: PackedScene = preload("res://ShaftLift.tscn")
const CRAWLER_SCENE: PackedScene = preload("res://ShaftCrawler.tscn")
const SENTRY_SCENE: PackedScene = preload("res://ShaftSentry.tscn")
const WISP_SCENE: PackedScene = preload("res://ShaftWisp.tscn")
const CRATE_SCENE: PackedScene = preload("res://DestructibleCrate.tscn")
const FAUNA_SCENE: PackedScene = preload("res://NeutralCreature.tscn")
const CACHE_SCENE: PackedScene = preload("res://ResonanceCache.tscn")
const ROUTE_HAZARD_SCENE: PackedScene = preload("res://ShaftRouteHazard.tscn")
const LOCAL_ENCOUNTER_SCENE: PackedScene = preload("res://LocalizedEncounter.tscn")
const EXPLORATION_SITES := preload("res://ShaftExplorationSites.gd")
const FLOOR_PLACEMENT := preload("res://RouteFloorPlacement.gd")
const FIELD_DRESSING := preload("res://ShaftRouteDressing.gd")

# Original hand-placed entry-court actors now use the same first-entry hook as
# the expanded route. Persistent doors, puzzles, lamps and caches stay authored
# in their scenes; only ordinary enemies and breakables move into this manifest.
const AUTHORED_POPULATION := {
	"ShaftHollow": [
		{"name": "HollowWispNear", "scene": WISP_SCENE, "position": Vector2(282, 171), "groups": [&"hollow_guardian"]},
		{"name": "HollowWispFar", "scene": WISP_SCENE, "position": Vector2(572, 136), "groups": [&"hollow_guardian"]},
		{"name": "HollowSentry", "scene": SENTRY_SCENE, "position": Vector2(469, 305)},
		{"name": "HollowCrate", "scene": CRATE_SCENE, "position": Vector2(167, 302)},
	],
	"DrownedCrossing": [
		{"name": "ChannelCrawler", "scene": CRAWLER_SCENE, "position": Vector2(312, 329)},
		{"name": "AqueductWisp", "scene": WISP_SCENE, "position": Vector2(500, 216)},
		{"name": "FarSentry", "scene": SENTRY_SCENE, "position": Vector2(634, 329)},
	],
	"FloodedGallery": [
		{"name": "GalleryCrawler", "scene": CRAWLER_SCENE, "position": Vector2(260, 347)},
		{"name": "GalleryWisp", "scene": WISP_SCENE, "position": Vector2(492, 150)},
		{"name": "GallerySentry", "scene": SENTRY_SCENE, "position": Vector2(665, 347)},
		{"name": "GalleryCrate", "scene": CRATE_SCENE, "position": Vector2(426, 344)},
	],
	"BlackwaterCistern": [
		{"name": "ChannelCrawler", "scene": CRAWLER_SCENE, "position": Vector2(350, 367)},
		{"name": "PressureWisp", "scene": WISP_SCENE, "position": Vector2(496, 117)},
		{"name": "FarSentry", "scene": SENTRY_SCENE, "position": Vector2(713, 367)},
		{"name": "CisternCrate", "scene": CRATE_SCENE, "position": Vector2(438, 368)},
	],
	"WardenApproach": [
		{"name": "EntryCrawler", "scene": CRAWLER_SCENE, "position": Vector2(185, 417)},
		{"name": "HighWisp", "scene": WISP_SCENE, "position": Vector2(603, 146)},
		{"name": "PitSentry", "scene": SENTRY_SCENE, "position": Vector2(782, 498)},
	],
}

# Horizontal corridor endpoints for each depth. Consecutive legs share one
# endpoint, so the route is a real corridor graph with shafts at different X
# positions instead of a stack of full-width shelves.
const MAZE_PATHS := {
	"ShaftHollow": [760.0, 3920.0, 1180.0, 4550.0, 2380.0, 4680.0, 3300.0, 5050.0],
	"DrownedCrossing": [900.0, 3300.0, 850.0, 4350.0, 1550.0, 4700.0, 2500.0, 5050.0],
	"FloodedGallery": [820.0, 2600.0, 470.0, 4000.0, 1800.0, 4800.0, 3100.0, 5050.0],
	"BlackwaterCistern": [1000.0, 4200.0, 1700.0, 4800.0, 900.0, 3600.0, 2100.0, 5050.0],
	"WardenApproach": [1200.0, 3500.0, 600.0, 4300.0, 2250.0, 4900.0, 2950.0, 5050.0],
	"StarfallOutskirts": [1700.0, 5200.0, 2450.0, 6100.0, 1200.0, 4500.0, 6250.0],
	"StarfallSilentGate": [1760.0, 3900.0, 900.0, 5450.0, 2300.0, 4850.0, 6250.0],
	"StarfallMemoryVault": [1700.0, 4700.0, 1350.0, 5900.0, 2800.0, 5100.0, 6250.0],
	"StarfallRootedHall": [1900.0, 5600.0, 3100.0, 800.0, 4200.0, 2100.0, 6250.0],
	"StarfallSoulCrucible": [1880.0, 4300.0, 950.0, 5300.0, 2600.0, 5900.0, 6250.0],
	"StarfallSunlessPassage": [2000.0, 600.0, 4100.0, 1450.0, 5600.0, 2950.0, 6250.0],
}

const CHAMBER_LAYOUTS := {
	"ShaftHollow": [[0.00, 0.35, 330.0], [0.27, 0.58, 690.0], [0.49, 0.82, 1050.0], [0.69, 1.00, 1410.0], [0.48, 0.77, 1050.0], [0.18, 0.55, 1770.0], [0.36, 0.96, 2130.0]],
	# The aqueduct doubles back through a low western channel before crossing
	# the full room. This deliberately avoids repeating Hollow's staircase.
	"DrownedCrossing": [[0.00, 0.32, 360.0], [0.24, 0.56, 720.0], [0.05, 0.32, 1080.0], [0.22, 0.58, 1440.0], [0.48, 0.82, 1080.0], [0.70, 1.00, 1800.0], [0.38, 0.76, 2160.0]],
	"FloodedGallery": [[0.00, 0.30, 380.0], [0.22, 0.49, 740.0], [0.41, 0.74, 1100.0], [0.66, 1.00, 1460.0], [0.52, 0.78, 1100.0], [0.18, 0.59, 1820.0], [0.38, 0.96, 2180.0]],
	# Tier five keeps the historic lamp floor so version-9 checkpoint and
	# fast-travel saves still resolve to the exact same RespawnPoint.
	"BlackwaterCistern": [[0.00, 0.38, 400.0], [0.30, 0.66, 760.0], [0.58, 0.92, 1120.0], [0.46, 0.78, 760.0], [0.18, 0.55, 1480.0], [0.20, 0.56, 1925.0], [0.42, 0.96, 2200.0]],
	# The defence line rises to a high eastern watch, falls through the siege
	# yard and only then descends towards the arena lamp.
	"WardenApproach": [[0.00, 0.34, 450.0], [0.26, 0.57, 810.0], [0.49, 0.80, 1170.0], [0.70, 1.00, 810.0], [0.55, 0.82, 1530.0], [0.24, 0.62, 1975.0], [0.43, 0.96, 2250.0]],
}

const PLANS := {
	"ShaftHollow": {
		"id": "hollow", "entry_end": 760.0, "entry_y": 330.0,
		"levels": [330.0, 635.0, 940.0, 1245.0, 1550.0, 1855.0],
		"tone": Color(0.11, 0.39, 0.42), "mist": Color(0.07, 0.20, 0.25, 0.42),
		"widths": [[370, 285, 445, 235, 400, 315, 380, 290], [290, 420, 275, 365, 450, 245, 390, 310], [410, 260, 350, 440, 280, 395, 300, 340], [310, 385, 240, 430, 295, 410, 340, 285], [435, 245, 385, 280, 460, 305, 370, 260], [275, 445, 320, 395, 250, 420, 280, 360]],
		"rise": [0, -24, -43, 8, -18, 21, -7, 13], "gap": [55, 62, 43, 72, 50, 64],
		"feature_x": [1260, 2110, 3110, 470, 1640, 2840],
	},
	"DrownedCrossing": {
		"id": "crossing", "entry_end": 900.0, "entry_y": 360.0,
		"levels": [360.0, 665.0, 970.0, 1275.0, 1580.0, 1885.0],
		"tone": Color(0.10, 0.35, 0.45), "mist": Color(0.04, 0.26, 0.38, 0.48),
		"widths": [[310, 470, 250, 395, 330, 460, 260, 355], [445, 260, 400, 315, 485, 270, 365, 300], [275, 385, 460, 240, 390, 300, 445, 285], [400, 325, 270, 475, 310, 425, 255, 365], [340, 455, 260, 410, 280, 465, 315, 340], [470, 260, 390, 290, 430, 310, 405, 270]],
		"rise": [0, 20, -27, -41, 9, -16, 24, -8], "gap": [60, 45, 70, 54, 67, 48],
		"feature_x": [1480, 2370, 3370, 670, 1770, 2800],
	},
	"FloodedGallery": {
		"id": "gallery", "entry_end": 820.0, "entry_y": 380.0,
		"levels": [380.0, 690.0, 1000.0, 1310.0, 1620.0, 1930.0],
		"tone": Color(0.12, 0.39, 0.48), "mist": Color(0.05, 0.30, 0.38, 0.46),
		"widths": [[430, 280, 390, 305, 455, 255, 370, 330], [270, 450, 315, 395, 255, 440, 325, 385], [385, 305, 460, 260, 400, 340, 445, 270], [310, 480, 270, 390, 320, 455, 280, 365], [450, 285, 410, 250, 390, 320, 455, 270], [280, 410, 340, 470, 265, 385, 310, 450]],
		"rise": [0, -32, -10, 18, -26, 7, -45, 15], "gap": [48, 72, 50, 63, 44, 70],
		"feature_x": [1180, 2050, 3220, 820, 1880, 2960],
	},
	"BlackwaterCistern": {
		"id": "cistern", "entry_end": 1000.0, "entry_y": 400.0,
		"levels": [400.0, 705.0, 1010.0, 1315.0, 1620.0, 1925.0],
		"tone": Color(0.10, 0.38, 0.43), "mist": Color(0.03, 0.29, 0.34, 0.53),
		"widths": [[290, 465, 315, 380, 250, 435, 300, 390], [450, 280, 405, 305, 475, 245, 370, 315], [315, 410, 265, 455, 330, 390, 275, 430], [485, 265, 390, 285, 460, 320, 405, 265], [270, 440, 305, 385, 475, 255, 400, 320], [395, 315, 455, 275, 410, 340, 470, 265]],
		"rise": [0, -20, -45, -12, 16, -28, 9, -6], "gap": [65, 45, 73, 52, 60, 46],
		"feature_x": [1410, 2330, 3450, 570, 1740, 2860],
	},
	"WardenApproach": {
		"id": "approach", "entry_end": 1200.0, "entry_y": 450.0,
		"levels": [450.0, 755.0, 1060.0, 1365.0, 1670.0, 1975.0],
		"tone": Color(0.16, 0.37, 0.43), "mist": Color(0.12, 0.17, 0.26, 0.5),
		"widths": [[395, 280, 455, 265, 400, 310, 445, 275], [310, 470, 265, 385, 330, 455, 280, 410], [440, 275, 385, 320, 465, 250, 395, 310], [285, 420, 355, 475, 270, 390, 305, 455], [465, 290, 420, 260, 390, 325, 440, 275], [325, 450, 270, 405, 310, 470, 260, 385]],
		"rise": [0, -38, -13, 22, -24, 12, -44, 4], "gap": [55, 68, 45, 74, 53, 62],
		"feature_x": [1600, 2420, 3370, 600, 1780, 2920],
	},
}

var room: Node2D
var plan: Dictionary
var generated: Node2D
var layout_width := ROOM_WIDTH
var layout_height := ROOM_HEIGHT
var population_loaded := false


func _ready() -> void:
	room = get_parent() as Node2D
	if room == null or not PLANS.has(room.name):
		return
	plan = PLANS[room.name].duplicate(true)
	var levels: Array = []
	for chamber_data in _layout_for_room():
		levels.append(float(chamber_data[2]))
	plan["levels"] = levels
	var widths: Array = plan["widths"]
	var final_motif: Array = (widths[2] as Array).duplicate()
	final_motif.reverse()
	widths.append(final_motif)
	plan["widths"] = widths
	var features: Array = plan["feature_x"]
	features.append(3960.0)
	plan["feature_x"] = features
	var gaps: Array = plan["gap"]
	gaps.append(float(gaps[2]))
	plan["gap"] = gaps
	generated = Node2D.new()
	generated.name = "AuthoredDescent"
	add_child(generated)
	if _use_schematic_editor_preview():
		_paint_cavern()
		_paint_editor_identity()
		_build_route_preview()
		_relocate_route_portals()
		_build_field_dressing()
		return
	_extend_boundaries()
	_paint_cavern()
	_build_descent()
	_build_checkpoint_approaches()
	_build_room_identity()
	_relocate_existing_features()
	_relocate_route_portals()
	_build_return_lift()
	_build_field_dressing()
	if Engine.is_editor_hint():
		_spawn_authored_population()
		_relocate_existing_features()
		_relocate_route_portals()
	elif not _uses_world_population_streaming():
		# When an individual room scene is instantiated, this child becomes ready
		# while its parent is still attaching siblings. Wait one turn before the
		# manifest adds authored actors beside this expansion node.
		call_deferred("activate_room_population")


func _build_field_dressing() -> void:
	if plan["id"] not in ["hollow", "crossing", "gallery", "cistern", "approach"]:
		return
	var dressing := Node2D.new()
	dressing.name = "FieldDressing"
	dressing.set_script(FIELD_DRESSING)
	dressing.set("region", plan["id"] if plan["id"] in ["hollow", "crossing"] else "shaft_" + String(plan["id"]))
	add_child(dressing)


func _uses_world_population_streaming() -> bool:
	return room != null and room.get_parent() != null and room.get_parent().get_node_or_null("RoomActivityDirector") != null


func activate_room_population() -> void:
	if Engine.is_editor_hint() or generated == null:
		return
	_spawn_authored_population()
	# Spawn coordinates are resolved before _ready; revisits preserve live state.
	_populate_descent()
	if population_loaded:
		return
	population_loaded = true


func is_population_loaded() -> bool:
	return population_loaded


func get_replay_spawn_points() -> Array[Vector2]:
	# Replay encounters belong deep in the expanded route, not in the small
	# legacy entrance pocket where their original coordinates were authored.
	if generated == null:
		return []
	var points: Array[Vector2] = []
	for path in ["T4_Bridge2", "T5_Bridge6"]:
		var anchor := generated.get_node_or_null(path) as Node2D
		if anchor != null:
			var tier := 4 if path == "T4_Bridge2" else 5
			points.append(_floor_point(tier, anchor.position.x, 92.0))
	return points


func get_replay_cache_position() -> Vector2:
	if generated == null:
		return Vector2.INF
	var branch := generated.get_node_or_null("Branch5_Chamber") as Node2D
	return room.to_local(branch.global_position) + Vector2(110.0, -36.0) if branch != null else Vector2.INF


func _spawn_authored_population() -> void:
	if room == null or not AUTHORED_POPULATION.has(String(room.name)):
		return
	var world_population: Node = room.get_parent().get_node_or_null("WorldPopulation") if room.get_parent() != null else null
	for entry in AUTHORED_POPULATION[String(room.name)]:
		var node_name := String(entry["name"])
		if room.has_node(node_name):
			continue
		if world_population != null and world_population.has_method("should_spawn_authored_actor") and not bool(world_population.call("should_spawn_authored_actor", String(room.name), node_name)):
			continue
		var actor := (entry["scene"] as PackedScene).instantiate() as Node2D
		actor.name = node_name
		actor.position = entry["position"]
		actor.position = _authored_spawn_position(node_name, actor.position)
		for group_name in entry.get("groups", []):
			actor.add_to_group(group_name)
		actor.set_meta("authored_streamed_population", true)
		actor.set_meta("streamed_population_kind", "crate" if actor.is_in_group("breakable") else ("neutral" if actor.is_in_group("neutral_creature") else "enemy"))
		room.add_child(actor)
		if world_population != null and world_population.has_method("register_authored_actor"):
			world_population.call("register_authored_actor", String(room.name), actor)


func _add_streamed_generated_actor(actor: Node2D) -> bool:
	var state_key := "generated:%s" % String(actor.name)
	var world_population: Node = room.get_parent().get_node_or_null("WorldPopulation") if room != null and room.get_parent() != null else null
	if world_population != null and world_population.has_method("should_spawn_authored_actor") and not bool(world_population.call("should_spawn_authored_actor", String(room.name), state_key)):
		actor.free()
		return false
	actor.set_meta("authored_streamed_population", true)
	actor.set_meta("streamed_population_kind", "crate" if actor.is_in_group("breakable") else ("neutral" if actor.is_in_group("neutral_creature") else "enemy"))
	actor.set_meta("streamed_population_key", state_key)
	generated.add_child(actor)
	if world_population != null and world_population.has_method("register_authored_actor"):
		world_population.call("register_authored_actor", String(room.name), actor, state_key)
	return true


func _route_xs() -> Array:
	var centers: Array = []
	for tier in range(_layout_for_room().size()):
		centers.append(_chamber_rect(tier).get_center().x)
	return centers


func _chamber_rect(tier: int) -> Rect2:
	var data: Array = _layout_for_room()[tier]
	return Rect2(Vector2(float(data[0]) * layout_width, float(data[2]) - 285.0), Vector2((float(data[1]) - float(data[0])) * layout_width, 285.0))


func _layout_for_room() -> Array:
	return CHAMBER_LAYOUTS[room.name]


func _topology_caption() -> String:
	return room.name.to_snake_case().replace("_", " ").to_upper()


func _portal_anchor(tier: int, ratio: float, clearance: float = 33.0) -> Vector2:
	var chamber := _chamber_rect(clampi(tier, 0, _layout_for_room().size() - 1))
	var desired := lerpf(chamber.position.x + 55.0, chamber.end.x - 55.0, clampf(ratio, 0.0, 1.0))
	if _use_schematic_editor_preview():
		return Vector2(desired, chamber.end.y - clearance)
	return _floor_point(tier, desired, clearance)


func _floor_point(tier: int, x: float, clearance: float = 33.0, margin: float = 125.0) -> Vector2:
	return FLOOR_PLACEMENT.on_floor(generated, "Chamber%d_Floor" % tier, x, clearance, margin)


func _authored_spawn_position(actor_name: String, original: Vector2) -> Vector2:
	match actor_name:
		"HollowSentry": return _floor_point(2, 2380)
		"GallerySentry", "FarSentry", "PitSentry": return _floor_point(5, 1450)
		"HollowWispNear": return _floor_point(0, 1500, 85)
		"HollowWispFar": return _floor_point(1, 2100, 85)
		"AqueductWisp": return _floor_point(2, 1300, 85)
		"GalleryWisp": return _floor_point(2, 2700, 85)
		"PressureWisp": return _floor_point(1, 3200, 85)
		"HighWisp": return _floor_point(0, 1600, 85)
		"ChannelCrawler":
			if room.name == "BlackwaterCistern":
				return _floor_point(2, generated.get_node("T2_Bridge4").position.x + 46)
	return original


func _build_checkpoint_approaches() -> void:
	# Saves store these lamp coordinates: reconnect the old alcoves instead of
	# moving their respawn points. This approach is level with chamber five.
	if room.name not in ["BlackwaterCistern", "WardenApproach"]:
		return
	var chamber := _chamber_rect(5)
	var left := 400.0
	var right := chamber.position.x + 220.0
	_platform("HistoricLampApproach", left, right, chamber.end.y, plan["tone"], false, 18.0)
	var backdrop := Polygon2D.new()
	backdrop.name = "HistoricLampAlcove"
	backdrop.z_index = -8
	backdrop.color = Color(0.025, 0.08, 0.12)
	backdrop.polygon = PackedVector2Array([Vector2(left - 25, chamber.end.y + 18), Vector2(left - 25, chamber.end.y - 130), Vector2(left + 80, chamber.end.y - 195), Vector2(right, chamber.end.y - 165), Vector2(right, chamber.end.y + 18)])
	generated.add_child(backdrop)


func _place_portal(door_name: String, marker_name: String, tier: int, ratio: float, marker_side: float = 1.0) -> void:
	var at := _portal_anchor(tier, ratio)
	_move(door_name, at)
	if not marker_name.is_empty():
		_move(marker_name, at + Vector2(78.0 * marker_side, 0.0))


func _relocate_route_portals() -> void:
	var last := _layout_for_room().size() - 1
	match room.name:
		"ShaftHollow":
			_place_portal("UpperReturnDoor", "UpperEntry", 0, 0.03)
			_place_portal("DriftDoor", "DriftReturn", 1, 0.90, -1.0)
			_place_portal("LowerReturnDoor", "LowerEntry", 3, 0.10)
			_place_portal("CrossingDoor", "CrossingEntry", last, 0.94, -1.0)
		"DrownedCrossing":
			_place_portal("ShaftReturnDoor", "ShaftEntry", 0, 0.03)
			_place_portal("HollowDoor", "HollowEntry", 1, 0.90, -1.0)
			_place_portal("CisternDoor", "CisternReturn", 3, 0.10)
			_place_portal("GalleryDoor", "GalleryReturn", last, 0.94, -1.0)
		"FloodedGallery":
			_place_portal("CrossingReturnDoor", "CrossingEntry", 0, 0.03)
			_place_portal("CisternDoor", "CisternReturn", 2, 0.90, -1.0)
			_place_portal("WardenShortcutDoor", "ShaftEntry", last, 0.94, -1.0)
		"BlackwaterCistern":
			_place_portal("CrossingReturnDoor", "CrossingEntry", 0, 0.03)
			_place_portal("GalleryShortcutDoor", "GalleryEntry", last, 0.94, -1.0)
		"WardenApproach":
			_place_portal("GalleryReturnDoor", "GalleryEntry", 0, 0.03)
			_place_portal("ArenaDoor", "ShaftEntry", last, 0.94, -1.0)


func _use_schematic_editor_preview() -> bool:
	if not Engine.is_editor_hint():
		return false
	var edited_root := get_tree().edited_scene_root
	return edited_root != null and edited_root != room


func _build_route_preview() -> void:
	var levels: Array = plan["levels"]
	for tier in range(levels.size()):
		var chamber := _chamber_rect(tier)
		var silhouette := _shaft_chamber_silhouette(chamber, tier)
		var closed_silhouette: PackedVector2Array = silhouette.duplicate()
		closed_silhouette.append(silhouette[0])
		var outline := Line2D.new()
		outline.name = "TopologyRoom%d" % tier
		outline.z_index = -1
		outline.width = 5.0
		outline.default_color = (plan["tone"] as Color).lightened(0.30)
		outline.points = closed_silhouette
		generated.add_child(outline)
		var floor_line := Line2D.new()
		floor_line.name = "TopologyFloor%d" % tier
		floor_line.z_index = 0
		floor_line.width = 14.0
		floor_line.default_color = (plan["tone"] as Color).lightened(0.08)
		floor_line.points = PackedVector2Array([Vector2(chamber.position.x + 12.0, chamber.end.y - 4.0), Vector2(chamber.end.x - 12.0, chamber.end.y - 4.0)])
		generated.add_child(floor_line)
		if tier < levels.size() - 1:
			var next := _chamber_rect(tier + 1)
			var x := (maxf(chamber.position.x, next.position.x) + minf(chamber.end.x, next.end.x)) * 0.5
			var shaft := Line2D.new()
			shaft.name = "TopologyShaft%d" % tier
			shaft.width = 5.0
			shaft.default_color = (plan["tone"] as Color).lightened(0.43)
			shaft.points = PackedVector2Array([Vector2(x, chamber.end.y), Vector2(x, next.end.y)])
			generated.add_child(shaft)
			var rung_count := maxi(2, int(absf(next.end.y - chamber.end.y) / 58.0))
			for rung in range(1, rung_count):
				var rung_line := Line2D.new()
				rung_line.name = "TopologyRung%d_%d" % [tier, rung]
				rung_line.width = 10.0
				rung_line.default_color = (plan["tone"] as Color).lightened(0.18)
				var rung_y := lerpf(chamber.end.y, next.end.y, float(rung) / float(rung_count))
				var rung_x := x + (-58.0 if (rung + tier) % 2 == 0 else 58.0)
				rung_line.points = PackedVector2Array([Vector2(rung_x - 60.0, rung_y), Vector2(rung_x + 60.0, rung_y)])
				generated.add_child(rung_line)
	for tier in [1, 3, 5]:
		if tier >= levels.size():
			continue
		var branch_anchor := Vector2(_chamber_rect(tier).get_center().x, float(levels[tier]))
		var branch_side := -1.0 if branch_anchor.x > layout_width * 0.52 else 1.0
		var branch := Line2D.new()
		branch.name = "TopologyDeadEnd%d" % tier
		branch.width = 17.0
		branch.default_color = _alpha((plan["tone"] as Color).lightened(0.12), 0.76)
		branch.points = PackedVector2Array([
			branch_anchor,
			branch_anchor + Vector2(branch_side * 145.0, -120.0),
			branch_anchor + Vector2(branch_side * 500.0, -120.0),
		])
		generated.add_child(branch)
	var caption := Label.new()
	caption.name = "TopologyCaption"
	caption.position = _chamber_rect(0).position + Vector2(40, 55)
	caption.add_theme_font_size_override("font_size", 34)
	caption.add_theme_color_override("font_color", Color(0.58, 0.94, 0.93, 0.86))
	caption.text = _topology_caption()
	generated.add_child(caption)


func _extend_boundaries() -> void:
	for wall_name in ["LeftWall", "RightWall"]:
		var wall := room.get_node_or_null(wall_name) as StaticBody2D
		if wall == null:
			continue
		wall.position = Vector2(0.0 if wall_name == "LeftWall" else layout_width, layout_height / 2.0)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(12.0, layout_height + 40.0)
		(wall.get_node("CollisionShape2D") as CollisionShape2D).shape = shape
	var roof := room.get_node_or_null("Roof")
	if roof == null:
		roof = room.get_node_or_null("Ceiling")
	if roof is StaticBody2D:
		roof.position = Vector2(layout_width / 2.0, 0.0)
		var roof_shape := RectangleShape2D.new()
		roof_shape.size = Vector2(layout_width, 12.0)
		(roof.get_node("CollisionShape2D") as CollisionShape2D).shape = roof_shape
	_platform("BasalCatchment", 0.0, layout_width, layout_height - 12.0, Color(0.07, 0.18, 0.23), false, 18.0)


func _paint_cavern() -> void:
	var mist_color: Color = plan["mist"]
	var tone: Color = plan["tone"]
	var levels: Array = plan["levels"]
	for tier in range(levels.size()):
		var chamber := _chamber_rect(tier)
		var y := chamber.end.y
		var left := chamber.position.x
		var right := chamber.end.x
		var shadow := Polygon2D.new()
		shadow.name = "ChamberShadow%d" % tier
		shadow.z_index = -8
		shadow.color = mist_color.darkened(float(tier % 3) * 0.13)
		shadow.polygon = _shaft_chamber_silhouette(chamber, tier)
		generated.add_child(shadow)
		var corridor_width := right - left
		var arch_count := maxi(2, int(corridor_width / 520.0))
		for arch in range(arch_count):
			var x := left + 150.0 + float(arch) * (corridor_width - 300.0) / float(maxi(1, arch_count - 1))
			var pier := Polygon2D.new()
			pier.name = "Pier%d_%d" % [tier, arch]
			pier.z_index = -6
			pier.color = tone.darkened(0.50 + float(arch % 3) * 0.06)
			pier.polygon = PackedVector2Array([Vector2(x - 34, y - 260), Vector2(x + 12, y - 275), Vector2(x + 49, y + 20), Vector2(x - 30, y + 25)])
			generated.add_child(pier)
			if arch % 2 == 0:
				var drip := Line2D.new()
				drip.name = "Seep%d_%d" % [tier, arch]
				drip.z_index = -5
				drip.width = 3.0 + float(tier % 2)
				drip.default_color = _alpha(tone.lightened(0.25), 0.37)
				drip.points = PackedVector2Array([Vector2(x + 19, y - 250), Vector2(x + 16, y - 120), Vector2(x + 26, y - 16)])
				generated.add_child(drip)
			var crystal := Polygon2D.new()
			crystal.name = "OreVein%d_%d" % [tier, arch]
			crystal.z_index = -4
			crystal.color = _alpha(tone.lightened(0.19), 0.47)
			crystal.polygon = PackedVector2Array([Vector2(x + 55, y - 5), Vector2(x + 72, y - 47 - 8 * (arch % 3)), Vector2(x + 88, y - 3)])
			generated.add_child(crystal)
		if tier < levels.size() - 1:
			var next := _chamber_rect(tier + 1)
			var shaft_x := (maxf(chamber.position.x, next.position.x) + minf(chamber.end.x, next.end.x)) * 0.5
			var top_y := minf(chamber.end.y, next.end.y)
			var bottom_y := maxf(chamber.end.y, next.end.y)
			var shaft := Polygon2D.new()
			shaft.name = "ChamberShaftShadow%d" % tier
			shaft.z_index = -8
			shaft.color = mist_color.darkened(0.22)
			shaft.polygon = PackedVector2Array([Vector2(shaft_x - 135.0, top_y - 35.0), Vector2(shaft_x + 135.0, top_y - 35.0), Vector2(shaft_x + 135.0, bottom_y + 45.0), Vector2(shaft_x - 135.0, bottom_y + 45.0)])
			generated.add_child(shaft)
	var water := Polygon2D.new()
	water.name = "BlackwaterBelow"
	water.z_index = -7
	water.color = mist_color.lightened(0.1)
	water.polygon = PackedVector2Array([Vector2(0, layout_height - 88), Vector2(layout_width, layout_height - 88), Vector2(layout_width, layout_height), Vector2(0, layout_height)])
	generated.add_child(water)


func _shaft_chamber_silhouette(chamber: Rect2, tier: int) -> PackedVector2Array:
	# Collision stays on the clear chamber floor, while the visible cave shell
	# gets an uneven roof and walls. The different seed per room/tier prevents
	# the world overview from reading as a grid of copied rectangles.
	var left := chamber.position.x
	var right := chamber.end.x
	var top := chamber.position.y
	var bottom := chamber.end.y
	var seed := int(plan.get("id", "shaft").hash()) + tier * 97
	var inset_left := 18.0 + float(abs(seed) % 35)
	var inset_right := 22.0 + float(abs(seed / 3) % 41)
	return PackedVector2Array([
		Vector2(left, bottom),
		Vector2(left - 14.0, bottom - 76.0),
		Vector2(left + inset_left, top + 86.0 + float(abs(seed / 5) % 52)),
		Vector2(left + chamber.size.x * 0.17, top + 28.0 + float(abs(seed / 7) % 54)),
		Vector2(left + chamber.size.x * 0.36, top + 7.0 + float(abs(seed / 11) % 43)),
		Vector2(left + chamber.size.x * 0.56, top + 42.0 + float(abs(seed / 13) % 47)),
		Vector2(left + chamber.size.x * 0.76, top + 12.0 + float(abs(seed / 17) % 58)),
		Vector2(right - inset_right, top + 58.0 + float(abs(seed / 19) % 48)),
		Vector2(right + 16.0, bottom - 83.0),
		Vector2(right, bottom),
	])


func _paint_editor_identity() -> void:
	# Game.tscn previews must communicate what each Shaft room is before the
	# scene is run. These are scenery-only silhouettes: runtime traversal and
	# collision remain authored by the matching identity builders below.
	var tone: Color = plan["tone"]
	for tier in range(_layout_for_room().size()):
		var chamber := _chamber_rect(tier)
		var floor_y := chamber.end.y
		var center := chamber.get_center()
		match room.name:
			"ShaftHollow":
				_mining_support("PreviewTimber%d" % tier, Vector2(center.x, floor_y - 5.0), 145.0 + float(tier % 3) * 24.0)
				for ore in range(3):
					var ore_x := chamber.position.x + chamber.size.x * (0.24 + float(ore) * 0.25)
					_poly("PreviewOre%d_%d" % [tier, ore], PackedVector2Array([Vector2(ore_x - 14, floor_y - 8), Vector2(ore_x, floor_y - 55 - ore * 9), Vector2(ore_x + 16, floor_y - 8)]), Color(0.45, 0.76, 0.60, 0.68), -2)
			"DrownedCrossing":
				for band in range(3):
					var water_line := Line2D.new()
					water_line.name = "PreviewCurrent%d_%d" % [tier, band]
					water_line.z_index = -2
					water_line.width = 5.0 - float(band)
					water_line.default_color = Color(0.28, 0.72, 0.88, 0.48 - float(band) * 0.08)
					var band_y := floor_y - 38.0 - float(band) * 34.0
					water_line.points = PackedVector2Array([Vector2(chamber.position.x + 55.0, band_y), Vector2(center.x - 45.0, band_y - 14.0), Vector2(chamber.end.x - 55.0, band_y)])
					generated.add_child(water_line)
			"FloodedGallery":
				var pipe := Line2D.new()
				pipe.name = "PreviewPressureMain%d" % tier
				pipe.z_index = -2
				pipe.width = 11.0
				pipe.default_color = Color(0.27, 0.66, 0.67, 0.72)
				pipe.points = PackedVector2Array([Vector2(chamber.position.x + 55.0, floor_y - 92.0), Vector2(center.x - 80.0, floor_y - 92.0), Vector2(center.x - 80.0, floor_y - 188.0), Vector2(chamber.end.x - 70.0, floor_y - 188.0)])
				generated.add_child(pipe)
				for gauge in range(3):
					_circle("PreviewGauge%d_%d" % [tier, gauge], Vector2(center.x - 96.0 + float(gauge) * 96.0, floor_y - 137.0), 18.0, Color(0.45, 0.9, 0.85, 0.72), -1)
			"BlackwaterCistern":
				var tank_width := minf(390.0, chamber.size.x * 0.42)
				_poly("PreviewTank%d" % tier, PackedVector2Array([Vector2(center.x - tank_width * 0.5, floor_y - 12.0), Vector2(center.x - tank_width * 0.46, floor_y - 205.0), Vector2(center.x - tank_width * 0.32, floor_y - 255.0), Vector2(center.x + tank_width * 0.32, floor_y - 255.0), Vector2(center.x + tank_width * 0.46, floor_y - 205.0), Vector2(center.x + tank_width * 0.5, floor_y - 12.0)]), Color(0.035, 0.22, 0.27, 0.88), -3)
				for gauge in range(3):
					_circle("PreviewTankGauge%d_%d" % [tier, gauge], Vector2(center.x - 88.0 + gauge * 88.0, floor_y - 155.0), 17.0, Color(0.31, 0.78, 0.75, 0.72), -2)
			"WardenApproach":
				for post in range(4):
					var post_x := lerpf(chamber.position.x + 120.0, chamber.end.x - 120.0, float(post) / 3.0)
					_poly("PreviewPalisade%d_%d" % [tier, post], PackedVector2Array([Vector2(post_x - 20.0, floor_y - 8.0), Vector2(post_x - 14.0, floor_y - 145.0 - 25.0 * float(post % 2)), Vector2(post_x, floor_y - 185.0 - 25.0 * float(post % 2)), Vector2(post_x + 14.0, floor_y - 145.0 - 25.0 * float(post % 2)), Vector2(post_x + 20.0, floor_y - 8.0)]), tone.darkened(0.26), -2)
				var warning := Line2D.new()
				warning.name = "PreviewSightline%d" % tier
				warning.z_index = -1
				warning.width = 3.0
				warning.default_color = Color(0.91, 0.39, 0.25, 0.48)
				warning.points = PackedVector2Array([Vector2(chamber.position.x + 90.0, floor_y - 48.0), Vector2(chamber.end.x - 90.0, floor_y - 48.0)])
				generated.add_child(warning)


func _build_descent() -> void:
	_build_chamber_foundations()
	var levels: Array = plan["levels"]
	# Resolve all real floor spans before choosing the shaft's upper landing.
	for tier in range(levels.size() - 1):
		var chamber := _chamber_rect(tier)
		var next := _chamber_rect(tier + 1)
		var x := (maxf(chamber.position.x, next.position.x) + minf(chamber.end.x, next.end.x)) * 0.5
		_build_turn(tier, x, chamber.end.y, next.end.y, 1 if next.get_center().x > chamber.get_center().x else -1)
	for tier in range(1, levels.size()):
		var focus_bridge := generated.get_node("T%d_Bridge4" % tier) as StaticBody2D
		var focus_x := focus_bridge.position.x
		var y := focus_bridge.position.y
		_platform("Overlook%dA" % tier, focus_x - 125.0, focus_x - 5.0, y - 72.0, (plan["tone"] as Color).lightened(0.3), true, 10.0)
		_platform("Overlook%dB" % tier, focus_x + 76.0, focus_x + 196.0, y - 42.0, (plan["tone"] as Color).lightened(0.17), true, 10.0)
	_build_high_niches()
	_build_dead_end_branches()


func _build_chamber_foundations(with_crossings: bool = true) -> void:
	# Shared by live terrain and Starfall's lightweight editor preview. Portal
	# anchors must use identical surviving floors, including merged shaft holes.
	var levels: Array = plan["levels"]
	var openings: Dictionary = {}
	for tier in range(levels.size()):
		openings[tier] = []
	for tier in range(levels.size() - 1):
		var chamber := _chamber_rect(tier)
		var next := _chamber_rect(tier + 1)
		var x := (maxf(chamber.position.x, next.position.x) + minf(chamber.end.x, next.end.x)) * 0.5
		var upper_y := minf(chamber.end.y, next.end.y)
		for candidate in range(levels.size()):
			var crossing := _chamber_rect(candidate)
			if crossing.end.y >= upper_y - 1 and crossing.end.y < maxf(chamber.end.y, next.end.y) - 1 and x + 135 > crossing.position.x and x - 135 < crossing.end.x:
				(openings[candidate] as Array).append(x)
	for tier in range(levels.size()):
		var chamber := _chamber_rect(tier)
		_build_chamber_floor(tier, chamber, openings[tier])
		_build_chamber_anchors(tier, chamber)
		if with_crossings:
			_build_shaft_crossings(tier, chamber)


func _build_chamber_floor(tier: int, chamber: Rect2, raw_openings: Array) -> void:
	var room_openings: Array = raw_openings.duplicate()
	room_openings.sort()
	var cursor := chamber.position.x
	var segment := 0
	for value in room_openings:
		var opening := float(value)
		var stop := maxf(cursor, opening - 135.0)
		if stop - cursor > 35.0:
			_platform("Chamber%d_Floor%d" % [tier, segment], cursor, stop, chamber.end.y, (plan["tone"] as Color).darkened(0.15), false, 18.0)
			segment += 1
		cursor = minf(chamber.end.x, opening + 135.0)
	if chamber.end.x - cursor > 35.0:
		_platform("Chamber%d_Floor%d" % [tier, segment], cursor, chamber.end.x, chamber.end.y, (plan["tone"] as Color).darkened(0.15), false, 18.0)


func _build_shaft_crossings(tier: int, chamber: Rect2) -> void:
	# Shaft stairs used to reach only one rim of a 270px mouth, stranding
	# the other half of the gallery with the basic jump. Short raised wooden
	# spans connect BOTH rims; gaps at their ends still allow descent.
	var floors: Array[StaticBody2D] = []
	for child in generated.get_children():
		if child is StaticBody2D and String(child.name).begins_with("Chamber%d_Floor" % tier):
			floors.append(child)
	floors.sort_custom(func(a: StaticBody2D, b: StaticBody2D) -> bool: return a.position.x < b.position.x)
	for index in range(floors.size() - 1):
		var a := floors[index]
		var b := floors[index + 1]
		var left: float = a.position.x + a.get_node("CollisionShape2D").shape.size.x * 0.5
		var right: float = b.position.x - b.get_node("CollisionShape2D").shape.size.x * 0.5
		if right - left <= 65:
			continue
		var pieces := maxi(1, ceili((right - left - 50.0) / 220.0))
		var span := (right - left - 50.0 * (pieces + 1)) / pieces
		for part in range(pieces):
			var start := left + 50.0 + part * (span + 50.0)
			var finish := start + span
			var label := "ShaftCrossing%d_%d_%d" % [tier, index, part]
			_platform(label, start, finish, chamber.end.y - 38.0, Color(0.36, 0.31, 0.25), true, 10.0)
			var rope := Line2D.new()
			rope.name = label + "Rope"
			rope.width = 2.0
			rope.default_color = (plan["tone"] as Color).lightened(0.3)
			rope.points = PackedVector2Array([Vector2(start, chamber.end.y - 38), Vector2(start + 8, chamber.end.y - 62), Vector2(finish - 8, chamber.end.y - 62), Vector2(finish, chamber.end.y - 38)])
			generated.add_child(rope)


func _build_chamber_anchors(tier: int, chamber: Rect2) -> void:
	# Gameplay features use nine semantic positions, but these anchors have no
	# collision or visual. The actual room floor is one continuous chamber.
	for index in range(9):
		var anchor := StaticBody2D.new()
		anchor.name = "T%d_Bridge%d" % [tier, index]
		anchor.position = Vector2(lerpf(chamber.position.x + 85.0, chamber.end.x - 85.0, float(index) / 8.0), chamber.end.y)
		generated.add_child(anchor)


func _build_room_identity() -> void:
	# The shared switchback grammar keeps every route readable, but each room
	# gets a different traversal verb and silhouette on top of that grammar.
	match room.name:
		"ShaftHollow":
			_build_hollow_identity()
		"DrownedCrossing":
			_build_crossing_identity()
		"FloodedGallery":
			_build_gallery_identity()
		"BlackwaterCistern":
			_build_cistern_identity()
		"WardenApproach":
			_build_approach_identity()


func _build_hollow_identity() -> void:
	_label("HollowIdentity", "ABANDONED ORE WORKS  •  WATCH THE CEILING", Vector2(1060, 225), 590.0, Color(0.72, 0.89, 0.73))
	var sites := [[0, 3], [0, 7], [1, 2], [1, 6], [2, 4], [3, 1], [3, 6], [4, 3], [5, 2], [5, 6], [6, 4]]
	for index in range(sites.size()):
		var bridge := _bridge(int(sites[index][0]), int(sites[index][1]))
		if bridge == null:
			continue
		_mining_support("HollowTimber%02d" % index, bridge.position, 125.0 + float(index % 3) * 18.0)
	# Authored danger stretches, not arbitrary bridge indices. Galleries 2/4
	# share terrain, so the old per-tier formula stacked two damage fields and
	# covered the camp/niche stairs. Keep full-width rockfalls on solid runs
	# with waiting space on both sides, clear of vertical junctions.
	var rockfall_sites := [[1, 1830.0], [0, 1050.0], [3, 4750.0], [6, 3900.0], [5, 1530.0]]
	for index in range(rockfall_sites.size()):
		var site: Array = rockfall_sites[index]
		var ground := _floor_point(int(site[0]), float(site[1]), 9.0, 200.0)
		_hazard("HollowRockfall%02d" % index, ground + Vector2(0, -50), Vector2(0.72, 1.22), "rockfall", "", Vector2(0, 215), float(index) * 0.43)
		for rock in range(4):
			var x := ground.x - 112.0 + float(rock) * 72.0
			_poly("HollowLooseRock%02d_%02d" % [index, rock], PackedVector2Array([Vector2(x - 13, ground.y - 144), Vector2(x + 5, ground.y - 174 - 10 * (rock % 2)), Vector2(x + 17, ground.y - 142)]), Color(0.33, 0.47, 0.41, 0.82), -1)
	var spur := _bridge(3, 4)
	if spur != null:
		_platform("HollowMinecartSpurA", spur.position.x - 285, spur.position.x - 145, spur.position.y - 62, Color(0.28, 0.53, 0.45), true, 10)
		_platform("HollowMinecartSpurB", spur.position.x - 118, spur.position.x + 40, spur.position.y - 112, Color(0.33, 0.59, 0.49), true, 10)
		_label("HollowOreLandmark", "SEALED ORE FACE", spur.position + Vector2(-158, -177), 260.0, Color(0.73, 0.91, 0.7))


func _build_crossing_identity() -> void:
	_label("CrossingIdentity", "THE DROWNED AQUEDUCT  •  CURRENTS CHANGE DIRECTION", Vector2(1080, 255), 670.0, Color(0.63, 0.91, 1.0))
	var sites := [[0, 4], [1, 3], [2, 5], [3, 2], [4, 5], [5, 3], [6, 5]]
	for index in range(sites.size()):
		var bridge := _bridge(int(sites[index][0]), int(sites[index][1]))
		if bridge == null:
			continue
		var direction := -1.0 if index % 2 == 0 else 1.0
		_hazard("CrossingCurrent%02d" % index, bridge.position + Vector2(0, -50), Vector2(0.86, 0.78), "current", "shaft_sluice_valve", Vector2(direction * 155.0, 0), float(index) * 0.2)
		_build_dry_bypass("CrossingDryRoute%02d" % index, bridge.position, direction)
		var flow := Line2D.new()
		flow.name = "CrossingFlow%02d" % index
		flow.z_index = -2
		flow.width = 5.0
		flow.default_color = Color(0.34, 0.76, 0.89, 0.42)
		flow.points = PackedVector2Array([bridge.position + Vector2(-175, -12), bridge.position + Vector2(-65, -28), bridge.position + Vector2(55, -11), bridge.position + Vector2(175, -27)])
		generated.add_child(flow)
	for tier in [1, 3, 5]:
		var y: float = plan["levels"][tier]
		_poly("CrossingAqueductArch%d" % tier, PackedVector2Array([Vector2(640, y - 250), Vector2(710, y - 335), Vector2(1080, y - 335), Vector2(1150, y - 250), Vector2(1100, y - 250), Vector2(1040, y - 290), Vector2(750, y - 290), Vector2(690, y - 250)]), Color(0.07, 0.25, 0.32, 0.72), -4)


func _build_gallery_identity() -> void:
	_label("GalleryIdentity", "PRESSURE GALLERY  •  TURN BOTH CONTROLS", Vector2(1080, 275), 580.0, Color(0.72, 0.95, 0.94))
	var sites := [[0, 5], [1, 2], [2, 5], [3, 3], [4, 5], [5, 2], [6, 4]]
	for index in range(sites.size()):
		var bridge := _bridge(int(sites[index][0]), int(sites[index][1]))
		if bridge == null:
			continue
		var control_id := "shaft_gallery_lower" if index < 4 else "shaft_gallery_upper"
		_hazard("GalleryPressureJet%02d" % index, bridge.position + Vector2(0, -50), Vector2(0.66, 0.88), "pressure", control_id, Vector2((-1.0 if index % 2 == 0 else 1.0) * 155.0, -175.0), float(index) * 0.31)
		_pressure_manifold("GalleryManifold%02d" % index, bridge.position, index % 2 == 0)
		if index in [1, 4, 6]:
			_build_pressure_catwalk("GalleryCatwalk%02d" % index, bridge.position)
	var lower_bridge := _bridge(3, 2)
	if lower_bridge != null:
		_move("LowerControl", lower_bridge.position + Vector2(0, -33))


func _build_cistern_identity() -> void:
	_label("CisternIdentity", "BLACKWATER PRESSURE CELLS  •  NEAR  >  HIGH  >  FAR", Vector2(1080, 135), 700.0, Color(0.66, 0.91, 0.88))
	# Full-size danger stretches with waiting pockets, away from side-stair
	# takeoffs. The old bridge-index sites covered the camp/niche entrances
	# and the lower return junction; tanks and their fields move together.
	var pressure_sites := [[1, 2080.0], [2, 4250.0], [5, 1430.0]]
	for chamber in range(3):
		var site: Array = pressure_sites[chamber]
		var at := _floor_point(int(site[0]), float(site[1]), 0.0, 244.0)
		var tank_color := Color(0.05, 0.25, 0.3, 0.76)
		_poly("CisternPressureCell%d" % chamber, PackedVector2Array([at + Vector2(-205, -26), at + Vector2(-180, -218), at + Vector2(-118, -270), at + Vector2(118, -270), at + Vector2(180, -218), at + Vector2(205, -26)]), tank_color, -3)
		for gauge in range(3):
			var center := at + Vector2(-92 + gauge * 92, -168 + 14 * (gauge % 2))
			_circle("CisternGauge%d_%d" % [chamber, gauge], center, 19.0, Color(0.25, 0.7, 0.7, 0.72), -2)
		_hazard("CisternPressureWave%d" % chamber, at + Vector2(0, -51), Vector2(0.91, 0.9), "pressure", "shaft_cistern_pump", Vector2((-1.0 if chamber % 2 == 0 else 1.0) * 170.0, -155), float(chamber) * 0.58)
	var channel := _bridge(4, 2)
	if channel != null:
		_platform("CisternOverflowStepA", channel.position.x - 185, channel.position.x - 65, channel.position.y - 58, Color(0.25, 0.57, 0.55), true, 10)
		_platform("CisternOverflowStepB", channel.position.x - 35, channel.position.x + 95, channel.position.y - 111, Color(0.3, 0.64, 0.59), true, 10)
		_label("CisternOverflowLandmark", "OVERFLOW OBSERVATORY", channel.position + Vector2(-145, -172), 310.0, Color(0.72, 0.94, 0.9))


func _build_approach_identity() -> void:
	_label("ApproachIdentity", "WARDEN'S DEFENCE LINE  •  USE COVER", Vector2(1290, 350), 560.0, Color(0.79, 0.88, 0.89))
	var sites := [[0, 4], [1, 3], [2, 5], [3, 2], [4, 5], [5, 3], [6, 5]]
	for index in range(sites.size()):
		var bridge := _bridge(int(sites[index][0]), int(sites[index][1]))
		if bridge == null:
			continue
		var direction := -1.0 if index % 2 == 0 else 1.0
		_sightline_pocket("ApproachSightline%02d" % index, bridge.position, direction)
		_barrier("ApproachCover%02d" % index, bridge.position.x - direction * 92.0, bridge.position.y, 52.0 + float(index % 3) * 7.0, Color(0.14, 0.33, 0.37))
	for tier in [2, 4, 6]:
		var bridge := _bridge(tier, 1)
		if bridge != null:
			_platform("ApproachWatchNiche%d" % tier, bridge.position.x - 55, bridge.position.x + 115, bridge.position.y - 70, Color(0.28, 0.55, 0.56), true, 11)
			_label("ApproachWatchLabel%d" % tier, "SENTRY POST", bridge.position + Vector2(-62, -123), 210.0, Color(0.64, 0.87, 0.86))


func _bridge(tier: int, index: int) -> StaticBody2D:
	return generated.get_node_or_null("T%d_Bridge%d" % [tier, index]) as StaticBody2D


func _hazard(node_name: String, at: Vector2, hazard_scale: Vector2, kind: String, disabled_by: String, impulse: Vector2, offset: float) -> void:
	var hazard := ROUTE_HAZARD_SCENE.instantiate() as Area2D
	hazard.name = node_name
	hazard.position = at
	hazard.scale = hazard_scale
	hazard.set("hazard_kind", kind)
	hazard.set("disabled_by_shortcut_id", disabled_by)
	hazard.set("force", impulse)
	hazard.set("initial_offset", offset)
	generated.add_child(hazard)
	if Engine.is_editor_hint():
		var fill := hazard.get_node("HazardFill") as Polygon2D
		var line := hazard.get_node("WarningLine") as Line2D
		var marks := hazard.get_node("DirectionMarks") as Line2D
		marks.visible = kind == "current"
		fill.color = Color(0.08, 0.46, 0.64, 0.22) if kind == "current" else (Color(0.38, 0.84, 0.91, 0.16) if kind == "pressure" else Color(0.74, 0.36, 0.18, 0.15))
		line.default_color = fill.color.lightened(0.35)


func _mining_support(node_name: String, at: Vector2, height: float) -> void:
	var timber := Line2D.new()
	timber.name = node_name
	timber.z_index = -1
	timber.width = 9.0
	timber.default_color = Color(0.29, 0.23, 0.16, 0.95)
	timber.points = PackedVector2Array([at + Vector2(-112, -4), at + Vector2(-92, -height), at + Vector2(92, -height), at + Vector2(112, -4), at + Vector2(92, -height), at + Vector2(-112, -4)])
	generated.add_child(timber)


func _build_dry_bypass(node_name: String, at: Vector2, direction: float) -> void:
	for step in range(3):
		var center := at.x + direction * (-118.0 + float(step) * 118.0)
		var y := at.y - 58.0 - (46.0 if step == 1 else 0.0)
		_platform("%s_%d" % [node_name, step], center - 50.0, center + 50.0, y, Color(0.28, 0.58, 0.62), true, 10.0)


func _pressure_manifold(node_name: String, at: Vector2, bends_right: bool) -> void:
	var direction := 1.0 if bends_right else -1.0
	var pipe := Line2D.new()
	pipe.name = node_name
	pipe.z_index = -1
	pipe.width = 8.0
	pipe.default_color = Color(0.22, 0.53, 0.57, 0.72)
	pipe.points = PackedVector2Array([at + Vector2(-direction * 175, -12), at + Vector2(-direction * 175, -120), at + Vector2(direction * 110, -120), at + Vector2(direction * 110, -52)])
	generated.add_child(pipe)


func _build_pressure_catwalk(node_name: String, at: Vector2) -> void:
	for step in range(3):
		var center := at.x - 125.0 + float(step) * 125.0
		_platform("%s_%d" % [node_name, step], center - 53, center + 53, at.y - 68.0 - 22.0 * float(step % 2), Color(0.32, 0.65, 0.64), true, 10)


func _sightline_pocket(node_name: String, at: Vector2, direction: float) -> void:
	var ray := Line2D.new()
	ray.name = node_name
	ray.z_index = -1
	ray.width = 3.0
	ray.default_color = Color(0.89, 0.46, 0.31, 0.47)
	ray.points = PackedVector2Array([at + Vector2(-direction * 185, -42), at + Vector2(direction * 185, -42)])
	generated.add_child(ray)


func _barrier(node_name: String, x: float, floor_y: float, height: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = Vector2(x, floor_y - height * 0.5)
	generated.add_child(body)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26.0, height)
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = color
	visual.polygon = PackedVector2Array([Vector2(-13, -height * 0.5), Vector2(13, -height * 0.5), Vector2(13, height * 0.5), Vector2(-13, height * 0.5)])
	body.add_child(visual)


func _label(node_name: String, words: String, at: Vector2, width: float, color: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.size = Vector2(width, 30)
	label.text = words
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	generated.add_child(label)


func _poly(node_name: String, points: PackedVector2Array, color: Color, layer: int) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = layer
	generated.add_child(polygon)


func _circle(node_name: String, center: Vector2, radius: float, color: Color, layer: int) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	_poly(node_name, points, color, layer)


func _build_partitions() -> void:
	# Falling between bridge segments must not skip a whole switchback. These
	# collidable strata leave only the end turn and authored side-shaft mouth.
	var levels: Array = plan["levels"]
	var tone: Color = plan["tone"]
	for tier in range(levels.size() - 1):
		var right_turn := tier % 2 == 0
		var left := 0.0 if right_turn else 520.0
		var right := layout_width - 520.0 if right_turn else layout_width
		var openings: Array[Vector2] = []
		if tier in [1, 3, 5] and tier + 1 < levels.size():
			var shaft_x := _shaft_gap_x(tier)
			openings.append(Vector2(shaft_x - 165.0, shaft_x + 165.0))
		var cursor := left
		var segment := 0
		for opening in openings:
			if opening.x > cursor + 24.0:
				_platform("Partition%d_%d" % [tier, segment], cursor, minf(opening.x, right), (float(levels[tier]) + float(levels[tier + 1])) * 0.5, tone.darkened(0.73), false, 18.0)
				segment += 1
			cursor = maxf(cursor, opening.y)
		if right > cursor + 24.0:
			_platform("Partition%d_%d" % [tier, segment], cursor, right, (float(levels[tier]) + float(levels[tier + 1])) * 0.5, tone.darkened(0.73), false, 18.0)


func _shaft_gap_x(tier: int) -> float:
	# Place the optional chimney near the mandatory end turn. A mid-course
	# shaft would skip almost two entire traverses and trivialize the room.
	var bridge_count := 0
	while generated.has_node("T%d_Bridge%d" % [tier, bridge_count]):
		bridge_count += 1
	var first_index := maxi(1, bridge_count - 3)
	var first := generated.get_node("T%d_Bridge%d" % [tier, first_index]) as StaticBody2D
	var second := generated.get_node("T%d_Bridge%d" % [tier, first_index + 1]) as StaticBody2D
	var first_half := ((first.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x / 2.0
	var second_half := ((second.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x / 2.0
	var gap_left := first.position.x + first_half if first.position.x < second.position.x else second.position.x + second_half
	var gap_right := second.position.x - second_half if first.position.x < second.position.x else first.position.x - first_half
	return (gap_left + gap_right) * 0.5


func _build_side_shafts() -> void:
	# Narrow local bypasses flank the end turns. They are optional, but every
	# ledge is climbable
	# in reverse with the plain 420 px/s jump impulse.
	for tier in [1, 3, 5]:
		if tier + 1 >= plan["levels"].size():
			continue
		var shaft_x := _shaft_gap_x(tier)
		var top_y: float = plan["levels"][tier]
		var bottom_y: float = plan["levels"][tier + 1]
		var recess := Polygon2D.new()
		recess.name = "VerticalShaft%d" % tier
		recess.z_index = -3
		recess.color = (plan["mist"] as Color).darkened(0.45)
		recess.polygon = PackedVector2Array([Vector2(shaft_x - 145, top_y - 110), Vector2(shaft_x + 145, top_y - 110), Vector2(shaft_x + 125, bottom_y + 15), Vector2(shaft_x - 120, bottom_y + 15)])
		generated.add_child(recess)
		for step in range(1, 5):
			var x := shaft_x - 88.0 if step % 2 == 0 else shaft_x - 12.0
			var y := top_y + float(step) * (bottom_y - top_y) / 5.0
			_platform("Shaft%d_Rung%d" % [tier, step], x, x + 120.0, y, (plan["tone"] as Color).lightened(0.26), true, 10.0)
		var trail := Line2D.new()
		trail.name = "Shaft%d_Cable" % tier
		trail.z_index = -1
		trail.width = 3.0
		trail.default_color = Color(0.44, 0.74, 0.78, 0.6)
		trail.points = PackedVector2Array([Vector2(shaft_x + 90, top_y - 105), Vector2(shaft_x + 87, bottom_y + 5)])
		generated.add_child(trail)
		var notice := Label.new()
		notice.name = "Shaft%d_Hint" % tier
		notice.position = Vector2(shaft_x - 125, top_y - 150)
		notice.add_theme_font_size_override("font_size", 10)
		notice.add_theme_color_override("font_color", Color(0.58, 0.86, 0.84, 0.7))
		notice.text = "SIDE SHAFT"
		generated.add_child(notice)


func _build_high_niches() -> void:
	# Broad side chambers are 220 px above the traffic line, reached through
	# four 55 px steps. They create real upward exploration and treasure detours.
	for tier in [1, 4]:
		var foundation := generated.get_node("T%d_Bridge4" % tier) as StaticBody2D
		var x := foundation.position.x
		var y := foundation.position.y
		var alcove := Polygon2D.new()
		alcove.name = "Niche%d_Alcove" % tier
		alcove.z_index = -3
		alcove.color = (plan["mist"] as Color).darkened(0.38)
		alcove.polygon = PackedVector2Array([Vector2(x - 250, y - 268), Vector2(x + 385, y - 270), Vector2(x + 400, y + 16), Vector2(x - 260, y + 16)])
		generated.add_child(alcove)
		for step in range(1, 5):
			var center := x - 130.0 + float(step) * 78.0
			_platform("Niche%d_Ascent%d" % [tier, step], center - 57.0, center + 57.0, y - float(step) * 55.0, (plan["tone"] as Color).lightened(0.19 + 0.03 * step), true, 10.0)
		_platform("Niche%d_Crest" % tier, x + 125.0, x + 390.0, y - 220.0, (plan["tone"] as Color).lightened(0.35), true, 16.0)
		var marker := Label.new()
		marker.name = "Niche%d_Label" % tier
		marker.position = Vector2(x + 157.0, y - 275.0)
		marker.add_theme_font_size_override("font_size", 10)
		marker.add_theme_color_override("font_color", Color(0.69, 0.93, 0.87, 0.8))
		marker.text = "ORE CHAMBER" if room.name == "ShaftHollow" else ("PRESSURE CELL" if room.name == "BlackwaterCistern" else "HIDDEN ALCOVE")
		generated.add_child(marker)


func _build_dead_end_branches() -> void:
	# These are deliberate one-way detours. They end in their own chamber and
	# do not quietly reconnect to the next main corridor.
	for tier in [1, 3, 5]:
		var anchor := generated.get_node_or_null("T%d_Bridge3" % tier) as StaticBody2D
		if anchor == null:
			continue
		var side := -1.0 if anchor.position.x > layout_width * 0.5 else 1.0
		var chamber_y := anchor.position.y - 176.0
		for step in range(1, 4):
			var center := anchor.position.x + side * (76.0 * float(step))
			_platform("Branch%d_Step%d" % [tier, step], center - 54.0, center + 54.0, anchor.position.y - 54.0 * float(step), (plan["tone"] as Color).lightened(0.18), true, 10.0)
		var near_x := anchor.position.x + side * 210.0
		var far_x := anchor.position.x + side * 650.0
		var chamber_left := minf(near_x, far_x)
		var chamber_right := maxf(near_x, far_x)
		_platform("Branch%d_Chamber" % tier, chamber_left, chamber_right, chamber_y, (plan["tone"] as Color).lightened(0.27), true, 17.0)
		var shadow := Polygon2D.new()
		shadow.name = "Branch%d_Shadow" % tier
		shadow.z_index = -7
		shadow.color = (plan["mist"] as Color).darkened(0.30)
		shadow.polygon = PackedVector2Array([
			Vector2(chamber_left - 45.0, chamber_y - 145.0),
			Vector2(chamber_right + 45.0, chamber_y - 145.0),
			Vector2(chamber_right + 45.0, chamber_y + 38.0),
			Vector2(chamber_left - 45.0, chamber_y + 38.0),
		])
		generated.add_child(shadow)
		_label("Branch%d_Label" % tier, "DEAD-END CHAMBER", Vector2(chamber_left + 24.0, chamber_y - 126.0), chamber_right - chamber_left - 48.0, Color(0.56, 0.82, 0.81, 0.68))


func _build_track(tier: int, from_x: float, to_x: float, y: float, widths: Array, gap: float, direction: int) -> void:
	var cursor := from_x
	# Nine readable chunks preserve authored encounter anchors 0..8 while the
	# whole tier remains only one corridor leg instead of a room-wide shelf.
	var segment_count := 9
	var effective_gap := clampf(gap, 42.0, 58.0)
	var extent := (absf(to_x - from_x) - effective_gap * float(segment_count - 1)) / float(segment_count)
	extent = maxf(extent, 82.0)
	var previous_left := 0.0
	var previous_right := 0.0
	var previous_y := 0.0
	for segment in range(segment_count):
		var offset: float = float(plan["rise"][segment % plan["rise"].size()]) * 0.55
		var next_x := cursor + float(direction) * extent
		var left := minf(cursor, next_x)
		var right := maxf(cursor, next_x)
		var bridge_y := y + offset
		_platform("T%d_Bridge%d" % [tier, segment], left, right, bridge_y, (plan["tone"] as Color).lightened(0.07 * float((tier + segment) % 4)), false, 18.0)
		if segment > 0:
			var gap_left := previous_right if direction > 0 else right
			var gap_right := left if direction > 0 else previous_left
			var catch_y := maxf(previous_y, bridge_y) + 58.0
			_platform("T%d_Catch%d" % [tier, segment - 1], gap_left - 38.0, gap_right + 38.0, catch_y, (plan["tone"] as Color).darkened(0.39), false, 10.0)
		if segment % 3 == 1:
			_platform("T%d_Shelf%d" % [tier, segment], left + 35.0, minf(right + 35.0, left + 170.0), y + offset - 66.0, (plan["tone"] as Color).lightened(0.26), true, 9.0)
		cursor = next_x + float(direction) * effective_gap
		previous_left = left
		previous_right = right
		previous_y = bridge_y


func _build_turn(tier: int, x: float, top_y: float, bottom_y: float, direction: int) -> void:
	var edge := x
	var intervals := maxi(2, int(ceil(absf(bottom_y - top_y) / 58.0)))
	var upper_tier := tier if top_y < bottom_y else tier + 1
	var nearest := INF
	var rim_x := x
	for body in generated.get_children():
		if not body is StaticBody2D or not String(body.name).begins_with("Chamber%d_Floor" % upper_tier):
			continue
		var half: float = body.get_node("CollisionShape2D").shape.size.x * 0.5
		var candidate := clampf(x, body.position.x - half, body.position.x + half)
		if absf(candidate - x) < nearest:
			nearest = absf(candidate - x)
			rim_x = candidate
	assert(nearest < INF, "Shaft route has no upper landing")
	var inside := -1.0 if rim_x < x else 1.0
	for step in range(1, intervals):
		var ledge_y := lerpf(top_y, bottom_y, float(step) / float(intervals))
		var center := edge + inside * (58.0 + float((step + tier) % 2) * 42.0)
		var left := center - 60.0
		var right := center + 60.0
		if step == (1 if top_y < bottom_y else intervals - 1):
			if inside < 0:
				left = minf(left, rim_x + 32.0)
			else:
				right = maxf(right, rim_x - 32.0)
		_platform("Turn%d_Drop%d" % [tier, step], left, right, ledge_y, (plan["tone"] as Color).lightened(0.17), true, 10.0)
	var arrow := Label.new()
	arrow.name = "DepthMarker%d" % tier
	arrow.position = Vector2(edge - 126.0 if direction > 0 else edge + 70.0, top_y - 95.0)
	arrow.add_theme_font_size_override("font_size", 11)
	arrow.add_theme_color_override("font_color", Color(0.56, 0.84, 0.86, 0.8))
	arrow.text = "DEPTH %d  v" % (tier + 2)
	generated.add_child(arrow)


func _platform(label: String, left: float, right: float, y: float, color: Color, one_way: bool, thickness: float) -> void:
	var body := StaticBody2D.new()
	body.name = label
	body.position = Vector2((left + right) / 2.0, y)
	generated.add_child(body)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(right - left, thickness)
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.name = "Stone"
	visual.color = color
	var half_width := (right - left) / 2.0
	var half_height := thickness / 2.0
	visual.polygon = PackedVector2Array([Vector2(-half_width, -half_height), Vector2(half_width, -half_height), Vector2(half_width, half_height), Vector2(-half_width, half_height)])
	body.add_child(visual)
	var lip := Line2D.new()
	lip.name = "WetEdge"
	lip.width = 2.0
	lip.default_color = color.lightened(0.27)
	lip.points = PackedVector2Array([Vector2(-half_width, -half_height), Vector2(half_width, -half_height)])
	body.add_child(lip)


func _alpha(color: Color, opacity: float) -> Color:
	color.a = opacity
	return color


func _move(name: String, at: Vector2) -> void:
	var node := room.get_node_or_null(name) as Node2D
	if node != null:
		node.position = at


func _relocate_existing_features() -> void:
	var bottom := float(plan["levels"].back()) - 33.0
	var final_right := layout_width - 45.0
	var final_marker := layout_width - 110.0
	match room.name:
		"ShaftHollow":
			_move("Relay", _floor_point(1, 2400))
			_move("DriftDoor", Vector2(3780, 297))
			_move("DriftReturn", Vector2(3728, 297))
			_move("CrossingDoor", Vector2(final_right - 200.0, bottom))
			_move("CrossingEntry", Vector2(final_marker - 200.0, bottom))
			_move("LowerReturnDoor", Vector2(final_right, bottom))
			_move("LowerEntry", Vector2(final_marker, bottom))
		"DrownedCrossing":
			_move("HollowDoor", Vector2(final_right, bottom))
			_move("HollowEntry", Vector2(final_marker, bottom))
			_move("GalleryDoor", Vector2(final_right - 210.0, bottom))
			_move("GalleryReturn", Vector2(final_marker - 210.0, bottom))
			_move("CisternDoor", Vector2(300, 1242))
			_move("CisternReturn", Vector2(365, 1242))
			_move("Valve", _floor_point(1, 2700))
			_move("CrossingCache", _floor_point(6, 2350))
		"FloodedGallery":
			_move("WardenShortcutDoor", Vector2(final_right, bottom))
			_move("ShaftEntry", Vector2(final_marker, bottom))
			_move("CisternDoor", Vector2(310, 657))
			_move("CisternReturn", Vector2(370, 657))
			_move("UpperControl", _floor_point(1, 2100))
			_move("GalleryCache", _floor_point(1, 2400))
		"BlackwaterCistern":
			_move("GalleryShortcutDoor", Vector2(final_right, bottom))
			_move("GalleryEntry", Vector2(final_marker, bottom))
			_move("HighDial", _floor_point(1, 3460))
			_move("FarDial", Vector2(final_right - 330.0, bottom))
			_move("CisternLamp", Vector2(500, float(plan["levels"][5]) - 33.0))
			_move("CisternCache", Vector2(720, float(plan["levels"][5]) - 33.0))
			var memory_crest := generated.get_node("Niche1_Crest") as StaticBody2D
			_move("MemoryReliquary", memory_crest.position + Vector2(-65, -34))
			var echo_plank := generated.get_node("T2_Bridge4") as StaticBody2D
			_move("DawnEcho", echo_plank.position + Vector2(-48, -33))
			_move("SequenceHint", _floor_point(1, 3460) + Vector2(-170, -105))
		"WardenApproach":
			_move("ArenaDoor", Vector2(final_right, bottom))
			_move("ShaftEntry", Vector2(final_marker, bottom))
			_move("CounterweightCrank", Vector2(final_right - 290.0, bottom))
			_move("ApproachLamp", Vector2(490, float(plan["levels"][5]) - 33.0))
			_move("UpperCache", _floor_point(0, 1600))
			_move("RouteHint", Vector2(1540, 350))


func _build_return_lift() -> void:
	var id: String = plan["id"]
	var last: int = plan["levels"].size() - 1
	var final_chamber := _chamber_rect(last)
	# Follow the final gallery, not the old room-wide bounding rectangle.
	# Drowned Crossing ends further west; a fixed X left its lift on an island.
	var bottom_at := _floor_point(last, final_chamber.end.x - 368.0, 32.0, 180.0)
	var bottom_y := bottom_at.y
	var top_y := float(plan["entry_y"]) - 32.0
	var top_lift_x := 240.0 if room.name == "ShaftHollow" else (185.0 if room.name == "WardenApproach" else 385.0)
	var top_marker_x := 290.0 if room.name == "ShaftHollow" else (240.0 if room.name == "WardenApproach" else 460.0)
	_platform("ReturnLiftLanding", bottom_at.x - 100.0, bottom_at.x + 85.0, bottom_y + 32.0, (plan["tone"] as Color).lightened(0.22), false, 18.0)
	var top_marker := Marker2D.new()
	top_marker.name = "ReturnTop"
	top_marker.position = Vector2(top_marker_x, top_y)
	top_marker.add_to_group("shaft_%s_lift_top" % id)
	generated.add_child(top_marker)
	var bottom_marker := Marker2D.new()
	bottom_marker.name = "ReturnBottom"
	bottom_marker.position = bottom_at + Vector2(-50, 0)
	bottom_marker.add_to_group("shaft_%s_lift_bottom" % id)
	generated.add_child(bottom_marker)
	for below in [false, true]:
		var lift := LIFT_SCENE.instantiate()
		lift.name = "ReturnLiftBottom" if below else "ReturnLiftTop"
		lift.position = bottom_at if below else Vector2(top_lift_x, top_y)
		lift.shortcut_id = "shaft_%s_return_lift" % id
		lift.room_id = "shaft_%s" % id
		lift.target_marker_group = StringName("shaft_%s_lift_top" % id) if below else StringName("shaft_%s_lift_bottom" % id)
		lift.activates_shortcut = below
		lift.lift_label = "RETURN LIFT"
		lift.enemy_block_radius = 70.0
		generated.add_child(lift)


func _populate_descent() -> void:
	var levels: Array = plan["levels"]
	var id: String = plan["id"]
	for tier in range(levels.size()):
		# Two spaced encounters per traverse leave breathing room between fights.
		for slot in range(2):
			var index := tier * 2 + slot
			var enemy_name := "DepthFoe%d" % index
			if generated.has_node(enemy_name):
				continue
			var plank := generated.get_node_or_null("T%d_Bridge%d" % [tier, 1 if slot == 0 else 6]) as StaticBody2D
			if plank == null:
				continue
			var enemy_scene: PackedScene = WISP_SCENE if (tier + slot) % 4 == 0 else (SENTRY_SCENE if (tier + slot) % 3 == 0 else CRAWLER_SCENE)
			var enemy := enemy_scene.instantiate() as Node2D
			enemy.name = enemy_name
			enemy.position = _floor_point(tier, plank.position.x, 98.0 if enemy_scene == WISP_SCENE else 31.0)
			_add_streamed_generated_actor(enemy)
		for crate_slot in range(2):
			var crate_name := "DepthCrate%d_%d" % [tier, crate_slot]
			if generated.has_node(crate_name):
				continue
			var crate_plank := generated.get_node_or_null("T%d_Bridge%d" % [tier, 2 if crate_slot == 0 else 5]) as StaticBody2D
			if crate_plank == null:
				continue
			var crate := CRATE_SCENE.instantiate() as Node2D
			crate.name = crate_name
			crate.position = _floor_point(tier, crate_plank.position.x, 31.0, 40.0)
			crate.set("empty_drop_chance", 0.34)
			_add_streamed_generated_actor(crate)
		if tier > 0:
			var fauna_name := "DepthFauna%d" % tier
			if generated.has_node(fauna_name):
				continue
			var fauna_plank := generated.get_node_or_null("T%d_Bridge4" % tier) as StaticBody2D
			if fauna_plank == null:
				continue
			var fauna := FAUNA_SCENE.instantiate() as Node2D
			fauna.name = fauna_name
			fauna.position = _floor_point(tier, fauna_plank.position.x, 31.0)
			fauna.set("creature_name", "Shaft Moth" if tier % 2 == 0 else "Cave Grazer")
			fauna.set("zone_id", "sunken_shaft")
			_add_streamed_generated_actor(fauna)
	for branch_tier in [1, 3, 5]:
		var chamber := generated.get_node("Branch%d_Chamber" % branch_tier) as StaticBody2D
		var branch_crate_name := "BranchCrate%d" % branch_tier
		if not generated.has_node(branch_crate_name):
			var branch_crate := CRATE_SCENE.instantiate() as Node2D
			branch_crate.name = branch_crate_name
			branch_crate.position = chamber.position + Vector2(105.0, -31.0)
			branch_crate.set("empty_drop_chance", 0.42 if branch_tier < 5 else 0.18)
			_add_streamed_generated_actor(branch_crate)
		if branch_tier == 1:
			if not generated.has_node("BranchGrazer"):
				var quiet_life := FAUNA_SCENE.instantiate() as Node2D
				quiet_life.name = "BranchGrazer"
				quiet_life.position = chamber.position + Vector2(-105.0, -31.0)
				quiet_life.set("creature_name", "Lost Cave Grazer")
				quiet_life.set("zone_id", "sunken_shaft")
				quiet_life.set("start_resting", true)
				_add_streamed_generated_actor(quiet_life)
		else:
			var guard_name := "BranchGuard%d" % branch_tier
			if not generated.has_node(guard_name):
				var guard_scene: PackedScene = WISP_SCENE if branch_tier == 3 else SENTRY_SCENE
				var branch_guard := guard_scene.instantiate() as Node2D
				branch_guard.name = guard_name
				branch_guard.position = chamber.position + Vector2(-105.0, -96.0 if guard_scene == WISP_SCENE else -31.0)
				branch_guard.set("zone_id", "sunken_shaft")
				_add_streamed_generated_actor(branch_guard)
	if not generated.has_node("HiddenDepthCache"):
		var treasure := CACHE_SCENE.instantiate() as Node2D
		treasure.name = "HiddenDepthCache"
		var crest := generated.get_node("Niche4_Crest") as StaticBody2D
		treasure.position = crest.position + Vector2(0.0, -36.0)
		treasure.set("cache_id", "shaft_%s_depth_cache" % id)
		treasure.set("cache_name", "Hidden %s Cache" % id.capitalize())
		treasure.set("gold_reward", 18)
		treasure.set("required_event_ids", PackedStringArray(["shaft_%s_hidden_depth_cleared" % id]))
		treasure.set("reward_item_id", "ether_dust" if id in ["hollow", "gallery"] else "iron_fragment")
		generated.add_child(treasure)
	_populate_identity_encounters()
	if not generated.has_node("ExplorationSites"):
		var sites := Node2D.new()
		sites.name = "ExplorationSites"
		sites.set_script(EXPLORATION_SITES)
		sites.set("expansion", self)
		generated.add_child(sites)


func _populate_identity_encounters() -> void:
	match room.name:
		"ShaftHollow":
			_spawn_identity_foe(CRAWLER_SCENE, "OreCrawlerA", 1, 3, Vector2(-70, -31))
			_spawn_identity_foe(CRAWLER_SCENE, "OreCrawlerB", 3, 5, Vector2(65, -31))
			_spawn_identity_foe(WISP_SCENE, "RockfallWisp", 5, 3, Vector2(0, -102))
			_spawn_identity_fauna("Lantern Moth", "HollowOreMoth", 3, 4)
		"DrownedCrossing":
			_spawn_identity_foe(WISP_SCENE, "CurrentWispA", 1, 3, Vector2(0, -112))
			_spawn_identity_foe(CRAWLER_SCENE, "ChannelCrawlerA", 3, 2, Vector2(72, -31))
			_spawn_identity_foe(WISP_SCENE, "CurrentWispB", 5, 3, Vector2(0, -112))
			_spawn_identity_fauna("Blind Eel", "CrossingEel", 4, 5)
		"FloodedGallery":
			_spawn_identity_foe(SENTRY_SCENE, "ValveSentryA", 1, 2, Vector2(-70, -31))
			_spawn_identity_foe(SENTRY_SCENE, "ValveSentryB", 4, 5, Vector2(65, -31))
			_spawn_identity_foe(WISP_SCENE, "PressureWispA", 3, 3, Vector2(0, -105))
			_spawn_identity_fauna("Pipe Newt", "GalleryNewt", 5, 2)
		"BlackwaterCistern":
			_spawn_identity_foe(WISP_SCENE, "GaugeWispA", 1, 4, Vector2(-82, -112))
			_spawn_identity_foe(CRAWLER_SCENE, "TankCrawler", 3, 4, Vector2(78, -31))
			_spawn_identity_foe(WISP_SCENE, "GaugeWispB", 5, 4, Vector2(80, -112))
			_spawn_identity_fauna("Blackwater Grazer", "CisternGrazer", 4, 2)
		"WardenApproach":
			for index in range(3):
				var tier := 2 + index * 2
				_spawn_identity_foe(SENTRY_SCENE, "WatchSentry%d" % index, tier, 1, Vector2(25, -100))
			_spawn_identity_foe(CRAWLER_SCENE, "GuardCrawler", 5, 3, Vector2(75, -31))
			_spawn_identity_fauna("Armored Cave Grazer", "ApproachGrazer", 3, 2)
	_spawn_hidden_depth_ambush()


func _spawn_hidden_depth_ambush() -> void:
	if generated.has_node("HiddenDepthAmbush"):
		return
	var crest := generated.get_node("Niche4_Crest") as StaticBody2D
	var encounter := LOCAL_ENCOUNTER_SCENE.instantiate() as Area2D
	encounter.name = "HiddenDepthAmbush"
	encounter.position = crest.position
	encounter.set("encounter_id", "shaft_%s_hidden_depth" % String(plan["id"]))
	encounter.set("completion_event_id", "shaft_%s_hidden_depth_cleared" % String(plan["id"]))
	encounter.set("encounter_title", "GUARDED SUPPLY ALCOVE")
	encounter.set("zone_id", "sunken_shaft")
	encounter.get("enemy_scenes").append(CRAWLER_SCENE)
	encounter.get("enemy_scenes").append(WISP_SCENE)
	encounter.get("spawn_offsets").append(Vector2(-105.0, -31.0))
	encounter.get("spawn_offsets").append(Vector2(105.0, -105.0))
	generated.add_child(encounter)


func _spawn_identity_foe(scene: PackedScene, node_name: String, tier: int, bridge_index: int, offset: Vector2) -> void:
	if generated.has_node(node_name):
		return
	var bridge := _bridge(tier, bridge_index)
	if bridge == null:
		return
	var foe := scene.instantiate() as Node2D
	foe.name = node_name
	foe.position = _floor_point(tier, bridge.position.x + offset.x, -offset.y)
	foe.set("zone_id", "sunken_shaft")
	_add_streamed_generated_actor(foe)


func _spawn_identity_fauna(creature_name: String, node_name: String, tier: int, bridge_index: int) -> void:
	if generated.has_node(node_name):
		return
	var bridge := _bridge(tier, bridge_index)
	if bridge == null:
		return
	var fauna := FAUNA_SCENE.instantiate() as Node2D
	fauna.name = node_name
	fauna.position = _floor_point(tier, bridge.position.x, 31)
	fauna.set("creature_name", creature_name)
	fauna.set("zone_id", "sunken_shaft")
	fauna.set("start_resting", tier % 2 == 1)
	_add_streamed_generated_actor(fauna)
