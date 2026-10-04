extends Node2D
## Small regional moth groups live only over existing safe soft vegetation.
## Planning runs on room registration, never on a frame callback.
const Placement := preload("res://RouteDressingPlacement.gd")
const Support := preload("res://WorldSupport.gd")
const Detail := preload("res://RouteDetail.gd")
const Roost := preload("res://AmbientMothRoost.gd")
const LIMIT := 6
var roosts: Array[Node2D]=[]

static func install(room: Node2D,id: String,nodes: Array[Node]) -> Node2D:
	var layer := room.get_node_or_null("AmbientFauna")
	if layer==null:
		layer=new(); layer.name="AmbientFauna"; room.add_child(layer)
		layer.set_process(false); layer.set_physics_process(false)
	layer.refresh(id,nodes); return layer

func refresh(id: String,nodes: Array[Node]) -> void:
	var solids := Support.solids(nodes)
	var reserved := Placement.reservations(nodes)
	var floors := Placement.floors(nodes)
	var habitats: Array[Node2D]=[]
	# Keep arenas and enemy silhouettes readable, even though moths are harmless.
	for node in nodes:
		if node is Node2D and node.is_in_group("boss"):
			reserved.append(Rect2(node.global_position-Vector2(650,300),Vector2(1300,600)))
		elif node is Node2D and node.is_in_group("enemy"):
			reserved.append(Rect2(node.global_position-Vector2(45,65),Vector2(90,95)))
		if node is Detail and node.kind=="floor" and node.variant==5 and node.is_visible_in_tree() and node.support.size.x>=240:
			habitats.append(node)
	# Deterministic spatial order distributes the small cap across room tiers.
	habitats.sort_custom(func(a: Node2D,b: Node2D): return _rank(a,id)<_rank(b,id))
	var kept: Array[Node2D]=[]
	for source in habitats:
		if kept.size()>=LIMIT: break
		if source.support not in floors: continue
		var center: Vector2=source.global_position-Vector2(0,45)
		var volume := Rect2(center+Roost.ENVELOPE.position,Roost.ENVELOPE.size)
		if volume.position.x<source.support.position.x+8 or volume.end.x>source.support.end.x-8: continue
		if not Placement.clear(volume,solids) or not Placement.clear(volume,reserved): continue
		var clear := true
		for prior in kept:
			if center.distance_to(prior.global_position)<380: clear=false; break
		if not clear: continue
		var existing: Node2D
		for prior in roosts:
			if prior.habitat==source and prior.global_position.is_equal_approx(center) and prior.support==source.support:
				existing=prior; break
		if existing==null:
			existing=Roost.new(); add_child(existing)
			existing.configure(Placement.family(id),source,center,source.support)
		kept.append(existing)
	for prior in roosts:
		if prior in kept: continue
		prior.reset_response(); prior.rest(); prior.hide()
		remove_child(prior); prior.queue_free()
	roosts=kept

func _rank(source: Node2D,id: String) -> int:
	return absi((id+":"+str(source.global_position)).hash())
