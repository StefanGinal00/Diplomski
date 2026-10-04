extends StaticBody2D
## Shallow, continuous walking contours backed by an untouched native floor.
const Edge := preload("res://TerrainEdgeArt.gd")
const PROFILES := [
	[Vector2(0,0),Vector2(.14,-.25),Vector2(.32,-1),Vector2(.55,-.85),Vector2(.79,-.22),Vector2(1,0)],
	[Vector2(0,0),Vector2(.15,-.7),Vector2(.3,-1),Vector2(.49,-.24),Vector2(.68,-.86),Vector2(.84,-.5),Vector2(1,0)],
	[Vector2(0,0),Vector2(.18,-.55),Vector2(.37,-.42),Vector2(.65,-1),Vector2(.82,-.32),Vector2(1,0)],
	# Eroded shelf, long shoulder and uneven saddle: not every path is a hill.
	[Vector2(0,0),Vector2(.16,-.65),Vector2(.29,-.92),Vector2(.62,-1),Vector2(.79,-.58),Vector2(1,0)],
	[Vector2(0,0),Vector2(.21,-.28),Vector2(.46,-.62),Vector2(.68,-1),Vector2(.84,-.62),Vector2(1,0)],
	[Vector2(0,0),Vector2(.17,-.86),Vector2(.33,-1),Vector2(.51,-.34),Vector2(.72,-.56),Vector2(.87,-.26),Vector2(1,0)]
]
var surface := PackedVector2Array()
var sheet: Texture2D
var strips: Array[Dictionary] = []
var support := Rect2()
var native: CollisionShape2D
var plan := {}
var plants: Array[Node2D] = []

func configure(data: Dictionary, collider: CollisionShape2D) -> void:
	plan = data; native = collider; support = data.floor
	global_transform = Transform2D(0,data.at)
	collision_layer = collider.get_parent().collision_layer
	collision_mask = collider.get_parent().collision_mask
	var corners := PackedVector2Array()
	for point in PROFILES[data.variant]: corners.append(point*Vector2(data.width,data.rise))
	surface.append(corners[0])
	# Round the corners without introducing a steeper slope than either of
	# their neighbours; painting and collision sample this same contour.
	for index in range(1,corners.size()-1):
		var enter := corners[index].lerp(corners[index-1],.22)
		var leave := corners[index].lerp(corners[index+1],.22)
		surface.append(enter)
		for sample in range(1,6):
			var t := sample/5.0
			surface.append(enter.lerp(corners[index],t).lerp(corners[index].lerp(leave,t),t))
	surface.append(corners[-1])
	var collision := CollisionPolygon2D.new(); collision.name = "ReliefCollision"
	var outline := surface.duplicate()
	outline.append(Vector2(data.width,6)); outline.append(Vector2(0,6))
	collision.polygon = outline; add_child(collision)
	set_meta("natural_mound_bounds",Rect2(data.at-Vector2(0,data.rise),Vector2(data.width,data.rise+8)))
	set_meta("walkable_relief",true)
	var material_family: String = data.material
	sheet = load("res://art/visual_slice/terrain_edge_%s_v1.png"%material_family)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var entry: Array = Edge.DATA[material_family][posmod(int(data.variant),3)]
	var source: Rect2 = entry[0]
	var contact: float = entry[1]
	var depth := support.size.y+minf(5,support.size.y*.3)
	var factor := depth/(source.end.y-contact)
	# Reuse the surrounding stone's material scale along X. The shallow face
	# follows its real collision above, reconnecting to the original underside.
	var left := source.position.x+64
	var tile_width := (source.size.x-128)*factor
	var x := 0.0
	while x < data.width-.001:
		var tile_x := fposmod(x,tile_width)
		var end_x := minf(data.width,minf(x+8,x+tile_width-tile_x))
		if end_x <= x+.001: end_x = minf(data.width,x+8); tile_x = 0
		var y0 := local_height(x); var y1 := local_height(end_x)
		var upper0 := y0-(contact-source.position.y)*factor
		var upper1 := y1-(contact-source.position.y)*factor
		strips.append({"points":PackedVector2Array([Vector2(x,upper0),Vector2(end_x,upper1),Vector2(end_x,depth),Vector2(x,depth)]),
			"uv":PackedVector2Array([Vector2(left+tile_x/factor,source.position.y)/Edge.SOURCE_SIZE,Vector2(left+(tile_x+end_x-x)/factor,source.position.y)/Edge.SOURCE_SIZE,Vector2(left+(tile_x+end_x-x)/factor,source.end.y)/Edge.SOURCE_SIZE,Vector2(left+tile_x/factor,source.end.y)/Edge.SOURCE_SIZE])})
		x = end_x
	_dress(data.family)
	set_process(false); set_physics_process(false); queue_redraw()

func local_height(x: float) -> float:
	for i in range(1,surface.size()):
		if x <= surface[i].x:
			return lerpf(surface[i-1].y,surface[i].y,clampf(inverse_lerp(surface[i-1].x,surface[i].x,x),0,1))
	return 0

func height_at(world_x: float) -> float:
	return global_position.y+local_height(world_x-global_position.x)

func _dress(palette: String) -> void:
	# Grounded small clumps on both sides of the player, tilted to the actual
	# local tangent. Hard props and interactions stay on the reserved flat paths.
	for index in range(1,int(plan.width/39)):
		var x := index*39.0
		var front := index%2==0
		var plant := preload("res://RouteDetail.gd").new(); add_child(plant)
		var anchor := global_position+Vector2(x,local_height(x)+.8)
		plant.configure(palette,"floor",5 if front else index%5,40,14 if front else 21,anchor,support,front)
		var slope := (local_height(x+2)-local_height(x-2))/4
		plant.rotation = atan(slope)
		plant.footprint = plant.art.global_transform*plant.art.get_rect()
		plants.append(plant)
	# Compact deposits reconnect the raised material to its original floor.
	# Keep both cutouts inside the reserved contour footprint.
	for end_index in 2:
		var x: float = 19 if end_index==0 else plan.width-19
		var cap := preload("res://RouteDetail.gd").new(); add_child(cap)
		cap.name = "SlopeJoin%d"%end_index
		cap.configure(palette,"floor",posmod(int(plan.variant)+end_index*2,5),29,9,global_position+Vector2(x,local_height(x)+.8),support)
		cap.rotation = atan((local_height(x+2)-local_height(x-2))/4)
		cap.footprint = cap.art.global_transform*cap.art.get_rect()
		cap.set_meta("slope_join",true); plants.append(cap)

func _draw() -> void:
	var tint := Color("a7b4b6") if plan.get("material","") in ["moss","shale"] else Color("b4ada6")
	for strip in strips: draw_polygon(strip.points,PackedColorArray([tint]),strip.uv,sheet)
