@tool
extends "res://RoomPaintedDepth.gd"
## Explicitly scoped remaining-room art; no actor, collision or save changes.

@export var artwork := "shaft_cutting"
@export_enum("hub", "shaft", "echo", "ash", "arena", "city", "district", "expedition", "training", "warden") var layout := "arena"
@export var route_path: NodePath
@export var plate_path: NodePath = ^"Backdrop"
var retired: Array[CanvasItem] = []


func _build() -> void:
	if built:
		return
	var texture := load("res://art/visual_slice/%s_depth_v1.png" % artwork) as Texture2D
	if texture == null:
		return
	var room := get_parent()
	var entry := room.get_node_or_null(plate_path) as Polygon2D
	if entry != null:
		plates.append(entry)
	var route := room.get_node_or_null(route_path) if not route_path.is_empty() else null
	if layout == "ash" and route != null:
		for index in range(route.CHAMBER_LAYOUTS[String(route.course_id)].size()):
			var chamber: Rect2 = route._chamber_rect(index)
			_create_plate("Gallery%d" % index, route._chamber_silhouette(chamber, index), route)
			if index + 1 < route.CHAMBER_LAYOUTS[String(route.course_id)].size():
				var next: Rect2 = route._chamber_rect(index + 1)
				var x := (maxf(chamber.position.x, next.position.x) + minf(chamber.end.x, next.end.x)) * 0.5
				var top := minf(chamber.position.y, next.position.y)
				var bottom := maxf(chamber.end.y, next.end.y)
				_create_plate("Shaft%d" % index, PackedVector2Array([Vector2(x - 112, top), Vector2(x + 112, top), Vector2(x + 112, bottom), Vector2(x - 112, bottom)]), route)
		route.painted_depth_enabled = true
		route.queue_redraw()
	elif route != null:
		for node in route.get_children():
			if node is Polygon2D and _is_plate(String(node.name)):
				plates.append(node)
	if plates.is_empty():
		push_warning("No authored background masks for " + artwork)
		return
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
	if layout == "city":
		material_shared.shader = preload("res://art/visual_slice/city_panorama.gdshader")
	var ratio := art_bounds.size.x / art_bounds.size.y / (float(texture.get_width()) / texture.get_height())
	material_shared.set_shader_parameter("crop", Vector2(minf(ratio, 1), minf(1 / ratio, 1)))
	# The city sky must stay upright: no vertically repeated rooflines.
	material_shared.set_shader_parameter("scene_scale", 1.0 if layout == "city" else maxf(1, art_bounds.size.x / 1800.0))
	var warm := artwork in ["ash_causeway", "ember_barracks", "slag_reservoir", "ash_chapel", "ash_coliseum", "castellan_throne", "emberspine", "ash_road"]
	material_shared.set_shader_parameter("haze_color", Color("3b2427") if warm else Color("1b2c3c"))
	material_shared.set_shader_parameter("brightness", 0.66 if layout == "city" else 0.58)
	for plate in plates:
		var uv := PackedVector2Array()
		for point in plate.polygon:
			uv.append((to_local(plate.to_global(point)) - art_bounds.position) / art_bounds.size * texture.get_size())
		plate.texture = texture
		plate.uv = uv
		plate.color = Color.WHITE
		plate.material = material_shared
		plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Hide only known, childless distant decoration. Never gameplay parents.
	var decoration_root: Node = route if route != null else room
	if layout == "training":
		decoration_root = room.get_node_or_null("GeneratedPassageDetails")
	if decoration_root != null:
		for node in decoration_root.get_children():
			if (node is Polygon2D or node is Line2D) and node.get_child_count() == 0 and _is_retired(String(node.name)):
				node.hide()
				retired.append(node)
	finish_report = preload("res://RoomArtFinish.gd").apply(room, "starfall" if layout == "city" else ("ash" if warm else "echo"))
	if layout == "training" and decoration_root != null:
		var gate := decoration_root.get_node_or_null("GateArch") as Polygon2D
		if gate != null:
			preload("res://RoomArtFinish.gd")._material(gate, preload("res://art/visual_slice/echo_path_stone_v1.png"), Color("7a9299"))
	retired.append_array(finish_report.retired)
	built = true


func _is_plate(named: String) -> bool:
	match layout:
		"shaft":
			return named.begins_with("ChamberShadow") or named.begins_with("ChamberShaftShadow") or named == "HistoricLampAlcove" or (named.begins_with("Branch") and named.ends_with("_Shadow"))
		"echo":
			return named.begins_with("ChamberPocket") or named.begins_with("RouteShaft") or (named.begins_with("Tier") and named.ends_with("BranchChamber"))
		"hub":
			return ((named.begins_with("MineChamber") or named.begins_with("SideCave")) and named.ends_with("Backdrop")) or named.begins_with("MineShaft") or named.begins_with("SideTunnel") or named == "BrokenHoistVoid"
		"district":
			return named.begins_with("DistrictPocket") or named.begins_with("DistrictShaft")
		"expedition":
			return ((named.begins_with("MainChamber") or named.begins_with("BranchChamber")) and named.ends_with("Backdrop")) or named.begins_with("MainShaft") or named.begins_with("BranchPassage") or named == "OptionalLoop"
	return false


func _is_retired(named: String) -> bool:
	if layout == "training":
		return named.begins_with("CaveTooth") or named.begins_with("CeilingShard") or named.begins_with("SentinelPillar") or named.begins_with("SentinelRune") or named == "SentinelDais" or named.begins_with("AqueductArch") or named == "OldWaterLine"
	if artwork == "ash_coliseum":
		return named in ["Grandstand", "RearArch", "ArchVoid", "BackRows", "WestBoundaryFlare", "EastBoundaryFlare", "TorchLeft", "TorchRight"]
	if artwork == "castellan_throne":
		return named in ["Vault", "BackThrone", "ThroneTrim", "ThroneGlow"]
	if artwork == "resonance_sanctum":
		return named in ["Vault", "CoreGlow", "ResonanceArc", "RearRibs", "SanctumCrown", "CoreShard", "PulseRail", "BoundaryGleam"]
	if artwork == "warden_arena":
		return named in ["ArenaGlow", "ArenaCrystal"]
	match layout:
		"shaft":
			return named.begins_with("Pier")
		"hub":
			return (named.begins_with("MineChamber") or named.begins_with("SideCave")) and (named.contains("Support") or named.contains("Brace"))
		"district":
			return named.begins_with("CavernRib")
	return false
