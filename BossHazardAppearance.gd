extends Node2D
## Decorative outline follows the exact existing warning node and visibility.
## The original marker is retained, including its gameplay-owned position.
var tint := Color.WHITE
var style := "lane"
var radius := 32.0
var age := 0.0
var presenter: Node2D
var peak_remaining := 0.0
var charge_progress := 0.0
var preparing := false
var animation_frame := 0

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_reset_preparation()

func _reset_preparation() -> void:
	age = 0
	peak_remaining = 0
	charge_progress = 0
	preparing = false
	animation_frame = 0
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		_reset_preparation()
		return
	age += delta
	if is_instance_valid(presenter):
		var remaining: float = presenter.sample_windup()
		preparing = remaining > 0
		peak_remaining = maxf(peak_remaining, remaining)
		charge_progress = clampf(1.0 - remaining / maxf(peak_remaining, 0.001), 0.0, 1.0)
		animation_frame = 0 if charge_progress < 0.5 else 1
	queue_redraw()

func _draw() -> void:
	var pulse := 0.7 + sin(age * 9) * 0.15
	if preparing and style != "line":
		var material_id := 15
		var base := Vector2.ZERO
		if style == "ember":
			material_id = 13
			base.y = 27
		elif style == "column":
			material_id = 14
			base.y = 190
		elif style == "lane" and is_instance_valid(presenter) and presenter.art.boss_id != "hollow_sovereign":
			material_id = 14
		# Early frames stay low and translucent; the native boundary stays clear.
		preload("res://CombatFlipbook.gd").stamp(self, material_id, animation_frame, Rect2(base + Vector2(-radius * 0.6, -24), Vector2(radius * 1.2, 24)), Color(1, 1, 1, 0.45), true)
	if style == "line":
		var line := get_parent() as Line2D
		if line.points.size() < 2:
			return
		var start := line.points[0]
		var finish := line.points[line.points.size() - 1]
		var direction := (finish - start).normalized()
		var normal := direction.orthogonal()
		for i in range(1, 5):
			var point := start.lerp(finish, i / 5.0)
			draw_polyline(PackedVector2Array([point - direction * 5 + normal * 4, point, point - direction * 5 - normal * 4]), Color(tint, pulse), 1.1, true)
		var leading := start.lerp(finish, charge_progress)
		draw_line(leading - normal * 4, leading + normal * 4, tint.lightened(0.5), 1.5, true)
	elif style == "column":
		for side in [-1, 1]:
			draw_line(Vector2(side * radius, -190), Vector2(side * radius, 190), Color(tint, pulse), 1.2, true)
		for i in range(4):
			var y := fmod(age * 90 + i * 95, 380) - 190
			draw_line(Vector2(-radius * 0.6, y - 7), Vector2(0, y), Color(tint, 0.4), 1.0, true)
			draw_line(Vector2(0, y), Vector2(radius * 0.6, y - 7), Color(tint, 0.4), 1.0, true)
	else:
		var origin := Vector2(0, 27) if style == "ember" else Vector2.ZERO
		if style in ["lane", "ember"]:
			draw_set_transform(origin, 0, Vector2(1, 0.13))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(tint, pulse), 1.8, true)
		draw_arc(Vector2.ZERO, radius * 0.78, age * 0.9, age * 0.9 + PI * 1.6, 48, Color(tint, 0.45), 1, true)
		if charge_progress > 0.01:
			draw_arc(Vector2.ZERO, radius * 0.93, -PI * 0.5, -PI * 0.5 + TAU * charge_progress, 64, Color(tint.lightened(0.45), 0.8), 1.5, true)
		draw_set_transform(Vector2.ZERO)
		for side in [-1.0, 1.0]:
			var point := origin + Vector2(side * radius, 0)
			draw_line(point + Vector2(0, -5), point + Vector2(0, 5), Color(tint, pulse), 1.5, true)
