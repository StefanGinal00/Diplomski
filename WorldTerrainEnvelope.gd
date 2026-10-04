extends Node2D
## Static art around real outer solids. No new physics and no filled-in bridges.
const CLIFF := preload("res://art/visual_slice/terrain_cliff_edges_v1.png")
const EARTH := preload("res://art/visual_slice/terrain_foundations_v1.png")
var foundations: Array[Rect2] = []
var boundaries: Array[Rect2] = []
var family := 0
static var seam_materials := {}

static func install(room: Node2D, id: String, nodes: Array[Node]) -> Node2D:
	var old := room.get_node_or_null("TerrainEnvelope")
	if old != null: return old
	var envelope := preload("res://WorldTerrainEnvelope.gd").new()
	envelope.name = "TerrainEnvelope"
	envelope.z_index = -5 # Behind portal mouths and actors, ahead of distant scenery.
	room.add_child(envelope)
	envelope.family = 1 if id.begins_with("ash_") else (2 if id.begins_with("starfall_") else 0)
	envelope._build(nodes)
	return envelope

func _build(nodes: Array[Node]) -> void:
	var floors: Array[Rect2] = []
	var ground: Array[bool] = []
	var walls: Array[CollisionShape2D] = []
	var edges: Array[float] = []
	for node in nodes:
		if not node is CollisionShape2D or node.disabled or node.one_way_collision or not node.shape is RectangleShape2D: continue
		var body := node.get_parent()
		if not body is StaticBody2D or body.is_in_group("enemy") or body.is_in_group("breakable"): continue
		if not is_zero_approx(node.global_rotation): continue
		var rect: Rect2 = global_transform.affine_inverse() * node.global_transform * Rect2(-node.shape.size / 2, node.shape.size)
		if rect.size.x > rect.size.y and rect.size.x >= 50:
			floors.append(rect)
			var named := String(body.name).to_lower()
			var open_ledge := false
			for token in ["platform","ledge","bridge","shelf","rung","step","ceiling"]:
				if token in named: open_ledge=true; break
			ground.append((rect.size.x >= 300 or "terminalfloor" in named) and not open_ledge)
			edges.append(rect.position.x)
			edges.append(rect.end.x)
		elif rect.size.y >= 100 and rect.size.x <= 90:
			if node.has_meta("boundary_envelope_superseded"):
				# The extension owns the cliff art. Do not leave the shorter
				# original wall's rectangular tiled face in front of that rock.
				for leaf in body.get_children():
					if (leaf is Polygon2D or leaf is Sprite2D or leaf is Line2D) and leaf.get_script()==null: leaf.hide()
			else:
				walls.append(node)
	if floors.is_empty(): return
	edges.sort()
	# Only the lowest floor in each x interval has earth beneath it. Upper
	# ledges, lift shafts and rooms below remain entirely visible.
	for i in range(edges.size() - 1):
		if edges[i + 1] - edges[i] < 0.5: continue
		var x: float = (edges[i] + edges[i + 1]) * 0.5
		var bottom := -INF
		var winner := -1
		for f in floors.size():
			var floor_rect := floors[f]
			if x >= floor_rect.position.x and x <= floor_rect.end.x and floor_rect.end.y > bottom:
				bottom = floor_rect.end.y
				winner = f
		if winner<0 or not ground[winner]: continue
		var strip := Rect2(edges[i], bottom - 2, edges[i + 1] - edges[i], 88)
		if not foundations.is_empty() and is_equal_approx(foundations[-1].position.y, strip.position.y) and is_equal_approx(foundations[-1].end.x, strip.position.x):
			foundations[-1].size.x += strip.size.x
		else: foundations.append(strip)
	for rect in foundations:
		_solid("DeepEarth", Rect2(rect.position + Vector2(0, 70), Vector2(rect.size.x, 1600)))
		var x := rect.position.x
		while x < rect.end.x - 0.1:
			var width := minf(396, rect.end.x - x)
			var ratio := EARTH.get_size()/Vector2(1536,1024)
			var art := _sprite("EarthCrust", EARTH, Rect2(Vector2(0,family*341+2)*ratio,Vector2(width/0.258,337)*ratio))
			art.position = Vector2(x, rect.position.y)
			art.scale = Vector2.ONE * 0.258 / ratio
			if x>rect.position.x:
				var join := ShaderMaterial.new()
				join.shader=preload("res://TerrainFoundationJoin.gdshader")
				join.set_shader_parameter("source_rect",Vector4(0,float(family*341+2)/1024.0,width/0.258/1536.0,337.0/1024.0))
				art.material=join
			if x+width>=rect.end.x-0.1: break
			x += width-44
	for wall in walls:
		var r: Rect2 = global_transform.affine_inverse() * wall.global_transform * Rect2(-wall.shape.size / 2, wall.shape.size)
		var west := r.get_center().x < (edges[0] + edges[-1]) * 0.5
		var outer := r.end.x <= edges[0] + 85 if west else r.position.x >= edges[-1] - 85
		# A local shaft edge can have another playable branch on its far side.
		# Only true room-wide boundaries may receive an opaque outer mass.
		if not outer:
			_rock_column(wall,r)
			continue
		boundaries.append(r)
		# Retire only this solid's old face. The new opaque mass ends at the
		# same playable edge; portals remain drawn in front of it.
		for leaf in wall.get_parent().get_children():
			if leaf is Polygon2D and leaf.get_script() == null: leaf.hide()
		var edge := r.end.x if west else r.position.x
		var top := r.position.y-650
		var bottom := r.end.y
		for floor_rect in floors: bottom=maxf(bottom,floor_rect.end.y+1100)
		# The mass continues into the same buried bedrock as the lowest floor,
		# so a short physical wall cannot leave a suspended black rectangle.
		# Meet the physical boundary exactly. The old two-pixel inset exposed
		# a bright vertical slice of distant scenery beside buried foundations.
		_solid("OuterRockMass", Rect2(edge - 900 if west else edge, top, 900, bottom-top))
		var y := top
		while y < bottom - 0.1:
			var height := minf(310, bottom - y)
			var ratio := CLIFF.get_size()/Vector2(1536,1024)
			var art := _sprite("NaturalCliff", CLIFF, Rect2(Vector2(family*512,0)*ratio,Vector2(512,height/0.303)*ratio))
			art.scale = Vector2(-0.303 if not west else 0.303, 0.303) / ratio
			art.position = Vector2(edge - 139 if west else edge + 139, y)
			art.material=_seam_material(Vector4(float(family)/3.0,0,1.0/3.0,height/0.303/1024.0))
			art.modulate=Color(0.48,0.61,0.66)
			if height<35: break
			y += height-28

func _rock_column(wall: CollisionShape2D, rect: Rect2) -> void:
	# Interior pillars can have playable space on BOTH sides. Keep their solid
	# width, but replace the tiled ruler-like face with overlapping crag edges.
	for leaf in wall.get_parent().get_children():
		if leaf is Polygon2D and leaf.get_script()==null: leaf.hide()
	var width := maxf(rect.size.x*1.15,24)
	var y := rect.position.y-4
	while y < rect.end.y-0.1:
		var source: Rect2 = preload("res://PortalContextArt.gd").REGIONS[family]
		var height := width*source.size.y/source.size.x
		var sheet := preload("res://PortalContextArt.gd").SHEET
		var ratio := sheet.get_size()/preload("res://PortalContextArt.gd").SOURCE_SIZE
		var art := _sprite("InteriorCrag",sheet,Rect2(source.position*ratio,Vector2(source.size.x,height/width*source.size.x)*ratio))
		art.scale=Vector2.ONE*width/(source.size.x*ratio.x)
		art.position=Vector2(rect.get_center().x-width*0.5,y)
		art.modulate=Color(0.74,0.81,0.81)
		# Overlap feathered ends instead of exposing atlas cuts at every join.
		art.material=_seam_material(Vector4(source.position.x/sheet.get_width()*ratio.x,source.position.y/sheet.get_height()*ratio.y,source.size.x/sheet.get_width()*ratio.x,source.size.y/sheet.get_height()*ratio.y))
		y += height*0.84

static func _seam_material(region: Vector4) -> ShaderMaterial:
	if seam_materials.has(region): return seam_materials[region]
	var material:=ShaderMaterial.new()
	material.shader=preload("res://TerrainSeamFade.gdshader")
	material.set_shader_parameter("source_rect",region)
	seam_materials[region]=material
	return material

func _sprite(named: String, source: Texture2D, region: Rect2) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = region
	atlas.filter_clip = true
	var art := Sprite2D.new()
	art.name = named
	art.texture = atlas
	art.centered = false
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(art)
	return art

func _solid(named: String, rect: Rect2) -> void:
	var solid := Polygon2D.new()
	solid.name = named
	solid.set_meta("terrain_mass_kind",named)
	solid.color = Color("050a0d")
	solid.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	add_child(solid)
