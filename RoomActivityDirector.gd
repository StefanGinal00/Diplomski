extends Node

# All rooms are editor-visible children of Game.tscn. At runtime only the
# current room needs AI, traps, ambient particles, NPC paths and rendering.
const WORLD_LAYOUT = preload("res://WorldLayout.gd")

var rooms: Dictionary = {}
var game_state: Node


func _ready() -> void:
	game_state = get_node_or_null("/root/GameState")
	var game := get_parent()
	for room_id in WORLD_LAYOUT.ROOM_ORIGINS:
		var expected_origin: Vector2 = WORLD_LAYOUT.ROOM_ORIGINS[room_id][1]
		for child in game.get_children():
			if child is Node2D and child.position == expected_origin:
				rooms[room_id] = child
				break
	if game_state != null:
		game_state.room_changed.connect(_on_room_changed)
		game_state.mode_changed.connect(_on_mode_changed)
		_on_room_changed(str(game_state.current_room_id))


func _on_mode_changed(_mode: String) -> void:
	_on_room_changed(str(game_state.current_room_id))


func _on_room_changed(room_id: String) -> void:
	for known_id in rooms:
		var room: Node2D = rooms[known_id]
		var active: bool = known_id == room_id
		room.visible = active
		room.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		if active:
			_activate_streamed_population(room)


func _activate_streamed_population(room: Node2D) -> void:
	# Persistent terrain, doors and puzzle state are already present. Expansion
	# scripts expose this hook only for the heavier enemies, fauna, breakables
	# and encounter triggers that can safely wait until first entry.
	if room.has_method("activate_room_population"):
		room.call("activate_room_population")
	for node in room.find_children("*", "Node", true, false):
		if node.has_method("activate_room_population"):
			node.call("activate_room_population")
