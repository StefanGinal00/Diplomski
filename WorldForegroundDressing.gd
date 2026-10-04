extends Node2D
## Low, non-solid foreground growth on real surveyed terrain. No particles,
## lights, per-plant processors, save writes, or imitation gameplay platforms.
const Growth := preload("res://ForegroundGrowth.gd")
const Placement := preload("res://RouteDressingPlacement.gd")
const Support := preload("res://WorldSupport.gd")
const MAX_GROWTH := 180
var plants: Array[Node2D] = []
var terrain_signature: Array[Rect2] = []
var floor_signature: Array[Rect2] = []

static func install(room: Node2D, id: String, nodes: Array[Node]) -> Node2D:
	if room.has_node("ForegroundGrowth"):
		var existing := room.get_node("ForegroundGrowth")
		existing.refresh_terrain(id,nodes)
		existing.refresh_devices(nodes)
		return existing
	var dressing := new()
	dressing.name="ForegroundGrowth"
	room.add_child(dressing)
	dressing._build(id,nodes)
	return dressing

func _reserved(nodes: Array[Node]) -> Array[Rect2]:
	return Placement.reservations(nodes)

func _build(id: String,nodes: Array[Node]) -> void:
	set_process(false)
	var family := "ash" if id.begins_with("ash_") else ("star" if id.begins_with("starfall_") else "cave")
	# Authored roofs are not growable ground. Test all solid silhouettes,
	# including narrow walls and polygonal relief, not only horizontal floors.
	var floors := Placement.floors(nodes)
	var solids := Support.solids(nodes)
	terrain_signature = solids.duplicate(); floor_signature = floors.duplicate()
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
			var clear := true
			for plant in plants:
				if at.distance_to(plant.global_position)<42: clear=false;break
			if not clear: continue
			var plant := Growth.new()
			plant.name="Tuft%02d"%plants.size()
			add_child(plant)
			plant.configure(family,(plants.size()+seed_value)%3,at,height,floor_rect)
			var bounds: Rect2 = plant.placement_bounds()
			var exposed := bounds
			# Registered roots touch their own floor; all visible foliage above
			# the subpixel contact band must clear every solid, including walls.
			exposed.size.y = maxf(0,floor_rect.position.y-.25-exposed.position.y)
			if bounds.position.x<floor_rect.position.x+1 or bounds.end.x>floor_rect.end.x-1 or not Placement.clear(exposed,solids) or not Placement.clear(bounds,reserved):
				plant.free(); continue
			plants.append(plant)

func refresh_terrain(id: String,nodes: Array[Node]) -> void:
	if terrain_signature==Support.solids(nodes) and floor_signature==Placement.floors(nodes): return
	for plant in plants:
		plant.reset_response(); plant.rest(); plant.hide()
		# A finish pass may still hold these nodes in its member snapshot for
		# the subsequent corridor pass. Detach now, dispose at the safe boundary.
		remove_child(plant); plant.queue_free()
	plants.clear()
	_build(id,nodes)

func refresh_devices(nodes: Array[Node]) -> void:
	var reserved := _reserved(nodes)
	for plant in plants:
		var clear:=true
		for obstacle in reserved:
			if plant.placement_bounds().intersects(obstacle): clear=false;break
		plant.visible=clear
		if not clear:
			plant.reset_response(); plant.rest()
