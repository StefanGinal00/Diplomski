extends "res://tests/gameplay_review_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_finished_props.json"
	state.start_new_game("normal")
	var template: Node = load("res://Game.tscn").instantiate()
	var player: Player = template.get_node("Player")
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.set_physics_process(false)
	for family in ["cave","ash","starfall"]:
		var cache: Node2D = load("res://ResonanceCache.tscn").instantiate()
		cache.cache_id = "repair_"+family
		root.add_child(cache)
		var art := cache.get_node("PaintedCache")
		var floors: Array[Rect2] = [Rect2(-100,34,200,12)]
		art.supply_surfaces(floors)
		for pose in 6:
			art.show_pose(pose)
			var foot: Vector2 = art.to_global(Vector2(0,-art.texture.get_height()*0.5+art.get_meta("contact_row")))
			_check(absf(foot.y-34)<0.01,"Cache foot moved with lid")
		art.show_pose(0)
		var gold: int = state.gold
		_check(cache.open(player),"Cache did not open")
		_check(art.is_processing() and art.pose==0,"Opening animation did not start")
		for step in 6: art._process(0.106)
		_check(art.pose==5 and not art.is_processing(),"Cache loop never stops")
		_check(not cache.open(player) and state.gold==gold+cache.gold_reward,"Animation duplicated reward")
		cache.free()
		cache = load("res://ResonanceCache.tscn").instantiate()
		cache.cache_id = "repair_"+family
		root.add_child(cache)
		_check(cache.opened and cache.get_node("PaintedCache").pose==5,"Restored chest closed again")
		cache.free()
	var lamp: Area2D = load("res://Checkpoint.tscn").instantiate()
	root.add_child(lamp)
	var body := preload("res://CavernDressingArt.gd").sprite(lamp,2,"FinishedDevice",Vector2(0,-8),Vector2(23,38))
	preload("res://CheckpointLampArt.gd").attach(lamp,body,"training_passage")
	var motion := body.get_node("LivingFlame")
	lamp.is_active=false
	motion.animate(0)
	_check(not motion.flame.visible,"Inactive lamp burns")
	lamp.is_active=true
	motion.animate(0)
	var texture: Texture2D = motion.flame.texture
	motion.animate(0.15)
	_check(motion.flame.visible and texture!=motion.flame.texture and not motion.is_processing(),"Lamp animation/budget missing")
	lamp.is_revealed=false
	motion.animate(0.3)
	_check(not motion.flame.visible,"Hidden boss lamp lit")
	lamp.free()
	player.queue_free()
	await process_frame
	state.delete_save()
	print("FINISHED PROPS TEST PASSED" if failures.is_empty() else "FINISHED PROPS TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
