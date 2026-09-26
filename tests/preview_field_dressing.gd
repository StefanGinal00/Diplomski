extends SceneTree

# Rendering-only inspection of the native blockout in its actual room.
# Run with a display driver, not --headless. No editor or player save changes.
func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	root.size = Vector2i(1100, 700)
	root.content_scale_size = root.size
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_field_preview_save.json"
	state.start_new_game("normal")
	var entries := [["VerticalChamber", "DeepShaftTraversal/FieldDressing", 2, "shaft"], ["EchoGrotto", "LongTraversal/FieldDressing", 6, "grotto"]]
	if "echo-records" in OS.get_cmdline_user_args():
		entries = [["EchoGallery", "LongTraversal/FieldDressing", 0, "gallery_camp"], ["PrismArchive", "LongTraversal/FieldDressing", 0, "archive_desk"], ["EchoGallery", "LongTraversal/FieldDressing", 5, "gallery_lens"], ["PrismArchive", "LongTraversal/FieldDressing", 3, "archive_lens"]]
	if "echo-habitats" in OS.get_cmdline_user_args():
		entries = [["TideWell", "LongTraversal/FieldDressing", 0, "tide_camp"], ["EchoNest", "LongTraversal/FieldDressing", 0, "nest_camp"], ["TideWell", "LongTraversal/FieldDressing", 3, "tide_gauge"], ["EchoNest", "LongTraversal/FieldDressing", 1, "nest_pods"], ["TideWell", "LongTraversal/FieldDressing", 3, "tide_calm", "echo_tide_field_station_0"], ["EchoNest", "LongTraversal/FieldDressing", 1, "nest_cleared", "echo_nest_field_station_0"]]
	if "echo-crossings" in OS.get_cmdline_user_args():
		entries = [["CrystalCauseway", "LongTraversal/FieldDressing", 0, "causeway_camp"], ["UndertowVault", "LongTraversal/FieldDressing", 0, "vault_camp"], ["CrystalCauseway", "LongTraversal/FieldDressing", 1, "causeway_tether"], ["UndertowVault", "LongTraversal/FieldDressing", 1, "vault_water"], ["CrystalCauseway", "LongTraversal/FieldDressing", 1, "causeway_stable", "echo_causeway_field_station_0"], ["UndertowVault", "LongTraversal/FieldDressing", 1, "vault_drained", "echo_vault_field_station_0"], ["UndertowVault", "LongTraversal/FieldDressing", 3, "vault_table", "echo_vault_upper"]]
	if "shaft-routes" in OS.get_cmdline_user_args():
		entries = [["ShaftHollow", "ExpandedRoute/FieldDressing", 0, "hollow_signal"], ["DrownedCrossing", "ExpandedRoute/FieldDressing", 0, "crossing_boat"], ["DrownedCrossing", "ExpandedRoute/FieldDressing", 2, "crossing_water"], ["ShaftHollow", "ExpandedRoute/FieldDressing", 4, "hollow_reserve"], ["ShaftHollow", "ExpandedRoute/FieldDressing", 0, "hollow_active", "shaft_hollow_relay"], ["DrownedCrossing", "ExpandedRoute/FieldDressing", 2, "crossing_drained", "shaft_sluice_valve"], ["ShaftHollow", "ExpandedRoute/FieldDressing", 4, "hollow_unsealed", "shaft_hollow_hidden_depth_cleared"]]
	if "shaft-deep" in OS.get_cmdline_user_args():
		entries = [["FloodedGallery", "ExpandedRoute/FieldDressing", 0, "gallery_pressure"], ["BlackwaterCistern", "ExpandedRoute/FieldDressing", 0, "cistern_diagram"], ["BlackwaterCistern", "ExpandedRoute/FieldDressing", 3, "cistern_tank"], ["WardenApproach", "ExpandedRoute/FieldDressing", 0, "approach_rack"], ["WardenApproach", "ExpandedRoute/FieldDressing", 3, "approach_weight"], ["WardenApproach", "ExpandedRoute/FieldDressing", 6, "approach_memorial"], ["FloodedGallery", "ExpandedRoute/FieldDressing", 0, "gallery_calm", "shaft_gallery_lower"], ["BlackwaterCistern", "ExpandedRoute/FieldDressing", 0, "cistern_complete", "shaft_cistern_pump"], ["BlackwaterCistern", "ExpandedRoute/FieldDressing", 3, "cistern_drained"], ["WardenApproach", "ExpandedRoute/FieldDressing", 3, "approach_lowered", "shaft_approach_bridge"]]
	if "ash-roads" in OS.get_cmdline_user_args():
		entries = [["BrokenCauseway", "AshSwitchback/FieldDressing", 0, "ash_road_camp"], ["AshChapel", "AshSwitchback/FieldDressing", 0, "ash_chapel_camp"], ["BrokenCauseway", "AshSwitchback/FieldDressing", 1, "ash_signal_table"], ["AshChapel", "AshSwitchback/FieldDressing", 1, "ash_record_desk"], ["AshChapel", "AshSwitchback/FieldDressing", 4, "ash_bell_memory"], ["BrokenCauseway", "AshSwitchback/FieldDressing", 1, "ash_signal_partial", "ash_causeway_signal_0"], ["AshChapel", "AshSwitchback/FieldDressing", 1, "ash_record_partial", "ash_chapel_record_1"], ["AshChapel", "AshSwitchback/FieldDressing", 4, "ash_bells_complete", "ash_chapel_bells"]]
	if "ash-industry" in OS.get_cmdline_user_args():
		entries = [
			["CinderForge", "AshSwitchback/FieldDressing", 0, "forge_camp"],
			["EmberBarracks", "AshSwitchback/FieldDressing", 0, "barracks_camp"],
			["SlagReservoir", "AshSwitchback/FieldDressing", 0, "reservoir_camp"],
			["CinderForge", "AshSwitchback/FieldDressing", 1, "forge_service"],
			["CinderForge", "AshSwitchback/FieldDressing", 3, "forge_fan"],
			["EmberBarracks", "AshSwitchback/FieldDressing", 1, "barracks_tally"],
			["SlagReservoir", "AshSwitchback/FieldDressing", 3, "reservoir_balance"],
			["CinderHearthOutskirts", "AshSwitchback/FieldDressing", 0, "outskirts_map"],
			["CinderForge", "AshSwitchback/FieldDressing", 1, "forge_ready", ["ash_forge_service_winch", "ash_forge_service_gearbox", "ash_forge_fan"]],
			["EmberBarracks", "AshSwitchback/FieldDressing", 1, "barracks_partial", "ash_barracks_drill_0"],
			["SlagReservoir", "AshSwitchback/FieldDressing", 3, "reservoir_ready", ["ash_reservoir_lower", "ash_reservoir_upper", "ash_reservoir_calibrated"]],
			["CinderHearthOutskirts", "AshSwitchback/FieldDressing", 0, "outskirts_partial", "ash_outskirts_report_0"],
		]
	if "starfall" in OS.get_cmdline_user_args():
		entries = []
		for room_name in ["StarfallOutskirts", "StarfallSilentGate", "StarfallMemoryVault", "StarfallRootedHall", "StarfallSoulCrucible", "StarfallSunlessPassage", "StarfallRamparts"]:
			var path := "FieldDressing" if room_name == "StarfallRamparts" else "ExpandedRoute/FieldDressing"
			entries.append([room_name, path, 0, room_name + "_camp"])
			entries.append([room_name, path, 1, room_name + "_task"])
			entries.append([room_name, path, 4 if room_name in ["StarfallOutskirts", "StarfallRootedHall"] else 3, room_name + "_identity"])
		entries.append(["StarfallSunlessPassage", "ExpandedRoute/FieldDressing", 3, "star_lights_partial", ["starfall_sunless_passage_beacon_0", "starfall_sunless_passage_beacon_1"]])
		entries.append(["StarfallMemoryVault", "ExpandedRoute/FieldDressing", 6, "star_reserve_partial", "starfall_memory_vault_field_complete"])
		entries.append(["StarfallMemoryVault", "ExpandedRoute/FieldDressing", 6, "star_reserve_cleared", ["starfall_memory_vault_niche_cleared", "starfall_memory_vault_field_return_complete"]])
	if "starfall-city" in OS.get_cmdline_user_args():
		entries = []
		for i in range(4):
			entries.append(["StarfallCitadel", "UpperCity/Workplace%d" % i, -1, "star_city_%d" % i])
	if "shaft-mouths" in OS.get_cmdline_user_args():
		entries = []
		for room_name in ["ShaftHollow", "DrownedCrossing", "BlackwaterCistern", "StarfallOutskirts"]:
			var generated_name := "StarfallDescent" if room_name.begins_with("Starfall") else "AuthoredDescent"
			entries.append([room_name, "ExpandedRoute/" + generated_name + "/ShaftCrossing0_0_0", -1, "mouth_" + room_name])
	if "return-lifts" in OS.get_cmdline_user_args():
		entries = []
		for room_name in ["ShaftHollow", "DrownedCrossing", "FloodedGallery", "BlackwaterCistern", "WardenApproach"]:
			entries.append([room_name, "ExpandedRoute/AuthoredDescent/ReturnLiftBottom", -1, "return_lift_" + room_name])
	if "expeditions" in OS.get_cmdline_user_args():
		entries = []
		for room_name in ["ShaftDriftworks", "EchoDepths", "AshEmberspine"]:
			for i in [0, 1, 3 if room_name != "AshEmberspine" else 4, 7]:
				entries.append([room_name, "FieldDressing", i, "exp_%s_%d" % [room_name, i]])
		entries.append(["ShaftDriftworks", "FieldDressing", 3, "exp_drift_partial", "shaft_drift_pumps_a"])
		entries.append(["EchoDepths", "FieldDressing", 5, "exp_depths_partial", "echo_depths_field_station_1"])
		entries.append(["AshEmberspine", "FieldDressing", 4, "exp_spine_partial", "ash_emberspine_cooling_0"])
		entries.append(["ShaftDriftworks", "FieldDressing", 7, "exp_drift_complete", ["shaft_drift_pumps_b", "shaft_drift_pumps_trial_complete"]])
		entries.append(["EchoDepths", "FieldDressing", 7, "exp_depths_complete", ["echo_depths_field_station_0", "echo_depths_field_return_complete"]])
		entries.append(["AshEmberspine", "FieldDressing", 7, "exp_spine_complete", ["ash_emberspine_cooling_1", "ash_emberspine_guarded_niche_cleared", "ash_emberspine_field_return_complete"]])
	var expedition_regions := {"ShaftDriftworks": "shaft", "EchoDepths": "echo", "AshEmberspine": "ash", "StarfallRamparts": "starfall"}
	for entry in entries:
		var room := load("res://%s.tscn" % ("ExpeditionWing" if expedition_regions.has(entry[0]) else entry[0])).instantiate() as Node2D
		if expedition_regions.has(entry[0]):
			room.region = expedition_regions[entry[0]]
		root.add_child(room)
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		if entry[3] == "star_reserve_cleared":
			state.mark_boss_defeated("hollow_sovereign")
		if entry.size() > 4:
			for flag in (entry[4] if entry[4] is Array else [entry[4]]):
				state.unlock_shortcut(flag)
		var detail := room.get_node(entry[1])
		var at: Vector2 = detail.anchors[entry[2]] if int(entry[2]) >= 0 else room.to_local(detail.global_position)
		root.canvas_transform = Transform2D(Vector2(0.9, 0), Vector2(0, 0.9), Vector2(550, 470) - at * 0.9)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://_tmp_field_%s_preview.png" % entry[3])
		print("FIELD PREVIEW ", entry[3], ": ", result)
		room.queue_free()
		await process_frame
	state.delete_save()
	quit(0)
