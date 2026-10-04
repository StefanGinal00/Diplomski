extends "res://tests/visual_style_slice_smoke.gd"
const Art := preload("res://CityArchitectureAtlas.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_city_architecture_finish.json"
	state.start_new_game("normal")
	var bytes := 0
	for sheet in 3:
		var texture: Texture2D = Art.SHEETS[sheet]
		var image := texture.get_image()
		bytes += image.get_data_size()
		_check(texture.get_width()<=1024 and image.has_mipmaps(),"Atlas import budget/mipmaps")
		_check(image.get_pixel(0,0).a<0.02,"Opaque atlas background")
		for index in Art.CROPS[sheet].size():
			var frame := Art.texture_for(sheet,index)
			_check(frame==Art.texture_for(sheet,index) and frame.filter_clip,"Regions must be cached and clipped")
			_check(Rect2(Vector2.ZERO,texture.get_size()).encloses(frame.region),"Atlas crop outside source")
			var fitted := Art.fit_rect(sheet,index,Rect2(25,70,55,48))
			var factor := fitted.size/frame.get_size()
			_check(is_equal_approx(factor.x,factor.y),"Object art stretched")
			if sheet==0:
				var at := frame.region.position+frame.region.size*Vector2(0.5,0.9)
				_check(image.get_pixelv(Vector2i(at)).a<0.02,"Arch opening contains a painted backdrop")
	for index in 6:
		var vertical := index<3
		for length in [45.0,140.0,600.0]:
			var bounds := Rect2(Vector2(13,27),Vector2(12,length) if vertical else Vector2(length,9))
			var cursor := bounds.position.y if vertical else bounds.position.x
			var pieces := Art.trim_pieces(index,bounds)
			_check(pieces.size()<=64,"Unbounded facade detail drawing")
			for piece in pieces:
				var factor: Vector2 = piece.rect.size/piece.source.size
				_check(absf(factor.x-factor.y)<0.0001,"Trim capital or stone grain stretched")
				_check(Art.CROPS[1][index].grow(0.01).encloses(piece.source),"Trim crossed into adjacent frame")
				_check(absf((piece.rect.position.y if vertical else piece.rect.position.x)-cursor)<0.001,"Trim seam gap")
				cursor = piece.rect.end.y if vertical else piece.rect.end.x
			_check(absf(cursor-(bounds.end.y if vertical else bounds.end.x))<0.001,"Trim does not cover facade edge")
	for material in ["citadel","cinder","echo"]:
		var texture: Texture2D=load("res://art/visual_slice/city_wall_%s_v1.png"%material)
		bytes += texture.get_image().get_data_size()
		_check(texture.get_size()==Vector2(512,512) and texture.get_image().has_mipmaps(),"Wall material budget")
	_check(bytes<16*1024*1024,"Six city images exceed 16 MiB decoded")
	var facade_count := 0
	var arch_count := 0
	for named in ["EchoHaven","EchoHavenOutskirts","CinderHearth","StarfallCitadel"]:
		var city: Node2D=load("res://%s.tscn"%named).instantiate()
		city.position=Vector2(19000,-12000)
		root.add_child(city)
		for i in 3: await process_frame
		city.process_mode=Node.PROCESS_MODE_DISABLED
		var before := _physics_snapshot(city)
		var art := city.get_node("MaterialExpansion" if named=="StarfallCitadel" else "PaintedBuildings")
		for plate in art.painted:
			if "/city_wall_" not in plate.texture.resource_path: continue
			facade_count += 1
			_check(plate.z_index<0 and plate.texture_repeat==CanvasItem.TEXTURE_REPEAT_ENABLED,"Wall obscures actors or stretches")
			var extent: Vector2=plate.polygon[1]-plate.polygon[0]
			var uv_extent: Vector2=(plate.uv[1]-plate.uv[0])/plate.texture.get_size()
			_check(extent.length()/uv_extent.length()<=180.01,"Person-sized bricks remain on close facade")
		if named=="StarfallCitadel":
			var upper := city.get_node("UpperCity")
			var civic := upper.get_node("CivicArt")
			var walk := upper.get_node("WalkwayArt")
			_check(not upper.get_node("CrownObservatory/CelestialLens").visible and not upper.get_node("CrownObservatory/LensPedestal").visible,"Schematic lens/pedestal visible")
			var nodes: Array[Node]=[]
			nodes.assign(city.find_children("*","",true,false))
			var floors:=Support.floors(nodes)
			for offset in [Vector2.ZERO,Vector2(215,0)]:
				_check(Support.below(civic.to_global(civic.lens_base+offset),floors,1).has_area(),"Floating observatory instrument")
			for arcade in walk.arcades:
				var cursor: float=arcade.rect.position.x
				for piece in walk._arcade_pieces(arcade.rect,arcade.district):
					arch_count+=1
					_check(absf(piece.rect.position.x-cursor)<0.001,"Gap between arches")
					_check(piece.rect.end.y<=arcade.rect.end.y and piece.rect.size.y<=50,"Arcade exceeds original shallow underside")
					cursor=piece.rect.end.x
				_check(absf(cursor-arcade.rect.end.x)<0.001,"Arcade detached from terrace end")
			for item in [civic,walk,upper.get_node("SkylineArt")]:
				item._build()
				_check(not item.is_processing() and item.get_child_count()==0,"Static architecture adds per-object frame updates")
		else:
			_check(art.gables.size()>=(16 if named=="EchoHavenOutskirts" else (18 if named=="EchoHaven" else 3)),"Open roof-to-wall gap remains")
			_check(art.wall_feet.size()>=(5 if named=="EchoHavenOutskirts" else (8 if named=="EchoHaven" else 3)),"House floats above street")
			for foot in art.wall_feet:
				var top: float=foot.to_global(foot.polygon[0]).y
				var bottom: float=foot.to_global(foot.polygon[2]).y
				var center_x: float=(foot.to_global(foot.polygon[0]).x+foot.to_global(foot.polygon[2]).x)/2
				var support:=Support.below(Vector2(center_x,bottom),art.floors,1)
				_check(support.has_area() and absf(bottom-support.position.y)<0.01 and bottom-top<=21,"Facade footing misses floor or fills too much headroom")
			for gable in art.gables:
				_check(gable.polygon.size()==3 and gable.texture==art.wall_texture and gable.z_index==-2,"Gable lacks matching rear wall texture")
			var gable_count: int=art.gables.size()
			art._build()
			_check(art.gables.size()==gable_count,"Gable duplicated on rebuild")
		art._build()
		_check(before==_physics_snapshot(city),"Architecture changed colliders")
		city.free()
		await process_frame
	_check(facade_count>=60 and arch_count>=25,"Incomplete city coverage")
	print("CITY ARCHITECTURE COVERAGE facades=",facade_count," arches=",arch_count," decoded_bytes=",bytes)
	state.delete_save()
	print("CITY ARCHITECTURE FINISH TEST PASSED" if failures.is_empty() else "CITY ARCHITECTURE FINISH TEST FAILED "+str(failures))
	quit(0 if failures.is_empty() else 1)
