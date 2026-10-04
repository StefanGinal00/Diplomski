extends Area2D
## Damage-only body volume. Navigation stays on the native foot collider.
## Layer 2 is queried by player weapons, never by walking actors/enemy shots.
const LAYER := 2
var profile: Array[Rect2] = []

static func actor(collider: Node) -> Node:
	if collider != null and collider.get_script() == preload("res://CombatHurtbox.gd"):
		return collider.get_parent()
	return collider

static func install(boss: CharacterBody2D, height: float, foot_y: float, flying: bool) -> Area2D:
	if boss.has_node("CombatHurtbox"): return boss.get_node("CombatHurtbox")
	var hurt := new()
	hurt.name = "CombatHurtbox"
	hurt.collision_layer = LAYER
	hurt.collision_mask = 0
	hurt.monitoring = false
	# Stable central armor/body, not outstretched weapons, wings or cape tips.
	if flying:
		hurt.profile = [Rect2(-23, -45, 46, 67)]
	else:
		var width := clampf(height * 0.36, 26, 42)
		hurt.profile = [Rect2(-width/2, foot_y-height*0.84, width, height*0.84),
			Rect2(-width*0.27, foot_y-height*0.99, width*0.54, height*0.24)]
	for rect in hurt.profile:
		var shape := CollisionShape2D.new()
		var capsule := CapsuleShape2D.new()
		capsule.radius = rect.size.x/2
		capsule.height = maxf(rect.size.y, rect.size.x)
		shape.shape = capsule
		shape.position = rect.get_center()
		hurt.add_child(shape)
		# A player touching the central torso must also receive contact damage.
		# Keep the original leg volume, adding only the same painted core.
		var contact := boss.get_node_or_null("ContactArea") as Area2D
		if contact != null:
			var body_contact := shape.duplicate() as CollisionShape2D
			body_contact.name = "PaintedCoreContact%d" % hurt.get_child_count()
			contact.add_child(body_contact)
	boss.add_child(hurt)
	return hurt
