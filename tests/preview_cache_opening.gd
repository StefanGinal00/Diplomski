extends "res://tests/preview_characters.gd"
func _render() -> void:
	root.size=Vector2i(1280,580)
	root.content_scale_size=root.size
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_cache_art_preview.json"
	state.start_new_game("normal")
	var stage := Node2D.new()
	root.add_child(stage)
	var bg := Polygon2D.new()
	bg.polygon=PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,580),Vector2(0,580)])
	bg.color=Color("14262e")
	stage.add_child(bg)
	var row := 0
	for family in ["cave","ash","starfall"]:
		_label(stage,family,Vector2(8,row*185+10),16)
		for pose in 6:
			var cache: Node2D=load("res://ResonanceCache.tscn").instantiate()
			cache.cache_id="preview_"+family+str(pose)
			stage.add_child(cache)
			cache.scale=Vector2.ONE*3
			cache.position=Vector2(170+pose*190,row*185+145)
			var art:=cache.get_node("PaintedCache")
			art.foot_y=0
			art.show_pose(pose)
			var line:=Line2D.new()
			line.points=PackedVector2Array([Vector2(-23,0),Vector2(23,0)])
			line.width=0.35
			line.default_color=Color("63838b")
			cache.add_child(line)
		row+=1
	await _capture("cache_opening_registered")
	state.delete_save()
	quit()
