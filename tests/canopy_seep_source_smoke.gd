extends "res://tests/boss_combat_presentation_smoke.gd"
const Atlas := preload("res://RouteDressingAtlas.gd")
const Detail := preload("res://RouteDetail.gd")
const Seep := preload("res://CanopySeep.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_canopy_seep_source.json"; state.start_new_game("normal")
	var stage := Node2D.new(); root.add_child(stage)
	stage.position = Vector2(1400,-650); stage.scale = Vector2(1.4,.9)
	var checked := 0
	for family in ["cave","mine","ash","star"]:
		var sheet := "route_%s_ceiling_v1"%family
		var entry: Dictionary = Atlas.DATA[sheet]
		var image := Image.new()
		_check(image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/visual_slice/"+sheet+".png"))==OK,"Missing source PNG: "+family)
		for index in [3,4]:
			var tip: Vector2 = Atlas.DRIP_TIPS[family][index-3]
			var box: Array = entry.boxes[index]
			_check(image.get_pixel(box[0]+int(tip.x),box[1]+int(tip.y)).a>=.65,"Drip starts on transparent source pixel: "+family)
			var root_art := Detail.new(); stage.add_child(root_art)
			root_art.configure(family,"hanging",index,42,45,Vector2(1450,-500),Rect2(1400,-520,400,20))
			var at: Vector2 = root_art.drip_anchor()
			var expected: Vector2 = root_art.art.to_global(root_art.art.get_rect().position+Atlas.drip_tip(family,index))
			_check(at.is_equal_approx(expected),"Root tip ignores cropped sprite pivot/scaled room")
			var floor_rect := Rect2(at.x-80,at.y+160,160,16)
			var seep := Seep.new(); stage.add_child(seep); seep.configure(at,floor_rect,root_art,family)
			_check(seep.global_scale.is_equal_approx(Vector2.ONE),"Room scale distorts drops")
			_check(not seep.is_processing() and not seep.is_physics_processing(),"Seep starts private processing")
			for bend in [-.42,0.0,.42]:
				root_art.response.bend = bend; root_art.wind = .023; root_art._apply_flex()
				var tip_at: Vector2 = root_art.drip_anchor()
				_check(seep.footprint.has_point(tip_at),"Reserved corridor excludes extreme root swing")
				seep.rest()
				seep.animate(6.8-seep.phase)
				_check(seep.global_position.is_equal_approx(tip_at),"Drop fails to snapshot bent tip on release")
				_check(is_equal_approx(seep.global_position.y+seep.fall_distance,floor_rect.position.y),"Bent drop misses its real floor")
				var release := seep.global_position
				root_art.response.bend = -bend; root_art._apply_flex()
				seep.animate(7.2-seep.phase)
				_check(seep.global_position.is_equal_approx(release),"Wind drags an already airborne drop sideways")
				_check(seep.drop_height()>0 and seep.drop_height()<seep.fall_distance,"Airborne drop outside traced corridor")
				seep.animate(7.61-seep.phase)
				_check(is_equal_approx(seep.drop_height(),seep.fall_distance),"Splash fails to reach floor")
				seep.animate(10.2-seep.phase)
				_check(seep.global_position.is_equal_approx(root_art.drip_anchor()),"Next release uses stale emitter position")
			root_art.hide(); seep.animate(11)
			_check(seep.cycle==-1 and seep.emission_serial==-1,"Hidden source continues releasing drops")
			root_art.show(); seep.animate(12); root_art.free(); seep.animate(12.1)
			_check(seep.cycle==-1,"Freed root leaves an orphan drip")
			seep.free(); checked += 1
	stage.free(); state.delete_save()
	print("CANOPY SEEP SOURCE TEST PASSED: %d alpha tips, scaled roots, swept margins, emission snapshots and lifecycle" % checked if failures.is_empty() else "CANOPY SEEP SOURCE TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
