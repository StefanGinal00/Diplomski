extends "res://tests/boss_combat_presentation_smoke.gd"
const Layout := preload("res://WorldLayout.gd")
const Atlas := preload("res://StructureAtlas.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_structure.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var seen := {}
	var portals := 0
	var compact_portals := 0
	var moved_landings := 0
	var lifts := 0
	var anchors := {}
	var ids: Array = ["training_passage"] + Layout.ROOM_NODES.keys()
	for id in ids:
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		if seen.has(room.get_instance_id()): continue
		seen[room.get_instance_id()] = true
		state.set_current_room(id)
		await process_frame
		await process_frame
		finish.finish_room(id)
		var nodes: Array[Node] = finish._members(room)
		for actor in nodes:
			if actor is LevelExit or actor.is_in_group("room_door"):
				portals += 1
				var shift: Vector2=actor.get_meta("portal_landing_shift",Vector2.ZERO)
				if not shift.is_zero_approx():
					moved_landings+=1
					_check(shift.y==0 and absf(shift.x)<=160,"Entrance left its landing")
					print("MOVED LANDING ",actor.get_path()," offset=",shift)
				var art: Sprite2D = actor.get_node("FinishedDevice")
				var context: Node2D = actor.get_node("PortalSurround")
				_check((art.texture.atlas == Atlas.FACADES or art.texture.atlas in preload("res://CompactPassageAtlas.gd").SHEETS) and art.scale.x == art.scale.y, "Unintegrated/distorted entrance: " + str(actor.get_path()))
				_check(art.z_index < 0 and context.has_node("UnderLedge"), "Entrance obscures actor or lacks underside support")
				var threshold: Sprite2D=context.get_node("Threshold")
				_check(threshold.texture is AtlasTexture and is_equal_approx(threshold.scale.x,threshold.scale.y),"Unpainted/stretched threshold")
				var floor_rect: Rect2=context.get_meta("supported_floor")
				var plan: Dictionary=context.get_meta("facade_plan")
				var facade_bounds: Rect2=art.global_transform*art.get_rect()
				if plan.compact:
					compact_portals+=1
					print("COMPACT PORTAL ",actor.get_path()," size=",facade_bounds.size," clearance=",plan.clearance," offset=",plan.x-actor.global_position.x)
					_check(facade_bounds.size.y>=36,"Door opening too small: "+str(actor.get_path()))
					_check(absf(plan.x-actor.global_position.x)<=20.1,"Art escaped native interaction footprint")
				_check(facade_bounds.position.y>=floor_rect.position.y-plan.clearance+7.0,"Stair/ceiling cuts across portal: "+str(actor.get_path()))
				var foot: Vector2=threshold.to_global(Vector2(0,-threshold.texture.get_height()*0.5+float(threshold.get_meta("contact_row"))))
				_check(absf(foot.y-floor_rect.position.y)<0.01,"Door threshold floats")
				_check(threshold.texture.get_width()*threshold.scale.x<=42.1,"Oversized threshold")
				var threshold_bounds: Rect2=threshold.global_transform*threshold.get_rect()
				_check(threshold_bounds.position.x>=floor_rect.position.x-0.01 and threshold_bounds.end.x<=floor_rect.end.x+0.01,"Threshold overhangs ledge")
				var anchor: Dictionary = context.get_meta("structural_anchor")
				anchors[anchor.kind] = int(anchors.get(anchor.kind, 0)) + 1
				_check(anchor.rect.has_area(), "Entrance has no terrain anchor")
				var hitbox: CollisionShape2D = actor.get_node("CollisionShape2D")
				_check(hitbox.shape.size.x >= 40, "Art shrank interaction reach")
			if actor.is_in_group("shaft_lift"):
				lifts += 1
				var art: Sprite2D = actor.get_node("FinishedDevice")
				var rig := actor.get_node("LiftGantry")
				_check(art.texture.atlas == Atlas.HOISTS and art.scale.x == art.scale.y, "Lift is still a hanging standalone picture")
				for named in ["WinchHead", "LoadPostLeft", "LoadPostRight", "SuspensionLeft", "SuspensionRight", "UnderLedge"]:
					_check(rig.has_node(named), "Incomplete lift construction: " + named)
				_check(not rig.has_node("TerrainTie"), "Solid triangular lift infill returned")
				_check(rig.has_node("WallBrace") or rig.has_node("TrestleLeft"), "Lift has no open structural bracing")
				for named in ["SuspensionLeft", "SuspensionRight"]:
					var rope: Line2D = rig.get_node(named)
					var head: Sprite2D = rig.get_node("WinchHead")
					var ratio: float = rig.get_meta("clearance_plan").width/69.0
					var side: float = -1 if named == "SuspensionLeft" else 1
					_check(rope.points[0].distance_to(head.position+Vector2(side*17*ratio,-8*ratio)) < 0.01 and rope.points[1] == Vector2(side*21,-2), "Cable misses fitted hoist/deck")
				var support: Rect2 = rig.get_meta("support_rect")
				for named in ["LoadPostLeft", "LoadPostRight"]:
					var post: Polygon2D = rig.get_node(named)
					var foot: Vector2 = post.to_global(post.polygon[0])
					_check(foot.x >= support.position.x - 0.05 and foot.x <= support.end.x + 0.05 and absf(foot.y-support.position.y) < 0.05, "Hoist post has no solid footing: " + str(actor.get_path()))
				_check(get_first_node_in_group(actor.target_marker_group) != null, "Hoist has no real destination")
		var count := nodes.size()
		finish.finish_room(id)
		_check(finish._members(room).size() == count, "Reentry duplicates structures: " + id)
	# The formerly cached path must dress real late/streamed native devices.
	state.set_current_room("training_passage")
	await process_frame
	await process_frame
	var door: Node2D = load("res://RoomDoor.tscn").instantiate()
	door.name = "LateStructureDoor"
	game.add_child(door)
	door.position = Vector2(800, 366)
	var lift: Node2D = load("res://ShaftLift.tscn").instantiate()
	lift.name = "LateStructureLift"
	lift.target_marker_group = &"shaft_lift_lower"
	game.add_child(lift)
	lift.position = Vector2(950, 368)
	for tick in range(3): await process_frame
	_check(door.has_node("PortalSurround/UnderLedge") and lift.has_node("LiftGantry/WinchHead"), "Cached room skipped late devices")
	var before: Transform2D = door.transform
	# Support reflow moves only artwork, never the native area/arrival.
	door.position.x += 25
	finish.finish_room("training_passage")
	_check(door.position == before.origin + Vector2(25, 0), "Reflow moved native door")
	_check(door.get_node("PortalSurround").get_meta("anchor_origin") == door.global_position, "Moved portal kept stale terrain anchor")
	# Facades must remain behind nearby lamp/NPC art, not erase it through draw order.
	_check(door.get_node("FinishedDevice").z_index + door.z_index < game.get_node("Checkpoint/FinishedDevice").z_index, "Rear facade can occlude checkpoint art")
	game.get_node("Player").position = Vector2(800, 370)
	finish._focus_devices()
	var visible := 0
	for label in finish.device_labels:
		if label.modulate.a > 0.5: visible += 1
	_check(visible <= 1, "Nearby device labels overlap")
	var bytes := 0
	for tex in [Atlas.FACADES, Atlas.HOISTS, preload("res://LedgeSupportArt.gd").SHEET]:
		var pixels: Image = tex.get_image()
		bytes += pixels.get_data_size()
		_check(pixels.has_mipmaps() and pixels.get_pixel(0, 0).a < 0.01, "Atlas lacks alpha/mipmaps")
	_check(portals == 112 and lifts >= 35, "Incomplete world device coverage")
	_check(compact_portals>0,"No constrained landing uses compact facade")
	# A moved/new overhead surface must invalidate the art-only cache.
	var compact:=preload("res://CompactPassageAtlas.gd")
	var ground:=Rect2(0,100,300,20)
	var open_floors: Array[Rect2]=[ground]
	var low_floors: Array[Rect2]=[ground,Rect2(0,20,300,10)]
	_check(not compact.plan(150,ground,open_floors,0,0).compact,"Open room needlessly shrunk")
	var constrained:=compact.plan(150,ground,low_floors,0,0)
	_check(constrained.compact and constrained.height<=62,"New ceiling ignored")
	var live_door: Node2D=Node2D.new()
	live_door.name="ReflowFixture"
	root.add_child(live_door); live_door.position=Vector2(150,80)
	var live_art:=Sprite2D.new(); live_art.name="FinishedDevice"; live_door.add_child(live_art)
	var portals_art:=preload("res://PortalContextArt.gd")
	portals_art.install(live_door,"echo_haven",open_floors)
	portals_art.install(live_door,"echo_haven",low_floors)
	_check(live_door.get_node("PortalSurround").get_meta("facade_plan").compact,"Reflow cache ignored ceiling change")
	_check(live_door.position==Vector2(150,80),"Ceiling reflow moved native portal")
	portals_art.install(live_door,"echo_haven",open_floors)
	_check(not live_door.get_node("PortalSurround").get_meta("facade_plan").compact,"Raised ceiling kept tiny facade")
	live_door.queue_free()
	print("WORLD STRUCTURE COVERAGE: ", seen.size(), " rooms, ", portals, " facades, ", lifts, " hoists; anchors=", anchors, "; shared atlas decoded bytes=", bytes)
	print("PORTAL HEADROOM COVERAGE: compact=",compact_portals," authored landing shifts=",moved_landings)
	game.queue_free()
	await process_frame
	state.delete_save()
	print("WORLD STRUCTURE TEST PASSED" if failures.is_empty() else "WORLD STRUCTURE TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
