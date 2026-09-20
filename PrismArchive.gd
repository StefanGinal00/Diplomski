extends Node2D

signal puzzle_progress_changed(step: int, message: String)

const MIRROR_ORDER := ["root", "star", "echo"]
const COMPLETION_EVENT := "prism_archive_solved"

var step: int = 0
var solved: bool = false


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	solved = game_state != null and bool(game_state.unlocked_shortcuts.get(COMPLETION_EVENT, false))
	step = MIRROR_ORDER.size() if solved else 0
	_refresh_mirrors()


func activate_mirror(mirror_id: String) -> bool:
	if solved or not MIRROR_ORDER.has(mirror_id):
		return false
	if mirror_id != MIRROR_ORDER[step]:
		step = 0
		_refresh_mirrors()
		puzzle_progress_changed.emit(step, "THE MIRRORS FALL SILENT")
		return false
	step += 1
	if step == MIRROR_ORDER.size():
		var game_state := get_node_or_null("/root/GameState")
		if game_state == null:
			step = 0
			_refresh_mirrors()
			return false
		solved = true
		game_state.unlock_shortcut(COMPLETION_EVENT)
		_refresh_mirrors()
		puzzle_progress_changed.emit(step, "THE ARCHIVE REMEMBERS")
		if not game_state.has_item("memory_sigil_echo"):
			game_state.add_item("memory_sigil_echo")
		return true
	_refresh_mirrors()
	puzzle_progress_changed.emit(step, "MIRROR %d/3 ALIGNED" % step)
	return true


func _refresh_mirrors() -> void:
	for mirror_id in MIRROR_ORDER:
		var mirror := get_node_or_null(mirror_id.capitalize() + "Mirror")
		if mirror != null and mirror.has_method("set_lit"):
			mirror.set_lit(solved or MIRROR_ORDER.find(mirror_id) < step, solved)
