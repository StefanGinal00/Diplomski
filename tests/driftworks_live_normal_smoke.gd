extends "res://tests/driftworks_live_route_pilot.gd"

# Normal 5 HP, starter sword, no movement upgrades and two herbs purchased
# using a disclosed 36-Gold setup allowance. Only guaranteed cache herbs extend
# the healing budget. Room actors/hazards stay live; no artificial kills.
# One entrance placement, then real movement and lift/door interactions.
# The final snapshot reload is persistence coverage, not another traversal.
# This is a base-room test, NOT an awakened/campaign or human pacing claim.
func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_driftworks_live_normal_save.json"
	await _run_driftworks()
