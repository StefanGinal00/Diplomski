@tool
extends RefCounted
## Separate region families for a gate, cornices, reliefs and hanging fabric.
const SHEETS := [preload("res://art/visual_slice/starfall_watch_arch_v1.png"),preload("res://art/visual_slice/civic_battlements_v1.png"),preload("res://art/visual_slice/civic_reliefs_v1.png"),preload("res://art/visual_slice/watch_banners_v1.png")]
const SIZE := Vector2(1536,1024)
const CROPS := [
	[Rect2(60,98,1416,810)],
	[Rect2(51,81,1434,244),Rect2(59,417,1418,231),Rect2(49,724,1438,220)],
	[Rect2(29,13,496,456),Rect2(557,71,480,376),Rect2(1096,13,403,435),Rect2(31,474,480,474),Rect2(575,458,436,509),Rect2(1075,454,432,525)],
	[Rect2(114,6,350,500),Rect2(593,6,350,500),Rect2(1070,6,351,500),Rect2(108,510,353,501),Rect2(591,510,352,499),Rect2(1068,510,354,499)]
]
static var cached: Array = [[],[],[],[]]

static func texture_for(sheet: int,index: int) -> AtlasTexture:
	if cached[sheet].is_empty():
		var ratio: Vector2=SHEETS[sheet].get_size()/SIZE
		for crop: Rect2 in CROPS[sheet]:
			var frame:=AtlasTexture.new()
			frame.atlas=SHEETS[sheet]
			frame.region=Rect2(crop.position*ratio,crop.size*ratio)
			frame.filter_clip=true
			cached[sheet].append(frame)
	return cached[sheet][index]

static func fit(canvas: CanvasItem,sheet: int,index: int,bounds: Rect2,tint := Color.WHITE) -> void:
	var texture:=texture_for(sheet,index)
	var size:=texture.get_size()
	size*=minf(bounds.size.x/size.x,bounds.size.y/size.y)
	canvas.draw_texture_rect(texture,Rect2(bounds.get_center()-size/2,size),false,tint)

static func sprite(parent: Node2D,named: String,sheet: int,index: int,at: Vector2,width: float) -> Sprite2D:
	var art:=Sprite2D.new()
	art.name=named
	art.texture=texture_for(sheet,index)
	art.scale=Vector2.ONE*width/art.texture.get_width()
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(art)
	art.global_position=at
	return art
