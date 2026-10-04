extends "res://tests/preview_characters.gd"
const Atlas:=preload("res://LivingSpriteAtlas.gd")

func _render() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=root.size
	var gallery:=Node2D.new()
	root.add_child(gallery)
	var bg:=Polygon2D.new()
	bg.polygon=PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,720),Vector2(0,720)])
	bg.color=Color("132531")
	gallery.add_child(bg)
	_label(gallery,"LOOT: four actual animation frames, 4x gameplay size",Vector2(30,12),23)
	for row in 6:
		var kind: String=["gold","xp","iron_fragment","healing_herb","ether_fragment","supply_pouch"][row]
		_label(gallery,kind,Vector2(20,80+row*96))
		for frame in 4:
			var parent:=Node2D.new()
			parent.position=Vector2(355+frame*225,100+row*96)
			parent.scale=Vector2.ONE*4
			gallery.add_child(parent)
			preload("res://AnimatedPickupArt.gd").configure(parent,kind)
			var definition: Array=parent.get_meta("pickup_cycle")
			preload("res://AnimatedPickupArt.gd").animate(parent,(frame+0.1)/float(definition[4]))
	await _capture("living_loot_cycle")
	for child in gallery.get_children():
		if child!=bg: child.queue_free()
	await process_frame
	_label(gallery,"FOREGROUND: cave / ash / star, root-registered poses",Vector2(30,12),23)
	for family_index in 3:
		var family: String=["cave","ash","star"][family_index]
		for kind in 3:
			for frame in 4:
				var actor:=Node2D.new()
				actor.position=Vector2(80+kind*425+frame*97,205+family_index*225)
				gallery.add_child(actor)
				var art:=Sprite2D.new()
				actor.add_child(art)
				Atlas.show(art,"foreground_%s_breeze_v1"%family,kind*4+frame,72,0,1,310,"root")
	await _capture("living_flora_cycle")
	for child in gallery.get_children():
		if child!=bg: child.queue_free()
	await process_frame
	_label(gallery,"NATURAL PATHS: matching shallow walkable rock contours",Vector2(30,12),23)
	for family_index in 3:
		var family: String=["cave","ash","star"][family_index]
		for variant in 3:
			var mound:=preload("res://NaturalMound.gd").new()
			gallery.add_child(mound)
			mound.configure(family,variant,Vector2(215+variant*420,180+family_index*230))
			mound.scale=Vector2.ONE*2.4
			var ground:=Polygon2D.new()
			ground.polygon=PackedVector2Array([Vector2(-90,0),Vector2(90,0),Vector2(90,16),Vector2(-90,16)])
			ground.color=Color("101a21")
			ground.z_index=-1
			mound.add_child(ground)
	await _capture("living_mound_atlas")
	quit()
