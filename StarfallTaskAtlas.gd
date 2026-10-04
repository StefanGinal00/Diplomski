@tool
extends RefCounted
## Original RGBA pixels are kept intact. Crops/opaque feet are source pixels.
const SOURCE_SIZE := Vector2(1536,1024)
const DATA := {
	"winch": [0, Rect2(47,96,483,364), 361, 42.0],
	"terminal": [0, Rect2(630,28,282,443), 440, 24.0],
	"seedbed": [0, Rect2(1011,192,474,276), 272, 42.0],
	"seedbed_done": [0, Rect2(52,636,473,320), 317, 42.0],
	"beacon": [0, Rect2(662,498,229,474), 471, 22.0],
	"beacon_done": [0, Rect2(1141,475,229,497), 494, 22.0],
	"register_wood": [1, Rect2(34,102,482,313), 311, 82.0],
	"register_stone": [1, Rect2(552,124,444,292), 290, 90.0],
	"growth": [1, Rect2(1030,170,487,252), 248, 44.0],
	"growth_done": [1, Rect2(31,591,591,343), 340, 44.0],
	"lantern": [1, Rect2(714,537,253,396), 394, 18.0],
	"lantern_done": [1, Rect2(1148,536,251,395), 393, 18.0],
	"caravan_a": [2, Rect2(23,95,466,400), 397, 86.0],
	"caravan_b": [2, Rect2(529,109,515,386), 384, 92.0],
	"barricade": [2, Rect2(1070,160,432,331), 329, 62.0],
	"post_moss": [2, Rect2(121,550,253,382), 380, 16.0],
	"post_carved": [2, Rect2(592,556,306,376), 374, 18.0],
	"books": [2, Rect2(998,632,502,329), 299, 38.0],
}
const FILES := ["starfall_task_stations_v1", "starfall_task_registers_v1", "starfall_route_furnishings_v1"]
static var cache := {}

static func texture(key: String) -> AtlasTexture:
	if cache.has(key): return cache[key]
	var data: Array = DATA[key]
	var source := load("res://art/visual_slice/%s.png" % FILES[data[0]]) as Texture2D
	var ratio := source.get_size()/SOURCE_SIZE
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(data[1].position*ratio,data[1].size*ratio)
	atlas.filter_clip = true
	cache[key] = atlas
	return atlas

static func apply(sprite: Sprite2D, key: String) -> void:
	var atlas := texture(key)
	var data: Array = DATA[key]
	var contact: float = data[2]*atlas.atlas.get_height()/SOURCE_SIZE.y
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2.ONE*float(data[3])/atlas.get_width()
	sprite.offset = Vector2(0,atlas.get_height()/2-contact)
	sprite.set_meta("task_frame",key)
	sprite.set_meta("contact_row",contact)

static func draw_at(canvas: CanvasItem,key: String,at: Vector2,width: float = 0,height_limit: float = INF,tint := Color.WHITE) -> Rect2:
	var tex := texture(key)
	var data: Array = DATA[key]
	var ratio := minf((width if width>0 else float(data[3]))/tex.get_width(),height_limit/tex.get_height())
	var contact: float = data[2]*tex.atlas.get_height()/SOURCE_SIZE.y
	var rect := Rect2(at-Vector2(tex.get_width()/2,contact)*ratio,tex.get_size()*ratio)
	canvas.draw_texture_rect(tex,rect,false,tint)
	return rect
