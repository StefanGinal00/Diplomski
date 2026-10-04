extends Sprite2D
## Feet-anchored original 2D bodies. Native interactions remain on the parent.
const SHEET := preload("res://art/characters/opening_residents_v1.png")
const REGIONS := [Rect2(65, 8, 510, 856), Rect2(670, 6, 500, 858), Rect2(1260, 4, 450, 860)]
const CONTACT_ROWS := [848, 853, 854]
var role := 0
var foot := 14.0

static func attach(actor: Node2D, identity: int, foot_y: float = 14) -> void:
	# Field residents already own the regional walking body. A static guide
	# portrait must not disable that body while its route keeps moving.
	if actor.has_node("ResidentMotion") and actor.get("route_marker_names") != null and not actor.route_marker_names.is_empty(): return
	if actor.has_node("OpeningResidentArt"): return
	var art := new()
	art.name = "OpeningResidentArt"
	art.role = identity
	art.foot = foot_y
	actor.add_child(art)

func _ready() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = REGIONS[role]
	texture = atlas
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	scale = Vector2.ONE * (36.0 / atlas.region.size.y)
	position = Vector2(0, foot - 18)
	for named in ["Sprite2D", "BodyVisual", "Hood", "Pack", "Cloak", "Coat", "Face", "Accent", "ResidentMotion"]:
		var old := get_parent().get_node_or_null(named)
		if old is CanvasItem: old.hide()
		if named == "ResidentMotion" and old != null: old.set_process(false)
	var label := get_parent().get_node_or_null("NameLabel") as Label
	if label != null:
		label.position.y = foot - 51
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", Color("09131c"))
