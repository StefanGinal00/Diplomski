@tool
extends Node2D
## Authored Starfall balcony trim only; no new collision or navigation.
const Architecture := preload("res://CityArchitectureAtlas.gd")
const Windows := preload("res://CityStreetAtlas.gd")
const Support := preload("res://WorldSupport.gd")
var rails: Array[Dictionary]=[]
var window_bounds := Rect2()
var window_art: Sprite2D
var retired: Array[CanvasItem]=[]
var built := false

static func install(room: Node2D) -> Node2D:
	if room.has_node("BalconyFinish"): return room.get_node("BalconyFinish")
	var layer := new(); layer.name="BalconyFinish"; room.add_child(layer)
	return layer

func _ready() -> void:
	top_level=true; global_transform=Transform2D.IDENTITY
	z_as_relative=false; z_index=-1; set_process(false); set_physics_process(false)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	call_deferred("_build")

func _build() -> void:
	if built: return
	var room := get_parent()
	for named in ["WestPromenadeRail","GardenRail"]:
		var old := room.get_node_or_null(named) as Line2D
		if old==null or old.points.is_empty(): continue
		var bounds := Rect2(old.to_global(old.points[0]),Vector2.ZERO)
		for point in old.points: bounds=bounds.expand(old.to_global(point))
		var floor_name := "WestPromenade" if named=="WestPromenadeRail" else "GardenBalcony"
		var floor_nodes: Array[Node]=[room.get_node(floor_name+"/CollisionShape2D")]
		# Only the native balcony owns this rail. Another landing at the same
		# height must not produce a second overlapping set of posts.
		for support in Support.floors(floor_nodes):
			if absf(support.position.y-bounds.end.y)>3: continue
			var left := maxf(bounds.position.x,support.position.x+3)
			var right := minf(bounds.end.x,support.end.x-3)
			if right-left<45: continue
			var rect := Rect2(to_local(Vector2(left,support.position.y-20)),Vector2(right-left,20))
			rails.append({"rect":rect,"support":support})
		old.hide(); retired.append(old)
	var source := room.get_node_or_null("LibraryRooftop/RoofArchiveWindow") as Polygon2D
	if source!=null:
		var bounds := Rect2(to_local(source.to_global(source.polygon[0])),Vector2.ZERO)
		for point in source.polygon: bounds=bounds.expand(to_local(source.to_global(point)))
		var texture := Windows.texture_for(0)
		var size := texture.get_size()*(34.0/texture.get_height())
		window_bounds=Rect2(bounds.get_center()-size/2,size)
		window_art=Sprite2D.new(); window_art.name="ArchiveWindow"; window_art.texture=texture
		window_art.position=window_bounds.get_center(); window_art.scale=size/texture.get_size()
		add_child(window_art); source.hide(); retired.append(source)
	built=true; queue_redraw()

func _draw() -> void:
	for rail in rails:
		var rect: Rect2=rail.rect
		Architecture.trim(self,3,Rect2(rect.position,Vector2(rect.size.x,3)),Color("868796"))
		Architecture.trim(self,3,Rect2(rect.position+Vector2(0,11),Vector2(rect.size.x,1.6)),Color("626b79"))
		var intervals := maxi(1,ceili(rect.size.x/66))
		for index in intervals+1:
			var x := lerpf(rect.position.x+2,rect.end.x-2,float(index)/intervals)
			Architecture.trim(self,1,Rect2(x-1.8,rect.position.y,3.6,rect.size.y+.1),Color("90909a"))
