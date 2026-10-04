@tool
extends Node2D
## Read-only presentation; controllers retain interaction/reward authority.
@export_enum("resonator", "valve", "anchor", "drain", "receiver") var kind := "valve"
var active := false
var listening := false
var refresh_count := 0
const INK := Color("182b35")
const STEEL := Color("718f95")
const BRASS := Color("ba9f73")
const PAINTED := {
	"resonator": preload("res://art/visual_slice/echo_resonator_v1.png"),
	"receiver": preload("res://art/visual_slice/echo_receiver_v1.png"),
	"valve": preload("res://art/visual_slice/echo_valve_v1.png"),
	"anchor": preload("res://art/visual_slice/echo_anchor_v1.png"),
	"drain": preload("res://art/visual_slice/echo_drain_v1.png"),
}
const REGIONS := {
	"resonator": Rect2(240, 60, 772, 1108), "receiver": Rect2(306, 48, 688, 1150),
	"valve": Rect2(282, 54, 690, 1140), "anchor": Rect2(36, 24, 1194, 1196),
	"drain": Rect2(146, 174, 1020, 900),
}
var painted_rect := Rect2()
var prompt_layout_pending := false
var prompt_layout_unresolved := false
var bind_native_state := false
var native_light := Color("7db6cd")

func animate(_age: float) -> void:
	if not bind_native_state: return
	var core := get_parent().get_node_or_null("Core") as Polygon2D
	var next := core.color if core!=null else Color("7db6cd")
	var done: bool = get_parent().get("is_active")==true
	if next!=native_light or done!=active:
		native_light=next
		active=done
		queue_redraw()

func rest() -> void:
	animate(0)


static func attach(device: Node2D, device_kind: String) -> Node2D:
	var existing := device.get_node_or_null("DeviceArt") as Node2D
	if existing != null:
		return existing
	var art := new()
	art.name = "DeviceArt"
	art.kind = device_kind
	device.add_child(art)
	return art


func _ready() -> void:
	set_process(false)
	if PAINTED.has(kind):
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var size: Vector2 = REGIONS[kind].size
		size *= (51.0 if kind == "resonator" else 36.0) / size.y
		painted_rect = Rect2(Vector2(-size.x * 0.5, 25 - size.y), size)
		if kind == "resonator":
			call_deferred("_ground_resonator")
	elif kind != "resonator":
		# Side-shelf stations sit under short overhangs. Compact only their
		# artwork around the original y=25 foot, never their Area2D or reach.
		scale.y = 0.7
		position.y = 7.5
	for leaf_name in ["Glow", "Core", "Base", "Facet"]:
		var leaf := get_parent().get_node_or_null(leaf_name) as CanvasItem
		if leaf != null and leaf.get_child_count() == 0:
			leaf.hide()
	if kind in ["valve", "anchor", "drain"]:
		var prompt := get_parent().get_node_or_null("InteractionPrompt") as Label
		if prompt != null:
			prompt.z_index = 3
			prompt.add_theme_color_override("font_outline_color", Color("09131c"))
			prompt.add_theme_constant_override("outline_size", 3)
			prompt.minimum_size_changed.connect(_schedule_prompt_layout)
			_schedule_prompt_layout()
	queue_redraw()


func _schedule_prompt_layout() -> void:
	if prompt_layout_pending:
		return
	prompt_layout_pending = true
	call_deferred("_layout_prompt")


func _layout_prompt() -> void:
	prompt_layout_pending = false
	var device := get_parent()
	var prompt := device.get_node_or_null("InteractionPrompt") as Label
	if prompt == null:
		return
	# Native prompts originally sit below y=25, inside the supporting floor.
	# Find a clear nearby band without moving controller, label text or reach.
	var obstacles: Array[Rect2] = []
	var operations := device.get_parent()
	var route := operations.get("route") as Node2D
	if route != null:
		for body in route.find_children("*", "StaticBody2D", true, false):
			if body.is_in_group("breakable"):
				continue
			var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if shape != null and not shape.disabled and shape.shape is RectangleShape2D:
				obstacles.append(shape.global_transform * Rect2(-shape.shape.size * 0.5, shape.shape.size))
	var status := device.get_node_or_null("StatusLabel") as Label
	if status != null:
		obstacles.append(status.get_global_transform() * Rect2(Vector2.ZERO, status.size))
	prompt_layout_unresolved = true
	for y in [-77, -101, -125, -149, -173]:
		prompt.position.y = y
		var rect := prompt.get_global_transform() * Rect2(Vector2.ZERO, prompt.size)
		var clear := true
		for obstacle in obstacles:
			if rect.grow(2).intersects(obstacle):
				clear = false
				break
		if clear:
			prompt_layout_unresolved = false
			return
	# Keep a bounded, readable fallback if a future map edit crowds all bands.
	prompt.position.y = -77


func _ground_resonator() -> void:
	if bind_native_state: return # World finish already fitted this exact support.
	# Original root crystals float 3/6 px above their shelves. Register only
	# painted feet to nearby existing support; never move the interaction.
	var room := get_parent().get_parent()
	var best := 13.0
	var shift := 0.0
	var foot := to_global(Vector2(0, painted_rect.end.y))
	for body in room.get_children():
		if not body is StaticBody2D:
			continue
		var collider := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collider == null or collider.disabled or not collider.shape is RectangleShape2D:
			continue
		var rect: Rect2 = collider.global_transform * Rect2(-collider.shape.size * 0.5, collider.shape.size)
		var delta_y: float = rect.position.y - foot.y
		if foot.x - painted_rect.size.x * 0.5 >= rect.position.x and foot.x + painted_rect.size.x * 0.5 <= rect.end.x and absf(delta_y) < best:
			best = absf(delta_y)
			shift = to_local(Vector2(foot.x, rect.position.y)).y - painted_rect.end.y
	painted_rect.position.y += shift
	queue_redraw()


func set_status(done: bool, recording: bool = false) -> void:
	if active == done and listening == recording:
		return
	active = done
	listening = recording
	refresh_count += 1
	queue_redraw()


func _draw() -> void:
	var light := Color("a0dec5") if active else Color("7db6cd")
	if bind_native_state: light=native_light
	if listening:
		light = Color("e5c887")
	if PAINTED.has(kind):
		draw_texture_rect_region(PAINTED[kind], painted_rect, REGIONS[kind])
		# A separate readable state marker avoids recolouring brass/stone.
		var registration := Vector2(0, painted_rect.end.y - 25)
		draw_circle(Vector2(0, 20) + registration, 2.2, light)
		if active:
			draw_polyline(PackedVector2Array([Vector2(14, 14) + registration, Vector2(18, 18) + registration, Vector2(25, 9) + registration]), light, 2, true)
		elif listening:
			# Receiver shelves have only 36 px of clearance; its status arc
			# must fit there too, not just the painted dish.
			var center := Vector2(0, 7) if kind != "resonator" else Vector2(0, -3) + registration
			draw_arc(center, 16 if kind != "resonator" else 20, PI * 1.15, TAU - 0.15, 24, light, 1.5, true)
		return
	# Base remains at the original device's y=25; no implied new platform.
	draw_colored_polygon(PackedVector2Array([Vector2(-20, 25), Vector2(-17, 18), Vector2(17, 18), Vector2(20, 25)]), INK)
	draw_line(Vector2(-17, 19), Vector2(17, 19), STEEL, 2, true)
	draw_line(Vector2(-16, 23), Vector2(16, 23), STEEL.darkened(0.5), 1)
	for x in [-14, 14]:
		draw_circle(Vector2(x, 21), 0.8, BRASS)
	match kind:
		"resonator":
			draw_rect(Rect2(-11, 13, 22, 6), STEEL.darkened(0.25))
			for x in [-17, 17]:
				draw_line(Vector2(x, 17), Vector2(x, -9), BRASS, 2, true)
				draw_circle(Vector2(x, -9), 3, STEEL)
			var points := PackedVector2Array([Vector2(0, -26), Vector2(10, -10), Vector2(7, 8), Vector2(0, 14), Vector2(-9, 5), Vector2(-11, -12)])
			draw_colored_polygon(points, light.darkened(0.32))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -26), Vector2(2, -8), Vector2(0, 14), Vector2(-9, 5), Vector2(-11, -12)]), light)
			draw_polyline(PackedVector2Array([Vector2(0, -23), Vector2(2, -8), Vector2(-1, 10)]), light.lightened(0.45), 1, true)
			for y in [-5, 2, 9]:
				draw_line(Vector2(-22, y), Vector2(-19, y), light, 1)
				draw_line(Vector2(19, y), Vector2(22, y), light, 1)
		"valve":
			draw_line(Vector2(-18, 14), Vector2(18, 14), STEEL.darkened(0.25), 7, true)
			draw_line(Vector2(0, 15), Vector2(0, -2), STEEL, 7, true)
			draw_circle(Vector2(0, -4), 17, INK)
			draw_arc(Vector2(0, -4), 14, 0, TAU, 32, BRASS, 3, true)
			draw_arc(Vector2(0, -4), 16, PI, TAU, 20, BRASS.lightened(0.22), 0.8, true)
			for i in range(5):
				var ray := Vector2.RIGHT.rotated(i * TAU / 5 + (0.45 if active else 0))
				draw_line(Vector2(0, -4) + ray * 3, Vector2(0, -4) + ray * 13, STEEL, 2, true)
			draw_circle(Vector2(0, -4), 4, light)
		"anchor":
			for x in [-14, 14]:
				draw_rect(Rect2(x - 3, -17, 6, 35), STEEL.darkened(0.25))
			draw_rect(Rect2(-17, -16, 34, 7), STEEL)
			for y in [-5, 3, 11]:
				draw_arc(Vector2(0, y), 4, 0, TAU, 16, BRASS, 2, true)
			draw_line(Vector2(-12, 0), Vector2(12, 0), light if active else STEEL, 4, true)
			draw_line(Vector2(-16, -20), Vector2(16, -20), light, 2)
			for x in [-14, 14]:
				for y in [-12, 14]:
					draw_circle(Vector2(x, y), 1.2, BRASS)
		"drain":
			draw_rect(Rect2(-16, -19, 32, 36), STEEL.darkened(0.2))
			draw_rect(Rect2(-12, -15, 24, 28), INK)
			for x in [-8, 0, 8]:
				draw_line(Vector2(x, -13), Vector2(x, 11), STEEL, 2, true)
			draw_rect(Rect2(-11, 1 if active else -10, 22, 11), Color(light, 0.4))
			draw_line(Vector2(17, -14), Vector2(22, -14), BRASS, 3)
			draw_line(Vector2(22, -14), Vector2(22, 5 if active else -23), BRASS, 2, true)
		"receiver":
			draw_rect(Rect2(-13, 0, 26, 17), STEEL.darkened(0.25))
			draw_rect(Rect2(-10, 3, 20, 9), INK)
			for i in range(4):
				draw_line(Vector2(-7 + i * 4, 10), Vector2(-7 + i * 4, 5 + i % 2 * 3), light, 1, true)
			draw_line(Vector2(0, 0), Vector2(0, -8), BRASS, 3)
			draw_arc(Vector2(0, -18), 14, 0.1, PI - 0.1, 24, STEEL, 4, true)
			draw_line(Vector2(0, -7), Vector2(0, -22), BRASS, 2)
			draw_circle(Vector2(0, -23), 3, light)
	# State is legible without relying only on blue/green tint.
	if active:
		draw_polyline(PackedVector2Array([Vector2(12, 13), Vector2(16, 17), Vector2(23, 9)]), Color("b4ecc8"), 2, true)
	elif listening:
		draw_arc(Vector2(0, -7), 18, 0.15, PI - 0.15, 20, light, 1.5, true)
