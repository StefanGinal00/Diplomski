extends Node2D
## Reads native attack state after physics; never changes AI, hitboxes or timers.
const Art = preload("res://EnemyAttackArt.gd")
var style := "enemy"
var attacking := false
var preparing := false
var age := 0.0
var heading := Vector2.RIGHT
var attack_age := 0.0
var animation_frame := 0
var preparation_duration := 0.0
var recovery_age := 0.0
var recovering := false
const ROOT_FADE_TIME := 0.14

static func attach(actor: Node2D, identity: String) -> void:
	if actor.has_node("AttackPresentation"):
		return
	var effect := new()
	effect.name = "AttackPresentation"
	effect.style = identity
	actor.add_child(effect)

func _ready() -> void:
	process_physics_priority = 1
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visibility_changed.connect(_visibility_changed)

func _visibility_changed() -> void:
	if not is_visible_in_tree():
		attacking = false
		preparing = false
		age = 0
		attack_age = 0
		animation_frame = 0
		preparation_duration = 0
		recovering = false
		recovery_age = 0
		queue_redraw()

func _physics_process(delta: float) -> void:
	var actor := get_parent()
	var was_attacking := attacking
	var was_preparing := preparing
	var previous_heading := heading
	attacking = false
	preparing = false
	if not is_visible_in_tree() or actor.is_dead:
		recovering = false
		queue_redraw()
		return
	age += delta
	match style:
		"crawler", "broodling":
			preparing = actor.state == 1
			attacking = actor.state == 2
			heading = Vector2(actor.direction, 0)
		"wisp":
			preparing = actor.state == 1
			attacking = actor.state == 2
			heading = actor.dive_direction
		"shade":
			preparing = actor.telegraph_remaining > 0
			attacking = actor.dash_remaining > 0
			heading = Vector2(actor.dash_direction, 0)
		"root":
			preparing = actor.phase == "warning"
			attacking = actor.phase == "burst"
			heading = Vector2(actor.facing, 0)
	if attacking:
		recovering = false
		attack_age = attack_age + delta if was_attacking else 0.0
		# The roots remain damaging for the whole native burst. Breakup belongs
		# to recovery, never to a still-active strike volume.
		animation_frame = 2 + int(attack_age * 12) % 2 if style == "root" else Art.Flipbook.phase(attack_age, 0.3, true)
	else:
		attack_age = 0
		animation_frame = 0
		if preparing:
			var remaining := _warning_remaining(actor)
			if not was_preparing:
				preparation_duration = maxf(remaining, 0.001)
			animation_frame = 1 if remaining < preparation_duration * 0.5 else 0
		if _native_recovery(actor):
			if was_attacking:
				recovering = true
				recovery_age = 0
			elif recovering:
				recovery_age += delta
				recovering = recovery_age < ROOT_FADE_TIME
			if recovering:
				# Keep the committed attack direction while the body brakes/turns.
				heading = previous_heading
				animation_frame = 4 if recovery_age < ROOT_FADE_TIME * 0.5 else 5
		else:
			recovering = false
	queue_redraw()

func _native_recovery(actor: Node) -> bool:
	match style:
		"root": return actor.phase == "recovery"
		"crawler", "broodling", "wisp": return actor.state == 3
		"shade": return actor.recovery_remaining > 0
	return false

func _warning_remaining(actor: Node) -> float:
	match style:
		"crawler", "broodling": return actor.state_remaining
		"wisp": return actor.state_time
		"shade": return actor.telegraph_remaining
		"root": return actor.phase_remaining
	return 0.0

func _root_visual_rect() -> Rect2:
	var actor := get_parent()
	var strike := actor.get_node("StrikeArea/CollisionShape2D") as CollisionShape2D
	var body := actor.get_node("CollisionShape2D") as CollisionShape2D
	var size: Vector2 = strike.shape.size
	var rect := Rect2(to_local(strike.global_position) - size * 0.5, size)
	var floor_y: float = to_local(body.global_position).y + body.shape.size.y * 0.5
	# The native volume extends underground. Paint only its above-floor part;
	# keep its exact top and horizontal reach, without moving the damage shape.
	rect.size.y = maxf(0, minf(rect.end.y, floor_y) - rect.position.y)
	return rect

func contact(body: Node2D) -> void:
	if not is_visible_in_tree() or get_parent().is_dead:
		return
	# Contact feedback, not a newly invented ranged slash or damage volume.
	var point: Vector2 = get_parent().global_position.lerp(body.global_position, 0.5)
	if get_parent().has_node("PaintedMobAppearance"):
		get_parent().get_node("PaintedMobAppearance").contact()
	preload("res://BossBurst.gd").spawn(get_parent().get_parent(), point, Color.WHITE, "contact", Vector2(13, 13), 0.18, Art.CONTACTS[style])

func _draw() -> void:
	if not is_visible_in_tree():
		return
	if preparing:
		# Compact material cue; native warning icons/lanes remain unobscured.
		var opacity := 0.25 + 0.15 * (1 + sin(age * 20))
		Art.Flipbook.stamp(self, Art.CONTACTS[style], animation_frame, Rect2(-10, -14, 20, 20), Color(1, 1, 1, opacity))
	if attacking or recovering:
		if style == "root":
			# Native strike reach, grounded at the body collider's feet.
			var opacity := 0.9 * (1.0 - recovery_age / ROOT_FADE_TIME) if recovering else 0.9
			Art.Flipbook.stamp(self, 17, animation_frame, _root_visual_rect(), Color(1, 1, 1, opacity), true)
			return
		draw_set_transform(Vector2.ZERO, heading.angle())
		# Trails end at the body, never in front of its real contact hitbox.
		var opacity := 0.6 * (1.0 - recovery_age / ROOT_FADE_TIME) if recovering else 0.6 + sin(age * 28) * 0.12
		Art.Flipbook.stamp(self, Art.CONTACTS[style], animation_frame, Rect2(-37, -12, 38, 24), Color(1, 1, 1, opacity))
		draw_set_transform(Vector2.ZERO)
