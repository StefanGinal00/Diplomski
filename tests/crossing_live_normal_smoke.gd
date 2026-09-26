extends "res://tests/crossing_live_route_pilot.gd"

# One connected base-room run from the lower Shaft entrance with starter
# sword/5 HP, no movement upgrades, two purchased herbs (36 setup Gold), and
# only acquired guaranteed cache herbs extending the healing budget. Actual
# combat, valve, detours, lift and door interactions; no mid-route placement.
# Not an awakened/campaign, pacifist, visual or human pacing measurement.
func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_crossing_live_normal_save.json"
	await _run_crossing()
