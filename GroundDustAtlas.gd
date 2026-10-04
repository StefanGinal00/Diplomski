extends RefCounted
## Read-only alpha registration of original six-phase ground dust sheets.
const SOURCE := Vector2(1536,1024)
const BOXES := {
	"moss":[Rect2(164,337,166,94),Rect2(619,311,305,120),Rect2(1084,268,389,164),Rect2(63,722,436,177),Rect2(579,741,403,156),Rect2(1105,760,371,131)],
	"shale":[Rect2(177,391,161,82),Rect2(601,349,336,125),Rect2(1050,328,433,146),Rect2(52,773,457,160),Rect2(570,785,421,147),Rect2(1105,824,350,109)],
	"basalt":[Rect2(172,311,196,103),Rect2(604,275,339,139),Rect2(1076,238,409,177),Rect2(30,661,466,208),Rect2(527,675,484,194),Rect2(1058,704,431,162)],
	"citadel":[Rect2(185,356,132,83),Rect2(618,341,304,103),Rect2(1097,287,399,157),Rect2(49,723,457,218),Rect2(572,767,424,171),Rect2(1108,811,378,120)]
}
static var cache := {}

static func frames_for(family: String) -> Array:
	if cache.has(family): return cache[family]
	var source := load("res://art/visual_slice/ground_dust_%s_v%d.png"%[family,2 if family=="moss" else 1]) as Texture2D
	var ratio := source.get_size()/SOURCE
	var frames := []
	for box: Rect2 in BOXES[family]:
		var frame := AtlasTexture.new(); frame.atlas=source
		frame.region=Rect2(box.position*ratio,box.size*ratio); frame.filter_clip=true
		frames.append(frame)
	cache[family]=frames; return frames

static func frame_rect(family: String,index: int,width: float) -> Rect2:
	var box: Rect2=BOXES[family][index]
	# Fixed cell-centre X and measured lowest alpha row: scale/anchor do not
	# drift as the puff expands. No part of a quad extends below its floor.
	var factor := width/512.0
	return Rect2(Vector2(box.position.x-(index%3*512+256),-box.size.y)*factor,box.size*factor)
