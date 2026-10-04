extends Node2D
## Physical relief only on broad quiet ground. Native jump routes stay intact.
const Support := preload("res://WorldSupport.gd")
const Placement := preload("res://RouteDressingPlacement.gd")
const Relief := preload("res://WalkableRouteRelief.gd")
const LIMIT := 10
var patches: Array[StaticBody2D] = []

static func install(room: Node2D, id: String, nodes: Array[Node]) -> Node2D:
	if room.has_node("RouteRelief"):
		var existing := room.get_node("RouteRelief")
		existing.refresh(nodes); return existing
	var layer := new(); layer.name = "RouteRelief"; room.add_child(layer)
	layer._build(id,nodes); return layer

func _build(id: String,nodes: Array[Node]) -> void:
	set_process(false); set_physics_process(false)
	# Town architecture, tightly authored arenas and timed jumping platforms
	# keep their authored support planes. Natural districts get broader relief.
	if id in ["echo_haven","ash_hearth","starfall_citadel","ash_arena","ash_throne","echo_nest","starfall_empty_court","starfall_hollow_throne"]: return
	var reserved := Placement.reservations(nodes)
	var solids := Support.solids(nodes)
	var floors: Array[CollisionShape2D] = []
	for node in nodes:
		if node is Node2D and node.is_in_group("boss"):
			reserved.append(Rect2(node.global_position-Vector2(650,300),Vector2(1300,600)))
		if node is Node2D and (node is Marker2D or node.is_in_group("enemy")):
			reserved.append(Rect2(node.global_position-Vector2(72,90),Vector2(144,130)))
		# Crates/loose items settle and receive their native spawn-clearance
		# correction on activation. Preserve a landing apron for that movement.
		if node is Node2D and (node.is_in_group("breakable") or node.is_in_group("item_pickup")):
			reserved.append(Rect2(node.global_position-Vector2(100,80),Vector2(200,130)))
		if not node is CollisionShape2D or node.disabled or node.one_way_collision or not node.shape is RectangleShape2D or not is_zero_approx(node.global_rotation): continue
		var body := node.get_parent()
		if not body is StaticBody2D or body.is_in_group("enemy") or body.is_in_group("breakable"): continue
		var floor_rect: Rect2 = node.global_transform*Rect2(-node.shape.size/2,node.shape.size)
		if floor_rect.size.x<540 or floor_rect.size.y>60 or floor_rect.size.y<8: continue
		var named := String(body.name).to_lower()
		var eligible := true
		for token in ["platform","ledge","bridge","shelf","rung","step","ceiling","roof","arena","gantry","wood","timber","catwalk"]:
			if token in named: eligible = false; break
		if eligible: floors.append(node)
	# Round-robin across floors, not just the first long base of a vertical room.
	for pass_index in 5:
		for native in floors:
			if patches.size()>=LIMIT: return
			var floor_rect: Rect2 = native.global_transform*Rect2(-native.shape.size/2,native.shape.size)
			var selection := posmod(id.hash()+pass_index+int(floor_rect.position.y/40),6)
			var width: float = [280.0,340.0,310.0,360.0,320.0,300.0][selection]
			var rise: float = [22.0,26.0,30.0,24.0,28.0,26.0][selection]
			var x := floor_rect.position.x+115+pass_index*390
			while x+width<floor_rect.end.x-110:
				var space := Rect2(x-15,floor_rect.position.y-rise-125,width+30,rise+124)
				var contact := Rect2(x-18,floor_rect.position.y-rise-30,width+36,rise+48)
				if Placement.clear(space,solids,floor_rect) and Placement.clear(contact,reserved):
					var patch := Relief.new(); patch.name = "WalkingContour%d"%patches.size(); add_child(patch)
					var material := "basalt" if id.begins_with("ash_") else ("citadel" if id.begins_with("starfall_") else ("shale" if Placement.family(id)=="mine" else "moss"))
					var edge := native.get_parent().get_node_or_null("TerrainEdgeArt")
					if edge!=null: material = edge.family
					# Raised ground in the old city is accumulated rock/soil, not
					# ornamental masonry bent like rubber into a mountain.
					if material in ["citadel","street","haven","hearth"]: material = "shale"
					patch.configure({"floor":floor_rect,"at":Vector2(x,floor_rect.position.y),"width":width,"rise":rise,"variant":selection,"family":Placement.family(id),"material":material,"clearance":space},native)
					patches.append(patch); reserved.append(contact.grow(45)); break
				x += 90

func refresh(nodes: Array[Node]) -> void:
	# Late walls/devices or removed supports retire a contour safely; restoring
	# a native floor is not a reason to regenerate geometry under the player.
	var external: Array[Node] = []
	for node in nodes:
		if not is_ancestor_of(node) and not node.has_meta("natural_mound_bounds"): external.append(node)
	var solids := Support.solids(external)
	var reservations := Placement.reservations(external)
	for patch in patches:
		if not patch.visible: continue
		var valid: bool = is_instance_valid(patch.native) and not patch.native.disabled and not patch.native.one_way_collision and patch.native.shape is RectangleShape2D
		if valid:
			var current: Rect2 = patch.native.global_transform*Rect2(-patch.native.shape.size/2,patch.native.shape.size)
			valid = current.is_equal_approx(patch.support) and Placement.clear(patch.plan.clearance,solids,patch.support)
		if valid: valid = Placement.clear(patch.get_meta("natural_mound_bounds"),reservations)
		if not valid:
			patch.hide(); patch.get_node("ReliefCollision").set_deferred("disabled",true)
			patch.remove_meta("natural_mound_bounds")
