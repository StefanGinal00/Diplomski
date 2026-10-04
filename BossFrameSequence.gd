extends RefCounted
## Twelve painted frames; selection observes combat, never advances its timers.
var data: Dictionary = {}
var texture: Texture2D
var windup_peak := 0.0
var recovery_peak := 0.0
var previous_windup := 0.0
var release_age := 10.0
var hovering := false
var hover_clock := 0.0

func initialize(id: String) -> bool:
	var path := "res://art/characters/boss_%s_animation_v2" % id
	if not ResourceLoader.exists(path + ".png"):
		return false
	var parsed: Variant = preload("res://BossFrameData.gd").DATA.get(id, {})
	if not parsed is Dictionary or parsed.get("frames", []).size() != 12:
		return false
	data = parsed
	texture = load(path + ".png")
	hovering = id == "echo_matriarch"
	return texture != null

func tick(delta: float, windup: float, recovery: float) -> void:
	release_age += delta
	hover_clock += delta
	if windup > previous_windup + 0.001:
		windup_peak = windup
	if windup <= 0:
		windup_peak = 0
	previous_windup = windup
	recovery_peak = maxf(recovery_peak, recovery) if recovery > 0 else 0.0

func select(pose: int, distance: float, charging: bool, windup: float, recovery: float) -> int:
	if charging:
		return 9
	if pose == 3 and release_age < 0.10:
		return 9
	if windup > 0:
		var progress := 1.0 - windup / maxf(windup_peak, windup)
		return 7 if progress < 0.45 else 8
	if pose == 3:
		if recovery > 0:
			return 10 if recovery > recovery_peak * 0.5 else 11
		return 10 if release_age < 0.19 else 11
	if pose == 1:
		return 1 + (int(hover_clock * 8.0) % 6 if hovering else int(distance / 7.0) % 6)
	return 0

func bounds(index: int) -> Rect2:
	var b: Array = data.frames[index].bounds
	return Rect2(b[0], b[1], b[2], b[3])

func pivot() -> Vector2:
	return Vector2(data.pivot[0], data.pivot[1])

func reset() -> void:
	windup_peak = 0
	previous_windup = 0
	recovery_peak = 0
	release_age = 10
