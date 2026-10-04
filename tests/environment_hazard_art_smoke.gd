extends "res://tests/boss_combat_presentation_smoke.gd"
const ART = preload("res://EnvironmentHazardArt.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_environment_hazard_art.json"
	state.start_new_game("normal")
	var cases := [["ShaftRouteHazard", "pressure"], ["ShaftRouteHazard", "rockfall"], ["ShaftRouteHazard", "current"], ["HeatVent", "fire"], ["TidePulse", "water"], ["RootSnare", "roots"], ["SoulPulse", "soul"], ["EchoCurrentField", "current"]]
	for item in cases:
		var actor: Area2D = load("res://%s.tscn" % item[0]).instantiate()
		if item[0] == "ShaftRouteHazard": actor.hazard_kind = item[1]
		var col: CollisionShape2D = actor.get_node("CollisionShape2D")
		var shape_id := col.shape.get_instance_id()
		var dimensions: Vector2 = col.shape.size
		root.add_child(actor)
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		var art: Node2D = actor.get_node("HazardArt")
		_check(art.kind == item[1], "Wrong art family: " + item[0])
		_check(col.shape.get_instance_id() == shape_id and col.shape.size == dimensions, "Art changed native collision")
		_check(art.bounds == col.transform * Rect2(-dimensions / 2, dimensions), "Art footprint differs from collision")
		_check(ART.attach(actor, item[1]) == art, "Art duplicated")
		var hashes := {}
		for i in range(4):
			var pixels: Image = art._sheet().get_image()
			var region: Rect2 = art.source_frame(i)
			_check(Rect2(Vector2.ZERO, pixels.get_size()).encloses(region), "Frame out of texture bounds")
			hashes[hash(pixels.get_region(Rect2i(region)).get_data())] = true
		_check(hashes.size() == 4, "Animation repeats one raster four times: " + item[1])
		if item[1] != "current":
			for phase in ["idle", "warning", "active", "idle"]:
				actor.phase = phase
				actor._update_visuals()
				art.refresh()
				_check(art.phase == phase and art.caption.visible == (phase in ["warning", "active"]), "Visual phase out of sync")
				var timer: float = actor.phase_remaining
				art.age = 0.27
				art.refresh()
				_check(art.frame == 2 and actor.phase_remaining == timer, "Presentation advanced native timer or failed to animate")
			actor.disabled = true
		else:
			art.refresh()
			_check(art.phase == "flow" and not art.caption.visible, "Nonlethal current displayed as attack")
			if item[0] == "EchoCurrentField": actor.set_calmed(true)
			else: actor.disabled = true
		art.refresh()
		_check(art.phase == "disabled" and not art.caption.visible, "Disabled hazard still announces damage")
		for named in ["HazardFill", "WarningLine", "DirectionMarks", "Flame", "Base", "RootBed", "PulseBase", "Water", "Crest", "StreamA", "StreamB", "DirectionArrow"]:
			if actor.has_node(named): _check(not actor.get_node(named).visible, "Prototype glow reappeared: " + item[0] + "/" + named)
		_check(not art.is_processing(), "Off-camera art updates every frame")
		actor.queue_free()
		await process_frame
	state.delete_save()
	print("ENVIRONMENT HAZARD ART TEST PASSED: 8 native cases, 7 families, 24 distinct frames" if failures.is_empty() else "TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
