extends RefCounted
## Original generated pixels, offline alpha crops and hand-registered thoraxes.
## Tiny world scale is shared by all poses; wings never resize the body.
const SOURCE := Vector2(1536,1024)
const DATA := {
	"cave":{"boxes":[Rect2(89,24,370,436),Rect2(613,88,367,375),Rect2(1083,195,404,267),Rect2(120,643,342,344),Rect2(605,582,375,327),Rect2(1119,652,374,251)],"pivots":[Vector2(337,343),Vector2(857,343),Vector2(1360,344),Vector2(345,756),Vector2(858,772),Vector2(1370,769)]},
	"mine":{"boxes":[Rect2(145,51,322,425),Rect2(633,136,335,341),Rect2(1084,225,386,251),Rect2(144,699,324,281),Rect2(637,585,329,305),Rect2(1086,699,386,191)],"pivots":[Vector2(339,364),Vector2(841,363),Vector2(1346,365),Vector2(340,777),Vector2(842,778),Vector2(1349,778)]},
	"ash":{"boxes":[Rect2(127,59,314,387),Rect2(620,125,345,321),Rect2(1091,202,366,244),Rect2(141,701,299,243),Rect2(632,611,333,283),Rect2(1115,701,343,193)],"pivots":[Vector2(325,324),Vector2(846,325),Vector2(1342,326),Vector2(326,774),Vector2(846,777),Vector2(1345,777)]},
	"star":{"boxes":[Rect2(91,34,364,430),Rect2(611,109,380,354),Rect2(1078,207,425,256),Rect2(136,644,319,331),Rect2(609,588,383,290),Rect2(1138,644,364,233)],"pivots":[Vector2(326,343),Vector2(856,343),Vector2(1366,344),Vector2(331,750),Vector2(856,751),Vector2(1381,750)]}
}
static var sheets := {}
static var frames := {}

static func texture(family: String,index: int) -> AtlasTexture:
	if not sheets.has(family): sheets[family]=load("res://art/visual_slice/ambient_moth_%s_v1.png"%family)
	var key := family+str(index)
	if not frames.has(key):
		var atlas := AtlasTexture.new(); atlas.atlas=sheets[family]
		var ratio: Vector2=atlas.atlas.get_size()/SOURCE
		var crop: Rect2=DATA[family].boxes[index]
		atlas.region=Rect2(crop.position*ratio,crop.size*ratio); atlas.filter_clip=true
		frames[key]=atlas
	return frames[key]

static func show(art: Sprite2D,family: String,index: int,span: float,left: bool) -> void:
	art.texture=texture(family,index)
	var ratio: Vector2=sheets[family].get_size()/SOURCE
	var crop: Rect2=DATA[family].boxes[index]
	var pivot: Vector2=(DATA[family].pivots[index]-crop.position)*ratio
	art.offset=art.texture.get_size()*.5-pivot
	art.flip_h=left
	if left: art.offset.x=-art.offset.x
	# Fixed reference span, not each differently posed wing's current bounds.
	art.scale=Vector2.ONE*(span/436.0)/ratio
