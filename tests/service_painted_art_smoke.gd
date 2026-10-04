extends "res://tests/gameplay_review_smoke.gd"
const Paint := preload("res://ServicePaintedArt.gd")
const Props := preload("res://WorkplaceAtlas.gd")
const Windows := preload("res://SettlementWindowAtlas.gd")
const CityPaint := preload("res://CityStreetAtlas.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_service_painted_art.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for tick in 3: await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.get_node("UI").story_player.cancel()
	paused = false
	var finish := game.get_node("WorldPresentationFinish")
	var count := 0
	var roles := {}
	var window_count := 0
	var stall_count := 0
	for id in ["echo_haven","ash_hearth","starfall_citadel"]:
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		var before := _collision_snapshot(nodes)
		for actor in nodes:
			if not actor.is_in_group("town_service"): continue
			count += 1
			_check(actor.has_node("ServicePainting"),"Missing painted service: "+str(actor.get_path()))
			if not actor.has_node("ServicePainting"): continue
			var art: Node2D = actor.get_node("ServicePainting")
			roles[Vector2i(art.kind,art.role)] = true
			_check(art.has_meta("support_rect"),"No service support: "+str(actor.get_path()))
			if not art.has_meta("support_rect"): continue
			var floor_rect: Rect2 = art.get_meta("support_rect")
			var original: Vector2 = actor.position
			for facing in [-1.0,1.0]:
				for pose in 3:
					art.show_pose(pose,facing)
					var boot: Vector2 = art.body.to_global(Vector2(0,-art.body.texture.get_height()/2.0+art.contact_row))
					_check(absf(boot.y-floor_rect.position.y)<0.05,"Floating service pose")
					_check(art.body.texture is AtlasTexture and art.body.flip_h==(facing<0),"Missing pose/facing")
					_check(art.body.texture.get_height()*art.body.scale.y<34,"Oversized service")
			_check(actor.position==original,"Painting moved native service")
			var prop: Sprite2D = art.workplace
			var contact := prop.to_global(Vector2(0,-prop.texture.get_height()/2.0+Props.contact(art.prop_index)))
			_check(absf(contact.y-floor_rect.position.y)<0.05,"Floating workplace")
			var half_width := prop.texture.get_width()*prop.scale.x/2.0
			_check(prop.global_position.x-half_width>=floor_rect.position.x and prop.global_position.x+half_width<=floor_rect.end.x,"Workplace overhangs ledge")
			for old in art.retired: _check(not old.visible,"Service prototype remains")
			_check(not art.is_processing() and not art.body.is_processing(),"Extra per-sprite process")
			art.show_pose(0,art.direction)
			# Test actual native signal -> shop/forge panel, not a replacement UI.
			var ui := game.get_node("UI")
			actor.interaction_requested.emit(actor)
			await process_frame
			_check(ui.shop_panel.visible,"Native service did not open")
			_check(ui.shop_portrait.texture==actor.get_portrait_texture(),"Service portrait identity changed")
			ui._close_shop()
			_check(not paused and not ui.shop_panel.visible,"Shop close/pause ownership")
		if room.has_node("PaintedBuildings"):
			var buildings := room.get_node("PaintedBuildings")
			window_count += buildings.window_art.size()
			_check(buildings.window_art.size()==buildings.window_frames.size(),"Unpainted facade window")
			for window in buildings.window_art:
				var texture: Texture2D = Windows.texture_for(window.index)
				_check(absf(window.rect.size.aspect()-texture.get_size().aspect())<0.01,"Stretched facade window")
			for prop in room.get_node("StreetArt").props:
				if prop.kind=="stall": stall_count += 1
		finish.finish_room(id)
		_check(_collision_snapshot(finish._members(room))==before,"Art changed native collisions")
	# A streamed service receives shared floor + focused name registration.
	state.set_current_room("echo_haven")
	for tick in 3: await process_frame
	var haven := game.get_node("EchoHaven")
	var late: Node2D = load("res://TownService.tscn").instantiate()
	late.position = haven.get_node("GlowmarketTrader").position
	haven.add_child(late)
	for tick in 4: await process_frame
	_check(not late.get_node("ServicePainting").surfaces.is_empty(),"Late service missing floor registration")
	_check(finish.focused_labels.has(late.get_node("NameLabel")),"Late service missing proximity name")
	var bytes := 0
	for sheet in Paint.SHEETS+[Props.SHEET,Windows.SHEET,CityPaint.SHEET]:
		var pixels: Image = sheet.get_image()
		bytes += pixels.get_data_size()
		_check(sheet.get_width()==1024 and pixels.has_mipmaps() and pixels.get_pixel(0,0).a<0.01,"Atlas import/alpha budget")
	_check(count>=8 and roles.size()==4 and window_count==59 and stall_count==9,"Missing coverage")
	_check(bytes<19*1024*1024,"Service/decor atlas budget exceeded")
	print("SERVICE ART COVERAGE ",count," services, ",roles.size()," body identities, ",window_count," windows, ",stall_count," stalls, ",bytes," decoded bytes")
	game.queue_free()
	await process_frame
	var town: Node2D = load("res://EchoHaven.tscn").instantiate()
	root.add_child(town)
	for tick in 3: await process_frame
	_check(not town.get_node("GlowmarketTrader/ServicePainting").surfaces.is_empty(),"F6 standalone service not grounded")
	town.queue_free()
	await process_frame
	state.delete_save()
	print("SERVICE PAINTED ART TEST PASSED" if failures.is_empty() else "SERVICE PAINTED ART TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
