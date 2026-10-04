extends "res://tests/gameplay_review_smoke.gd"
const Walk := preload("res://WalkCycleAtlas.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_walk_cycle.json"
	state.start_new_game("normal")
	var holder := Node2D.new()
	root.add_child(holder)
	var art := Sprite2D.new()
	holder.add_child(art)
	var bytes := 0
	for identity in Walk.DATA:
		var frames := Walk.frames_for(identity)
		_check(frames.size()==8 and frames==Walk.frames_for(identity),"Eight shared frames missing: "+identity)
		var sheet: Texture2D = frames[0].atlas
		var image := sheet.get_image()
		bytes += image.get_data_size()
		_check(image.has_mipmaps() and image.get_width()<=1024 and image.get_pixel(0,0).a<0.01,"Walk import/alpha: "+identity)
		for direction in [-1.0,1.0]:
			for pose in 8:
				Walk.show(art,identity,pose,31,14,direction)
				var contact := art.to_global(Vector2(0,-art.texture.get_height()*0.5+float(art.get_meta("contact_row"))))
				_check(absf(contact.y-14)<0.001 and art.flip_h==(direction<0),"Foot or facing drifts: "+identity)
				_check(art.scale.x==art.scale.y and art.texture is AtlasTexture,"Walk stretched or bypasses atlas")
	_check(bytes<36*1024*1024,"Walk sheets exceed decoded budget")
	var resident: Node2D = load("res://TownResident.tscn").instantiate()
	root.add_child(resident)
	resident.set_process(false)
	await process_frame
	var motion := resident.get_node("ResidentMotion")
	motion.set_process(false)
	var seen := {}
	for step in 32:
		resident.position.x += 1
		motion._process(1.0/30)
		motion._update_paint()
		seen[motion.painted.pose] = true
	_check(seen.size()>=8,"Walk does not expose eight poses")
	var phase: float = motion.phase
	for step in 30: motion._process(1.0/30)
	_check(motion.phase==phase and motion.painted.pose==0,"Idle continues walking")
	resident.position.x += 200
	motion._process(0.1)
	_check(motion.phase==0 and motion.painted.pose==0,"Teleport advances feet")
	motion.painted.show_walk(4,-1,14)
	motion.painted.show_pose(3,1,14,0)
	_check(motion.painted.pose==3 and motion.painted.texture is AtlasTexture and motion.painted.material!=null,"Talk did not restore articulated gesture")
	_check(absf(motion.painted.position.y+(-motion.painted.texture.get_height()*0.5+motion.painted.contact_row)*motion.painted.scale.y-14)<0.001,"Talk boot drifted")
	motion.painted.show_walk(4,-1,14)
	_check(motion.painted.material==null and motion.painted.flip_h,"Walk retained gesture mask or wrong facing")
	print("WALK CYCLE COVERAGE: ",Walk.DATA.size()," identities, ",bytes," decoded bytes")
	resident.queue_free()
	holder.queue_free()
	await process_frame
	state.delete_save()
	print("WALK CYCLE TEST PASSED" if failures.is_empty() else "WALK CYCLE TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
