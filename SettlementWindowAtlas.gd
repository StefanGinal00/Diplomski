@tool
extends RefCounted
const SHEET := preload("res://art/visual_slice/settlement_windows_v1.png")
# Keep trailing ivy out of the neighboring row, not an assumed even sprite grid.
const CROPS := [Rect2(52,14,431,490),Rect2(590,9,384,490),Rect2(1087,40,382,447),Rect2(69,525,432,457),Rect2(570,505,366,488),Rect2(1045,524,428,456)]
static var frames: Array[AtlasTexture] = []

static func texture_for(index: int) -> AtlasTexture:
	if frames.is_empty():
		var ratio := SHEET.get_size()/Vector2(1536,1024)
		for crop in CROPS:
			var atlas := AtlasTexture.new()
			atlas.atlas = SHEET
			atlas.region = Rect2(crop.position*ratio,crop.size*ratio)
			atlas.filter_clip = true
			frames.append(atlas)
	return frames[index]
