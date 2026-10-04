@tool
extends RefCounted
## Offline-measured, shared regions. No image readbacks during play.
const SHEETS := [preload("res://art/visual_slice/civic_landmarks_v1.png"), preload("res://art/visual_slice/settlement_hanging_v1.png"), preload("res://art/visual_slice/settlement_joinery_v1.png")]
const CROPS := [
	[Rect2(80,10,631,458), Rect2(889,9,529,458), Rect2(137,479,535,518), Rect2(974,500,321,499)],
	[Rect2(222,6,135,492), Rect2(691,2,154,496), Rect2(1179,2,140,496), Rect2(171,519,234,496), Rect2(639,519,259,493), Rect2(1120,519,257,498)],
	[Rect2(83,13,225,474), Rect2(426,173,680,175), Rect2(1115,53,377,413), Rect2(67,511,253,481), Rect2(435,651,632,249), Rect2(1123,550,400,421)]
]
const CONTACTS := [[456,456,515,496],[1,1,1,3,3,3],[471,173,411,478,247,419]]
static var cache := {}

static func texture_for(sheet: int, index: int) -> AtlasTexture:
	var key := sheet*10+index
	if cache.has(key): return cache[key]
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEETS[sheet]
	var ratio: Vector2 = SHEETS[sheet].get_size()/Vector2(1536,1024)
	var rect: Rect2 = CROPS[sheet][index]
	atlas.region = Rect2(rect.position*ratio,rect.size*ratio)
	atlas.filter_clip = true
	cache[key] = atlas
	return atlas

static func contact(sheet: int, index: int) -> float:
	return CONTACTS[sheet][index]*SHEETS[sheet].get_height()/1024.0

static func contact_rect(sheet: int, index: int, anchor: Vector2, height: float) -> Rect2:
	var texture := texture_for(sheet,index)
	var ratio := height/texture.get_height()
	return Rect2(anchor-Vector2(texture.get_width()*0.5,contact(sheet,index))*ratio,texture.get_size()*ratio)

static func draw_contact(canvas: CanvasItem, sheet: int, index: int, anchor: Vector2, height: float) -> void:
	canvas.draw_texture_rect(texture_for(sheet,index),contact_rect(sheet,index,anchor,height),false)
