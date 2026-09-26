extends Area2D

@export var speed: float = 430.0
@export var lifetime: float = 1.4
@export var knockback_force: float = 120.0

var direction: Vector2 = Vector2.RIGHT
var source: Node
var damage: int = 1
var arrow_type: String = "basic_arrow"
var weapon_id: String = "hunter_bow"
var remaining_hits: int = 1
var hit_targets: Dictionary = {}
var pending_hits: int = 0
var stopped: bool = false

@onready var trail: Polygon2D = $Trail
@onready var head: Polygon2D = $Head


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2, projectile_source: Node, new_arrow_type: String = "basic_arrow", damage_bonus: int = 0, pierce_count: int = 0, new_weapon_id: String = "hunter_bow", base_weapon_damage: int = 1, max_range: float = 520.0) -> void:
	direction = new_direction.normalized()
	source = projectile_source
	arrow_type = new_arrow_type
	weapon_id = new_weapon_id
	damage = maxi(base_weapon_damage, 1) + (1 if arrow_type == "ember_arrow" else 0) + damage_bonus
	remaining_hits = 1 + maxi(pierce_count, 0) if arrow_type == "basic_arrow" else 1
	rotation = direction.angle()
	if arrow_type == "ember_arrow":
		head.color = Color(1.0, 0.3, 0.08, 1.0)
		trail.color = Color(1.0, 0.55, 0.1, 0.72)
		speed = 470.0
	elif weapon_id == "thorn_bow":
		head.color = Color(0.52, 1.0, 0.55, 1.0)
		trail.color = Color(0.24, 0.8, 0.35, 0.72)
	lifetime = maxf(max_range / speed, 0.1)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == source or stopped or is_queued_for_deletion():
		return
	if (body.is_in_group("enemy") or body.is_in_group("neutral_creature") or body.is_in_group("breakable")) and body.has_method("take_damage"):
		var target_id := body.get_instance_id()
		if hit_targets.has(target_id) or pending_hits >= remaining_hits:
			return
		hit_targets[target_id] = true
		# Reserve the hit now: several bodies can enter before deferred damage
		# and monitoring changes run at the end of the physics step.
		pending_hits += 1
		set_deferred("monitoring", false)
		if pending_hits >= remaining_hits:
			visible = false
		call_deferred("_resolve_hit", body)
		return
	stopped = true
	set_deferred("monitoring", false)
	visible = false
	queue_free()


func _resolve_hit(body: Node) -> void:
	if is_instance_valid(body):
		var game_state := get_node_or_null("/root/GameState")
		var target_bonus: int = game_state.get_weapon_target_bonus(weapon_id, body) if game_state != null else 0
		body.take_damage(damage + target_bonus, direction * knockback_force + Vector2(0.0, -35.0))
	pending_hits -= 1
	remaining_hits -= 1
	if remaining_hits <= 0:
		stopped = true
		queue_free()
	elif pending_hits == 0 and not stopped:
		global_position += direction * 12.0
		set_deferred("monitoring", true)
