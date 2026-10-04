extends RefCounted
## Original transparent town cutouts, registered without modifying source pixels.
const SOURCE := Vector2(1536,1024)
const ROOMS := {"echo_haven":"echo","ash_hearth":"ash","starfall_citadel":"star"}
const BOXES := {
	"echo":[Rect2(41,114,489,339),Rect2(577,131,379,318),Rect2(1042,166,444,282),Rect2(40,670,455,254),Rect2(536,606,451,294),Rect2(1020,603,487,310)],
	"ash":[Rect2(56,150,468,340),Rect2(573,170,401,327),Rect2(1048,206,433,287),Rect2(52,681,447,236),Rect2(538,643,470,259),Rect2(1019,657,487,257)],
	"star":[Rect2(37,89,459,375),Rect2(581,128,380,345),Rect2(1057,176,419,297),Rect2(47,663,440,249),Rect2(527,612,469,291),Rect2(1020,630,491,290)]
}
static var cache := {}

static func texture(family: String,index: int) -> AtlasTexture:
	var key := family+str(index)
	if cache.has(key): return cache[key]
	var source := load("res://art/visual_slice/town_verge_%s_v1.png"%family) as Texture2D
	var box: Rect2 = BOXES[family][index]
	var ratio := source.get_size()/SOURCE
	var atlas := AtlasTexture.new(); atlas.atlas=source
	atlas.region=Rect2(box.position*ratio,box.size*ratio); atlas.filter_clip=true
	cache[key]=atlas; return atlas

static func contact(family: String,index: int) -> float:
	# The last occupied alpha row, with only a subpixel root seam buried.
	return (BOXES[family][index].size.y-1)*texture(family,index).atlas.get_height()/SOURCE.y

static func home_zones(nodes: Array[Node]) -> Array[Rect2]:
	var zones: Array[Rect2]=[]
	for node in nodes:
		if not is_instance_valid(node): continue
		if node.get_script()==preload("res://PaintedSettlementBuildings.gd"):
			for home in node.painted:
				if home.texture==node.wall_texture and home.polygon.size()>=4:
					var rect := _bounds(home)
					if rect.size.x>=70 and rect.size.y>=60: zones.append(rect)
		elif node.get_script()==preload("res://StarfallUpperCityArt.gd"):
			for rect in node.houses: zones.append(node.global_transform*rect)
		elif node is Polygon2D and node.name in [&"MarketArch",&"MarketHall",&"ApothecaryHouse"]:
			zones.append(_bounds(node))
	return zones

static func near_home(at: Vector2,zones: Array[Rect2]) -> bool:
	for zone in zones:
		if absf(at.y-zone.end.y)<=24 and at.x>=zone.position.x-45 and at.x<=zone.end.x+45: return true
	return false

static func openings(nodes: Array[Node]) -> Array[Rect2]:
	var result: Array[Rect2]=[]
	for node in nodes:
		if not is_instance_valid(node): continue
		if node.get_script()==preload("res://ResidentialFacadeDetails.gd"):
			for entry in node.entries:
				if entry.kind!="door": continue
				var index: int = node.family+(3 if entry.index%2 else 0)
				var rect := preload("res://FacadePropAtlas.gd").contact_rect(0,index,entry.at,entry.height,entry.width)
				result.append((node.global_transform*rect).grow(5))
		elif node.get_script()==preload("res://StarfallUpperCityArt.gd"):
			for rect in node.doors: result.append((node.global_transform*rect).grow(6))
	return result

static func _bounds(home: Polygon2D) -> Rect2:
	var rect := Rect2(home.to_global(home.polygon[0]),Vector2.ZERO)
	for point in home.polygon: rect=rect.expand(home.to_global(point))
	return rect
