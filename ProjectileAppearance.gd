extends Node2D

## Local-space art follows the existing projectile rotation/scale.
## Flight art has no physics. Accepted contact can spawn a bounded cosmetic burst.
const Impact = preload("res://ProjectileImpact.gd")
const Flipbook = preload("res://CombatFlipbook.gd")
@export var magical := false
var style := ""
var core_color := Color.WHITE
var active := false
var phase := 0.0
var redraw_clock := 0.0
var flight_age := 0.0
var animation_frame := 1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visibility_changed.connect(_on_visibility_changed)
	get_parent().contacted.connect(_on_contacted)
	_process(0)


func _on_contacted(kind: String, point: Vector2) -> void:
	# Contact is reported before the projectile hides. This is contact feedback,
	# not a claim that an invulnerable target accepted damage.
	_process(0)
	if active:
		Impact.spawn(get_parent(), point, get_parent().direction, style, core_color, kind)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		active = false
		phase = 0.0
		redraw_clock = 0.0
		flight_age = 0.0
		animation_frame = 1
		queue_redraw()


func _process(delta: float) -> void:
	var actor := get_parent()
	if not is_visible_in_tree() or actor.stopped or actor.is_queued_for_deletion():
		if active:
			active = false
			queue_redraw()
		return
	var next_style: String
	var next_color: Color
	if magical:
		next_style = "frost" if actor.spell_id == "frost_orb" else "arc"
		next_color = actor.get_node("Core").color
	else:
		next_style = "ember" if actor.arrow_type == "ember_arrow" else ("thorn" if actor.weapon_id == "thorn_bow" else "arrow")
		next_color = actor.get_node("Head").color
	var changed := not active or style != next_style or core_color != next_color
	if changed:
		flight_age = 0.0
		animation_frame = 1
		if magical:
			if material == null:
				material = ShaderMaterial.new()
				material.shader = preload("res://shaders/player_projectile_palette.gdshader")
			material.set_shader_parameter("accent", next_color)
	style = next_style
	core_color = next_color
	active = true
	if magical or style == "ember":
		flight_age += delta
		var next_frame := Flipbook.phase(flight_age, 0.3, true)
		changed = changed or animation_frame != next_frame
		animation_frame = next_frame
		phase = fmod(phase + delta * 8.0, TAU)
		redraw_clock += delta
	if changed or redraw_clock >= 1.0 / 30.0:
		redraw_clock = 0.0
		queue_redraw()


func _draw() -> void:
	if not active:
		return
	if style in ["arrow", "thorn", "ember"]:
		_draw_arrow()
	elif style == "frost":
		_draw_frost()
	else:
		_draw_arc()


func _draw_arrow() -> void:
	if style == "ember":
		# Upward-painted flame turns toward travel; tail stays behind the tip.
		draw_set_transform(Vector2(5, 0), PI * 0.5)
		Flipbook.stamp(self, 13, animation_frame, Rect2(-5, -4, 10, 20))
		draw_set_transform(Vector2.ZERO)
	var feather := Color("84ae8a") if style == "thorn" else Color("c7bda1")
	draw_line(Vector2(-8, 0), Vector2(5, 0), Color("967147"), 1.1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(3, -2), Vector2(9, 0), Vector2(3, 2), Vector2(4, 0)]), core_color)
	for side in [-1.0, 1.0]:
		draw_line(Vector2(-8, side * 2), Vector2(-5, 0), feather, 1.0, true)
		if style == "thorn":
			draw_line(Vector2(-2, 0), Vector2(-4, side * 2), core_color, 0.8, true)
	if style == "ember":
		draw_line(Vector2(4, 0), Vector2(7, 0), Color("fff1b0"), 0.8, true)


func _draw_arc() -> void:
	# Register the dense head near the existing radius-7 damage body.
	Flipbook.stamp(self, 0, animation_frame, flight_rect(), Color(1.25, 1.25, 1.25, 1))
	draw_circle(Vector2.ZERO, 1.2, Color("fff3ff"))


func _draw_frost() -> void:
	Flipbook.stamp(self, 16, animation_frame, flight_rect(), Color(1.15, 1.15, 1.15, 1))
	draw_circle(Vector2.ZERO, 1.0, Color("eaffff"))

func flight_rect() -> Rect2:
	return Rect2(-17.16, -9, 22, 18) if style == "frost" else Rect2(-20.28, -7.5, 26, 15)
