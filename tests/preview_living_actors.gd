extends "res://tests/preview_characters.gd"
const Atlas:=preload("res://LivingSpriteAtlas.gd")
func _render() -> void:
	root.size=Vector2i(1440,960)
	root.content_scale_size=root.size
	for section in ["boss","motion","mob","resident","scenery"]:
		var gallery:=Node2D.new()
		root.add_child(gallery)
		var bg:=Polygon2D.new()
		bg.polygon=PackedVector2Array([Vector2.ZERO,Vector2(1440,0),Vector2(1440,960),Vector2(0,960)])
		bg.color=Color("163443")
		gallery.add_child(bg)
		_label(gallery,"REGISTERED "+section.to_upper()+" ANIMATION / source alpha masks",Vector2(25,8),22)
		var entries: Array=[]
		for id in Atlas.DATA:
			if section=="scenery" and id.begins_with("dressing_"): entries.append(id)
			if (section=="boss" and id.begins_with("boss_") and "_attack_" in id) or (section=="motion" and id.begins_with("boss_") and "_motion_" in id) or (section=="mob" and id.begins_with("mob_attack")) or (section=="resident" and id.begins_with("resident_gestures")): entries.append(id)
		for row in entries.size():
			var id: String=entries[row]
			var baseline:=145+row*115 if section in ["boss","motion"] else 220+row*210
			_label(gallery,id.trim_prefix("boss_").trim_suffix("_attack_v5").trim_suffix("_attack_v3"),Vector2(5,baseline-107),14)
			for frame in 8:
				var anchor:=Node2D.new()
				anchor.position=Vector2(95+frame*176,baseline)
				gallery.add_child(anchor)
				var art:=Sprite2D.new()
				anchor.add_child(art)
				Atlas.show(art,id,frame,95 if section in ["boss","motion"] else 150,0,1,float(Atlas.DATA[id].boxes[0 if section!="resident" else (frame/4)*4][3]),"root")
				var mark:=Line2D.new()
				mark.points=PackedVector2Array([Vector2(-30,0),Vector2(30,0)])
				mark.width=1
				mark.default_color=Color(0.2,0.75,0.75,0.4)
				anchor.add_child(mark)
		await _capture("living_"+section+"_attacks")
		gallery.queue_free()
		await process_frame
	quit()
