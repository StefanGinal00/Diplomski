@tool
extends Node2D
## Small, physically legible machinery. Animation is driven by the room budget.
const SHEET := preload("res://art/visual_slice/field_machinery_atlas_v1.png")
const SOURCE_SIZE := Vector2(1536, 1024)
const CROPS := [Rect2(35, 32, 470, 470), Rect2(540, 151, 454, 347), Rect2(1000, 20, 530, 481), Rect2(42, 665, 456, 292), Rect2(532, 568, 478, 377), Rect2(1122, 506, 350, 488)]
var wheel: Sprite2D
var kind := "pump"
var retired: Array[CanvasItem] = []

static func crop(index: int) -> Rect2:
	var scale := SHEET.get_size() / SOURCE_SIZE
	return Rect2(CROPS[index].position * scale, CROPS[index].size * scale)

static func sprite(parent: Node, index: int, at: Vector2, size: Vector2) -> Sprite2D:
	var image := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = crop(index)
	atlas.filter_clip = true
	image.texture = atlas
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.position = at
	image.scale = size / atlas.region.size
	parent.add_child(image)
	return image

static func attach(site: Node2D, machine_kind: String) -> Node2D:
	if site.has_node("FieldMachineArt"): return site.get_node("FieldMachineArt")
	var art := new()
	art.name = "FieldMachineArt"
	art.kind = machine_kind
	site.add_child(art)
	return art

func _ready() -> void:
	set_process(false)
	z_index = -1
	for child in get_parent().get_children():
		if child is Line2D or (child is Polygon2D and child.get_child_count() == 0):
			child.hide()
			retired.append(child)
	if kind == "flywheel":
		sprite(self, 1, Vector2(0, -23), Vector2(62, 46))
		wheel = sprite(self, 0, Vector2(0, -33.5), Vector2(60, 60))
		wheel.name = "Flywheel"
	else:
		var dimensions := Vector2(82, 74) if kind != "control" else Vector2(36, 33)
		sprite(self, 2, Vector2(0, -dimensions.y * 0.5 + (25 if kind == "control" else 0)), dimensions)
	if kind == "pump_board": sprite(self, 5, Vector2(64, -27), Vector2(36, 54))
	if not Engine.is_editor_hint(): _fit_headroom()

func _fit_headroom() -> void:
	# Shelves above a site are actual terrain. Keep the machine beneath them.
	var height := 63.5 if kind == "flywheel" else 74.0
	if kind == "control": return
	var available := height
	var ancestor := get_parent()
	for level in range(4):
		if ancestor == null: break
		for body in ancestor.get_children():
			if not body is StaticBody2D: continue
			var col := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col == null or col.disabled or not col.shape is RectangleShape2D: continue
			var rect: Rect2 = global_transform.affine_inverse() * col.global_transform * Rect2(-col.shape.size * 0.5, col.shape.size)
			if rect.end.y < -8 and rect.end.x > -42 and rect.position.x < 42:
				available = minf(available, -rect.end.y - 3)
		ancestor = ancestor.get_parent()
	scale = Vector2.ONE * clampf(available / height, 0.35, 1.0)

func animate(age: float) -> void:
	if wheel != null: wheel.rotation = age * 0.22
