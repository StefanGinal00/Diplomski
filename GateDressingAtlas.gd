@tool
extends RefCounted
## Original source alpha is preserved; shared runtime crops and uniform scaling.
const SHEETS := [preload("res://art/visual_slice/haven_court_gate_v1.png"),preload("res://art/visual_slice/haven_ward_gate_v1.png"),preload("res://art/visual_slice/haven_road_ruin_v1.png"),preload("res://art/visual_slice/gate_buttress_modules_v1.png"),preload("res://art/visual_slice/portal_threshold_dressing_v1.png")]
const SOURCE_SIZE := Vector2(1536,1024)
const CROPS := [[Rect2(46,26,1444,958)],[Rect2(36,20,1465,960)],[Rect2(63,46,1420,918)],
	[Rect2(110,40,322,604),Rect2(589,62,355,598),Rect2(1206,50,228,619),Rect2(25,726,485,236),Rect2(544,739,470,225),Rect2(1045,754,469,213)],
	[Rect2(11,308,496,169),Rect2(528,338,489,139),Rect2(1034,260,489,219),Rect2(8,735,504,163),Rect2(512,671,508,226),Rect2(1033,734,494,162)]]
const CONTACT := [[956],[958],[916],[602,596,617,235,223,211],[166,137,217,161,223,160]]
static var cache: Array = [[],[],[],[],[]]

static func texture_for(sheet: int,index: int) -> AtlasTexture:
	if cache[sheet].is_empty():
		var ratio: Vector2 = SHEETS[sheet].get_size()/SOURCE_SIZE
		for crop: Rect2 in CROPS[sheet]:
			var frame := AtlasTexture.new()
			frame.atlas=SHEETS[sheet]; frame.region=Rect2(crop.position*ratio,crop.size*ratio); frame.filter_clip=true
			cache[sheet].append(frame)
	return cache[sheet][index]

static func grounded(parent: Node2D,named: String,sheet: int,index: int,foot: Vector2,width: float) -> Sprite2D:
	var art := Sprite2D.new()
	art.name=named; art.texture=texture_for(sheet,index)
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.scale=Vector2.ONE*width/art.texture.get_width()
	parent.add_child(art)
	art.global_position=foot
	var contact: float = CONTACT[sheet][index]*SHEETS[sheet].get_height()/SOURCE_SIZE.y
	preload("res://WorldSupport.gd").plant(art,contact,foot.y)
	art.set_meta("gate_sheet",sheet); art.set_meta("gate_frame",index)
	return art
