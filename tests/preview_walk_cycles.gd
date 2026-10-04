extends "res://tests/preview_characters.gd"
const Walk := preload("res://WalkCycleAtlas.gd")

func _render() -> void:
	root.size = Vector2i(1280,900)
	root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_walk_preview.json"
	var stage := Node2D.new()
	root.add_child(stage)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,900),Vector2(0,900)])
	bg.color = Color("15272d")
	stage.add_child(bg)
	var row := 0
	for identity in Walk.DATA:
		var label := Label.new()
		label.text = identity
		label.position = Vector2(8,row*98+8)
		label.add_theme_font_size_override("font_size",14)
		stage.add_child(label)
		for frame in 8:
			var holder := Node2D.new()
			holder.position = Vector2(195+frame*143,row*98+87)
			stage.add_child(holder)
			var line := Line2D.new()
			line.points = PackedVector2Array([Vector2(-55,0),Vector2(55,0)])
			line.default_color = Color("45616b")
			line.width = 1
			holder.add_child(line)
			var sprite := Sprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			holder.add_child(sprite)
			Walk.show(sprite,identity,frame,76,0,1)
		row += 1
	await _capture("walk_cycles_registered")
	quit()
