extends "res://tests/boss_combat_presentation_smoke.gd"
const Response := preload("res://FoliageResponse.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_reactive_foliage_smoke.json"; state.start_new_game("normal")
	var stage := Node2D.new(); root.add_child(stage); stage.position = Vector2(90,-80)
	var manager := preload("res://WorldAmbience.gd").new(); stage.add_child(manager)
	manager.set_physics_process(false); manager.set_process(false)
	_check(manager.brush_motes.global_transform.is_equal_approx(Transform2D.IDENTITY),"Room origin offsets contact particles twice")
	var plants: Array[Node] = []
	for family in ["cave","mine","ash","star"]:
		for hanging in [false,true]:
			var plant := preload("res://RouteDetail.gd").new(); stage.add_child(plant)
			plant.configure(family,"hanging" if hanging else "floor",3 if hanging else 5,45,24,Vector2(100,100),Rect2(0,100,300,20),not hanging)
			plants.append(plant)
		var rear := preload("res://RouteDetail.gd").new(); stage.add_child(rear)
		rear.configure(family,"floor",5,46,26,Vector2(100,100),Rect2(0,100,300,20),false)
		plants.append(rear)
	for family in ["cave","ash","star"]:
		var plant := preload("res://ForegroundGrowth.gd").new(); stage.add_child(plant)
		plant.configure(family,0,Vector2(100,100),14,Rect2(0,100,300,20)); plants.append(plant)
	for biome in 3:
		for variant in [1,4]:
			var plant := preload("res://AmbientSetpiece.gd").new(); stage.add_child(plant)
			plant.configure(biome,variant,Vector2(100,100),30,Rect2(0,100,300,20),"floor" if variant==1 else "ceiling")
			plants.append(plant)
	for plant in plants:
		_check(plant.has_meta("player_reactive"),"Soft prop missing contact response")
		_check(not plant.is_processing() and not plant.is_physics_processing(),"Plant runs an individual callback")
		var root_at: Vector2 = plant.global_position
		for direction in [-1.0,1.0]:
			plant.reset_response(); plant.rest()
			for tick in 12: plant.brush(direction*.25); plant.advance_response(1.0/60)
			_check(plant.response.bend*direction>.08,"Wrong/imperceptible brushing direction")
			_check(root_at.is_equal_approx(plant.global_position),"Root detaches while brushing")
			plant.animate(1.3); plant.rest()
			_check(absf(plant.response.bend)>.08,"Wind selection erased contact response")
			for tick in 200: plant.advance_response(1.0/60)
			_check(plant.response.bend==0 and plant.response.speed==0,"Spring never settles")
	_check(Response.crosses(Rect2(0,90,20,10),Vector2(-45,90),Vector2(65,90)),"Dash tunnels past plant")
	_check(not Response.crosses(Rect2(0,10,20,10),Vector2(-45,90),Vector2(65,90)),"Separate floor reacts")
	_check(not Response.crosses(Rect2(0,90,20,10),Vector2(300,90),Vector2(320,90)),"Distant plant reacts")
	# Dense fixture exceeds both budgets, so limiting/cleanup is exercised.
	for index in 30:
		var plant := preload("res://RouteDetail.gd").new(); stage.add_child(plant)
		plant.configure("cave","floor",5,45,14,Vector2(100+index%3,100),Rect2(0,100,300,20),true); plants.append(plant)
	manager.register_room("fixture",plants)
	manager.sample_brushing(Vector2(45,92),Vector2(140,92),Vector2(540,0),1.0/60)
	_check(manager.brushing.size()==12,"Desktop brush budget not enforced")
	_check(manager.brush_motes.motes.size()<=36,"Contact particle cap exceeded")
	manager.set_low_quality(true)
	_check(manager.brushing.size()==6,"Low-cost brush budget not enforced")
	manager.sample_brushing(Vector2(100,92),Vector2(800,92),Vector2(42000,0),1.0/60)
	_check(manager.brushing.is_empty() and manager.brush_motes.motes.is_empty(),"Teleport sweeps entire room")
	manager.sample_brushing(Vector2(90,92),Vector2(100,92),Vector2(165,0),1.0/60)
	for tick in 220: manager.sample_brushing(Vector2(100,92),Vector2(100,92),Vector2.ZERO,1.0/60)
	_check(manager.brushing.is_empty(),"Idle player perpetually bends grass")
	manager.sample_brushing(Vector2(90,92),Vector2(100,92),Vector2(165,0),1.0/60)
	manager.register_room("empty",[])
	_check(manager.brushing.is_empty() and manager.brush_bins.is_empty(),"Room change retains contacts")
	for plant in plants: _check(plant.response.bend==0,"Hidden room keeps a bent prop")
	stage.free(); state.delete_save()
	print("REACTIVE FOLIAGE TEST PASSED: 21 soft families/types including rear understory, direction, settling, swept contact, 12/6 budgets" if failures.is_empty() else "REACTIVE FOLIAGE TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
