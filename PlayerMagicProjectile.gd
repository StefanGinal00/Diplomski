extends Area2D

@export var lifetime: float = 1.7

var direction: Vector2 = Vector2.RIGHT
var source: Node
var spell_id: String = "arc_bolt"
var weapon_id: String = "apprentice_staff"
var damage: int = 2
var speed: float = 345.0
var remaining_hits: int = 1
var hit_targets: Dictionary = {}
var pending_hits: int = 0
var stopped: bool = false

@onready var aura: Polygon2D = $Aura
@onready var core: Polygon2D = $Core


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2, projectile_source: Node, new_spell_id: String, damage_bonus: int = 0, new_weapon_id: String = "apprentice_staff", base_weapon_damage: int = 2, max_range: float = 440.0) -> void:
	direction = new_direction.normalized()
	source = projectile_source
	spell_id = new_spell_id
	weapon_id = new_weapon_id
	if spell_id == "frost_orb":
		damage = maxi(base_weapon_damage - 1, 1) + damage_bonus
		speed = 230.0
		remaining_hits = 2
		aura.color = Color(0.25, 0.75, 1.0, 0.32)
		core.color = Color(0.62, 0.94, 1.0, 1.0)
		scale = Vector2(1.25, 1.25)
	else:
		damage = maxi(base_weapon_damage, 1) + damage_bonus
		speed = 345.0
		remaining_hits = 1
		if weapon_id == "sunder_staff":
			aura.color = Color(1.0, 0.22, 0.52, 0.32)
			core.color = Color(1.0, 0.62, 0.74, 1.0)
	lifetime = maxf(max_range / speed, 0.1)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	aura.rotation += delta * 5.5
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
		# Reserve each contact before deferred damage resolves, so overlapping
		# enemies cannot exceed this spell's single-hit / piercing budget.
		pending_hits += 1
		set_deferred("monitoring", false)
		if pending_hits >= remaining_hits:
			visible = false
		call_deferred("_damage_target", body)
		return
	stopped = true
	queue_free()


func _damage_target(body: Node) -> void:
	if is_instance_valid(body):
		var game_state := get_node_or_null("/root/GameState")
		var target_bonus: int = game_state.get_weapon_target_bonus(weapon_id, body) if game_state != null else 0
		body.take_damage(damage + target_bonus, direction * 90.0 + Vector2(0.0, -28.0))
	pending_hits -= 1
	remaining_hits -= 1
	if remaining_hits <= 0:
		stopped = true
		queue_free()
	elif pending_hits == 0 and not stopped:
		set_deferred("monitoring", true)
