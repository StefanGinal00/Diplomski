extends Node2D

signal sequence_changed

const COMPLETION_EVENT := "ash_chapel_bells"

var puzzle_progress: int = 0
var is_complete: bool = false

@onready var bells := [$HighBell, $LowBell, $FarBell]
@onready var sequence_hint: Label = $SequenceHint


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		is_complete = bool(game_state.unlocked_shortcuts.get(COMPLETION_EVENT, false))
		game_state.shortcut_changed.connect(_on_shortcut_changed)
	if is_complete:
		puzzle_progress = bells.size()
	_refresh()


func attempt_dial(bell_index: int, player: Player) -> bool:
	if is_complete or player == null or player.is_dead or bell_index < 0 or bell_index >= bells.size():
		return false
	if bell_index != puzzle_progress:
		puzzle_progress = 1 if bell_index == 0 else 0
		_refresh()
		sequence_changed.emit()
		return false
	puzzle_progress += 1
	if puzzle_progress == bells.size():
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
	puzzle_progress = bells.size()
	_refresh()
	sequence_changed.emit()


func _refresh() -> void:
	for bell in bells:
		bell.set_progress(puzzle_progress, is_complete)
	sequence_hint.text = "CHAPEL QUIET  |  RELIQUARY UNSEALED" if is_complete else "BELL ORDER: HIGH  >  LOW  >  FAR  |  %d/3" % puzzle_progress
