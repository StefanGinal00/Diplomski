@tool
extends Node2D
## Small, explicit street compositions. All original gameplay remains intact.
const Atlas := preload("res://CivicGuardAtlas.gd")
const Support := preload("res://WorldSupport.gd")
var pieces: Array[Sprite2D] = []
var banners: Array[Node2D] = []
var retired: Array[CanvasItem] = []
var houses: Array[Dictionary] = []
var built := false

static func install(room: Node2D,floors: Array[Rect2]) -> Node2D:
	if room.name not in [&"CinderHearth",&"StarfallCitadel"]: return null
	var existing:=room.get_node_or_null("GuardhouseArt")
	if existing!=null: return existing
	var art:=preload("res://GuardhouseArt.gd").new()
	art.name="GuardhouseArt"
	room.add_child(art)
	art._build(floors)
	return art

func _ready() -> void:
	z_index=-1
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)

func _build(floors: Array[Rect2]) -> void:
	if built: return
	var room:=get_parent() as Node2D
	if room.name==&"StarfallCitadel":
		var district:=room.get_node("GateDistrict") as Node2D
		# The upper-city stair starts at x400. Keep both complete gate piers
		# west of it, rather than letting the first tread cut the right pier.
		var at:=district.to_global(Vector2(265,390))
		var support:=Support.below(at,floors,4)
		if support.has_area():
			var gate:=Atlas.sprite(self,"OpenWatchArch",0,0,at,220)
			Support.plant(gate,807*Atlas.SHEETS[0].get_height()/Atlas.SIZE.y,support.position.y)
			gate.modulate=Color("949aa4")
			gate.z_index=-2
			gate.set_meta("support_rect",support)
			pieces.append(gate)
			for named in ["GateArch","GateGlow"]:
				var old:=district.get_node(named) as CanvasItem
				old.hide(); retired.append(old)
			for side in [-1,1]: _banner(3 if side<0 else 4,at+Vector2(side*89,-88),32)
		var house:=district.get_node("WatchHouse") as Polygon2D
		var rect:=_bounds(house)
		houses.append({"bounds":rect,"star":true})
		for side in [-1,1]: _banner(4 if side<0 else 5,to_global(Vector2(rect.get_center().x+side*64,rect.position.y+53)),36)
	else:
		var district:=room.get_node("EasternDistricts")
		for named in ["GateBarracks","WatchHouse","BellFoundry","CaravanInn","ArchiveHall"]:
			var house:=district.get_node(named) as Polygon2D
			var rect:=_bounds(house)
			if named=="WatchHouse": houses.append({"bounds":rect,"star":false})
			var variant:=0 if named in ["GateBarracks","CaravanInn"] else (1 if named=="WatchHouse" else 2)
			var at:=to_global(Vector2(rect.get_center().x+rect.size.x*0.31,rect.position.y+58))
			if named=="WatchHouse": at=to_global(Vector2(rect.get_center().x,rect.position.y+45))
			_banner(variant,at,37)
			if named=="GateBarracks": _banner(1,to_global(Vector2(rect.get_center().x-rect.size.x*0.31,rect.position.y+58)),37)
	built=true
	queue_redraw()

func _bounds(home: Polygon2D) -> Rect2:
	var rect:=Rect2(to_local(home.to_global(home.polygon[0])),Vector2.ZERO)
	for point in home.polygon: rect=rect.expand(to_local(home.to_global(point)))
	return rect

func _banner(index: int,at: Vector2,height: float) -> void:
	var banner:=preload("res://WatchBanner.gd").new()
	banner.name="WatchBanner%02d"%banners.size()
	add_child(banner)
	banner.configure(index,at,height)
	banner.modulate=Color("a6a0a0")
	banners.append(banner)

func _draw() -> void:
	for entry in houses:
		var rect: Rect2=entry.bounds
		var at:=Vector2(rect.get_center().x,rect.end.y)
		var eave: float=rect.position.y+39
		var trim:=preload("res://CityArchitectureAtlas.gd")
		for side in [-1,1]:
			trim.trim(self,0 if entry.star else 1,Rect2(rect.get_center().x+side*(rect.size.x*0.5-9)-6,eave+7,12,rect.end.y-eave-7),Color("a0a0a7") if entry.star else Color("ada091"))
		Atlas.fit(self,1,1 if entry.star else 0,Rect2(rect.position.x+3,eave-24,rect.size.x-6,33),Color("a3a3ad") if entry.star else Color("ad9d8e"))
		if entry.star:
			preload("res://FacadePropAtlas.gd").door(self,Rect2(at-Vector2(16,43),Vector2(32,43)),2,0)
			for side in [-1,1]:
				var texture:=preload("res://SettlementWindowAtlas.gd").texture_for(4)
				var size:=texture.get_size()*(28/texture.get_height())
				draw_texture_rect(texture,Rect2(at+Vector2(side*42,-81)-size*0.5,size),false,Color("b4b7c3"))
