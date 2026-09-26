@tool
extends Node2D

# Authored extensions for the seven ordinary Echo rooms. The original chambers
# remain the puzzle/entry courts; these shelves turn their exits into journeys.
# A basic jump rises about 88 px, so the 220 px tier spacing can only be climbed
# at the alternating four-step staircases. Every gap within a tier is < 70 px.
const SHADE: PackedScene = preload("res://EchoShade.tscn")
const WISP: PackedScene = preload("res://ShaftWisp.tscn")
const BROOD: PackedScene = preload("res://EchoBroodling.tscn")
const NEUTRAL: PackedScene = preload("res://NeutralCreature.tscn")
const CRATE: PackedScene = preload("res://DestructibleCrate.tscn")
const CACHE: PackedScene = preload("res://ResonanceCache.tscn")
const DOOR: PackedScene = preload("res://RoomDoor.tscn")
const PHASE_BRIDGE: PackedScene = preload("res://EchoPhaseBridge.tscn")
const TIDE_PULSE: PackedScene = preload("res://TidePulse.tscn")
const CURRENT_FIELD: PackedScene = preload("res://EchoCurrentField.tscn")
const LOCAL_ENCOUNTER: PackedScene = preload("res://LocalizedEncounter.tscn")
const FIELD_DISCOVERIES := preload("res://EchoRouteDiscoveries.gd")
const FIELD_OPERATIONS := preload("res://EchoFieldOperations.gd")
const FLOOR_PLACEMENT := preload("res://RouteFloorPlacement.gd")
const FIELD_DRESSING := preload("res://RouteFieldDressing.gd")
const HABITAT_DRESSING := preload("res://EchoHabitatDressing.gd")
const CROSSING_DRESSING := preload("res://EchoCrossingDressing.gd")

# Original entry-court enemies and ordinary breakables. Puzzle controls,
# unique items, seals, lamps, caches and doors deliberately stay in the scene.
const AUTHORED_POPULATION := {
	"grotto": [
		{"name": "ForgottenCrate", "scene": CRATE, "position": Vector2(171, 136), "properties": {"min_gold": 12, "max_gold": 22}},
		{"name": "EchoWisp", "scene": WISP, "position": Vector2(604, -20), "properties": {"zone_id": "echo_grotto", "xp_reward": 2, "gold_reward": 11}},
		{"name": "FarWisp", "scene": WISP, "position": Vector2(869, 70), "properties": {"zone_id": "echo_grotto", "xp_reward": 2, "gold_reward": 12}},
		{"name": "FarCrate", "scene": CRATE, "position": Vector2(900, 136), "properties": {"min_gold": 15, "max_gold": 25}},
	],
	"gallery": [
		{"name": "NearShade", "scene": SHADE, "position": Vector2(342, 135)},
		{"name": "FarShade", "scene": SHADE, "position": Vector2(585, 135), "properties": {"max_health": 5, "gold_reward": 18}},
		{"name": "PrismCrate", "scene": CRATE, "position": Vector2(473, 136), "properties": {"min_gold": 15, "max_gold": 26}},
	],
	"archive": [
		{"name": "ArchiveShade", "scene": SHADE, "position": Vector2(435, 135), "properties": {"max_health": 5, "gold_reward": 18}},
		{"name": "FarShade", "scene": SHADE, "position": Vector2(715, 135), "properties": {"max_health": 5, "gold_reward": 20}},
	],
	"tide": [
		{"name": "MidWisp", "scene": WISP, "position": Vector2(300, 319), "properties": {"zone_id": "echo_grotto", "xp_reward": 2, "gold_reward": 12}},
		{"name": "DeepShade", "scene": SHADE, "position": Vector2(325, 637), "properties": {"max_health": 5, "gold_reward": 20}},
	],
	"nest": [
		{"name": "BroodlingOne", "scene": BROOD, "position": Vector2(280, 146)},
		{"name": "BroodlingTwo", "scene": BROOD, "position": Vector2(465, 146), "properties": {"max_health": 4, "gold_reward": 16}},
		{"name": "BroodlingThree", "scene": BROOD, "position": Vector2(610, 146), "properties": {"max_health": 4, "gold_reward": 18}},
	],
	"causeway": [
		{"name": "CausewayWisp", "scene": WISP, "position": Vector2(420, 204), "properties": {"zone_id": "echo_grotto", "xp_reward": 2, "gold_reward": 13}},
		{"name": "FarShade", "scene": SHADE, "position": Vector2(701, 357), "properties": {"gold_reward": 18}},
		{"name": "LeftCrate", "scene": CRATE, "position": Vector2(155, 360)},
	],
	"vault": [
		{"name": "VaultWisp", "scene": WISP, "position": Vector2(360, 153), "properties": {"zone_id": "echo_grotto", "xp_reward": 2, "gold_reward": 14}},
		{"name": "MidShade", "scene": SHADE, "position": Vector2(472, 377), "properties": {"gold_reward": 18}},
		{"name": "FarBroodling", "scene": BROOD, "position": Vector2(690, 377), "properties": {"max_health": 4, "gold_reward": 19, "counts_for_nest": false}},
		{"name": "VaultCrate", "scene": CRATE, "position": Vector2(586, 378)},
	],
}

const RETURN_TARGETS := {
	"grotto": ["echo_grotto", "grotto_entry"],
	"gallery": ["echo_gallery", "gallery_entry"],
	"archive": ["echo_archive", "archive_entry"],
	"tide": ["echo_tide_well", "tide_entry"],
	"nest": ["echo_nest", "nest_entry"],
	"causeway": ["echo_causeway", "causeway_gallery_entry"],
	"vault": ["echo_vault", "vault_entry"],
}

const TIER_RISE := 220.0
const PROFILES := {
	"grotto": {"start": 980.0, "end": 4200.0, "floor": 166.0, "tiers": 9, "shelves": 7, "name": "RESONANCE RIM", "accent": Color(0.21, 0.72, 0.78), "shadow": Color(0.025, 0.08, 0.14), "foe": "wisp"},
	"gallery": {"start": 840.0, "end": 4100.0, "floor": 166.0, "tiers": 9, "shelves": 6, "name": "WHISPERING SPAN", "accent": Color(0.38, 0.62, 0.85), "shadow": Color(0.045, 0.055, 0.14), "foe": "shade"},
	"archive": {"start": 920.0, "end": 4150.0, "floor": 166.0, "tiers": 9, "shelves": 8, "name": "PRISM ASCENT", "accent": Color(0.47, 0.62, 0.93), "shadow": Color(0.045, 0.055, 0.15), "foe": "shade"},
	"tide": {"start": 500.0, "end": 2800.0, "floor": 665.0, "tiers": 13, "shelves": 5, "name": "TIDAL SPIRAL", "accent": Color(0.19, 0.69, 0.75), "shadow": Color(0.02, 0.075, 0.13), "foe": "wisp"},
	"nest": {"start": 920.0, "end": 4200.0, "floor": 166.0, "tiers": 9, "shelves": 7, "name": "BROOD ROOTS", "accent": Color(0.68, 0.38, 0.7), "shadow": Color(0.06, 0.045, 0.12), "foe": "brood"},
	"causeway": {"start": 900.0, "end": 4200.0, "floor": 390.0, "tiers": 9, "shelves": 8, "name": "SHATTERED SPINE", "accent": Color(0.27, 0.72, 0.84), "shadow": Color(0.035, 0.08, 0.15), "foe": "shade"},
	"vault": {"start": 1050.0, "end": 4400.0, "floor": 410.0, "tiers": 9, "shelves": 7, "name": "UNDERTOW TIERS", "accent": Color(0.23, 0.59, 0.78), "shadow": Color(0.025, 0.065, 0.12), "foe": "shade"},
}

# Each array describes consecutive horizontal corridor endpoints from the
# entry floor to the highest exit. Shared endpoints become vertical shafts;
# deliberately uneven X positions create a cave route rather than shelves.
const CORRIDOR_PATHS := {
	"grotto": [980.0, 3260.0, 1320.0, 3820.0, 2180.0, 1050.0, 3460.0, 1760.0, 2980.0, 4200.0],
	"gallery": [840.0, 2940.0, 1260.0, 3650.0, 1960.0, 930.0, 3310.0, 1510.0, 2870.0, 4100.0],
	"archive": [920.0, 3500.0, 1700.0, 4050.0, 2320.0, 1050.0, 3150.0, 1450.0, 2860.0, 4150.0],
	"tide": [500.0, 2300.0, 850.0, 2700.0, 1450.0, 600.0, 2400.0, 1050.0, 2780.0, 1550.0, 700.0, 2200.0, 1250.0, 2800.0],
	"nest": [920.0, 2780.0, 1120.0, 3920.0, 2240.0, 1020.0, 3440.0, 1680.0, 2970.0, 4200.0],
	"causeway": [900.0, 3450.0, 1540.0, 4050.0, 2420.0, 980.0, 3220.0, 1320.0, 2860.0, 4200.0],
	"vault": [1050.0, 3700.0, 1920.0, 4250.0, 2620.0, 1180.0, 3420.0, 1580.0, 3100.0, 4400.0],
}

# [left ratio, right ratio, floor offset]. Every route owns a different graph;
# consecutive rooms overlap only where a reversible shaft is intended.
const CHAMBER_LAYOUTS := {
	"grotto": [[0.00, 0.35, 0.0], [0.27, 0.59, -360.0], [0.50, 0.88, -720.0], [0.72, 1.00, -360.0], [0.59, 0.82, -1080.0], [0.31, 0.66, -1440.0], [0.08, 0.39, -1080.0], [0.00, 0.26, -1800.0], [0.18, 0.62, -2160.0]],
	"gallery": [[0.00, 0.31, 0.0], [0.22, 0.53, -360.0], [0.45, 0.74, -720.0], [0.66, 0.96, -1080.0], [0.74, 1.00, -1440.0], [0.48, 0.80, -1080.0], [0.23, 0.55, -1440.0], [0.04, 0.31, -1800.0], [0.20, 0.67, -2160.0]],
	"archive": [[0.00, 0.40, 0.0], [0.32, 0.68, -360.0], [0.59, 0.93, -720.0], [0.72, 1.00, -1080.0], [0.45, 0.78, -1440.0], [0.18, 0.52, -1080.0], [0.00, 0.28, -1440.0], [0.16, 0.55, -1800.0], [0.46, 0.95, -2160.0]],
	"tide": [[0.00, 0.34, 0.0], [0.25, 0.58, -320.0], [0.49, 0.82, -640.0], [0.70, 1.00, -960.0], [0.58, 0.86, -1280.0], [0.34, 0.66, -960.0], [0.12, 0.43, -1280.0], [0.00, 0.28, -1600.0], [0.17, 0.49, -1920.0], [0.41, 0.72, -1600.0], [0.64, 0.94, -1920.0], [0.72, 1.00, -2240.0], [0.45, 0.82, -2560.0]],
	"nest": [[0.00, 0.34, 0.0], [0.25, 0.52, -360.0], [0.44, 0.73, -720.0], [0.62, 0.93, -360.0], [0.76, 1.00, -1080.0], [0.49, 0.82, -1440.0], [0.22, 0.56, -1080.0], [0.00, 0.31, -1440.0], [0.20, 0.67, -1800.0]],
	"causeway": [[0.00, 0.42, 0.0], [0.34, 0.71, -360.0], [0.62, 1.00, -720.0], [0.74, 0.94, -1080.0], [0.46, 0.78, -720.0], [0.19, 0.52, -1080.0], [0.00, 0.27, -1440.0], [0.18, 0.56, -1800.0], [0.48, 0.98, -1440.0]],
	"vault": [[0.00, 0.37, 0.0], [0.28, 0.65, -360.0], [0.56, 0.90, -720.0], [0.72, 1.00, -1080.0], [0.48, 0.79, -1440.0], [0.20, 0.55, -1800.0], [0.00, 0.31, -1440.0], [0.19, 0.59, -2160.0], [0.51, 0.97, -2520.0]],
}

const ROUTE_HINTS := {
	"grotto": "Wake the crystal choir; every ledge carries its answer.",
	"gallery": "Follow the whisper arches into their hidden listening rooms.",
	"archive": "Reflected light marks the order of the buried records.",
	"tide": "Read the current, then ride its rising breath.",
	"nest": "Brood chambers branch from the silk-bound central climb.",
	"causeway": "Phase crystal turns pale before the bridge disappears.",
	"vault": "Open the sluices between surges; both seals feed the reliquary.",
}

const FAUNA_NAMES := {
	"grotto": "Resonance Moth",
	"gallery": "Whisper Bat",
	"archive": "Glasswing Moth",
	"tide": "Tide Skimmer",
	"nest": "Brood Moth",
	"causeway": "Shard Crawler",
	"vault": "Undertow Newt",
}

const HIDDEN_REWARDS := {
	"grotto": ["Choir's Lost Offering", "resonance_shard", 34],
	"gallery": ["Whisper Listener's Cache", "ether_dust", 36],
	"archive": ["Unindexed Memory", "ether_dust", 40],
	"tide": ["Pearl Below the Current", "healing_herb", 42],
	"nest": ["Abandoned Brood Tribute", "resonance_shard", 44],
	"causeway": ["Phasewalker's Satchel", "iron_fragment", 42],
	"vault": ["Sluice Keeper's Reliquary", "resonance_shard", 48],
}

@export_enum("grotto", "gallery", "archive", "tide", "nest", "causeway", "vault") var route_id: String = "grotto"

var profile: Dictionary
var landing_points: Dictionary = {}
var population_loaded := false


func _ready() -> void:
	profile = PROFILES[route_id]
	if _use_schematic_editor_preview():
		# Game.tscn still gets a lightweight preview, but it must resemble the
		# authored room rather than an empty collision diagram.
		_build_background()
		_build_route_preview()
		_build_landmarks()
		_relocate_room_portals()
		return
	_build_background()
	_build_terrain()
	_build_landmarks()
	_build_identity_features()
	_relocate_room_portals()
	if Engine.is_editor_hint():
		call_deferred("_spawn_authored_population")
	elif not _uses_world_population_streaming():
		# An individual room is still attaching its children during this ready
		# callback; defer sibling manifest nodes by one turn.
		call_deferred("activate_room_population")


func _uses_world_population_streaming() -> bool:
	var room := get_parent()
	return room != null and room.get_parent() != null and room.get_parent().get_node_or_null("RoomActivityDirector") != null


func activate_room_population() -> void:
	if Engine.is_editor_hint():
		return
	_spawn_authored_population()
	_build_life()
	if population_loaded:
		_refresh_streamed_dependencies()
		return
	population_loaded = true
	_refresh_streamed_dependencies()


func _refresh_streamed_dependencies() -> void:
	var nest_veil := get_parent().get_node_or_null("NestVeil")
	if nest_veil != null and nest_veil.has_method("refresh_brood_watch"):
		nest_veil.call("refresh_brood_watch")


func is_population_loaded() -> bool:
	return population_loaded


func get_replay_spawn_points() -> Array[Vector2]:
	# Put awakened opposition on the later traversal folds so a return visit
	# actually asks the player to explore the enlarged room.
	if landing_points.is_empty():
		return []
	var first_tier := mini(8, landing_points.size() - 1)
	var second_tier := mini(10, landing_points.size() - 1)
	var first_points: Array = landing_points[first_tier]
	var second_points: Array = landing_points[second_tier]
	return [
		get_parent().to_local(to_global(_floor_point(first_tier, first_points[first_points.size() / 2].x, 86))),
		get_parent().to_local(to_global(_floor_point(second_tier, second_points[second_points.size() - 2].x, 86))),
	]


func get_replay_cache_position() -> Vector2:
	if landing_points.is_empty():
		return Vector2.INF
	var tier := mini(10, landing_points.size() - 1)
	var alcove := get_node_or_null("Tier%02dSideAlcove" % tier) as Node2D
	if alcove != null:
		return get_parent().to_local(alcove.global_position) + Vector2(0.0, -36.0)
	var points: Array = landing_points[tier]
	return get_parent().to_local(to_global(_floor_point(tier, points[points.size() / 2].x, 36)))


func _spawn_authored_population() -> void:
	if not AUTHORED_POPULATION.has(route_id):
		return
	var room := get_parent()
	var world_population: Node = room.get_parent().get_node_or_null("WorldPopulation") if room.get_parent() != null else null
	for entry in AUTHORED_POPULATION[route_id]:
		var node_name := String(entry["name"])
		if room.has_node(node_name):
			continue
		if world_population != null and world_population.has_method("should_spawn_authored_actor") and not bool(world_population.call("should_spawn_authored_actor", String(room.name), node_name)):
			continue
		var actor := (entry["scene"] as PackedScene).instantiate() as Node2D
		actor.name = node_name
		actor.position = entry["position"]
		var properties: Dictionary = entry.get("properties", {})
		for property_name in properties:
			actor.set(StringName(property_name), properties[property_name])
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


func _path() -> Array:
	var path: Array = []
	for tier in range(int(profile["tiers"])):
		path.append(_chamber_rect(tier).get_center().x)
	return path


func _portal_anchor(tier: int, ratio: float, clearance: float = 33.0) -> Vector2:
	var chamber := _chamber_rect(clampi(tier, 0, int(profile["tiers"]) - 1))
	var desired := lerpf(chamber.position.x + 55.0, chamber.end.x - 55.0, clampf(ratio, 0.0, 1.0))
	if _use_schematic_editor_preview():
		return Vector2(desired, chamber.end.y - clearance)
	return _floor_point(tier, desired, clearance, 125.0)


func _floor_point(tier: int, x: float, clearance: float = 33.0, margin: float = 110.0) -> Vector2:
	return FLOOR_PLACEMENT.on_floor(self, "Chamber%02dFloor" % tier, x, clearance, margin)


func _move_room_node(node_name: String, at: Vector2) -> void:
	var target := get_parent().get_node_or_null(node_name) as Node2D
	if target != null:
		target.position = at


func _place_portal(door_name: String, marker_name: String, tier: int, ratio: float, marker_side: float = 1.0) -> void:
	var door_at := _portal_anchor(tier, ratio)
	_move_room_node(door_name, door_at)
	if not marker_name.is_empty():
		_move_room_node(marker_name, door_at + Vector2(78.0 * marker_side, 0.0))


func _relocate_room_portals() -> void:
	# These scenes were originally small courts. Their doors must follow the
	# authored chamber graph in both the running game and @tool editor preview;
	# otherwise they remain suspended at coordinates from the old 900px room.
	match route_id:
		"grotto":
			_place_portal("ReturnDoor", "GrottoEntry", 0, 0.03)
			_place_portal("HavenDoor", "HavenReturn", 0, 0.25)
			_place_portal("TideDoor", "TideReturn", 2, 0.90, -1.0)
			_place_portal("GalleryDoor", "GalleryReturn", 8, 0.94, -1.0)
			_move_room_node("ShortcutReturn", _portal_anchor(4, 0.18))
			_move_room_node("ArchiveReturn", _portal_anchor(5, 0.82))
			_move_room_node("SanctumReturn", _portal_anchor(7, 0.72))
		"gallery":
			_place_portal("ReturnDoor", "GalleryEntry", 0, 0.03)
			_place_portal("DepthsDoor", "DepthsReturn", 3, 0.90, -1.0)
			_place_portal("ArchiveDoor", "ArchiveReturn", 8, 0.94, -1.0)
			_place_portal("CausewayDoor", "CausewayReturn", 7, 0.12)
			_move_room_node("ShortcutDoor", _portal_anchor(4, 0.86))
		"archive":
			_place_portal("ReturnDoor", "ArchiveEntry", 0, 0.03)
			_move_room_node("ShortcutDoor", _portal_anchor(8, 0.94))
		"tide":
			_place_portal("ReturnDoor", "TideEntry", 0, 0.03)
			_place_portal("CausewayDoor", "CausewayReturn", 3, 0.90, -1.0)
			_place_portal("VaultDoor", "VaultReturn", 6, 0.10)
			_place_portal("NestDoor", "NestReturn", 12, 0.94, -1.0)
			_move_room_node("NestShortcutReturn", _portal_anchor(5, 0.16))
			var upper_lift_at := _portal_anchor(0, 0.20)
			# Keep the activation plate in the middle of the final landing, away
			# from both the Nest gate and the two patrol anchors on its edges.
			var lower_lift_at := _portal_anchor(12, 0.50)
			_move_room_node("UpperLift", upper_lift_at)
			_move_room_node("UpperLiftMarker", upper_lift_at + Vector2(-29.0, 2.0))
			_move_room_node("LowerLift", lower_lift_at)
			_move_room_node("LowerLiftMarker", lower_lift_at + Vector2(-25.0, 0.0))
		"nest":
			_place_portal("ReturnDoor", "NestEntry", 0, 0.03)
			_place_portal("SanctumDoor", "SanctumReturn", 8, 0.94, -1.0)
			_move_room_node("ShortcutDoor", _portal_anchor(4, 0.84))
		"causeway":
			_place_portal("GalleryReturnDoor", "GalleryEntry", 0, 0.03)
			_place_portal("TideLoopDoor", "TideEntry", 8, 0.94, -1.0)
		"vault":
			_place_portal("ReturnDoor", "VaultEntry", 0, 0.03)
			_move_room_node("VaultCache", _portal_anchor(8, 0.70))


func _chamber_rect(tier: int) -> Rect2:
	var data: Array = CHAMBER_LAYOUTS[route_id][tier]
	var start: float = profile["start"]
	var span: float = float(profile["end"]) - start
	var floor_y: float = float(profile["floor"]) + float(data[2])
	return Rect2(Vector2(start + span * float(data[0]), floor_y - 300.0), Vector2(span * (float(data[1]) - float(data[0])), 300.0))


func _use_schematic_editor_preview() -> bool:
	if not Engine.is_editor_hint():
		return false
	var edited_root := get_tree().edited_scene_root
	return edited_root != null and edited_root != get_parent()


func _build_route_preview() -> void:
	var accent: Color = profile["accent"]
	for tier in range(int(profile["tiers"])):
		var room := _chamber_rect(tier)
		var silhouette := _echo_chamber_silhouette(room, tier)
		var closed_silhouette: PackedVector2Array = silhouette.duplicate()
		closed_silhouette.append(silhouette[0])
		_line("TopologyRoom%02d" % tier, closed_silhouette, 5.0, accent.lightened(0.28), -1)
		_line("TopologyFloor%02d" % tier, PackedVector2Array([Vector2(room.position.x + 12.0, room.end.y - 4.0), Vector2(room.end.x - 12.0, room.end.y - 4.0)]), 12.0, accent.darkened(0.08), 0)
		if tier < int(profile["tiers"]) - 1:
			var next := _chamber_rect(tier + 1)
			var x := (maxf(room.position.x, next.position.x) + minf(room.end.x, next.end.x)) * 0.5
			_line("TopologyShaft%02d" % tier, PackedVector2Array([Vector2(x, room.end.y), Vector2(x, next.end.y)]), 5.0, accent.lightened(0.4), -1)
			var rung_count := maxi(2, int(absf(next.end.y - room.end.y) / 58.0))
			for rung in range(1, rung_count):
				var rung_y := lerpf(room.end.y, next.end.y, float(rung) / float(rung_count))
				var rung_x := x + (-58.0 if (rung + tier) % 2 == 0 else 58.0)
				_line("TopologyRung%02d_%02d" % [tier, rung], PackedVector2Array([Vector2(rung_x - 61.0, rung_y), Vector2(rung_x + 61.0, rung_y)]), 10.0, accent.lightened(0.16), 0)
		if tier % 2 == 1:
			var side := -1.0 if room.get_center().x > (float(profile["start"]) + float(profile["end"])) * 0.5 else 1.0
			var root := Vector2(room.get_center().x, room.end.y - 105.0)
			_line("TopologyDeadEnd%02d" % tier, PackedVector2Array([root, root + Vector2(side * 540.0, 0.0)]), 17.0, Color(accent, 0.55), -1)
	_label("TopologyCaption", String(profile["name"]), _chamber_rect(0).position + Vector2(40, 55), 520.0, 28, accent.lightened(0.32))


func _build_background() -> void:
	var start: float = profile["start"]
	var finish: float = profile["end"]
	var floor_y: float = profile["floor"]
	var ceiling_y := 10000.0
	var accent: Color = profile["accent"]
	for tier in range(int(profile["tiers"])):
		var room := _chamber_rect(tier)
		ceiling_y = minf(ceiling_y, room.position.y)
		_poly("ChamberPocket%02d" % tier, _echo_chamber_silhouette(room, tier), profile["shadow"], -9)
		var rib_count := clampi(int(room.size.x / 360.0), 2, 7)
		for index in range(rib_count):
			var x := room.position.x + 75.0 + (room.size.x - 150.0) * float(index) / float(maxi(1, rib_count - 1))
			var sway := float((index * 43 + tier * 67 + route_id.length() * 11) % 69)
			_poly("Rib_%02d_%02d" % [tier, index], PackedVector2Array([Vector2(x - 48.0, room.end.y), Vector2(x - 12.0, room.end.y - 115.0 - sway), Vector2(x + 23.0, room.end.y - 175.0 - sway), Vector2(x + 54.0, room.end.y)]), accent.darkened(0.68), -8)
			_poly("Pendant_%02d_%02d" % [tier, index], PackedVector2Array([Vector2(x - 18.0, room.position.y), Vector2(x + 18.0, room.position.y), Vector2(x, room.position.y + 65.0 + sway * 0.3)]), accent.darkened(0.45), -6)
		_line("ResonanceRibbon%02d" % tier, PackedVector2Array([Vector2(room.position.x + 45.0, room.end.y - 55.0), Vector2(lerpf(room.position.x, room.end.x, 0.38), room.end.y - 122.0), Vector2(lerpf(room.position.x, room.end.x, 0.72), room.end.y - 75.0), Vector2(room.end.x - 45.0, room.end.y - 142.0)]), 3.0, Color(accent.r, accent.g, accent.b, 0.25), -5)
		if tier < int(profile["tiers"]) - 1:
			var next := _chamber_rect(tier + 1)
			var shaft_x := (maxf(room.position.x, next.position.x) + minf(room.end.x, next.end.x)) * 0.5
			var top := minf(room.end.y, next.end.y) - 20.0
			var bottom := maxf(room.end.y, next.end.y) + 20.0
			_poly("RouteShaft%02d" % tier, PackedVector2Array([Vector2(shaft_x - 120.0, top), Vector2(shaft_x + 120.0, top), Vector2(shaft_x + 120.0, bottom), Vector2(shaft_x - 120.0, bottom)]), (profile["shadow"] as Color).lightened(0.025), -9)
	_build_identity_backdrop(start, finish, floor_y, ceiling_y, accent)


func _echo_chamber_silhouette(room: Rect2, tier: int) -> PackedVector2Array:
	var left := room.position.x
	var right := room.end.x
	var top := room.position.y
	var bottom := room.end.y
	var seed := tier * 41 + route_id.length() * 23
	return PackedVector2Array([
		Vector2(left, bottom), Vector2(left - 15.0, bottom - 74.0),
		Vector2(left + 24.0 + float(seed % 31), top + 85.0 + float(seed % 47)),
		Vector2(left + room.size.x * 0.18, top + 21.0 + float((seed * 3) % 49)),
		Vector2(left + room.size.x * 0.39, top + 5.0 + float((seed * 5) % 43)),
		Vector2(left + room.size.x * 0.61, top + 38.0 + float((seed * 7) % 46)),
		Vector2(left + room.size.x * 0.81, top + 12.0 + float((seed * 11) % 53)),
		Vector2(right - 25.0 - float(seed % 37), top + 71.0 + float((seed * 13) % 45)),
		Vector2(right + 15.0, bottom - 79.0), Vector2(right, bottom),
	])


func _build_identity_backdrop(start: float, finish: float, floor_y: float, ceiling_y: float, accent: Color) -> void:
	var span := finish - start
	match route_id:
		"grotto":
			# Three giant crystal organs make the first cave recognizable at any height.
			for choir in range(3):
				var cx := start + span * (0.24 + float(choir) * 0.27)
				var base := floor_y - float(choir * 3 + 2) * TIER_RISE
				for shard in range(5):
					var sx := cx + float(shard - 2) * 42.0
					var height := 170.0 + float((shard * 37 + choir * 61) % 155)
					_poly("ChoirCrystal%02d_%02d" % [choir, shard], PackedVector2Array([Vector2(sx - 24.0, base), Vector2(sx, base - height), Vector2(sx + 29.0, base)]), Color(accent.r, accent.g, accent.b, 0.34), -4)
				_circle("ChoirHalo%02d" % choir, Vector2(cx, base - 105.0), 150.0, Color(accent.r, accent.g, accent.b, 0.075), -7)
		"gallery":
			for arch in range(7):
				var x := start + 240.0 + float(arch) * (span - 480.0) / 6.0
				var top := ceiling_y + 120.0 + float((arch * 89) % 145)
				_line("WhisperArch%02d" % arch, PackedVector2Array([Vector2(x - 125.0, floor_y + 48.0), Vector2(x - 82.0, top + 74.0), Vector2(x, top), Vector2(x + 82.0, top + 74.0), Vector2(x + 125.0, floor_y + 48.0)]), 15.0, Color(accent.r, accent.g, accent.b, 0.17), -5)
				_circle("SoundBell%02d" % arch, Vector2(x, top + 82.0), 42.0, Color(accent.r, accent.g, accent.b, 0.16), -4)
		"archive":
			for tower in range(5):
				var x := start + 270.0 + float(tower) * (span - 540.0) / 4.0
				var top := ceiling_y + 150.0 + float(tower % 2) * 115.0
				_visual_rect("MirrorTower%02d" % tower, Vector2(x, (top + floor_y) * 0.5), Vector2(235.0, floor_y - top), Color(accent.r, accent.g, accent.b, 0.105), -5)
				_line("MirrorSeam%02d" % tower, PackedVector2Array([Vector2(x - 84.0, top + 38.0), Vector2(x + 67.0, floor_y - 74.0), Vector2(x - 45.0, floor_y - 16.0)]), 3.0, Color(accent.r, accent.g, accent.b, 0.31), -4)
		"tide":
			for basin in range(6):
				var y := floor_y - 165.0 - float(basin) * (TIER_RISE * 1.9)
				var bx := start + span * (0.3 if basin % 2 == 0 else 0.7)
				_circle("Reservoir%02d" % basin, Vector2(bx, y), 175.0, Color(accent.r, accent.g, accent.b, 0.105), -6)
				_line("Overflow%02d" % basin, PackedVector2Array([Vector2(bx - 150.0, y), Vector2(bx - 45.0, y + 22.0), Vector2(bx + 62.0, y - 14.0), Vector2(bx + 151.0, y + 3.0)]), 8.0, Color(accent.r, accent.g, accent.b, 0.24), -4)
		"nest":
			for chamber in range(8):
				var x := start + 210.0 + float(chamber % 4) * span * 0.245
				var y := floor_y - 260.0 - float(chamber / 4) * 880.0 - float((chamber * 73) % 170)
				_circle("BroodChamber%02d" % chamber, Vector2(x, y), 150.0 + float(chamber % 3) * 34.0, Color(accent.r, accent.g, accent.b, 0.12), -6)
				for strand in range(4):
					var angle := TAU * float(strand) / 4.0
					_line("Silk%02d_%02d" % [chamber, strand], PackedVector2Array([Vector2(x, y), Vector2(x, y) + Vector2.RIGHT.rotated(angle) * 185.0]), 3.0, Color(0.68, 0.56, 0.78, 0.19), -4)
		"causeway":
			# Local fractured walls replace the old full-map black pillars. They
			# frame each chamber without hiding routes above or below it.
			for fault in range(int(profile["tiers"])):
				var room := _chamber_rect(fault)
				var x := lerpf(room.position.x, room.end.x, 0.28 + 0.44 * float(fault % 2))
				var top := room.position.y + 28.0
				var bottom := room.end.y - 8.0
				_poly("LocalFault%02d" % fault, PackedVector2Array([Vector2(x - 38.0, top), Vector2(x + 24.0, top), Vector2(x + 58.0, bottom), Vector2(x - 63.0, bottom)]), Color(0.008, 0.025, 0.07, 0.54), -6)
				for shard in range(2):
					var sy := bottom - 52.0 - float(shard) * 77.0
					var sx := x + (-92.0 if shard == 0 else 88.0)
					_poly("FaultShard%02d_%02d" % [fault, shard], PackedVector2Array([Vector2(sx - 27.0, sy), Vector2(sx + 4.0, sy - 72.0), Vector2(sx + 35.0, sy)]), Color(accent.r, accent.g, accent.b, 0.34), -3)
		"vault":
			for gate in range(6):
				var x := start + 280.0 + float(gate) * (span - 560.0) / 5.0
				_visual_rect("SluiceGate%02d" % gate, Vector2(x, (ceiling_y + floor_y) * 0.5), Vector2(42.0, floor_y - ceiling_y), Color(0.1, 0.26, 0.38, 0.48), -4)
				for brace in range(5):
					_visual_rect("SluiceBrace%02d_%02d" % [gate, brace], Vector2(x, ceiling_y + 150.0 + float(brace) * 330.0), Vector2(185.0, 18.0), Color(accent.r, accent.g, accent.b, 0.18), -3)


func _build_terrain() -> void:
	var accent: Color = profile["accent"]
	var tier_count := int(profile["tiers"])
	var openings: Dictionary = {}
	for tier in range(tier_count):
		openings[tier] = []
	for tier in range(tier_count - 1):
		var room := _chamber_rect(tier)
		var next := _chamber_rect(tier + 1)
		var x := (maxf(room.position.x, next.position.x) + minf(room.end.x, next.end.x)) * 0.5
		var upper_y := minf(room.end.y, next.end.y)
		# Overlapping galleries at the same height share a mouth. Otherwise a
		# second gallery's floor silently fills the first gallery's shaft hole.
		for candidate in range(tier_count):
			var crossing := _chamber_rect(candidate)
			if is_equal_approx(crossing.end.y, upper_y) and x + 128 > crossing.position.x and x - 128 < crossing.end.x:
				(openings[candidate] as Array).append(x)
	for tier in range(tier_count):
		var room := _chamber_rect(tier)
		_build_chamber_floor(tier, room, openings[tier], accent)
		var spots: Array[Vector2] = []
		for index in range(7):
			spots.append(Vector2(lerpf(room.position.x + 85.0, room.end.x - 85.0, float(index) / 6.0), room.end.y))
		landing_points[tier] = spots
		_build_side_chamber(tier, room, spots[3], accent)
	# All floor segments must exist before choosing the top landing direction:
	# neighbouring shaft mouths can merge and remove the expected landing.
	for tier in range(tier_count - 1):
		_build_chamber_shaft(tier, _chamber_rect(tier), _chamber_rect(tier + 1), accent)
	var first := _chamber_rect(0)
	var last := _chamber_rect(tier_count - 1)
	_rect("LowerSill", Vector2(first.position.x + 85.0, first.end.y), Vector2(170.0, 20.0), accent.darkened(0.47))
	_rect("FarBoundary", Vector2(last.end.x, last.get_center().y), Vector2(14.0, last.size.y), accent.darkened(0.58))


func _build_chamber_floor(tier: int, room: Rect2, raw_openings: Array, accent: Color) -> void:
	var room_openings: Array = raw_openings.duplicate()
	room_openings.sort()
	var cursor := room.position.x
	var segment := 0
	for value in room_openings:
		var opening := float(value)
		var stop := maxf(cursor, opening - 128.0)
		if stop - cursor > 35.0:
			_rect("Chamber%02dFloor%d" % [tier, segment], Vector2((cursor + stop) * 0.5, room.end.y), Vector2(stop - cursor, 18.0), accent.darkened(0.18))
			segment += 1
		cursor = minf(room.end.x, opening + 128.0)
	if room.end.x - cursor > 35.0:
		_rect("Chamber%02dFloor%d" % [tier, segment], Vector2((cursor + room.end.x) * 0.5, room.end.y), Vector2(room.end.x - cursor, 18.0), accent.darkened(0.18))


func _build_chamber_shaft(tier: int, room: Rect2, next: Rect2, accent: Color) -> void:
	var x := (maxf(room.position.x, next.position.x) + minf(room.end.x, next.end.x)) * 0.5
	var upper := minf(room.end.y, next.end.y)
	var lower := maxf(room.end.y, next.end.y)
	var upper_tier := tier if room.end.y < next.end.y else tier + 1
	var lower_tier := tier + 1 if upper_tier == tier else tier
	var top_side := -1.0
	var nearest := INF
	var rim_x := x
	var left_rim := -INF
	var right_rim := INF
	for body in get_children():
		if not body is StaticBody2D or not String(body.name).begins_with("Chamber%02dFloor" % upper_tier):
			continue
		var width: float = body.get_node("CollisionShape2D").shape.size.x
		var landing_x := clampf(x, body.position.x - width * 0.5, body.position.x + width * 0.5)
		if landing_x < x:
			left_rim = maxf(left_rim, landing_x)
		elif landing_x > x:
			right_rim = minf(right_rim, landing_x)
		if absf(landing_x - x) < nearest:
			nearest = absf(landing_x - x)
			rim_x = landing_x
			top_side = -1.0 if landing_x < x else 1.0
	assert(nearest < INF, "Echo shaft has no surviving upper floor: %s/%d" % [route_id, tier])
	var count := maxi(2, int(ceil((lower - upper) / 58.0)) - 1)
	for step in range(count):
		var fraction := float(step + 1) / float(count + 1)
		var offset := top_side * (58.0 if step % 2 == 0 else -58.0)
		var left := x + offset - 61.0
		var right := x + offset + 61.0
		if step == 0:
			# The upper plank is also the crossing between the two corridor
			# rims. An offset 122px step left a 125px opposite gap plus a
			# 50-59px climb, unreachable with the basic jump. Keep 32px gaps
			# at both normal rims; one-way collision preserves shaft ascent.
			left = minf(left, x - 96.0)
			right = maxf(right, x + 96.0)
			if is_finite(left_rim):
				left = minf(left, left_rim + 32.0)
			if is_finite(right_rim):
				right = maxf(right, right_rim - 32.0)
			# Two merged mouths sometimes remove the near rim altogether. Extend
			# this landing toward the surviving floor, keeping a 32px exit gap.
			if top_side < 0:
				left = minf(left, rim_x + 32.0)
			else:
				right = maxf(right, rim_x - 32.0)
		if step == count - 1:
			# A neighbouring shaft can cut away the lower approach as well.
			# Keep the bottom plank within basic-jump range of an actual floor
			# in THIS lower chamber, not a different gallery at the same height.
			var approach_x := x
			var approach_gap := INF
			for body in get_children():
				if not body is StaticBody2D or not String(body.name).begins_with("Chamber%02dFloor" % lower_tier):
					continue
				var half: float = body.get_node("CollisionShape2D").shape.size.x * 0.5
				var floor_left: float = body.position.x - half
				var floor_right: float = body.position.x + half
				var gap := maxf(left, floor_left) - minf(right, floor_right)
				if gap < approach_gap:
					approach_gap = gap
					approach_x = clampf((left + right) * 0.5, floor_left, floor_right)
			assert(approach_gap < INF, "Echo shaft has no lower approach: %s/%d" % [route_id, tier])
			if approach_gap > 70.0:
				if approach_x < left:
					left = approach_x + 32.0
				else:
					right = approach_x - 32.0
		_rect("Tier%02dRise%02d" % [tier + 1, step + 1], Vector2((left + right) * 0.5, lerpf(upper, lower, fraction)), Vector2(right - left, 11.0), accent.lightened(0.12), true)


func _build_side_chamber(tier: int, room: Rect2, root: Vector2, accent: Color) -> void:
	var side := -1.0 if room.get_center().x > (float(profile["start"]) + float(profile["end"])) * 0.5 else 1.0
	if tier % 2 == 1:
		var branch_floor := room.end.y - 108.0
		var chamber_left := root.x - 610.0 if side < 0.0 else root.x + 185.0
		var chamber_right := root.x - 185.0 if side < 0.0 else root.x + 610.0
		_poly("Tier%02dBranchChamber" % tier, PackedVector2Array([
			Vector2(chamber_left - 35.0, branch_floor + 25.0), Vector2(chamber_left - 51.0, branch_floor - 51.0),
			Vector2(chamber_left - 12.0, branch_floor - 172.0), Vector2(chamber_left + 82.0, branch_floor - 229.0),
			Vector2((chamber_left + chamber_right) * 0.5, branch_floor - 194.0 - float((tier * 17) % 32)),
			Vector2(chamber_right - 74.0, branch_floor - 224.0), Vector2(chamber_right + 18.0, branch_floor - 166.0),
			Vector2(chamber_right + 51.0, branch_floor - 46.0), Vector2(chamber_right + 35.0, branch_floor + 25.0),
		]), profile["shadow"], -8)
		# A neighbouring shaft can remove the floor beneath the branch mouth.
		# Reach the surviving floor of this chamber, rather than asking for a
		# long diagonal jump across the hole. One-way collision keeps it open.
		var step_left := root.x + side * 82.0 - 60.0
		var step_right := step_left + 120.0
		var approach_gap := INF
		var approach_x := root.x
		for body in get_children():
			if not body is StaticBody2D or not String(body.name).begins_with("Chamber%02dFloor" % tier):
				continue
			var half: float = body.get_node("CollisionShape2D").shape.size.x * 0.5
			var floor_left: float = body.position.x - half
			var floor_right: float = body.position.x + half
			var gap := maxf(step_left, floor_left) - minf(step_right, floor_right)
			if gap < approach_gap:
				approach_gap = gap
				approach_x = clampf((step_left + step_right) * 0.5, floor_left, floor_right)
		if approach_gap > 70.0 and is_finite(approach_gap):
			if approach_x < step_left:
				step_left = approach_x + 32.0
			else:
				step_right = approach_x - 32.0
		_rect("Tier%02dBranchStep1" % tier, Vector2((step_left + step_right) * 0.5, root.y - 54.0), Vector2(step_right - step_left, 11.0), accent.lightened(0.11), true)
		_rect("Tier%02dBranchStep2" % tier, root + Vector2(side * 164.0, -108.0), Vector2(120.0, 11.0), accent.lightened(0.15), true)
		var split := (chamber_left + chamber_right) * 0.5
		# These raised ledges can cross a neighbouring shaft. Like their access
		# steps, they must catch landings without sealing ascent from underneath.
		_rect("Tier%02dHiddenShelfA" % tier, Vector2((chamber_left + split) * 0.5, branch_floor), Vector2(split - chamber_left, 18.0), accent.lightened(0.13), true)
		_rect("Tier%02dHiddenShelfB" % tier, Vector2((split + chamber_right) * 0.5, branch_floor), Vector2(chamber_right - split, 18.0), accent.lightened(0.2), true)
	else:
		_rect("Tier%02dSideAlcove" % tier, root + Vector2(side * 155.0, -62.0), Vector2(430.0, 16.0), accent.lightened(0.18), true)
		_poly("Tier%02dAlcoveMouth" % tier, PackedVector2Array([root + Vector2(side * 370.0, -175.0), root + Vector2(side * 330.0, -82.0), root + Vector2(side * 45.0, -82.0), root + Vector2(side * 15.0, -175.0)]), accent.darkened(0.53), -2)


func _route_gap(tier: int, gap_index: int) -> float:
	var seed := tier * 19 + gap_index * 31 + route_id.length() * 7
	match route_id:
		"gallery":
			return 44.0 + float(seed % 19)
		"archive":
			return 48.0 + float((gap_index % 3) * 7)
		"tide":
			return 46.0 + float((tier + gap_index * 2) % 20)
		"nest":
			return 42.0 + float(seed % 25)
		"causeway":
			return 55.0 + float(seed % 13)
		"vault":
			return 47.0 + float((tier * 3 + gap_index * 11) % 20)
		_:
			return 45.0 + float(seed % 21)


func _shelf_offset(tier: int, contour_index: int, shelf_count: int) -> float:
	if contour_index <= 0 or contour_index >= shelf_count - 1:
		return 0.0
	var patterns := {
		"grotto": [0.0, -8.0, 24.0, 43.0, 8.0, -5.0, 29.0, 0.0],
		"gallery": [0.0, 34.0, 8.0, -9.0, 28.0, 44.0, 12.0, 0.0],
		"archive": [0.0, -10.0, -10.0, 31.0, 31.0, 4.0, 42.0, 0.0],
		"tide": [0.0, 25.0, 43.0, 14.0, -7.0, 0.0, 0.0, 0.0],
		"nest": [0.0, 42.0, 16.0, -6.0, 35.0, 9.0, 45.0, 0.0],
		"causeway": [0.0, -8.0, 36.0, 9.0, 43.0, 4.0, 32.0, 0.0],
		"vault": [0.0, 17.0, 39.0, 8.0, -9.0, 28.0, 43.0, 0.0],
	}
	var contour: Array = patterns[route_id]
	var safe_index := mini(contour_index, contour.size() - 1)
	var offset: float = contour[safe_index]
	# Alternating tiers invert only the small accents, while the central bowl is
	# kept lower so a room reads as chambers instead of a stack of ruler lines.
	if tier % 2 == 0 and offset < 20.0:
		offset += 16.0
	return offset


func _build_landmarks() -> void:
	if route_id in ["grotto", "gallery", "archive", "tide", "nest", "causeway", "vault"]:
		var dressing := Node2D.new()
		dressing.name = "FieldDressing"
		if route_id in ["causeway", "vault"]:
			dressing.set_script(CROSSING_DRESSING)
		else:
			dressing.set_script(HABITAT_DRESSING if route_id in ["tide", "nest"] else FIELD_DRESSING)
		dressing.set("region", "echo" if route_id == "grotto" else route_id)
		add_child(dressing)
	var start: float = profile["start"]
	var floor_y: float = profile["floor"]
	var accent: Color = profile["accent"]
	_label("RouteTitle", profile["name"], Vector2(start + 92.0, floor_y - 150.0), 340.0, 16, accent.lightened(0.46))
	_label("RouteHint", ROUTE_HINTS[route_id], Vector2(start + 92.0, floor_y - 123.0), 520.0, 10, accent.lightened(0.26))
	for tier in range(int(profile["tiers"])):
		var room := _chamber_rect(tier)
		var y := room.end.y
		var going_right := true if tier == int(profile["tiers"]) - 1 else _chamber_rect(tier + 1).get_center().x > room.get_center().x
		var direction := "FOLLOW THE ECHO  >" if going_right else "<  FOLLOW THE ECHO"
		var leg_left := room.position.x
		var leg_right := room.end.x
		_label("TierSign%02d" % tier, direction, Vector2(leg_left + 55.0 if going_right else leg_right - 295.0, y - 88.0), 240.0, 9, accent.lightened(0.22))
		if tier == int(profile["tiers"]) - 1:
			_label("ReturnSign", "RETURN TO ENTRY", Vector2(leg_right - 230.0, y - 88.0), 220.0, 9, accent.lightened(0.34))
		var growth_count := clampi(int((leg_right - leg_left) / 260.0), 3, 9)
		for plant in range(growth_count):
			var x := leg_left + 62.0 + (leg_right - leg_left - 124.0) * float(plant) / float(maxi(1, growth_count - 1))
			var height := 17.0 + float((plant * 19 + tier * 11) % 35)
			var stem := PackedVector2Array([Vector2(x - 9.0, y - 9.0), Vector2(x - 4.0, y - height), Vector2(x, y - height - 12.0), Vector2(x + 4.0, y - height), Vector2(x + 9.0, y - 9.0)])
			_poly("LumenGrowth%02d_%02d" % [tier, plant], stem, Color(accent.r, accent.g, accent.b, 0.68), -1)
			_poly("LumenCap%02d_%02d" % [tier, plant], PackedVector2Array([Vector2(x - 13.0, y - height), Vector2(x, y - height - 13.0), Vector2(x + 13.0, y - height)]), accent.lightened(0.27), -1)
		for crystal in range(3):
			var cx := lerpf(leg_left, leg_right, 0.2 + float(crystal) * 0.3) + float(tier % 2) * 22.0
			_poly("EchoCrystal%02d_%02d" % [tier, crystal], PackedVector2Array([Vector2(cx - 14.0, y - 9.0), Vector2(cx, y - 83.0 - float(crystal % 2) * 32.0), Vector2(cx + 18.0, y - 9.0)]), Color(accent.r, accent.g, accent.b, 0.66), -1)


func _build_identity_features() -> void:
	var identity := Node2D.new()
	identity.name = {
		"grotto": "ResonanceChoir",
		"gallery": "WhisperGalleries",
		"archive": "MirrorStacks",
		"tide": "TidalCurrents",
		"nest": "BroodNurseries",
		"causeway": "PhaseCauseway",
		"vault": "SluiceVault",
	}[route_id]
	identity.set_meta("route_identity", route_id)
	add_child(identity)
	var accent: Color = profile["accent"]
	match route_id:
		"grotto":
			for index in range(3):
				var tier := 2 + index * 3
				var point: Vector2 = landing_points[tier][landing_points[tier].size() / 2]
				_rect("ChoirDais%02d" % index, point + Vector2(0.0, -72.0), Vector2(210.0, 12.0), accent.lightened(0.25), true)
				_circle("ChoirHeart%02d" % index, point + Vector2(0.0, -139.0), 38.0, Color(0.46, 0.96, 0.94, 0.29), -1)
		"gallery":
			for index in range(4):
				var tier := 1 + index * 2
				var points: Array = landing_points[tier]
				var point: Vector2 = points[1 if index % 2 == 0 else points.size() - 2]
				_rect("ListeningNiche%02d" % index, point + Vector2(0.0, -73.0), Vector2(225.0, 12.0), accent.lightened(0.18), true)
				_circle("WhisperBell%02d" % index, point + Vector2(0.0, -137.0), 32.0, Color(accent.r, accent.g, accent.b, 0.23), -1)
		"archive":
			for index in range(4):
				var tier := 1 + index * 2
				var points: Array = landing_points[tier]
				var point: Vector2 = points[points.size() / 2]
				_rect("IndexBalcony%02d" % index, point + Vector2(0.0, -76.0), Vector2(248.0, 12.0), accent.lightened(0.2), true)
				_visual_rect("ReadingMirror%02d" % index, point + Vector2(0.0, -150.0), Vector2(86.0, 118.0), Color(accent.r, accent.g, accent.b, 0.27), -1)
				_line("RefractionBeam%02d" % index, PackedVector2Array([point + Vector2(-150.0, -188.0), point + Vector2(0.0, -150.0), point + Vector2(165.0, -205.0)]), 4.0, Color(accent.r, accent.g, accent.b, 0.35), -2)
		"tide":
			var tiers := [2, 5, 8, 11]
			for index in range(tiers.size()):
				var tier: int = tiers[index]
				var points: Array = landing_points[tier]
				var point: Vector2 = points[points.size() / 2]
				_add_current("RisingCurrent%02d" % index, point + Vector2(0.0, -55.0), Vector2(68.0 if index % 2 == 0 else -68.0, -58.0), 1.25)
				_label("CurrentMarker%02d" % index, "RISING CURRENT  %s" % (">" if index % 2 == 0 else "<"), point + Vector2(-105.0, -116.0), 210.0, 8, accent.lightened(0.35))
		"nest":
			for index in range(4):
				var tier := 1 + index * 2
				var points: Array = landing_points[tier]
				var point: Vector2 = points[1 if index % 2 == 0 else points.size() - 2]
				_rect("NurseryPerch%02d" % index, point + Vector2(0.0, -74.0), Vector2(238.0, 12.0), accent.lightened(0.12), true)
				for egg in range(3):
					_circle("Cocoon%02d_%02d" % [index, egg], point + Vector2(float(egg - 1) * 54.0, -112.0 - float(egg % 2) * 18.0), 25.0, Color(0.76, 0.49, 0.77, 0.3), -1)
		"causeway":
			for index in range(4):
				var tier := 2 + index * 2
				var points: Array = landing_points[tier]
				var point: Vector2 = points[points.size() / 2]
				_add_phase_bridge("TraversalPhaseBridge%02d" % index, point + Vector2(0.0, -82.0), float(index) * 0.47)
				_line("AnchorRay%02d" % index, PackedVector2Array([point + Vector2(-120.0, -145.0), point + Vector2(0.0, -82.0), point + Vector2(120.0, -145.0)]), 3.0, Color(accent.r, accent.g, accent.b, 0.42), -1)
		"vault":
			for index in range(3):
				var tier := 2 + index * 2
				var points: Array = landing_points[tier]
				var point: Vector2 = points[points.size() / 2]
				_add_tide_pulse("SluiceSurge%02d" % index, point + Vector2(0.0, -22.0), "echo_vault_upper" if index == 0 else "echo_vault_far")
				_label("SluiceWarning%02d" % index, "SLUICE %02d  •  WATCH THE CREST" % (index + 1), point + Vector2(-145.0, -91.0), 290.0, 8, accent.lightened(0.34))
			for index in range(2):
				var tier := 3 + index * 4
				var point: Vector2 = landing_points[tier][1 if index == 0 else landing_points[tier].size() - 2]
				_add_current("UndertowCurrent%02d" % index, point + Vector2(0.0, -55.0), Vector2(-74.0 if index == 0 else 74.0, 18.0), 1.1)


func _add_current(node_name: String, at: Vector2, flow: Vector2, width_scale: float) -> void:
	var current := CURRENT_FIELD.instantiate() as Area2D
	current.name = node_name
	current.position = at
	current.scale.x = width_scale
	current.set("flow_velocity", flow)
	current.set("current_tint", profile["accent"].lightened(0.1))
	add_child(current)


func _add_phase_bridge(node_name: String, at: Vector2, offset: float) -> void:
	var bridge := PHASE_BRIDGE.instantiate() as StaticBody2D
	bridge.name = node_name
	bridge.position = at
	bridge.scale.x = 1.55
	bridge.set("initial_offset", offset)
	add_child(bridge)


func _add_tide_pulse(node_name: String, at: Vector2, disabled_by: String) -> void:
	var surge := TIDE_PULSE.instantiate() as Area2D
	surge.name = node_name
	surge.position = at
	surge.scale.x = 0.82
	surge.set("zone_id", "echo_grotto")
	surge.set("disabled_by_shortcut_id", disabled_by)
	add_child(surge)


func _build_life() -> void:
	for tier in range(int(profile["tiers"])):
		var positions: Array[Vector2] = []
		for point in landing_points[tier]:
			positions.append(point)
		for index in range(2):
			var site: Vector2 = positions[1 + (index * (positions.size() - 3))]
			var kind := _encounter_kind(tier, index)
			var enemy_name := "%s_%02d_%02d" % [_enemy_role_name(kind), tier, index]
			if has_node(enemy_name):
				continue
			var enemy: Node2D = (WISP if kind == "wisp" else (BROOD if kind == "brood" else SHADE)).instantiate()
			enemy.name = enemy_name
			# The Causeway's fractured third shelf has a deliberately short patrol.
			var narrow_shelf := route_id == "causeway" and tier == 3
			enemy.position = site + Vector2(0, -72) if kind == "wisp" else _floor_point(tier, site.x, 32, 80 if narrow_shelf else 110)
			if narrow_shelf and kind == "shade":
				enemy.set("patrol_radius", 60.0)
			enemy.set("zone_id", "echo_grotto")
			enemy.set("gold_reward", 10 + tier + (4 if index == 1 else 0))
			if kind == "brood":
				enemy.set("counts_for_nest", false)
			_add_streamed_generated_actor(enemy)
		if tier > 0 and tier % 3 == 2:
			var ambush_kind := "brood" if route_id == "nest" else "shade"
			var ambusher_name := "%sAmbusher%02d" % [route_id.capitalize(), tier]
			if not has_node(ambusher_name):
				var ambusher: Node2D = (BROOD if ambush_kind == "brood" else SHADE).instantiate()
				ambusher.name = ambusher_name
				ambusher.position = _floor_point(tier, positions[positions.size() / 2].x, 34.0)
				if route_id == "tide" and tier == 11:
					# This narrow landing cannot host a second full patrol and an
					# ambusher. Guard the side branch instead of stacking three foes.
					ambusher.position = get_node("Tier11HiddenShelfB").position + Vector2(0, -34)
					ambusher.set("patrol_radius", 70.0)
				ambusher.set("zone_id", "echo_grotto")
				ambusher.set("gold_reward", 14 + tier)
				if ambush_kind == "brood":
					ambusher.set("counts_for_nest", false)
				_add_streamed_generated_actor(ambusher)
		if tier % 2 == 0:
			var traversal_crate_name := "TraversalCrate%02d" % tier
			if not has_node(traversal_crate_name):
				var crate := CRATE.instantiate()
				crate.name = traversal_crate_name
				crate.position = _floor_point(tier, positions[0].x, 28.0, 40.0)
				crate.empty_drop_chance = 0.27
				crate.item_drop_chance = 0.22
				crate.common_item_ids = PackedStringArray(["ether_dust", "healing_herb", "resonance_shard"])
				_add_streamed_generated_actor(crate)
			if tier > 0:
				var alcove_crate_name := "AlcoveCrate%02d" % tier
				if not has_node(alcove_crate_name):
					var alcove_crate := CRATE.instantiate()
					alcove_crate.name = alcove_crate_name
					var alcove: StaticBody2D = get_node("Tier%02dSideAlcove" % tier)
					# Archive's sixth alcove overlaps the only surviving lower
					# takeoff for the next shaft. Keep its optional crate to the
					# side instead of making the mandatory jump hit its underside.
					var crate_offset := -110.0 if route_id == "archive" and tier == 6 else 0.0
					alcove_crate.position = alcove.position + Vector2(crate_offset, -27.0)
					alcove_crate.empty_drop_chance = 0.39
					alcove_crate.item_drop_chance = 0.2
					_add_streamed_generated_actor(alcove_crate)
		elif tier > 0:
			var hidden_crate_name := "HiddenCrate%02d" % tier
			if not has_node(hidden_crate_name):
				var hidden_crate := CRATE.instantiate()
				hidden_crate.name = hidden_crate_name
				hidden_crate.position = traverse_branch_position(tier)
				hidden_crate.empty_drop_chance = 0.34
				hidden_crate.item_drop_chance = 0.24
				hidden_crate.common_item_ids = PackedStringArray(["ether_dust", "healing_herb"])
				_add_streamed_generated_actor(hidden_crate)
	for index in range(5):
		var creature_node_name := "QuietCaveLife%d" % index
		if has_node(creature_node_name):
			continue
		var tier: int = 0 if index == 0 else mini(int(profile["tiers"]) - 1, 1 + index * (int(profile["tiers"]) - 2) / 4)
		var creature := NEUTRAL.instantiate()
		creature.name = creature_node_name
		creature.position = _floor_point(tier, landing_points[tier][0 if index % 2 == 0 else landing_points[tier].size() - 1].x, 32.0)
		creature.creature_name = FAUNA_NAMES[route_id]
		creature.zone_id = "echo_grotto"
		creature.start_resting = index % 2 == 0
		creature.passive_tint = profile["accent"].lightened(0.25)
		_add_streamed_generated_actor(creature)
	if not has_node("RouteDiscoveryCache"):
		var reward_data: Array = HIDDEN_REWARDS[route_id]
		var reward_shelf := get_node("Tier07HiddenShelfB") as StaticBody2D
		var discovery := CACHE.instantiate()
		discovery.name = "RouteDiscoveryCache"
		discovery.position = reward_shelf.position + Vector2(0.0, -34.0)
		discovery.cache_id = "echo_%s_route_discovery" % route_id
		discovery.cache_name = String(reward_data[0])
		discovery.reward_item_id = String(reward_data[1])
		discovery.gold_reward = int(reward_data[2])
		if FIELD_DISCOVERIES.PROFILES.has(route_id) or FIELD_OPERATIONS.PROFILES.has(route_id):
			discovery.required_event_ids = PackedStringArray(["echo_%s_field_complete" % route_id])
		add_child(discovery)
	_spawn_optional_ambush()
	if FIELD_DISCOVERIES.PROFILES.has(route_id) and not has_node("FieldDiscoveries"):
		var discoveries := Node2D.new()
		discoveries.name = "FieldDiscoveries"
		discoveries.set_script(FIELD_DISCOVERIES)
		discoveries.set("route", self)
		add_child(discoveries)
	if FIELD_OPERATIONS.PROFILES.has(route_id) and not has_node("FieldOperations"):
		var operations := Node2D.new()
		operations.name = "FieldOperations"
		operations.set_script(FIELD_OPERATIONS)
		operations.set("route", self)
		operations.set("route_id", route_id)
		add_child(operations)
	if not has_node("RimReturnDoor"):
		var backtrack := DOOR.instantiate()
		backtrack.name = "RimReturnDoor"
		var final_room := _chamber_rect(int(profile["tiers"]) - 1)
		backtrack.position = _floor_point(int(profile["tiers"]) - 1, final_room.end.x - 120.0)
		backtrack.target_room_id = RETURN_TARGETS[route_id][0]
		backtrack.target_marker_group = StringName(RETURN_TARGETS[route_id][1])
		backtrack.door_label = "ENTRY RETURN"
		add_child(backtrack)


func _spawn_optional_ambush() -> void:
	if has_node("OptionalAmbush"):
		return
	# Tier three is a real dead-end chamber in every Echo route. Its enemies
	# are created only when the player enters, so the reward is not another
	# predictable pair of patrols waiting from scene load.
	var branch := get_node("Tier03HiddenShelfB") as StaticBody2D
	var encounter := LOCAL_ENCOUNTER.instantiate() as Area2D
	encounter.name = "OptionalAmbush"
	encounter.position = branch.position + Vector2(-70.0, 0.0)
	encounter.set("encounter_id", "echo_%s_hidden_ambush" % route_id)
	encounter.set("zone_id", "echo_grotto")
	var first_kind := _encounter_kind(3, 0)
	var second_kind := _encounter_kind(3, 1)
	encounter.get("enemy_scenes").append(_scene_for_kind(first_kind))
	encounter.get("enemy_scenes").append(_scene_for_kind(second_kind))
	encounter.get("spawn_offsets").append(Vector2(-105.0, -78.0 if first_kind == "wisp" else -32.0))
	encounter.get("spawn_offsets").append(Vector2(105.0, -78.0 if second_kind == "wisp" else -32.0))
	add_child(encounter)


func _scene_for_kind(kind: String) -> PackedScene:
	return WISP if kind == "wisp" else (BROOD if kind == "brood" else SHADE)


func _encounter_kind(tier: int, index: int) -> String:
	match route_id:
		"grotto":
			return "shade" if tier in [3, 6] and index == 1 else "wisp"
		"gallery":
			return "wisp" if (tier + index) % 4 == 0 else "shade"
		"archive":
			return "wisp" if tier % 4 == 2 and index == 0 else "shade"
		"tide":
			return "shade" if tier % 4 == 3 and not (tier == 11 and index == 1) else "wisp"
		"nest":
			return "wisp" if tier in [4, 8] and index == 0 else "brood"
		"causeway":
			return "shade" if (tier + index) % 2 == 0 else "wisp"
		"vault":
			var cycle := (tier + index) % 3
			return "brood" if cycle == 0 else ("wisp" if cycle == 1 else "shade")
	return "shade"


func _enemy_role_name(kind: String) -> String:
	var role: String = {
		"grotto": "Choir",
		"gallery": "Whisper",
		"archive": "Index",
		"tide": "Current",
		"nest": "Nursery",
		"causeway": "Shard",
		"vault": "Sluice",
	}[route_id]
	return "%s%s" % [role, kind.capitalize()]


func traverse_branch_position(tier: int) -> Vector2:
	var branch: StaticBody2D = get_node("Tier%02dHiddenShelfB" % tier)
	return branch.position + Vector2(0.0, -27.0)


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


func _visual_rect(node_name: String, at: Vector2, size: Vector2, tint: Color, layer: int) -> void:
	_poly(node_name, PackedVector2Array([
		at + Vector2(-size.x * 0.5, -size.y * 0.5),
		at + Vector2(size.x * 0.5, -size.y * 0.5),
		at + Vector2(size.x * 0.5, size.y * 0.5),
		at + Vector2(-size.x * 0.5, size.y * 0.5),
	]), tint, layer)


func _circle(node_name: String, at: Vector2, radius: float, tint: Color, layer: int, points: int = 18) -> void:
	var vertices := PackedVector2Array()
	for index in range(points):
		vertices.append(at + Vector2.RIGHT.rotated(TAU * float(index) / float(points)) * radius)
	_poly(node_name, vertices, tint, layer)


func _line(node_name: String, points: PackedVector2Array, width: float, tint: Color, layer: int) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.z_index = layer
	line.width = width
	line.default_color = tint
	line.points = points
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)


func _label(node_name: String, message: String, at: Vector2, width: float, font_size: int, tint: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.size = Vector2(width, 26)
	label.text = message
	label.add_theme_color_override("font_color", tint)
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
