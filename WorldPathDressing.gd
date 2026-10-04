extends Node2D
## Dense coherent ground bands, attached ceiling details, and walk-through foreground.
## Rectangular and polygonal solids, hazards and interaction artwork stay readable.
const Placement := preload("res://RouteDressingPlacement.gd")
const Support := preload("res://WorldSupport.gd")
const Detail := preload("res://RouteDetail.gd")
const MAX_FLOOR := 600
const MAX_HANGING := 150
var details: Array[Node2D] = []
var terrain_signature: Array[Rect2] = []
var room_id := ""
var understory: Array[Node2D] = []
var seeps: Array[Node2D] = []

static func install(room: Node2D, id: String, nodes: Array[Node]) -> Node2D:
	var prior := room.get_node_or_null("PathDressing")
	if prior != null:
		prior.refresh(nodes)
		return prior
	var layer := new(); layer.name = "PathDressing"; room.add_child(layer)
	layer.room_id = id; layer.set_process(false); layer._build(nodes)
	return layer

func refresh(nodes: Array[Node]) -> void:
	if Support.solids(nodes) != terrain_signature:
		for detail in details: detail.free()
		for seep in seeps: seep.free()
		seeps.clear()
		details.clear(); understory.clear(); _build(nodes)
	var reserved := Placement.reservations(nodes)
	for detail in details:
		detail.visible = Placement.clear(detail.footprint,reserved)
		if not detail.visible: detail.rest()
	for seep in seeps:
		seep.visible = is_instance_valid(seep.source) and seep.source.visible and Placement.clear(seep.footprint,reserved)
		if not seep.visible: seep.rest()

func _build(nodes: Array[Node]) -> void:
	terrain_signature = Support.solids(nodes)
	var floors := Placement.floors(nodes)
	var reserved := Placement.reservations(nodes)
	var palette := Placement.family(room_id)
	var settled := room_id in ["echo_haven","echo_haven_outskirts","ash_hearth","ash_hearth_outskirts","starfall_citadel"]
	var seed_value := absi(room_id.hash())%997
	var created := 0
	# Round-robin placement prevents the budget being consumed by one long floor.
	for step in 150:
		for floor_rect in floors:
			if created >= MAX_FLOOR: break
			var seed_index := absi(int(floor_rect.position.x*0.03+floor_rect.position.y*0.07)+step*7+seed_value)
			var x := floor_rect.position.x+40+step*74+(seed_index%17)
			if x > floor_rect.end.x-36: continue
			var index := seed_index%6
			var front := step%3 == 1
			if front: index = 5
			var width := 75.0+float(seed_index%31)
			var cap := 15.0 if front else (22.0 if settled else 30.0)
			var prop := _detail(palette,"floor",index,width,cap,Vector2(x,floor_rect.position.y+0.65),floor_rect,front)
			var tested: Rect2 = prop.footprint
			tested.size.y = maxf(0,floor_rect.position.y-0.25-tested.position.y)
			if prop.footprint.position.x < floor_rect.position.x+3 or prop.footprint.end.x > floor_rect.end.x-3 or not Placement.clear(tested,terrain_signature) or not Placement.clear(prop.footprint,reserved):
				prop.free(); continue
			details.append(prop); created += 1
	_add_understory(palette,settled,reserved)
	var hanging_count := 0
	var existing_canopies: Array[Rect2] = []
	for node in nodes:
		if node is Sprite2D and node.name.begins_with("CeilingLip") and node.texture != null:
			existing_canopies.append((node.global_transform*node.get_rect()).grow(12))
	for step in 35:
		for upper in floors:
			if hanging_count >= MAX_HANGING: break
			if upper.size.x < 190: continue
			var seed_index := absi(int(upper.position.x*0.03+upper.position.y*0.05)+step*5+seed_value)
			var x := upper.position.x+64+step*142+seed_index%25
			if x > upper.end.x-58: continue
			var index := 3+seed_index%3
			if settled and index == 5: index = 3
			var height := 29.0+seed_index%23
			var prop := _detail(palette,"hanging",index,42,height,Vector2(x,upper.end.y-2),upper)
			var bounds: Rect2 = prop.footprint
			var safe := Placement.clear(bounds,terrain_signature,upper) and Placement.clear(bounds.grow(5),reserved)
			for lower in floors:
				if lower == upper or lower.position.y <= upper.end.y: continue
				if bounds.end.x > lower.position.x and bounds.position.x < lower.end.x and lower.position.y-bounds.end.y < 105: safe = false
			if not safe: prop.free(); continue
			details.append(prop); hanging_count += 1
	# Broad attached trim fills the negative space above routes where a real
	# rock vault would block a ledge. These are soft background decorations.
	for step in 20:
		for upper in floors:
			if settled: continue
			if upper.size.x < 280: continue
			var seed_index := absi(int(upper.position.x*0.031+upper.position.y*0.071)+step*11+seed_value)
			var x := upper.position.x+100+step*260+seed_index%29
			if x > upper.end.x-95: continue
			var prop := _detail(palette,"canopy",seed_index%3,122+seed_index%35,90,Vector2(x,upper.end.y-4),upper)
			var bounds: Rect2 = prop.footprint
			var safe := Placement.clear(bounds,terrain_signature,upper) and Placement.clear(bounds.grow(7),reserved) and Placement.clear(bounds,existing_canopies)
			for lower in floors:
				if lower == upper or lower.position.y <= upper.end.y: continue
				if bounds.end.x > lower.position.x and bounds.position.x < lower.end.x and lower.position.y-bounds.end.y < 140: safe = false
			if not safe: prop.free(); continue
			details.append(prop); existing_canopies.append(bounds.grow(12))
	# New collidable pockets carry their own cap; add only short free-hanging tips.
	for node in nodes:
		if not node is StaticBody2D or not node.has_meta("route_vault") or not node.visible: continue
		var plan: Dictionary = node.get_meta("vault_plan")
		for at in node.get_meta("hanging_anchors",[]):
			var prop := _detail(palette,"hanging",3+details.size()%3,22,32,at,plan.upper)
			if not Placement.clear(prop.footprint,reserved): prop.free(); continue
			prop.set_meta("vault_detail",true)
			details.append(prop)
	_add_seeps(palette,floors,reserved)

func _add_seeps(palette: String, floors: Array[Rect2], reserved: Array[Rect2]) -> void:
	if palette=="ash": return # Do not suggest water in dry furnace halls.
	var occupied: Array[Vector2] = []
	for detail in details:
		if seeps.size()>=12: return
		if detail.kind!="hanging" or detail.variant not in [3,4]: continue
		var at := Vector2(detail.footprint.get_center().x,detail.footprint.end.y)
		var floor_rect := Support.below(at+Vector2(0,2),floors,310)
		if not floor_rect.has_area() or floor_rect.position.y-at.y<45: continue
		var volume := Rect2(at-Vector2(4,0),Vector2(8,floor_rect.position.y-at.y-.25))
		if not Placement.clear(volume,terrain_signature) or not Placement.clear(volume.grow(5),reserved): continue
		var clear := true
		for prior in occupied:
			if at.distance_to(prior)<190: clear = false; break
		if not clear: continue
		var seep := preload("res://CanopySeep.gd").new(); seep.name = "RootSeep%02d"%seeps.size(); add_child(seep)
		seep.configure(at,floor_rect,detail,palette); seeps.append(seep); occupied.append(at)

func _add_understory(palette: String, settled: bool, reserved: Array[Rect2]) -> void:
	# Small uneven plant companions to rock/log groups, not another continuous
	# carpet. Rear fronds rise behind boots; low front leaves remain see-through
	# to movement and never hide traps, clues, loot or a landing edge.
	var bases := details.duplicate()
	var occupied: Array[Rect2] = []
	for base in bases:
		if base.kind != "floor" or base.variant == 5: continue
		var seed_value := posmod(int(base.global_position.x*.19+base.global_position.y*.11),997)
		if seed_value%3 != 0: continue
		for side in [-1,1]:
			if understory.size()>=120: return
			var front: bool = side>0
			var height := 12.0+float(seed_value%3) if front else (18.0 if settled else 23.0+float(seed_value%4))
			var at := Vector2(base.global_position.x+side*(29.0+seed_value%9),base.support.position.y+.65)
			var prop := _detail(palette,"floor",5,38+seed_value%13,height,at,base.support,front)
			var probe: Rect2 = prop.footprint
			probe.size.y = maxf(0,base.support.position.y-.25-probe.position.y)
			if prop.footprint.position.x<base.support.position.x+10 or prop.footprint.end.x>base.support.end.x-10 or not Placement.clear(probe,terrain_signature) or not Placement.clear(prop.footprint,reserved) or not Placement.clear(prop.footprint.grow(5),occupied):
				prop.free(); continue
			prop.art.flip_h = (seed_value+side)%2==0
			prop.art.modulate = Color(.68,.78,.73) if front else Color(.72,.82,.8)
			prop.set_meta("route_understory",true)
			details.append(prop); understory.append(prop); occupied.append(prop.footprint)

func _detail(palette: String, kind: String, index: int, width: float, height: float, at: Vector2, floor_rect: Rect2, front := false) -> Node2D:
	var prop := Detail.new(); prop.name = "Route%s%03d"%[kind,details.size()]
	add_child(prop); prop.configure(palette,kind,index,width,height,at,floor_rect,front)
	return prop
