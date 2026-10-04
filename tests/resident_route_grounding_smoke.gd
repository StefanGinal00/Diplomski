extends "res://tests/gameplay_review_smoke.gd"
const Motion := preload("res://ResidentMotion.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_resident_route_audit.json"; state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate(); root.add_child(game); current_scene=game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false; game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var totals := {"residents":0,"legs":0,"samples":0,"unsupported":0,"extreme_offset":0,"step_jumps":0}
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if not node is Motion: continue
			var actor: Node2D=node.get_parent()
			totals.residents+=1
			var stops: Array[Vector2]=[actor.global_position]
			for marker in actor.route_markers: stops.append(marker.global_position)
			if stops.size()<2: continue
			stops.append(stops[1])
			for leg in stops.size()-1:
				totals.legs+=1
				var samples := maxi(2,ceili(stops[leg].distance_to(stops[leg+1])/4.0))
				var last_floor := INF
				var problems := {"unsupported":0,"extreme_offset":0,"step_jumps":0}
				for sample in samples+1:
					var at := stops[leg].lerp(stops[leg+1],float(sample)/samples)
					var floor_rect := Support.below(at,node.surfaces,64)
					totals.samples+=1
					if not floor_rect.has_area(): problems.unsupported+=1; continue
					if absf(floor_rect.position.y-(at.y+14))>16: problems.extreme_offset+=1
					if last_floor!=INF and absf(last_floor-floor_rect.position.y)>6: problems.step_jumps+=1
					last_floor=floor_rect.position.y
				for key in problems: totals[key]+=problems[key]
				if problems.unsupported+problems.extreme_offset+problems.step_jumps>0:
					print("ROUTE_GROUND_FINDING ",actor.get_path()," leg=",leg," from=",stops[leg]," to=",stops[leg+1]," ",JSON.stringify(problems))
	print("RESIDENT_ROUTE_AUDIT ",JSON.stringify(totals))
	_check(totals.residents>=100 and totals.legs>=300 and totals.samples>10000,"Resident route audit misses world coverage")
	_check(totals.unsupported==0 and totals.extreme_offset==0 and totals.step_jumps==0,"Resident route has missing support or abrupt height changes")
	game.free(); state.delete_save()
	print("RESIDENT ROUTE GROUNDING TEST PASSED" if failures.is_empty() else "RESIDENT ROUTE GROUNDING TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
