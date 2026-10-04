extends "res://tests/visual_style_slice_smoke.gd"
const Fit := preload("res://SettlementCanopyPlacement.gd")
const Wares := preload("res://WorkplaceAtlas.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_canopy_placement.json"
	state.start_new_game("normal")
	var canvas := Node2D.new()
	canvas.position=Vector2(18000,-7000)
	canvas.scale=Vector2(1.25,0.8)
	root.add_child(canvas)
	var floor_rect := Rect2(-200,100,400,18)
	var floors: Array[Rect2] = [canvas.global_transform*floor_rect]
	var openings: Array[Rect2] = [Rect2(-22,35,44,42),Rect2(-18,70,36,30)]
	var layout := Fit.fit(canvas,floors,Vector2(0,100),90,92,Wares.texture_for(3),openings)
	_check(not layout.is_empty(),"Scaled/translated facade has no clear canopy")
	if not layout.is_empty():
		_check(layout.support==floors[0] and is_equal_approx(canvas.to_global(layout.at).y,floors[0].position.y),"Canopy loses scaled world support")
		_check(is_equal_approx(layout.cloth.size.x/Wares.texture_for(3).get_width(),layout.cloth.size.y/Wares.texture_for(3).get_height()),"Canopy texture stretched")
		for opening in openings:
			_check(not layout.cloth.intersects(opening) and not layout.posts[0].intersects(opening) and not layout.posts[1].intersects(opening),"Canopy masks opening in scaled room")
	var blocked: Array[Rect2] = [Rect2(-300,-250,600,600)]
	_check(Fit.fit(canvas,floors,Vector2(0,100),90,92,Wares.texture_for(3),blocked).is_empty(),"Impossible canopy invents unreserved space")
	_check(Fit.fit_counter(canvas,floors,Vector2(0,100),Wares.texture_for(0),36,blocked).is_empty(),"Impossible counter ignores wall")
	# Real low ceiling: the top is also a registered surface, but all of its
	# upper airspace is reserved. Only the original lower street is a valid site.
	floors.append(canvas.global_transform*Rect2(-200,55,400,14))
	var low_reserve: Array[Rect2] = [Rect2(-300,-200,600,270)]
	_check(Fit.fit(canvas,floors,Vector2(0,100),90,92,Wares.texture_for(3),low_reserve).is_empty(),"Tent was forced into low passage")
	var counter := Fit.fit_counter(canvas,floors,Vector2(0,100),Wares.texture_for(0),36,low_reserve)
	_check(not counter.is_empty(),"Low passage lost its compact open counter")
	if not counter.is_empty():
		_check(counter.mode=="counter" and counter.support==floors[0] and counter.counter.size.y<31,"Counter moved onto ceiling/grew too tall")
		_check(not counter.counter.intersects(low_reserve[0]),"Counter crosses low ceiling")
	_check(canvas.get_child_count()==0 and not canvas.is_physics_processing(),"Static fit adds colliders/frame work")
	canvas.queue_free()
	await process_frame
	state.delete_save()
	print("CANOPY PLACEMENT TEST ","PASSED" if failures.is_empty() else "FAILED",": scaled/translated support, opening clearance, uniform texture, impossible-site rejection, low-ceiling counter fallback")
	quit(0 if failures.is_empty() else 1)
