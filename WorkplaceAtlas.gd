@tool
extends RefCounted
## Untouched source art, shared crops. No physics or autonomous callbacks.
const SHEET := preload("res://art/visual_slice/service_workplaces_v1.png")
const CROPS := [Rect2(16,172,587,389), Rect2(632,90,391,472), Rect2(1102,205,393,369), Rect2(29,671,464,249), Rect2(539,671,461,252), Rect2(1038,674,471,259)]
const CONTACTS := [388,470,367,247,250,257]
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
