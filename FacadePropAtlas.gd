@tool
extends RefCounted
## Original RGBA sources remain untouched; cached regions share two GPU sheets.
const SHEETS := [preload("res://art/visual_slice/residential_doors_v1.png"), preload("res://art/visual_slice/settlement_utilities_v1.png")]
const SOURCE_SIZE := Vector2(1536,1024)
const CROPS := [
	[Rect2(132,7,341,481),Rect2(594,7,349,487),Rect2(1073,7,349,486),Rect2(132,521,342,473),Rect2(593,525,349,471),Rect2(1104,493,286,501)],
	[Rect2(98,44,332,423),Rect2(578,99,369,337),Rect2(999,174,536,254),Rect2(84,481,354,514),Rect2(575,474,406,510),Rect2(1102,515,331,468)],
]
const CONTACTS := [[479,485,484,471,469,499],[420,334,251,2,507,465]]
static var cached: Array = [[],[]]

static func texture_for(sheet: int, index: int) -> AtlasTexture:
	if cached[sheet].is_empty():
		var ratio: Vector2 = SHEETS[sheet].get_size()/SOURCE_SIZE
		for crop: Rect2 in CROPS[sheet]:
			var texture := AtlasTexture.new()
			texture.atlas = SHEETS[sheet]
			texture.region = Rect2(crop.position*ratio,crop.size*ratio)
			texture.filter_clip = true
			cached[sheet].append(texture)
	return cached[sheet][index]

static func contact(sheet: int, index: int) -> float:
	return CONTACTS[sheet][index]*SHEETS[sheet].get_height()/SOURCE_SIZE.y

static func contact_rect(sheet: int, index: int, at: Vector2, height: float, max_width: float = INF) -> Rect2:
	var texture := texture_for(sheet,index)
	var ratio := minf(height/texture.get_height(),max_width/texture.get_width())
	var size := texture.get_size()*ratio
	return Rect2(at-Vector2(size.x/2,contact(sheet,index)*ratio),size)

static func draw_at(canvas: CanvasItem, sheet: int, index: int, at: Vector2, height: float, max_width: float = INF) -> void:
	canvas.draw_texture_rect(texture_for(sheet,index),contact_rect(sheet,index,at,height,max_width),false)

static func door(canvas: CanvasItem, rect: Rect2, family: int, variant: int) -> void:
	# Closed scenery, not a fake portal. Do not stretch the arch or threshold.
	draw_at(canvas,0,family+(3 if variant%2 else 0),Vector2(rect.get_center().x,rect.end.y),rect.size.y,rect.size.x)
