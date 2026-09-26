extends "res://tests/shaft_final_rooms_pilot.gd"


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_cistern_earned_route_save.json"
	final_kind = "cistern"
	earned_arrival = true
	await _run_crossing()
