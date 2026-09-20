extends Area2D

@export var cache_id: String = ""
@export var cache_name: String = "Resonance Cache"
@export var gold_reward: int = 20
@export var reward_item_id: String = "ether_dust"
@export var required_event_ids: PackedStringArray = []

var nearby_player: Player
var opened: bool = false
var age: float = 0.0

@onready var lid: Polygon2D = $Lid
@onready var core: Polygon2D = $Core
@onready var prompt: Label = $Prompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var game_state := get_node_or_null("/root/GameState")
	opened = game_state != null and bool(game_state.opened_caches.get(cache_id, false))
	if game_state != null and not required_event_ids.is_empty():
		game_state.shortcut_changed.connect(_on_shortcut_changed)
	_refresh_visuals()
	prompt.hide()


func _process(delta: float) -> void:
	if opened:
		return
	age += delta
	core.modulate.a = 0.7 + sin(age * 3.4) * 0.25


func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or nearby_player.is_dead or event.is_echo() or not event.is_action_pressed("interact"):
		return
	open(nearby_player)
	get_viewport().set_input_as_handled()


func open(player: Player) -> bool:
	if opened or player == null or player.is_dead:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not _requirements_met(game_state) or not game_state.open_cache(cache_id):
		return false
	opened = true
	game_state.add_gold(gold_reward)
	if not reward_item_id.is_empty():
		game_state.add_item(reward_item_id)
	var weapon_class := str(game_state.get_item_definition(game_state.get_active_weapon_id()).get("weapon_class", "sword"))
	match weapon_class:
		"bow":
			game_state.add_item("ember_arrow", 2)
		"staff":
			game_state.add_item("ether_dust")
		_:
			game_state.add_item("healing_herb")
	_refresh_visuals()
	return true


func _refresh_visuals() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var sealed: bool = not opened and not _requirements_met(game_state)
	lid.position.y = -9.0 if opened else -2.0
	lid.rotation = -0.3 if opened else 0.0
	lid.color = Color(0.22, 0.42, 0.46, 1.0) if opened else (Color(0.42, 0.37, 0.63, 1.0) if sealed else Color(0.28, 0.82, 0.82, 1.0))
	core.visible = not opened and not sealed
	prompt.text = "CACHE EMPTY" if opened else ("SEALS %d/%d" % [required_event_ids.size() - _remaining_seals(game_state), required_event_ids.size()] if sealed else "[E] OPEN " + cache_name.to_upper())


func _requirements_met(game_state: Node) -> bool:
	return _remaining_seals(game_state) == 0


func _remaining_seals(game_state: Node) -> int:
	if game_state == null:
		return required_event_ids.size()
	var remaining := 0
	for event_id in required_event_ids:
		if not bool(game_state.unlocked_shortcuts.get(event_id, false)):
			remaining += 1
	return remaining


func _on_shortcut_changed(shortcut_id: String) -> void:
	if required_event_ids.has(shortcut_id):
		_refresh_visuals()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		nearby_player = body
		prompt.show()


func _on_body_exited(body: Node) -> void:
	if body == nearby_player:
		nearby_player = null
		prompt.hide()
