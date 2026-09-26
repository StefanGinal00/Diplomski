@tool
extends Node2D

# Curated placements add life to established rooms without moving any existing
# door, puzzle, boss or save marker. The plant silhouettes also preview in the
# Game scene editor; combatants and loot are only instantiated during play.
const CRATE_SCENE: PackedScene = preload("res://DestructibleCrate.tscn")
const NEUTRAL_SCENE: PackedScene = preload("res://NeutralCreature.tscn")
const WORLD_LAYOUT = preload("res://WorldLayout.gd")
const ROOM_UNLOAD_GRACE_SECONDS := 10.0
const FOES := {
	"crawler": preload("res://ShaftCrawler.tscn"),
	"wisp": preload("res://ShaftWisp.tscn"),
	"sentry": preload("res://ShaftSentry.tscn"),
	"shade": preload("res://EchoShade.tscn"),
	"brood": preload("res://EchoBroodling.tscn"),
	"fiend": preload("res://AshFiend.tscn"),
	"ash_sentry": preload("res://AshSentry.tscn"),
	"stalker": preload("res://RootStalker.tscn"),
}
const ROOMS := {
	"ShaftHollow": {"zone": "sunken_shaft", "tint": Color(0.24, 0.65, 0.68), "foes": [["crawler", Vector2(630, 305)]], "fauna": [["Cave Grazer", Vector2(375, 305)]], "crates": [Vector2(605, 302)], "growth": [Vector2(340, 303), Vector2(530, 303)]},
	"DrownedCrossing": {"zone": "sunken_shaft", "tint": Color(0.22, 0.59, 0.73), "foes": [["crawler", Vector2(550, 329)]], "fauna": [], "crates": [Vector2(230, 329)], "growth": [Vector2(285, 327), Vector2(775, 327)]},
	"FloodedGallery": {"zone": "sunken_shaft", "tint": Color(0.24, 0.62, 0.75), "foes": [["sentry", Vector2(535, 347)]], "fauna": [], "crates": [Vector2(580, 344)], "growth": [Vector2(310, 345), Vector2(625, 345)]},
	"EchoGrotto": {"zone": "echo_grotto", "tint": Color(0.35, 0.78, 0.78), "foes": [["shade", Vector2(750, 130)]], "fauna": [["Glow Moth", Vector2(350, 137)]], "crates": [Vector2(455, 136)], "growth": [Vector2(345, 135), Vector2(720, 135)]},
	"EchoGallery": {"zone": "echo_grotto", "tint": Color(0.34, 0.77, 0.8), "foes": [["shade", Vector2(695, 135)]], "fauna": [["Cave Moth", Vector2(205, 135)]], "crates": [Vector2(395, 136)], "growth": [Vector2(290, 135), Vector2(665, 135)]},
	"PrismArchive": {"zone": "echo_grotto", "tint": Color(0.42, 0.68, 0.89), "foes": [["shade", Vector2(555, 135)]], "fauna": [], "crates": [Vector2(335, 136)], "growth": [Vector2(305, 132), Vector2(775, 132)]},
	"EchoNest": {"zone": "echo_grotto", "tint": Color(0.45, 0.7, 0.72), "foes": [["brood", Vector2(720, 146)]], "fauna": [], "crates": [Vector2(365, 146)], "growth": [Vector2(215, 144), Vector2(685, 144)]},
	"EchoHavenOutskirts": {"zone": "echo_grotto", "tint": Color(0.31, 0.81, 0.67), "foes": [["wisp", Vector2(440, 65)]], "fauna": [["Lantern Moth", Vector2(720, 142)]], "crates": [Vector2(525, 136)], "growth": [Vector2(480, 152), Vector2(870, 152)]},
	"BrokenCauseway": {"zone": "ashen_bastion", "tint": Color(0.84, 0.43, 0.24), "foes": [["fiend", Vector2(555, 357)], ["ash_sentry", Vector2(970, 357)]], "fauna": [], "crates": [Vector2(615, 357)], "growth": [Vector2(355, 355), Vector2(935, 355)]},
	"CinderForge": {"zone": "ashen_bastion", "tint": Color(0.86, 0.45, 0.25), "foes": [["fiend", Vector2(550, 387)]], "fauna": [], "crates": [Vector2(325, 387)], "growth": [Vector2(355, 385), Vector2(780, 385)]},
	"EmberBarracks": {"zone": "ashen_bastion", "tint": Color(0.78, 0.39, 0.23), "foes": [["fiend", Vector2(1040, 387)]], "fauna": [], "crates": [Vector2(495, 387)], "growth": [Vector2(410, 385), Vector2(1000, 385)]},
	"AshChapel": {"zone": "ashen_bastion", "tint": Color(0.89, 0.44, 0.28), "foes": [["fiend", Vector2(990, 387)]], "fauna": [], "crates": [Vector2(405, 387)], "growth": [Vector2(365, 385), Vector2(940, 385)]},
	"CinderHearthOutskirts": {"zone": "ashen_bastion", "tint": Color(0.8, 0.52, 0.29), "foes": [["fiend", Vector2(510, 357)]], "fauna": [["Ash Grazer", Vector2(900, 371)]], "crates": [Vector2(750, 357)], "growth": [Vector2(490, 354), Vector2(900, 354)]},
	"StarfallOutskirts": {"zone": "starfall_reach", "tint": Color(0.63, 0.61, 0.86), "foes": [["shade", Vector2(555, 367)], ["stalker", Vector2(1100, 367)]], "fauna": [["Dusk Moth", Vector2(420, 367)]], "crates": [Vector2(715, 367)], "growth": [Vector2(480, 364), Vector2(1200, 364)]},
	"StarfallSilentGate": {"zone": "starfall_reach", "tint": Color(0.59, 0.62, 0.8), "foes": [["shade", Vector2(375, 367)]], "fauna": [], "crates": [Vector2(940, 367)], "growth": [Vector2(495, 364), Vector2(1500, 364)]},
	"StarfallMemoryVault": {"zone": "starfall_reach", "tint": Color(0.61, 0.59, 0.81), "foes": [["shade", Vector2(555, 587)]], "fauna": [], "crates": [Vector2(1160, 367)], "growth": [Vector2(630, 584), Vector2(1260, 364)]},
	"StarfallRootedHall": {"zone": "starfall_reach", "tint": Color(0.4, 0.73, 0.64), "foes": [["stalker", Vector2(385, 370)], ["stalker", Vector2(1200, 370)]], "fauna": [["Root Grazer", Vector2(480, 370)]], "crates": [Vector2(1030, 367)], "growth": [Vector2(470, 364), Vector2(1140, 364)]},
}

var populated_rooms: Dictionary = {}
var room_snapshots: Dictionary = {}
var authored_actor_states: Dictionary = {}
var pending_unloads: Dictionary = {}
var active_room_name := ""
var game_state: Node


func _ready() -> void:
	for room_name in ROOMS:
		var room := get_parent().get_node_or_null(room_name) as Node2D
		if room == null:
			continue
		var data: Dictionary = ROOMS[room_name]
		_build_growth(room, data)
	if Engine.is_editor_hint():
		return
	game_state = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.room_changed.connect(_on_room_changed)
		game_state.mode_changed.connect(_on_mode_changed)
		_on_room_changed(str(game_state.current_room_id))


func _on_mode_changed(_mode: String) -> void:
	populated_rooms.clear()
	room_snapshots.clear()
	authored_actor_states.clear()
	pending_unloads.clear()
	active_room_name = ""
	# Starting a new run rebuilds Game.tscn in normal flow. Keeping this guard
	# also makes an in-place mode reset deterministic in smoke tests.
	var reset_rooms: Dictionary = {}
	for room_name in WORLD_LAYOUT.ROOM_NODES.values():
		reset_rooms[String(room_name)] = true
	for room_name in reset_rooms:
		var room := get_parent().get_node_or_null(room_name) as Node2D
		if room == null:
			continue
		var authored_to_free: Array[Node] = []
		for child in room.find_children("*", "Node", true, false):
			if not is_instance_valid(child):
				continue
			if bool(child.get_meta("authored_streamed_population", false)):
				authored_to_free.append(child)
			elif _is_curated_population_name(String(child.name)):
				child.queue_free()
		for child in authored_to_free:
			if is_instance_valid(child):
				child.free()
	call_deferred("_on_room_changed", str(game_state.current_room_id))


func _on_room_changed(room_id: String) -> void:
	var room_name := String(WORLD_LAYOUT.ROOM_NODES.get(room_id, ""))
	var previous_room := active_room_name
	active_room_name = room_name if not room_name.is_empty() and get_parent().get_node_or_null(room_name) != null else ""
	if not previous_room.is_empty() and previous_room != active_room_name:
		_schedule_room_unload(previous_room)
	if active_room_name.is_empty():
		return
	# Returning before the grace window expires cancels its pending unload.
	pending_unloads.erase(active_room_name)
	_ensure_room_population(active_room_name)


func _schedule_room_unload(room_name: String) -> void:
	var room := get_parent().get_node_or_null(room_name) as Node2D
	if room == null:
		return
	var has_streamed_actor := bool(populated_rooms.get(room_name, false))
	if not has_streamed_actor:
		for child in room.find_children("*", "Node", true, false):
			if _is_streamed_population_node(child):
				has_streamed_actor = true
				break
	if not has_streamed_actor:
		return
	pending_unloads[room_name] = Time.get_ticks_msec() + int(ROOM_UNLOAD_GRACE_SECONDS * 1000.0)


func _process(_delta: float) -> void:
	if pending_unloads.is_empty():
		return
	var now := Time.get_ticks_msec()
	for room_name in pending_unloads.keys():
		if String(room_name) == active_room_name:
			pending_unloads.erase(room_name)
			continue
		if now < int(pending_unloads[room_name]):
			continue
		pending_unloads.erase(room_name)
		unload_room_population(String(room_name))


func unload_room_population(room_name: String) -> void:
	var room := get_parent().get_node_or_null(room_name) as Node2D
	if room == null:
		return
	var snapshot: Dictionary = {}
	for child in room.find_children("*", "Node", true, false):
		var child_name := String(child.name)
		if not _is_streamed_population_node(child) or child.is_queued_for_deletion():
			continue
		var kind := _streamed_population_kind(child)
		var state_key := String(child.get_meta("streamed_population_key", child_name))
		var removed := bool(child.get("is_destroyed")) if kind == "crate" else bool(child.get("is_dead"))
		if bool(child.get_meta("authored_streamed_population", false)):
			_set_authored_actor_state(room_name, state_key, not removed, _capture_runtime_state(child, kind) if not removed else {})
		elif not removed:
			snapshot[child_name] = _capture_runtime_state(child, kind)
		child.queue_free()
	room_snapshots[room_name] = snapshot
	populated_rooms.erase(room_name)


func _is_curated_population_name(node_name: String) -> bool:
	return node_name.begins_with("WildPatrol") or node_name.begins_with("WildFauna") or node_name.begins_with("WildCrate")


func _is_streamed_population_node(node: Node) -> bool:
	return _is_curated_population_name(String(node.name)) or bool(node.get_meta("authored_streamed_population", false))


func _streamed_population_kind(node: Node) -> String:
	if node.has_meta("streamed_population_kind"):
		return String(node.get_meta("streamed_population_kind"))
	if String(node.name).begins_with("WildCrate") or node.is_in_group("breakable"):
		return "crate"
	if String(node.name).begins_with("WildFauna") or node.is_in_group("neutral_creature"):
		return "neutral"
	return "enemy"


func _capture_runtime_state(node: Node, kind: String = "") -> Dictionary:
	if kind.is_empty():
		kind = _streamed_population_kind(node)
	var state := {"position": (node as Node2D).position}
	state["current_health"] = int(node.get("current_health"))
	if kind == "neutral":
		state["is_hostile"] = bool(node.get("is_hostile"))
		state["resting"] = bool(node.get("resting"))
		state["phase_remaining"] = float(node.get("phase_remaining"))
		state["grace_remaining"] = float(node.get("grace_remaining"))
		state["direction"] = float(node.get("direction"))
	return state


func _snapshot_allows(room_name: String, node_name: String) -> bool:
	return not room_snapshots.has(room_name) or (room_snapshots[room_name] as Dictionary).has(node_name)


func _restore_runtime_state(room_name: String, node: Node2D) -> void:
	if not room_snapshots.has(room_name):
		return
	var snapshot: Dictionary = room_snapshots[room_name]
	if not snapshot.has(String(node.name)):
		return
	var state: Dictionary = snapshot[String(node.name)]
	_apply_runtime_state(node, state, _streamed_population_kind(node))


func _apply_runtime_state(node: Node2D, state: Dictionary, kind: String) -> void:
	node.position = state.get("position", node.position)
	if kind == "neutral" and node.has_method("restore_streamed_state"):
		node.call("restore_streamed_state", state)
		return
	node.set("current_health", mini(int(state.get("current_health", node.get("max_health"))), int(node.get("max_health"))))
	var health_bar := node.get_node_or_null("HealthBar") as ProgressBar
	if health_bar != null:
		health_bar.value = int(node.get("current_health"))


func should_spawn_authored_actor(room_name: String, actor_name: String) -> bool:
	if not authored_actor_states.has(room_name):
		return true
	var room_states: Dictionary = authored_actor_states[room_name]
	if not room_states.has(actor_name):
		return true
	return bool((room_states[actor_name] as Dictionary).get("alive", true))


func register_authored_actor(room_name: String, actor: Node2D, actor_key: String = "") -> void:
	var actor_name := actor_key if not actor_key.is_empty() else String(actor.name)
	actor.set_meta("streamed_population_key", actor_name)
	if not authored_actor_states.has(room_name):
		authored_actor_states[room_name] = {}
	var room_states: Dictionary = authored_actor_states[room_name]
	if not room_states.has(actor_name):
		room_states[actor_name] = {"alive": true, "state": {}}
	var entry: Dictionary = room_states[actor_name]
	if not bool(entry.get("alive", true)):
		actor.queue_free()
		return
	var saved_state: Dictionary = entry.get("state", {})
	if not saved_state.is_empty():
		_apply_runtime_state(actor, saved_state, _streamed_population_kind(actor))
	var removal_signal := "destroyed" if _streamed_population_kind(actor) == "crate" else "defeated"
	if actor.has_signal(removal_signal):
		actor.connect(removal_signal, Callable(self, "_on_authored_actor_removed").bind(room_name, actor_name), CONNECT_ONE_SHOT)


func _on_authored_actor_removed(room_name: String, actor_name: String) -> void:
	_set_authored_actor_state(room_name, actor_name, false, {})


func _set_authored_actor_state(room_name: String, actor_name: String, alive: bool, state: Dictionary) -> void:
	if not authored_actor_states.has(room_name):
		authored_actor_states[room_name] = {}
	var room_states: Dictionary = authored_actor_states[room_name]
	room_states[actor_name] = {"alive": alive, "state": state}


func _ensure_room_population(room_name: String) -> void:
	if bool(populated_rooms.get(room_name, false)) or not ROOMS.has(room_name):
		return
	var room := get_parent().get_node_or_null(room_name) as Node2D
	if room == null:
		return
	_populate(room, ROOMS[room_name])
	populated_rooms[room_name] = true


func is_room_populated(room_name: String) -> bool:
	return bool(populated_rooms.get(room_name, false))


func _populate(room: Node2D, data: Dictionary) -> void:
	var room_name := String(room.name)
	var index := 0
	for spawn_info in data["foes"]:
		var node_name := "WildPatrol%d" % index
		if not _snapshot_allows(room_name, node_name):
			index += 1
			continue
		var kind: String = spawn_info[0]
		var enemy: Node2D = FOES[kind].instantiate()
		enemy.name = node_name
		enemy.position = spawn_info[1]
		enemy.set("zone_id", data["zone"])
		room.add_child(enemy)
		# The Nest veil counts its three named guardians, not ambient broodlings.
		if room.name == "EchoNest" and kind == "brood":
			enemy.remove_from_group("nest_brood")
		_restore_runtime_state(room_name, enemy)
		index += 1
	index = 0
	for spawn_info in data["fauna"]:
		var node_name := "WildFauna%d" % index
		if not _snapshot_allows(room_name, node_name):
			index += 1
			continue
		var creature := NEUTRAL_SCENE.instantiate()
		creature.name = node_name
		creature.position = spawn_info[1]
		creature.creature_name = spawn_info[0]
		creature.zone_id = data["zone"]
		creature.passive_tint = data["tint"].lightened(0.15)
		creature.start_resting = index % 2 == 0
		room.add_child(creature)
		_restore_runtime_state(room_name, creature)
		index += 1
	index = 0
	for at in data["crates"]:
		var node_name := "WildCrate%d" % index
		if not _snapshot_allows(room_name, node_name):
			index += 1
			continue
		var crate := CRATE_SCENE.instantiate()
		crate.name = node_name
		crate.position = at
		crate.empty_drop_chance = 0.35
		crate.item_drop_chance = 0.18
		crate.min_gold = 2
		crate.max_gold = 9
		room.add_child(crate)
		_restore_runtime_state(room_name, crate)
		index += 1


func _build_growth(room: Node2D, data: Dictionary) -> void:
	var tint: Color = data["tint"]
	var index := 0
	for at in data["growth"]:
		for leaf_index in range(5):
			var x: float = at.x + float(leaf_index - 2) * 10.0
			var height := 15.0 + float((index * 7 + leaf_index * 11) % 21)
			var leaf := Polygon2D.new()
			leaf.name = "WildGrowth%d_%d" % [index, leaf_index]
			leaf.z_index = -1
			leaf.color = tint.darkened(0.1 + float(leaf_index % 2) * 0.18)
			leaf.polygon = PackedVector2Array([Vector2(x - 6.0, at.y), Vector2(x - 2.0, at.y - height), Vector2(x + 3.0, at.y - height - 5.0), Vector2(x + 1.0, at.y - height), Vector2(x + 7.0, at.y)])
			room.add_child(leaf)
		index += 1
