@tool
extends "res://ShaftRoomExpansion.gd"

# Six late-game routes inherit the proven basic-jump geometry helpers, but
# author their own 6.5k-wide paths, encounter sites, architecture and puzzles.
const STAR_WIDTH := 6500.0
const STAR_HEIGHT := 2300.0
const STAR_LIFT: PackedScene = preload("res://ShaftLift.tscn")
const SHADE: PackedScene = preload("res://EchoShade.tscn")
const STALKER: PackedScene = preload("res://RootStalker.tscn")
const SENTRY: PackedScene = preload("res://AshSentry.tscn")
const STAR_CRATE: PackedScene = preload("res://DestructibleCrate.tscn")
const STAR_FAUNA: PackedScene = preload("res://NeutralCreature.tscn")
const STAR_CACHE: PackedScene = preload("res://ResonanceCache.tscn")
const STAR_SURGE: PackedScene = preload("res://TidePulse.tscn")
const LOCAL_ENCOUNTER: PackedScene = preload("res://LocalizedEncounter.tscn")
const FIELD_OPERATIONS = preload("res://StarfallFieldOperations.gd")
const AUTHORED_FLOOR_SLOTS := {
	"LostWatch": [3, 5], "WardSentry": [3, 5], "PitShade": [3, 4],
	"ArchiveSentry": [4, 5], "FarStalker": [4, 5],
	"CrucibleSentry": [3, 5], "SunlessSentry": [3, 5],
}

# Original scene actors are data-driven so the late-game rooms do not pay
# their combat cost before first entry. Relays, snares, caches and boss rooms
# remain persistent because their state participates in progression/save flow.
const STAR_AUTHORED_POPULATION := {
	"StarfallOutskirts": [
		{"name": "DuskShade", "scene": SHADE, "position": Vector2(880, 367), "properties": {"zone_id": "starfall_reach", "max_health": 5, "patrol_radius": 105.0, "xp_reward": 3, "gold_reward": 20}, "child_properties": {"BodyVisual": {"color": Color(0.56, 0.44, 0.75, 1)}}},
		{"name": "LostWatch", "scene": SENTRY, "position": Vector2(1340, 368), "properties": {"zone_id": "starfall_reach", "max_health": 5, "detection_range": 255.0, "gold_reward": 22, "projectile_color": Color(0.78, 0.55, 1, 1), "projectile_glow_color": Color(0.65, 0.4, 0.88, 0.4), "idle_eye_color": Color(0.88, 0.7, 1, 1)}, "child_properties": {"Shell": {"color": Color(0.32, 0.25, 0.47, 1)}}},
	],
	"StarfallSilentGate": [
		{"name": "HushedShade", "scene": SHADE, "position": Vector2(675, 367), "properties": {"zone_id": "starfall_reach", "max_health": 6, "patrol_radius": 85.0, "xp_reward": 3, "gold_reward": 22}, "child_properties": {"BodyVisual": {"color": Color(0.57, 0.42, 0.74, 1)}}},
		{"name": "WardSentry", "scene": SENTRY, "position": Vector2(1180, 368), "properties": {"zone_id": "starfall_reach", "max_health": 6, "detection_range": 245.0, "gold_reward": 24, "projectile_color": Color(0.82, 0.6, 1, 1), "projectile_glow_color": Color(0.65, 0.4, 0.88, 0.4)}},
	],
	"StarfallMemoryVault": [
		{"name": "PitShade", "scene": SHADE, "position": Vector2(895, 587), "properties": {"zone_id": "starfall_reach", "max_health": 6, "patrol_radius": 65.0, "xp_reward": 3, "gold_reward": 23}, "child_properties": {"BodyVisual": {"color": Color(0.42, 0.63, 0.72, 1)}}},
		{"name": "ArchiveSentry", "scene": SENTRY, "position": Vector2(1370, 368), "properties": {"zone_id": "starfall_reach", "max_health": 6, "detection_range": 245.0, "gold_reward": 25, "projectile_color": Color(0.55, 0.85, 0.98, 1), "projectile_glow_color": Color(0.35, 0.72, 0.92, 0.4)}},
	],
	"StarfallRootedHall": [
		{"name": "FirstStalker", "scene": STALKER, "position": Vector2(840, 370), "properties": {"patrol_radius": 65.0}},
		{"name": "FarStalker", "scene": STALKER, "position": Vector2(1580, 370), "properties": {"patrol_radius": 70.0}},
	],
	"StarfallSoulCrucible": [
		{"name": "BoundShade", "scene": SHADE, "position": Vector2(495, 407), "properties": {"zone_id": "starfall_reach", "max_health": 6, "patrol_radius": 65.0, "gold_reward": 22}, "child_properties": {"BodyVisual": {"color": Color(0.64, 0.39, 0.76, 1)}}},
		{"name": "CrucibleSentry", "scene": SENTRY, "position": Vector2(1170, 408), "properties": {"zone_id": "starfall_reach", "max_health": 7, "detection_range": 250.0, "gold_reward": 28, "projectile_color": Color(0.9, 0.61, 1, 1), "projectile_glow_color": Color(0.67, 0.35, 0.88, 0.4)}},
	],
	"StarfallSunlessPassage": [
		{"name": "LostShade", "scene": SHADE, "position": Vector2(650, 508), "properties": {"zone_id": "starfall_reach", "max_health": 7, "patrol_radius": 75.0, "gold_reward": 25}, "child_properties": {"BodyVisual": {"color": Color(0.37, 0.43, 0.75, 1)}}},
		{"name": "SunlessSentry", "scene": SENTRY, "position": Vector2(1190, 508), "properties": {"zone_id": "starfall_reach", "max_health": 7, "detection_range": 270.0, "gold_reward": 28, "projectile_color": Color(0.65, 0.72, 1, 1), "projectile_glow_color": Color(0.45, 0.5, 0.85, 0.4)}},
	],
}

const STAR_IDENTITIES := {
	"StarfallOutskirts": {
		"title": "THE FALLEN MUSTER", "motif": "gate_siege",
		"cache": "Last Caravan Cache", "reward": "iron_fragment", "gold": 38,
		"fauna": ["Rampart Moth", "Dusk Grazer"],
	},
	"StarfallSilentGate": {
		"title": "THE SILENT GATE", "motif": "warded_gate",
		"cache": "Gatekeeper's Quiet Cache", "reward": "ether_dust", "gold": 42,
		"fauna": ["Mute Moth", "Ward Grazer"],
	},
	"StarfallMemoryVault": {
		"title": "VAULT OF REMEMBERED NAMES", "motif": "memory_archive",
		"cache": "Archivist's Memory Cache", "reward": "ether_dust", "gold": 46,
		"fauna": ["Script Moth", "Memory Grazer"],
	},
	"StarfallRootedHall": {
		"title": "THE ROOT-BOUND HALL", "motif": "living_roots",
		"cache": "Rootkeeper's Cache", "reward": "healing_herb", "gold": 44,
		"fauna": ["Root Moth", "Pale Antlerling"],
	},
	"StarfallSoulCrucible": {
		"title": "THE SOUL CRUCIBLE", "motif": "unstable_crucible",
		"cache": "Crucible Tender Cache", "reward": "resonance_shard", "gold": 50,
		"fauna": ["Spark Moth", "Crucible Grazer"],
	},
	"StarfallSunlessPassage": {
		"title": "THE SUNLESS PROCESSION", "motif": "living_darkness",
		"cache": "Bearer's Last Light", "reward": "resonance_shard", "gold": 55,
		"fauna": ["Night Moth", "Gloom Grazer"],
	},
}

# These are deliberately not recoloured Shaft layouts. The six Starfall
# routes use their own late-game traversal silhouettes: a breached rampart,
# a warded gate circuit, an archive loop, a root-grown hall, a crucible spiral
# and a descending procession. Each route still has overlapping chambers so
# every ascent and drop remains reversible.
const STAR_CHAMBER_LAYOUTS := {
	"StarfallOutskirts": [[0.00, 0.28, 400.0], [0.20, 0.50, 760.0], [0.41, 0.73, 1120.0], [0.64, 1.00, 760.0], [0.72, 1.00, 1480.0], [0.43, 0.80, 1840.0], [0.12, 0.54, 2180.0]],
	"StarfallSilentGate": [[0.00, 0.31, 400.0], [0.22, 0.51, 760.0], [0.43, 0.78, 1120.0], [0.69, 1.00, 1480.0], [0.50, 0.82, 1840.0], [0.23, 0.60, 1480.0], [0.43, 0.97, 2180.0]],
	"StarfallMemoryVault": [[0.00, 0.29, 400.0], [0.19, 0.53, 760.0], [0.44, 0.76, 1120.0], [0.63, 0.96, 760.0], [0.73, 1.00, 1480.0], [0.39, 0.80, 1840.0], [0.58, 0.97, 2180.0]],
	"StarfallRootedHall": [[0.00, 0.33, 400.0], [0.24, 0.63, 760.0], [0.52, 0.91, 1120.0], [0.73, 1.00, 1480.0], [0.48, 0.83, 1120.0], [0.17, 0.58, 1840.0], [0.39, 0.97, 2180.0]],
	"StarfallSoulCrucible": [[0.00, 0.35, 440.0], [0.26, 0.63, 800.0], [0.53, 0.91, 1160.0], [0.70, 1.00, 1520.0], [0.40, 0.77, 1880.0], [0.12, 0.51, 1520.0], [0.33, 0.97, 2200.0]],
	"StarfallSunlessPassage": [[0.00, 0.33, 440.0], [0.23, 0.51, 800.0], [0.05, 0.31, 1160.0], [0.21, 0.57, 1520.0], [0.49, 0.87, 1880.0], [0.73, 1.00, 1520.0], [0.41, 0.97, 2200.0]],
}

const STAR_PLANS := {
	"StarfallOutskirts": {
		"id": "starfall_outskirts", "entry_end": 1700.0, "entry_y": 400.0,
		"levels": [400.0, 755.0, 1110.0, 1465.0, 1820.0, 2175.0],
		"tone": Color(0.34, 0.36, 0.51), "mist": Color(0.15, 0.16, 0.29, 0.56),
		"motif": [430, 265, 470, 310, 395, 280, 450, 335, 410],
		"rise": [0, -18, -44, -10, 20, -23, 13, -37, 6], "gap": [60, 73, 49, 65, 52, 70],
		"feature_x": [2200, 3540, 5010, 1050, 2870, 4720],
	},
	"StarfallSilentGate": {
		"id": "starfall_silent_gate", "entry_end": 1760.0, "entry_y": 400.0,
		"levels": [400.0, 760.0, 1120.0, 1480.0, 1840.0, 2180.0],
		"tone": Color(0.34, 0.34, 0.56), "mist": Color(0.13, 0.12, 0.29, 0.58),
		"motif": [285, 445, 330, 485, 270, 420, 345, 465, 295],
		"rise": [0, 16, -28, -46, -8, 19, -24, 11, -37], "gap": [53, 74, 59, 67, 47, 71],
		"feature_x": [2050, 3900, 5280, 870, 2680, 4840],
	},
	"StarfallMemoryVault": {
		"id": "starfall_memory_vault", "entry_end": 1700.0, "entry_y": 400.0,
		"levels": [400.0, 755.0, 1110.0, 1465.0, 1820.0, 2175.0],
		"tone": Color(0.43, 0.43, 0.64), "mist": Color(0.20, 0.17, 0.36, 0.52),
		"motif": [475, 275, 405, 335, 460, 290, 420, 350, 390],
		"rise": [0, -31, -6, 21, -26, 7, -44, -12, 14], "gap": [70, 48, 65, 53, 73, 57],
		"feature_x": [2390, 3700, 5310, 1080, 2760, 4860],
	},
	"StarfallRootedHall": {
		"id": "starfall_rooted_hall", "entry_end": 1900.0, "entry_y": 400.0,
		"levels": [400.0, 770.0, 1130.0, 1490.0, 1850.0, 2190.0],
		"tone": Color(0.28, 0.48, 0.39), "mist": Color(0.12, 0.26, 0.20, 0.55),
		"motif": [350, 490, 270, 430, 315, 465, 295, 420, 365],
		"rise": [0, -42, -17, 12, -28, 18, -36, -5, 21], "gap": [64, 52, 72, 48, 68, 54],
		"feature_x": [2170, 3720, 5200, 920, 2920, 4900],
	},
	"StarfallSoulCrucible": {
		"id": "starfall_soul_crucible", "entry_end": 1880.0, "entry_y": 280.0,
		"levels": [440.0, 790.0, 1140.0, 1490.0, 1840.0, 2190.0],
		"tone": Color(0.49, 0.35, 0.58), "mist": Color(0.30, 0.13, 0.39, 0.56),
		"motif": [455, 285, 410, 365, 490, 265, 430, 315, 390],
		"rise": [0, 20, -19, -47, -11, 15, -30, 8, -38], "gap": [56, 72, 49, 66, 54, 70],
		"feature_x": [2270, 3900, 5160, 1010, 2850, 4720],
	},
	"StarfallSunlessPassage": {
		"id": "starfall_sunless_passage", "entry_end": 2000.0, "entry_y": 440.0,
		"levels": [440.0, 795.0, 1150.0, 1505.0, 1860.0, 2200.0],
		"tone": Color(0.34, 0.39, 0.59), "mist": Color(0.10, 0.11, 0.29, 0.61),
		"motif": [315, 465, 280, 425, 360, 485, 270, 410, 345],
		"rise": [0, -24, -46, -13, 19, -29, 8, -37, 17], "gap": [73, 52, 68, 47, 65, 55],
		"feature_x": [2360, 3860, 5300, 900, 2800, 4810],
	},
}


func _ready() -> void:
	room = get_parent() as Node2D
	if room == null or not STAR_PLANS.has(room.name):
		return
	plan = STAR_PLANS[room.name].duplicate(true)
	layout_width = STAR_WIDTH
	layout_height = STAR_HEIGHT
	var levels: Array = []
	for chamber_data in _layout_for_room():
		levels.append(float(chamber_data[2]))
	plan["levels"] = levels
	var motif: Array = plan["motif"]
	var widths: Array = []
	for tier in range(6):
		var rotation: Array = []
		for index in range(motif.size()):
			rotation.append(motif[(index + tier * 2) % motif.size()])
		widths.append(rotation)
	plan["widths"] = widths
	generated = Node2D.new()
	generated.name = "StarfallDescent"
	add_child(generated)
	if _use_schematic_editor_preview():
		# The shared world scene needs the authored room silhouettes too. A bare
		# topology overlay made these late-game areas look unfinished and empty.
		_paint_cavern()
		_build_chamber_foundations(false)
		_build_route_preview()
		_retire_covered_entry_floors()
		_relocate_route_portals()
		_build_starfall_dressing()
		return
	_extend_boundaries()
	_paint_cavern()
	_build_descent()
	_retire_covered_entry_floors()
	_relocate_existing_features()
	_relocate_route_portals()
	_build_return_lift()
	_build_starfall_dressing()
	if Engine.is_editor_hint():
		_spawn_authored_population()
		_relocate_existing_features()
		_relocate_route_portals()
	elif not _uses_world_population_streaming():
		call_deferred("activate_room_population")


func _build_starfall_dressing() -> void:
	var dressing := Node2D.new()
	dressing.set_script(preload("res://StarfallRouteDressing.gd"))
	dressing.name = "FieldDressing"
	dressing.set("region", String(room.name))
	add_child(dressing)


func _retire_covered_entry_floors() -> void:
	# The old court floor used to bridge straight across the new shaft mouth.
	# Retire only floors fully replaced by the first authored chamber, keeping
	# their scene nodes (and every existing lamp/marker) intact.
	var first := _chamber_rect(0)
	for node_name in ["Floor", "LeftFloor", "RightFloor"]:
		var body := room.get_node_or_null(node_name) as StaticBody2D
		if body == null:
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var center := generated.to_local(collision.global_position)
		var half: float = collision.shape.size.x * 0.5
		if absf(center.y - first.end.y) <= 1 and center.x - half >= first.position.x - 1 and center.x + half <= first.end.x + 1:
			collision.disabled = true
			body.collision_layer = 0
			body.hide()


func _spawn_authored_population() -> void:
	if room == null or not STAR_AUTHORED_POPULATION.has(String(room.name)):
		return
	var world_population: Node = room.get_parent().get_node_or_null("WorldPopulation") if room.get_parent() != null else null
	for entry in STAR_AUTHORED_POPULATION[String(room.name)]:
		var node_name := String(entry["name"])
		if room.has_node(node_name):
			continue
		if world_population != null and world_population.has_method("should_spawn_authored_actor") and not bool(world_population.call("should_spawn_authored_actor", String(room.name), node_name)):
			continue
		var actor := (entry["scene"] as PackedScene).instantiate() as Node2D
		actor.name = node_name
		actor.position = entry["position"]
		if AUTHORED_FLOOR_SLOTS.has(node_name):
			var slot: Array = AUTHORED_FLOOR_SLOTS[node_name]
			actor.position = _at(slot[0], slot[1], 0, 85 if entry["scene"] == SHADE else 33, 145)
		var properties: Dictionary = entry.get("properties", {})
		for property_name in properties:
			actor.set(StringName(property_name), properties[property_name])
		var child_properties: Dictionary = entry.get("child_properties", {})
		for child_path in child_properties:
			var child := actor.get_node_or_null(NodePath(child_path))
			if child == null:
				continue
			var overrides: Dictionary = child_properties[child_path]
			for property_name in overrides:
				child.set(StringName(property_name), overrides[property_name])
		actor.set_meta("authored_streamed_population", true)
		actor.set_meta("streamed_population_kind", "crate" if actor.is_in_group("breakable") else ("neutral" if actor.is_in_group("neutral_creature") else "enemy"))
		room.add_child(actor)
		if world_population != null and world_population.has_method("register_authored_actor"):
			world_population.call("register_authored_actor", String(room.name), actor)


func _layout_for_room() -> Array:
	return STAR_CHAMBER_LAYOUTS[room.name]


func _topology_caption() -> String:
	return room.name.to_snake_case().replace("_", " ").to_upper()


func _portal_anchor(tier: int, ratio: float, clearance: float = 33.0) -> Vector2:
	tier = clampi(tier, 0, _layout_for_room().size() - 1)
	var chamber := _chamber_rect(tier)
	var desired := lerpf(chamber.position.x + 55.0, chamber.end.x - 55.0, clampf(ratio, 0.0, 1.0))
	var anchor := generated.get_node("T%d_Bridge0" % tier) as Node2D
	# Both the door and its arrival marker (78 px to either side) need floor,
	# not merely a position inside the chamber's rectangular bounds.
	return _at(tier, 0, desired - anchor.position.x, clearance, 120)


func _place_portal(door_name: String, marker_name: String, tier: int, ratio: float, marker_side: float = 1.0) -> void:
	var door_at := _portal_anchor(tier, ratio)
	_move(door_name, door_at)
	if not marker_name.is_empty():
		_move(marker_name, door_at + Vector2(78.0 * marker_side, 0.0))


func _relocate_route_portals() -> void:
	# Keep the original scene doors, but bind them to the edges of the new
	# Starfall chambers. This also runs in the editor preview, where the old
	# coordinates previously left doors floating far outside the route.
	var last_tier := _layout_for_room().size() - 1
	match room.name:
		"StarfallOutskirts":
			_place_portal("CityReturnDoor", "Entry", 0, 0.03)
			_place_portal("RampartsDoor", "RampartsReturn", 3, 0.94, -1.0)
			_place_portal("SilentGateDoor", "SilentGateReturn", last_tier, 0.94, -1.0)
		"StarfallSilentGate":
			_place_portal("OuterReturnDoor", "Entry", 0, 0.03)
			_place_portal("VaultDoor", "VaultReturn", last_tier, 0.94, -1.0)
		"StarfallMemoryVault":
			_place_portal("SilentReturnDoor", "Entry", 0, 0.03)
			_place_portal("RootShortcutDoor", "RootShortcutReturn", 1, 0.91, -1.0)
			_place_portal("RootedHallDoor", "RootedReturn", last_tier, 0.94, -1.0)
		"StarfallRootedHall":
			_place_portal("VaultReturnDoor", "Entry", 0, 0.03)
			_place_portal("VaultShortcutDoor", "ShortcutReturn", 1, 0.91, -1.0)
			_place_portal("CourtDoor", "CourtReturn", last_tier, 0.94, -1.0)
		"StarfallSoulCrucible":
			_place_portal("CourtReturnDoor", "Entry", 0, 0.03)
			_place_portal("SunlessDoor", "SunlessReturn", last_tier, 0.94, -1.0)
		"StarfallSunlessPassage":
			_place_portal("CrucibleReturnDoor", "Entry", 0, 0.03)
			_place_portal("HollowThroneDoor", "ThroneReturn", last_tier, 0.94, -1.0)


func _paint_cavern() -> void:
	super._paint_cavern()
	var color: Color = plan["tone"]
	var shape_kind := room.name
	for tier in range(plan["levels"].size()):
		var y: float = plan["levels"][tier]
		var chamber := _chamber_rect(tier)
		var left := chamber.position.x
		var right := chamber.end.x
		var landmark_count := clampi(int((right - left) / 470.0), 2, 9)
		for index in range(landmark_count):
			var x := left + 105.0 + float(index) * (right - left - 210.0) / float(maxi(1, landmark_count - 1)) + float((tier * 19 + index * 13) % 35)
			var architecture := Polygon2D.new()
			architecture.name = "Identity%d_%d" % [tier, index]
			architecture.z_index = -5
			architecture.color = color.darkened(0.36 + 0.05 * float(index % 3))
			match shape_kind:
				"StarfallOutskirts":
					architecture.polygon = PackedVector2Array([Vector2(x - 75, y - 18), Vector2(x - 75, y - 165), Vector2(x - 55, y - 165), Vector2(x - 55, y - 207), Vector2(x + 50, y - 207), Vector2(x + 50, y - 165), Vector2(x + 74, y - 165), Vector2(x + 74, y - 18)])
				"StarfallSilentGate":
					architecture.polygon = PackedVector2Array([Vector2(x - 95, y - 15), Vector2(x - 75, y - 236), Vector2(x, y - 264), Vector2(x + 78, y - 236), Vector2(x + 95, y - 15), Vector2(x + 38, y - 15), Vector2(x + 31, y - 170), Vector2(x - 31, y - 170), Vector2(x - 38, y - 15)])
				"StarfallMemoryVault":
					architecture.polygon = PackedVector2Array([Vector2(x - 74, y - 14), Vector2(x - 54, y - 198), Vector2(x, y - 265), Vector2(x + 54, y - 198), Vector2(x + 74, y - 14), Vector2(x + 23, y - 45), Vector2(x, y - 146), Vector2(x - 23, y - 45)])
				"StarfallRootedHall":
					architecture.polygon = PackedVector2Array([Vector2(x - 113, y - 18), Vector2(x - 71, y - 104), Vector2(x - 89, y - 220), Vector2(x - 29, y - 260), Vector2(x + 10, y - 158), Vector2(x + 64, y - 251), Vector2(x + 105, y - 201), Vector2(x + 55, y - 64), Vector2(x + 111, y - 18)])
				"StarfallSoulCrucible":
					architecture.polygon = PackedVector2Array([Vector2(x - 82, y - 18), Vector2(x - 82, y - 178), Vector2(x - 58, y - 178), Vector2(x - 40, y - 247), Vector2(x + 39, y - 247), Vector2(x + 58, y - 178), Vector2(x + 82, y - 178), Vector2(x + 82, y - 18)])
				_:
					architecture.polygon = PackedVector2Array([Vector2(x - 99, y - 15), Vector2(x - 61, y - 164), Vector2(x - 21, y - 228), Vector2(x + 20, y - 199), Vector2(x + 56, y - 266), Vector2(x + 100, y - 15)])
			generated.add_child(architecture)
			if shape_kind in ["StarfallRootedHall", "StarfallSoulCrucible"]:
				var tendril := Line2D.new()
				tendril.name = "Tendril%d_%d" % [tier, index]
				tendril.z_index = -4
				tendril.width = 4.0
				tendril.default_color = _alpha(color.lightened(0.3), 0.52)
				tendril.points = PackedVector2Array([Vector2(x, y - 250), Vector2(x - 30, y - 155), Vector2(x + 17, y - 63)])
				generated.add_child(tendril)
	_paint_starfall_identity()


func _paint_starfall_identity() -> void:
	var profile: Dictionary = STAR_IDENTITIES[room.name]
	var identity := Node2D.new()
	identity.name = "RoomIdentity"
	identity.z_index = -2
	identity.set_meta("identity_title", String(profile["title"]))
	identity.set_meta("identity_motif", String(profile["motif"]))
	generated.add_child(identity)
	var title := Label.new()
	title.name = "IdentityTitle"
	title.position = Vector2(125.0, 82.0)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", _alpha((plan["tone"] as Color).lightened(0.47), 0.78))
	title.text = String(profile["title"])
	identity.add_child(title)
	match room.name:
		"StarfallOutskirts":
			_paint_outskirts_identity(identity)
		"StarfallSilentGate":
			_paint_silent_gate_identity(identity)
		"StarfallMemoryVault":
			_paint_memory_vault_identity(identity)
		"StarfallRootedHall":
			_paint_rooted_hall_identity(identity)
		"StarfallSoulCrucible":
			_paint_soul_crucible_identity(identity)
		"StarfallSunlessPassage":
			_paint_sunless_identity(identity)


func _star_anchor(identity: Node2D, anchor_name: String, kind: String) -> Node2D:
	var anchor := Node2D.new()
	anchor.name = anchor_name
	anchor.set_meta("landmark_kind", kind)
	identity.add_child(anchor)
	return anchor


func _star_polygon(parent: Node, node_name: String, points: PackedVector2Array, color: Color, z: int = -1) -> Polygon2D:
	var shape := Polygon2D.new()
	shape.name = node_name
	shape.polygon = points
	shape.color = color
	shape.z_index = z
	parent.add_child(shape)
	return shape


func _star_line(parent: Node, node_name: String, points: PackedVector2Array, color: Color, width: float = 4.0) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	parent.add_child(line)
	return line


func _star_circle(center: Vector2, radius: float, count: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _paint_outskirts_identity(identity: Node2D) -> void:
	var barricades := _star_anchor(identity, "SiegeBarricades", "gate_siege")
	for tier in range(6):
		var y: float = plan["levels"][tier]
		var x := 1120.0 + float((tier * 947) % 4200)
		_star_polygon(barricades, "StakeWall%d" % tier, PackedVector2Array([
			Vector2(x - 145, y - 8), Vector2(x - 103, y - 92), Vector2(x - 55, y - 29),
			Vector2(x, y - 110), Vector2(x + 58, y - 31), Vector2(x + 106, y - 88), Vector2(x + 148, y - 8),
		]), Color(0.22, 0.20, 0.31, 0.89), 1)
	var caravans := _star_anchor(identity, "BrokenCaravans", "abandoned_muster")
	for index in range(4):
		var tier := index + 1
		var x := 1760.0 + float(index) * 930.0
		var y: float = plan["levels"][tier]
		_star_polygon(caravans, "Wagon%d" % index, PackedVector2Array([Vector2(x - 115, y - 18), Vector2(x - 88, y - 104), Vector2(x + 92, y - 104), Vector2(x + 126, y - 18)]), Color(0.25, 0.23, 0.37, 0.68))
		_star_polygon(caravans, "Wheel%d" % index, _star_circle(Vector2(x + 72, y - 18), 37.0, 12), Color(0.43, 0.39, 0.55, 0.61), 1)


func _paint_silent_gate_identity(identity: Node2D) -> void:
	var gates := _star_anchor(identity, "WardedGateArches", "silent_wards")
	for tier in range(6):
		var y: float = plan["levels"][tier]
		var x := 1230.0 + float((tier * 887) % 4050)
		_star_polygon(gates, "SealedArch%d" % tier, PackedVector2Array([
			Vector2(x - 150, y - 12), Vector2(x - 126, y - 244), Vector2(x, y - 310),
			Vector2(x + 126, y - 244), Vector2(x + 150, y - 12), Vector2(x + 84, y - 12),
			Vector2(x + 68, y - 196), Vector2(x, y - 235), Vector2(x - 68, y - 196), Vector2(x - 84, y - 12),
		]), Color(0.19, 0.17, 0.39, 0.79))
		for bar in range(3):
			var bx := x - 42.0 + float(bar) * 42.0
			_star_line(gates, "WardBar%d_%d" % [tier, bar], PackedVector2Array([Vector2(bx, y - 26), Vector2(bx, y - 203)]), Color(0.51, 0.48, 0.85, 0.56), 5.0)
	var bells := _star_anchor(identity, "MuteBells", "silenced_bells")
	for index in range(5):
		var x := 1550.0 + float(index) * 940.0
		var y: float = plan["levels"][index + 1] - 72.0
		_star_line(bells, "CutRope%d" % index, PackedVector2Array([Vector2(x, y - 205), Vector2(x - 8, y - 96)]), Color(0.51, 0.48, 0.69, 0.38), 3.0)
		_star_polygon(bells, "MuteBell%d" % index, PackedVector2Array([Vector2(x - 48, y - 94), Vector2(x - 34, y - 35), Vector2(x + 34, y - 35), Vector2(x + 48, y - 94), Vector2(x, y - 127)]), Color(0.38, 0.35, 0.59, 0.52), 1)


func _paint_memory_vault_identity(identity: Node2D) -> void:
	var archive := _star_anchor(identity, "MemoryMonoliths", "memory_archive")
	for tier in range(6):
		var y: float = plan["levels"][tier]
		for column in range(2):
			var x := 1380.0 + float(column) * 2480.0 + float((tier * 367) % 760)
			_star_polygon(archive, "Monolith%d_%d" % [tier, column], PackedVector2Array([
				Vector2(x - 62, y - 16), Vector2(x - 50, y - 224), Vector2(x, y - 294),
				Vector2(x + 50, y - 224), Vector2(x + 62, y - 16),
			]), Color(0.33, 0.29, 0.55, 0.73))
			_star_line(archive, "Inscription%d_%d" % [tier, column], PackedVector2Array([
				Vector2(x - 27, y - 184), Vector2(x + 23, y - 157), Vector2(x - 18, y - 126), Vector2(x + 29, y - 89),
			]), Color(0.72, 0.68, 0.98, 0.64), 4.0)
	var ribbons := _star_anchor(identity, "MemoryRibbons", "echo_records")
	for index in range(7):
		var y: float = plan["levels"][index % 6] - 125.0
		var x := 1050.0 + float(index) * 720.0
		_star_line(ribbons, "Record%d" % index, PackedVector2Array([Vector2(x, y), Vector2(x + 115, y - 44), Vector2(x + 245, y + 17), Vector2(x + 360, y - 26)]), Color(0.70, 0.61, 0.95, 0.34), 5.0)


func _paint_rooted_hall_identity(identity: Node2D) -> void:
	var roots := _star_anchor(identity, "AncientRootNetwork", "living_roots")
	for tier in range(6):
		var y: float = plan["levels"][tier]
		for branch in range(3):
			var x := 780.0 + float(branch) * 1950.0 + float((tier * 211) % 510)
			_star_line(roots, "Root%d_%d" % [tier, branch], PackedVector2Array([
				Vector2(x - 140, y - 260), Vector2(x - 52, y - 188), Vector2(x + 24, y - 112), Vector2(x + 148, y - 8),
			]), Color(0.24, 0.56, 0.38, 0.58), 11.0)
			_star_line(roots, "RootFork%d_%d" % [tier, branch], PackedVector2Array([Vector2(x - 52, y - 188), Vector2(x + 72, y - 246)]), Color(0.31, 0.66, 0.44, 0.42), 6.0)
	var hearts := _star_anchor(identity, "RootHearts", "living_growth")
	for index in range(5):
		var y: float = plan["levels"][index + 1] - 95.0
		var x := 1520.0 + float(index) * 910.0
		_star_polygon(hearts, "RootHeart%d" % index, _star_circle(Vector2(x, y), 44.0, 13), Color(0.27, 0.75, 0.50, 0.49), 1)


func _paint_soul_crucible_identity(identity: Node2D) -> void:
	var vats := _star_anchor(identity, "SoulVats", "unstable_crucible")
	for tier in range(6):
		var y: float = plan["levels"][tier]
		var x := 1320.0 + float((tier * 991) % 4200)
		_star_polygon(vats, "Crucible%d" % tier, PackedVector2Array([
			Vector2(x - 118, y - 14), Vector2(x - 92, y - 184), Vector2(x - 55, y - 224),
			Vector2(x + 55, y - 224), Vector2(x + 92, y - 184), Vector2(x + 118, y - 14),
		]), Color(0.35, 0.20, 0.47, 0.84))
		_star_polygon(vats, "SoulCore%d" % tier, _star_circle(Vector2(x, y - 112), 48.0, 14), Color(0.72, 0.34, 0.88, 0.61), 1)
	var conduits := _star_anchor(identity, "SoulConduits", "energy_network")
	for tier in range(6):
		var y: float = plan["levels"][tier] - 82.0
		_star_line(conduits, "Conduit%d" % tier, PackedVector2Array([Vector2(420, y), Vector2(1840, y - 33), Vector2(3370, y + 24), Vector2(6040, y - 12)]), Color(0.73, 0.35, 0.92, 0.47), 7.0)


func _paint_sunless_identity(identity: Node2D) -> void:
	var curtains := _star_anchor(identity, "ShadowCurtains", "living_darkness")
	for tier in range(6):
		var y: float = plan["levels"][tier]
		for index in range(5):
			var x := 760.0 + float(index) * 1210.0 + float((tier * 157) % 280)
			_star_polygon(curtains, "Curtain%d_%d" % [tier, index], PackedVector2Array([
				Vector2(x - 138, y - 310), Vector2(x + 125, y - 310), Vector2(x + 92, y - 20),
				Vector2(x + 31, y - 74), Vector2(x - 38, y - 17), Vector2(x - 102, y - 91),
			]), Color(0.035, 0.035, 0.12, 0.77))
	var lights := _star_anchor(identity, "ExtinguishedLanterns", "last_light")
	for index in range(9):
		var tier := index % 6
		var x := 910.0 + float(index) * 620.0
		var y: float = plan["levels"][tier] - 118.0
		_star_line(lights, "LanternChain%d" % index, PackedVector2Array([Vector2(x, y - 115), Vector2(x, y - 23)]), Color(0.34, 0.39, 0.65, 0.37), 2.0)
		_star_polygon(lights, "Lantern%d" % index, _star_circle(Vector2(x, y), 22.0, 10), Color(0.52, 0.62, 0.96, 0.24 if index % 3 else 0.62), 1)


func _at(tier: int, segment: int, offset_x: float = 0.0, clearance: float = 33.0, edge_margin: float = 40.0) -> Vector2:
	var plank := generated.get_node("T%d_Bridge%d" % [tier, segment]) as StaticBody2D
	var desired := plank.position.x + offset_x
	var best := Vector2.INF
	var distance := INF
	# Bridge nodes mark design intent, not solid terrain. Keep the original
	# spread along each corridor, but clamp away from shafts and outer edges.
	for body in generated.get_children():
		if not String(body.name).begins_with("Chamber%d_Floor" % tier):
			continue
		var collision := body.get_node("CollisionShape2D") as CollisionShape2D
		var half := (collision.shape as RectangleShape2D).size.x * 0.5
		if half < edge_margin + 12:
			continue
		var x := clampf(desired, body.position.x - half + edge_margin, body.position.x + half - edge_margin)
		if absf(x - desired) < distance:
			distance = absf(x - desired)
			best = Vector2(x, body.position.y - clearance)
	assert(best.is_finite(), "Missing supported Starfall anchor: %s/%d" % [room.name, tier])
	return best


func _relocate_existing_features() -> void:
	var final_chamber := _chamber_rect(_layout_for_room().size() - 1)
	var bottom := final_chamber.end.y - 33.0
	var final_left := final_chamber.position.x + 45.0
	match room.name:
		"StarfallOutskirts":
			_move("SilentGateDoor", Vector2(final_left, bottom))
			_move("SilentGateReturn", Vector2(final_left + 70.0, bottom))
			_move("RampartsDoor", Vector2(6290, 367))
			_move("RampartsReturn", Vector2(6220, 367))
		"StarfallSilentGate":
			_move("VaultDoor", Vector2(final_left, bottom))
			_move("VaultReturn", Vector2(final_left + 70.0, bottom))
			_move("HighRelay", _at(1, 8))
			_move("LowRelay", _at(4, 4))
			_move("UpperCache", _at(1, 8, -155))
		"StarfallMemoryVault":
			_move("RootedHallDoor", Vector2(final_left, bottom))
			_move("RootedReturn", Vector2(final_left + 70.0, bottom))
			_move("RootShortcutDoor", _at(1, 8, 95))
			_move("RootShortcutReturn", _at(1, 8, 20))
			_move("BridgeCache", _at(1, 8, -100))
			_move("PitCache", _at(3, 4, 130))
		"StarfallRootedHall":
			_move("CourtDoor", Vector2(final_left, bottom))
			_move("CourtReturn", Vector2(final_left + 70.0, bottom))
			_move("RootControl", _at(1, 8))
			_move("VaultShortcutDoor", _at(1, 8, 210))
			_move("ShortcutReturn", _at(1, 8, 145))
			_move("HighCache", _at(1, 8, -115))
			_move("SecondSnare", _at(3, 4))
		"StarfallSoulCrucible":
			_move("SunlessDoor", Vector2(final_left, bottom))
			_move("SunlessReturn", Vector2(final_left + 70.0, bottom))
			_move("HighChannel", _at(1, 8))
			_move("LowChannel", _at(4, 4))
			_move("StabilizedCache", _at(4, 4, 155))
			_move("CircuitStatus", _at(1, 8, -170, 135))
		"StarfallSunlessPassage":
			_move("HollowThroneDoor", Vector2(final_left, bottom))
			_move("ThroneReturn", Vector2(final_left + 70.0, bottom))
			_move("DawnAnchor", Vector2(final_left + 260.0, bottom))
			var crest := generated.get_node("Niche4_Crest") as StaticBody2D
			_move("DawnCache", crest.position + Vector2(65, -33))
			_move("BasinCache", _at(2, 6))


func _build_return_lift() -> void:
	var id: String = plan["id"]
	var final_chamber := _chamber_rect(_layout_for_room().size() - 1)
	var bottom_y := final_chamber.end.y - 32.0
	var top_y := float(plan["entry_y"]) - 32.0
	var top_x := 205.0 if room.name == "StarfallSoulCrucible" else (260.0 if room.name == "StarfallSunlessPassage" else 390.0)
	var landing_left := final_chamber.end.x - 360.0
	var bottom_lift_x := final_chamber.end.x - 235.0
	_platform("ReturnLiftLanding", landing_left, final_chamber.end.x - 45.0, bottom_y + 32.0, (plan["tone"] as Color).lightened(0.25), false, 18.0)
	for below in [false, true]:
		var marker := Marker2D.new()
		marker.name = "LiftBottomMarker" if below else "LiftTopMarker"
		marker.position = Vector2(bottom_lift_x - 85.0, bottom_y) if below else Vector2(top_x + 60, top_y)
		marker.add_to_group("%s_lift_bottom" % id if below else "%s_lift_top" % id)
		generated.add_child(marker)
		var lift := STAR_LIFT.instantiate()
		lift.name = "ReturnLiftBottom" if below else "ReturnLiftTop"
		lift.position = Vector2(bottom_lift_x, bottom_y) if below else Vector2(top_x, top_y)
		lift.shortcut_id = "%s_return_lift" % id
		lift.room_id = id
		lift.target_marker_group = StringName("%s_lift_top" % id) if below else StringName("%s_lift_bottom" % id)
		lift.activates_shortcut = below
		lift.enemy_group = &"enemy"
		lift.enemy_block_radius = 70.0
		lift.lift_label = "STARFALL LIFT"
		generated.add_child(lift)


func _populate_descent() -> void:
	var id: String = plan["id"]
	var profile: Dictionary = STAR_IDENTITIES[room.name]
	var fauna_names: Array = profile["fauna"]
	for tier in range(6):
		for slot in range(2):
			var foe_name := "DepthFoe%d_%d" % [tier, slot]
			if generated.has_node(foe_name):
				continue
			var scene: PackedScene = _identity_enemy_scene(tier, slot)
			var foe := scene.instantiate() as Node2D
			foe.name = foe_name
			foe.position = _at(tier, 2 if slot == 0 else 8, 0, 85 if scene == SHADE else 31, 145)
			foe.set("zone_id", "starfall_reach")
			foe.set_meta("encounter_motif", String(profile["motif"]))
			_add_streamed_generated_actor(foe)
		for slot in range(2):
			var crate_name := "DepthCrate%d_%d" % [tier, slot]
			if generated.has_node(crate_name):
				continue
			var crate := STAR_CRATE.instantiate() as Node2D
			crate.name = crate_name
			crate.position = _at(tier, 3 if slot == 0 else 7, 0, 31)
			crate.set("empty_drop_chance", 0.36)
			_add_streamed_generated_actor(crate)
		if tier > 0:
			var fauna_name := "DepthFauna%d" % tier
			if generated.has_node(fauna_name):
				continue
			var fauna := STAR_FAUNA.instantiate() as Node2D
			fauna.name = fauna_name
			fauna.position = _at(tier, 5, 0, 31, 145)
			fauna.set("creature_name", String(fauna_names[tier % fauna_names.size()]))
			fauna.set("zone_id", "starfall_reach")
			_add_streamed_generated_actor(fauna)
	for branch_tier in [1, 3, 5]:
		var chamber := generated.get_node("Branch%d_Chamber" % branch_tier) as StaticBody2D
		var branch_crate_name := "BranchCrate%d" % branch_tier
		if not generated.has_node(branch_crate_name):
			var branch_crate := STAR_CRATE.instantiate() as Node2D
			branch_crate.name = branch_crate_name
			branch_crate.position = chamber.position + Vector2(105.0, -31.0)
			branch_crate.set("empty_drop_chance", 0.4)
			_add_streamed_generated_actor(branch_crate)
		if branch_tier == 1:
			if not generated.has_node("BranchFauna"):
				var creature := STAR_FAUNA.instantiate() as Node2D
				creature.name = "BranchFauna"
				creature.position = chamber.position + Vector2(-105.0, -31.0)
				creature.set("creature_name", String(fauna_names[0]))
				creature.set("zone_id", "starfall_reach")
				creature.set("start_resting", true)
				_add_streamed_generated_actor(creature)
		else:
			var guard_name := "BranchGuard%d" % branch_tier
			if not generated.has_node(guard_name):
				var branch_scene: PackedScene = _identity_enemy_scene(branch_tier, 1)
				var branch_guard := branch_scene.instantiate() as Node2D
				branch_guard.name = guard_name
				branch_guard.position = chamber.position + Vector2(-105.0, -82.0 if branch_scene == SHADE else -31.0)
				branch_guard.set("zone_id", "starfall_reach")
				_add_streamed_generated_actor(branch_guard)
	if not generated.has_node("HiddenStarCache"):
		var treasure := STAR_CACHE.instantiate() as Node2D
		var crest := generated.get_node("Niche4_Crest") as StaticBody2D
		treasure.name = "HiddenStarCache"
		treasure.position = crest.position + Vector2(-55, -37)
		treasure.set("cache_id", "%s_hidden_depth" % id)
		treasure.set("cache_name", String(profile["cache"]))
		treasure.set("gold_reward", int(profile["gold"]))
		treasure.set("reward_item_id", String(profile["reward"]))
		treasure.set_meta("identity_motif", String(profile["motif"]))
		if FIELD_OPERATIONS.PROFILES.has(String(room.name)):
			treasure.set("required_event_ids", PackedStringArray([id + "_field_complete", id + "_niche_cleared"]))
		generated.add_child(treasure)
	_populate_starfall_identity()
	if FIELD_OPERATIONS.PROFILES.has(String(room.name)) and not generated.has_node("FieldOperations"):
		var operations := Node2D.new()
		operations.set_script(FIELD_OPERATIONS)
		operations.name = "FieldOperations"
		operations.set("route", self)
		generated.add_child(operations)


func _identity_enemy_scene(tier: int, slot: int) -> PackedScene:
	match room.name:
		"StarfallOutskirts":
			# A fortified approach: sentries hold the long lanes while a few
			# stalkers pressure the broken wagon cover.
			return STALKER if tier in [1, 4] and slot == 1 else SENTRY
		"StarfallSilentGate":
			return SHADE if tier in [1, 3, 5] and slot == 0 else SENTRY
		"StarfallMemoryVault":
			return STALKER if tier in [2, 5] and slot == 1 else (SENTRY if tier in [1, 4] and slot == 1 else SHADE)
		"StarfallRootedHall":
			return SHADE if tier in [1, 4] and slot == 0 else STALKER
		"StarfallSoulCrucible":
			var cycle := (tier * 2 + slot) % 3
			return SHADE if cycle == 0 else (SENTRY if cycle == 1 else STALKER)
		"StarfallSunlessPassage":
			return STALKER if tier in [2, 5] and slot == 1 else SHADE
		_:
			return STALKER


func _populate_starfall_identity() -> void:
	match room.name:
		"StarfallOutskirts":
			_spawn_starfall_props("SiegeSupply", [0, 1, 2, 4, 5], 6, 0.28)
		"StarfallSilentGate":
			_spawn_starfall_props("WardObstruction", [0, 2, 3, 5], 5, 0.55)
		"StarfallMemoryVault":
			_spawn_archive_rewards()
		"StarfallRootedHall":
			_spawn_root_grazers()
		"StarfallSoulCrucible":
			_spawn_star_surges("SoulSurge", "starfall_crucible_stabilized", Color(1.0, 0.48, 1.0, 0.92))
		"StarfallSunlessPassage":
			_spawn_star_surges("VoidPulse", "starfall_sunless_anchor", Color(0.48, 0.55, 1.0, 0.86))
	_spawn_hidden_star_ambush()


func _spawn_hidden_star_ambush() -> void:
	if generated.has_node("HiddenStarAmbush"):
		return
	var crest := generated.get_node("Niche4_Crest") as StaticBody2D
	var first_scene := _identity_enemy_scene(4, 0)
	var second_scene := _identity_enemy_scene(4, 1)
	var encounter := LOCAL_ENCOUNTER.instantiate() as Area2D
	encounter.name = "HiddenStarAmbush"
	encounter.position = crest.position
	encounter.set("encounter_id", "%s_hidden_star" % String(plan["id"]))
	encounter.set("zone_id", "starfall_reach")
	if FIELD_OPERATIONS.PROFILES.has(String(room.name)):
		encounter.set("completion_event_id", String(plan["id"]) + "_niche_cleared")
		encounter.set("encounter_title", "UPPER RESERVE GUARDIANS")
	encounter.get("enemy_scenes").append(first_scene)
	encounter.get("enemy_scenes").append(second_scene)
	encounter.get("spawn_offsets").append(Vector2(-115.0, -86.0 if first_scene == SHADE else -31.0))
	encounter.get("spawn_offsets").append(Vector2(115.0, -86.0 if second_scene == SHADE else -31.0))
	generated.add_child(encounter)


func _spawn_starfall_props(prefix: String, tiers: Array, segment: int, empty_chance: float) -> void:
	for index in range(tiers.size()):
		var tier: int = int(tiers[index])
		var prop_name := "%s%d" % [prefix, index]
		if generated.has_node(prop_name):
			continue
		var prop := STAR_CRATE.instantiate() as Node2D
		prop.name = prop_name
		prop.position = _at(tier, segment, 0, 31)
		prop.set("empty_drop_chance", empty_chance)
		prop.set_meta("identity_prop", String(STAR_IDENTITIES[room.name]["motif"]))
		_add_streamed_generated_actor(prop)


func _spawn_archive_rewards() -> void:
	for index in range(3):
		var tier := 1 + index * 2
		var plank := generated.get_node("Branch%d_Chamber" % tier) as StaticBody2D
		var archive_name := "SealedRecord%d" % index
		var event_id := "starfall_memory_vault_record_%d" % index
		var state := get_node("/root/GameState")
		if generated.has_node(archive_name) or bool(state.unlocked_shortcuts.get(event_id, false)):
			continue
		var archive := STAR_CRATE.instantiate() as Node2D
		archive.name = archive_name
		archive.position = plank.position + Vector2(0.0, -31.0)
		archive.set("empty_drop_chance", 0.0 if index == 2 else 0.25)
		archive.set_meta("identity_prop", "memory_record")
		archive.connect("destroyed", Callable(state, "unlock_shortcut").bind(event_id))
		var label := Label.new()
		label.position = Vector2(-100, -62)
		label.size = Vector2(200, 40)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.text = "SEALED RECORD %d/3 - BREAK TO RECOVER" % (index + 1)
		archive.add_child(label)
		_add_streamed_generated_actor(archive)


func _spawn_root_grazers() -> void:
	for index in range(3):
		var tier := 1 + index * 2
		var fauna_name := "RootSanctuaryFauna%d" % index
		if generated.has_node(fauna_name):
			continue
		var fauna := STAR_FAUNA.instantiate() as Node2D
		fauna.name = fauna_name
		fauna.position = _at(tier, 6, 0, 31, 145)
		fauna.set("creature_name", "Rootling" if index < 2 else "Ancient Grazer")
		fauna.set("zone_id", "starfall_reach")
		_add_streamed_generated_actor(fauna)


func _spawn_star_surges(prefix: String, disabled_event: String, tint: Color) -> void:
	# Foes use bridges 2/8 and ordinary crates use 3/7. These clear lanes keep
	# each telegraph visible and leave a safe platform between pulses.
	var placements := [[0, 5], [1, 4], [2, 6], [3, 5], [4, 4], [5, 6]]
	for index in range(placements.size()):
		var surge_name := "%s%d" % [prefix, index]
		if generated.has_node(surge_name):
			continue
		var tier: int = int(placements[index][0])
		var plank := generated.get_node("T%d_Bridge%d" % [tier, int(placements[index][1])]) as StaticBody2D
		var surge := STAR_SURGE.instantiate() as Node2D
		surge.name = surge_name
		surge.position = plank.position + Vector2(0.0, -18.0)
		# Bridge nodes are semantic positions inside a continuous chamber floor;
		# the hazard width follows that chamber instead of an old platform piece.
		var chamber_width := _chamber_rect(tier).size.x
		surge.scale.x = clampf(chamber_width / 1850.0, 0.60, 1.0)
		surge.modulate = tint
		surge.set("zone_id", "starfall_reach")
		surge.set("disabled_by_shortcut_id", disabled_event)
		if prefix == "VoidPulse":
			surge.set("additional_disabled_event_ids", PackedStringArray(["starfall_sunless_passage_beacon_%d" % (index / 2)]))
		# Keep hazard lanes on real floors, not semantic anchors over shafts.
		surge.position = FIELD_OPERATIONS.floor_point(self, tier) + Vector2(0, 16)
		surge.set("idle_duration", 1.95 if prefix == "VoidPulse" else 1.55)
		surge.set("warning_duration", 0.78)
		generated.add_child(surge)
