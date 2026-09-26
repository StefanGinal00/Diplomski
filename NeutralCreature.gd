extends "res://Enemy.gd"

@export var creature_name: String = "Mossling"
@export var passive_tint: Color = Color(0.57, 0.8, 0.58, 1.0)
@export var hostile_tint: Color = Color(0.95, 0.48, 0.36, 1.0)
@export var passive_walk_speed: float = 18.0
@export var rest_seconds: float = 3.0
@export var wander_seconds: float = 4.0
@export var start_resting: bool = true
@export var wake_grace_seconds: float = 0.55

var is_hostile: bool = false
var resting: bool = true
var phase_remaining: float = 0.0
var grace_remaining: float = 0.0

@onready var sleep_label: Label = $SleepLabel
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	super._ready()
	resting = start_resting
	phase_remaining = maxf(rest_seconds if resting else wander_seconds, 0.1)
	default_sprite_modulate = passive_tint
	sprite.modulate = passive_tint.darkened(0.22) if resting else passive_tint
	name_label.text = creature_name
	sleep_label.visible = resting
	health_bar.hide()


func _physics_process(delta: float) -> void:
	if not is_hostile and not is_dead:
		phase_remaining -= delta
		if phase_remaining <= 0.0:
			resting = not resting
			phase_remaining = maxf(rest_seconds if resting else wander_seconds, 0.1)
			sleep_label.visible = resting
			sprite.modulate = passive_tint.darkened(0.22) if resting else passive_tint
	elif grace_remaining > 0.0:
		grace_remaining = maxf(grace_remaining - delta, 0.0)
		if is_zero_approx(grace_remaining):
			sleep_label.hide()
	super._physics_process(delta)


func _update_horizontal_movement() -> void:
	if not is_hostile:
		target_player = null
		velocity.x = 0.0 if resting else direction * passive_walk_speed
		return
	if grace_remaining > 0.0:
		velocity.x = 0.0
		return
	super._update_horizontal_movement()


func _on_awareness_area_body_entered(body: Node) -> void:
	if is_hostile:
		super._on_awareness_area_body_entered(body)


func _damage_player_if_possible(body: Node) -> bool:
	if not is_hostile or grace_remaining > 0.0:
		return false
	return super._damage_player_if_possible(body)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	if not is_hostile:
		_wake_up()
	super.take_damage(amount, knockback)


func _wake_up() -> void:
	is_hostile = true
	resting = false
	grace_remaining = wake_grace_seconds
	sleep_label.text = "!"
	sleep_label.show()
	health_bar.show()
	default_sprite_modulate = hostile_tint
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= 300.0:
		target_player = player


func restore_streamed_state(state: Dictionary) -> void:
	current_health = mini(int(state.get("current_health", max_health)), max_health)
	is_hostile = bool(state.get("is_hostile", false))
	resting = bool(state.get("resting", true))
	phase_remaining = maxf(float(state.get("phase_remaining", 0.1)), 0.1)
	grace_remaining = maxf(float(state.get("grace_remaining", 0.0)), 0.0)
	direction = float(state.get("direction", direction))
	health_bar.value = current_health
	health_bar.visible = is_hostile
	default_sprite_modulate = hostile_tint if is_hostile else passive_tint
	sprite.modulate = default_sprite_modulate if is_hostile or not resting else passive_tint.darkened(0.22)
	sleep_label.text = "!" if is_hostile and grace_remaining > 0.0 else "Z"
	sleep_label.visible = (not is_hostile and resting) or (is_hostile and grace_remaining > 0.0)
