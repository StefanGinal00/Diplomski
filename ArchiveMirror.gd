extends Area2D

@export var mirror_id: String = "root"
@export var mirror_name: String = "ROOT"

var player_in_range: Player
var age: float = 0.0
var is_lit: bool = false
var is_solved: bool = false

@onready var core: Polygon2D = $Core
@onready var halo: Polygon2D = $Halo
@onready var prompt: Label = $Prompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()
	_update_visuals()


func _process(delta: float) -> void:
	age += delta
	halo.modulate.a = 0.58 + sin(age * 3.0) * 0.24


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or player_in_range.is_dead or event.is_echo() or not event.is_action_pressed("interact"):
		return
	activate(player_in_range)
	get_viewport().set_input_as_handled()


func activate(player: Player) -> bool:
	if player == null or player.is_dead or is_solved:
		return false
	var archive := get_parent()
	if archive == null or not archive.has_method("activate_mirror"):
		return false
	return archive.activate_mirror(mirror_id)


func set_lit(lit: bool, solved: bool) -> void:
	is_lit = lit
	is_solved = solved
	_update_visuals()


func _update_visuals() -> void:
	if core == null or halo == null or prompt == null:
		return
	core.color = Color(0.65, 1.0, 0.83, 1.0) if is_lit else Color(0.37, 0.55, 0.93, 1.0)
	halo.color = Color(0.28, 1.0, 0.78, 0.35) if is_lit else Color(0.34, 0.62, 1.0, 0.28)
	prompt.text = "MIRROR ALIGNED" if is_solved else "[E] %s MIRROR" % mirror_name.to_upper()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		prompt.show()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		prompt.hide()
