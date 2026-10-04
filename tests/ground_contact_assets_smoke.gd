extends "res://tests/audit_ground_contacts.gd"
var checked_frames := 0

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ground_contact_assets.json"
	state.start_new_game("normal")
	for script in [preload("res://CrawlerAppearance.gd"), preload("res://EchoGrazerAppearance.gd")]:
		_verify(script.SHEET, 3, 2, script.CONTACT_ROWS)
	var player_art := preload("res://PlayerAppearance.gd")
	_verify(player_art.SHEET, 3, 2, player_art.GROUND_ROWS)
	_verify(player_art.COMBAT_SHEET, 3, 2, player_art.COMBAT_GROUND_ROWS)
	_verify(player_art.MOVEMENT_SHEET, 2, 2, [604, -1, -1, 533])
	_verify(preload("res://RangedAppearance.gd").SHEET, 2, 2, preload("res://RangedAppearance.gd").CONTACT_ROWS)
	for script in [preload("res://EchoGuideAppearance.gd"), preload("res://EchoFaunaAppearance.gd")]:
		for key in script.CONTACT_ROWS: _verify(script.SHEETS[key], 2, 2, script.CONTACT_ROWS[key])
	var mob_art := preload("res://CompactMobAppearance.gd")
	var rows: Array = []
	for key in ["enemy", "fiend", "root"]: rows.append_array(mob_art.CONTACT_ROWS[key])
	_verify(mob_art.SHEET, 6, 4, rows)
	for script in [preload("res://CavernDressingArt.gd"), preload("res://OpeningResidentArt.gd")]:
		var pixels: Image = script.SHEET.get_image()
		var rects: Array = script.RECTS if script == preload("res://CavernDressingArt.gd") else script.REGIONS
		for index in rects.size():
			_check(_bottom(pixels, Rect2i(rects[index])) == script.CONTACT_ROWS[index], "Prop alpha-foot metadata stale: " + script.SHEET.resource_path + " " + str(index))
			checked_frames += 1
	state.delete_save()
	if failures.is_empty(): print("GROUND CONTACT ASSETS TEST PASSED: ", checked_frames, " baked opaque contact rows verified against actual imported pixels; airborne poses excluded")
	else: print("GROUND CONTACT ASSETS TEST FAILED: ", failures)
	quit(0 if failures.is_empty() else 1)

func _verify(tex: Texture2D, columns: int, rows: int, contacts: Array) -> void:
	var pixels := tex.get_image()
	var size := pixels.get_size() / Vector2i(columns, rows)
	for index in contacts.size():
		if contacts[index] < 0: continue
		var rect := Rect2i(Vector2i(index % columns, index / columns) * size, size)
		_check(_bottom(pixels, rect) == contacts[index], "Actor alpha-foot metadata stale: " + tex.resource_path + " " + str(index))
		checked_frames += 1
