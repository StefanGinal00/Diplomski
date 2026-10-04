extends "res://tests/preview_characters.gd"
const Layout := preload("res://WorldLayout.gd")
const Town := preload("res://TownVergeAtlas.gd")

func _render() -> void:
	root.size=Vector2i(1280,720); root.content_scale_size=root.size
	var state := root.get_node("GameState"); state.save_path="res://_tmp_town_verge_preview.json"; state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate(); root.add_child(game); current_scene=game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false; game.process_mode=Node.PROCESS_MODE_DISABLED
	var player: Player=game.get_node("Player"); player.test_invincible=true
	var camera: Camera2D=player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for id in ["echo_haven","ash_hearth","starfall_citadel"]:
		state.set_current_room(id)
		for tick in 5: await process_frame
		finish.finish_room(id); game.get_node("UI")._dismiss_zone_title()
		var room: Node2D=game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node is CollisionObject2D:
				node.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
				if node is Area2D or node.is_in_group("enemy") or node.is_in_group("neutral_creature"):
					node.collision_layer=0; node.collision_mask=0
		var layer: Node2D=room.get_node("PathDressing")
		var home: Node2D; var verge: Node2D
		for prop in layer.details:
			if prop.kind!="floor" or not prop.visible: continue
			if home==null and prop.variant<5: home=prop
			if verge==null and prop.variant==5 and not Town.near_home(prop.global_position,layer.home_zones): verge=prop
		if home==null or verge==null: push_error("Missing native town sites: "+id); quit(1); return
		var ambience: Node=finish.ambience
		for target in [home,verge]:
			player.global_position=Vector2(target.global_position.x-27,target.support.position.y-25)
			player.velocity=Vector2.ZERO; player.process_mode=Node.PROCESS_MODE_ALWAYS
			for tick in 30: await physics_frame
			if not player.is_on_floor(): push_error("Native town site lacks floor: "+id); quit(1); return
			player.process_mode=Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
			camera.offset=Vector2(0,-28); camera.reset_smoothing(); camera.force_update_scroll()
			finish.background._process(0); finish._process(.15); ambience.clear_brushing()
			await _capture("town_verge_"+id+("_home" if target==home else "_calm"))
			if target==home: continue
			player.process_mode=Node.PROCESS_MODE_ALWAYS; Input.action_press("ui_right")
			var contacted := false
			for tick in 18:
				await physics_frame; ambience._physics_process(1.0/60); ambience._process(1.0/60)
				if target in ambience.brushing: contacted=true
			Input.action_release("ui_right"); player.process_mode=Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
			if not contacted or absf(target.response.bend)<.005: push_error("Native town walk never bends new foliage: "+id); quit(1); return
			await _capture("town_verge_"+id+"_brushed")
			print("TOWN_NATIVE ",id," support=",player.is_on_floor()," bend=",target.response.bend," local=",room.to_local(target.global_position))
			for tick in 240: ambience.sample_brushing(player.global_position,player.global_position,Vector2.ZERO,1.0/60)
			if target.response.bend!=0: push_error("Native town grass does not settle"); quit(1); return
			await _capture("town_verge_"+id+"_settled")
		if id=="echo_haven":
			var records := room.get_node("NewDistricts/DiscoveryBoard")
			player.global_position=records.curator.global_position-Vector2(90,4)
			player.velocity=Vector2.ZERO; player.process_mode=Node.PROCESS_MODE_ALWAYS
			for tick in 30: await physics_frame
			if not player.is_on_floor() or records.backing.visible: push_error("Record roof regression"); quit(1); return
			player.process_mode=Node.PROCESS_MODE_DISABLED; player.get_node("Appearance")._process(.1)
			camera.reset_smoothing(); camera.force_update_scroll(); finish.background._process(0); finish._process(.15)
			await _capture("town_verge_echo_records_roof")
	game.free(); state.delete_save(); quit(0)
