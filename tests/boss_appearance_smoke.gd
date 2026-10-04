extends SceneTree

const CASES := [
	["Boss", "void_sentinel", ["BodyVisual", "Crown", "Eye"], []],
	["AbyssWarden", "abyss_warden", ["BodyVisual", "Crown", "Eye"], ["Telegraph"]],
	["EchoMatriarch", "echo_matriarch", ["WingLeft", "WingRight", "BodyVisual", "Crown", "Eye"], ["PulseRing"]],
	["AshCastellan", "ash_castellan", ["Cape", "Armor", "Crown", "Eye"], ["ChargeLine", "EruptionMiddle"]],
	["HollowSovereign", "hollow_sovereign", ["Aura", "Mantle", "BodyVisual", "Crown", "Eye"], ["TelegraphLine", "RiftMark"]],
	["StarfallGuardian", "starfall_guardian", ["Mantle", "Armor", "Crown", "Eye"], ["ChargeLine", "VolleyLine"]],
	["EmberMarshal", "ember_marshal", ["Cape", "Armor", "Helm", "Eye"], []],
]
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_appearance.json"
	state.start_new_game("normal")
	for data in CASES:
		var boss := load("res://%s.tscn" % data[0]).instantiate() as CharacterBody2D
		root.add_child(boss)
		boss.set_physics_process(false)
		await process_frame
		var art := boss.get_node_or_null("PaintedAppearance") as Sprite2D
		_check(art != null and art.boss_id == data[1], "Unique boss sheet missing: " + data[0])
		if art != null:
			_check(art.hframes == 4 and art.vframes == 3 and art.frame_sequence != null, "Expanded boss sheet missing: " + data[0])
			_check(art.texture.get_image().has_mipmaps(), "Boss texture lacks mipmaps: " + data[0])
			var cell: Vector2i = Vector2i(art.texture.get_size() / Vector2(4, 3))
			for frame_index in range(12):
				var corner := Vector2i(frame_index % 4, frame_index / 4) * cell
				_check(art.texture.get_image().get_pixelv(corner).a == 0, "Boss sprite sheet has opaque gutters: " + data[0])
				_check(Rect2(Vector2.ZERO, Vector2(cell)).encloses(art.get_frame_bounds(frame_index)), "Frame clips outside cell: " + data[0])
			art._process(0.016)
			_check(art.frame >= 0 and art.frame < 12 and art.scale.x > 0 and art.scale.y > 0, "Boss presentation state invalid: " + data[0])
		for node_name in data[2]:
			_check(not boss.get_node(node_name).visible, "Legacy flat boss body still visible: %s/%s" % [data[0], node_name])
		for cue_name in data[3]:
			_check(boss.has_node(cue_name), "Existing combat cue missing: %s/%s" % [data[0], cue_name])
		var shape := boss.get_node("CollisionShape2D") as CollisionShape2D
		_check(shape.shape != null and boss.is_in_group("enemy") and boss.is_in_group("mini_boss" if data[0] == "EmberMarshal" else "boss"), "Boss collision/group changed: " + data[0])
		boss.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("BOSS APPEARANCE TEST PASSED: seven unique 4x3 transparent boss sheets, 84 bounded frames, mipmaps, existing cues and collisions")
		quit(0)
	else:
		quit(1)
