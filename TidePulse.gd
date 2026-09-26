extends Area2D

@export var idle_duration: float = 1.7
@export var warning_duration: float = 0.7
@export var active_duration: float = 0.55
@export var damage: int = 1
@export var zone_id: String = "echo_grotto"
@export var disabled_by_shortcut_id: String = ""
@export var additional_disabled_event_ids: PackedStringArray = []
@export var knockback: Vector2 = Vector2(0.0, -175.0)

var phase: String = "idle"
var phase_remaining: float = 1.0
var hit_players: Dictionary = {}
var disabled: bool = false

@onready var water: Polygon2D = $Water
@onready var crest: Line2D = $Crest


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.zone_tier_changed.connect(_on_zone_tier_changed)
		game_state.shortcut_changed.connect(_on_shortcut_changed)
		_on_zone_tier_changed(zone_id, game_state.get_zone_tier(zone_id))
		disabled = not disabled_by_shortcut_id.is_empty() and bool(game_state.unlocked_shortcuts.get(disabled_by_shortcut_id, false))
		for event_id in additional_disabled_event_ids:
			disabled = disabled or bool(game_state.unlocked_shortcuts.get(event_id, false))
	phase_remaining = idle_duration
	monitoring = false
	_update_visuals()


func _on_zone_tier_changed(zone_id: String, tier: int) -> void:
	if zone_id != self.zone_id:
		return
	idle_duration = 1.15 if tier >= 1 else 1.7
	warning_duration = 0.58 if tier >= 1 else 0.7
	active_duration = 0.68 if tier >= 1 else 0.55


func _process(delta: float) -> void:
	if disabled:
		return
	phase_remaining -= delta
	if phase_remaining <= 0.0:
		_advance_phase()
	if phase == "active" and monitoring:
		for body in get_overlapping_bodies():
			if body is Player and not body.is_dead:
				var game_state := get_node_or_null("/root/GameState")
				if game_state != null and game_state.get_equipped_defense_id() == "tideguard_mantle":
					continue
				var player_id := body.get_instance_id()
				if not hit_players.has(player_id):
					hit_players[player_id] = true
					body.take_damage(damage, knockback)
	if phase == "warning":
		crest.modulate.a = 0.48 + sin(Time.get_ticks_msec() * 0.023) * 0.35


func _advance_phase() -> void:
	match phase:
		"idle":
			phase = "warning"
			phase_remaining = warning_duration
		"warning":
			phase = "active"
			phase_remaining = active_duration
			hit_players.clear()
			set_deferred("monitoring", true)
		"active":
			phase = "idle"
			phase_remaining = idle_duration
			set_deferred("monitoring", false)
	_update_visuals()


func _on_shortcut_changed(shortcut_id: String) -> void:
	if (shortcut_id != disabled_by_shortcut_id and not additional_disabled_event_ids.has(shortcut_id)) or disabled:
		return
	disabled = true
	phase = "disabled"
	hit_players.clear()
	set_deferred("monitoring", false)
	_update_visuals()


func _update_visuals() -> void:
	if disabled:
		water.color = Color(0.13, 0.35, 0.42, 0.07)
		crest.default_color = Color(0.29, 0.68, 0.67, 0.24)
		crest.modulate.a = 1.0
		return
	match phase:
		"idle":
			water.color = Color(0.14, 0.46, 0.63, 0.11)
			crest.default_color = Color(0.35, 0.76, 0.9, 0.18)
		"warning":
			water.color = Color(0.22, 0.68, 0.87, 0.27)
			crest.default_color = Color(0.63, 0.97, 1.0, 0.86)
		"active":
			water.color = Color(0.32, 0.82, 1.0, 0.69)
			crest.default_color = Color(0.88, 1.0, 1.0, 1.0)
			crest.modulate.a = 1.0
