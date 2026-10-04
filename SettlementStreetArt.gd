@tool
extends Node2D
## Static replacements for explicitly named decorative polygons only.
## No interaction, loot, navigation, colliders, timers or frame updates.

@export_enum("echo", "cinder") var theme := "echo"
const Paint := preload("res://CityStreetAtlas.gd")
const Ambient := preload("res://AmbientSetpiece.gd")
const Support := preload("res://WorldSupport.gd")
const FacadePaint := preload("res://FacadePropAtlas.gd")
const Joinery := preload("res://SettlementDetailAtlas.gd")
const Canopies := preload("res://SettlementCanopyPlacement.gd")
const Workplace := preload("res://WorkplaceAtlas.gd")
var floor_surfaces: Array[Rect2] = []
var foliage: AtlasTexture

var props: Array[Dictionary] = []
var retired: Array[Polygon2D] = []
var built := false
var stalls_fitted := false


func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	var room := get_parent()
	var nodes: Array[Node] = []
	nodes.assign(room.find_children("*","",true,false))
	floor_surfaces = Support.floors(nodes)
	var family := 0 if theme=="echo" else 1
	var crop: Rect2 = Ambient.CROPS[family][1]
	var ratio: Vector2 = Ambient.SHEETS[family].get_size()/Ambient.SOURCE_SIZE
	foliage = AtlasTexture.new()
	foliage.atlas = Ambient.SHEETS[family]
	foliage.region = Rect2(crop.position*ratio,crop.size*ratio)
	foliage.filter_clip = true
	var district := room.get_node_or_null("NewDistricts" if theme == "echo" else "EasternDistricts")
	if district == null and theme == "echo":
		district = room.get_node_or_null("GateApproach")
	if district == null:
		return
	var patterns := {
		"bench": "^StreetBench[0-9]+$",
		"stall": "^(QuarterStall|MarketAwning)[0-9]+$",
		"barrel": "^SupplyCluster[0-9]+Barrel[0-9]+$",
		"cart": "^CaravanCart[0-9]+$",
		"wheel": "^CartWheel[0-9]+_[LR]$",
		"plant": "^Garden[0-9]+_[0-9]+$",
	}
	for kind in patterns:
		var pattern := RegEx.new()
		pattern.compile(patterns[kind])
		for child in district.get_children():
			if child is Polygon2D and pattern.search(String(child.name)) != null:
				_register(child, kind)
	# The bench renderer includes feet, so retire only their old visual shapes.
	for child in district.get_children():
		if child is Polygon2D and String(child.name).begins_with("BenchFoot"):
			_retire(child)
		if child is Polygon2D and (String(child.name).begins_with("MarketPost") or String(child.name).begins_with("StallPost")):
			_retire(child)
		if child is Node2D and String(child.name).begins_with("AshGarden"):
			_register_leaves(child)
	var patch := room.get_node_or_null("UpperVillage/HavenGarden" if theme == "echo" else "UpperVillage/HearthPlanters")
	if patch != null:
		_register_leaves(patch)
	built = true
	call_deferred("_fit_stalls")
	queue_redraw()

func _fit_stalls() -> void:
	if stalls_fitted: return
	var reserves := Canopies.openings(self)
	for prop in props:
		if prop.kind != "stall": continue
		var rect: Rect2 = prop.bounds
		var floor_y := _floor_y(Vector2(rect.get_center().x,rect.end.y+(37.0 if theme=="echo" else 51.0)),10)
		if is_nan(floor_y): prop["layout"]={};continue
		var image := Workplace.texture_for(3 if theme=="echo" else (4 if prop.seed%2==0 else 5))
		var height := floor_y-rect.end.y+image.get_height()*rect.size.x/image.get_width()
		var layout := Canopies.fit(self,floor_surfaces,Vector2(rect.get_center().x,floor_y),rect.size.x,height,image,reserves)
		if layout.is_empty():
			var index := 2 if prop.craft else (0 if prop.seed%3!=0 else 1)
			layout=Canopies.fit_counter(self,floor_surfaces,Vector2(rect.get_center().x,floor_y),Workplace.texture_for(index),30 if prop.craft else 36,reserves)
		prop["layout"]=layout
		if not layout.is_empty():
			if layout.mode=="canopy":
				reserves.append(layout.cloth)
				reserves.append_array(layout.posts)
			else: reserves.append(layout.counter)
	stalls_fitted = true
	queue_redraw()


func _register_leaves(patch: Node) -> void:
	for child in patch.get_children():
		if child is Polygon2D and String(child.name).begins_with("Leaf"):
			_register(child, "plant")


func _retire(plate: Polygon2D) -> void:
	# Never hide an originally hidden prop or a gameplay object.
	if plate.visible and not plate in retired:
		plate.hide()
		retired.append(plate)


func _register(plate: Polygon2D, kind: String) -> void:
	if not plate.visible or plate.polygon.size() < 3:
		return
	var points := PackedVector2Array()
	for point in plate.polygon:
		points.append(to_local(plate.to_global(point)))
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	props.append({"kind": kind, "bounds": bounds, "points": points, "seed": absi(String(plate.name).hash()) % 19, "craft": theme == "echo" and plate.get_parent().name == &"NewDistricts" and plate.name == &"QuarterStall00"})
	_retire(plate)


func _draw() -> void:
	for prop in props:
		var bounds: Rect2 = prop.bounds
		match prop.kind:
			"bench": _bench(bounds)
			"stall": _stall(bounds, prop.seed, prop.craft, prop.get("layout",{}))
			"barrel": _barrel(bounds, prop.seed)
			"cart": _cart(prop.points, bounds)
			"wheel": _wheel(bounds)
			"plant": _plant(bounds, prop.seed)


func _wood() -> Color:
	return Color("46636a") if theme == "echo" else Color("795344")

func _floor_y(at: Vector2, upward_tolerance: float) -> float:
	var floor_rect := Support.below(to_global(at-Vector2(0,upward_tolerance)),floor_surfaces,80)
	return to_local(floor_rect.position).y if floor_rect.has_area() else NAN


func _bench(rect: Rect2) -> void:
	var floor_y := _floor_y(Vector2(rect.get_center().x,rect.end.y+(8 if theme=="echo" else 16)),4)
	if is_nan(floor_y): return
	Paint.draw_ground(self,5,Vector2(rect.get_center().x,floor_y),27)


func _stall(rect: Rect2, seed: int, craft: bool, layout: Dictionary) -> void:
	if layout.is_empty(): return # No safe visual site: never revive the sketch.
	var atlas := Workplace
	var canopy := atlas.texture_for(3 if theme=="echo" else (4 if seed%2==0 else 5))
	var floor_y := _floor_y(Vector2(rect.get_center().x,rect.end.y+(37.0 if theme=="echo" else 51.0)),10)
	if is_nan(floor_y): return
	var center := rect.get_center().x
	if not layout.is_empty():
		center=layout.at.x;floor_y=layout.at.y
		# Slim posts attach both brackets to the same supported footprint.
		for post_rect in layout.get("posts",[]):
			var post := Joinery.texture_for(2,3 if theme=="cinder" else 0)
			draw_texture_rect(post,post_rect,false)
	var index := 2 if craft else (0 if seed%3!=0 else 1)
	var wares := atlas.texture_for(index)
	var height := minf(30 if craft else 36, rect.size.x*0.45)
	var size := wares.get_size()*(height/wares.get_height())
	# Moon Forge's native service now owns its correctly sized anvil. Do not
	# stack a second, person-height decorative anvil behind the blacksmith.
	if not craft: draw_texture_rect(wares,layout.get("counter",Rect2(Vector2(center-size.x/2,floor_y-height),size)),false)
	if layout.get("mode","")=="canopy": draw_texture_rect(canopy,layout.cloth,false)


func _barrel(rect: Rect2, seed: int) -> void:
	var floor_y := _floor_y(Vector2(rect.get_center().x,rect.end.y),18)
	if is_nan(floor_y): return
	# Old circles occupied supply corners, never breakable/gameplay containers.
	# Alternate compact stores; their opacity contact row is on the real floor.
	FacadePaint.draw_at(self,1,seed%3,Vector2(rect.get_center().x,floor_y),28,24)


func _cart(_points: PackedVector2Array, rect: Rect2) -> void:
	var floor_y := _floor_y(Vector2(rect.get_center().x,rect.end.y+10),4)
	if is_nan(floor_y): return
	Paint.draw_ground(self,4,Vector2(rect.get_center().x,floor_y),50)


func _wheel(_rect: Rect2) -> void:
	pass # Painted cart already contains both wheels.


func _plant(rect: Rect2, seed: int) -> void:
	var floor_y := _floor_y(Vector2(rect.get_center().x,rect.end.y),40)
	if is_nan(floor_y): return
	var height := clampf(rect.size.y*0.7,10,23)*(0.9+0.05*(seed%3))
	var ratio := height/foliage.get_height()
	var family := 0 if theme=="echo" else 1
	var contact: float = Ambient.CONTACT[family][1]*Ambient.SHEETS[family].get_height()/1024.0
	var size := foliage.get_size()*ratio
	draw_texture_rect(foliage,Rect2(Vector2(rect.get_center().x-size.x/2,floor_y-contact*ratio),size),false)
