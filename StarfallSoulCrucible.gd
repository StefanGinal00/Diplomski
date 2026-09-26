extends Node2D

const HIGH_CHANNEL := "starfall_crucible_high"
const LOW_CHANNEL := "starfall_crucible_low"
const STABILIZED := "starfall_crucible_stabilized"

@onready var conduit: Line2D = $Conduit
@onready var heart: Polygon2D = $Heart
@onready var circuit_status: Label = $CircuitStatus


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.shortcut_changed.connect(_on_shortcut_changed)
		if _channel_count(game_state) == 2 and not bool(game_state.unlocked_shortcuts.get(STABILIZED, false)):
			game_state.unlock_shortcut(STABILIZED)
	_refresh()


func _on_shortcut_changed(event_id: String) -> void:
	if event_id not in [HIGH_CHANNEL, LOW_CHANNEL, STABILIZED]:
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if event_id != STABILIZED and _channel_count(game_state) == 2:
		game_state.unlock_shortcut(STABILIZED)
	_refresh()


func _channel_count(game_state: Node) -> int:
	return int(bool(game_state.unlocked_shortcuts.get(HIGH_CHANNEL, false))) + int(bool(game_state.unlocked_shortcuts.get(LOW_CHANNEL, false)))


func _refresh() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var count := _channel_count(game_state) if game_state != null else 0
	var stable := game_state != null and bool(game_state.unlocked_shortcuts.get(STABILIZED, false))
	circuit_status.text = "SOUL FLOW STABLE - PULSES QUIET" if stable else "SOUL CHANNELS %d/2 - PULSES ACTIVE" % count
	conduit.default_color = Color(0.39, 0.96, 0.8, 0.65) if stable else Color(0.77, 0.44, 0.95, 0.45)
	heart.color = Color(0.38, 0.94, 0.78, 0.84) if stable else Color(0.72, 0.45, 0.91, 0.65)
