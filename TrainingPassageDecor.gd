@tool
extends Node2D

## Adds a readable camp, aqueduct and sentinel court to the opening passage.
## Existing combat, quest, checkpoint and exit nodes remain untouched.

const NEUTRAL_SCENE: PackedScene = preload("res://NeutralCreature.tscn")

var generated: Node2D


func _ready() -> void:
	generated = Node2D.new()
	generated.name = "GeneratedPassageDetails"
	add_child(generated)
	_build_cavern_depth()
	_build_wayfarer_camp()
	_build_aqueduct()
	_build_sentinel_court()
	if Engine.is_editor_hint():
		return
	var moth := NEUTRAL_SCENE.instantiate()
	moth.name = "WayfarerMoth"
	moth.position = Vector2(92.0, 367.0)
	moth.creature_name = "Lantern Moth"
	moth.zone_id = "training_passage"
	moth.start_resting = true
	moth.passive_tint = Color("75d9ca")
	generated.add_child(moth)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.room_changed.connect(_on_room_changed)
		state.mode_changed.connect(_on_mode_changed)
		_refresh_active(str(state.current_room_id))


func _on_room_changed(room_id: String) -> void:
	_refresh_active(room_id)


func _on_mode_changed(_mode: String) -> void:
	var state := get_node_or_null("/root/GameState")
	if state != null:
		_refresh_active(str(state.current_room_id))


func _refresh_active(room_id: String) -> void:
	var active := room_id == "training_passage"
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _build_cavern_depth() -> void:
	_poly("FarCave", PackedVector2Array([Vector2(-90, 410), Vector2(-90, 70), Vector2(80, 25), Vector2(230, 86), Vector2(390, 18), Vector2(570, 83), Vector2(760, 36), Vector2(940, 91), Vector2(1110, 25), Vector2(1425, 78), Vector2(1425, 410)]), Color("071924"), -9)
	for index in range(8):
		var x := 40.0 + float(index) * 185.0
		var height := 76.0 + float((index * 37) % 82)
		_poly("CaveTooth%d" % index, PackedVector2Array([Vector2(x - 58, 395), Vector2(x, 395 - height), Vector2(x + 74, 395)]), Color(0.05, 0.17, 0.21, 0.86), -8)
	for index in range(7):
		var x := 125.0 + float(index) * 205.0
		_poly("CeilingShard%d" % index, PackedVector2Array([Vector2(x - 24, 0), Vector2(x + 29, 0), Vector2(x + 3, 62 + float(index % 3) * 24)]), Color(0.08, 0.29, 0.34, 0.72), -7)


func _build_wayfarer_camp() -> void:
	# A two-step optional overlook makes the opening camp feel inhabited without
	# bypassing the first encounter or the dash gate.
	_platform("CampStep", Vector2(108, 335), Vector2(112, 10), Color("23606a"))
	_platform("CampRoof", Vector2(247, 282), Vector2(205, 12), Color("2c6d73"))
	_poly("CampCanopy", PackedVector2Array([Vector2(128, 316), Vector2(172, 235), Vector2(292, 235), Vector2(344, 316)]), Color(0.14, 0.37, 0.4, 0.75), -2)
	for x in [151.0, 319.0]:
		_line("CanopyPost%d" % int(x), PackedVector2Array([Vector2(x, 239), Vector2(x, 389)]), 4.0, Color("497a79"), -1)
	for x in [87.0, 215.0, 333.0]:
		_poly("CampLamp%d" % int(x), PackedVector2Array([Vector2(x - 7, 357), Vector2(x, 337), Vector2(x + 7, 357)]), Color(0.42, 0.96, 0.78, 0.8), -1)
	_label("CampSign", "WAYFARER REST", Vector2(167, 246), 154, 10, Color("8fe3d4"))
	_flora("CampMoss", Vector2(58, 390), 8, Color("3f9b75"))


func _build_aqueduct() -> void:
	for index in range(3):
		var center_x := 500.0 + float(index) * 165.0
		_poly("AqueductArch%d" % index, PackedVector2Array([Vector2(center_x - 68, 390), Vector2(center_x - 68, 185), Vector2(center_x - 42, 159), Vector2(center_x + 42, 159), Vector2(center_x + 68, 185), Vector2(center_x + 68, 390), Vector2(center_x + 45, 390), Vector2(center_x + 45, 205), Vector2(center_x + 26, 182), Vector2(center_x - 26, 182), Vector2(center_x - 45, 205), Vector2(center_x - 45, 390)]), Color(0.08, 0.25, 0.3, 0.8), -5)
	_line("OldWaterLine", PackedVector2Array([Vector2(432, 198), Vector2(568, 180), Vector2(733, 199), Vector2(812, 176)]), 3.0, Color(0.22, 0.75, 0.75, 0.4), -4)
	_label("AqueductSign", "THE OLD CHANNEL", Vector2(525, 206), 190, 9, Color(0.37, 0.78, 0.78, 0.72))
	_flora("ChannelFern", Vector2(846, 390), 7, Color("398c76"))


func _build_sentinel_court() -> void:
	_poly("SentinelDais", PackedVector2Array([Vector2(918, 390), Vector2(950, 340), Vector2(1195, 340), Vector2(1234, 390)]), Color(0.12, 0.28, 0.34, 0.72), -4)
	for x in [945.0, 1210.0]:
		_poly("SentinelPillar%d" % int(x), PackedVector2Array([Vector2(x - 18, 390), Vector2(x - 13, 196), Vector2(x, 176), Vector2(x + 13, 196), Vector2(x + 18, 390)]), Color("21434c"), -3)
		_poly("SentinelRune%d" % int(x), PackedVector2Array([Vector2(x - 8, 235), Vector2(x, 218), Vector2(x + 8, 235), Vector2(x, 252)]), Color(0.33, 0.9, 0.88, 0.58), -2)
	_poly("GateArch", PackedVector2Array([Vector2(1284, 390), Vector2(1284, 270), Vector2(1310, 238), Vector2(1360, 238), Vector2(1387, 270), Vector2(1387, 390), Vector2(1370, 390), Vector2(1370, 282), Vector2(1350, 259), Vector2(1320, 259), Vector2(1301, 282), Vector2(1301, 390)]), Color("334c55"), -2)
	_label("CourtSign", "SENTINEL COURT", Vector2(995, 302), 180, 10, Color("8dc7c5"))


func _platform(node_name: String, at: Vector2, platform_size: Vector2, tint: Color) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = at
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	collision.shape = shape
	collision.one_way_collision = true
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.color = tint
	visual.polygon = PackedVector2Array([Vector2(-platform_size.x * 0.5, -platform_size.y * 0.5), Vector2(platform_size.x * 0.5, -platform_size.y * 0.5), Vector2(platform_size.x * 0.5, platform_size.y * 0.5), Vector2(-platform_size.x * 0.5, platform_size.y * 0.5)])
	body.add_child(visual)
	generated.add_child(body)


func _flora(node_name: String, at: Vector2, count: int, tint: Color) -> void:
	var patch := Node2D.new()
	patch.name = node_name
	for index in range(count):
		var x := at.x + float(index) * 12.0
		var height := 14.0 + float((index * 9) % 22)
		var leaf := Polygon2D.new()
		leaf.name = "Leaf%d" % index
		leaf.z_index = -1
		leaf.color = tint.lightened(0.05 * float(index % 3))
		leaf.polygon = PackedVector2Array([Vector2(x - 6, at.y), Vector2(x, at.y - height), Vector2(x + 6, at.y)])
		patch.add_child(leaf)
	generated.add_child(patch)


func _poly(node_name: String, points: PackedVector2Array, tint: Color, layer: int) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = tint
	polygon.z_index = layer
	generated.add_child(polygon)


func _line(node_name: String, points: PackedVector2Array, width: float, tint: Color, layer: int) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.width = width
	line.default_color = tint
	line.z_index = layer
	generated.add_child(line)


func _label(node_name: String, words: String, at: Vector2, label_width: float, font_size: int, tint: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.size = Vector2(label_width, 24)
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	generated.add_child(label)
