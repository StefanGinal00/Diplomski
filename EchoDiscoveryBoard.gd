extends Node2D

const RESIDENT := preload("res://TownResident.tscn")
const ROOMS := {"grotto": "Grotto Choir", "gallery": "Gallery", "archive": "Archive", "tide": "Tide Well", "nest": "Nest", "causeway": "Causeway", "vault": "Vault", "depths": "Echo Depths"}
var state: Node
var board: Label
var curator: Area2D


func _ready() -> void:
	var backing := Polygon2D.new()
	backing.z_index = -1
	backing.color = Color(0.025, 0.11, 0.16, 0.96)
	backing.polygon = PackedVector2Array([Vector2(-180, -218), Vector2(220, -218), Vector2(220, -65), Vector2(-180, -65)])
	add_child(backing)
	board = Label.new()
	board.name = "Records"
	board.position = Vector2(-170, -208)
	board.size = Vector2(380, 140)
	board.add_theme_font_size_override("font_size", 11)
	add_child(board)
	for index in range(2):
		var marker := Marker2D.new()
		marker.name = "CuratorStop%d" % index
		marker.position = Vector2(-55 + index * 65, -26)
		add_child(marker)
	curator = RESIDENT.instantiate() as Area2D
	curator.name = "Curator"
	curator.position = Vector2(-55, -26)
	curator.set("resident_name", "Edda, Record Keeper")
	curator.set("route_marker_names", PackedStringArray(["CuratorStop0", "CuratorStop1"]))
	curator.set("coat_color", Color(0.33, 0.37, 0.57))
	add_child(curator)
	curator.get_node("NameLabel").position.x = -130
	curator.get_node("NameLabel").size.x = 260
	state = get_node_or_null("/root/GameState")
	if state != null:
		state.shortcut_changed.connect(_on_event)
		state.zone_tier_changed.connect(_on_tier)
	_refresh()


func _on_event(event_id: String) -> void:
	if event_id.begins_with("echo_"):
		_refresh()


func _on_tier(zone_id: String, _tier: int) -> void:
	if zone_id == "echo_grotto":
		_refresh()


func _refresh() -> void:
	if state == null:
		return
	var lines := PackedStringArray(["HAVEN FIELD RECORDS", "Task / Return: - missing, + complete, * awakened"])
	var entries := PackedStringArray()
	var found := 0
	var returned := 0
	for id in ROOMS:
		var recorded := bool(state.unlocked_shortcuts.get("echo_%s_field_complete" % id, false))
		var cleared := bool(state.unlocked_shortcuts.get("echo_%s_field_return_complete" % id, false))
		found += int(recorded)
		returned += int(cleared)
		entries.append("%s: %s / %s" % [ROOMS[id], "+" if recorded else "-", "+" if cleared else ("*" if recorded and state.get_zone_tier("echo_grotto") >= 1 else "-")])
	for index in range(4):
		lines.append(entries[index] + "   |   " + entries[index + 4])
	lines.append("RECORDS %d/%d    RETURN ECHOES %d/%d" % [found, ROOMS.size(), returned, ROOMS.size()])
	board.text = "\n".join(lines)
	var dialogue := PackedStringArray([
		"The posts are in the side chambers of the enlarged routes. Clear nearby foes, press Interact, and stay close until listening finishes.",
		"The Grotto choir answers low, middle, then high. A wrong tone resets the unfinished sequence. The Gallery's two witnesses can be heard in either order.",
		"The Archive begins at Zenith, returns to Dawn, and ends at Dusk. Its posts repeat the clue. Finishing a room's records unseals its cache in the final hidden chamber.",
		"Save completed records at a lamp. An unfinished tone sequence must be restarted after loading; each Gallery witness can be saved separately.",
		"In Tide Well, two regulators calm the current banks. The Causeway's two side anchors keep its expanded bridges solid. Neither replaces the old Tide Core or main crystal anchor.",
		"Clear the Nest's two outer nurseries. In the Vault, drain both undertow channels and open the original two seals. Each task unseals that room's final hidden-shelf cache.",
		"Echo Depths has two lost expedition signals, in the western and eastern branches. Listen to both for the deepest reserve; after awakening, investigate the middle supply branch again.",
	])
	if state.get_zone_tier("echo_grotto") >= 1:
		dialogue.append("The Matriarch has fallen. Completed records now draw echoes to an upper side alcove in each room. Defeat them for a separate reserve.")
	if found == ROOMS.size():
		dialogue.insert(0, "All eight field tasks are complete. The board tracks your awakened encounters too. Lyra's trace survey remains a separate task.")
	curator.set("dialogue_lines", dialogue)
	curator.set("next_line_index", 0)
