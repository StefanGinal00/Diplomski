extends Node2D

signal sequence_changed

const COMPLETION_EVENT := "shaft_cistern_pump"

var puzzle_progress: int = 0
var is_complete: bool = false

@onready var dials := [$NearDial, $HighDial, $FarDial]
@onready var sequence_hint: Label = $SequenceHint


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		is_complete = bool(game_state.unlocked_shortcuts.get(COMPLETION_EVENT, false))
		game_state.shortcut_changed.connect(_on_shortcut_changed)
	if is_complete:
		puzzle_progress = dials.size()
	_refresh()


func attempt_dial(dial_index: int, player: Player) -> bool:
	if is_complete or player == null or player.is_dead or dial_index < 0 or dial_index >= dials.size():
		return false
	if dial_index != puzzle_progress:
		puzzle_progress = 1 if dial_index == 0 else 0
		_refresh()
		sequence_changed.emit()
		return false
	puzzle_progress += 1
	if puzzle_progress == dials.size():
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.unlock_shortcut(COMPLETION_EVENT)
	_refresh()
	sequence_changed.emit()
	return true


func _on_shortcut_changed(shortcut_id: String) -> void:
	if shortcut_id != COMPLETION_EVENT:
		return
	is_complete = true
	puzzle_progress = dials.size()
	_refresh()
	sequence_changed.emit()


func _refresh() -> void:
	for dial in dials:
		dial.set_progress(puzzle_progress, is_complete)
	sequence_hint.text = "PUMP RUNNING  |  GALLERY PASSAGE OPEN" if is_complete else "PRESSURE ORDER: NEAR  >  HIGH  >  FAR  |  %d/3" % puzzle_progress
