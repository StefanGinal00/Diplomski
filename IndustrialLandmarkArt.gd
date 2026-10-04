@tool
extends Node2D
## Read-only scenery: native valves/flags still control the actual mechanics.
const SHEET := preload("res://art/visual_slice/ash_industrial_landmarks_v1.png")
const CROPS := [Rect2(33,12,661,550), Rect2(755,78,475,471), Rect2(76,631,564,595), Rect2(763,562,395,670)]
const CONTACTS := [548,470,594,668]
const Support := preload("res://WorldSupport.gd")
var kind := "fan_model"
var rotor: Sprite2D
var body: Sprite2D
var enabled := false
var nominal_height := 78.0
var retired: Array[CanvasItem] = []

static func finish_identity(nodes: Array[Node]) -> void:
	# Only audited, inert AshIdentity scenery; never valves or hazard lines.
	for node in nodes:
		if not node is Line2D or node.points.is_empty(): continue
		var parent := node.get_parent()
		if parent.get_parent()==null or parent.get_parent().name!="AshIdentity": continue
		var named := String(node.name)
		var style := ""
		var anchor: Vector2 = node.points[0]
		if parent.name=="TrainingYards" and named.begins_with("SpearRack"):
			style = "armour_rack"
			anchor += Vector2(65,8)
		elif parent.name=="PatrolStandards" and named.begins_with("StandardPole"):
			style = "watch_banner"
		elif parent.name=="MoltenConduits" and named.begins_with("Conduit"):
			# These screen-wide bright strokes falsely resemble active heat lanes.
			# The painted Forge background already contains its pipe network.
			node.hide()
			node.set_meta("industrial_sketch_retired",true)
		if style.is_empty(): continue
		var key := "Painted"+named
		if parent.has_node(NodePath(key)): continue
		var suffix := named.trim_prefix("SpearRack" if style=="armour_rack" else "StandardPole")
		var course := parent.get_parent().get_parent()
		if course.has_method("surface_at"):
			# Use the same gallery's authoritative snapped X AND Y. The old
			# sketch retained only Y and could sit outside the gallery entirely.
			anchor = course.surface_at(suffix.to_int()%int(course.GALLERY_COUNT),anchor.x)
		var site := Node2D.new()
		site.name = key
		site.position = anchor
		parent.add_child(site)
		attach(site,style)
		for old in parent.get_children():
			if not (old is Line2D or old is Polygon2D): continue
			var old_name := String(old.name)
			if old==node or (style=="armour_rack" and old_name.begins_with("Spear"+suffix+"_")) or (style=="watch_banner" and old_name=="Standard"+suffix):
				old.hide()
				old.set_meta("industrial_sketch_retired",true)

static func attach(site: Node2D, style: String) -> Node2D:
	if site.has_node("IndustrialLandmark"): return site.get_node("IndustrialLandmark")
	var art := new()
	art.name = "IndustrialLandmark"
	art.kind = style
	site.add_child(art)
	return art

func _ready() -> void:
	set_process(false)
	z_index = -1
	var names: Array = {"fan_model": ["Duct", "DuctFeet", "Blade0", "Blade1", "Blade2", "Blade3"], "armour_rack": ["Rack", "Armour0", "Armour1", "Armour2", "Belt0", "Belt1", "Belt2"], "watch_banner": ["Standard", "Cloth", "WatchEye"]}[kind]
	for named in names:
		var old := get_parent().get_node_or_null(NodePath(named))
		if old is Polygon2D or old is Line2D:
			old.hide()
			retired.append(old)
	var index := 0 if kind == "fan_model" else (2 if kind == "armour_rack" else 3)
	nominal_height = 78 if index == 0 else (56 if index == 2 else 76)
	body = _sprite(index, nominal_height)
	body.name = "Housing" if index == 0 else "PaintedFixture"
	var ratio := SHEET.get_size().y / 1254.0
	body.position.y = (body.texture.get_height()*0.5 - CONTACTS[index]*ratio) * body.scale.y
	if index == 0:
		rotor = _sprite(1, 37)
		rotor.name = "Rotor"
		rotor.position = Vector2(360.0-(33+661*0.5), 228.0-(12+548)) * ratio * body.scale
		set_meta("ambient_motion", true)

func _sprite(index: int, height: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	var ratio := SHEET.get_size() / Vector2(1254,1254)
	atlas.region = Rect2(CROPS[index].position * ratio, CROPS[index].size * ratio)
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2.ONE * height / atlas.region.size.y
	add_child(sprite)
	return sprite

func supply_surfaces(surfaces: Array[Rect2]) -> void:
	var anchor: Vector2 = get_parent().global_position
	# Identity landmarks were authored at deck centers, field sites at deck tops.
	# Accommodate either without touching the original positions or collision.
	var floor_rect := Support.below(anchor - Vector2(0,24), surfaces, 67)
	if not floor_rect.has_area():
		# Old overview landmarks sometimes use the unsnapped requested X while
		# their Y came from surface_at(). Move only this new painted cutout onto
		# the adjacent deck, never the authoring root, route or collider.
		var best := 180.0
		var half_width := body.texture.get_width()*body.scale.x*0.5+3
		for solid in surfaces:
			if absf(solid.position.y-anchor.y)>28 or solid.size.x<half_width*2: continue
			var x := clampf(anchor.x,solid.position.x+half_width,solid.end.x-half_width)
			if absf(x-anchor.x)<best:
				best = absf(x-anchor.x)
				floor_rect = solid
		if floor_rect.has_area(): anchor.x = clampf(anchor.x,floor_rect.position.x+half_width,floor_rect.end.x-half_width)
	if not floor_rect.has_area(): return
	position = get_parent().to_local(Vector2(anchor.x,floor_rect.position.y))
	var available := nominal_height
	for solid in surfaces:
		if solid.end.y > floor_rect.position.y-8: continue
		if solid.end.x < anchor.x-50 or solid.position.x > anchor.x+50: continue
		available = minf(available,floor_rect.position.y-solid.end.y-3)
	scale = Vector2.ONE * clampf(available/nominal_height,0.35,1)
	set_meta("contact_floor", floor_rect.position.y)
	set_meta("support_rect",floor_rect)

func set_enabled(value: bool) -> void:
	enabled = value
	if is_instance_valid(rotor):
		rotor.modulate = Color.WHITE if enabled else Color("96908a")
		if not enabled: rotor.rotation = 0

func animate(age: float) -> void:
	if is_instance_valid(rotor) and enabled: rotor.rotation = fposmod(age * 0.8, TAU)

func rest() -> void:
	# A stopped mechanism keeps its angle; leaving the viewport is not a reset.
	pass
