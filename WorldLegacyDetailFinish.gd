extends RefCounted
## Audited, art-only migrations of overview drawings. Never walks into enemy,
## hazard or collision subtrees. Device controllers keep all state authority.
const DEVICES := {
	"ShaftRelay.gd":"resonator", "SluiceValve.gd":"valve", "CisternDial.gd":"valve",
	"StarfallRelay.gd":"resonator", "ArchiveMirror.gd":"receiver", "EchoAnchor.gd":"anchor",
	"BarracksBeacon.gd":"receiver", "PressureCalibrationStation.gd":"valve", "AshSurveyStation.gd":"receiver",
}
static var textures := {}

static func install(nodes: Array[Node], id: String, floors: Array[Rect2]) -> void:
	for node in nodes:
		if not is_instance_valid(node) or node.has_meta("world_detail_finished"): continue
		# Former overview path ribbons are decorative, not attack/current cues.
		# Keep the native currents and telegraphs; retire only these exact guides.
		if node is Line2D and String(node.name).begins_with("ResonanceRibbon") and node.get_parent().get_script()==preload("res://EchoTraversal.gd"):
			node.hide()
			node.set_meta("world_detail_finished",true)
			continue
		var script: Script = node.get_script()
		var file := script.resource_path.get_file() if script!=null else ""
		if DEVICES.has(file):
			node.set_meta("world_detail_finished",true)
			# Specialized task art already owns this station's appearance.
			# Do not stack a generic receiver over a winch/seedbed/beacon.
			if node.has_node("TaskArt"): continue
			if node.has_node("DeviceArt"): continue
			var art := preload("res://EchoDeviceArt.gd").attach(node,DEVICES[file])
			art.bind_native_state = true
			art.set_meta("ambient_motion",true)
			var support := preload("res://WorldSupport.gd").below(node.global_position,floors,90)
			if support.has_area():
				var height: float = art.painted_rect.size.y
				var available := height
				for ceiling in floors:
					if ceiling.end.y<support.position.y-8 and ceiling.end.x>node.global_position.x-12 and ceiling.position.x<node.global_position.x+12:
						available=minf(available,support.position.y-ceiling.end.y-4)
				art.scale=Vector2.ONE*clampf(available/height,0.4,1)
				art.position.y = node.to_local(Vector2(node.global_position.x,support.position.y)).y-art.painted_rect.end.y*art.scale.y
				art.set_meta("support_floor",support)
			for leaf in node.get_children():
				if (leaf is Polygon2D or leaf is Line2D) and leaf.get_child_count()==0: leaf.self_modulate.a=0
			art.animate(0)
			continue
		if not node is Polygon2D or node.get_child_count()!=0 or script!=null or not node.visible or node.self_modulate.a<0.01: continue
		var named := String(node.name)
		var parent := node.get_parent()
		# The special survey camp was outside the usual field-dressing hierarchy.
		if named=="SurveyTent" and parent.get_script()==preload("res://ShaftExplorationSites.gd"):
			_replace(node,"tent",90,floors)
			continue
		if not String(parent.name).begins_with("Site"): continue
		if named.begins_with("Waystone"):
			_replace(node,"stone",28,floors)
		elif named in ["ClimbArrow","GuardianSeal","TaskSeal","FieldSeal"] or named.begins_with("GuardianSeal"):
			# Native site text still reports locked/completed; a painted carved
			# marker replaces the overview-scale floating diamond/arrow.
			_replace(node,"stone",20,floors)
		elif named=="Basin":
			node.color=Color("18333b")
			node.color.a=0.3
			node.self_modulate.a=0.35
			node.set_meta("world_detail_finished",true)

static func _replace(old: Polygon2D, kind: String, width: float, floors: Array[Rect2]) -> void:
	if old.polygon.is_empty(): return
	var rect := Rect2(old.polygon[0],Vector2.ZERO)
	for point in old.polygon: rect=rect.expand(point)
	var at := old.to_global(Vector2(rect.get_center().x,rect.end.y))
	var support := preload("res://WorldSupport.gd").below(at-Vector2(0,12),floors,160)
	if not support.has_area(): return
	if not textures.has(kind):
		var atlas := AtlasTexture.new()
		atlas.atlas = preload("res://art/visual_slice/echo_field_tent_v1.png") if kind=="tent" else preload("res://art/visual_slice/shaft_fixtures_v1.png")
		atlas.region = Rect2(90,132,1522,678) if kind=="tent" else Rect2(986,618,520,350)
		atlas.filter_clip=true
		textures[kind]=atlas
	# New modular silhouettes replace the generic repeated marker painting.
	var library:="dressing_cave_relics_v2"
	if preload("res://LivingSpriteAtlas.gd").DATA.has(library):
		var frame:=2 if kind=="tent" else (absi(String(old.get_path()).hash())%2)
		textures[kind]=preload("res://LivingSpriteAtlas.gd").frames_for(library)[frame]
	var art := Sprite2D.new()
	art.name="Painted"+String(old.name)
	art.texture=textures[kind]
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.scale=Vector2.ONE*width/art.texture.get_width()
	art.offset.y=-art.texture.get_height()*0.5
	art.z_index=-2
	old.get_parent().add_child(art)
	art.global_position=Vector2(clampf(at.x,support.position.x+width*0.5,support.end.x-width*0.5),support.position.y)
	if preload("res://LivingSpriteAtlas.gd").DATA.has(library):
		var contact: float=art.texture.get_height()-3.0*art.texture.atlas.get_height()/1024.0
		preload("res://WorldSupport.gd").plant(art,contact,support.position.y)
	old.self_modulate.a=0
	old.set_meta("world_detail_finished",true)
