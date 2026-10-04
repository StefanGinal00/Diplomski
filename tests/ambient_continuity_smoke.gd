extends "res://tests/boss_combat_presentation_smoke.gd"

class Probe extends Node2D:
	var rests := 0
	func rest() -> void:
		rests += 1
		rotation = 0
	func animate(_age: float) -> void:
		pass

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ambient_continuity.json"
	state.start_new_game("normal")
	var room := Node2D.new()
	root.add_child(room)
	var ambience := preload("res://WorldAmbience.gd").new()
	room.add_child(ambience)
	var nodes: Array[Node] = []
	for index in 25:
		var prop := Probe.new()
		prop.position = Vector2(index * 5, 0)
		prop.set_meta("ambient_motion", true)
		room.add_child(prop)
		nodes.append(prop)
		ambience.candidates.append(prop)
	var view := Rect2(Vector2(-100, -100), Vector2(400, 200))
	ambience.select_visible(view)
	var retained: Array[Node2D] = ambience.active.duplicate()
	for prop in retained: prop.rotation = 0.12
	for refresh in 8: ambience.select_visible(view)
	for prop in retained:
		_check(prop.rests == 0 and is_equal_approx(prop.rotation, 0.12), "Visible ornament resets every camera selection")
	ambience.low_quality = true
	ambience.select_visible(view)
	_check(ambience.active.size() == 8, "Low-cost continuity exceeded eight props")
	for prop in retained:
		_check(prop.rests == (0 if prop in ambience.active else 1), "Budget change resets a retained prop / fails to retire one")
	ambience.select_visible(Rect2(Vector2(10000, 10000), Vector2.ONE))
	for prop in retained: _check(prop.rests == 1 and prop.rotation == 0, "Leaving the view did not rest exactly once")
	_check(ambience.active.is_empty(), "Offscreen animation remains selected")

	var plant := preload("res://ForegroundGrowth.gd").new()
	room.add_child(plant)
	plant.configure("cave", 0, Vector2.ZERO, 12, Rect2(-80, 0, 160, 12))
	var vine := Sprite2D.new()
	vine.set_meta("wind_vine", true)
	room.add_child(vine)
	ambience.candidates.assign([plant, vine])
	ambience.select_visible(view)
	plant.animate(1.7)
	vine.rotation = 0.017
	var alpha: float = plant.echo.self_modulate.a
	var frame: int = plant.art.get_meta("atlas_frame")
	var shape: Transform2D = plant.global_transform
	ambience.select_visible(view)
	_check(plant.echo.self_modulate.a == alpha and plant.art.get_meta("atlas_frame") == frame,
		"Real grass breeze returns to frame zero on camera refresh")
	_check(plant.global_transform.is_equal_approx(shape) and is_equal_approx(vine.rotation, 0.017), "Retained grass/vine pose jumps")
	ambience.select_visible(Rect2(Vector2(10000, 10000), Vector2.ONE))
	_check(plant.rotation == 0 and plant.echo.self_modulate.a == 0 and vine.rotation == 0, "Actual foliage does not retire")
	room.free()
	state.delete_save()
	print("AMBIENT CONTINUITY TEST PASSED: retained poses, exact retirement, 18/8 budget, actual grass and vine" if failures.is_empty() else "AMBIENT CONTINUITY TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
