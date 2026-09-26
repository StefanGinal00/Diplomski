@tool
extends Node2D

## Six authored Ashen routes climb through alternating ruined galleries. Each
## gallery is broken into short, height-shifted spans; an undercroft catches
## missed jumps, while side niches and drop shafts offer exploration/returns.
## The same geometry is drawn in the editor and used for runtime collision.

@export var course_id: StringName = &"causeway"
@export_range(3600.0, 4600.0, 10.0) var course_width: float = 4200.0
@export_range(900.0, 1300.0, 10.0) var legacy_width: float = 1100.0
@export var ground_y: float = 420.0

const GALLERY_COUNT := 6
const GALLERY_RISE := 260.0
const GALLERY_SPACING := 270.0
const DECK_THICKNESS := 18.0
const STEP_WIDTH := 112.0
const STEP_THICKNESS := 10.0
const STEP_RISE := 52.0
const STEP_COUNT := 5
const CRATE_SCENE: PackedScene = preload("res://DestructibleCrate.tscn")
const FIEND_SCENE: PackedScene = preload("res://AshFiend.tscn")
const SENTRY_SCENE: PackedScene = preload("res://AshSentry.tscn")
const FAUNA_SCENE: PackedScene = preload("res://NeutralCreature.tscn")
const CACHE_SCENE: PackedScene = preload("res://ResonanceCache.tscn")
const LOCAL_ENCOUNTER_SCENE: PackedScene = preload("res://LocalizedEncounter.tscn")
const HEAT_VENT_SCENE: PackedScene = preload("res://HeatVent.tscn")
const PRESSURE_SURGE_SCENE: PackedScene = preload("res://TidePulse.tscn")
const FIELD_OPERATIONS := preload("res://AshFieldOperations.gd")
const FIELD_DRESSING := preload("res://AshRouteDressing.gd")
const INDUSTRY_DRESSING := preload("res://AshIndustryDressing.gd")
const AUTHORED_GALLERIES := {
	"CinderShelfFiend": 0, "OverlookSentry": 2, "HighSpineFiend": 3, "FinalWatchSentry": 5,
	"SmelterFiend": 0, "CrossDuctSentry": 2, "FanGalleryFiend": 3, "LastFurnaceSentry": 5,
	"RampartFiend": 0, "GallerySentry": 2, "SparringFiend": 3, "LastWatchSentry": 5,
	"OverflowFiend": 0, "PressureSentry": 2, "SpillwayFiend": 3, "CrownSentry": 4,
	"ChoirSentry": 3, "NaveGalleryFiend": 0, "BelfrySentry": 2, "ChancelFiend": 3, "ReliquaryGuard": 5,
	"BrokenRoadFiend": 0, "RampartSentry": 2, "HighRoadFiend": 3, "GateWatchSentry": 5,
}

# The original hand-placed population is kept as data so WorldPopulation can
# attach it only while the player is inside the room. Encounters, puzzles,
# doors, lamps and quest infrastructure deliberately remain persistent.
const AUTHORED_POPULATION := {
	"causeway": [
		{"name": "NearFiend", "scene": FIEND_SCENE, "position": Vector2(295, 357)},
		{"name": "FarSentry", "scene": SENTRY_SCENE, "position": Vector2(870, 357)},
		{"name": "CinderShelfFiend", "scene": FIEND_SCENE, "position": Vector2(3150, -3)},
		{"name": "OverlookSentry", "scene": SENTRY_SCENE, "position": Vector2(3260, -343)},
		{"name": "HighSpineFiend", "scene": FIEND_SCENE, "position": Vector2(2300, -683)},
		{"name": "FinalWatchSentry", "scene": SENTRY_SCENE, "position": Vector2(3440, -1023)},
	],
	"forge": [
		{"name": "EntryFiend", "scene": FIEND_SCENE, "position": Vector2(245, 387)},
		{"name": "UpperSentry", "scene": SENTRY_SCENE, "position": Vector2(450, 194)},
		{"name": "FloorSentry", "scene": SENTRY_SCENE, "position": Vector2(683, 387)},
		{"name": "SmelterFiend", "scene": FIEND_SCENE, "position": Vector2(2900, 27)},
		{"name": "CrossDuctSentry", "scene": SENTRY_SCENE, "position": Vector2(3320, -313)},
		{"name": "FanGalleryFiend", "scene": FIEND_SCENE, "position": Vector2(3100, -653)},
		{"name": "LastFurnaceSentry", "scene": SENTRY_SCENE, "position": Vector2(3380, -993)},
	],
	"barracks": [
		{"name": "EntryFiend", "scene": FIEND_SCENE, "position": Vector2(335, 387)},
		{"name": "UpperSentry", "scene": SENTRY_SCENE, "position": Vector2(760, 258)},
		{"name": "RampartFiend", "scene": FIEND_SCENE, "position": Vector2(3310, 27)},
		{"name": "GallerySentry", "scene": SENTRY_SCENE, "position": Vector2(2760, -313)},
		{"name": "SparringFiend", "scene": FIEND_SCENE, "position": Vector2(2390, -653)},
		{"name": "LastWatchSentry", "scene": SENTRY_SCENE, "position": Vector2(3270, -993)},
	],
	"reservoir": [
		{"name": "NearFiend", "scene": FIEND_SCENE, "position": Vector2(252, 387)},
		{"name": "UpperSentry", "scene": SENTRY_SCENE, "position": Vector2(2980, -653)},
		{"name": "OverflowFiend", "scene": FIEND_SCENE, "position": Vector2(3350, 27)},
		{"name": "PressureSentry", "scene": SENTRY_SCENE, "position": Vector2(3340, -313)},
		{"name": "SpillwayFiend", "scene": FIEND_SCENE, "position": Vector2(2290, -653)},
		{"name": "CrownSentry", "scene": SENTRY_SCENE, "position": Vector2(3170, -993)},
	],
	"chapel": [
		{"name": "NaveFiend", "scene": FIEND_SCENE, "position": Vector2(325, 387)},
		{"name": "ChoirSentry", "scene": SENTRY_SCENE, "position": Vector2(3490, -653)},
		{"name": "EntranceCrate", "scene": CRATE_SCENE, "position": Vector2(280, 387)},
		{"name": "NaveGalleryFiend", "scene": FIEND_SCENE, "position": Vector2(3350, 27)},
		{"name": "BelfrySentry", "scene": SENTRY_SCENE, "position": Vector2(3060, -313)},
		{"name": "ChancelFiend", "scene": FIEND_SCENE, "position": Vector2(2915, -653)},
		{"name": "ReliquaryGuard", "scene": SENTRY_SCENE, "position": Vector2(3580, -993)},
	],
	"outskirts": [
		{"name": "GateFiend", "scene": FIEND_SCENE, "position": Vector2(360, 357), "properties": {"gold_reward": 14}, "groups": [&"hearth_gate_target"]},
		{"name": "GateSentry", "scene": SENTRY_SCENE, "position": Vector2(650, 357), "properties": {"gold_reward": 16}, "groups": [&"hearth_gate_target"]},
		{"name": "AshGrazer", "scene": FAUNA_SCENE, "position": Vector2(825, 371), "properties": {"zone_id": "ashen_bastion", "creature_name": "Ash Grazer", "passive_tint": Color(0.69, 0.65, 0.52, 1), "hostile_tint": Color(0.93, 0.46, 0.31, 1), "rest_seconds": 4.0}},
		{"name": "BrokenRoadFiend", "scene": FIEND_SCENE, "position": Vector2(3070, -3)},
		{"name": "RampartSentry", "scene": SENTRY_SCENE, "position": Vector2(2880, -343)},
		{"name": "HighRoadFiend", "scene": FIEND_SCENE, "position": Vector2(2390, -683)},
		{"name": "GateWatchSentry", "scene": SENTRY_SCENE, "position": Vector2(3260, -1023)},
	],
}

const IDENTITY_NAMES := {
	&"causeway": "SHATTERED MARCH",
	&"forge": "THE SIX FURNACES",
	&"barracks": "EMBER DRILL YARD",
	&"reservoir": "PRESSURE WORKS",
	&"chapel": "BELLS OF THE LAST EMBER",
	&"outskirts": "SCORIA GATE SIEGE",
}

const COURSE_PATHS := {
	"causeway": [1100.0, 3400.0, 1500.0, 3850.0, 1850.0, 3600.0, 1200.0, 3980.0],
	"forge": [1100.0, 3000.0, 1250.0, 3700.0, 1650.0, 3900.0, 1450.0, 3980.0],
	"barracks": [1100.0, 3650.0, 1750.0, 3950.0, 1450.0, 3300.0, 1200.0, 3980.0],
	"reservoir": [1100.0, 3100.0, 1350.0, 3900.0, 1850.0, 3700.0, 1250.0, 3980.0],
	"chapel": [1100.0, 3700.0, 1800.0, 3850.0, 1250.0, 3400.0, 1550.0, 3980.0],
	"outskirts": [1100.0, 2850.0, 1200.0, 3500.0, 1500.0, 3950.0, 1750.0, 3980.0],
}

# Seven connected rooms per route (entry + six authored destinations). These
# are independent silhouettes, not six recolours of one switchback. Values
# are [left_ratio, right_ratio, floor_y]; consecutive rooms overlap only where
# a reversible stair shaft joins them.
const CHAMBER_LAYOUTS := {
	"causeway": [[0.00, 0.35, 420.0], [0.25, 0.59, 120.0], [0.49, 0.84, -180.0], [0.70, 1.00, 120.0], [0.55, 0.85, -480.0], [0.22, 0.63, -780.0], [0.40, 0.96, -1080.0]],
	"forge": [[0.00, 0.32, 420.0], [0.23, 0.56, 120.0], [0.47, 0.81, -180.0], [0.68, 1.00, -480.0], [0.45, 0.78, -180.0], [0.18, 0.59, -780.0], [0.40, 0.96, -1080.0]],
	"barracks": [[0.00, 0.41, 420.0], [0.30, 0.73, 120.0], [0.58, 1.00, -180.0], [0.35, 0.74, -480.0], [0.08, 0.46, -180.0], [0.20, 0.61, -780.0], [0.48, 0.96, -1080.0]],
	"reservoir": [[0.00, 0.34, 420.0], [0.23, 0.57, 120.0], [0.05, 0.33, -180.0], [0.21, 0.61, -480.0], [0.51, 0.89, -180.0], [0.72, 1.00, -780.0], [0.38, 0.82, -1080.0]],
	"chapel": [[0.00, 0.37, 420.0], [0.27, 0.64, 120.0], [0.52, 0.89, -180.0], [0.69, 1.00, 120.0], [0.48, 0.81, -480.0], [0.20, 0.59, -780.0], [0.42, 0.96, -1080.0]],
	"outskirts": [[0.00, 0.33, 420.0], [0.22, 0.50, 120.0], [0.04, 0.32, -180.0], [0.20, 0.56, -480.0], [0.47, 0.83, -780.0], [0.68, 1.00, -480.0], [0.38, 0.92, -1080.0]],
}

var _solid_rects: Array[Rect2] = []
var _step_rects: Array[Rect2] = []
var _track_rects: Dictionary = {}
var _niche_crests: Array[Rect2] = []
var _preview_only := false
var population_loaded := false


func _ready() -> void:
	if Engine.is_editor_hint():
		var edited_root := get_tree().edited_scene_root
		if edited_root != null and edited_root != get_parent():
			_preview_only = true
			_build_route()
			_build_identity_landmarks()
			_snap_room_features()
			_build_field_dressing()
			queue_redraw()
			return
	_build_route()
	_build_identity_landmarks()
	_snap_room_features()
	_build_field_dressing()
	if Engine.is_editor_hint():
		call_deferred("_spawn_authored_population")
	elif not _uses_world_population_streaming():
		# The room parent is still attaching siblings during this callback.
		call_deferred("activate_room_population")
	queue_redraw()


func _build_field_dressing() -> void:
	if not FIELD_OPERATIONS.PROFILES.has(String(course_id)):
		return
	var dressing := Node2D.new()
	dressing.name = "FieldDressing"
	dressing.set_script(FIELD_DRESSING if String(course_id) in ["causeway", "chapel"] else INDUSTRY_DRESSING)
	dressing.set("region", String(course_id))
	add_child(dressing)


func _uses_world_population_streaming() -> bool:
	var room := get_parent()
	return room != null and room.get_parent() != null and room.get_parent().get_node_or_null("RoomActivityDirector") != null


func activate_room_population() -> void:
	if Engine.is_editor_hint():
		return
	_spawn_authored_population()
	# Persistent features were placed in _ready. Never relocate restored actors.
	_populate_route()
	_populate_streamed_identity_props()
	if population_loaded:
		return
	_populate_identity_gameplay()
	if FIELD_OPERATIONS.PROFILES.has(String(course_id)):
		var operations := Node2D.new()
		operations.name = "FieldOperations"
		operations.set_script(FIELD_OPERATIONS)
		operations.set("route", self)
		add_child(operations)
		var dressing := get_node_or_null("FieldDressing")
		if dressing != null and dressing.has_method("bind_operations"):
			dressing.bind_operations()
	population_loaded = true


func is_population_loaded() -> bool:
	return population_loaded


func get_replay_spawn_points() -> Array[Vector2]:
	# The old replay coordinates point at the pre-expansion entry court. Anchor
	# the upgraded patrol to two late switchbacks instead.
	if _track_rects.size() < 6:
		return []
	var upper: Rect2 = _track_rects[4][mini(3, _track_rects[4].size() - 1)]
	var lower: Rect2 = _track_rects[5][mini(6, _track_rects[5].size() - 1)]
	return [
		get_parent().to_local(to_global(surface_at(4, upper.get_center().x) + Vector2(0.0, -34.0))),
		get_parent().to_local(to_global(surface_at(5, lower.get_center().x) + Vector2(0.0, -34.0))),
	]


func get_replay_cache_position() -> Vector2:
	if _niche_crests.is_empty():
		return Vector2.INF
	return get_parent().to_local(to_global((_niche_crests[0] as Rect2).get_center() + Vector2(70.0, -37.0)))


func _spawn_authored_population() -> void:
	var route_key := String(course_id)
	if not AUTHORED_POPULATION.has(route_key):
		return
	var room := get_parent()
	var world_population: Node = room.get_parent().get_node_or_null("WorldPopulation") if room.get_parent() != null else null
	for entry in AUTHORED_POPULATION[route_key]:
		var node_name := String(entry["name"])
		if room.has_node(node_name):
			continue
		if world_population != null and world_population.has_method("should_spawn_authored_actor") and not bool(world_population.call("should_spawn_authored_actor", String(room.name), node_name)):
			continue
		var actor := (entry["scene"] as PackedScene).instantiate() as Node2D
		actor.name = node_name
		actor.position = entry["position"]
		if AUTHORED_GALLERIES.has(node_name):
			actor.position = surface_at(AUTHORED_GALLERIES[node_name], actor.position.x) + Vector2(0, -33)
		elif course_id == &"reservoir" and node_name == "UpperSentry":
			actor.position = surface_at(3, actor.position.x) + Vector2(0, -33)
		if node_name == "ChancelFiend":
			var echo := room.get_node("DawnEcho") as Node2D
			actor.position = surface_at(3, echo.position.x + 86) + Vector2(0, -33)
		var properties: Dictionary = entry.get("properties", {})
		for property_name in properties:
			actor.set(StringName(property_name), properties[property_name])
		for group_name in entry.get("groups", []):
			actor.add_to_group(group_name)
		actor.set_meta("authored_streamed_population", true)
		actor.set_meta("streamed_population_kind", "crate" if actor.is_in_group("breakable") else ("neutral" if actor.is_in_group("neutral_creature") else "enemy"))
		room.add_child(actor)
		if world_population != null and world_population.has_method("register_authored_actor"):
			world_population.call("register_authored_actor", String(room.name), actor)


func _add_streamed_generated_actor(actor: Node2D) -> bool:
	var room := get_parent()
	var state_key := "generated:%s" % String(actor.name)
	var world_population: Node = room.get_parent().get_node_or_null("WorldPopulation") if room != null and room.get_parent() != null else null
	if world_population != null and world_population.has_method("should_spawn_authored_actor") and not bool(world_population.call("should_spawn_authored_actor", String(room.name), state_key)):
		actor.free()
		return false
	actor.set_meta("authored_streamed_population", true)
	actor.set_meta("streamed_population_kind", "crate" if actor.is_in_group("breakable") else ("neutral" if actor.is_in_group("neutral_creature") else "enemy"))
	actor.set_meta("streamed_population_key", state_key)
	add_child(actor)
	if world_population != null and world_population.has_method("register_authored_actor"):
		world_population.call("register_authored_actor", String(room.name), actor, state_key)
	return true


func gallery_y(index: int) -> float:
	return _chamber_rect(index + 1).end.y


func ceiling_y() -> float:
	var highest := ground_y
	for index in range(CHAMBER_LAYOUTS[String(course_id)].size()):
		highest = minf(highest, _chamber_rect(index).position.y)
	return highest - 80.0


func _route_xs() -> Array:
	var centers: Array = []
	for index in range(CHAMBER_LAYOUTS[String(course_id)].size()):
		centers.append(_chamber_rect(index).get_center().x)
	return centers


func _chamber_rect(index: int) -> Rect2:
	var data: Array = CHAMBER_LAYOUTS.get(String(course_id), CHAMBER_LAYOUTS["causeway"])[index]
	return Rect2(float(data[0]) * course_width, float(data[2]) - 240.0, (float(data[1]) - float(data[0])) * course_width, 240.0)


func _build_route() -> void:
	for child in get_children():
		if child.name.begins_with("AshSolid_") or child.name.begins_with("AshStep_"):
			remove_child(child)
			child.queue_free()
	_solid_rects.clear()
	_step_rects.clear()
	_track_rects.clear()
	_niche_crests.clear()

	var layout: Array = CHAMBER_LAYOUTS[String(course_id)]
	var openings: Dictionary = {}
	for index in range(layout.size()):
		openings[index] = []
	for index in range(layout.size() - 1):
		var chamber := _chamber_rect(index)
		var next := _chamber_rect(index + 1)
		var shaft_x := (maxf(chamber.position.x, next.position.x) + minf(chamber.end.x, next.end.x)) * 0.5
		var upper_y := minf(chamber.end.y, next.end.y)
		for candidate in range(layout.size()):
			var crossing := _chamber_rect(candidate)
			if crossing.end.y >= upper_y - 1 and crossing.end.y < maxf(chamber.end.y, next.end.y) - 1 and shaft_x + 120 > crossing.position.x and shaft_x - 120 < crossing.end.x:
				(openings[candidate] as Array).append(shaft_x)
	for index in range(layout.size()):
		var chamber := _chamber_rect(index)
		_build_chamber_floor(index, chamber, openings[index])
		_build_chamber_anchors(index, chamber)
	for index in range(layout.size() - 1):
		_build_chamber_shaft(index, _chamber_rect(index), _chamber_rect(index + 1))
	_build_niche(1)
	_build_niche(4)
	_build_return_chute(2)
	_build_return_chute(4)

	if course_id == &"outskirts":
		var final_chamber := _chamber_rect(6)
		_add_solid(Rect2(final_chamber.position.x - 80.0, final_chamber.position.y - 24.0, final_chamber.size.x + 160.0, 12.0))


func _build_chamber_floor(chamber_index: int, chamber: Rect2, raw_openings: Array) -> void:
	var room_openings := raw_openings.duplicate()
	room_openings.sort()
	var cursor := chamber.position.x
	for value in room_openings:
		var opening := float(value)
		var stop := maxf(cursor, opening - 120.0)
		if stop - cursor > 32.0:
			_add_solid(Rect2(cursor, chamber.end.y - DECK_THICKNESS * 0.5, stop - cursor, DECK_THICKNESS))
		cursor = minf(chamber.end.x, opening + 120.0)
	if chamber.end.x - cursor > 32.0:
		_add_solid(Rect2(cursor, chamber.end.y - DECK_THICKNESS * 0.5, chamber.end.x - cursor, DECK_THICKNESS))


func _build_chamber_anchors(chamber_index: int, chamber: Rect2) -> void:
	var gallery := chamber_index - 1
	var spans: Array[Rect2] = []
	var usable_left := chamber.position.x + 65.0
	var usable_width := chamber.size.x - 130.0
	var anchor_width := usable_width / 9.0
	for index in range(9):
		spans.append(Rect2(usable_left + anchor_width * float(index), chamber.end.y - DECK_THICKNESS * 0.5, anchor_width, DECK_THICKNESS))
	_track_rects[gallery] = spans


func _build_chamber_shaft(index: int, chamber: Rect2, next: Rect2) -> void:
	var overlap_left := maxf(chamber.position.x, next.position.x)
	var overlap_right := minf(chamber.end.x, next.end.x)
	var shaft_x := (overlap_left + overlap_right) * 0.5
	var intervals := maxi(2, int(ceil(absf(next.end.y - chamber.end.y) / STEP_RISE)))
	for step in range(1, intervals):
		var y := lerpf(chamber.end.y, next.end.y, float(step) / float(intervals))
		var stagger := -42.0 if (step + index) % 2 == 0 else 42.0
		_add_step(Rect2(shaft_x + stagger - STEP_WIDTH * 0.5, y - STEP_THICKNESS * 0.5, STEP_WIDTH, STEP_THICKNESS))


func _add_ascent(gallery: int, upper_y: float) -> void:
	var lower_y := ground_y if gallery == 0 else gallery_y(gallery - 1)
	var route_x := _route_xs()
	var center_x: float = route_x[gallery + 1]
	var lower_start: float = route_x[gallery]
	var right_end := center_x > lower_start
	for step_index in range(STEP_COUNT):
		# The last tread sits within one ordinary jump of the destination deck.
		var y := lower_y - STEP_RISE * float(step_index + 1)
		var stagger := 20.0 if step_index % 2 == 1 else -20.0
		var x := center_x + (stagger if right_end else -stagger)
		_add_step(Rect2(x - STEP_WIDTH * 0.5, y - STEP_THICKNESS * 0.5, STEP_WIDTH, STEP_THICKNESS))
	# Last tread and gallery are within a normal jump, without Dash or Double Jump.
	assert(upper_y - (lower_y - STEP_RISE * STEP_COUNT) <= 15.0)


func _build_track(gallery: int, nominal_y: float) -> void:
	var route_x := _route_xs()
	var route_index := gallery + 1
	var start_x: float = route_x[route_index]
	var finish_x: float = route_x[route_index + 1]
	var direction := 1.0 if finish_x > start_x else -1.0
	var spans: Array[Rect2] = []
	var segment_count := 9
	var gap := 50.0 + float((_variant_index() + gallery + 2) % 9)
	var extent := (absf(finish_x - start_x) - gap * float(segment_count - 1)) / float(segment_count)
	extent = maxf(48.0, extent)
	var rises := _rise_motif(gallery)
	var cursor := start_x
	for segment in range(segment_count):
		var rise: float = float(rises[segment % rises.size()]) * 0.62
		var next_x := cursor + direction * extent
		var rect := Rect2(minf(cursor, next_x), nominal_y + rise - 9.0, extent, DECK_THICKNESS)
		_add_solid(rect)
		spans.append(rect)
		cursor = next_x + direction * gap
	_track_rects[gallery] = spans


func _build_recovery_stairs() -> void:
	var spans: Array = _track_rects[-1]
	for index in range(1, spans.size()):
		var previous: Rect2 = spans[index - 1]
		var next: Rect2 = spans[index]
		var gap_center := (previous.end.x + next.position.x) * 0.5
		if next.position.x - previous.end.x < 32.0:
			continue
		for rung in range(1, 4):
			var rung_y := ground_y + 180.0 - float(rung) * 50.0
			_add_step(Rect2(gap_center - 43.0, rung_y - 5.0, 86.0, 10.0))


func _build_niche(gallery: int) -> void:
	var spans: Array = _track_rects[gallery]
	var anchor: Rect2 = spans[spans.size() / 2]
	var footing := Vector2(anchor.get_center().x, anchor.position.y + 9.0)
	var x := footing.x
	var y := footing.y
	var side := -1.0 if x > course_width * 0.54 else 1.0
	var crest_rise := 166.0
	var rung_rise := 42.0
	for rung in range(1, 5):
		var rung_x := x + side * float(rung) * 68.0
		_add_step(Rect2(rung_x - 56.0, y - float(rung) * rung_rise - 5.0, 112.0, 10.0))
	# A true dead end: the reward chamber has one approach and no descent that
	# silently reconnects it to the following gallery.
	var crest_left := x + side * 630.0 if side < 0.0 else x + side * 270.0
	var crest := Rect2(crest_left, y - crest_rise - 8.0, 360.0, 16.0)
	_add_solid(crest, true)
	_niche_crests.append(crest)


func _build_return_chute(upper_gallery: int) -> void:
	var spans: Array = _track_rects[upper_gallery]
	var chute_span: Rect2 = spans[spans.size() / 2]
	var x := chute_span.get_center().x
	# A narrow visible recess at a broken span drops into the previous route.
	# Rungs are 92 px apart: easy to descend, not an unintended climb bypass.
	var upper := gallery_y(upper_gallery)
	for rung in range(1, 3):
		_add_step(Rect2(x - 56.0, upper + float(rung) * 92.0 - 5.0, 112.0, 10.0))


func surface_at(gallery: int, x: float, margin: float = 125.0) -> Vector2:
	var chamber := _chamber_rect(gallery + 1)
	var best_distance := INF
	var best := Vector2.INF
	for span_value in _solid_rects:
		var span: Rect2 = span_value
		if absf(span.get_center().y - chamber.end.y) > 1 or span.size.x < margin * 2 + 24:
			continue
		if span.position.x < chamber.position.x - 1 or span.end.x > chamber.end.x + 1:
			continue
		var snapped_x := clampf(x, span.position.x + margin, span.end.x - margin)
		var distance := absf(snapped_x - x)
		if distance < best_distance:
			best_distance = distance
			best = Vector2(snapped_x, span.get_center().y)
	assert(best.is_finite(), "No Ash surface: %s/%d" % [course_id, gallery])
	return best


func _add_solid(rect: Rect2, one_way: bool = false) -> void:
	_solid_rects.append(rect)
	_make_body("AshSolid_%02d" % _solid_rects.size(), rect, one_way)


func _add_step(rect: Rect2) -> void:
	_step_rects.append(rect)
	_make_body("AshStep_%02d" % _step_rects.size(), rect, true)


func _make_body(body_name: String, rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.name = body_name
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	add_child(body)


func _variant_index() -> int:
	match course_id:
		&"forge": return 1
		&"barracks": return 2
		&"reservoir": return 3
		&"chapel": return 4
		&"outskirts": return 5
		_: return 0


func _build_identity_landmarks() -> void:
	var old := get_node_or_null("AshIdentity")
	if old != null:
		remove_child(old)
		old.queue_free()
	var identity := Node2D.new()
	identity.name = "AshIdentity"
	identity.z_index = -2
	identity.set_meta("course_id", String(course_id))
	identity.set_meta("identity_name", IDENTITY_NAMES.get(course_id, "ASHEN ROAD"))
	add_child(identity)
	_add_identity_title(identity)
	match course_id:
		&"forge":
			_build_forge_identity(identity)
		&"barracks":
			_build_barracks_identity(identity)
		&"reservoir":
			_build_reservoir_identity(identity)
		&"chapel":
			_build_chapel_identity(identity)
		&"outskirts":
			_build_outskirts_identity(identity)
		_:
			_build_causeway_identity(identity)


func _add_identity_title(identity: Node2D) -> void:
	var title := Label.new()
	title.name = "RouteIdentity"
	title.position = Vector2(legacy_width + 70.0, ceiling_y() + 48.0)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(_palette()[3], 0.72))
	title.text = String(IDENTITY_NAMES.get(course_id, "ASHEN ROAD"))
	identity.add_child(title)


func _identity_anchor(identity: Node2D, anchor_name: String, kind: String) -> Node2D:
	var anchor := Node2D.new()
	anchor.name = anchor_name
	anchor.set_meta("landmark_kind", kind)
	identity.add_child(anchor)
	return anchor


func _identity_polygon(parent: Node, node_name: String, points: PackedVector2Array, color: Color, z: int = -1) -> Polygon2D:
	var shape := Polygon2D.new()
	shape.name = node_name
	shape.polygon = points
	shape.color = color
	shape.z_index = z
	parent.add_child(shape)
	return shape


func _identity_line(parent: Node, node_name: String, points: PackedVector2Array, color: Color, width: float = 4.0) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	parent.add_child(line)
	return line


func _circle_points(center: Vector2, radius: float, count: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _build_causeway_identity(identity: Node2D) -> void:
	var ruins := _identity_anchor(identity, "CollapsedViaduct", "broken_bridge")
	for index in range(5):
		var x := 1420.0 + float(index) * 610.0
		var y := gallery_y(index % 3) - 24.0
		_identity_polygon(ruins, "BrokenArch%d" % index, PackedVector2Array([
			Vector2(x - 125, y), Vector2(x - 105, y - 190), Vector2(x - 48, y - 245),
			Vector2(x + 34, y - 222), Vector2(x + 102, y - 150), Vector2(x + 125, y),
			Vector2(x + 66, y), Vector2(x + 48, y - 126), Vector2(x - 42, y - 142), Vector2(x - 65, y),
		]), Color("2f1b1e"))
	var chains := _identity_anchor(identity, "WatchChains", "hanging_chains")
	for index in range(7):
		var x := 1280.0 + float(index) * 430.0
		var bottom := gallery_y((index + 1) % GALLERY_COUNT) - 70.0
		_identity_line(chains, "Chain%d" % index, PackedVector2Array([
			Vector2(x, ceiling_y() + 28.0), Vector2(x + 16.0, (ceiling_y() + bottom) * 0.5), Vector2(x - 7.0, bottom),
		]), Color(0.60, 0.30, 0.20, 0.48), 3.0)
	var beacons := _identity_anchor(identity, "RefugeBeacons", "safe_route_beacons")
	for index in range(3):
		var point := surface_at(index * 2, 1850.0 + float(index) * 760.0)
		_identity_polygon(beacons, "Beacon%d" % index, PackedVector2Array([
			point + Vector2(-18, -8), point + Vector2(-11, -65), point + Vector2(0, -91),
			point + Vector2(13, -61), point + Vector2(18, -8),
		]), Color(0.95, 0.39, 0.13, 0.60), 1)


func _build_forge_identity(identity: Node2D) -> void:
	var furnaces := _identity_anchor(identity, "SixFurnaces", "heat_lane")
	for gallery in range(GALLERY_COUNT):
		var x := 1470.0 + float((gallery * 613) % 2180)
		var y := surface_at(gallery, x).y
		_identity_polygon(furnaces, "KilnHousing%d" % gallery, PackedVector2Array([
			Vector2(x - 105, y - 8), Vector2(x - 105, y - 152), Vector2(x - 66, y - 205),
			Vector2(x + 66, y - 205), Vector2(x + 105, y - 152), Vector2(x + 105, y - 8),
		]), Color("4b2724"))
		_identity_polygon(furnaces, "KilnMouth%d" % gallery, PackedVector2Array([
			Vector2(x - 46, y - 9), Vector2(x - 37, y - 93), Vector2(x, y - 123),
			Vector2(x + 37, y - 93), Vector2(x + 46, y - 9),
		]), Color(0.95, 0.29, 0.08, 0.58), 1)
	var conduits := _identity_anchor(identity, "MoltenConduits", "heat_network")
	for gallery in range(GALLERY_COUNT):
		var y := gallery_y(gallery) - 112.0
		_identity_line(conduits, "Conduit%d" % gallery, PackedVector2Array([
			Vector2(legacy_width + 70, y), Vector2(2120, y - 18), Vector2(2920, y + 22), Vector2(course_width - 160, y),
		]), Color(0.94, 0.34, 0.11, 0.50), 7.0)


func _build_barracks_identity(identity: Node2D) -> void:
	var yard := _identity_anchor(identity, "TrainingYards", "combat_drill")
	for gallery in range(GALLERY_COUNT):
		var x := 1510.0 + float((gallery * 557) % 2250)
		var y := surface_at(gallery, x).y
		_identity_line(yard, "SpearRack%d" % gallery, PackedVector2Array([
			Vector2(x - 65, y - 8), Vector2(x - 62, y - 112), Vector2(x + 68, y - 112), Vector2(x + 65, y - 8),
		]), Color(0.76, 0.42, 0.24, 0.67), 5.0)
		for spear in range(4):
			var sx := x - 44.0 + float(spear) * 29.0
			_identity_line(yard, "Spear%d_%d" % [gallery, spear], PackedVector2Array([Vector2(sx, y - 18), Vector2(sx + 12, y - 146)]), Color(0.86, 0.61, 0.34, 0.61), 3.0)
	var standards := _identity_anchor(identity, "PatrolStandards", "guard_patrol")
	for index in range(8):
		var gallery := index % GALLERY_COUNT
		var x := 1260.0 + float(index) * 365.0
		var y := surface_at(gallery, x).y
		_identity_line(standards, "StandardPole%d" % index, PackedVector2Array([Vector2(x, y), Vector2(x, y - 180)]), Color(0.79, 0.49, 0.30, 0.54), 3.0)
		_identity_polygon(standards, "Standard%d" % index, PackedVector2Array([Vector2(x, y - 178), Vector2(x + 70, y - 157), Vector2(x + 50, y - 112), Vector2(x, y - 126)]), Color(0.50, 0.13, 0.12, 0.69), 1)


func _build_reservoir_identity(identity: Node2D) -> void:
	var tanks := _identity_anchor(identity, "PressureTanks", "pressure_water")
	for gallery in range(GALLERY_COUNT):
		var x := 1480.0 + float((gallery * 677) % 2310)
		var y := surface_at(gallery, x).y
		_identity_polygon(tanks, "Tank%d" % gallery, _circle_points(Vector2(x, y - 106), 82.0, 18), Color(0.20, 0.35, 0.37, 0.76))
		_identity_line(tanks, "TankBand%d" % gallery, PackedVector2Array([Vector2(x - 74, y - 106), Vector2(x + 74, y - 106)]), Color(0.52, 0.72, 0.70, 0.55), 7.0)
	var channels := _identity_anchor(identity, "CoolantChannels", "timed_pressure_surge")
	for gallery in range(GALLERY_COUNT):
		var y := gallery_y(gallery) - 68.0
		_identity_line(channels, "PressurePipe%d" % gallery, PackedVector2Array([
			Vector2(legacy_width + 45, y), Vector2(1900, y), Vector2(1900, y - 42),
			Vector2(3260, y - 42), Vector2(3260, y), Vector2(course_width - 170, y),
		]), Color(0.38, 0.68, 0.70, 0.48), 8.0)


func _build_chapel_identity(identity: Node2D) -> void:
	var nave := _identity_anchor(identity, "BellNave", "bell_reliquary")
	for gallery in range(GALLERY_COUNT):
		var x := 1420.0 + float((gallery * 701) % 2400)
		var y := surface_at(gallery, x).y
		_identity_polygon(nave, "RoseWindow%d" % gallery, _circle_points(Vector2(x, y - 148), 64.0, 12), Color(0.62, 0.34, 0.36, 0.42))
		_identity_line(nave, "WindowCross%d" % gallery, PackedVector2Array([Vector2(x - 55, y - 148), Vector2(x + 55, y - 148), Vector2(x, y - 203), Vector2(x, y - 93)]), Color(0.87, 0.68, 0.48, 0.52), 4.0)
	var bells := _identity_anchor(identity, "ProcessionBells", "bell_sequence")
	for index in range(5):
		var gallery := index + 1
		var x := 1780.0 + float(index) * 455.0
		var y := gallery_y(gallery) - 42.0
		_identity_line(bells, "BellRope%d" % index, PackedVector2Array([Vector2(x, ceiling_y() + 15), Vector2(x, y - 118)]), Color(0.76, 0.61, 0.45, 0.42), 3.0)
		_identity_polygon(bells, "Bell%d" % index, PackedVector2Array([Vector2(x - 46, y - 115), Vector2(x - 34, y - 55), Vector2(x + 34, y - 55), Vector2(x + 46, y - 115), Vector2(x, y - 146)]), Color(0.71, 0.47, 0.34, 0.63), 1)


func _build_outskirts_identity(identity: Node2D) -> void:
	var siege := _identity_anchor(identity, "SiegeLine", "gate_siege")
	for gallery in range(GALLERY_COUNT):
		var x := 1390.0 + float((gallery * 641) % 2380)
		var y := surface_at(gallery, x).y
		_identity_polygon(siege, "Barricade%d" % gallery, PackedVector2Array([
			Vector2(x - 120, y - 7), Vector2(x - 78, y - 76), Vector2(x - 42, y - 25),
			Vector2(x, y - 92), Vector2(x + 43, y - 27), Vector2(x + 82, y - 74), Vector2(x + 121, y - 7),
		]), Color(0.41, 0.25, 0.20, 0.88), 1)
	var towers := _identity_anchor(identity, "WatchTowers", "fortified_gate")
	for index in range(4):
		var gallery := mini(index + 2, 5)
		var x := 1880.0 + float(index) * 650.0
		var y := surface_at(gallery, x).y
		_identity_polygon(towers, "WatchTower%d" % index, PackedVector2Array([
			Vector2(x - 78, y), Vector2(x - 69, y - 230), Vector2(x - 92, y - 230),
			Vector2(x - 92, y - 270), Vector2(x + 92, y - 270), Vector2(x + 92, y - 230),
			Vector2(x + 69, y - 230), Vector2(x + 78, y),
		]), Color(0.30, 0.19, 0.18, 0.75))


func _width_motif(gallery: int) -> Array:
	var motif: Array
	match course_id:
		&"forge": motif = [420, 275, 455, 300, 390, 265, 475, 320]
		&"barracks": motif = [350, 470, 285, 410, 330, 450, 295, 385]
		&"reservoir": motif = [465, 275, 390, 335, 450, 285, 410, 310]
		&"chapel": motif = [300, 470, 350, 430, 275, 460, 325, 400]
		&"outskirts": motif = [430, 285, 455, 315, 390, 270, 470, 340]
		_: motif = [310, 425, 270, 480, 335, 390, 285, 440]
	var rotated: Array = []
	for index in range(motif.size()):
		rotated.append(motif[(index + gallery * 2 + _variant_index()) % motif.size()])
	return rotated


func _rise_motif(gallery: int) -> Array:
	var motif: Array
	match course_id:
		&"forge": motif = [0, -29, -8, 24, -16, -42, -11, 13]
		&"barracks": motif = [0, 22, -16, -43, -10, 17, -27, 7]
		&"reservoir": motif = [0, -18, -45, -14, 19, -23, 8, -33]
		&"chapel": motif = [0, -31, -7, 19, -24, -46, -12, 11]
		&"outskirts": motif = [0, 16, -21, -44, -13, 20, -26, 6]
		_: motif = [0, -24, -42, -12, 14, -20, 8, -34]
	var rotated: Array = []
	for index in range(motif.size()):
		rotated.append(motif[(index + gallery + _variant_index()) % motif.size()])
	return rotated


func _place_feature(node_name: String, gallery: int, clearance: float = 33.0) -> void:
	var node := get_parent().get_node_or_null(node_name) as Node2D
	if node == null:
		return
	if node.has_meta("authored_streamed_population"):
		return
	var footing := surface_at(gallery, node.position.x)
	node.position = footing + Vector2(0.0, -clearance)


func _place_many(names: Array[String], gallery: int, clearance: float = 33.0) -> void:
	for node_name in names:
		_place_feature(node_name, gallery, clearance)


func _snap_room_features() -> void:
	# Entrance markers and all existing checkpoint lamps deliberately retain
	# their old local coordinates for saves and room-to-room arrival contracts.
	match course_id:
		&"causeway":
			_place_many(["EmberspineReturn", "EmberspineDoor", "ForgeReturn", "ForgeDoor", "FinalWatchSentry"], 5)
			_place_many(["BarracksReturn", "BarracksLoopDoor", "OverlookSentry"], 2)
			_place_feature("CinderShelfFiend", 0)
			_place_feature("HighSpineFiend", 3)
			_place_feature("SecondVent", 1, 51.0)
			if not _niche_crests.is_empty():
				var cache := get_parent().get_node_or_null("UpperCache") as Node2D
				if cache != null:
					cache.position = _niche_crests[0].get_center() + Vector2(0.0, -33.0)
		&"forge":
			_place_many(["BarracksReturn", "BarracksDoor", "LastFurnaceSentry"], 5)
			_place_many(["ReservoirReturn", "ReservoirLoopDoor", "CoolingFan", "CrossDuctSentry"], 2)
			_place_many(["ForgeCache", "FanGalleryFiend"], 3)
			_place_feature("SmelterFiend", 0)
			_place_feature("ForgeVent", 0, 51.0)
		&"barracks":
			_place_many(["BarracksLoopEntry", "CausewayLoopDoor", "GallerySentry"], 2)
			_place_many(["ArenaReturn", "ArenaDoor", "LastWatchSentry"], 5)
			_place_many(["BarracksCache", "SparringFiend"], 3)
			_place_feature("RampartFiend", 0)
			_place_feature("BarracksVent", 2, 51.0)
		&"reservoir":
			_place_many(["ForgeLoopEntry", "ForgeLoopDoor", "UpperValve", "PressureSentry"], 2)
			_place_many(["CoreCache", "UpperSentry", "SpillwayFiend"], 3)
			_place_feature("OverflowFiend", 0)
			_place_feature("UpperVent", 2, 51.0)
			_place_feature("CrownSentry", 4)
			var spur := get_parent().get_node_or_null("ChapelSpur") as Node2D
			if spur != null:
				var foundation := surface_at(5, spur.position.x)
				spur.position = foundation + Vector2(0.0, -70.0)
				for node_name in ["ChapelReturn", "ChapelDoor"]:
					var feature := get_parent().get_node_or_null(node_name) as Node2D
					if feature != null:
						feature.position = spur.position + Vector2(-30 if node_name == "ChapelReturn" else 30, -33)
		&"chapel":
			_place_many(["ThroneReturn", "ThroneDoor", "FarBell", "ChapelCache", "ReliquaryGuard"], 5)
			_place_many(["HighBell", "BelfrySentry"], 2)
			_place_many(["LowBell", "MemoryReliquary", "DawnEcho", "ChoirSentry", "ChancelFiend"], 3)
			_place_feature("NaveGalleryFiend", 0)
			_place_feature("LowVent", 1, 51.0)
			_place_feature("FarVent", 3, 51.0)
		&"outskirts":
			_place_many(["GateReturn", "GateDoor", "GateWatchSentry"], 5)
			_place_feature("BrokenRoadFiend", 0)
			_place_feature("RampartSentry", 2)
			_place_feature("HighRoadFiend", 3)
			# Keep the monumental gate art attached to the new high approach.
			for node_name in ["GateGlow", "GateLeftTower", "GateRightTower", "GateLintel", "GateBanner"]:
				var visual := get_parent().get_node_or_null(node_name) as Node2D
				if visual != null:
					visual.position.y = gallery_y(5) - 370.0
			var sign := get_parent().get_node_or_null("GateSign") as Node2D
			if sign != null:
				sign.position.y = gallery_y(5) - 140.0


func _populate_route() -> void:
	for gallery in range(GALLERY_COUNT):
		var spans: Array = _track_rects[gallery]
		for slot in range(2):
			var foe_name := "AshRouteFoe%d_%d" % [gallery, slot]
			if has_node(foe_name):
				continue
			var span: Rect2 = spans[2 if slot == 0 else mini(5, spans.size() - 2)]
			var enemy_scene: PackedScene = _enemy_scene_for(gallery, slot)
			var foe := enemy_scene.instantiate() as Node2D
			foe.name = foe_name
			foe.position = surface_at(gallery, span.get_center().x) + Vector2(0.0, -33.0)
			foe.set_meta("encounter_identity", String(course_id))
			_add_streamed_generated_actor(foe)
		var route_crate_name := "AshRouteCrate%d" % gallery
		if has_node(route_crate_name):
			continue
		var crate_span: Rect2 = spans[mini(4, spans.size() - 2)]
		var crate := CRATE_SCENE.instantiate() as Node2D
		crate.name = route_crate_name
		crate.position = surface_at(gallery, crate_span.get_center().x, 40) + Vector2(0.0, -33.0)
		crate.set("empty_drop_chance", _crate_empty_chance())
		_add_streamed_generated_actor(crate)
	for index in range(_niche_crests.size()):
		var crest: Rect2 = _niche_crests[index]
		var fauna_name := "AshNicheGrazer%d" % index
		if not has_node(fauna_name):
			var fauna := FAUNA_SCENE.instantiate() as Node2D
			fauna.name = fauna_name
			fauna.position = crest.get_center() + Vector2(-62.0, -33.0)
			fauna.set("zone_id", "ashen_bastion")
			fauna.set("creature_name", _fauna_names()[index])
			_add_streamed_generated_actor(fauna)
		var niche_crate_name := "AshNicheCacheCrate%d" % index
		if not has_node(niche_crate_name):
			var crate := CRATE_SCENE.instantiate() as Node2D
			crate.name = niche_crate_name
			crate.position = crest.get_center() + Vector2(70.0, -33.0)
			crate.set("empty_drop_chance", 0.0)
			_add_streamed_generated_actor(crate)


func _enemy_scene_for(gallery: int, slot: int) -> PackedScene:
	match course_id:
		&"forge":
			return SENTRY_SCENE if gallery in [2, 5] and slot == 1 else FIEND_SCENE
		&"barracks":
			return FIEND_SCENE if gallery in [1, 4] and slot == 1 else SENTRY_SCENE
		&"reservoir":
			return SENTRY_SCENE if slot == gallery % 2 else FIEND_SCENE
		&"chapel":
			return FIEND_SCENE if gallery in [0, 3, 5] and slot == 1 else SENTRY_SCENE
		&"outskirts":
			return FIEND_SCENE if gallery < 5 and slot == 0 else SENTRY_SCENE
		_:
			return SENTRY_SCENE if (gallery + slot) % 3 == 0 else FIEND_SCENE


func _crate_empty_chance() -> float:
	match course_id:
		&"forge": return 0.30
		&"barracks": return 0.18
		&"reservoir": return 0.26
		&"chapel": return 0.34
		&"outskirts": return 0.14
		_: return 0.22


func _fauna_names() -> PackedStringArray:
	match course_id:
		&"forge": return PackedStringArray(["Furnace Moth", "Cinder Beetle"])
		&"barracks": return PackedStringArray(["Banner Moth", "Yard Grazer"])
		&"reservoir": return PackedStringArray(["Steam Skipper", "Slag Salamander"])
		&"chapel": return PackedStringArray(["Candle Moth", "Bellwing"])
		&"outskirts": return PackedStringArray(["Watch Moth", "Scoria Grazer"])
		_: return PackedStringArray(["Road Ember", "Ash Grazer"])


func _populate_identity_gameplay() -> void:
	_spawn_identity_cache()
	_spawn_guarded_niche_ambush()
	match course_id:
		&"forge":
			_spawn_forge_heat_lanes()
		&"barracks":
			_spawn_drill_targets()
		&"reservoir":
			_spawn_pressure_surges()
		&"outskirts":
			_spawn_siege_supplies()


func _populate_streamed_identity_props() -> void:
	if course_id == &"barracks":
		_spawn_drill_targets()
	elif course_id == &"outskirts":
		_spawn_siege_supplies()


func _spawn_guarded_niche_ambush() -> void:
	var crest: Rect2 = _niche_crests[1]
	var encounter := LOCAL_ENCOUNTER_SCENE.instantiate() as Area2D
	encounter.name = "GuardedNicheAmbush"
	encounter.position = crest.get_center()
	encounter.set("encounter_id", "ash_%s_guarded_niche" % String(course_id))
	encounter.set("zone_id", "ashen_bastion")
	if FIELD_OPERATIONS.PROFILES.has(String(course_id)):
		encounter.set("completion_event_id", "ash_%s_guarded_niche_cleared" % String(course_id))
		encounter.set("encounter_title", "UPPER SUPPLY GUARDIANS")
	encounter.get("enemy_scenes").append(_enemy_scene_for(4, 0))
	encounter.get("enemy_scenes").append(_enemy_scene_for(4, 1))
	encounter.get("spawn_offsets").append(Vector2(-112.0, -33.0))
	encounter.get("spawn_offsets").append(Vector2(112.0, -33.0))
	add_child(encounter)


func _spawn_identity_cache() -> void:
	var rewards := {
		&"causeway": ["March Survivor Cache", "iron_fragment", 22],
		&"forge": ["Furnace Keeper Cache", "ember_arrow", 26],
		&"barracks": ["Quartermaster Cache", "healing_herb", 30],
		&"reservoir": ["Pressure Engineer Cache", "ether_dust", 34],
		&"chapel": ["Votive Reliquary", "ether_dust", 38],
		&"outskirts": ["Scoria Watch Cache", "iron_fragment", 42],
	}
	var reward: Array = rewards.get(course_id, rewards[&"causeway"])
	var crest: Rect2 = _niche_crests[1]
	var cache := CACHE_SCENE.instantiate() as Node2D
	cache.name = "IdentityRewardCache"
	cache.position = crest.get_center() + Vector2(0.0, -37.0)
	cache.set("cache_id", "ash_%s_identity_cache" % String(course_id))
	cache.set("cache_name", String(reward[0]))
	cache.set("reward_item_id", String(reward[1]))
	cache.set("gold_reward", int(reward[2]))
	cache.set_meta("identity_course", String(course_id))
	if FIELD_OPERATIONS.PROFILES.has(String(course_id)):
		cache.set("required_event_ids", PackedStringArray(["ash_%s_field_complete" % String(course_id), "ash_%s_guarded_niche_cleared" % String(course_id)]))
	add_child(cache)


func _spawn_forge_heat_lanes() -> void:
	var placements := [[0, 3], [1, 6], [2, 4], [3, 7], [4, 3], [5, 6]]
	for index in range(placements.size()):
		var gallery: int = int(placements[index][0])
		var spans: Array = _track_rects[gallery]
		var span: Rect2 = spans[mini(int(placements[index][1]), spans.size() - 2)]
		var vent := HEAT_VENT_SCENE.instantiate() as Node2D
		vent.name = "ForgeHeatLane%d" % index
		vent.position = span.get_center() + Vector2(0.0, -51.0)
		vent.set("initial_offset", float(index) * 0.31)
		vent.set("disabled_by_shortcut_id", "ash_forge_fan")
		add_child(vent)


func _spawn_drill_targets() -> void:
	for index in range(4):
		var state := get_node_or_null("/root/GameState")
		if state != null and bool(state.unlocked_shortcuts.get("ash_barracks_drill_%d" % index, false)):
			continue
		var target_name := "DrillTarget%d" % index
		if has_node(target_name):
			continue
		var gallery := index + 1
		var target := CRATE_SCENE.instantiate() as Node2D
		target.name = target_name
		target.position = FIELD_OPERATIONS.supported_floor(self, gallery, float(index % 2) * 130.0)
		target.set("empty_drop_chance", 0.62)
		target.set_meta("combat_prop", "training_target")
		target.connect("destroyed", _on_drill_destroyed.bind(index))
		var label := Label.new()
		label.position = Vector2(-85, -60)
		label.size = Vector2(170, 25)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = "INSPECTION TARGET %d/4" % (index + 1)
		label.add_theme_font_size_override("font_size", 10)
		target.add_child(label)
		_add_streamed_generated_actor(target)


func _on_drill_destroyed(index: int) -> void:
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.unlock_shortcut("ash_barracks_drill_%d" % index)


func _spawn_pressure_surges() -> void:
	# Keep pressure lanes between encounters and supply crates so their warning
	# can be read instead of being hidden beneath an enemy or interactable.
	var placements := [[0, 3], [1, 6], [3, 3], [4, 6]]
	for index in range(placements.size()):
		var gallery: int = int(placements[index][0])
		var spans: Array = _track_rects[gallery]
		var span: Rect2 = spans[mini(int(placements[index][1]), spans.size() - 2)]
		var surge := PRESSURE_SURGE_SCENE.instantiate() as Node2D
		surge.name = "PressureSurge%d" % index
		surge.position = span.get_center() + Vector2(0.0, -18.0)
		surge.scale.x = clampf(span.size.x / 470.0, 0.62, 1.0)
		surge.set("zone_id", "ashen_bastion")
		surge.set("disabled_by_shortcut_id", "ash_reservoir_lower" if index < 2 else "ash_reservoir_upper")
		add_child(surge)


func _spawn_siege_supplies() -> void:
	for index in range(5):
		var supply_name := "SiegeSupply%d" % index
		if has_node(supply_name):
			continue
		var gallery := index
		var spans: Array = _track_rects[gallery]
		var span: Rect2 = spans[mini(6, spans.size() - 2)]
		var supply := CRATE_SCENE.instantiate() as Node2D
		supply.name = supply_name
		supply.position = surface_at(gallery, span.get_center().x, 40) + Vector2(0.0, -33.0)
		supply.set("empty_drop_chance", 0.42)
		supply.set_meta("combat_prop", "siege_supply")
		_add_streamed_generated_actor(supply)


func _palette() -> Array[Color]:
	match course_id:
		&"forge": return [Color("170d12"), Color("382027"), Color("a94c2b"), Color("e0803c")]
		&"barracks": return [Color("170d11"), Color("392023"), Color("ab5438"), Color("d99158")]
		&"reservoir": return [Color("101519"), Color("27343a"), Color("5a8791"), Color("a7c6bd")]
		&"chapel": return [Color("161017"), Color("392b35"), Color("a0645b"), Color("dbc096")]
		&"outskirts": return [Color("1d1011"), Color("47302b"), Color("a46043"), Color("e9a76a")]
		_: return [Color("1a0d11"), Color("422324"), Color("b65a32"), Color("e9a068")]


func _chamber_silhouette(chamber: Rect2, index: int) -> PackedVector2Array:
	var left := chamber.position.x
	var right := chamber.end.x
	var top := chamber.position.y
	var bottom := chamber.end.y
	return PackedVector2Array([
		Vector2(left, bottom), Vector2(left - 18.0, bottom - 58.0 - float(index % 2) * 26.0),
		Vector2(left + 12.0, top + 74.0), Vector2(left + chamber.size.x * 0.18, top + 18.0 + float((index * 23) % 42)),
		Vector2(left + chamber.size.x * 0.42, top + 4.0 + float((index * 17) % 37)),
		Vector2(left + chamber.size.x * 0.66, top + 31.0 + float((index * 29) % 34)),
		Vector2(right - 65.0, top + 12.0 + float((index * 11) % 51)), Vector2(right + 18.0, bottom - 77.0),
		Vector2(right, bottom),
	])


func _draw() -> void:
	var palette := _palette()
	var layout: Array = CHAMBER_LAYOUTS[String(course_id)]
	for index in range(layout.size()):
		var chamber := _chamber_rect(index)
		var silhouette := _chamber_silhouette(chamber, index)
		if _preview_only:
			draw_colored_polygon(silhouette, Color(palette[0], 0.94))
			var outline := silhouette.duplicate()
			outline.append(silhouette[0])
			draw_polyline(outline, palette[2], 5.0, true)
			var preview_piers := maxi(2, int(chamber.size.x / 520.0))
			for pier in range(preview_piers):
				var preview_x := chamber.position.x + 110.0 + float(pier) * (chamber.size.x - 220.0) / float(maxi(1, preview_piers - 1))
				draw_rect(Rect2(preview_x - 22.0, chamber.position.y + 35.0, 44.0, chamber.size.y - 44.0), Color(palette[1], 0.72))
			draw_rect(Rect2(chamber.position.x, chamber.end.y - 10.0, chamber.size.x, 10.0), palette[2])
		else:
			draw_colored_polygon(silhouette, palette[0])
			# Broad piers make these read as ruins/rooms rather than floating
			# platform rows; identity landmarks add the course-specific layer.
			var pier_count := maxi(2, int(chamber.size.x / 520.0))
			for pier in range(pier_count):
				var x := chamber.position.x + 110.0 + float(pier) * (chamber.size.x - 220.0) / float(maxi(1, pier_count - 1))
				draw_rect(Rect2(x - 22.0, chamber.position.y + 35.0, 44.0, chamber.size.y - 44.0), palette[1].darkened(0.24))
		if index < layout.size() - 1:
			var next := _chamber_rect(index + 1)
			var overlap_left := maxf(chamber.position.x, next.position.x)
			var overlap_right := minf(chamber.end.x, next.end.x)
			var shaft_x := (overlap_left + overlap_right) * 0.5
			var top_y := minf(chamber.position.y, next.position.y)
			var bottom_y := maxf(chamber.end.y, next.end.y)
			var shaft_rect := Rect2(shaft_x - 112.0, top_y, 224.0, bottom_y - top_y)
			if _preview_only:
				draw_rect(shaft_rect, Color(palette[0], 0.94))
				draw_rect(shaft_rect, palette[2], false, 5.0)
				var rung_count := maxi(2, int(absf(next.end.y - chamber.end.y) / 58.0))
				for rung in range(1, rung_count):
					var rung_y := lerpf(chamber.end.y, next.end.y, float(rung) / float(rung_count))
					var rung_x := shaft_x + (-42.0 if (rung + index) % 2 == 0 else 42.0)
					draw_rect(Rect2(rung_x - 56.0, rung_y - 5.0, 112.0, 10.0), palette[3])
			else:
				draw_rect(shaft_rect, palette[0])
	if _preview_only:
		return
	for rect in _solid_rects:
		draw_rect(rect, palette[1])
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 4.0), palette[2])
		for rib_index in range(int(rect.position.x + 24.0), int(rect.end.x - 12.0), 126):
			draw_rect(Rect2(float(rib_index), rect.position.y + 6.0, 18.0, 5.0), palette[2].darkened(0.42))
	for rect in _step_rects:
		draw_rect(rect, palette[1].lightened(0.19))
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 3.0), palette[3])
	# Mark each real shaft, including the direction of the next chamber.
	for index in range(layout.size() - 1):
		var chamber := _chamber_rect(index)
		var next := _chamber_rect(index + 1)
		var arrow_x := (maxf(chamber.position.x, next.position.x) + minf(chamber.end.x, next.end.x)) * 0.5
		var arrow_y := minf(chamber.end.y, next.end.y) + 34.0
		var points := PackedVector2Array([
			Vector2(arrow_x, arrow_y),
			Vector2(arrow_x - 13.0, arrow_y + 23.0),
			Vector2(arrow_x + 13.0, arrow_y + 23.0),
		])
		draw_colored_polygon(points, Color(palette[3], 0.55))
