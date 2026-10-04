@tool
extends RefCounted
const SHEET := preload("res://art/visual_slice/starfall_street_furnishings_v1.png")
const CROPS := [Rect2(133,70,244,489),Rect2(582,83,380,469),Rect2(1229,9,126,600),Rect2(22,659,455,309),Rect2(494,632,527,333),Rect2(1069,678,439,287)]
const CONTACTS := [487,467,599,305,331,285]
static var frames: Array[AtlasTexture] = []

static func texture_for(index: int) -> AtlasTexture:
	if frames.is_empty():
		var ratio := SHEET.get_size()/Vector2(1536,1024)
		for crop in CROPS:
			var frame := AtlasTexture.new()
			frame.atlas = SHEET
			frame.region = Rect2(crop.position*ratio,crop.size*ratio)
			frame.filter_clip = true
			frames.append(frame)
	return frames[index]

static func contact(index: int) -> float:
	return CONTACTS[index]*SHEET.get_height()/1024.0

static func street_y(room: Node2D) -> float:
	var shape := room.get_node("Floor/CollisionShape2D") as CollisionShape2D
	return room.to_local(shape.to_global(Vector2(0,-shape.shape.size.y/2))).y

static func ground_rect(index: int, at: Vector2, height: float) -> Rect2:
	var image := texture_for(index)
	var scale := height/image.get_height()
	var size := image.get_size()*scale
	return Rect2(at-Vector2(size.x/2,contact(index)*scale),size)

static func draw_ground(target: CanvasItem, index: int, at: Vector2, height: float) -> void:
	target.draw_texture_rect(texture_for(index),ground_rect(index,at,height),false)

static func draw_window(target: CanvasItem, rect: Rect2, variant: int) -> void:
	var image := texture_for(variant%2)
	var size := image.get_size()*((rect.size.y+8)/image.get_height())
	target.draw_texture_rect(image,Rect2(rect.get_center()-size/2,size),false)
