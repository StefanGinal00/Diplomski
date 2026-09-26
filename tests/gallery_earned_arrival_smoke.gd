extends "res://tests/gallery_live_route_pilot.gd"


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_gallery_earned_arrival_save.json"
	earned_arrival = true
	await _run_crossing()
