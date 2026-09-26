extends "res://Enemy.gd"

var applied_tier: int = 0


func _ready() -> void:
	super._ready()
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	_apply_tier(game_state.get_zone_tier(zone_id))
	game_state.zone_tier_changed.connect(_on_zone_tier_changed)


func _on_zone_tier_changed(changed_zone_id: String, tier: int) -> void:
	if changed_zone_id == zone_id and not is_dead:
		_apply_tier(tier)


func _apply_tier(tier: int) -> void:
	if tier <= applied_tier:
		return
	var increase := tier - applied_tier
	applied_tier = tier
	max_health += increase
	current_health += increase
	chase_speed += 12.0 * increase
	gold_reward += 3 * increase
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
