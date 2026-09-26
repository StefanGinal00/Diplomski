extends "res://tests/echo_grotto_live_pilot.gd"


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_echo_grotto_earned_route_save.json"
	await _run_crossing()
