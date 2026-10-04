extends "res://tests/preview_settlement_atmosphere.gd"
## Uses the same isolated-save, actual-physics native camera review harness.
func _targets() -> Array:
	return [
		["echo_haven",Vector2(420,150),"facade_echo_court"],
		["echo_haven",Vector2(1480,150),"facade_echo_gate"],
		["echo_haven_outskirts",Vector2(1890,180),"facade_echo_road"],
		["ash_hearth",Vector2(1550,370),"facade_foundry"],
		["ash_hearth",Vector2(2040,370),"facade_inn"],
		["starfall_citadel",Vector2(2420,385),"facade_city_street"],
		["starfall_citadel",Vector2(3595,385),"facade_market"],
		["starfall_citadel",Vector2(2520,-1090),"facade_bell_house"],
		["starfall_citadel",Vector2(3260,-1090),"facade_bells"],
		["starfall_citadel",Vector2(5520,-1610),"facade_telescope"],
	]
