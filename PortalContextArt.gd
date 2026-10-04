extends RefCounted
## A passage into a rock face, not a loose arch in front of the sky.
## Side passages stay traversable; only audited outer edges acquire a wall.
const SHEET := preload("res://art/visual_slice/portal_cliff_modules_v1.png")
const SOURCE_SIZE := Vector2(1330, 1182)
const REGIONS := [Rect2(14, 18, 443, 1153), Rect2(480, 15, 410, 1160), Rect2(914, 12, 406, 1160)]
const Support := preload("res://WorldSupport.gd")
const Atlas := preload("res://StructureAtlas.gd")
const Compact := preload("res://CompactPassageAtlas.gd")

static func install(actor: Node2D, room_id: String, surfaces: Array[Rect2], nodes: Array[Node] = []) -> void:
	var floor_rect := Support.below(actor.global_position, surfaces)
	if not floor_rect.has_area(): return
	var variant := Atlas.family(room_id)
	var plan := Compact.plan(actor.global_position.x,floor_rect,surfaces,variant,String(actor.name).hash())
	if actor.has_node("PortalSurround"):
		var existing := actor.get_node("PortalSurround")
		if existing.get_meta("structure_revision", 0) == 6 and existing.get_meta("supported_floor", Rect2()) == floor_rect and existing.get_meta("anchor_origin", Vector2.INF) == actor.global_position and existing.get_meta("facade_plan",{})==plan: return
		existing.free()
	var surround := Node2D.new()
	surround.name = "PortalSurround"
	surround.z_index = -4
	actor.add_child(surround)
	surround.global_position = Vector2(actor.global_position.x, floor_rect.position.y)
	var material_name := "starfall_masonry_v1" if variant == 2 else ("cinder_masonry_v1" if variant == 1 else "echo_path_stone_v1")
	var stone := load("res://art/visual_slice/%s.png" % material_name) as Texture2D
	var width: float = plan.width
	var facade: Sprite2D = actor.get_node("FinishedDevice")
	if plan.compact: Compact.configure(facade,variant,plan)
	else: Atlas.configure(facade, Atlas.FACADES, Atlas.FACADE_SIZE, Atlas.FACADES_RECTS[variant], width)
	facade.global_position.x=plan.x
	facade.set_meta("structural_facade", true)
	facade.z_index = -3 # rear wall: lamps, residents and relics stay in front too
	facade.modulate = Color("c1cbd0") if variant != 1 else Color("cbb8a7")
	Support.plant(facade, facade.get_meta("contact_row"), floor_rect.position.y)
	# A facade on a shelf must join the nearest real wall or underlying floor,
	# rather than acquiring another isolated decorative pillar.
	var anchor := _anchor(actor.global_position.x, floor_rect, surfaces, nodes)
	var local_anchor: Rect2 = surround.global_transform.affine_inverse() * anchor.rect
	var backing := Polygon2D.new()
	backing.name = "RockFace"
	if anchor.kind == "wall":
		var edge: float = local_anchor.get_center().x
		var direction := signf(edge)
		var rise := minf(100,plan.height*0.85)
		backing.polygon = PackedVector2Array([Vector2(direction * width * 0.22, 8), Vector2(edge, 8), Vector2(edge, -rise), Vector2(direction * width * 0.33, -rise*0.88)])
	else:
		var bottom: float = local_anchor.position.y + 8
		var half := width * 0.31
		backing.polygon = PackedVector2Array([Vector2(-half, -8), Vector2(half, -8), Vector2(half*.84, bottom), Vector2(-half*.88, bottom)])
	surround.add_child(backing)
	preload("res://RoomArtFinish.gd")._material(backing, stone, Color("515d60"))
	if anchor.kind=="wall":
		# Join the mouth to a rough buttress, never a strip of square tiles.
		var edge: float = local_anchor.get_center().x
		if plan.compact:
			# One continuous textured shoulder, not isolated miniature pillars
			# against a conspicuous flat-colour rectangle beside the doorway.
			var direction:=signf(edge)
			var rise: float=plan.height
			backing.polygon=PackedVector2Array([Vector2(direction*width*0.16,6),Vector2(edge,6),Vector2(edge,-rise*0.94),Vector2(edge*0.83,-rise*0.74),Vector2(edge*0.52,-rise*0.81),Vector2(direction*width*0.16,-rise*0.56)])
			var wall_texture:=stone
			if variant>0: wall_texture=load("res://art/visual_slice/city_wall_%s_v1.png"%("citadel" if variant==2 else "cinder"))
			preload("res://RoomArtFinish.gd")._material(backing,wall_texture,Color("68717a"))
		else:
			backing.texture=null
			backing.material=null
			backing.color=Color("101b20")
			for blend in [0.52,0.82]:
				var rise: float=minf(plan.height,152+(12 if blend>0.7 else 0))
				_module(surround,variant,Vector2(edge*blend,8),Vector2(rise*0.37,rise),edge<0)
	surround.set_meta("supported_floor", floor_rect)
	surround.set_meta("structural_anchor", anchor)
	surround.set_meta("structure_revision", 6)
	surround.set_meta("facade_plan",plan)
	surround.set_meta("anchor_origin", actor.global_position)
	preload("res://LedgeSupportArt.gd").attach(surround, variant, minf(width * 0.6, 90))
	# A shallow threshold joins the painted facade to the actual ledge. Its
	# native collider and arrival area remain authoritative and unchanged.
	var threshold_frame := 5 if variant==2 else (4 if variant==1 else absi(String(actor.name).hash())%3)
	if room_id.begins_with("shaft") or room_id=="sunken_shaft": threshold_frame=3
	var threshold_width := minf(42,maxf(12,minf(actor.global_position.x-floor_rect.position.x,floor_rect.end.x-actor.global_position.x)*2))
	var threshold_x := clampf(plan.x,floor_rect.position.x+threshold_width*0.5,floor_rect.end.x-threshold_width*0.5)
	var threshold := preload("res://GateDressingAtlas.gd").grounded(surround,"Threshold",4,threshold_frame,Vector2(threshold_x,floor_rect.position.y),threshold_width)
	threshold.modulate=Color("9eaaa8")
	threshold.z_index=2

static func _anchor(x: float, floor_rect: Rect2, surfaces: Array[Rect2], nodes: Array[Node]) -> Dictionary:
	var nearest := Rect2()
	var distance := 130.0
	for node in nodes:
		if not is_instance_valid(node): continue
		if not node is CollisionShape2D or node.disabled or not node.shape is RectangleShape2D: continue
		if not node.get_parent() is StaticBody2D or node.get_parent().is_in_group("breakable"): continue
		var rect: Rect2 = node.global_transform * Rect2(-node.shape.size / 2, node.shape.size)
		if rect.size.y < 80 or rect.size.y <= rect.size.x or rect.position.y > floor_rect.position.y - 15 or rect.end.y < floor_rect.position.y: continue
		var gap := absf(rect.get_center().x - x)
		if gap < distance:
			distance = gap
			nearest = rect
	if nearest.has_area(): return {"kind": "wall", "rect": nearest}
	var below := Support.below(Vector2(x, floor_rect.end.y + 3), surfaces, 1200)
	if below.has_area(): return {"kind": "lower_floor", "rect": below}
	# Main ground is the foundation when no lower room terrain exists.
	return {"kind": "foundation", "rect": floor_rect}

static func _module(parent: Node2D, variant: int, foot: Vector2, size: Vector2, mirrored: bool) -> Sprite2D:
	var sprite := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	var ratio := SHEET.get_size() / SOURCE_SIZE
	atlas.region = Rect2(REGIONS[variant].position * ratio, REGIONS[variant].size * ratio)
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2.ONE*minf(size.x/atlas.region.size.x,size.y/atlas.region.size.y)
	sprite.position = foot - Vector2(0, atlas.region.size.y*sprite.scale.y * 0.5)
	sprite.flip_h = mirrored
	sprite.modulate = Color("9ea6a1")
	parent.add_child(sprite)
	return sprite

static func close_outer_edges(room: Node2D, nodes: Array[Node], surfaces: Array[Rect2], room_id: String) -> void:
	var left := INF
	var right := -INF
	for rect in surfaces:
		left = minf(left, rect.position.x)
		right = maxf(right, rect.end.x)
	var walls: Dictionary = {}
	for node in nodes:
		if not (node is LevelExit or node.is_in_group("room_door")): continue
		var support := Support.below(node.global_position, surfaces)
		if not support.has_area(): continue
		# Only the actual world-wide edge, not an individual ledge/shaft edge.
		var side := -1 if node.global_position.x - left <= 80 else (1 if right - node.global_position.x <= 80 else 0)
		if side == 0: continue
		var edge := left if side < 0 else right
		# Place outside existing terrain, never through a door or arrival.
		var rect := Rect2(Vector2(edge - (64 if side < 0 else 0), support.position.y - 540), Vector2(64, 720))
		var occupied := false
		for member in nodes:
			if member is Marker2D and rect.grow(12).has_point(member.global_position): occupied = true; break
		if occupied: continue
		# One vertical edge may serve multiple floors; merge overlapping spans.
		if walls.has(side):
			var prior: Rect2 = walls[side]
			walls[side] = prior.merge(rect)
		else: walls[side] = rect
	for side in walls:
		var named := "PortalBoundaryWest" if side < 0 else "PortalBoundaryEast"
		if room.has_node(named): continue
		var rect: Rect2 = walls[side]
		var body := StaticBody2D.new()
		body.name = named
		body.set_meta("portal_boundary", true)
		room.add_child(body)
		body.global_position = rect.get_center()
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		col.shape = RectangleShape2D.new()
		col.shape.size = rect.size / body.global_scale.abs()
		body.add_child(col)
		var face := Polygon2D.new()
		face.name = "CliffMaterial"
		var size: Vector2 = col.shape.size * 0.5
		face.polygon = PackedVector2Array([-size, Vector2(size.x, -size.y), size, Vector2(-size.x, size.y)])
		body.add_child(face)
		var texture: Texture2D = load("res://art/visual_slice/%s.png" % ("starfall_masonry_v1" if room_id.begins_with("starfall_") else ("cinder_masonry_v1" if room_id.begins_with("ash_") else "echo_path_stone_v1")))
		preload("res://RoomArtFinish.gd")._material(face, texture, Color("778183"))
		body.set_meta("world_surface_finished", true)
		var variant := 2 if room_id.begins_with("starfall_") else (1 if room_id.begins_with("ash_") or room_id.begins_with("shaft_") or room_id == "sunken_shaft" else 0)
		for index in range(ceili(rect.size.y / 170)):
			_module(body, variant, Vector2(-side * 22, -size.y + (index + 1) * 170), Vector2(47, 182), side > 0)
