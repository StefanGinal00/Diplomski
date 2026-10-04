@tool
extends RefCounted
## Original RGBA sheets; only cached runtime regions, never rewritten pixels.
const SHEETS := [preload("res://art/visual_slice/city_arcade_spandrels_v1.png"), preload("res://art/visual_slice/city_facade_trim_v1.png"), preload("res://art/visual_slice/city_observatory_details_v1.png")]
const SOURCE_SIZE := Vector2(1536, 1024)
const CROPS := [
	[Rect2(36,59,1466,238), Rect2(35,381,1467,244), Rect2(35,710,1468,248)],
	[Rect2(178,61,156,676), Rect2(694,60,152,678), Rect2(1206,62,149,676), Rect2(22,816,476,118), Rect2(537,809,465,125), Rect2(1043,816,470,118)],
	[Rect2(126,9,328,491), Rect2(588,49,380,444), Rect2(1038,39,424,429), Rect2(58,515,465,454), Rect2(620,524,316,443), Rect2(1073,549,391,385)],
]
static var cached: Array = [[], [], []]

static func texture_for(sheet: int, index: int) -> AtlasTexture:
	if cached[sheet].is_empty():
		var ratio: Vector2 = SHEETS[sheet].get_size() / SOURCE_SIZE
		for crop: Rect2 in CROPS[sheet]:
			var frame := AtlasTexture.new()
			frame.atlas = SHEETS[sheet]
			frame.region = Rect2(crop.position * ratio, crop.size * ratio)
			frame.filter_clip = true
			cached[sheet].append(frame)
	return cached[sheet][index]

static func fit_rect(sheet: int, index: int, bounds: Rect2) -> Rect2:
	var size := texture_for(sheet,index).get_size()
	size *= minf(bounds.size.x / size.x, bounds.size.y / size.y)
	return Rect2(bounds.get_center() - size / 2, size)

static func fit(canvas: CanvasItem, sheet: int, index: int, bounds: Rect2, tint := Color.WHITE) -> void:
	canvas.draw_texture_rect(texture_for(sheet,index), fit_rect(sheet,index,bounds), false, tint)

static func ground_rect(index: int, at: Vector2, height: float) -> Rect2:
	var size := texture_for(2,index).get_size()
	size *= height / size.y
	return Rect2(at - Vector2(size.x/2, size.y - 0.3), size)

static func ground(canvas: CanvasItem, index: int, at: Vector2, height: float) -> void:
	canvas.draw_texture_rect(texture_for(2,index), ground_rect(index,at,height), false)

static func trim_pieces(index: int, bounds: Rect2) -> Array[Dictionary]:
	# Retain capital/end caps; repeat/crop only the shaft or plain middle.
	# Uniform source-to-world scale avoids stretched stones on tall facades.
	var vertical := index < 3
	var source: Rect2 = CROPS[1][index]
	var size := source.size.y if vertical else source.size.x
	var cross_size := source.size.x if vertical else source.size.y
	var cross_world := bounds.size.x if vertical else bounds.size.y
	var length := bounds.size.y if vertical else bounds.size.x
	var factor := cross_world / cross_size
	var cap := 175.0 if vertical else 70.0
	cap = minf(cap, length / factor * 0.45)
	var pieces: Array[Dictionary] = []
	var cursor := 0.0
	while cursor < length - 0.0001:
		var start := 0.0
		var extent := cap * factor
		if cursor > 0:
			if cursor >= length - cap * factor - 0.0001:
				start = size - cap
				extent = length - cursor
			else:
				start = cap
				extent = minf((size - cap*2) * factor, length - cap*factor - cursor)
		var src := Rect2(source.position + (Vector2(0,start) if vertical else Vector2(start,0)), Vector2(cross_size,extent/factor) if vertical else Vector2(extent/factor,cross_size))
		var dst := Rect2(bounds.position + (Vector2(0,cursor) if vertical else Vector2(cursor,0)), Vector2(cross_world,extent) if vertical else Vector2(extent,cross_world))
		pieces.append({"source":src, "rect":dst})
		cursor += extent
	return pieces

static func trim(canvas: CanvasItem, index: int, bounds: Rect2, tint := Color.WHITE) -> void:
	var ratio: Vector2 = SHEETS[1].get_size() / SOURCE_SIZE
	for piece in trim_pieces(index,bounds):
		canvas.draw_texture_rect_region(SHEETS[1],piece.rect,Rect2(piece.source.position*ratio,piece.source.size*ratio),tint,false,true)
