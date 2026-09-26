extends Area2D

@export_enum("shaft", "echo", "ash") var echo_id: String = "shaft"
@export var echo_name: String = "Dawn Echo"
@export var echo_color: Color = Color(0.66, 0.91, 1.0, 1.0)
@export_range(60.0, 300.0, 5.0) var threat_radius: float = 180.0
@export_range(0.5, 4.0, 0.1) var attune_seconds: float = 1.6

var nearby_player: Player
var age: float = 0.0
var quest_manager: Node
var game_state: Node
var attuning: bool = false
var attune_remaining: float = 0.0
var prompt_refresh_remaining: float = 0.0

@onready var halo: Line2D = $Halo
@onready var core: Polygon2D = $Core
@onready var name_label: Label = $NameLabel
@onready var prompt: Label = $Prompt
@onready var attune_bar: ProgressBar = $AttuneBar
@onready var echo_chime: AudioStreamPlayer2D = $EchoChime


func _ready() -> void:
	game_state = get_node_or_null("/root/GameState")
	quest_manager = get_tree().get_first_node_in_group("quest_manager")
	name_label.text = echo_name.to_upper()
	core.color = echo_color
	halo.default_color = echo_color
	attune_bar.max_value = attune_seconds
	attune_bar.hide()
	echo_chime.stream = _create_echo_chime()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if game_state != null:
		game_state.boss_progress_changed.connect(_on_boss_progress_changed)
		game_state.mode_changed.connect(_on_mode_changed)
	if quest_manager != null:
		quest_manager.quest_updated.connect(_refresh_visuals)
	call_deferred("_refresh_visuals")


func _process(delta: float) -> void:
	if not visible:
		return
	age += delta
	halo.rotation += delta * 0.3
	core.modulate.a = 0.72 + 0.22 * sin(age * 2.5)
	if attuning:
		if nearby_player == null or nearby_player.is_dead or nearby_player.global_position.distance_to(global_position) > 70.0 or _has_nearby_threat():
			_cancel_attunement()
			return
		attune_remaining = maxf(attune_remaining - delta, 0.0)
		attune_bar.value = attune_seconds - attune_remaining
		if is_zero_approx(attune_remaining):
			_complete_attunement()
		return
	if nearby_player != null:
		prompt_refresh_remaining = maxf(prompt_refresh_remaining - delta, 0.0)
		if is_zero_approx(prompt_refresh_remaining):
			prompt_refresh_remaining = 0.2
			_update_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or nearby_player.is_dead or not visible or event.is_echo() or not event.is_action_pressed("interact"):
		return
	if record():
		get_viewport().set_input_as_handled()


func record() -> bool:
	if game_state == null or quest_manager == null or nearby_player == null or nearby_player.is_dead or not bool(game_state.defeated_bosses.get("hollow_sovereign", false)) or quest_manager.is_dawn_echo_recorded(echo_id) or attuning:
		return false
	if nearby_player.global_position.distance_to(global_position) > 70.0 or _has_nearby_threat():
		_update_prompt()
		return false
	attuning = true
	attune_remaining = attune_seconds
	attune_bar.value = 0.0
	attune_bar.show()
	_update_prompt()
	return true


func _complete_attunement() -> void:
	attuning = false
	attune_bar.hide()
	if quest_manager.record_dawn_echo(echo_id):
		echo_chime.play()
	_refresh_visuals()


func _cancel_attunement() -> void:
	attuning = false
	attune_remaining = 0.0
	attune_bar.hide()
	_update_prompt()


func _has_nearby_threat() -> bool:
	for threat in get_tree().get_nodes_in_group("enemy"):
		if not threat is Node2D or not get_parent().is_ancestor_of(threat) or bool(threat.get("is_dead")):
			continue
		if global_position.distance_to(threat.global_position) <= threat_radius:
			return true
	return false


func _update_prompt() -> void:
	if quest_manager != null and quest_manager.is_dawn_echo_recorded(echo_id):
		prompt.text = "ECHO RECORDED"
	elif attuning:
		prompt.text = "LISTENING TO " + echo_name.to_upper()
	elif _has_nearby_threat():
		prompt.text = "DEFEAT NEARBY FOES"
	else:
		prompt.text = "[E] LISTEN TO " + echo_name.to_upper()
	prompt.visible = nearby_player != null


func _refresh_visuals() -> void:
	var available: bool = game_state != null and bool(game_state.defeated_bosses.get("hollow_sovereign", false))
	visible = available
	set_deferred("monitoring", available)
	if not available:
		_cancel_attunement()
		nearby_player = null
		prompt.hide()
		return
	var recorded: bool = quest_manager != null and quest_manager.is_dawn_echo_recorded(echo_id)
	if recorded and attuning:
		_cancel_attunement()
	core.modulate = Color(0.68, 0.72, 0.8, 0.65) if recorded else Color.WHITE
	halo.modulate.a = 0.3 if recorded else 0.9
	_update_prompt()


func _on_boss_progress_changed(boss_id: String) -> void:
	if boss_id == "hollow_sovereign":
		_refresh_visuals()


func _on_mode_changed(_mode: String) -> void:
	_refresh_visuals()


func _on_body_entered(body: Node) -> void:
	if body is Player and visible:
		nearby_player = body
		_update_prompt()


func _on_body_exited(body: Node) -> void:
	if body == nearby_player:
		_cancel_attunement()
		nearby_player = null
		prompt.hide()


func _create_echo_chime() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.38
	var sample_count := int(sample_rate * duration)
	var frequency := 493.9 if echo_id == "shaft" else (659.3 if echo_id == "echo" else 587.3)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / sample_rate
		var envelope := pow(1.0 - time / duration, 2.0)
		var sample := (sin(TAU * frequency * time) * 0.5 + sin(TAU * frequency * 1.5 * time) * 0.2) * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
