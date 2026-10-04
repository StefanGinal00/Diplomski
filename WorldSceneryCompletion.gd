extends RefCounted
## Paint-only coverage for audited background sketches. Never replaces a hazard,
## actor, collider or controller. Original leaves retain live color/visibility.
const Atlas:=preload("res://LivingSpriteAtlas.gd")
const Support:=preload("res://WorldSupport.gd")
const FIELD_SCRIPTS:=["RouteFieldDressing.gd","ShaftRouteDressing.gd","ExpeditionFieldDressing.gd","AshRouteDressing.gd","AshIndustryDressing.gd","StarfallRouteDressing.gd","EchoHabitatDressing.gd","EchoCrossingDressing.gd"]
static func install(nodes: Array[Node],room_id: String,floors: Array[Rect2]) -> void:
	var ash:=room_id.begins_with("ash_")
	var star:=room_id.begins_with("starfall_")
	for old in nodes:
		if room_id=="starfall_outskirts" and old is Polygon2D and String(old.name).begins_with("Identity") and String(old.get_parent().name)=="StarfallDescent":
			_finish_outskirts_tower(old,floors)
			continue
		if old is Line2D:
			_finish_line(old,floors)
			continue
		if not old is Polygon2D or old.texture!=null or old.get_script()!=null or old.get_child_count()!=0 or not old.visible or old.self_modulate.a<0.01 or old.has_meta("scenery_completed"): continue
		var owner_node: Node=old.get_parent()
		while owner_node!=null and owner_node.get_script()==null: owner_node=owner_node.get_parent()
		var owner_file: String=owner_node.get_script().resource_path.get_file() if owner_node!=null else ""
		var name:=String(old.name)
		var spec: Array=[]
		var hang:=false
		var centered:=false
		var stateful:=false
		if owner_file in FIELD_SCRIPTS:
			if name.begins_with("Tablet"): spec=["dressing_cave_relics_v2",1,32.0]
			elif name=="ReturnStone": spec=["dressing_cave_relics_v2",0,42.0]
			elif name=="Boat": spec=["dressing_waterworks_v1",1,54.0]
			elif name in ["TankShell","Vessel"]: spec=["dressing_star_relics_v1" if star else "dressing_waterworks_v1",2 if star else 0,56.0]
			elif name=="Weight": spec=["dressing_waterworks_v1",3,38.0];hang=true
			elif name in ["WestPier","EastPier"] or name.begins_with("AnchorPylon"): spec=["dressing_waterworks_v1",4,72.0]
			elif name.begins_with("Shield"): spec=["dressing_cave_relics_v2",1,30.0]
			elif name.begins_with("Resonator") or name.begins_with("Light") or name=="RecordLight": spec=["dressing_star_relics_v1" if star else "dressing_cave_relics_v2",7,38.0];stateful=true
			elif name=="WardSeal": spec=["dressing_star_relics_v1",0,40.0];stateful=true
			elif name=="TornStandard": spec=["dressing_star_relics_v1",3,48.0];stateful=true
			elif name.begins_with("SeedPot"): spec=["dressing_star_relics_v1",1,23.0]
			elif name=="KilnShell": spec=["dressing_ash_architecture_v1",6,58.0]
			elif name.begins_with("KilnWindow"): old.self_modulate.a=0;continue
			elif name.begins_with("Folio"): spec=["dressing_cave_relics_v2",1,26.0]
			elif name in ["Water","ChannelWater","Basin"]: _water(old);continue
		elif owner_file=="ExpeditionWing.gd" and "KilnArch" in name: spec=["dressing_ash_architecture_v1",0,125.0]
		elif owner_file=="AshSwitchback.gd":
			if name.begins_with("KilnHousing"): spec=["dressing_ash_architecture_v1",0,126.0]
			elif name.begins_with("KilnMouth"): old.self_modulate.a=0;continue
			elif name.begins_with("WatchTower"): spec=["dressing_ash_architecture_v1",1,155.0]
			elif name.begins_with("Barricade"): spec=["dressing_ash_architecture_v1",2,45.0]
			elif name.begins_with("Bell"): spec=["dressing_ash_architecture_v1",3,55.0];hang=true
			elif name.begins_with("RoseWindow"): spec=["dressing_ash_architecture_v1",4,60.0];centered=true
			elif name.begins_with("Tank"): spec=["dressing_waterworks_v1",0,80.0]
			elif name.begins_with("Beacon"): spec=["dressing_ash_architecture_v1",7,35.0]
		elif owner_file=="EchoTraversal.gd":
			if name.begins_with("ChoirHeart"): spec=["dressing_cave_relics_v2",5,32.0];centered=true
			elif name.begins_with("WhisperBell"): spec=["dressing_cave_relics_v2",3,40.0];hang=true
			elif name.begins_with("ReadingMirror"): spec=["dressing_cave_relics_v2",4,55.0]
		elif owner_file=="StarfallRoomExpansion.gd":
			if name.begins_with("MuteBell"): spec=["dressing_star_relics_v1",4,45.0];hang=true
			elif name.begins_with("RootHeart"): spec=["dressing_star_relics_v1",1,30.0];centered=true
			elif name.begins_with("SoulCore"): spec=["dressing_star_relics_v1",2,42.0];centered=true
		elif owner_file=="StarfallSoulCrucible.gd" and name=="Heart":
			spec=["dressing_star_relics_v1",7,46.0];centered=true;stateful=true
		elif owner_file in ["BarracksTrial.gd","AshChapelTrial.gd"] and (name.begins_with("FurnaceWindow") or name=="WindowGlow"):
			spec=["dressing_ash_architecture_v1",4,65.0];centered=true;stateful=true
		elif owner_file=="CounterweightBridge.gd" and name=="Walkway":
			preload("res://RoomArtFinish.gd")._material(old,load("res://art/visual_slice/drift_iron_v1.png"),Color("8c9393"))
		if spec.is_empty():
			if name in ["DeepPool","Reservoir","BasinMist","MoltenPool"]: _water(old)
			elif name in ["DeepGlow","ChasmGlow","ReservoirGlow","PitGlow","CoalGlow","PrismBeam","PrismLight","BuriedGlow","GateGlow"]: old.self_modulate.a=0.12
			elif name=="CocoonCluster": spec=["dressing_cave_relics_v2",6,80.0];hang=true
			elif name in ["BrokenPillar","GateLeftPillar","GateRightPillar","RuinLeft","RuinRight","GateLeftTower","GateRightTower"]: spec=["dressing_ash_architecture_v1" if ash else "dressing_waterworks_v1",5 if ash else 4,100.0]
			elif name=="FallenShard": spec=["dressing_cave_relics_v2",5,35.0]
			elif name=="CelestialDial": spec=["dressing_star_relics_v1",6,35.0]
			elif name=="CivicStarChart": spec=["dressing_star_relics_v1",6,48.0];centered=true
			elif name.begins_with("BellChain") and owner_file=="StarfallUpperCity.gd":
				preload("res://RoomArtFinish.gd")._material(old,load("res://art/visual_slice/drift_iron_v1.png"),Color("95866b"))
			elif name=="HearthDistrictArch": spec=["dressing_ash_architecture_v1",0,150.0]
			elif name=="GateLintel" or name.begins_with("StreetBench") or name.begins_with("QuarterStall") or (name.begins_with("LowerHome") and name.ends_with("Balcony")):
				preload("res://RoomArtFinish.gd")._material(old,load("res://art/visual_slice/cinder_masonry_v1.png" if ash else "res://art/visual_slice/echo_path_stone_v1.png"),Color("63777d"))
		if spec.is_empty() or not Atlas.DATA.has(spec[0]): continue
		_paint(old,spec,floors,hang,centered,stateful)

static func _finish_outskirts_tower(old: Polygon2D,floors: Array[Rect2]) -> void:
	if old.get_script()!=null or old.get_child_count()!=0 or old.has_meta("scenery_completed"): return
	var rect:=_bounds(old)
	var bottom:=old.to_global(Vector2(rect.get_center().x,rect.end.y))
	var floor_rect:=Support.below(bottom-Vector2(0,12),floors,70)
	if not floor_rect.has_area(): return
	var variant:=absi(String(old.name).hash())%6
	var texture:=preload("res://CityParallaxAtlas.gd").texture_for(variant/3,variant%3)
	var art:=Sprite2D.new()
	art.name="SceneryPainting";art.texture=texture
	art.scale=Vector2.ONE*minf(rect.size.y,160)/texture.get_height()
	art.offset.y=-texture.get_height()*0.5
	art.modulate=Color("67718a")
	art.z_index=-2
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	old.add_child(art)
	art.global_position=Vector2(bottom.x,floor_rect.position.y)
	Support.plant(art,texture.get_height()-3,floor_rect.position.y)
	art.set_meta("scenery_completed",true)
	old.self_modulate.a=0
	old.set_meta("scenery_completed",true)
static func _finish_line(line: Line2D,floors: Array[Rect2]) -> void:
	if line.texture!=null or line.get_child_count()!=0 or not line.visible or line.self_modulate.a<0.01 or line.has_meta("scenery_completed"): return
	var owner_node: Node=line.get_parent()
	while owner_node!=null and owner_node.get_script()==null: owner_node=owner_node.get_parent()
	var owner_file: String=owner_node.get_script().resource_path.get_file() if owner_node!=null else ""
	var named:=String(line.name)
	if (owner_file=="ShaftRoomExpansion.gd" and named.begins_with("GalleryManifold")) or (line.get_parent().name=="FloodedGallery" and named in ["UpperConduit","LowerConduit"]):
		line.texture=load("res://art/visual_slice/drift_iron_v1.png")
		line.texture_mode=Line2D.LINE_TEXTURE_TILE
		line.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
		line.default_color=Color("8d978f")
		line.width=minf(line.width,5.5)
		line.joint_mode=Line2D.LINE_JOINT_ROUND
		var metal:=ShaderMaterial.new(); metal.shader=preload("res://shaders/aged_conduit.gdshader")
		line.material=metal; line.set_meta("painted_pressure_pipe",true)
		line.set_meta("scenery_completed",true)
		return
	if owner_file=="ExpeditionWing.gd" and named.ends_with("OutlineFloor"):
		line.self_modulate.a=0 # Old room blueprint, not a traversal surface.
		line.set_meta("scenery_completed",true)
		return
	if named=="HangingRoots" and line.get_script()==null:
		preload("res://RootRibbonArt.gd").paint(line,6)
		return
	if owner_file not in FIELD_SCRIPTS: return
	if owner_file=="ExpeditionFieldDressing.gd" and named in ["TaskSeal","ReturnSeal"]:
		# Native modulate still tints these grounded markers when progress changes.
		# The same detailed task/return status remains readable with G.
		_paint(line,["dressing_cave_relics_v2",7,16.0],floors,false,false,false)
		var anchor: Node2D = line.get_node("PaintedDetailAnchor")
		anchor.global_transform=Transform2D(0,anchor.global_position)
		line.set_meta("compact_return_marker",true)
		return
	if named.begins_with("Mark") and named.trim_prefix("Mark").is_valid_int() and line.get_script()==null and line.get_child_count()==0:
		# Mark0/1/2 were schematic chevrons on the old large waystones.
		# The compact painted stones and native G notice now carry that clue.
		line.self_modulate.a=0
		line.set_meta("scenery_completed",true)
		return
	if named.begins_with("Seedling") or named.begins_with("Fork") or named.begins_with("Grate") or named.begins_with("SignalRing") or named.begins_with("SignalPost") or named in ["LensFrame","OpticalTrace","Meridian","Pedestal","ContainmentRing","AbandonedWheel","Waterline","BrokenSpar"]:
		# The newly painted fern and pot are a single correctly sized object.
		line.self_modulate.a=0
		line.set_meta("scenery_completed",true)
		return
	var spec: Array=[]
	if named in ["ChoirFrame","Support","LensStand","OuterLens","SurveyTripod","WaterStaff","MemoryOrbit"]: spec=["dressing_cave_relics_v2",7,46.0]
	elif named in ["DivingRack","BearerRail"]: spec=["dressing_cave_relics_v2",2,55.0]
	elif named=="Belfry": spec=["dressing_ash_architecture_v1",3,55.0]
	elif named=="WardArch": spec=["dressing_star_relics_v1",0,50.0]
	elif named=="WindowFrame": spec=["dressing_waterworks_v1",0,58.0]
	elif named=="PanelFrame": spec=["dressing_ash_architecture_v1",6,46.0]
	elif named.begins_with("Stem"): spec=["dressing_star_relics_v1",1,23.0]
	elif named in ["Desk","TableFrame"]:
		_paint_desk(line,floors)
		return
	if not spec.is_empty(): _paint(line,spec,floors,false,false,false)
	elif named in ["Pipe","BleedPipe","BrokenTether","ReturnTrace","SilkHammock"]:
		line.texture=load("res://art/visual_slice/drift_iron_v1.png")
		line.texture_mode=Line2D.LINE_TEXTURE_TILE
		line.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
		line.default_color=Color("76807f")
		line.width=minf(line.width,2)
		line.set_meta("scenery_completed",true)

static func _paint_desk(old: Line2D,floors: Array[Rect2]) -> void:
	var rect:=_bounds(old)
	var bottom:=old.to_global(Vector2(rect.get_center().x,rect.end.y))
	var support:=Support.below(bottom-Vector2(0,18),floors,160)
	if not support.has_area(): return
	var source: Array=preload("res://EchoPaintedProps.gd").SOURCES.desk
	var texture:=AtlasTexture.new()
	texture.atlas=load(source[0]);texture.region=source[1];texture.filter_clip=true
	var art:=Sprite2D.new()
	art.name="SceneryPainting";art.texture=texture
	art.z_index=-2
	old.add_child(art)
	art.scale=Vector2.ONE*65/texture.get_width()
	art.offset.y=-texture.get_height()*0.5
	art.global_position=Vector2(bottom.x,support.position.y)
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	Support.plant(art,texture.get_height()-3,support.position.y)
	old.self_modulate.a=0
	old.set_meta("scenery_completed",true)
	art.set_meta("scenery_completed",true)

static func _bounds(old: Node2D) -> Rect2:
	var points: PackedVector2Array=old.polygon if old is Polygon2D else old.points
	var rect:=Rect2(points[0],Vector2.ZERO)
	for p in points: rect=rect.expand(p)
	return rect

static func _paint(old: Node2D,spec: Array,floors: Array[Rect2],hang: bool,centered: bool,stateful: bool) -> void:
	var rect:=_bounds(old)
	var height:=float(spec[2])
	var bottom:=old.to_global(Vector2(rect.get_center().x,rect.end.y))
	var support:=Support.below(bottom-Vector2(0,18),floors,160)
	if hang: bottom=old.to_global(Vector2(rect.get_center().x,rect.position.y))+Vector2(0,height)
	elif centered: bottom=old.to_global(rect.get_center())+Vector2(0,height*0.5)
	elif support.has_area(): bottom.y=support.position.y
	var anchor:=Node2D.new()
	anchor.name="PaintedDetailAnchor"
	old.add_child(anchor)
	anchor.global_position=bottom
	var art: Sprite2D=preload("res://SceneryStateArt.gd").new() if stateful else Sprite2D.new()
	art.name="SceneryPainting"
	art.z_index=-2
	anchor.add_child(art)
	Atlas.show(art,str(spec[0]),int(spec[1]),height,0,1,0,"root")
	art.set_meta("scenery_completed",true)
	if not support.has_area() or hang or centered: art.remove_meta("contact_floor")
	# Keep native transforms and visibility alive; only the polygon's own paint
	# disappears. Children and all controller references remain intact.
	old.self_modulate.a=0
	old.set_meta("scenery_completed",true)
	if stateful: art.bind_source(old)
static func _water(old: Polygon2D) -> void:
	var path:="res://art/visual_slice/ambient_water_surface_v1.png"
	if not ResourceLoader.exists(path): return
	var tint:=old.color
	tint.r*=0.6;tint.g*=0.6;tint.b*=0.6
	preload("res://RoomArtFinish.gd")._material(old,load(path),tint)
	var shader:=ShaderMaterial.new()
	shader.shader=preload("res://shaders/ambient_water_surface.gdshader")
	old.material=shader
	old.set_meta("scenery_completed",true)
