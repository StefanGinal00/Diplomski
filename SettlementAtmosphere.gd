@tool
extends Node2D
## Audited scenery replacements shared by towns and their connected outskirts.
## Originals stay in place for editor inspection; no actor or collider is moved.
const Atlas := preload("res://SettlementDetailAtlas.gd")
const Hanging := preload("res://SettlementHangingDetail.gd")
const Landmark := preload("res://CivicLandmarkDetail.gd")
const Support := preload("res://WorldSupport.gd")
var built := false
var retired: Array[CanvasItem] = []
var fixtures: Array[Dictionary] = []
var hangings: Array[Node2D] = []
var landmarks: Array[Node2D] = []
var floors: Array[Rect2] = []
var family := 0

func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")

func _build() -> void:
	if built: return
	var room := get_parent() as Node2D
	family = 2 if room.name=="StarfallCitadel" else (1 if room.name=="CinderHearth" else 0)
	var nodes: Array[Node] = []
	nodes.assign(room.find_children("*","",true,false))
	floors = Support.floors(nodes)
	preload("res://ApproachGateArt.gd").install(room,floors)
	preload("res://GuardhouseArt.gd").install(room,floors)
	for node in nodes:
		if not node is Polygon2D or node.polygon.is_empty(): continue
		var named := String(node.name)
		var bounds := _bounds(node)
		if family==0 and node.get_parent()==room and named in ["HangingGlowLeft","HangingGlowRight"]:
			var rope := room.get_node(named.replace("HangingGlow","HangingLamp")) as Line2D
			_hang(0,rope.to_global(rope.points[-1]),31,"rope")
			rope.default_color = Color("626660")
			_retire(node)
			continue
		if named.begins_with("QuarterLantern"):
			if _post_lamp(Vector2(bounds.get_center().x,bounds.end.y),58,0):
				_retire(node)
				_retire(node.get_parent().get_node_or_null(named.replace("QuarterLantern","QuarterGlow")))
		elif family==1 and named.begins_with("StreetLantern"):
			if _post_lamp(Vector2(bounds.get_center().x,room.to_global(Vector2(0,380)).y),58,1): _retire(node)
		elif named.begins_with("HangingCloth") or named.begins_with("WardCloth"):
			var rope: Line2D
			if named.begins_with("WardCloth"):
				rope = node.get_parent().get_node_or_null("WardLaundry"+named.trim_prefix("WardCloth").get_slice("_",0))
			elif named.contains("_"):
				rope = node.get_parent().get_node_or_null("LaundryLine"+named.trim_prefix("HangingCloth").get_slice("_",0))
			else: rope = node.get_parent().get_node_or_null("MarketClothesline")
			if rope!=null:
				# Keep the real suspension cable, but not a thick luminous cyan
				# route-like stripe through otherwise painted street scenery.
				rope.default_color = Color(0.42,0.38,0.31,0.75)
				rope.width = 0.8
				var anchor := _rope_at(rope,bounds.get_center().x)
				_hang(3+family,anchor,32+absi(named.hash())%7,"rope")
				_retire(node)
		elif family==2 and named in ["LanternWest","LanternEast"]:
			var rope := node.get_parent().get_node_or_null("LanternLine") as Line2D
			if rope!=null:
				_hang(2,_rope_at(rope,bounds.get_center().x),27,"rope")
				_retire(node)
		elif family==1 and named=="ForgeFlame":
			_wall_hanging(1,room.to_global(Vector2(930,268)),30)
			_retire(node)
		elif family==1 and named=="BannerCloth":
			# Old banner/pole floated above the gate. Attach it to HearthHouse.
			_wall_hanging(4,room.to_global(Vector2(244,244)),43)
			_retire(node)
			_retire(room.get_node_or_null("HearthBanner"))
		elif family==2 and named.begins_with("CivicBanner"):
			_wall_hanging(5,Vector2(bounds.get_center().x,bounds.position.y),43)
			_retire(node)
	if family==2: _city_landmarks(room)
	built = true
	queue_redraw()

func _bounds(node: Polygon2D) -> Rect2:
	var rect := Rect2(node.to_global(node.polygon[0]),Vector2.ZERO)
	for point in node.polygon: rect = rect.expand(node.to_global(point))
	return rect

func _retire(node: Node) -> void:
	if node is CanvasItem and not node in retired:
		node.hide()
		retired.append(node)

func _rope_at(rope: Line2D, world_x: float) -> Vector2:
	# Ring sits ON the real sagging cable, not the old approximate cloth row.
	for i in range(rope.points.size()-1):
		var a := rope.to_global(rope.points[i])
		var b := rope.to_global(rope.points[i+1])
		if world_x>=minf(a.x,b.x) and world_x<=maxf(a.x,b.x):
			return Vector2(world_x,lerpf(a.y,b.y,(world_x-a.x)/(b.x-a.x)))
	return rope.to_global(rope.points[0])

func _hang(index: int, anchor: Vector2, height: float, kind: String) -> void:
	var detail := Hanging.new()
	detail.name = "HangingDetail%02d" % hangings.size()
	add_child(detail)
	detail.configure(index,anchor,height,kind)
	hangings.append(detail)

func _wall_hanging(index: int, anchor: Vector2, height: float) -> void:
	fixtures.append({"kind":"bracket","anchor":to_local(anchor)})
	_hang(index,anchor,height,"wall")

func _post_lamp(at: Vector2, height: float, index: int) -> bool:
	var floor_rect := Support.below(at,floors,40)
	if not floor_rect.has_area(): return false
	var base := Vector2(clampf(at.x,floor_rect.position.x+16,floor_rect.end.x-16),floor_rect.position.y)
	var anchor := base+Vector2(16,-height+5)
	fixtures.append({"kind":"post","anchor":to_local(base),"height":height,"index":3 if index==1 else 0,"support":floor_rect})
	_hang(index,anchor,31,"post")
	return true

func _city_landmarks(room: Node2D) -> void:
	var square := room.get_node("CityDistrictDetails/CivicSquareDetails")
	if _landmark(0,room.to_global(Vector2(2557,390)),68):
		for child in square.get_children():
			if String(child.name).begins_with("StarFountain") or String(child.name).begins_with("FountainStream"): _retire(child)
	if _landmark(1,room.to_global(Vector2(2773,390)),56):
		for child in square.get_children():
			if String(child.name).begins_with("Notice"): _retire(child)
	var gardens := room.get_node("CityDistrictDetails/CelestialGardenDetails")
	# Painted planters/trellises now provide the garden; the old huge flat arch
	# and forty-two triangles must not remain in front of that artwork.
	_retire(room.get_node_or_null("GardenArbor"))
	for child in gardens.get_children():
		if String(child.name).begins_with("Plant") or String(child.name).begins_with("GardenBed"): _retire(child)
	for index in 3:
		if _landmark(2,room.to_global(Vector2(4865+index*185,390)),92): _retire(gardens.get_node("VineTrellis%d" % index))
	# The original armillary's rotations were about room origin, leaving its
	# rings detached. Place the coherent pedestal on the observatory street.
	if _landmark(3,room.to_global(Vector2(5880,390)),48):
		var observatory := room.get_node("CityDistrictDetails/ObservatoryDetails")
		for index in 3: _retire(observatory.get_node("ArmillaryRing%d" % index))
		for index in 3: _retire(observatory.get_node("ChartCase%d" % index))

func _landmark(index: int, at: Vector2, height: float) -> bool:
	var floor_rect := Support.below(at,floors,100)
	if not floor_rect.has_area(): return false
	# Existing balconies must not slice through a finial or noticeboard roof.
	for ceiling in floors:
		if ceiling==floor_rect or ceiling.end.y>=floor_rect.position.y: continue
		var half_width := Atlas.texture_for(0,index).get_size().aspect()*height*0.5
		if ceiling.position.x<at.x+half_width and ceiling.end.x>at.x-half_width:
			height = minf(height,floor_rect.position.y-ceiling.end.y-5)
	if height<24: return false
	var width := Atlas.texture_for(0,index).get_size().aspect()*height
	if floor_rect.size.x<width+4: return false
	var anchor := Vector2(clampf(at.x,floor_rect.position.x+width/2+2,floor_rect.end.x-width/2-2),floor_rect.position.y)
	var detail := Landmark.new()
	detail.name = "CivicLandmark%02d" % landmarks.size()
	add_child(detail)
	detail.configure(index,anchor,height,floor_rect)
	landmarks.append(detail)
	return true

func _draw() -> void:
	for fixture in fixtures:
		var at: Vector2 = fixture.anchor
		if fixture.kind=="post":
			Atlas.draw_contact(self,2,fixture.index,at,fixture.height)
			var beam := Atlas.texture_for(2,1)
			var size := beam.get_size()*(27.0/beam.get_width())
			draw_texture_rect(beam,Rect2(at+Vector2(-10,-fixture.height+3),size),false)
		else:
			# Small iron wall fastener remains static while the whole pendant
			# swings about its suspension ring, never around its center.
			draw_circle(at,1.8,Color("34343a"))
			draw_circle(at+Vector2(-0.4,-0.4),0.6,Color("ad9571"))
