extends "res://HeatVent.gd"


func _ready() -> void:
	super._ready()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		_on_zone_tier_changed(zone_id_for_snare(), game_state.get_zone_tier(zone_id_for_snare()))


func zone_id_for_snare() -> String:
	return "starfall_reach"


func _on_zone_tier_changed(changed_zone_id: String, tier: int) -> void:
	if changed_zone_id != zone_id_for_snare():
		return
	idle_duration = 1.45 if tier >= 1 else 2.0
	warning_duration = 0.7 if tier >= 1 else 0.9
	active_duration = 0.65 if tier >= 1 else 0.55


func _update_visuals() -> void:
	if disabled:
		flame.color = Color(0.18, 0.4, 0.28, 0.08)
		warning_line.default_color = Color(0.38, 0.6, 0.42, 0.18)
		warning_line.modulate.a = 1.0
		return
	match phase:
		"idle":
			flame.color = Color(0.26, 0.55, 0.32, 0.12)
			warning_line.default_color = Color(0.5, 0.74, 0.43, 0.3)
			warning_line.modulate.a = 1.0
		"warning":
			flame.color = Color(0.76, 0.7, 0.28, 0.3)
			warning_line.default_color = Color(1.0, 0.8, 0.35, 0.95)
		"active":
			flame.color = Color(0.61, 0.91, 0.36, 0.78)
			warning_line.default_color = Color(0.9, 1.0, 0.55, 1.0)
			warning_line.modulate.a = 1.0
