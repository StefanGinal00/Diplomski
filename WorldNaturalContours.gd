extends Node2D
## Sparse shallow slopes on broad quiet floors, never on jump platforms,
## bridges, moving machinery, spawn landings, hazards, or boss arenas.
const Mound:=preload("res://NaturalMound.gd")
const Atlas:=preload("res://LivingSpriteAtlas.gd")
var mounds: Array[StaticBody2D]=[]
var edge_details: Array[Sprite2D]=[]

static func install(room: Node2D,id: String,nodes: Array[Node]) -> Node2D:
	if room.has_node("NaturalContours"): return room.get_node("NaturalContours")
	var contours:=new()
	contours.name="NaturalContours"
	room.add_child(contours)
	contours._build(room,id,nodes)
	return contours

func _build(room: Node2D,id: String,nodes: Array[Node]) -> void:
	set_process(false)
	var family: String="ash" if id.begins_with("ash_") else ("star" if id.begins_with("starfall_") else "cave")
	var solids: Array[Rect2]=[]
	var floors: Array[Rect2]=[]
	var reserved: Array[Rect2]=[]
	var arena:=false
	for node in nodes:
		if not is_instance_valid(node): continue
		if node is Node2D:
			if node.has_meta("task_scenery") and node.has_method("painted_bounds"): reserved.append(node.painted_bounds().grow(8))
			if node.has_meta("natural_mound_bounds"): reserved.append(node.get_meta("natural_mound_bounds"))
			if node.is_in_group("boss"): arena=true
			if node is Marker2D or node.has_node("FinishedDevice") or node.is_in_group("enemy") or node.is_in_group("town_resident") or node.is_in_group("town_service") or node.is_in_group("friendly_npc") or node.is_in_group("breakable") or node.is_in_group("item_pickup"):
				reserved.append(Rect2(node.global_position-Vector2(110,95),Vector2(220,145)))
			if node.has_meta("ambient_attachment") or node.has_meta("ambient_motion"):
				reserved.append(Rect2(node.global_position-Vector2(45,45),Vector2(90,65)))
		if not node is CollisionShape2D or node.disabled or not node.shape is RectangleShape2D or not is_zero_approx(node.global_rotation): continue
		var rect: Rect2=node.global_transform*Rect2(-node.shape.size*0.5,node.shape.size)
		var body:=node.get_parent()
		if body is Area2D:
			var path: String=body.get_script().resource_path if body.get_script()!=null else ""
			if "Hazard" in path or "Spike" in path or (rect.size.x<180 and rect.size.y<140): reserved.append(rect.grow(32))
		if not body is StaticBody2D or body.is_in_group("enemy") or body.is_in_group("breakable"): continue
		solids.append(rect)
		if node.one_way_collision or rect.size.x<480 or rect.size.y>60: continue
		var named:=String(body.name).to_lower()
		var eligible:=true
		for token in ["platform","ledge","bridge","shelf","rung","step","ceiling","roof","arena"]:
			if token in named: eligible=false;break
		if eligible: floors.append(rect)
	if not arena:
		for floor_rect in floors:
			if mounds.size()>=2: break
			for fraction in [0.38,0.64,0.2,0.8,0.5]:
				var at:=Vector2(lerpf(floor_rect.position.x+130,floor_rect.end.x-130,fraction),floor_rect.position.y)
				var space:=Rect2(at-Vector2(98,76),Vector2(196,80))
				var clear:=true
				for obstacle in reserved:
					if space.intersects(obstacle): clear=false;break
				if not clear: continue
				for solid in solids:
					if solid!=floor_rect and space.intersects(solid): clear=false;break
				if not clear: continue
				var mound:=Mound.new()
				mound.name="ShallowRubble%d"%mounds.size()
				add_child(mound)
				mound.configure(family,(mounds.size()+int(id.hash()%3))%3,at)
				mounds.append(mound)
				reserved.append(space.grow(80))
				break
	# Fresh modular overhangs and diagonals vary the filled earth silhouette.
	# They sit entirely below the lowest base floor; upper paths stay open.
	var envelope:=room.get_node_or_null("TerrainEnvelope")
	if envelope==null: return
	for foundation in envelope.foundations:
		if foundation.size.x<180: continue
		for side in [-1,1]:
			if edge_details.size()>=8: return
			var art:=Sprite2D.new()
			art.name="BuriedRockShoulder"
			art.z_index=-4
			add_child(art)
			var variant:=4 if side<0 else 5
			Atlas.show(art,"terrain_segments_%s_v1"%family,variant,95)
			var anchor: Vector2=room.to_global(Vector2(foundation.position.x+54 if side<0 else foundation.end.x-54,foundation.position.y+95))
			art.global_position+=anchor-global_position
			art.set_meta("contact_floor",anchor.y)
			art.modulate=Color(0.48,0.55,0.57)
			edge_details.append(art)
