@tool
extends RefCounted
## Six original elevations, shared full-resolution sources, no pixel readback.
const SHEETS := [preload("res://art/visual_slice/starfall_parallax_towers_v1.png"),preload("res://art/visual_slice/starfall_parallax_quarters_v1.png")]
const CROPS := [
	[Rect2(39,13,418,984),Rect2(499,73,539,915),Rect2(1070,96,452,897)],
	[Rect2(20,184,437,762),Rect2(485,283,555,663),Rect2(1064,99,453,847)],
]
static var cached: Array = [[],[]]

static func texture_for(sheet: int, index: int) -> AtlasTexture:
	if cached[sheet].is_empty():
		var ratio: Vector2 = SHEETS[sheet].get_size()/Vector2(1536,1024)
		for crop: Rect2 in CROPS[sheet]:
			var art := AtlasTexture.new()
			art.atlas = SHEETS[sheet]
			art.region = Rect2(crop.position*ratio,crop.size*ratio)
			art.filter_clip = true
			cached[sheet].append(art)
	return cached[sheet][index]
