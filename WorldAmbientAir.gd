extends Node2D
## A single inexpensive screen-space air layer, behind terrain and actors.
## Motion is supplied by the room coordinator, not an independent particle sim.
var family := "cave"
var age := 0.0
var count := 18
var camera_offset := Vector2.ZERO
var viewport_size := Vector2(960, 540)

func update_air(room_family: String, time: float, low: bool, center: Vector2, size: Vector2) -> void:
	family = room_family
	age = time
	count = 8 if low else 18
	camera_offset = center * Vector2(0.44, 0.31)
	viewport_size = size
	queue_redraw()

func _draw() -> void:
	if viewport_size.x <= 0 or viewport_size.y <= 0: return
	var wind := 8.0 + sin(age * 0.23) * 5.0
	for i in range(count):
		var depth := 0.55 + float(i % 3) * 0.25
		var speed := Vector2(wind, 5)
		var color := Color(0.57, 0.77, 0.8, 0.22)
		if family == "ash":
			speed.y = -9
			color = Color(0.91, 0.6, 0.37, 0.25)
		elif family == "star":
			speed.y = -3
			color = Color(0.72, 0.7, 0.91, 0.24)
		var raw := Vector2(i * 193.7, i * i * 39.1) + speed * age * depth - camera_offset * depth
		var at := Vector2(fposmod(raw.x, viewport_size.x), fposmod(raw.y, viewport_size.y))
		draw_line(at, at + Vector2(2.5, -0.5) * depth, color, depth, true)
