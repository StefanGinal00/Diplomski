extends "res://tests/hollow_live_route_pilot.gd"

# One connected base-room run with normal 5 HP, starter sword, no movement
# upgrades and all actors/hazards live. Preparation buys two herbs for 36 Gold;
# acquired guaranteed cache herbs extend that allowance. Random loot is counted
# but cannot raise the healing budget, so survival must not depend on lucky drops.
# This is NOT a no-healing run, awakened campaign or human pacing measurement.
# CLI diagnostic flags cannot raise this wrapper's health or switch its tier.
func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hollow_live_normal_save.json"
	diagnostic_health = 5
	awakened_fixture = false
	await _run_route()
