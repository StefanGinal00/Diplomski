extends Sprite2D
## Short, capped paint-only flourish. The original pickup still frees immediately.
static var active_count := 0
const LIMIT := 18

static func spawn(pickup: Area2D, player: Node2D) -> void:
	if active_count >= LIMIT or not is_instance_valid(player): return
	var original := pickup.get_node_or_null("Visual/PaintedPickup") as Sprite2D
	if original == null or original.texture == null or pickup.get_parent() == null: return
	var art := new()
	art.name = "CollectedLootEcho"
	art.texture = original.texture
	art.texture_filter = original.texture_filter
	art.offset = original.offset
	art.z_index = 6
	pickup.get_parent().add_child(art)
	art.global_transform = original.global_transform
	var animation := art.create_tween().set_parallel(true)
	animation.tween_property(art, "global_position", player.global_position + Vector2(0, -10), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(art, "scale", art.scale * 0.2, 0.22)
	animation.tween_property(art, "self_modulate:a", 0.0, 0.22)
	animation.tween_property(art, "rotation", art.rotation + 0.5, 0.22)
	animation.chain().tween_callback(art.queue_free)

func _enter_tree() -> void: active_count += 1
func _exit_tree() -> void: active_count = maxi(0, active_count - 1)
