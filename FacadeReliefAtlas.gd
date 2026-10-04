extends RefCounted
## Twelve original cutouts; imports share two <=1024px mipmapped sheets.
## Crops are offline alpha measurements, never runtime image readbacks.
const SOURCE_SIZE := Vector2(1536, 1024)
const SHEETS := [preload("res://art/visual_slice/facade_pilasters_v1.png"), preload("res://art/visual_slice/facade_growth_v1.png")]
const CROPS := [
	[Rect2(248,20,138,477),Rect2(709,19,118,478),Rect2(1156,19,136,478),Rect2(242,525,151,477),Rect2(696,526,144,475),Rect2(1152,520,145,481)],
	[Rect2(88,21,346,479),Rect2(585,17,412,495),Rect2(1101,28,396,464),Rect2(86,517,363,483),Rect2(596,512,398,494),Rect2(1094,524,414,487)],
]
static var cached := {}

static func texture_for(sheet: int, index: int) -> AtlasTexture:
	var key := sheet * 6 + index
	if cached.has(key): return cached[key]
	var texture := AtlasTexture.new()
	texture.atlas = SHEETS[sheet]
	var ratio: Vector2 = SHEETS[sheet].get_size() / SOURCE_SIZE
	texture.region = Rect2(CROPS[sheet][index].position * ratio, CROPS[sheet][index].size * ratio)
	texture.filter_clip = true
	cached[key] = texture
	return texture
