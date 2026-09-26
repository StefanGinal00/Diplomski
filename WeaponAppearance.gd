extends Node2D

## Native weapon art only. No collision, input, timers or damage ownership.
## Pixel-space grip anchors in the six existing combat atlas cells.
const GRIPS := [Vector2(476, 235), Vector2(451, 192), Vector2(235, 246), Vector2(464, 280), Vector2(449, 188), Vector2(238, 266)]
var active := false
var weapon_class := ""
var weapon_id := ""
var hand := Vector2.ZERO
var direction := Vector2.RIGHT
var side := 1.0
var progress := 0.0
var reach := 34.0
var accent := Color.WHITE


func _ready() -> void:
	process_priority = 2 # Appearance has already selected its body frame.
	visibility_changed.connect(_clear_hidden)


func _clear_hidden() -> void:
	if not is_visible_in_tree():
		active = false
		queue_redraw()


func _process(_delta: float) -> void:
	var actor := get_parent() as Player
	var body := actor.get_node("Appearance")
	var was_active := active
	active = is_visible_in_tree() and not actor.is_dead and body.current_pose == body.Pose.ATTACK and body.texture == body.COMBAT_SHEET and not body.attack_class.is_empty() and not actor.attack_visual_timer.is_stopped()
	if not active:
		if was_active:
			queue_redraw()
		return
	weapon_class = body.attack_class
	weapon_id = body.attack_weapon_id
	direction = body.attack_direction
	side = -1.0 if body.flip_h else 1.0
	# Do not inherit Sprite2D atlas offset/scale on the weapon itself.
	var grip: Vector2 = (GRIPS[body.frame] - body.COMBAT_PIVOTS[body.frame]) * body.scale
	grip.x *= side
	hand = body.position + grip
	progress = clampf(1.0 - actor.attack_visual_timer.time_left / maxf(body.attack_duration, 0.001), 0.0, 1.0)
	reach = body.attack_reach
	accent = actor.attack_visual.color if weapon_class == "sword" else Color("83d39b")
	if weapon_class == "staff":
		accent = Color("ee879e") if weapon_id == "sunder_staff" else Color("b8a3f2")
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	match weapon_class:
		"sword":
			_draw_sword()
		"bow":
			_draw_bow()
		"staff":
			_draw_staff()


func _draw_sword() -> void:
	# Keep the tip within the committed hitbox's forward extent (reach + 7).
	var length := clampf(reach + 7.0 - absf(hand.x), 12.0, 58.0)
	draw_set_transform(hand, 0, Vector2(side, 1))
	var blade := PackedVector2Array([Vector2(2, -1.7), Vector2(length - 5, -1.5), Vector2(length, 0), Vector2(length - 5, 1.5), Vector2(2, 1.7)])
	draw_colored_polygon(blade, Color("afd5da") if weapon_id == "spiritglass_blade" else Color("a9b7bc"))
	draw_line(Vector2(3, -1), Vector2(length - 3, -0.3), Color("edf2e6"), 0.7, true)
	draw_line(Vector2(-4, 0), Vector2(2, 0), Color("654c3e"), 2.8, true)
	draw_line(Vector2(2, -3), Vector2(2, 3), Color("c9aa6e"), 1.3, true)
	draw_circle(Vector2(-4, 0), 1.5, Color("c9aa6e"))
	# Small hand wrap masks the open palm in the follow-through drawing.
	draw_line(Vector2(-1.5, 0), Vector2(0.5, 0), Color("775d46"), 3.1, true)
	draw_set_transform(Vector2.ZERO, 0, Vector2(side, 1))
	var sweep_color := Color(accent, 0.48 * (1.0 - progress))
	draw_arc(Vector2.ZERO, reach + 6.0, -0.42 + progress * 0.35, 0.3 + progress * 0.35, 16, sweep_color, 1.1, true)
	draw_set_transform(Vector2.ZERO)


func _draw_bow() -> void:
	# Symmetric limbs rotate around the registered grip, not the body origin.
	draw_set_transform(hand, direction.angle())
	var wood := Color("6eae76") if weapon_id == "thorn_bow" else Color("ae875a")
	var limbs := PackedVector2Array([Vector2(-2, -9), Vector2(2, -6), Vector2(3.5, 0), Vector2(2, 6), Vector2(-2, 9)])
	draw_polyline(limbs, Color("302c2c"), 3.1, true)
	draw_polyline(limbs, wood, 1.8, true)
	var vibration := sin(progress * TAU * 2.0) * (1.0 - progress)
	draw_polyline(PackedVector2Array([Vector2(-2, -9), Vector2(-2 + vibration, 0), Vector2(-2, 9)]), Color("dad7ba"), 0.65, true)
	draw_line(Vector2(3, -2), Vector2(3, 2), Color("594336"), 2.4, true)
	if weapon_id == "thorn_bow":
		draw_line(Vector2(2, -6), Vector2(5, -7), wood, 1, true)
		draw_line(Vector2(2, 6), Vector2(5, 7), wood, 1, true)
	draw_set_transform(Vector2.ZERO)


func _draw_staff() -> void:
	# Crystal stays above the hand when facing left; no upside-down staff.
	# Tilt away from the hood so the crystal does not cover the face.
	draw_set_transform(hand, -0.22 * side, Vector2(side, 1))
	draw_line(Vector2(0, -9), Vector2(0, 9), Color("302c2c"), 3.8, true)
	draw_line(Vector2(0, -9), Vector2(0, 9), Color("8d6c50"), 2.2, true)
	draw_line(Vector2(-1.5, -6), Vector2(1.5, -6), Color("d3b67d"), 1.5, true)
	draw_line(Vector2(-1.5, 3), Vector2(1.5, 3), Color("d3b67d"), 1.1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -15), Vector2(3, -11), Vector2(0, -7), Vector2(-3, -11)]), accent)
	draw_line(Vector2(0, -14), Vector2(1, -11), Color("f0e6ff"), 0.8, true)
	draw_circle(Vector2(0, -11), 4.5, Color(accent, (1.0 - progress) * 0.18))
	draw_set_transform(Vector2.ZERO)
