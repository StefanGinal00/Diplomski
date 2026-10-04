extends TextureRect
## Screen-covering distant plane: jumping or falling cannot reveal an art edge.
var origin := Vector2.ZERO
var camera_uv := Vector2.ZERO
var view_uv := Vector2.ONE
var city_horizon := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material = ShaderMaterial.new()
	material.shader = preload("res://art/visual_slice/camera_backdrop.gdshader")

func use_paint(paint: Texture2D, room_origin: Vector2, family: String) -> void:
	texture = paint
	origin = room_origin
	city_horizon = family=="starfall_citadel"
	material.set_shader_parameter("city_horizon",city_horizon)
	material.set_shader_parameter("fog_color", Color("251b22") if family.begins_with("ash") else (Color("131526") if family.begins_with("starfall") else Color("091c25")))
	_process(0)

func _process(_delta: float) -> void:
	if texture == null or not is_inside_tree(): return
	var canvas := get_viewport().canvas_transform.affine_inverse()
	var viewport_size := get_viewport_rect().size
	var center := canvas * (viewport_size * 0.5)
	# 2 source pixels per world unit; no stretching one painting over a 6000px room.
	var world_tile := texture.get_size() * 0.5
	view_uv = (canvas.basis_xform(viewport_size)).abs() / world_tile
	camera_uv = (center - origin) * (Vector2(0.08,0.035) if city_horizon else Vector2(0.24, 0.18)) / world_tile
	material.set_shader_parameter("camera_uv", camera_uv)
	material.set_shader_parameter("view_uv", view_uv)
