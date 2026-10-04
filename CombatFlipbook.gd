extends RefCounted
## Six genuinely painted frames per material. Shared, immutable GPU resources.
const SHEETS := [preload("res://art/characters/combat_arcane_frames_v2.png"), preload("res://art/characters/combat_spectral_frames_v2.png"), preload("res://art/characters/combat_contact_frames_v2.png"), preload("res://art/characters/combat_ground_frames_v2.png"), preload("res://art/characters/combat_wild_frames_v2.png")]

static func phase(age: float, duration := 0.3, flight := false) -> int:
	if flight:
		# Do not play breakup frames while a projectile still deals damage.
		return [1, 2, 3, 2][int(maxf(age, 0) * 16) % 4]
	# Native warnings own anticipation (0/1). Damage/release starts at full power.
	return mini(5, 2 + int(clampf(age / maxf(duration, 0.001), 0, 1) * 4))

static func stamp(canvas: CanvasItem, identity: int, frame: int, rect: Rect2, color := Color.WHITE, grounded := false) -> void:
	var source := Rect2(Vector2(clampi(frame, 0, 5), identity % 4) * 256, Vector2(256, 256))
	if grounded:
		# Common sequence canvas, not per-frame bounds: growth remains real.
		source.position += Vector2(16, 16)
		source.size = Vector2(224, 224)
	canvas.draw_texture_rect_region(SHEETS[identity / 4], rect, source, color)
