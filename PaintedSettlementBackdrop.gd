@tool
extends Node2D
## Repaints only explicitly selected background polygons; never changes terrain.

const ATMOSPHERE := preload("res://art/visual_slice/settlement_atmosphere.gdshader")

@export var backdrop_texture: Texture2D
@export var plate_paths: Array[NodePath] = []
@export var hide_paths: Array[NodePath] = []
@export var top_fade_paths: Array[NodePath] = []
@export_range(0.0, 300.0) var top_fade_pixels := 140.0

var plates: Array[Polygon2D] = []
var built := false
var update_clock := 0.0


func _ready() -> void:
	call_deferred("_build")


func _build() -> void:
	if built or backdrop_texture == null:
		return
	var room := get_parent()
	# Neighbouring pockets/shafts in one district share a single image space,
	# rather than repeating the same roofline independently on every floor.
	var district_bounds := {}
	for path in plate_paths:
		var plate := room.get_node_or_null(path) as Polygon2D
		if plate == null or plate.polygon.size() < 3:
			continue
		var bounds := Rect2(plate.transform * plate.polygon[0], Vector2.ZERO)
		for point in plate.polygon:
			bounds = bounds.expand(plate.transform * point)
		var district := plate.get_parent()
		district_bounds[district] = bounds.merge(district_bounds[district]) if district_bounds.has(district) else bounds
	for path in plate_paths:
		var plate := room.get_node_or_null(path) as Polygon2D
		if plate == null or plate.polygon.size() < 3:
			push_warning("Settlement background missing: " + str(path))
			continue
		var bounds: Rect2 = district_bounds[plate.get_parent()]
		if not bounds.has_area():
			continue
		plate.texture = backdrop_texture
		plate.color = Color(0.78, 0.78, 0.78, 1.0)
		plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var uv := PackedVector2Array()
		for point in plate.polygon:
			uv.append((plate.transform * point - bounds.position) / bounds.size * backdrop_texture.get_size())
		plate.uv = uv
		var paint := ShaderMaterial.new()
		paint.shader = ATMOSPHERE
		var ratio := bounds.size.x / bounds.size.y / (float(backdrop_texture.get_width()) / backdrop_texture.get_height())
		paint.set_shader_parameter("crop", Vector2(minf(ratio, 1.0), minf(1.0 / ratio, 1.0)))
		paint.set_shader_parameter("top_fade", minf(top_fade_pixels / bounds.size.y, 0.45) if path in top_fade_paths else 0.0)
		plate.material = paint
		plate.set_meta("settlement_art_bounds", bounds)
		plates.append(plate)
	if not plates.is_empty():
		for path in hide_paths:
			var old := room.get_node_or_null(path) as Polygon2D
			if old != null:
				old.hide()
	built = true
	if Engine.is_editor_hint():
		set_process(false)


func _process(delta: float) -> void:
	if not built or not is_visible_in_tree() or Engine.is_editor_hint():
		return
	update_clock += delta
	if update_clock < 0.05:
		return
	update_clock = 0.0
	var center := get_viewport().canvas_transform.affine_inverse() * (get_viewport_rect().size * 0.5)
	for plate in plates:
		if not is_instance_valid(plate):
			continue
		var bounds: Rect2 = plate.get_meta("settlement_art_bounds")
		var shift := ((plate.get_parent() as Node2D).to_local(center) - bounds.get_center()) / bounds.size * 0.04
		plate.material.set_shader_parameter("camera_shift", shift.clamp(Vector2(-0.055, -0.055), Vector2(0.055, 0.055)))
