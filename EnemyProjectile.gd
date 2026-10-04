extends Area2D

@export var speed: float = 125.0
@export var damage: int = 1
@export var lifetime: float = 4.0
@export var max_range: float = 400.0
@export var player_knockback: float = 120.0

var direction: Vector2 = Vector2.LEFT
var source: Node
var spent := false
var distance_travelled := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visibility_changed.connect(_on_visibility_changed)
	var state := get_node_or_null("/root/GameState")
	if state != null:
		state.room_changed.connect(_retire)
		state.checkpoint_resting.connect(_retire)
	var transition := get_node_or_null("/root/RoomTransition")
	if transition != null:
		transition.transition_started.connect(_retire)
		if transition.is_transitioning:
			_retire()
	if not is_visible_in_tree():
		_retire()

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_retire()

func _retire(_unused: String = "") -> void:
	spent = true
	hide()
	set_deferred("monitoring", false)
	queue_free()


func setup(new_direction: Vector2, projectile_source: Node) -> void:
	if spent or is_queued_for_deletion():
		return
	direction = new_direction.normalized()
	source = projectile_source
	global_rotation = direction.angle()
	if is_instance_valid(source) and not has_node("BossProjectileArt"):
		var art := preload("res://BossProjectileAppearance.gd").new()
		art.name = "BossProjectileArt"
		if source.has_node("CombatPresentation"):
			art.tint = source.get_node("CombatPresentation").tint
			art.style = source.boss_id
		else:
			art.tint = Color("e66b69")
			art.style = "ranged"
			if source.has_node("WarningRay"):
				art.style = "sentry"
				art.tint = source.projectile_color
				art.awakened = source.zone_tier >= 1
				if source.projectile_color.r > source.projectile_color.b:
					art.style = "ash_sentry"
		add_child(art)


func _physics_process(delta: float) -> void:
	if spent or is_queued_for_deletion():
		return
	var step := minf(maxf(speed * delta, 0.0), maxf(max_range - distance_travelled, 0.0))
	distance_travelled += preload("res://ProjectileTravel.gd").advance(self,step)
	lifetime -= delta
	if lifetime <= 0.0 or distance_travelled >= max_range:
		_retire()


func _on_body_entered(body: Node) -> void:
	if body == source or spent or is_queued_for_deletion():
		return
	# Reserve the single impact immediately; multiple body_entered signals can
	# arrive before deferred deletion at the end of this physics step.
	spent = true
	var art := get_node_or_null("BossProjectileArt")
	if art != null:
		art.impact()
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(
			damage,
			Vector2(direction.x * player_knockback, -80.0)
		)
	_retire()
