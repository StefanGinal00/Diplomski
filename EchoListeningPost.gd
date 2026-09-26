extends Area2D

signal heard(index: int)

var station_index := 0
var station_title := "LISTENING POST"
var room_id := "echo_grotto"
var threat_root: Node
var nearby_player: Player
var attuned := false
var listening := false
var remaining := 0.0
var starting_health := 0
const LISTEN_SECONDS := 1.2
const REACH := 42.0

@onready var prompt: Label = $InteractionPrompt
@onready var core: Polygon2D = $Core


func _ready() -> void:
	$StatusLabel.text = station_title
	$StatusLabel.position.x = -140
	$StatusLabel.size.x = 280
	prompt.position.x = -140
	prompt.size.x = 280
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.room_changed.connect(_on_room_changed)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or event.is_echo() or not event.is_action_pressed("interact"):
		return
	begin_listening()
	get_viewport().set_input_as_handled()


func begin_listening() -> bool:
	if attuned or listening or not _player_in_reach() or _has_threat():
		return false
	listening = true
	remaining = LISTEN_SECONDS
	starting_health = nearby_player.current_health
	_refresh()
	return true


func _player_in_reach() -> bool:
	return is_instance_valid(nearby_player) and not nearby_player.is_dead and nearby_player.global_position.distance_to(global_position) <= REACH


func _has_threat() -> bool:
	return _nearest_threat() != null


func _nearest_threat() -> Node2D:
	var nearest: Node2D
	var distance := 155.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and threat_root != null and threat_root.is_ancestor_of(enemy) and not bool(enemy.get("is_dead")):
			var separation: float = enemy.global_position.distance_to(global_position)
			if separation < distance:
				nearest = enemy
				distance = separation
	return nearest


func _threat_hint(threat: Node2D) -> String:
	# Raised listening rooms can be blocked by a patrol in the corridor below.
	# Tell the player where to look without changing the encounter requirement.
	var offset := threat.global_position - global_position
	if absf(offset.y) > maxf(40.0, absf(offset.x)):
		return "CLEAR FOES BELOW" if offset.y > 0 else "CLEAR FOES ABOVE"
	if absf(offset.x) > 24.0:
		return "CLEAR FOES TO THE RIGHT" if offset.x > 0 else "CLEAR FOES TO THE LEFT"
	return "CLEAR NEARBY FOES"


func _process(delta: float) -> void:
	if listening:
		if not _player_in_reach() or nearby_player.current_health < starting_health or _has_threat():
			listening = false
		else:
			remaining = maxf(0.0, remaining - delta)
			if is_zero_approx(remaining):
				listening = false
				heard.emit(station_index)
	if nearby_player != null or listening:
		_refresh()


func set_attuned(value: bool) -> void:
	attuned = value
	listening = false
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	core.color = Color(0.35, 0.96, 0.75) if attuned else Color(0.53, 0.65, 1.0)
	$Glow.color = Color(core.color, 0.24)
	prompt.visible = nearby_player != null
	if attuned:
		prompt.text = "RECORD ATTUNED"
	elif listening:
		prompt.text = "LISTENING %d%%" % int(100.0 * (1.0 - remaining / LISTEN_SECONDS))
	else:
		var threat := _nearest_threat() if nearby_player != null else null
		prompt.text = _threat_hint(threat) if threat != null else "[E] LISTEN - STAY CLOSE"


func _on_room_changed(next_room: String) -> void:
	if next_room != room_id:
		listening = false
		nearby_player = null
		_refresh()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		nearby_player = body
		_refresh()


func _on_body_exited(body: Node) -> void:
	if body == nearby_player:
		listening = false
		nearby_player = null
		_refresh()
