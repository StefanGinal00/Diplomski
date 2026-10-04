extends "res://tests/preview_characters.gd"

const ART := preload("res://EchoDeviceArt.gd")


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_devices_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var background := Polygon2D.new()
	background.color = Color("12232d")
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	gallery.add_child(background)
	_label(gallery, "ECHO FIELD DEVICES / native 2D presentation", Vector2(35, 25), 25)
	_label(gallery, "Inactive / completed at 3x inspection; bottom: actual size (receiver recording)", Vector2(35, 66), 18)
	var kinds := ["resonator", "valve", "anchor", "drain", "receiver"]
	for column in range(kinds.size()):
		_label(gallery, ["Resonator", "Flow regulator", "Bridge anchor", "Drain gate", "Signal receiver"][column], Vector2(55 + column * 246, 123), 19)
		for row in range(3):
			var device := Node2D.new()
			device.position = Vector2(140 + column * 246, 240 + row * 180)
			device.scale = Vector2.ONE * (1 if row == 2 else 3)
			gallery.add_child(device)
			var art := ART.attach(device, kinds[column])
			art.set_status(row == 1, row == 2 and column == 4)
	await _capture("echo_devices")
	gallery.queue_free()
	await process_frame
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	game.get_node("Player").set_physics_process(false)
	for data in [
		["EchoGrotto", "echo_grotto", "LowerResonator"],
		["TideWell", "echo_tide_well", "LongTraversal/FieldOperations/Control0"],
		["CrystalCauseway", "echo_causeway", "LongTraversal/FieldOperations/Control0"],
		["UndertowVault", "echo_vault", "LongTraversal/FieldOperations/Control0"],
		["EchoGrotto", "echo_grotto", "LongTraversal/FieldDiscoveries/ListeningPost0"],
	]:
		state.set_current_room(data[1])
		await process_frame
		var room := game.get_node(data[0]) as Node2D
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var device := room.get_node(data[2]) as Node2D
		root.canvas_transform = Transform2D(Vector2(1.7, 0), Vector2(0, 1.7), Vector2(640, 530) - device.global_position * 1.7)
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		if room.has_node("PaintedDepth"):
			room.get_node("PaintedDepth")._process(0.1)
		await _capture("echo_device_" + device.get_node("DeviceArt").kind)
		if device.get_node("DeviceArt").kind == "valve":
			device.activate(game.get_node("Player"))
			await _capture("echo_device_valve_active")
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
