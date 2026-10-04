extends Node2D
## Seven encounter identities plus the ordinary stone sentinel's thorn dart.
const Art = preload("res://EnemyAttackArt.gd")
var tint := Color.WHITE
var style := ""
var age := 0.0
var awakened := false
var animation_frame := 1

func _ready() -> void:
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	get_parent().get_node("Core").hide()
	get_parent().get_node("Glow").hide()

func _process(delta: float) -> void:
	age += delta
	animation_frame = Art.Flipbook.phase(age, 0.3, true)
	queue_redraw()

func _draw() -> void:
	# Solid core remains close to the unchanged radius-4 projectile collider.
	draw_circle(Vector2.ZERO, 5, Color(tint, 0.06))
	var tail := PackedVector2Array([Vector2(-23, sin(age * 19) * 2), Vector2(-14, -1), Vector2(-7, 1), Vector2.ZERO])
	draw_polyline(tail, Color(tint, 0.18), 1.0, true)
	var index: int = Art.PROJECTILES.get(style, 7)
	# Register the dense head on the unchanged radius-4 collider, not the tail.
	var pivot := 0.78
	if style == "starfall_guardian":
		pivot = 0.5
	elif style == "ember_marshal":
		pivot = 0.72
	var height := 15.0 + sin(age * 22) * 0.6
	if style == "ash_sentry":
		# Flame rises in the atlas; rotate it into the bolt's travel direction.
		draw_set_transform(Vector2.ZERO, PI * 0.5)
		Art.Flipbook.stamp(self, index, animation_frame, Rect2(-height * 0.5, -8, height, 24))
		draw_set_transform(Vector2.ZERO)
	else:
		Art.Flipbook.stamp(self, index, animation_frame, Rect2(-24 * pivot, -height * 0.5, 24, height))
	if awakened:
		# Preserve sentry's upgraded purple cue without recoloring its identity.
		draw_arc(Vector2.ZERO, 6, age * 8, age * 8 + PI, 16, Color("c789ec"), 1.0, true)
	draw_circle(Vector2.ZERO, 1.1, Color("fff3e2"))

func impact() -> void:
	var burst := preload("res://BossBurst.gd").spawn(get_parent().get_parent(), global_position, tint, "impact", Vector2(14, 14), 0.18, Art.PROJECTILES.get(style, 7))
	if burst != null:
		# Direction is world-space movement, independent of the room transform.
		burst.global_transform = Transform2D(get_parent().direction.angle(), global_position)
		burst.paint_rotation = PI * 0.5 if style == "ash_sentry" else 0.0
