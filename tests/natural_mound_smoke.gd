extends "res://tests/pickup_motion_smoke.gd"

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_natural_mound.json"
	state.start_new_game("normal")
	player=_player()
	player.get_node("Camera2D").enabled=false
	var floor_body:=_surface(Vector2(0,310),Vector2(900,20))
	for family in ["cave","ash","star"]:
		for variant in 3:
			var mound:=preload("res://NaturalMound.gd").new()
			root.add_child(mound)
			mound.configure(family,variant,Vector2(0,300))
			for i in range(1,mound.surface.size()):
				_check(absf((mound.surface[i].y-mound.surface[i-1].y)/(mound.surface[i].x-mound.surface[i-1].x))<=0.551,"Unwalkable cliff in shallow mound")
			for side in [-1.0,1.0]:
				player.set_physics_process(true)
				player.global_position=Vector2(-105*side,278)
				player.velocity=Vector2.ZERO
				for tick in 8: await physics_frame
				var start:=player.global_position
				var highest:=start.y
				Input.action_press("ui_right" if side>0 else "ui_left")
				for tick in 100:
					await physics_frame
					highest=minf(highest,player.position.y)
				Input.action_release("ui_right");Input.action_release("ui_left")
				_check((player.position.x-start.x)*side>210,"Player stuck on %s mound %d side %d"%[family,variant,int(side)])
				_check(highest<start.y-8,"Player did not climb painted mound")
				player.set_physics_process(false)
			mound.queue_free()
			await physics_frame
	floor_body.free();player.free()
	state.delete_save()
	print("NATURAL MOUND TEST PASSED" if failures.is_empty() else "NATURAL MOUND TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
