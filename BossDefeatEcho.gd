extends Sprite2D
## Snapshot only: collision/rewards/defeat signals still finish immediately.
const DURATION := 0.55
const GROUP := "boss_defeat_echo"
var age := 0.0
var origin := Vector2.ZERO

static func spawn(art: Sprite2D, tint: Color) -> Sprite2D:
	if not is_instance_valid(art) or not art.is_inside_tree() or not art.is_visible_in_tree():
		return null
	var parent := art.get_parent().get_parent()
	if parent == null or parent.is_queued_for_deletion():
		return null
	var tree := art.get_tree()
	var transition := tree.root.get_node_or_null("RoomTransition")
	if (transition != null and transition.is_transitioning) or tree.get_nodes_in_group("boss_cosmetic_effect").size() >= 64:
		return null
	if art.has_method("rendered_sprite"): art=art.rendered_sprite()
	var echo := new()
	echo.texture = art.texture
	echo.texture_filter = art.texture_filter
	echo.hframes = art.hframes
	echo.vframes = art.vframes
	echo.frame = art.frame
	echo.offset = art.offset
	echo.flip_h = art.flip_h
	echo.flip_v = art.flip_v
	echo.centered = art.centered
	var dissolve := ShaderMaterial.new()
	dissolve.shader = preload("res://shaders/boss_defeat_dissolve.gdshader")
	dissolve.set_shader_parameter("frame_grid", Vector2(art.hframes, art.vframes))
	if art.material is ShaderMaterial:
		if art.material.shader==preload("res://shaders/living_frame_isolation.gdshader"):
			dissolve.set_shader_parameter("use_living_mask",true)
			for parameter in ["source_rect","spans"]: dissolve.set_shader_parameter(parameter,art.material.get_shader_parameter(parameter))
		else:
			for parameter in ["frame_bounds", "exclude_upper_left"]:
				dissolve.set_shader_parameter(parameter, art.material.get_shader_parameter(parameter))
	dissolve.set_shader_parameter("edge_color", tint)
	echo.material = dissolve
	echo.z_index = 2
	parent.add_child(echo)
	echo.global_transform = art.global_transform
	echo.origin = art.global_position
	return echo

func _ready() -> void:
	add_to_group(GROUP)
	add_to_group("boss_cosmetic_effect")
	visibility_changed.connect(_on_visibility_changed)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.room_changed.connect(_retire)
		state.checkpoint_resting.connect(_retire)
	var transition := get_node_or_null("/root/RoomTransition")
	if transition != null:
		transition.transition_started.connect(_retire)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_retire()

func _retire(_unused: String = "") -> void:
	hide()
	queue_free()

func _process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	age += delta
	if age >= DURATION:
		_retire()
		return
	var progress := clampf(age / DURATION, 0, 1)
	material.set_shader_parameter("dissolve_progress", progress)
	self_modulate.a = 1.0 - progress * 0.65
	global_position = origin + Vector2(0, -14 * progress)
