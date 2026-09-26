extends Area2D

signal interaction_requested(npc: Area2D)

@export var resident_name: String = "Resident"
@export var dialogue_lines: PackedStringArray = ["The roads beyond the gate are dangerous. Rest here a while."]
@export var timeline_dialogue_stage: int = -1
@export var timeline_dialogue_lines: PackedStringArray = []
@export var victory_dialogue_lines: PackedStringArray = []
@export var route_marker_names: PackedStringArray = []
@export var talk_partner: NodePath
@export var social_lines: PackedStringArray = []
@export var victory_social_lines: PackedStringArray = []
@export_range(10.0, 90.0, 1.0) var walk_speed: float = 30.0
@export_range(0.5, 6.0, 0.1) var pause_seconds: float = 1.4
@export_range(1.0, 6.0, 0.1) var indoor_seconds: float = 2.3
@export var coat_color: Color = Color(0.35, 0.44, 0.58, 1.0)
@export var accent_color: Color = Color(0.72, 0.83, 0.9, 1.0)

var player_in_range: Player
var next_line_index: int = 0
var current_dialogue_set: int = -1
var social_line_index: int = 0
var route_markers: Array[Marker2D] = []
var route_index: int = 0
var current_stop_marker: Marker2D
var pause_remaining: float = 0.5
var indoor_state: String = ""
var indoor_timer: float = 0.0
var social_remaining: float = 0.0
var social_cooldown: float = 0.0
var social_partner: Area2D
var social_initiator: bool = false
var social_reply_started: bool = false
var player_dialogue_active: bool = false

@onready var coat: Polygon2D = $Coat
@onready var accent: Polygon2D = $Accent
@onready var name_label: Label = $NameLabel
@onready var prompt: Label = $InteractionPrompt
@onready var social_bubble: Label = $SocialBubble
@onready var bubble_backdrop: ColorRect = $BubbleBackdrop


func _ready() -> void:
	name_label.text = resident_name
	coat.color = coat_color
	accent.color = accent_color
	prompt.hide()
	social_bubble.hide()
	bubble_backdrop.hide()
	for marker_name in route_marker_names:
		var marker := get_parent().get_node_or_null(str(marker_name)) as Marker2D
		if marker == null:
			push_warning("Town resident route marker missing: %s" % marker_name)
			continue
		route_markers.append(marker)
	pause_remaining += fposmod(position.x * 0.013, 0.7)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	accent.modulate.a = 0.86 + 0.14 * sin(Time.get_ticks_msec() * 0.002 + position.x)
	social_cooldown = maxf(social_cooldown - delta, 0.0)
	if not indoor_state.is_empty():
		_update_interior(delta)
		return
	if social_remaining > 0.0:
		_update_social(delta)
		return
	if route_markers.is_empty() or player_in_range != null or player_dialogue_active:
		return
	if pause_remaining > 0.0:
		pause_remaining = maxf(pause_remaining - delta, 0.0)
		_try_social_exchange()
		return
	current_stop_marker = null
	var target: Marker2D = route_markers[route_index]
	position = position.move_toward(target.position, walk_speed * delta)
	if position.distance_to(target.position) > 1.0:
		return
	position = target.position
	current_stop_marker = target
	if target.is_in_group("town_interior"):
		indoor_state = "entering"
		indoor_timer = 0.3
		return
	pause_remaining = pause_seconds + (1.3 if target.is_in_group("town_social_spot") else 0.0)
	route_index = (route_index + 1) % route_markers.size()
	_try_social_exchange()


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or player_dialogue_active or not indoor_state.is_empty() or event.is_echo() or not event.is_action_pressed("interact"):
		return
	interaction_requested.emit(self)
	get_viewport().set_input_as_handled()


func set_player_dialogue_active(active: bool) -> void:
	player_dialogue_active = active
	if active:
		_end_social_exchange(true)


func _update_interior(delta: float) -> void:
	indoor_timer -= delta
	match indoor_state:
		"entering":
			modulate.a = clampf(indoor_timer / 0.3, 0.0, 1.0)
			if indoor_timer <= 0.0:
				modulate.a = 0.0
				hide()
				set_deferred("monitoring", false)
				indoor_state = "inside"
				indoor_timer = indoor_seconds
		"inside":
			if indoor_timer <= 0.0:
				show()
				set_deferred("monitoring", true)
				indoor_state = "exiting"
				indoor_timer = 0.3
		"exiting":
			modulate.a = clampf(1.0 - indoor_timer / 0.3, 0.0, 1.0)
			if indoor_timer <= 0.0:
				modulate.a = 1.0
				indoor_state = ""
				current_stop_marker = null
				route_index = (route_index + 1) % route_markers.size()
				pause_remaining = 0.4


func _try_social_exchange() -> void:
	if current_stop_marker == null or not current_stop_marker.is_in_group("town_social_spot") or social_cooldown > 0.0 or talk_partner.is_empty():
		return
	var partner := get_node_or_null(talk_partner) as Area2D
	if partner == null or not partner.has_method("_receive_social_exchange") or partner.get("social_remaining") > 0.0:
		return
	var partner_stop := partner.get("current_stop_marker") as Marker2D
	if partner_stop == null or not partner_stop.is_in_group("town_social_spot") or global_position.distance_to(partner.global_position) > 110.0:
		return
	if partner.get("player_in_range") != null or partner.get("player_dialogue_active") or partner.get("indoor_state") != "" or partner.get("social_cooldown") > 0.0:
		return
	social_partner = partner
	social_initiator = true
	social_reply_started = false
	social_remaining = 3.4
	social_cooldown = 7.0
	pause_remaining = maxf(pause_remaining, 3.5)
	_show_social_line()
	partner.call("_receive_social_exchange", self)


func _receive_social_exchange(partner: Area2D) -> void:
	social_partner = partner
	social_initiator = false
	social_reply_started = false
	social_remaining = 3.4
	social_cooldown = 7.0
	pause_remaining = maxf(pause_remaining, 3.5)
	social_bubble.hide()
	bubble_backdrop.hide()


func _update_social(delta: float) -> void:
	social_remaining = maxf(social_remaining - delta, 0.0)
	if social_initiator and not social_reply_started and social_remaining <= 1.7:
		social_reply_started = true
		social_bubble.hide()
		bubble_backdrop.hide()
		if is_instance_valid(social_partner):
			social_partner.call("_show_social_line")
	if social_remaining <= 0.0:
		_end_social_exchange(true)


func _show_social_line() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var victory: bool = game_state != null and bool(game_state.defeated_bosses.get("hollow_sovereign", false))
	var active_social_lines: PackedStringArray = victory_social_lines if victory and not victory_social_lines.is_empty() else social_lines
	if active_social_lines.is_empty():
		social_bubble.text = "Good to see you."
	else:
		social_bubble.text = active_social_lines[social_line_index % active_social_lines.size()]
		social_line_index += 1
	social_bubble.show()
	bubble_backdrop.show()


func _end_social_exchange(cancel_partner: bool) -> void:
	social_remaining = 0.0
	social_bubble.hide()
	bubble_backdrop.hide()
	var partner := social_partner
	social_partner = null
	if cancel_partner and is_instance_valid(partner):
		partner.call("_end_social_exchange", false)


func get_next_line() -> String:
	var game_state := get_node_or_null("/root/GameState")
	var use_victory_lines: bool = game_state != null and bool(game_state.defeated_bosses.get("hollow_sovereign", false)) and not victory_dialogue_lines.is_empty()
	var use_timeline_lines: bool = game_state != null and timeline_dialogue_stage >= 0 and game_state.timeline_stage >= timeline_dialogue_stage and not timeline_dialogue_lines.is_empty()
	var dialogue_set := 100 if use_victory_lines else (timeline_dialogue_stage if use_timeline_lines else 0)
	if current_dialogue_set != dialogue_set:
		current_dialogue_set = dialogue_set
		next_line_index = 0
	var active_lines: PackedStringArray = victory_dialogue_lines if use_victory_lines else (timeline_dialogue_lines if use_timeline_lines else dialogue_lines)
	if active_lines.is_empty():
		return "It's good to have company."
	var line: String = active_lines[next_line_index % active_lines.size()]
	next_line_index += 1
	return line


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = body
		_end_social_exchange(true)
		prompt.show()


func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		prompt.hide()
