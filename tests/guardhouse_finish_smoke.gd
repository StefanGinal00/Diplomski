extends "res://tests/visual_style_slice_smoke.gd"
const Art := preload("res://GuardhouseArt.gd")
const Atlas := preload("res://CivicGuardAtlas.gd")
const Compact := preload("res://CompactPassageAtlas.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state:=root.get_node("GameState")
	state.save_path="res://_tmp_guardhouse_finish.json"
	state.start_new_game("normal")
	var bytes:=0
	for sheet in Atlas.SHEETS+Compact.SHEETS:
		var picture: Image=sheet.get_image()
		bytes+=picture.get_data_size()
		_check(picture.has_mipmaps() and picture.get_pixel(0,0).a<0.01,"No alpha/mipmaps")
		_check(sheet.get_width()<=1024,"Runtime atlas exceeds mobile dimension cap")
	_check(bytes<27*1024*1024,"Guard art decoded memory budget exceeded")
	_check(Atlas.SHEETS[0].get_image().get_pixel(512,450).a<0.01,"Gate opening is not transparent")
	for sheet in Atlas.SHEETS.size():
		for frame in Atlas.CROPS[sheet].size():
			var texture:=Atlas.texture_for(sheet,frame)
			_check(texture==Atlas.texture_for(sheet,frame) and texture.filter_clip,"Uncached/unclipped atlas")
			_check(Rect2(Vector2.ZERO,Atlas.SHEETS[sheet].get_size()).encloses(texture.region),"Crop out of bounds")
	for named in ["CinderHearth","StarfallCitadel"]:
		var room: Node2D=load("res://%s.tscn"%named).instantiate()
		var ambience:=room.get_node("SettlementAtmosphere")
		ambience.owner=null; room.remove_child(ambience)
		room.position=Vector2(13000,-7000)
		root.add_child(room)
		for tick in 4: await process_frame
		room.process_mode=Node.PROCESS_MODE_DISABLED
		var before:=_physics_snapshot(room)
		var nodes: Array[Node]=[]
		nodes.assign(room.find_children("*","",true,false))
		var floors:=Support.floors(nodes)
		var originals: Dictionary={}
		for node in nodes:
			if node is CollisionObject2D or node is Marker2D: originals[node]=node.global_transform
		var finish:=Art.install(room,floors)
		_check(finish.built and not finish.is_processing(),"Unbuilt/processing guardhouse")
		_check(_physics_snapshot(room)==before,"Guardhouse changed gameplay geometry")
		for node in originals: _check(originals[node]==node.global_transform,"Native actor/arrival moved")
		_check(finish.banners.size()==(6 if named=="CinderHearth" else 4),"Banner coverage")
		for banner in finish.banners:
			_check(not banner.is_processing() and banner.has_meta("ambient_motion"),"Per-banner processing/timer")
			var origin: Vector2=banner.global_position
			var rod_before: Transform2D=banner.rod.global_transform
			banner.animate(1.7)
			_check(banner.global_position==origin and banner.rod.global_transform==rod_before,"Banner rod drifted")
			_check(absf(banner.art.skew)<=0.015,"Excessive cloth distortion")
			banner.rest()
			_check(banner.art.skew==0,"Hidden cloth does not rest")
		for piece in finish.pieces:
			var support: Rect2=piece.get_meta("support_rect")
			var foot: Vector2=piece.to_global(Vector2(0,-piece.texture.get_height()*0.5+float(piece.get_meta("contact_row"))))
			_check(absf(foot.y-support.position.y)<0.01,"Floating gate")
			_check(is_equal_approx(piece.scale.x,piece.scale.y),"Stretched gate")
			for x in [-112,112]:
				var footing:=Support.below(foot+Vector2(x,0),floors,3)
				_check(footing.has_area() and absf(footing.position.y-foot.y)<0.01,"Unsupported gate foot")
		for old in finish.retired: _check(not old.visible,"Schematic gate still visible")
		_check(Art.install(room,floors)==finish,"Duplicated art")
		room.hide()
		_check(not finish.is_visible_in_tree(),"Hidden room keeps scenery")
		room.add_child(ambience)
		for tick in 2: await process_frame
		room.queue_free(); await process_frame
	state.delete_save()
	print("GUARDHOUSE FINISH TEST PASSED; decoded RGBA+mips bytes=",bytes) if failures.is_empty() else print("GUARDHOUSE FINISH TEST FAILED ",failures)
	quit(0 if failures.is_empty() else 1)
