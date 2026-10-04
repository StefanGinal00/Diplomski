@tool
extends Node2D
## Explicit room-scoped paintings, clipped to existing background silhouettes.

const DEPTH_SHADER := preload("res://art/visual_slice/room_depth.gdshader")
const STAR_PROFILES := ["memory", "rampart", "silent_gate", "rooted", "crucible", "sunless"]
@export_enum("cistern", "prism", "forge", "memory", "rampart", "silent_gate", "rooted", "crucible", "sunless") var profile := "cistern"
@export var entry_plate_path: NodePath = ^"Backdrop"
var plates: Array[Polygon2D] = []
var created: Array[Polygon2D] = []
var material_shared: ShaderMaterial
var art_bounds := Rect2()
var built := false
var update_clock := 0.0
var update_count := 0
var finish_report: Dictionary = {}


func _ready() -> void:
	call_deferred("_build")
	if Engine.is_editor_hint():
		set_process(false)


func _build() -> void:
	if built:
		return
	var room := get_parent()
	var texture := load("res://art/visual_slice/%s_depth_v1.png" % profile) as Texture2D
	if texture == null:
		return
	if profile == "forge":
		var route := room.get_node("AshSwitchback")
		# The Ash renderer combines background and terrain in one draw call.
		# Replace only its fills; all terrain and traversal hints remain drawn.
		for index in range(route.CHAMBER_LAYOUTS[String(route.course_id)].size()):
			var chamber: Rect2 = route._chamber_rect(index)
			_create_plate("Gallery%d" % index, route._chamber_silhouette(chamber, index), route)
			if index < route.CHAMBER_LAYOUTS[String(route.course_id)].size() - 1:
				var next: Rect2 = route._chamber_rect(index + 1)
				var x := (maxf(chamber.position.x, next.position.x) + minf(chamber.end.x, next.end.x)) * 0.5
				var top := minf(chamber.position.y, next.position.y)
				var bottom := maxf(chamber.end.y, next.end.y)
				_create_plate("Shaft%d" % index, PackedVector2Array([Vector2(x - 112, top), Vector2(x + 112, top), Vector2(x + 112, bottom), Vector2(x - 112, bottom)]), route)
		plates.append(room.get_node("FurnaceWall"))
		route.painted_depth_enabled = true
		route.queue_redraw()
	else:
		plates.append(room.get_node(entry_plate_path))
		var route: Node = room.get_node("LongTraversal") if profile == "prism" else room.get_node("ExpandedRoute/StarfallDescent" if profile in STAR_PROFILES else "ExpandedRoute/AuthoredDescent")
		for node in route.get_children():
			if not node is Polygon2D:
				continue
			var named := String(node.name)
			if named.begins_with("ChamberShadow") or named.begins_with("ChamberShaftShadow") or named == "HistoricLampAlcove" or named.begins_with("ChamberPocket") or named.begins_with("RouteShaft") or (named.begins_with("Tier") and named.ends_with("BranchChamber")) or (named.begins_with("Branch") and named.ends_with("_Shadow")) or (named.begins_with("Niche") and named.ends_with("_Alcove")):
				plates.append(node)
	var first := true
	for plate in plates:
		for point in plate.polygon:
			var local := to_local(plate.to_global(point))
			if first:
				art_bounds = Rect2(local, Vector2.ZERO)
				first = false
			else:
				art_bounds = art_bounds.expand(local)
	if not art_bounds.has_area():
		return
	material_shared = ShaderMaterial.new()
	material_shared.shader = DEPTH_SHADER
	var ratio := art_bounds.size.x / art_bounds.size.y / (texture.get_width() / float(texture.get_height()))
	material_shared.set_shader_parameter("crop", Vector2(minf(ratio, 1), minf(1 / ratio, 1)))
	# Bound world-space magnification in EVERY room, not only Starfall.
	material_shared.set_shader_parameter("scene_scale", maxf(1, art_bounds.size.x / 1800.0))
	if profile == "cistern":
		# Keep the dry entrance against masonry, not the painting's water band.
		material_shared.set_shader_parameter("texture_phase", Vector2(0, -0.35))
	var haze := Color("16363d")
	var brightness := 0.66
	match profile:
		"forge": haze = Color("443039")
		"prism", "memory": haze = Color("242b43")
		"rampart": haze = Color("363047")
		"silent_gate": haze = Color("282a43")
		"rooted": haze = Color("233c35")
		"crucible": haze = Color("382541")
		"sunless": haze = Color("181f34")
	if profile in STAR_PROFILES:
		brightness = 0.55 if profile != "sunless" else 0.62
	material_shared.set_shader_parameter("haze_color", haze)
	material_shared.set_shader_parameter("brightness", brightness)
	for plate in plates:
		var uv := PackedVector2Array()
		for point in plate.polygon:
			uv.append((to_local(plate.to_global(point)) - art_bounds.position) / art_bounds.size * texture.get_size())
		plate.texture = texture
		plate.uv = uv
		plate.color = Color.WHITE
		plate.material = material_shared
		plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	finish_report = preload("res://RoomArtFinish.gd").apply(room, "starfall" if profile in STAR_PROFILES else ("ash" if profile == "forge" else "echo"))
	built = true


func _create_plate(named: String, points: PackedVector2Array, source: Node2D) -> void:
	var plate := Polygon2D.new()
	plate.name = named
	plate.z_index = -3
	var local := PackedVector2Array()
	for point in points:
		local.append(to_local(source.to_global(point)))
	plate.polygon = local
	add_child(plate)
	plates.append(plate)
	created.append(plate)


func _process(delta: float) -> void:
	if not built or not is_visible_in_tree() or Engine.is_editor_hint():
		return
	update_clock += delta
	if update_clock < 0.05:
		return
	update_clock = 0
	var camera := to_local(get_viewport().canvas_transform.affine_inverse() * (get_viewport_rect().size * 0.5))
	var offset := (camera - art_bounds.get_center()) / art_bounds.size
	# Oppose camera travel: distant painted details move slower than terrain.
	material_shared.set_shader_parameter("camera_shift", (-offset * 0.08).clamp(Vector2(-0.055, -0.055), Vector2(0.055, 0.055)))
	material_shared.set_shader_parameter("haze_shift", (-offset * 0.025).clamp(Vector2(-0.055, -0.055), Vector2(0.055, 0.055)))
	update_count += 1
