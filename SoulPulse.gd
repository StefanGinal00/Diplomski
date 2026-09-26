extends "res://HeatVent.gd"


func _ready() -> void:
	super._ready()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		_on_zone_tier_changed("starfall_reach", game_state.get_zone_tier("starfall_reach"))


func _on_zone_tier_changed(zone_id: String, tier: int) -> void:
	if zone_id != "starfall_reach":
		return
	idle_duration = 1.35 if tier >= 1 else 1.8
	warning_duration = 0.7 if tier >= 1 else 0.9
	active_duration = 0.7 if tier >= 1 else 0.55


func _update_visuals() -> void:
	if disabled:
		flame.color = Color(0.28, 0.58, 0.5, 0.08)
		warning_line.default_color = Color(0.4, 0.8, 0.7, 0.18)
		warning_line.modulate.a = 1.0
		return
	match phase:
		"idle":
			flame.color = Color(0.55, 0.3, 0.76, 0.1)
			warning_line.default_color = Color(0.7, 0.48, 0.87, 0.28)
			warning_line.modulate.a = 1.0
		"warning":
			flame.color = Color(0.86, 0.46, 0.9, 0.3)
			warning_line.default_color = Color(1.0, 0.68, 0.95, 0.96)
		"active":
			flame.color = Color(0.86, 0.56, 1.0, 0.8)
			warning_line.default_color = Color(1.0, 0.88, 1.0, 1.0)
			warning_line.modulate.a = 1.0
