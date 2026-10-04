@tool
extends Node2D
## Static facade materials and window trim; no terrain, actors or physics.

@export_enum("echo", "cinder") var theme := "echo"
@export var wall_texture: Texture2D
@export var roof_texture: Texture2D
@export var door_texture: Texture2D
const Windows := preload("res://SettlementWindowAtlas.gd")

const CINDER_HOMES := ["BellFoundry", "CaravanInn", "KilnSchool", "ArchiveHall", "CopperLibrary", "GateBarracks", "KilnLoft", "ArcadeShrine", "ArchiveLoft", "WatchHouse"]
var painted: Array[Polygon2D] = []
var window_frames: Array[Rect2] = []
var window_art: Array[Dictionary] = []
var gables: Array[Polygon2D] = []
var wall_feet: Array[Polygon2D] = []
var built := false
var floors: Array[Rect2] = []


func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built or wall_texture == null or roof_texture == null or door_texture == null:
		return
	var room := get_parent()
	var members: Array[Node] = []
	members.assign(room.find_children("*","",true,false))
	floors = preload("res://WorldSupport.gd").floors(members)
	var roots := ["HouseLeft", "HouseMiddle", "HouseRight"] if theme == "echo" else ["HearthHouse", "MarketHouse", "SmithyHouse"]
	for named in roots:
		var home := room.get_node_or_null(named) as Polygon2D
		_paint(home, wall_texture, 144.0)
		_ground_root_wall(home)
	var roofs := ["RoofLeft", "RoofMiddle", "RoofRight"] if theme == "echo" else ["HearthRoof", "MarketRoof", "SmithyRoof"]
	for index in roofs.size():
		var roof := room.get_node_or_null(roofs[index]) as Polygon2D
		_paint(roof, roof_texture, 100.0)
		_close_gable(roof,room.get_node_or_null(roots[index]) as Polygon2D)
	var doors := ["LeftHomeDoorVisual", "MarketDoorVisual", "RightHomeDoorVisual"] if theme == "echo" else ["HearthDoor", "MarketDoor", "SmithyDoor"]
	for named in doors:
		_paint(room.get_node_or_null(named) as Polygon2D, door_texture, 0.0)
	for child in room.get_children():
		if child is Polygon2D and String(child.name).contains("Window"):
			_add_window_frame(child)
	var upper := room.get_node_or_null("UpperVillage")
	var upper_names := ["LanternHouse", "SurveyLoft"] if theme == "echo" else ["BellKeeperHouse", "CaravanLoft"]
	for named in upper_names:
		if upper==null: break
		var home := upper.get_node(named) as Polygon2D
		_paint(home, wall_texture, 144.0)
		_add_roof_cap(home)
		_add_window_frame(upper.get_node(named + "Window") as Polygon2D, home)
	var district := room.get_node_or_null("NewDistricts" if theme == "echo" else "EasternDistricts")
	if district==null: district = room.get_node("GateApproach")
	var home_pattern := RegEx.new()
	home_pattern.compile("^(LowerHome[0-9]+|TerraceHome[0-9]+_[0-9]+)$")
	for child in district.get_children():
		if not child is Polygon2D:
			continue
		var named := String(child.name)
		var home: bool = home_pattern.search(named) != null if theme == "echo" else named in CINDER_HOMES
		if not home:
			continue
		_paint(child, wall_texture, 144.0)
		_ground_root_wall(child)
		if theme == "echo":
			var roof := district.get_node_or_null(named + "Roof") as Polygon2D
			_paint(roof, roof_texture, 100.0)
			_close_gable(roof,child)
			_paint(district.get_node_or_null(named + "Door") as Polygon2D, door_texture, 0.0)
			_paint(district.get_node_or_null(named + "Chimney") as Polygon2D, wall_texture, 144.0)
		else:
			_add_roof_cap(child)
		for sibling in district.get_children():
			if sibling is Polygon2D and String(sibling.name).begins_with(named + "Window"):
					_add_window_frame(sibling,child)
	built = true
	preload("res://SettlementFacadeRelief.gd").install(room, self)
	queue_redraw()


func _close_gable(roof: Polygon2D, home: Polygon2D) -> void:
	if roof==null or home==null or roof.polygon.size()!=6: return
	# The authored roofs are open six-point chevrons. Fill only their inner
	# triangle behind the tiles; otherwise a strip of sky separates roof/wall.
	var gable := Polygon2D.new()
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var wall_origin := _bounds(home).position
	for index in [3,4,5]:
		var point := roof.to_global(roof.polygon[index])
		points.append(to_local(point))
		uv.append((home.to_local(point)-wall_origin)/144.0*wall_texture.get_size())
	gable.name = str(home.name)+"ClosedGable"
	gable.polygon = points
	gable.uv = uv
	gable.texture = wall_texture
	gable.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	gable.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	gable.color = home.color
	gable.z_as_relative = false
	gable.z_index = -2
	add_child(gable)
	gables.append(gable)


func _ground_root_wall(home: Polygon2D) -> void:
	if home==null: return
	var bounds := _bounds(home)
	var at := home.to_global(Vector2(bounds.get_center().x,bounds.end.y))
	var support := preload("res://WorldSupport.gd").below(at,floors,22)
	if not support.has_area(): return
	var floor_y := home.to_local(Vector2(at.x,support.position.y)).y
	var drop := floor_y-bounds.end.y
	if drop<=0 or drop>20: return # Never fill porticos or paths below raised houses.
	var local_points := PackedVector2Array([Vector2(bounds.position.x,bounds.end.y-1),bounds.end-Vector2(0,1),Vector2(bounds.end.x,floor_y),Vector2(bounds.position.x,floor_y)])
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in local_points:
		points.append(to_local(home.to_global(point)))
		uv.append((point-bounds.position)/144.0*wall_texture.get_size())
	var foot := Polygon2D.new()
	foot.name=str(home.name)+"WallFoot"
	foot.polygon=points
	foot.uv=uv
	foot.texture=wall_texture
	foot.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	foot.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	foot.color=home.color
	foot.z_as_relative=false
	foot.z_index=-2
	add_child(foot)
	wall_feet.append(foot)


func _add_window_frame(window: Polygon2D, home: Polygon2D = null) -> void:
	var bounds := _bounds(window)
	var opening := Rect2(to_local(window.to_global(bounds.position)), bounds.size)
	if home == null:
		# Root-quarter windows used to bypass silhouette checks entirely. Resolve
		# the smallest painted wall containing the native opening, not a roof,
		# door or unrelated house that happens to share its height.
		var point := window.to_global(bounds.get_center())
		var area := INF
		for plate in painted:
			if plate.texture != wall_texture: continue
			var wall_bounds := _bounds(plate)
			if wall_bounds.get_area() < area and Geometry2D.is_point_in_polygon(plate.to_local(point), plate.polygon):
				home = plate
				area = wall_bounds.get_area()
	window_frames.append(opening)
	var index := absi(String(window.name).hash())%3 + (3 if theme=="cinder" else 0)
	var image := Windows.texture_for(index)
	var height := clampf(opening.size.y*1.45,15,44)
	var size := image.get_size()*(height/image.get_height())
	var preferred := Rect2(opening.get_center()-size/2,size)
	var fitted := _clear_window(preferred,home)
	if fitted.has_area(): window_art.append({"index":index,"rect":fitted,"preferred":preferred,"home":home})
	# Authored polygon still exists, but its flat luminous rectangle must not
	# shine through the transparent shutter margins of the painted window.
	window.modulate.a = 0

func _clear_window(preferred: Rect2, home: Polygon2D) -> Rect2:
	# The playable balcony is foreground; a window belongs wholly above or
	# below it, never sliced in half. Only painted fixtures move, not platforms.
	var points := PackedVector2Array()
	if home != null:
		for point in home.polygon: points.append(to_local(home.to_global(point)))
	for factor in [1.0,0.82,0.68]:
		var size := preferred.size*float(factor)
		for dy in [0,-24,24,-44,44,-64,64]:
			for dx in [0,-22,22,-40,40]:
				var candidate := Rect2(preferred.get_center()+Vector2(dx,dy)-size/2,size)
				var clear := true
				if not points.is_empty():
					for corner in [candidate.position,Vector2(candidate.end.x,candidate.position.y),candidate.end,Vector2(candidate.position.x,candidate.end.y)]:
						if not Geometry2D.is_point_in_polygon(corner,points): clear=false;break
				if not clear: continue
				var world: Rect2=global_transform*candidate
				for floor_rect in floors:
					if world.intersects(floor_rect.grow(3)): clear=false;break
				for prior in window_art:
					if candidate.intersects(prior.rect.grow(3)): clear=false;break
				if home != null:
					var bounds := _bounds(home)
					var foot := to_local(home.to_global(Vector2(bounds.get_center().x,bounds.end.y)))
					if candidate.intersects(Rect2(foot-Vector2(21,52),Vector2(42,52))): clear=false
				if clear: return candidate
	return Rect2()


func _add_roof_cap(home: Polygon2D) -> void:
	# Trace the existing gable; this cap is decorative, never a new ledge.
	var cap := Polygon2D.new()
	cap.name = String(home.name) + "PaintedRoof"
	cap.z_index = -2
	cap.z_as_relative = false
	var points := PackedVector2Array()
	for index in [1, 2, 3]:
		points.append(to_local(home.to_global(home.polygon[index])))
	for index in [3, 2, 1]:
		points.append(to_local(home.to_global(home.polygon[index])) + Vector2(0, 9))
	cap.polygon = points
	add_child(cap)
	_paint(cap, roof_texture, 100.0)


func _bounds(plate: Polygon2D) -> Rect2:
	var bounds := Rect2(plate.polygon[0], Vector2.ZERO)
	for point in plate.polygon:
		bounds = bounds.expand(point)
	return bounds


func _paint(plate: Polygon2D, texture: Texture2D, tile_size: float) -> void:
	if plate == null or plate.polygon.size() < 3:
		return
	var bounds := _bounds(plate)
	if not bounds.has_area():
		return
	plate.texture = texture
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	plate.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if tile_size > 0 else CanvasItem.TEXTURE_REPEAT_DISABLED
	plate.color = Color(0.85, 0.88, 0.9) if theme == "echo" else Color(0.91, 0.85, 0.8)
	var uv := PackedVector2Array()
	for point in plate.polygon:
		uv.append((point - bounds.position) / (Vector2.ONE * tile_size if tile_size > 0 else bounds.size) * texture.get_size())
	plate.uv = uv
	painted.append(plate)


func _draw() -> void:
	for window in window_art:
		draw_texture_rect(Windows.texture_for(window.index),window.rect,false)
