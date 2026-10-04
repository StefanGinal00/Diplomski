extends "res://tests/boss_combat_presentation_smoke.gd"
const Atlas:=preload("res://LivingSpriteAtlas.gd")
func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_living_actor_cycles.json"
	state.start_new_game("normal")
	var room:=Node2D.new()
	root.add_child(room)
	room.process_mode=Node.PROCESS_MODE_DISABLED
	var sample:=Sprite2D.new()
	room.add_child(sample)
	var bytes:=0
	var count:=0
	for id in Atlas.DATA:
		var frames:=Atlas.frames_for(id)
		var source: Image=frames[0].atlas.get_image()
		bytes+=source.get_data_size()
		_check(source.get_pixel(0,0).a<0.01 and source.has_mipmaps() and source.get_width()<=1024,"Alpha/mipmap/budget: "+id)
		for facing in [-1.0,1.0]:
			for frame in frames.size():
				Atlas.show(sample,id,frame,40,16,facing,float(Atlas.DATA[id].boxes[0][3]),"root")
				var foot:=sample.to_global(Vector2(0,-sample.texture.get_height()*0.5+float(sample.get_meta("contact_row"))))
				_check(absf(foot.y-16)<0.001 and sample.flip_h==(facing<0),"Registered foot/facing: "+id)
				_check(sample.scale.x==sample.scale.y,"Nonuniform body: "+id)
				if Atlas.DATA[id].has("spans"):
					_check(sample.material.get_shader_parameter("spans").size()==64,"Missing alpha ownership mask")
				count+=1
	_check(bytes<80*1024*1024,"New atlases exceed 80 MiB decoded ceiling")
	for actor_case in [["Enemy","enemy"],["AshFiend","fiend"],["RootStalker","root"],["ShaftSentry","sentry"],["AshSentry","sentry"]]:
		var actor: Node2D=load("res://%s.tscn"%actor_case[0]).instantiate()
		room.add_child(actor)
		var art: Sprite2D=actor.get_node("PaintedMobAppearance")
		var col: CollisionShape2D=actor.get_node("CollisionShape2D")
		var original:=col.transform
		art.contact()
		_check(art.get_meta("atlas_frame")==4,"Actual contact misses impact: "+actor_case[0])
		for elapsed in [0.03,0.09,0.15,0.21]:
			art.release_remaining=0.24-elapsed
			art._apply_pose(4 if elapsed<0.12 else 5)
			_check(art.get_meta("atlas_frame")==4+int(elapsed/0.06),"Follow-through clock drift")
		if actor_case[1]=="root":
			actor.phase="warning"
			for phase in 3:
				actor.phase_remaining=0.7*(1.0-(phase+0.1)/3.0)
				art.release_remaining=0
				art._apply_pose(3)
				_check(art.get_meta("atlas_frame")==phase+1,"Root preparation lost native progress")
		if actor_case[1]=="sentry":
			_check(art.material.get_shader_parameter("heated")==bool(art.heated),"Ash palette lost")
		else:
			art._apply_pose(1)
			_check(art.material==null,"Walk retained wrong mask")
		_check(col.transform==original,"Paint moved native collider")
		actor.free()
	for data in CASES:
		var boss: CharacterBody2D=load("res://%s.tscn"%data[0]).instantiate()
		room.add_child(boss)
		var art:=boss.get_node("PaintedAppearance")
		art.presentation=null
		var cycle: Sprite2D=art.painted_cycle
		_check(Atlas.DATA.has(cycle.attack_id) and Atlas.DATA.has(cycle.motion_id),"Incomplete boss animation libraries: "+data[0])
		var col: CollisionShape2D=boss.get_node("CollisionShape2D")
		var original:=col.transform
		art.pose_index=0
		art.frame_sequence.release_age=10
		for key in ["charge_remaining","recovery_remaining","windup_remaining","charge_windup","volley_windup","pulse_windup","eruption_windup"]:
			if art.property_names.has(key): boss.set(key,0)
		art._update_living_paint()
		_check(art.rendered_sprite()==cycle and cycle.previous_library==cycle.motion_id,"Idle uses obsolete boss silhouette")
		_check(art.material.get_shader_parameter("hide_paint"),"Old boss body paints over new")
		art.pose_index=1
		var seen: Dictionary={}
		for step in 6:
			art.stride_distance=step*7+0.1
			art.frame_sequence.hover_clock=(step+0.1)/8.0
			cycle.sample(art)
			seen[cycle.previous_frame]=true
		_check(seen.size()==6,"Boss lacks six locomotion in-betweens")
		art.begin_release()
		_check(cycle.previous_library==cycle.attack_id and cycle.previous_frame==4,"Release and damage tick disagree")
		art.frame_sequence.release_age=0.17
		cycle.sample(art)
		_check(cycle.previous_frame==6,"Recovery frame missing")
		var echo:=preload("res://BossDefeatEcho.gd").spawn(art,Color.WHITE)
		_check(echo!=null and echo.texture==cycle.texture and echo.global_transform.is_equal_approx(cycle.global_transform),"Defeat snapshots obsolete body")
		if echo!=null:
			_check(echo.material.get_shader_parameter("use_living_mask"),"Defeat loses frame isolation")
			echo.free()
		_check(col.transform==original,"Boss art changed collision")
		boss.hide()
		_check(not cycle.visible,"Hidden room retains painted body")
		boss.free()
	print("LIVING ACTORS COVERAGE: ",Atlas.DATA.size()," libraries, ",count," registered samples, ",bytes," decoded bytes")
	room.queue_free()
	await process_frame
	state.delete_save()
	print("LIVING ACTORS TEST PASSED" if failures.is_empty() else "TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
