@tool
extends Sprite2D
## Species-specific art only. Native neutral AI and streaming remain authoritative.
const SHEETS := {
	"moth": preload("res://art/characters/echo_fauna_moth_v1.png"),
	"bat": preload("res://art/characters/echo_fauna_bat_v1.png"),
	"skimmer": preload("res://art/characters/echo_fauna_skimmer_v3.png"),
	"crawler": preload("res://art/characters/echo_fauna_crawler_v1.png"),
	"newt": preload("res://art/characters/echo_fauna_newt_v1.png"),
}
const PIVOTS := {
	"moth": [Vector2(390, 588), Vector2(390, 588), Vector2(390, 526), Vector2(380, 528)],
	"bat": [Vector2(360, 556), Vector2(360, 554), Vector2(360, 556), Vector2(340, 510)],
	"skimmer": [Vector2(340, 490), Vector2(340, 508), Vector2(340, 498), Vector2(340, 496)],
	"crawler": [Vector2(350, 524), Vector2(350, 524), Vector2(350, 514), Vector2(340, 518)],
	"newt": [Vector2(365, 526), Vector2(365, 538), Vector2(365, 512), Vector2(365, 524)],
}
const SCALES := {"moth": 0.046, "bat": 0.05, "skimmer": 0.054, "crawler": 0.052, "newt": 0.05}
# Ground species only: moths and bats deliberately keep their hovering pose.
const CONTACT_ROWS := {"skimmer": [486, 502, 493, 491], "crawler": [521, 521, 513, 516], "newt": [525, 536, 510, 522]}
var species := ""
var enabled := false
var previous_position := Vector2.ZERO
var travel := 0.0
var motion_grace := 0.0


static func species_for(zone: String, creature: String) -> String:
	if zone not in ["echo_grotto", "training_passage", "sunken_shaft", "ashen_bastion", "starfall_reach"]:
		return ""
	for pair in [[" Moth", "moth"], [" Bat", "bat"], [" Skimmer", "skimmer"], [" Crawler", "crawler"], [" Newt", "newt"]]:
		if creature.ends_with(pair[0]):
			return pair[1]
	return ""


func _ready() -> void:
	var actor := get_parent()
	species = species_for(actor.zone_id, actor.creature_name)
	var original := actor.get_node_or_null("Sprite2D") as Sprite2D
	if species.is_empty() or original == null or original.get_child_count() != 0:
		hide()
		set_process(false)
		return
	enabled = true
	texture = SHEETS[species]
	hframes = 2
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	previous_position = actor.global_position
	_apply_pose(0, false, Color.WHITE)
	original.hide()
	if Engine.is_editor_hint():
		set_process(false)


func _process(delta: float) -> void:
	if not enabled:
		return
	var actor := get_parent()
	var displacement: Vector2 = actor.global_position - previous_position
	previous_position = actor.global_position
	if not is_visible_in_tree() or actor.is_dead:
		motion_grace = 0
		return
	motion_grace = maxf(0, motion_grace - delta)
	if displacement.length() >= 40 or actor.resting or actor.grace_remaining > 0 or actor.hit_stun_remaining > 0:
		motion_grace = 0
	elif actor.is_on_floor() and absf(displacement.x) > 0.01:
		travel += absf(displacement.x)
		motion_grace = 0.04
	var pose := 0
	if actor.hit_flash_remaining > 0 or actor.grace_remaining > 0:
		pose = 3
	elif actor.is_on_floor() and motion_grace > 0:
		pose = 1 + int(travel / 2.5) % 2
	elif actor.is_hostile:
		pose = 3
	var tint: Color = actor.sprite.modulate
	if actor.hit_flash_remaining <= 0:
		tint = tint.lerp(Color.WHITE, 0.7)
	_apply_pose(pose, actor.direction < 0, tint)


func _apply_pose(pose: int, left: bool, tint: Color) -> void:
	frame = pose
	flip_h = left
	offset = texture.get_size() * 0.25 - PIVOTS[species][pose]
	if CONTACT_ROWS.has(species): offset.y = texture.get_height() * 0.25 - CONTACT_ROWS[species][pose]
	if left:
		offset.x = -offset.x
	position = Vector2(0, 9)
	scale = Vector2.ONE * SCALES[species]
	modulate = tint
