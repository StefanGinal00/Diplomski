@tool
extends Sprite2D
## Field-guide presentation only: no dialogue, movement or interaction authority.
const SHEETS := {
	"gallery": preload("res://art/characters/echo_venn_v1.png"),
	"archive": preload("res://art/characters/echo_oris_v1.png"),
	"nest": preload("res://art/characters/echo_senn_v1.png"),
	"tide": preload("res://art/characters/echo_rill_v1.png"),
	"causeway": preload("res://art/characters/echo_taren_v1.png"),
	"vault": preload("res://art/characters/echo_odel_v1.png"),
	"shaft": preload("res://art/characters/echo_dena_v1.png"),
	"echo": preload("res://art/characters/echo_leth_v1.png"),
	"depths": preload("res://art/characters/echo_aven_v1.png"),
	"emberspine": preload("res://art/characters/echo_rovan_v1.png"),
}
const PIVOTS := {
	"gallery": [Vector2(315, 604), Vector2(313, 594), Vector2(350, 592), Vector2(302, 604)],
	"archive": [Vector2(324, 596), Vector2(328, 596), Vector2(348, 590), Vector2(298, 598)],
	"nest": [Vector2(326, 614), Vector2(332, 606), Vector2(380, 602), Vector2(308, 612)],
	"tide": [Vector2(330, 604), Vector2(310, 598), Vector2(358, 586), Vector2(300, 600)],
	"causeway": [Vector2(320, 584), Vector2(323, 584), Vector2(340, 576), Vector2(325, 578)],
	"vault": [Vector2(333, 606), Vector2(332, 600), Vector2(360, 596), Vector2(325, 602)],
	"shaft": [Vector2(310, 602), Vector2(320, 600), Vector2(330, 602), Vector2(308, 602)],
	"echo": [Vector2(314, 595), Vector2(312, 594), Vector2(322, 596), Vector2(314, 592)],
	"depths": [Vector2(318, 601), Vector2(324, 604), Vector2(319, 604), Vector2(318, 603)],
	"emberspine": [Vector2(335, 605), Vector2(330, 603), Vector2(325, 605), Vector2(330, 604)],
}
const SCALES := {"gallery": 0.074, "archive": 0.076, "nest": 0.073, "tide": 0.076, "causeway": 0.0785, "vault": 0.0745, "shaft": 0.076, "echo": 0.073, "depths": 0.073, "emberspine": 0.071}
const CONTACT_ROWS := {"gallery": [603, 593, 591, 603], "archive": [596, 596, 589, 597], "nest": [614, 605, 602, 611], "tide": [602, 597, 585, 599], "causeway": [583, 583, 574, 577], "vault": [604, 599, 594, 601], "shaft": [608, 608, 582, 586], "echo": [596, 593, 589, 600], "depths": [602, 601, 598, 598], "emberspine": [604, 602, 582, 582]}
var region := ""
var previous_position := Vector2.ZERO
var travel := 0.0
var facing_left := false


static func attach(actor: Node2D, guide_region: String) -> Sprite2D:
	if not SHEETS.has(guide_region):
		return null
	if actor.has_node("FieldAppearance"):
		return actor.get_node("FieldAppearance")
	var art := new()
	art.name = "FieldAppearance"
	art.region = guide_region
	actor.add_child(art)
	return art


func _ready() -> void:
	texture = SHEETS[region]
	hframes = 2
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var actor := get_parent()
	for leaf in ["Coat", "Face", "Accent", "ResidentMotion"]:
		actor.get_node(leaf).hide()
	actor.get_node("ResidentMotion").set_process(false)
	previous_position = actor.global_position
	# These field routes place the actor 24 px above their floor anchor.
	# Move only painted feet; preserve actor origin, talk reach and patrol.
	position.y = 24
	var prompt := actor.get_node("InteractionPrompt") as Label
	actor.get_node("NameLabel").position.y = -64
	prompt.position.y = -86
	prompt.z_index = 3
	prompt.add_theme_color_override("font_outline_color", Color("09131c"))
	prompt.add_theme_constant_override("outline_size", 3)
	_apply_pose(0, false)
	if Engine.is_editor_hint():
		set_process(false)


func _process(_delta: float) -> void:
	var actor := get_parent()
	var displacement: Vector2 = actor.global_position - previous_position
	previous_position = actor.global_position
	if not is_visible_in_tree():
		travel = 0
		_apply_pose(0, facing_left)
		return
	var pose := 0
	if displacement.length() < 20 and absf(displacement.x) > 0.01:
		travel += absf(displacement.x)
		facing_left = displacement.x < 0
		pose = 1 + int(travel / 5.0) % 2
	elif displacement.length() >= 20:
		travel = 0
	var target = actor.get_attention_target()
	if is_instance_valid(target):
		var dx: float = target.global_position.x - actor.global_position.x
		if absf(dx) > 1:
			facing_left = dx < 0
		pose = 0
	if actor.player_dialogue_active or actor.social_bubble.visible:
		pose = 3
	_apply_pose(pose, facing_left)


func _apply_pose(pose: int, left: bool) -> void:
	frame = pose
	flip_h = left
	offset = texture.get_size() * 0.25 - PIVOTS[region][pose]
	offset.y = texture.get_height() * 0.25 - CONTACT_ROWS[region][pose]
	if left:
		offset.x = -offset.x
	scale = Vector2.ONE * SCALES[region]
