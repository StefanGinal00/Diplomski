@tool
extends Node2D
## Camera-relative scenery only. Playable buildings, routes and physics stay fixed.
## Two culled architectural planes over the one opaque camera horizon painting.
const Art := preload("res://CityParallaxAtlas.gd")
const LAYERS := [
	{"sheet":1,"scroll":Vector2(0.32,0.045),"spacing":135.0,"base":100.0,"height":210.0,"variation":60.0,"tint":Color("66728b")},
	{"sheet":0,"scroll":Vector2(0.57,0.09),"spacing":230.0,"base":175.0,"height":260.0,"variation":80.0,"tint":Color("8290a9")},
]
var entries: Array[Dictionary] = []
var retired: Array[CanvasItem] = []
var built := false
var low_quality := false
var camera_local := Vector2.ZERO
var world_view_size := Vector2.ZERO
var revision := 0

func _ready() -> void:
	z_index = -8
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material = ShaderMaterial.new()
	material.shader = preload("res://art/visual_slice/city_distance_fade.gdshader")
	low_quality = OS.has_feature("mobile") or bool(ProjectSettings.get_setting("world/ambient/low_cost",false))
	visibility_changed.connect(_sync_activity)
	set_process(false)
	call_deferred("_build")

func _build() -> void:
	if built: return
	var city := get_parent()
	# Only audited background renderers. Never hide a house, bridge collider,
	# light, district parent, service NPC, marker or native gate/lift.
	for node in city.get_children():
		var named := String(node.name)
		if node is Polygon2D and (named in ["FarCity","LayeredRearDistricts"] or named.begins_with("SkyTower") or named.begins_with("TowerWindow") or named.begins_with("DistantSkybridge") or named.begins_with("BridgeSupport")):
			_retire(node)
	var upper := city.get_node("UpperCity")
	for node in upper.get_children():
		if String(node.name).begins_with("UpperSkyline"):
			for plate in node.get_children():
				if plate is Polygon2D: _retire(plate)
	# Its own _draw would otherwise put old bays/windows back over the new sky.
	_retire(upper.get_node("SkylineArt"))
	built = true
	if Engine.is_editor_hint():
		update_view(Vector2(3125,-650),Vector2(6500,2700),true)
	else:
		update_view(Vector2(800,300),Vector2(1280,720),true)
	_sync_activity()

func _retire(node: CanvasItem) -> void:
	if node.get_child_count()!=0 or node in retired: return
	node.hide()
	node.set_meta("city_parallax_replaced",true)
	retired.append(node)

func _sync_activity() -> void:
	set_process(built and not Engine.is_editor_hint() and is_visible_in_tree())

func set_low_quality(value: bool) -> void:
	if low_quality==value: return
	low_quality = value
	update_view(camera_local,world_view_size,true)

func _process(_delta: float) -> void:
	if not is_visible_in_tree(): return
	var inverse := get_viewport().canvas_transform.affine_inverse()
	var viewport_size := get_viewport_rect().size
	update_view(to_local(inverse*(viewport_size*0.5)),inverse.basis_xform(viewport_size).abs())

func update_view(center: Vector2, view_size: Vector2, force := false) -> void:
	if not force and center.is_equal_approx(camera_local) and view_size.is_equal_approx(world_view_size): return
	camera_local = center
	world_view_size = view_size
	entries.clear()
	var view := Rect2(center-view_size/2,view_size).grow(12)
	var cap := 8 if low_quality else 12
	# The editor overview may display the entire town, never at gameplay cost.
	if Engine.is_editor_hint(): cap = 40
	for layer in LAYERS.size():
		var data: Dictionary = LAYERS[layer]
		var scroll: Vector2 = data.scroll
		var spacing: float = data.spacing
		var middle := floori(center.x*scroll.x/spacing)
		var half_count := mini(cap/2,maxi(2,ceili(view_size.x/spacing/2)+2))
		for cell in range(middle-half_count,middle+half_count):
			var entry := building(layer,cell,center)
			if view.intersects(entry.rect): entries.append(entry)
	revision += 1
	queue_redraw()

func building(layer: int, cell: int, center: Vector2) -> Dictionary:
	var data: Dictionary = LAYERS[layer]
	var seed := posmod(cell*73+layer*31,97)
	var index := posmod(cell*5+layer,3)
	var image := Art.texture_for(data.sheet,index)
	var height: float = data.height+data.variation*float(seed)/96.0
	var size := image.get_size()*(height/image.get_height())
	# World position incorporates camera compensation. Its screen displacement
	# is -camera_delta*scroll, not -camera_delta like the playable foreground.
	var base := Vector2(cell*float(data.spacing)+float(seed%41)-20,float(data.base)+float(seed%29))
	var at: Vector2 = base+center*(Vector2.ONE-data.scroll)
	return {"layer":layer,"cell":cell,"sheet":data.sheet,"index":index,"rect":Rect2(at-Vector2(size.x/2,size.y),size),"tint":data.tint,"scroll":data.scroll}

func _draw() -> void:
	for entry in entries:
		draw_texture_rect(Art.texture_for(entry.sheet,entry.index),entry.rect,false,entry.tint)
