extends "res://tests/visual_style_slice_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_city_parallax_runtime.json"
	state.start_new_game("normal")
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 3: await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player := game.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.offset = Vector2.ZERO
	var finish := game.get_node("WorldPresentationFinish")
	var background: TextureRect = finish.background
	var ambience: Node = finish.ambience
	var worst_motion_error := 0.0
	for visit in 2:
		state.set_current_room("starfall_citadel")
		for frame in 3: await process_frame
		finish.finish_room("starfall_citadel")
		var city := game.get_node("StarfallCitadel")
		var art := city.get_node("ParallaxArchitecture")
		_check(art.built and art.is_visible_in_tree(),"City architecture missing on entry/revisit")
		_check(ambience.parallax_architecture==art,"Room ambience missed parallax quality owner")
		_check(background.city_horizon and background.material.get_shader_parameter("city_horizon"),"City horizon mode not activated")
		_check(not city.get_node("Sky").visible,"Original room sky covers the camera horizon")
		_check(city.get_node("RemainingArt").plates.size()==1,"Extra opaque city painting")
		var native := _physics_snapshot(city)
		for quality in [false,true]:
			ambience.set_low_quality(quality)
			_check(art.low_quality==quality,"Shared low-cost setting did not reach city")
			for target in [Vector2(800,350),Vector2(2500,-600),Vector2(5700,-1900)]:
				player.global_position = city.to_global(target)
				camera.force_update_scroll()
				background._process(0)
				art._process(0)
				var inverse := root.canvas_transform.affine_inverse()
				var center := inverse*(Vector2(root.size)*0.5)
				_check(art.camera_local.is_equal_approx(city.to_local(center)),"Real camera transform not applied to architecture")
				var world_tile: Vector2 = background.texture.get_size()*0.5
				_check(background.camera_uv.is_equal_approx((center-city.global_position)*Vector2(0.08,0.035)/world_tile),"Far horizon has incorrect speed/origin")
				_check(background.get_rect().encloses(Rect2(Vector2.ZERO,Vector2(root.size))),"Horizon fails to cover viewport")
				_check(art.entries.size()<= (16 if quality else 24),"Runtime building budget exceeded")
				var old_uv: Vector2 = background.camera_uv
				var old_center: Vector2 = center
				var old_buildings: Array[Dictionary] = []
				for layer in 2: old_buildings.append(art.building(layer,4,art.camera_local))
				player.global_position += Vector2(80,-60)
				camera.force_update_scroll()
				background._process(0)
				art._process(0)
				center = root.canvas_transform.affine_inverse()*(Vector2(root.size)*0.5)
				var travel: Vector2 = center-old_center
				_check(travel.length()>1,"Camera remained stationary in motion test")
				_check((background.camera_uv-old_uv).is_equal_approx(travel*Vector2(0.08,0.035)/world_tile),"Horizon does not move continuously with real camera")
				for layer in 2:
					var after: Dictionary = art.building(layer,4,art.camera_local)
					var screen_delta: Vector2 = after.rect.position-old_buildings[layer].rect.position-travel
					var error := screen_delta.distance_to(-travel*art.LAYERS[layer].scroll)
					worst_motion_error = maxf(worst_motion_error,error)
					# Subtracting distant world positions incurs float32 rounding;
					# 0.02 world units is <0.05 screen pixels at native 2.5x zoom.
					_check(error<0.02,"Architecture plane moves at wrong camera speed: "+str(error))
		_check(_physics_snapshot(city)==native,"Camera/quality changes alter gameplay collision")
		var count: int = art.retired.size()
		finish.finish_room("starfall_citadel")
		_check(art.retired.size()==count and art.get_child_count()==0,"Room finish duplicates skyline")
		state.set_current_room("training_passage")
		for frame in 3: await process_frame
		finish.finish_room("training_passage")
		_check(not art.is_visible_in_tree() and not art.is_processing(),"Previous city's scenery stays active")
		_check(ambience.parallax_architecture==null,"Cave retains city quality owner")
		_check(not background.city_horizon and not background.material.get_shader_parameter("city_horizon"),"City horizon mode leaked into caves")
	print("CITY PARALLAX RUNTIME: two visits, real Camera2D travel, three depths, both quality modes; physics unchanged")
	print("CITY PARALLAX MAX MOTION ERROR ",worst_motion_error," world units")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("CITY PARALLAX RUNTIME TEST PASSED" if failures.is_empty() else "CITY PARALLAX RUNTIME TEST FAILED")
	quit(0 if failures.is_empty() else 1)
