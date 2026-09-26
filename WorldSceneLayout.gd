@tool
extends Node2D

const LAYOUT = preload("res://WorldLayout.gd")

const ZONES := {
	"SUNKEN SHAFT": [Rect2(5600, -21800, 43500, 10300), Color(0.10, 0.52, 0.58, 0.055)],
	"ECHO GROTTO": [Rect2(5600, -12500, 56500, 9500), Color(0.23, 0.58, 0.78, 0.05)],
	"ASHEN BASTION": [Rect2(5600, -1800, 50500, 10800), Color(0.72, 0.27, 0.13, 0.05)],
	"STARFALL REACH": [Rect2(5600, 10800, 64500, 9400), Color(0.48, 0.42, 0.76, 0.055)],
}

const CONNECTIONS := [
	["sunken_shaft", "shaft_hollow"], ["shaft_hollow", "shaft_drift"], ["shaft_drift", "shaft_crossing"],
	["shaft_crossing", "shaft_gallery"], ["shaft_gallery", "shaft_cistern"], ["shaft_cistern", "shaft_approach"],
	["echo_grotto", "echo_gallery"], ["echo_gallery", "echo_depths"], ["echo_depths", "echo_archive"],
	["echo_archive", "echo_tide_well"], ["echo_tide_well", "echo_nest"], ["echo_nest", "echo_causeway"],
	["echo_causeway", "echo_vault"], ["echo_nest", "echo_sanctum"], ["echo_sanctum", "echo_haven"],
	["echo_haven", "echo_haven_outskirts"],
	["ash_causeway", "ash_emberspine"], ["ash_emberspine", "ash_forge"], ["ash_forge", "ash_barracks"],
	["ash_barracks", "ash_arena"], ["ash_arena", "ash_reservoir"], ["ash_reservoir", "ash_chapel"],
	["ash_chapel", "ash_throne"], ["ash_reservoir", "ash_hearth"], ["ash_hearth", "ash_hearth_outskirts"],
	["starfall_citadel", "starfall_outskirts"], ["starfall_outskirts", "starfall_ramparts"],
	["starfall_ramparts", "starfall_silent_gate"], ["starfall_silent_gate", "starfall_memory_vault"],
	["starfall_memory_vault", "starfall_rooted_hall"], ["starfall_rooted_hall", "starfall_empty_court"],
	["starfall_empty_court", "starfall_soul_crucible"], ["starfall_soul_crucible", "starfall_sunless_passage"],
	["starfall_sunless_passage", "starfall_hollow_throne"],
]


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_layout")
	else:
		_apply_runtime_layout()


func _apply_runtime_layout() -> void:
	for room_id in LAYOUT.ROOM_NODES:
		var room := get_node_or_null(str(LAYOUT.ROOM_NODES[room_id])) as Node2D
		if room != null:
			room.position = LAYOUT.ROOM_ORIGINS[room_id][1]


func _apply_editor_layout() -> void:
	for room_id in LAYOUT.ROOM_NODES:
		var room := get_node_or_null(str(LAYOUT.ROOM_NODES[room_id])) as Node2D
		if room != null:
			room.position = LAYOUT.EDITOR_ORIGINS[room_id]
	_build_editor_diagram()


func _build_editor_diagram() -> void:
	var previous := get_node_or_null("WorldEditorDiagram")
	if previous != null:
		remove_child(previous)
		previous.queue_free()
	var diagram := Node2D.new()
	diagram.name = "WorldEditorDiagram"
	diagram.z_index = -100
	add_child(diagram, false, Node.INTERNAL_MODE_BACK)
	for zone_name in ZONES:
		var data: Array = ZONES[zone_name]
		var bounds: Rect2 = data[0]
		var panel := Polygon2D.new()
		panel.name = str(zone_name).to_pascal_case() + "Panel"
		panel.color = data[1]
		panel.polygon = PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)])
		diagram.add_child(panel)
		var outline := Line2D.new()
		outline.name = str(zone_name).to_pascal_case() + "Outline"
		outline.width = 24.0
		outline.default_color = Color((data[1] as Color).r, (data[1] as Color).g, (data[1] as Color).b, 0.34)
		outline.points = PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y), bounds.position])
		diagram.add_child(outline)
		var label := Label.new()
		label.name = str(zone_name).to_pascal_case() + "Label"
		label.position = bounds.position + Vector2(260, 190)
		label.size = Vector2(3600, 320)
		label.text = str(zone_name)
		label.add_theme_font_size_override("font_size", 170)
		label.add_theme_color_override("font_color", Color((data[1] as Color).r, (data[1] as Color).g, (data[1] as Color).b, 0.68))
		diagram.add_child(label)
	for index in range(CONNECTIONS.size()):
		var edge: Array = CONNECTIONS[index]
		var from: Vector2 = LAYOUT.EDITOR_ORIGINS[edge[0]] + Vector2(520, 340)
		var to: Vector2 = LAYOUT.EDITOR_ORIGINS[edge[1]] + Vector2(520, 340)
		var line := Line2D.new()
		line.name = "WorldLink%d" % index
		line.width = 22.0
		line.default_color = Color(0.32, 0.75, 0.78, 0.24)
		line.points = PackedVector2Array([from, Vector2(to.x, from.y), to])
		diagram.add_child(line)
