extends "res://tests/boss_combat_presentation_smoke.gd"

func _plant(stage: Node2D, at: Vector2, hanging := false) -> Node2D:
	var prop := preload("res://RouteDetail.gd").new()
	stage.add_child(prop)
	prop.configure("cave","hanging" if hanging else "floor",3 if hanging else 5,32,25,at,Rect2(at-Vector2(50,0),Vector2(100,12)),not hanging)
	return prop

func _lamp(stage: Node2D, at: Vector2) -> Node2D:
	var lamp := load("res://Checkpoint.tscn").instantiate() as Node2D
	stage.add_child(lamp); lamp.position = at; lamp.set_process(false)
	var body := Sprite2D.new(); body.name = "FinishedDevice"; lamp.add_child(body)
	preload("res://CheckpointLampArt.gd").attach(lamp,body,"training_passage")
	return lamp

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ambient_contact_priority.json"
	state.start_new_game("normal")
	var stage := Node2D.new(); root.add_child(stage)
	var manager := preload("res://WorldAmbience.gd").new(); stage.add_child(manager)
	manager.set_process(false); manager.set_physics_process(false)
	var roots := _plant(stage,Vector2(10,0),true)
	manager.register_room("fixture",[roots])
	manager.sample_brushing(Vector2(8,35),Vector2(8,9),Vector2(0,-260),1.0/60)
	_check(roots in manager.brushing and roots.response.speed>0,"Upward head contact leaves hanging roots inert")
	for tick in 8: manager.sample_brushing(Vector2(8,9),Vector2(8,7),Vector2(0,-120),1.0/60)
	_check(roots.response.bend>.08,"Upward contact has no visible bend")
	manager.clear_brushing()
	var grass := _plant(stage,Vector2(10,100))
	manager.register_room("fixture",[grass])
	manager.sample_brushing(Vector2(8,92),Vector2(8,86),Vector2(0,-260),1.0/60)
	_check(manager.brushing.is_empty(),"Vertical takeoff sprays grounded grass")
	manager.sample_brushing(Vector2(8,86),Vector2(8,92),Vector2(0,260),1.0/60)
	_check(grass in manager.brushing,"Landing stopped responding")
	manager.clear_brushing()
	var nodes: Array[Node] = []
	var old_clump: Array[Node2D] = []
	for index in 12:
		var prop := _plant(stage,Vector2(index%3,200))
		nodes.append(prop); old_clump.append(prop)
	var incoming := _plant(stage,Vector2(122,200)); nodes.append(incoming)
	for low in [false,true]:
		manager.set_low_quality(low); manager.register_room("fixture",nodes)
		manager.sample_brushing(Vector2(-15,194),Vector2(2,194),Vector2(165,0),1.0/60)
		_check(manager.brushing.size()==manager.brush_budget(),"Dense clump does not fill expected brush budget")
		for tick in 8: manager.sample_brushing(Vector2(1,194),Vector2(2,194),Vector2(80,0),1.0/60)
		var prior := manager.brushing.duplicate()
		manager.sample_brushing(Vector2(106,194),Vector2(122,194),Vector2(165,0),1.0/60)
		_check(incoming in manager.brushing and incoming.response.speed>0,"Old settling clump blocks a newly touched plant")
		_check(manager.brushing.size()==manager.brush_budget(),"New contact increases the spring budget")
		var retired := 0
		for prop in prior:
			if not prop in manager.brushing:
				retired += 1
				_check(prop.response.bend==0 and prop.response.speed==0,"Retired plant freezes in a bent pose")
		_check(retired==1,"A single new contact should replace exactly one old spring")
		for tick in 220: manager.sample_brushing(Vector2(122,194),Vector2(122,194),Vector2.ZERO,1.0/60)
		_check(manager.brushing.is_empty(),"Prioritized contacts never settle")
	# More simultaneous contacts than slots must prefer the closest current
	# ones even when farther current contacts already occupy the whole pool.
	manager.set_low_quality(true)
	var cluster: Array[Node] = []
	for index in 10: cluster.append(_plant(stage,Vector2(index*3,300)))
	manager.register_room("fixture",cluster)
	manager.sample_brushing(Vector2(-4,294),Vector2(0,294),Vector2(165,0),1.0/60)
	manager.sample_brushing(Vector2(0,294),Vector2(27,294),Vector2(165,0),1.0/60)
	_check(manager.brushing.size()==6 and cluster[9] in manager.brushing and not cluster[0] in manager.brushing,"Closest current contacts lose to older farther contacts")
	manager.clear_brushing()
	var attachment := Node2D.new(); stage.add_child(attachment)
	var seep := preload("res://CanopySeep.gd").new(); stage.add_child(seep)
	seep.configure(Vector2(0,-160),Rect2(-100,130,200,12),attachment,"cave")
	manager.register_room("fixture",[seep])
	var view := Rect2(-40,0,80,100)
	_check(not view.grow(100).has_point(seep.global_position),"Seep fixture origin must be outside culling margin")
	manager.select_visible(view)
	_check(seep in manager.active,"Visible falling water culled because its ceiling source is offscreen")
	_check(manager._animation_distance_squared(seep,view.get_center())==0,"Visible drop bounds lose priority to distant source anchor")
	seep.animate(1.0)
	manager.select_visible(Rect2(400,400,50,50))
	_check(manager.active.is_empty() and seep.cycle==-1,"Fully offscreen seep was not retired")
	# Real checkpoint state must not wait for camera scheduling. Setting the
	# gameplay properties also covers loading, save, rest and boss reveal paths.
	var lamp := _lamp(stage,Vector2(120,400))
	var motion: Node2D = lamp.get_node("FinishedDevice/LivingFlame")
	_check(not motion.flame.visible,"Undiscovered lamp is already burning")
	lamp.activate_from_travel()
	_check(motion.flame.visible and motion.body.self_modulate==Color.WHITE,"Culled lamp does not immediately reflect activation")
	motion.animate(.28)
	var frame: int = motion.current_frame
	var flame_scale: Vector2 = motion.flame.scale
	lamp.is_resting = true
	_check(motion.flame.scale.is_equal_approx(flame_scale*1.12) and motion.current_frame==frame,"Rest state changes reset flame pose / miss warm-up scale")
	lamp.is_resting = false
	_check(motion.flame.scale.is_equal_approx(flame_scale) and motion.current_frame==frame,"Rest ending leaves a stale large flame")
	lamp.is_active = false
	_check(not motion.flame.visible and motion.body.self_modulate!=Color.WHITE,"Inactive culled lamp keeps old lit state")
	lamp.is_resting = true
	_check(motion.flame.visible,"Rest at a new lamp does not light until next animation tick")
	lamp.is_resting = false; lamp.is_active = true
	lamp.reveal_after_boss_id = "ambient_priority_guardian"
	lamp._refresh_reveal_state()
	_check(not motion.flame.visible and not lamp.is_revealed,"Boss-locked lamp keeps a visible flame")
	state.mark_boss_defeated("ambient_priority_guardian")
	_check(lamp.is_revealed and motion.flame.visible,"Boss reveal leaves saved active lamp dark")
	_check(not motion.is_processing(),"Lamp state fix adds a private frame callback")
	var mixed: Array[Node] = []
	for index in 24: mixed.append(_plant(stage,Vector2(-30+index*2.5,400)))
	var lamps: Array[Node2D] = [motion]
	for index in 2:
		var extra := _lamp(stage,Vector2(135+index*15,400))
		extra.is_active = true; lamps.append(extra.get_node("FinishedDevice/LivingFlame"))
	var machines: Array[Node2D] = []
	for index in 3:
		var site := Node2D.new(); stage.add_child(site); site.position = Vector2(-120-index*15,400)
		machines.append(preload("res://FieldMachineryArt.gd").attach(site,"flywheel"))
	mixed.append_array(lamps); mixed.append_array(machines)
	var mixed_view := Rect2(-200,340,400,120)
	for low in [false,true]:
		manager.set_low_quality(low); manager.register_room("fixture",mixed)
		manager.select_visible(mixed_view)
		var lamp_count := 0; var machine_count := 0; var foliage_count := 0
		for prop in manager.active:
			if prop in lamps: lamp_count += 1
			elif prop in machines: machine_count += 1
			else: foliage_count += 1
		var quota := 1 if low else 2
		_check(manager.active.size()==manager.animation_budget(),"Category reservations increase the combined 18/8 budget")
		_check(lamp_count==quota and machine_count==quota and foliage_count>0,"Dense foliage starves flame / machinery, or reservations starve foliage")
		motion.animate(.28); frame = motion.current_frame
		var alpha: float = motion.flame.modulate.a
		for refresh in 4: manager.select_visible(mixed_view)
		_check(motion.current_frame==frame and motion.flame.modulate.a==alpha,"Mixed camera refresh resets a retained real flame")
		manager.select_visible(Rect2(5000,5000,20,20))
		_check(motion.current_frame==frame,"Retiring a lamp resets its painted pose")
		print("AMBIENT MIXED BUDGET low=",low," foliage=",foliage_count," lamps=",lamp_count," rotors=",machine_count)
	stage.free(); state.delete_save()
	print("AMBIENT CONTACT PRIORITY TEST PASSED: upward roots, nearest 12/6 contacts, long seep visibility, real lamp state, mixed 18/8 budgets" if failures.is_empty() else "AMBIENT CONTACT PRIORITY TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
