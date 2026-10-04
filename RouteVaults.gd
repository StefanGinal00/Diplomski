extends Node2D
## Genuine shallow ceiling additions beneath existing broad solid terrain.
## No shaft mouths, boss arenas, jumping ledges or native interaction moves.
const Support := preload("res://WorldSupport.gd")
const Placement := preload("res://RouteDressingPlacement.gd")
const Atlas := preload("res://RouteDressingAtlas.gd")
const MAX_VAULTS := 8
const HEADROOM := 110.0 # +13px visual inset, +8px solid inset: >128px actual clearance.
var vaults: Array[StaticBody2D] = []
var plans: Array[Dictionary] = []

static func install(room: Node2D, id: String, nodes: Array[Node]) -> Node2D:
	var prior := room.get_node_or_null("RouteVaults")
	if prior != null:
		prior.refresh(nodes); return prior
	var group := new(); group.name = "RouteVaults"; room.add_child(group)
	group.set_process(false)
	group._build(id,nodes)
	return group

func _build(id: String, nodes: Array[Node]) -> void:
	if id in ["echo_haven","echo_haven_outskirts","ash_hearth","ash_hearth_outskirts","starfall_citadel"]: return
	if id in ["training_passage","sunken_shaft","echo_sanctum","ash_arena","ash_throne","starfall_empty_court","starfall_hollow_throne"]: return
	for node in nodes:
		if node.is_in_group("boss"): return
	var surfaces := Support.floors(nodes)
	var solids := Support.solids(nodes)
	var reserved := Placement.reservations(nodes,true)
	var uppers: Array[Rect2] = []
	for node in nodes:
		if not node is CollisionShape2D or node.disabled or node.one_way_collision or not node.shape is RectangleShape2D: continue
		if not node.get_parent() is StaticBody2D or node.get_parent().is_in_group("breakable") or node.get_parent().is_in_group("enemy") or not is_zero_approx(node.global_rotation): continue
		var rect: Rect2 = node.global_transform*Rect2(-node.shape.size/2,node.shape.size)
		if rect.size.x >= 410 and rect.size.y >= 14 and rect.size.y <= 90: uppers.append(rect)
	# Round-robin selects separated pockets across the room's vertical tiers.
	# Keep broad central pockets first. If authored piers or machinery rule out
	# their centre, search narrower off-centre bays instead of abandoning the
	# entire ceiling. Landing margins and the same swept volume tests still apply.
	var widths := [480.0,320.0,240.0,280.0,280.0,220.0,220.0,220.0,220.0]
	var fractions := [.5,.24,.76,.38,.62,.14,.86,.46,.54]
	for pass_index in widths.size():
		for upper in uppers:
			if vaults.size() >= MAX_VAULTS: return
			var width := minf(widths[pass_index],upper.size.x-190)
			var fraction: float = fractions[pass_index]
			var x := clampf(lerpf(upper.position.x,upper.end.x,fraction),upper.position.x+95+width/2,upper.end.x-95-width/2)
			var lower := Rect2()
			var floor_y := INF
			for surface in surfaces:
				if surface.position.y < upper.end.y+215 or surface.position.y > upper.end.y+480: continue
				if surface.position.x > x-width/2-20 or surface.end.x < x+width/2+20: continue
				if surface.position.y < floor_y: lower = surface; floor_y = surface.position.y
			if not lower.has_area(): continue
			var depth := minf(300,floor_y-upper.end.y-HEADROOM-8)
			if depth < 55: continue
			var family := Placement.family(id)
			var variant := plans.size()%3
			if floor_y-upper.end.y-depth > 175: continue
			var volume := Rect2(x-width/2,upper.end.y+0.25,width,depth+9)
			if not Placement.clear(volume,solids,upper) or not Placement.clear(volume.grow(15),reserved): continue
			var near := false
			for previous in plans:
				if previous.volume.grow(90).intersects(volume): near = true; break
			if near: continue
			var plan := {"at":Vector2(x-width/2,upper.end.y-5),"width":width,"depth":depth,"upper":upper,"lower":lower,"volume":volume,"family":family,"variant":variant}
			plans.append(plan)
			_build_vault(plan)

func refresh(nodes: Array[Node]) -> void:
	# Retire unsupported/conflicting additions, never grow new solids under a
	# visiting player. Original terrain is left untouched, including on re-entry.
	var external: Array[Node] = []
	for node in nodes:
		if not is_ancestor_of(node): external.append(node)
	var solids := Support.solids(external)
	var floors := Support.floors(external)
	for vault in vaults:
		if not vault.visible: continue
		var plan: Dictionary = vault.get_meta("vault_plan")
		if plan.upper in solids and plan.lower in floors and Placement.clear(plan.volume,solids,plan.upper): continue
		vault.hide(); vault.get_node("VaultCollision").set_deferred("disabled",true)
		vault.set_meta("hanging_anchors",[])

func _build_vault(plan: Dictionary) -> void:
	var body := StaticBody2D.new(); body.name = "LowVault%02d"%vaults.size()
	add_child(body); body.global_transform = Transform2D(0,plan.at)
	var w: float = plan.width
	var h: float = plan.depth
	var sheet := "route_%s_ceiling_v1"%plan.family
	var profile := PackedVector2Array([Vector2.ZERO,Vector2(w,0),Vector2(w,h-31),Vector2(w-30,h-14),Vector2(w*0.65,h-8),Vector2(w*0.3,h-10),Vector2(30,h-20),Vector2(0,h-35)])
	var collision := CollisionPolygon2D.new(); collision.name = "VaultCollision"; collision.polygon = profile; body.add_child(collision)
	body.set_meta("route_vault",true)
	body.set_meta("vault_plan",plan)
	body.set_meta("hanging_anchors",[body.to_global(Vector2(w*0.36,h-26))])
	var face := Polygon2D.new(); face.name = "VaultCore"; face.z_index = -3
	face.polygon = _rock_outline(w,h,plan.variant)
	# A ceiling is solid earth, not a transparent curtain of hanging sprites.
	# Keep the opaque fill INSIDE this vault: the slab above can also be a
	# walkable upper tier, so an unbounded upward rectangle would hide a route.
	var mass := Polygon2D.new(); mass.name = "TunnelMass"; mass.z_index = -4
	mass.polygon = face.polygon; mass.color = Color("050a0d")
	mass.set_meta("terrain_mass_kind","TunnelCeiling")
	body.add_child(mass)
	body.add_child(face)
	# Invert the same geological strata used below the floors. The textured
	# underside recedes into black bedrock instead of repeating masonry tiles.
	face.texture = preload("res://art/visual_slice/terrain_foundations_v1.png")
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	face.color = Color(0.67,0.73,0.73)
	var blend := ShaderMaterial.new(); blend.shader = preload("res://art/visual_slice/route_vault_blend.gdshader")
	blend.set_shader_parameter("edge_points",PackedVector2Array([Vector2(0,h-39),Vector2(32,h-23),Vector2(w*0.3,h-13),Vector2(w*0.65,h-11),Vector2(w-33,h-17),Vector2(w,h-35)]))
	var family_index: int = {"cave":0,"mine":0,"ash":1,"star":2}[plan.family]
	blend.set_shader_parameter("source_band",Vector2(family_index*341+2,family_index*341+339)/1024.0)
	blend.set_shader_parameter("texture_offset",float(plan.variant)*0.27)
	blend.set_shader_parameter("mass_width",w)
	face.material = blend
	# A broad buried core closes the overhead mass; overlapping transparent
	# scallops break its lower outline. Nothing is stretched into a thin tooth.
	var piece_width := minf(195,h*1.2)
	var pieces := maxi(3,ceili(w/(piece_width*0.72)))
	for index in pieces:
		var tip := Sprite2D.new(); tip.name = "Scallop%02d"%index; tip.z_index = -2
		tip.texture = Atlas.texture(sheet,(index+plan.variant)%3)
		tip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tip.centered = false
		var ratio := minf(piece_width/tip.texture.get_width(),(h-8)/tip.texture.get_height())
		tip.scale = Vector2.ONE*ratio
		var dimensions := tip.texture.get_size()*ratio
		var t := float(index)/(pieces-1)
		tip.position = Vector2(lerpf(0,w-dimensions.x,t),h-dimensions.y-absf(t-0.5)*28)
		tip.modulate = Color(0.64,0.72,0.72,1)
		# Bury the upper edge of each cutout in the same dark mass while leaving
		# roots/crystals and the detailed lower silhouette legible.
		var rim := ShaderMaterial.new(); rim.shader = preload("res://art/visual_slice/route_vault_rim.gdshader")
		rim.set_shader_parameter("piece_height",float(tip.texture.get_height()))
		tip.material = rim
		body.add_child(tip)
	body.set_meta("visual_bounds",Rect2(plan.at,Vector2(w,h)))
	vaults.append(body)

static func _rock_outline(w: float, h: float, variant: int) -> PackedVector2Array:
	# Inset chipped edges remove the straight hanging black columns. Every
	# point remains inside the unchanged solid/collision and landing margins.
	var outline := PackedVector2Array([Vector2.ZERO,Vector2(w,0)])
	var sides := maxi(2,ceili((h-50)/22))
	for index in range(1,sides+1):
		outline.append(Vector2(w-5-float((index*7+variant*3)%11),(h-50)*index/sides))
	var edge := PackedVector2Array([Vector2(0,h-39),Vector2(32,h-23),Vector2(w*.3,h-13),Vector2(w*.65,h-11),Vector2(w-33,h-17),Vector2(w,h-35)])
	var segments := maxi(8,ceili(w/19))
	for index in range(segments+1):
		var x := lerpf(w-16,16,float(index)/segments)
		var y := h-40
		for segment in range(edge.size()-1):
			if x>=edge[segment].x and x<=edge[segment+1].x:
				y = lerpf(edge[segment].y,edge[segment+1].y,inverse_lerp(edge[segment].x,edge[segment+1].x,x)); break
		outline.append(Vector2(x,y-3-float((index*7+variant*5)%8)))
	for index in range(sides,0,-1):
		outline.append(Vector2(5+float((index*9+variant*5)%11),(h-50)*index/sides))
	return outline
