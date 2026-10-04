extends Node2D
## Length-spaced, planted clusters and ceiling undersides. All non-solid.
## No per-object processing, particle emitters, lights, or save changes.
const Atlas := preload("res://CorridorAtlas.gd")
const Support := preload("res://WorldSupport.gd")
var clusters: Array[Sprite2D] = []
var canopies: Array[Sprite2D] = []
var footprints: Array[Rect2] = []
var crag_caps: Array[Sprite2D] = []
var terrain_signature: Array[Rect2] = []

static func install(room: Node2D, id: String, nodes: Array[Node]) -> Node2D:
	if room.has_node("CorridorDressing"):
		var old := room.get_node("CorridorDressing")
		old.refresh_terrain(id,nodes)
		old.refresh_devices(nodes)
		return old
	var art := new()
	art.name="CorridorDressing"
	room.add_child(art)
	art._build(id,nodes)
	return art

func _reserved(nodes: Array[Node]) -> Array[Rect2]:
	var result: Array[Rect2]=[]
	for n in nodes:
		if n is Node2D and (n.has_node("FinishedDevice") or n.is_in_group("breakable") or n.is_in_group("enemy") or n.is_in_group("town_resident") or n.is_in_group("town_service") or n is Marker2D):
			result.append(Rect2(n.global_position-Vector2(44,65),Vector2(88,92)))
			var device := n.get_node_or_null("FinishedDevice") as Sprite2D
			if device != null and device.texture != null: result.append((device.global_transform*device.get_rect()).grow(4))
			var gantry := n.get_node_or_null("LiftGantry")
			if gantry != null:
				var volume: Rect2 = gantry.get_meta("clearance_plan",{}).get("volume",Rect2())
				if volume.has_area(): result.append(volume.grow(4))
		if n is Node2D and n.has_meta("natural_mound_bounds"): result.append(n.get_meta("natural_mound_bounds"))
		if n is CollisionShape2D and n.get_parent() is Area2D and n.shape is RectangleShape2D:
			var path: String=n.get_parent().get_script().resource_path if n.get_parent().get_script()!=null else ""
			if "Hazard" in path or "Spike" in path or "Vent" in path:
				result.append((n.global_transform*Rect2(-n.shape.size*0.5,n.shape.size)).grow(24))
	return result

func _clear(bounds: Rect2, reserved: Array[Rect2]) -> bool:
	for rect in reserved:
		if rect.intersects(bounds): return false
	return true

func _place(prop: Sprite2D, at: Vector2) -> void:
	# Widths are world-space targets, like the support rectangles. Compensate
	# scaled/translated room roots instead of silently enlarging the artwork.
	prop.global_transform = Transform2D(0,Vector2.ONE*prop.scale.x,0,at)

func _build(id: String, nodes: Array[Node]) -> void:
	set_process(false)
	var family := "ash" if id.begins_with("ash_") else ("star" if id.begins_with("starfall_") else "cave")
	var floors := Support.floors(nodes)
	var solids := Support.solids(nodes)
	terrain_signature = solids.duplicate()
	var reserved := _reserved(nodes)
	var seed_value := absi(id.hash()%997)
	for pass_index in 36:
		for floor_rect in floors:
			if clusters.size()>=120: break
			if floor_rect.size.x<200 or floor_rect.size.y>55: continue
			var count := maxi(1,int(floor_rect.size.x/126))
			if pass_index>=count: continue
			var fraction := (pass_index+0.45+fposmod(seed_value*0.011+pass_index*0.38,0.2))/count
			var at := Vector2(lerpf(floor_rect.position.x+30,floor_rect.end.x-30,fraction),floor_rect.position.y+0.6)
			var width: float=[36.0,48.0,42.0,32.0,52.0][(pass_index+seed_value)%5]
			var prop := Atlas.sprite("corridor_%s_clusters_v1"%family,(clusters.size()+seed_value)%6,width)
			prop.name="GroundCluster%03d"%clusters.size()
			prop.z_index=-1
			add_child(prop)
			_place(prop,at)
			Support.plant(prop,float(prop.get_meta("contact_row")),at.y)
			var footprint: Rect2 = prop.global_transform * prop.get_rect()
			var exposed := footprint
			exposed.size.y = maxf(0,floor_rect.position.y-0.25-exposed.position.y)
			# A registered root can enter its own floor very slightly. Everything
			# above that contact must clear ALL solids, including vertical walls.
			if footprint.position.x < floor_rect.position.x+0.5 or footprint.end.x > floor_rect.end.x-0.5 or not _clear(exposed,solids) or not _clear(footprint,reserved) or not _clear(footprint.grow(8),footprints):
				prop.free(); continue
			prop.flip_h=(clusters.size()%3==1)
			prop.modulate=Color(0.75,0.85,0.83) if family=="cave" else Color(0.82,0.81,0.8)
			prop.set_meta("ground_contact",at)
			prop.set_meta("footprint",footprint)
			prop.set_meta("supported_floor",floor_rect)
			footprints.append(footprint)
			clusters.append(prop)
	# Hang low, irregular rock lips UNDER real upper terrain. Do not cover
	# either end of a jumping platform or fake a traversable floating slab.
	for upper in floors:
		if id in ["echo_haven","ash_hearth","starfall_citadel"]: break # Built galleries use architectural corbels, not cavern lips.
		if canopies.size()>=40: break
		if upper.size.x<300: continue
		for section in range(1,maxi(2,int(upper.size.x/185))):
			if canopies.size()>=40: break
			var x:=lerpf(upper.position.x+65,upper.end.x-65,float(section)/maxi(2,int(upper.size.x/185)))
			var lower:=Support.below(Vector2(x,upper.end.y+50),floors,370)
			if not lower.has_area() or lower.position.y-upper.end.y<175: continue
			var width:=124.0+float((section+seed_value)%3)*18
			var prop:=Atlas.sprite("corridor_%s_overhangs_v1"%family,section%2,width)
			prop.name="CeilingLip%02d"%canopies.size()
			prop.z_index=-2
			add_child(prop)
			_place(prop,Vector2(x,upper.end.y+prop.texture.get_height()*prop.scale.y*0.5-8))
			var bounds: Rect2 = prop.global_transform * prop.get_rect()
			var clear := bounds.position.x >= upper.position.x+1 and bounds.end.x <= upper.end.x-1 and lower.position.y-bounds.end.y >= 95 and _clear(bounds.grow(15),reserved)
			for solid in solids:
				if solid != upper and bounds.grow(-0.2).intersects(solid): clear = false; break
			if not clear: prop.free(); continue
			prop.modulate=Color(0.61,0.69,0.71)
			prop.set_meta("ceiling_support",upper)
			prop.set_meta("clearance_floor",lower)
			prop.set_meta("footprint",bounds)
			canopies.append(prop)
	# Terminate narrow interior crags with a real irregular underside, not an
	# atlas rectangle. Both sides of these pillars remain see-through.
	for n in nodes:
		if not n is CollisionShape2D or n.disabled or n.one_way_collision or not n.shape is RectangleShape2D or not n.get_parent() is StaticBody2D: continue
		var body := n.get_parent()
		if body.is_in_group("breakable") or body.is_in_group("enemy") or body.has_meta("portal_boundary") or n.has_meta("boundary_envelope_superseded") or not is_zero_approx(n.global_rotation): continue
		if n.shape.size.y<120 or n.shape.size.x>90: continue
		var r: Rect2=n.global_transform*Rect2(-n.shape.size*0.5,n.shape.size)
		var envelope:=get_parent().get_node_or_null("TerrainEnvelope")
		if envelope!=null and envelope.boundaries.has(envelope.global_transform.affine_inverse()*r): continue
		var prop:=Atlas.sprite("corridor_%s_overhangs_v1"%family,2+canopies.size()%2,maxf(30,r.size.x*1.35))
		prop.name="CragUnderside%02d"%crag_caps.size()
		prop.z_index=-3
		add_child(prop)
		_place(prop,Vector2(r.get_center().x,r.end.y-4))
		var bounds: Rect2 = prop.global_transform * prop.get_rect()
		var clear := _clear(bounds.grow(4),reserved)
		for solid in solids:
			if solid != r and bounds.grow(-0.2).intersects(solid): clear = false; break
		if not clear: prop.free(); continue
		prop.modulate=Color(0.65,0.73,0.74)
		prop.set_meta("pillar_support",r)
		prop.set_meta("footprint",bounds)
		crag_caps.append(prop)

func refresh_terrain(id: String, nodes: Array[Node]) -> void:
	# Re-evaluate only on room/device refresh, never every frame. A new/moved
	# ceiling must not leave the first installation's stale decoration behind.
	if terrain_signature == Support.solids(nodes): return
	for prop in clusters + canopies + crag_caps:
		if is_instance_valid(prop): prop.free()
	clusters.clear(); canopies.clear(); crag_caps.clear(); footprints.clear()
	_build(id,nodes)

func refresh_devices(nodes: Array[Node]) -> void:
	var reserved:=_reserved(nodes)
	for prop in clusters + canopies + crag_caps:
		prop.visible=_clear(prop.get_meta("footprint"),reserved)
