@tool
extends Node2D
## Static cosmetics parented to the habitat's authoritative state containers.
const SOURCES := {
	"closed": ["res://art/visual_slice/echo_closed_cocoon_v1.png", Rect2(214, 138, 602, 1234)],
	"spent": ["res://art/visual_slice/echo_spent_husk_v1.png", Rect2(32, 112, 1712, 670)],
}
var built := false
var retired: Array[CanvasItem] = []
var sprites: Array[Sprite2D] = []


static func attach(site: Node2D) -> Node2D:
	var existing := site.get_node_or_null("NestArt") as Node2D
	if existing != null:
		return existing
	var art := new()
	art.name = "NestArt"
	site.add_child(art)
	return art


func _ready() -> void:
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	var site := get_parent()
	var leaves: Array[CanvasItem] = []
	for i in range(3):
		for path in ["DormantPods/Pod%d", "DormantPods/SilkSeam%d", "SpentSilk/Shell%d"]:
			var leaf := site.get_node_or_null(path % i)
			if not (leaf is Polygon2D or leaf is Line2D) or leaf.get_child_count() != 0:
				return
			leaves.append(leaf)
	var textures := {}
	for key in SOURCES:
		var source := load(SOURCES[key][0]) as Texture2D
		if source == null:
			return
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = SOURCES[key][1]
		atlas.filter_clip = true
		textures[key] = atlas
	for i in range(3):
		var height: float = [34.0, 38.0, 36.0][i]
		_sprite(site.get_node("DormantPods"), "Cocoon%d" % i, textures.closed, (i - 1) * 70.0, height / textures.closed.get_height(), i == 2)
		_sprite(site.get_node("SpentSilk"), "Husk%d" % i, textures.spent, (i - 1) * 70.0, (42.0 + i * 3) / textures.spent.get_width(), i == 1)
	for leaf in leaves:
		leaf.hide()
	retired = leaves
	built = true


func _sprite(container: Node2D, named: String, texture: Texture2D, x: float, ratio: float, flip: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.name = named
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position.x = x
	sprite.offset.y = -texture.get_height() * 0.5
	sprite.scale = Vector2.ONE * ratio
	sprite.flip_h = flip
	container.add_child(sprite)
	sprites.append(sprite)
