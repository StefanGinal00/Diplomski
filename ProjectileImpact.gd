extends Node2D

## Short cosmetic contact burst; no physics, damage, timers or global RNG.
const MAX_ACTIVE := 24
const DURATION := 0.22
const GROUP := "projectile_impact"
const PAINTED_MATERIALS := {"thorn": 7, "ember": 13, "arc": 0, "frost": 16}
var style := "arrow"
var tint := Color.WHITE
var contact_kind := "actor"
var age := 0.0
var redraw_clock := 0.0


static func spawn(emitter: Node2D, point: Vector2, aim: Vector2, effect_style: String, color: Color, kind: String) -> Node2D:
	if not is_instance_valid(emitter) or not emitter.is_inside_tree():
		return null
	var parent := emitter.get_parent()
	var tree := emitter.get_tree()
	var transition := tree.root.get_node_or_null("RoomTransition")
	if parent == null or parent.is_queued_for_deletion() or (transition != null and transition.is_transitioning):
		return null
	if not emitter.is_visible_in_tree() or (parent is CanvasItem and not parent.is_visible_in_tree()):
		return null
	if tree.get_nodes_in_group(GROUP).size() >= MAX_ACTIVE:
		return null
	var burst := new()
	burst.style = effect_style
	burst.tint = color
	burst.contact_kind = kind
	burst.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(burst)
	burst.global_transform = Transform2D(aim.angle(), point)
	return burst


func _ready() -> void:
	add_to_group(GROUP)
	z_index = 8
	# Pausing freezes this brief effect; room changes/rest discard it outright.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	visibility_changed.connect(_visibility_changed)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.room_changed.connect(_retire)
		state.checkpoint_resting.connect(_retire)
	var transition := get_node_or_null("/root/RoomTransition")
	if transition != null:
		transition.transition_started.connect(_retire)
	queue_redraw()


func _retire(_unused: String = "") -> void:
	hide()
	queue_free()


func _visibility_changed() -> void:
	if not is_visible_in_tree():
		queue_free()


func _process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	age += delta
	if age >= DURATION:
		_retire()
		return
	redraw_clock += delta
	if redraw_clock >= 1.0 / 30.0:
		redraw_clock = 0.0
		queue_redraw()


func _draw() -> void:
	var progress := clampf(age / DURATION, 0.0, 1.0)
	if style == "crate_break":
		_draw_crate_break(progress)
		return
	if style in ["player_hurt", "player_rescue"]:
		_draw_player_contact(progress)
		return
	if style in ["slash", "spirit_slash"]:
		_draw_slash(progress)
		return
	var fade := 1.0 - progress
	var color := tint
	var radius := 3.0 + progress * 13.0
	if contact_kind == "terrain":
		color = tint.lerp(Color("a7abb4"), 0.55)
		radius *= 0.65
	elif contact_kind == "breakable":
		color = tint.lerp(Color("c69865"), 0.45)
	if PAINTED_MATERIALS.has(style):
		# Painted breakup replaces the generic ring AND the large line-star.
		# Keep the plain arrow's physical spark language separate.
		_draw_painted_contact(progress, color)
		# A small contact glint keeps dark materials readable at gameplay zoom;
		# it fades early and is not a second radial line-star.
		var glint := maxf(0, 1.0 - progress * 2.5)
		var at := Vector2(-1.5, 0) if contact_kind == "terrain" else Vector2.ZERO
		draw_circle(at, 1.3 * glint, Color(color.lightened(0.75), glint))
		return
	for index in range(4):
		# Terrain sparks fan back toward the incoming shot, not into the wall.
		var angle := PI * 0.65 + index * PI * 0.14 if contact_kind == "terrain" else index * TAU / 4.0 + 0.3
		var ray := Vector2.RIGHT.rotated(angle)
		var tip := ray * radius
		if contact_kind == "breakable":
			tip.y += progress * progress * 6.0
		draw_line(tip - ray * (2.0 + fade * 3.0), tip, Color(color, fade), 1.0, true)
	if progress < 0.35:
		draw_line(Vector2(-3, 0), Vector2(3, 0), Color(1, 0.96, 0.83, fade), 1.3, true)

func painted_frame() -> int:
	# A contact starts with breakup, never a charge/flight frame.
	return 4 if age < DURATION * 0.5 else 5

func painted_rect() -> Rect2:
	var progress := clampf(age / DURATION, 0, 1)
	var radius := (8.0 + progress * 5.0) * (0.65 if contact_kind == "terrain" else 1.0)
	# The local positive X axis points into the wall. Keep the full square,
	# including rotated flame art, on the incoming side of the contact plane.
	return Rect2(Vector2(-radius * 2 if contact_kind == "terrain" else -radius, -radius), Vector2.ONE * radius * 2)

func _draw_painted_contact(progress: float, color: Color) -> void:
	var rect := painted_rect()
	var center := rect.get_center()
	draw_set_transform(center, PI * 0.5 if style == "ember" else 0.0)
	# A light tint preserves the atlas highlights instead of multiplying dark
	# blue/violet pixels to black (especially the thorn and Sunder variants).
	var highlight := color.lightened(0.65) * 1.6
	highlight.a = 1.0 - progress
	preload("res://CombatFlipbook.gd").stamp(self, PAINTED_MATERIALS[style], painted_frame(), Rect2(-rect.size * 0.5, rect.size), highlight)
	draw_set_transform(Vector2.ZERO)


func _draw_crate_break(progress: float) -> void:
	# Deterministic splinters share the existing effect cap and room cleanup.
	# No physical debris, random calls, loot or persistent broken-crate nodes.
	for index in range(6):
		var direction := Vector2.RIGHT.rotated(-2.8 + index * 0.51)
		var tip := direction * (4.0 + progress * 18.0)
		tip.y += progress * progress * 15.0
		var edge := direction.rotated(index * 0.7 + progress) * 3.5
		draw_line(tip - edge, tip + edge, Color(tint.lightened(0.12 if index % 2 == 0 else 0.0), 1.0 - progress), 2.1, true)
		draw_line(tip - edge, tip, Color(tint.lightened(0.35), 1.0 - progress), 0.7, true)


func _draw_slash(progress: float) -> void:
	var fade := 1.0 - progress
	var color := tint.lerp(Color("ca9b6b"), 0.5) if contact_kind == "breakable" else tint
	var length := 7.0 + progress * 6.0
	var curve := PackedVector2Array([Vector2(-3, -length), Vector2(0, -length * 0.45), Vector2(1.5, 0), Vector2(0, length * 0.45), Vector2(-3, length)])
	if style == "spirit_slash":
		draw_polyline(curve, Color(color, fade * 0.2), 3.8, true)
	draw_polyline(curve, Color(color, fade * 0.85), 1.4, true)
	draw_line(Vector2(0, -3 * fade), Vector2(1, 3 * fade), Color(1, 0.98, 0.85, fade), 0.8, true)
	for index in range(4):
		var ray := Vector2.RIGHT.rotated(-1.05 + index * 0.7)
		var tip := ray * (3.0 + progress * 12.0)
		if contact_kind == "breakable":
			tip.y += progress * progress * 7.0
		draw_line(tip - ray * 2.5, tip, Color(color, fade), 0.9, true)


func _draw_player_contact(progress: float) -> void:
	var fade := 1.0 - progress
	var radius := 6.0 + progress * 12.0
	var rescued := style == "player_rescue"
	if rescued:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(tint, fade * 0.7), 1.0, true)
	else:
		draw_arc(Vector2.ZERO, radius * 0.7, -1.1, 1.1, 12, Color(tint, fade * 0.5), 0.9, true)
	for index in range(6 if rescued else 4):
		var angle := index * TAU / 6.0 if rescued else -1.0 + index * 0.66
		var ray := Vector2.RIGHT.rotated(angle)
		var tip := ray * radius
		draw_line(tip - ray * (2 + fade * 2), tip, Color(tint, fade), 0.9, true)
