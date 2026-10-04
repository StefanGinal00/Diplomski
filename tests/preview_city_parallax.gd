extends "res://tests/preview_settlement_atmosphere.gd"

func _capture(file_name: String) -> void:
	await super._capture(file_name)
	if file_name!="atmosphere_parallax_bells": return
	var camera: Camera2D = current_scene.get_node("Player/Camera2D")
	var background: TextureRect = current_scene.get_node("WorldPresentationFinish").background
	var art := current_scene.get_node("StarfallCitadel/ParallaxArchitecture")
	var old_offset := camera.offset
	var before: Vector2 = background.camera_uv
	var before_center: Vector2 = art.camera_local
	camera.offset += Vector2(100,-60)
	camera.reset_smoothing()
	camera.force_update_scroll()
	background._process(0)
	art._process(0)
	if background.camera_uv.is_equal_approx(before) or art.camera_local.is_equal_approx(before_center):
		push_error("Native parallax did not follow camera travel")
		quit(1)
		return
	await super._capture(file_name+"_travel")
	print("NATIVE CITY PARALLAX MOTION ",art.camera_local-before_center,"; far UV ",background.camera_uv-before)
	camera.offset = old_offset
	camera.reset_smoothing()
	camera.force_update_scroll()
	background._process(0)
	art._process(0)

func _targets() -> Array:
	return [
		["starfall_citadel",Vector2(760,385),"parallax_gate"],
		["starfall_citadel",Vector2(2557,385),"parallax_square"],
		["starfall_citadel",Vector2(3990,385),"parallax_market_edge"],
		["starfall_citadel",Vector2(5050,385),"parallax_garden"],
		["starfall_citadel",Vector2(1800,-310),"parallax_artisans"],
		["starfall_citadel",Vector2(4620,-630),"parallax_upper_garden"],
		["starfall_citadel",Vector2(3260,-1090),"parallax_bells"],
		["starfall_citadel",Vector2(5520,-1610),"parallax_observatory"],
	]
