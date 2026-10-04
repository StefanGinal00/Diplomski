extends Node2D
## Low, non-solid foreground growth on real surveyed terrain. No particles,
## lights, per-plant processors, save writes, or imitation gameplay platforms.
const Growth := preload("res://ForegroundGrowth.gd")
const MAX_GROWTH := 180
var plants: Array[Node2D] = []

static func install(room: Node2D, id: String, nodes: Array[Node]) -> Node2D:
	if room.has_node("ForegroundGrowth"):
		var existing := room.get_node("ForegroundGrowth")
		existing.refresh_devices(nodes)
		return existing
	var dressing := new()
	dressing.name="ForegroundGrowth"
	room.add_child(dressing)
	dressing._build(id,nodes)
	return dressing

func _reserved(nodes: Array[Node]) -> Array[Rect2]:
	var reserves: Array[Rect2]=[]
	for node in nodes:
		if not is_instance_valid(node): continue
		if node is CollisionShape2D and not node.disabled and node.shape is RectangleShape2D and node.get_parent() is Area2D:
			var body := node.get_parent()
			var path: String = body.get_script().resource_path if body.get_script()!=null else ""
			if "Hazard" in path or "Spike" in path:
				reserves.append((node.global_transform*Rect2(-node.shape.size*0.5,node.shape.size)).grow(15))
		if node is Node2D and (node.has_node("FinishedDevice") or node.is_in_group("breakable") or node.is_in_group("town_resident") or node.is_in_group("town_service") or node.is_in_group("item_pickup")):
			reserves.append(Rect2(node.global_position-Vector2(30,44),Vector2(60,62)))
		if node is Node2D and node.has_meta("natural_mound_bounds"):
			reserves.append(node.get_meta("natural_mound_bounds"))
	return reserves

func _build(id: String,nodes: Array[Node]) -> void:
	set_process(false)
	var family := "ash" if id.begins_with("ash_") else ("star" if id.begins_with("starfall_") else "cave")
	var floors := preload("res://WorldSupport.gd").floors(nodes)
	var reserved := _reserved(nodes)
	var seed_value := int(id.hash()%997)
	# Length-based density: a 2,000-unit hall needs more growth than a ledge.
	# Round-robin still distributes it over vertical rooms, with no per-plant ticks.
	for pass_index in 48:
		for floor_rect in floors:
			if plants.size()>=MAX_GROWTH: return
			if floor_rect.size.x<110 or floor_rect.size.y>55: continue
			var count := maxi(1,int(floor_rect.size.x/76.0))
			if pass_index>=count: continue
			var fraction := (pass_index+0.35+fposmod(seed_value*0.0017+pass_index*0.37,0.3))/float(count)
			var at := Vector2(lerpf(floor_rect.position.x+20,floor_rect.end.x-20,fraction),floor_rect.position.y+0.5)
			var height: float = [10.0,12.0,14.0][plants.size()%3]
			var bounds := Rect2(at-Vector2(18,height+1),Vector2(36,height+1))
			var clear := true
			for obstacle in reserved:
				if bounds.intersects(obstacle): clear=false;break
			if not clear: continue
			for other_floor in floors:
				if other_floor!=floor_rect and bounds.grow(-1).intersects(other_floor): clear=false;break
			if not clear: continue
			for plant in plants:
				if at.distance_to(plant.global_position)<42: clear=false;break
			if not clear: continue
			var plant := Growth.new()
			plant.name="Tuft%02d"%plants.size()
			add_child(plant)
			plant.configure(family,(plants.size()+seed_value)%3,at,height,floor_rect)
			plants.append(plant)

func refresh_devices(nodes: Array[Node]) -> void:
	var reserved := _reserved(nodes)
	for plant in plants:
		var clear:=true
		for obstacle in reserved:
			if plant.footprint.intersects(obstacle): clear=false;break
		plant.visible=clear
		if not clear: plant.rest()
