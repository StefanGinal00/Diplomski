@tool
extends Node2D
## Visual supports behind actors. Never adds walkable geometry.
const Atlas := preload("res://SettlementDetailAtlas.gd")

@export_enum("echo", "cinder") var theme := "echo"
var supports: Array[Rect2] = []
var foundations: Array[Rect2] = []
var floor_top := 0.0
var built := false


func _ready() -> void:
	z_index = -2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	var room := get_parent()
	var floor_shape := room.get_node("Floor/CollisionShape2D") as CollisionShape2D
	floor_top = to_local(floor_shape.to_global(Vector2(0, -floor_shape.shape.size.y * 0.5))).y
	var names := ["LanternHouse", "SurveyLoft"] if theme == "echo" else ["BellKeeperHouse", "CaravanLoft"]
	for named in names:
		var home := room.get_node("UpperVillage/" + named) as Polygon2D
		var bounds := _home_bounds(home)
		supports.append(Rect2(bounds.position.x + 10, bounds.end.y, bounds.size.x - 20, floor_top - bounds.end.y))
	if theme == "cinder":
		for named in ["BellFoundry", "CaravanInn", "KilnSchool", "ArchiveHall", "CopperLibrary", "GateBarracks"]:
			var home := room.get_node("EasternDistricts/" + named) as Polygon2D
			var bounds := _home_bounds(home)
			foundations.append(Rect2(bounds.position.x, bounds.end.y, bounds.size.x, floor_top - bounds.end.y))
	built = true
	queue_redraw()


func _home_bounds(home: Polygon2D) -> Rect2:
	var bounds := Rect2(to_local(home.to_global(home.polygon[0])), Vector2.ZERO)
	for point in home.polygon:
		bounds = bounds.expand(to_local(home.to_global(point)))
	return bounds


func _draw() -> void:
	for rect in supports:
		# Open portico preserves sight of residents and the lower walking lane.
		for x in [rect.position.x + 5, rect.end.x - 5]:
			Atlas.draw_contact(self,2,0 if theme=="echo" else 3,Vector2(x,rect.end.y),rect.size.y+1)
		# Repeat a short natural-width lintel instead of stretching grain over
		# an entire facade; posts/footings and braces retain their aspect ratio.
		_draw_course(1,Rect2(rect.position-Vector2(5,2),Vector2(rect.size.x+10,9)))
		for side in [-1.0, 1.0]:
			var corner := Vector2(rect.get_center().x + side * (rect.size.x * 0.5 - 5), rect.position.y)
			var brace := Atlas.texture_for(2,2 if theme=="echo" else 5)
			var size := brace.get_size()*(minf(26,rect.size.y*0.65)/brace.get_height())
			var origin := corner+Vector2(-size.x if side>0 else size.x,4)
			draw_texture_rect(brace,Rect2(origin,Vector2(size.x*side,size.y)),false)
	for rect in foundations:
		_draw_course(4,rect)

func _draw_course(index: int, rect: Rect2) -> void:
	if rect.size.y<=0: return
	var texture := Atlas.texture_for(2,index)
	var unit := texture.get_size()*(rect.size.y/texture.get_height())
	var x := rect.position.x
	while x<rect.end.x:
		var width := minf(unit.x,rect.end.x-x)
		draw_texture_rect_region(texture,Rect2(Vector2(x,rect.position.y),Vector2(width,unit.y)),Rect2(Vector2.ZERO,Vector2(width*texture.get_height()/unit.y,texture.get_height())))
		x += width
