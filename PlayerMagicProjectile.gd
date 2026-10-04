extends Area2D

signal contacted(kind: String, point: Vector2)

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
var lifecycle_retired := false
var hiding_for_contact := false
var remaining_range := 270.0

@onready var aura: Polygon2D = $Aura
@onready var core: Polygon2D = $Core


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_mask |= preload("res://CombatHurtbox.gd").LAYER
	area_entered.connect(_on_hurtbox_entered)
	visibility_changed.connect(_on_visibility_changed)
	# Listen to ancestors too: a contact-hidden projectile does not receive
	# another effective-visibility change when its room subsequently hides.
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is CanvasItem:
			ancestor.visibility_changed.connect(_on_ancestor_visibility_changed)
		ancestor = ancestor.get_parent()
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
	if not is_visible_in_tree() and not hiding_for_contact:
		_retire()

func _on_ancestor_visibility_changed() -> void:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is CanvasItem and not ancestor.is_visible_in_tree():
			_retire()
			return
		ancestor = ancestor.get_parent()

func _hide_for_contact() -> void:
	# Reserved native hits still resolve after visual contact hiding.
	hiding_for_contact = true
	hide()
	hiding_for_contact = false

func _retire(_unused: String = "") -> void:
	if lifecycle_retired:
		return
	lifecycle_retired = true
	stopped = true
	hide()
	set_deferred("monitoring", false)
	queue_free()


func setup(new_direction: Vector2, projectile_source: Node, new_spell_id: String, damage_bonus: int = 0, new_weapon_id: String = "apprentice_staff", base_weapon_damage: int = 2, max_range: float = 270.0) -> void:
	if lifecycle_retired or is_queued_for_deletion():
		return
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
	remaining_range = clampf(max_range, 1.0, 380.0)
	lifetime = maxf(remaining_range / speed, 0.1)
	global_rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if stopped or lifecycle_retired or is_queued_for_deletion() or pending_hits >= remaining_hits:
		return
	var step := minf(maxf(speed * delta, 0.0), remaining_range)
	remaining_range -= preload("res://ProjectileTravel.gd").advance(self,step,hit_targets)
	aura.rotation += delta * 5.5
	lifetime -= delta
	if pending_hits == 0 and (lifetime <= 0.0 or remaining_range <= 0.0):
		_retire()


func _on_hurtbox_entered(area: Area2D) -> void:
	if area.get_script()==preload("res://CombatHurtbox.gd"): _on_body_entered(area)

func _on_body_entered(body: Node) -> void:
	body = preload("res://CombatHurtbox.gd").actor(body)
	if not is_instance_valid(body): return
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
		contacted.emit("breakable" if body.is_in_group("breakable") else "actor", global_position)
		set_deferred("monitoring", false)
		if pending_hits >= remaining_hits:
			_hide_for_contact()
		call_deferred("_damage_target", body)
		return
	if pending_hits < remaining_hits:
		contacted.emit("terrain", global_position)
	stopped = true
	set_deferred("monitoring", false)
	_hide_for_contact()
	queue_free()


func _damage_target(body: Node) -> void:
	if lifecycle_retired:
		return
	if is_instance_valid(body):
		var game_state := get_node_or_null("/root/GameState")
		var target_bonus: int = game_state.get_weapon_target_bonus(weapon_id, body) if game_state != null else 0
		body.take_damage(damage + target_bonus, direction * 90.0 + Vector2(0.0, -28.0))
	pending_hits -= 1
	remaining_hits -= 1
	if remaining_hits <= 0:
		_retire()
	elif pending_hits == 0 and not stopped:
		set_deferred("monitoring", true)
