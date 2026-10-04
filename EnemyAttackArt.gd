extends RefCounted
## Shared immutable texture; presentation only. Cells have transparent gutters.
const ATLAS = preload("res://art/characters/enemy_attacks_v1.png")
const Flipbook = preload("res://CombatFlipbook.gd")
const PROJECTILES := {"void_sentinel": 0, "abyss_warden": 1, "echo_matriarch": 2, "ash_castellan": 3, "hollow_sovereign": 4, "starfall_guardian": 5, "ember_marshal": 6, "ranged": 7, "sentry": 16, "ash_sentry": 13}
const CONTACTS := {"enemy": 8, "crawler": 9, "wisp": 10, "shade": 11, "broodling": 12, "root": 17, "fiend": 18, "neutral": 19}

static func stamp(canvas: CanvasItem, index: int, rect: Rect2, color := Color.WHITE, tight := false) -> void:
	var source := Rect2(Vector2(index % 4, index / 4) * 320, Vector2(320, 320))
	if tight:
		source = preload("res://EnemyAttackBounds.gd").CELLS[index]
	canvas.draw_texture_rect_region(ATLAS, rect, source, color)

static func release_frame(boss_id: String, kind: String) -> int:
	if kind == "volley":
		return PROJECTILES.get(boss_id, 0)
	if kind == "eruption":
		return 13
	if kind == "pulse" or kind == "starfall":
		return 14
	if kind == "ring" and boss_id == "echo_matriarch":
		return 2
	return 15
