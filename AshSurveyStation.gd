extends "res://SluiceValve.gd"

var required_event_ids := PackedStringArray()
var locked_hint := "LIGHT THE PREVIOUS SIGNAL FIRST"
var threat_root: Node


func _requirements_met() -> bool:
	var state := get_node_or_null("/root/GameState")
	for event_id in required_event_ids:
		if state == null or not bool(state.unlocked_shortcuts.get(event_id, false)):
			return false
	return true


func _has_threat() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and is_instance_valid(threat_root) and threat_root.is_ancestor_of(enemy) and not bool(enemy.get("is_dead")) and enemy.global_position.distance_to(global_position) < 155:
			return true
	return false


func activate(player: Player) -> bool:
	if player == null or player.is_dead or player.global_position.distance_to(global_position) > 48 or not _requirements_met() or _has_threat():
		_update_visuals()
		return false
	return super.activate(player)


func _process(delta: float) -> void:
	super._process(delta)
	if player_in_range != null:
		_update_visuals()


func _on_shortcut_changed(event_id: String) -> void:
	super._on_shortcut_changed(event_id)
	if required_event_ids.has(event_id):
		_update_visuals()


func _update_visuals() -> void:
	super._update_visuals()
	if not is_active:
		if not _requirements_met():
			interaction_prompt.text = locked_hint
		elif player_in_range != null and _has_threat():
			interaction_prompt.text = "CLEAR NEARBY FOES FIRST"
