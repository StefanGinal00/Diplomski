extends "res://tests/pickup_motion_smoke.gd"
const Dust := preload("res://GroundDustAtlas.gd")
const Fx := preload("res://GroundContactFx.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_ground_dust_animation.json"; state.start_new_game("normal")
	var stage := Node2D.new(); root.add_child(stage); stage.position=Vector2(750,-90); stage.scale=Vector2(1.6,.7)
	var fx := Fx.new(); stage.add_child(fx)
	_check(fx.global_transform.is_equal_approx(Transform2D.IDENTITY),"Dust world-space draw inherits room transform")
	_check(not fx.is_processing() and not fx.is_physics_processing(),"Dust adds private callbacks")
	var bytes := 0
	for family in Dust.BOXES:
		var frames := Dust.frames_for(family)
		_check(frames.size()==6 and frames==Dust.frames_for(family),"Dust frames are not shared")
		var pixels: Image=frames[0].atlas.get_image(); bytes+=pixels.get_data_size()
		_check(pixels.has_mipmaps() and pixels.get_width()<=512 and pixels.get_pixel(0,0).a<.01,"Dust texture import budget/alpha")
		for index in 6:
			var cell := Rect2(Vector2(index%3,index/3)*512,Vector2(512,512))
			_check(cell.encloses(Dust.BOXES[family][index]),"Dust crop leaks neighboring pose")
			for width in [14.0,30.4]:
				var rect := Dust.frame_rect(family,index,width)
				_check(is_zero_approx(rect.end.y) and rect.size.x<=width and rect.size.y<=width*.5,"Dust drifts under floor or grows too large")
		for normal in [Vector2.UP,Vector2(-.22,-1).normalized(),Vector2(.22,-1).normalized()]:
			fx.clear(); fx.emit_contact(Vector2(-500,-500),normal,family,160,1.3,true)
			_check(fx.puffs.size()==1,"Missing material dust puff")
			var puff: Dictionary=fx.puffs[0]
			var transform := Transform2D(puff.rotation,Vector2(puff.facing,1),0,puff.at)
			for index in 6:
				var rect := Dust.frame_rect(family,index,puff.width)
				for point in [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:
					_check(((transform*point)-Vector2(-500,-500)).dot(normal)>=0,"Rotated/flipped dust crosses its supporting plane")
			var anchor: Vector2=puff.at
			for tick in 20: fx.advance(1.0/60)
			_check(fx.puffs.size()==1 and fx.puffs[0].at==anchor,"Landing puff follows later player movement")
			fx.advance(.5); _check(fx.puffs.is_empty(),"Dust does not finish")
	_check(bytes<4*1024*1024,"Dust atlases exceed 4 MiB including mipmaps")
	# A neighboring wall constrains both facing directions equally.
	var wall := _surface(Vector2(12,250),Vector2(4,100))
	await physics_frame
	for speed in [-160,160]:
		fx.clear(); fx.emit_contact(Vector2(0,300),Vector2.UP,"shale",speed,1,true)
		_check(fx.puffs.size()==1 and fx.puffs[0].width<=18,"Puff grows through a wall")
		fx.clear(); fx.emit_contact(Vector2(9,300),Vector2.UP,"shale",speed,1,true)
		_check(fx.puffs.is_empty(),"No-clearance contact creates wall-clipping puff")
	wall.free(); await physics_frame
	# Dynamic actors in the query never hide the farther real wall.
	wall=_surface(Vector2(12,250),Vector2(4,100))
	var blocker := CharacterBody2D.new(); root.add_child(blocker); blocker.position=Vector2(5,290); blocker.collision_layer=1
	var shape := CollisionShape2D.new(); shape.shape=RectangleShape2D.new(); shape.shape.size=Vector2(2,40); blocker.add_child(shape)
	await physics_frame
	_check(fx._clear_puff_width(Vector2(0,300),Vector2.UP,28)<=18,"Actor masks farther wall from dust clearance")
	blocker.free(); wall.free(); await physics_frame
	var overhang := _surface(Vector2(16,292),Vector2(8,4))
	await physics_frame
	fx.clear(); fx.emit_contact(Vector2(0,300),Vector2.UP,"shale",100,1,true)
	_check(fx.puffs.size()==1 and fx.puffs[0].width<24,"Rising dust clips an overhang above its ankle ray")
	overhang.free(); await physics_frame
	for material in ["iron","timber"]:
		fx.clear(); fx.emit_contact(Vector2.ZERO,Vector2.UP,material,100,1,true)
		_check(fx.puffs.is_empty() and fx.grains.size()<=2,"Manufactured floor emits a large soil cloud")
	fx.clear()
	for index in 20: fx.emit_contact(Vector2.ZERO,Vector2.UP,"moss",100,1,true)
	_check(fx.puffs.size()==8,"Full dust pool limit")
	fx.set_low_quality(true); _check(fx.puffs.size()==3,"Low quality does not trim dust pool")
	for index in 40: fx.emit_contact(Vector2.ZERO,Vector2.UP,"moss",100,.35,false)
	_check(fx.puffs.size()==3,"Low-cost steps bypass pool cap")
	fx.advance(10); _check(fx.puffs.is_empty() and fx.grains.is_empty(),"Large delta does not retire ground effects")
	fx.emit_contact(Vector2.ZERO,Vector2.UP,"moss",100,1,true); fx.clear()
	_check(fx.puffs.is_empty() and not fx.sampled,"Room/warp clear leaves lingering dust")
	_check(fx.get_child_count()==0,"Dust pool adds per-effect nodes/colliders")
	print("GROUND_DUST_DECODED_BYTES ",bytes)
	stage.free(); state.delete_save()
	print("GROUND DUST ANIMATION TEST PASSED" if failures.is_empty() else "GROUND DUST ANIMATION TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
