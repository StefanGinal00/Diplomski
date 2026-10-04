@tool
extends Node2D
const Atlas := preload("res://SettlementDetailAtlas.gd")
var art: Sprite2D
var variant := 0
var support := Rect2()
var age := 0.0
var source_scale := 1.0

func configure(index: int, anchor: Vector2, height: float, floor_rect: Rect2) -> void:
	variant = index
	support = floor_rect
	global_position = anchor
	z_index = 0 # Parent dressing layer is already behind actors at -1.
	set_process(false)
	art = Sprite2D.new()
	art.name = "LandmarkPainting"
	art.show_behind_parent = true
	art.texture = Atlas.texture_for(0,index)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.scale = Vector2.ONE*height/art.texture.get_height()
	art.position.y = (art.texture.get_height()*0.5-Atlas.contact(0,index))*art.scale.y
	add_child(art)
	source_scale = height/float(Atlas.CROPS[0][index].size.y)
	if index==0: set_meta("ambient_motion",true)

func animate(time: float) -> void:
	age = time
	queue_redraw()

func rest() -> void:
	age = 0
	queue_redraw()

func _draw() -> void:
	if variant!=0 or art==null: return
	# Small, local water rings within the painted pool. Stone never pulses or
	# warps. Two short polylines, no particles, lights or transparent fullscreen.
	var center := Vector2(-4,-190)*source_scale
	for ring in 2:
		var step := fposmod(age*0.5+ring*0.5,1.0)
		var points := PackedVector2Array()
		for point in 17:
			var angle := TAU*point/16.0
			points.append(center+Vector2(cos(angle)*(16+step*58),sin(angle)*(3+step*9))*source_scale)
		draw_polyline(points,Color(0.57,0.83,0.84,(1-step)*0.3),0.6,true)
