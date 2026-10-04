@tool
extends Node2D
## Generated raster props only; field controllers retain all gameplay authority.
const REGIONS := ["echo", "gallery", "archive", "tide", "nest", "causeway", "vault", "depths", "shaft", "hollow", "crossing", "shaft_gallery", "shaft_cistern", "shaft_approach"]
const MAX_WIDTH := {"cart": 68.0, "shelf": 100.0, "fern": 46.0, "tent": 94.0, "desk": 50.0, "book_cart": 68.0}
# Art-only offsets audited against the actual Archive floor/ledge rectangles.
# Keep NPC/loot/site markers fixed. Do not move other regions' site numbers.
const ARCHIVE_PLACEMENT := {
	"Site0": {"shelf": Vector2(-270, 240), "desk": Vector2(20, 88)},
	"Site2": {"shelf": Vector2(305, 190)},
	"Site4": {"book_cart": Vector2(260, 174)},
	"Site7": {"shelf": Vector2(-128, 170)},
}
const SOURCES := {
	"cart": ["res://art/visual_slice/echo_cargo_cart_v1.png", Rect2(46, 110, 1580, 738)],
	"shelf": ["res://art/visual_slice/echo_archive_shelf_v1.png", Rect2(32, 122, 1520, 754)],
	"fern": ["res://art/visual_slice/echo_cave_fern_v1.png", Rect2(66, 54, 1366, 962)],
	"tent": ["res://art/visual_slice/echo_field_tent_v1.png", Rect2(90, 132, 1522, 678)],
	"desk": ["res://art/visual_slice/echo_field_desk_v1.png", Rect2(62, 42, 1648, 798)],
	"book_cart": ["res://art/visual_slice/echo_book_cart_v1.png", Rect2(52, 98, 1622, 716)],
}
var retired: Array[CanvasItem] = []
var sprites: Array[Sprite2D] = []
var built := false
var counts := {"cart": 0, "shelf": 0, "fern": 0, "tent": 0, "desk": 0, "book_cart": 0}
var atlases: Dictionary = {}


func _ready() -> void:
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	var dressing := get_parent()
	if not dressing.has_method("_sites"): return
	for kind in SOURCES:
		var texture := load(SOURCES[kind][0]) as Texture2D
		if texture == null:
			return # Keep placeholders when an asset cannot be loaded.
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = SOURCES[kind][1]
		atlas.filter_clip = true
		atlases[kind] = atlas
	for site in dressing.get_children():
		if not site is Node2D or not String(site.name).begins_with("Site"):
			continue
		if site.has_node("Cart"):
			var rails := site.get_node_or_null("Rails") as Line2D
			if rails != null:
				rails.texture = preload("res://art/visual_slice/drift_iron_v1.png")
				rails.texture_mode = Line2D.LINE_TEXTURE_TILE
				rails.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				rails.default_color = Color("768386")
				rails.width = 1.5
			var book_cargo: bool = dressing.region == "archive"
			var leaves: Array[CanvasItem] = []
			for node in site.get_children():
				var named := String(node.name)
				if named == "Cart" or named.begins_with("Wheel") or named.begins_with("Manuscripts" if book_cargo else "Ore"):
					if _safe_leaf(node):
						leaves.append(node)
			if leaves.size() >= 4:
				_replace(site, "book_cart" if book_cargo else "cart", "PaintedCargo", Vector2(-8.5, 0), 82, leaves)
		var tent := site.get_node_or_null("Tent")
		var door := site.get_node_or_null("TentDoor")
		if _safe_leaf(tent) and _safe_leaf(door):
			# Low bivouac shelter: the camps sit under 60 px raised walkways.
			_replace(site, "tent", "PaintedTent", Vector2(18, 0), 94, [tent, door])
			var old_awning := site.get_node_or_null("SilkAwning")
			if site.has_node("PaintedTent") and _safe_leaf(old_awning):
				old_awning.hide()
				retired.append(old_awning)
		for label in ["FieldTable", "ReadingDesk"]:
			var desk := site.get_node_or_null(label)
			if _safe_leaf(desk):
				var field: bool = label == "FieldTable"
				# Field-table placeholders ended 12 px above their site's ground.
				# Ground only the new artwork; keep guide markers/collision intact.
				_replace(site, "desk", "Painted" + label, Vector2(109 if field else 20, 0), 78 if field else 136, [desk])
		if site.has_node("Cabinet"):
			var leaves: Array[CanvasItem] = []
			for node in site.get_children():
				var named := String(node.name)
				if named == "Cabinet" or named.begins_with("Shelf") or named.begins_with("Book"):
					if _safe_leaf(node):
						leaves.append(node)
			if leaves.size() == 25:
				_replace(site, "shelf", "PaintedBookshelf", Vector2.ZERO, 240, leaves)
		# Furniture is layered within its site, without raising it above actors.
		var reading_desk := site.get_node_or_null("PaintedReadingDesk")
		if reading_desk != null:
			site.move_child(reading_desk, site.get_child_count() - 1)
		for node in site.get_children():
			if node is Polygon2D and String(node.name).begins_with("Fern") and _safe_leaf(node):
				var rect := Rect2(node.polygon[0], Vector2.ZERO)
				for point in node.polygon:
					rect = rect.expand(point)
				var height := clampf(rect.size.y, 18, 32)
				var atlas: AtlasTexture = atlases.fern
				var width := height * atlas.get_width() / float(atlas.get_height())
				var sprite := _replace(site, "fern", "Painted" + String(node.name), node.position + Vector2(rect.get_center().x, rect.end.y), width, [node])
				if sprite != null:
					sprite.flip_h = int(String(node.name).trim_prefix("Fern")) % 2 == 1
					if dressing.region == "nest":
						sprite.modulate = Color(0.92, 0.84, 1.0)
	built = true


func _safe_leaf(node: Node) -> bool:
	return (node is Polygon2D or node is Line2D) and node.get_child_count() == 0


func _replace(site: Node2D, kind: String, named: String, foot: Vector2, width: float, leaves: Array[CanvasItem]) -> Sprite2D:
	if site.has_node(named):
		return null
	var sprite := Sprite2D.new()
	if get_parent().region == "archive":
		var placement: Dictionary = ARCHIVE_PLACEMENT.get(String(site.name), {})
		if placement.has(kind):
			var dimensions: Vector2 = placement[kind]
			foot.x = dimensions.x
			width = dimensions.y
			if kind == "book_cart":
				var rails := site.get_node_or_null("Rails") as Line2D
				if rails != null and rails.get_child_count() == 0:
					rails.points = PackedVector2Array([Vector2(foot.x - 102, -2), Vector2(foot.x + 102, -2)])
	# Old site sketches described whole chambers; they are not a scale guide
	# for ordinary furniture. Keep foot offsets, but cap each real prop class.
	width = minf(width, float(MAX_WIDTH[kind]))
	if kind == "book_cart":
		var rails := site.get_node_or_null("Rails") as Line2D
		if rails != null: rails.points = PackedVector2Array([Vector2(foot.x - width*0.65,-2),Vector2(foot.x + width*0.65,-2)])
	sprite.name = named
	sprite.texture = atlases[kind]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
	sprite.position = foot
	sprite.scale = Vector2.ONE * width / sprite.texture.get_width()
	sprite.set_meta("painted_prop_kind", kind)
	site.add_child(sprite)
	for leaf in leaves:
		leaf.hide()
		retired.append(leaf)
	sprites.append(sprite)
	counts[kind] += 1
	return sprite
