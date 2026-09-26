@tool
extends Node2D

## Native 2D detail/animation over the existing resident shapes. Never moves
## the resident, its interaction reach, labels or route markers.
var elapsed := 0.0
var phase := 0.0
var stride := 0.0
var facing := 1.0
var previous_position := Vector2.ZERO
var redraw_clock := 0.0
var coat: Polygon2D
var face: Polygon2D
var accent: Polygon2D
var origins: Array[Vector2] = []


func _ready() -> void:
	coat = get_parent().get_node("Coat")
	face = get_parent().get_node("Face")
	accent = get_parent().get_node("Accent")
	origins.assign([coat.position, face.position, accent.position])
	previous_position = get_parent().position
	queue_redraw()
	if Engine.is_editor_hint():
		set_process(false)


func _process(delta: float) -> void:
	var resident := get_parent()
	if not is_visible_in_tree():
		previous_position = resident.position
		return
	var movement: Vector2 = resident.position - previous_position
	previous_position = resident.position
	var speed := movement.length() / maxf(delta, 0.001)
	# Room relocation / save restore is not a walking stride.
	if movement.length() > 20:
		speed = 0
	if absf(movement.x) > 0.01 and movement.length() <= 20:
		facing = signf(movement.x)
	stride = move_toward(stride, clampf(speed / 30.0, 0.0, 1.0), delta * 8)
	elapsed += delta
	phase += delta * lerpf(2.0, 9.0, stride)
	redraw_clock += delta
	if redraw_clock < 0.05:
		return
	redraw_clock = 0.0
	var bob := sin(elapsed * 2.1) * 0.3 + absf(sin(phase)) * stride * 0.7
	coat.position = origins[0] + Vector2(0, -bob)
	face.position = origins[1] + Vector2(facing * 0.35, -bob)
	accent.position = origins[2] + Vector2(sin(phase) * stride * 0.8, -bob)
	queue_redraw()


func _draw() -> void:
	if coat == null:
		return
	var tone := coat.color
	var trim := accent.color
	var swing := sin(phase) * stride * 3.0
	# Boots remain above the actor's existing y=15 ground baseline.
	for side in [-1.0, 1.0]:
		var foot := Vector2(side * 5 + side * swing, 14 - maxf(0, side * sin(phase)) * stride * 2)
		draw_line(Vector2(side * 5, 9), foot, tone.darkened(0.4), 5, true)
		draw_line(foot - Vector2(2, 0), foot + Vector2(facing * 4, 0), Color("182332"), 3, true)
	# Lapels, belt and brass clasp enrich the same editable vector silhouette.
	draw_polyline(PackedVector2Array([Vector2(-6, -9), Vector2(-3, 4), Vector2(0, 0), Vector2(3, 4), Vector2(6, -9)]), trim.darkened(0.24), 1.3, true)
	draw_line(Vector2(-10, 8), Vector2(10, 8), tone.darkened(0.4), 2)
	draw_circle(Vector2(1, 8), 1.3, Color("c6ac7d"))
	var talking: bool = not Engine.is_editor_hint() and (get_parent().get("player_dialogue_active") == true or float(get_parent().get("social_remaining")) > 0)
	for side in [-1.0, 1.0]:
		var hand := Vector2(side * 11, 4 + side * swing)
		if talking and side == facing:
			hand += Vector2(side * 3, -5 + sin(elapsed * 3) * 1.5)
		draw_line(Vector2(side * 9, -7), hand, tone.darkened(0.12), 4, true)
		draw_circle(hand, 1.8, face.color)
	var head := face.position - origins[1]
	draw_arc(Vector2(0, -17) + head, 6.0, PI * 1.05, TAU - 0.1, 9, tone.darkened(0.55), 3, true)
	draw_line(Vector2(facing * 2, -16) + head, Vector2(facing * 4, -16) + head, Color("1b2633"), 1.3, true)
