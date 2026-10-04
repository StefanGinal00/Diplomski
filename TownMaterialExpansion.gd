@tool
extends Node2D
## Reusable image materials on existing scenery. No gameplay geometry edits.

@export_enum("echo", "starfall") var theme := "echo"
@export var primary_texture: Texture2D
@export var secondary_texture: Texture2D
var painted: Array[Polygon2D] = []
var edges: Array[Rect2] = []
var edge_bodies: Array[StaticBody2D] = []
var built := false


func _ready() -> void:
	z_index = -1
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built or primary_texture == null or secondary_texture == null:
		return
	var town := get_parent()
	if theme == "echo":
		var bodies: Array[Node] = [town.get_node("Floor")]
		for named in ["UpperVillage", "NewDistricts"]:
			for child in town.get_node(named).get_children():
				if child is StaticBody2D:
					bodies.append(child)
		for body in bodies:
			var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if collision == null or not collision.shape is RectangleShape2D:
				continue
			var size: Vector2 = collision.shape.size
			if size.y > 22 or size.x < 80:
				continue
			var timber := String(body.name).contains("Balcony") or String(body.name).contains("RoofNook")
			for plate in body.get_children():
				if plate is Polygon2D:
					_paint(plate, secondary_texture if timber else primary_texture, 115 if timber else 110, Color(0.8, 0.92, 0.94))
			var top_left := to_local(collision.to_global(-size * 0.5))
			edges.append(Rect2(top_left, size))
			edge_bodies.append(body)
	else:
		for named in ["LinkTownhouse", "GardenLibrary", "ObservatoryTower", "LibraryRooftop/RoofArchive"]:
			_paint(town.get_node(named), primary_texture, 180, Color(0.66, 0.68, 0.81))
		for named in ["LinkRoof", "GardenLibraryRoof", "ObservatoryDome"]:
			_paint(town.get_node(named), secondary_texture, 125, Color(0.8, 0.8, 0.9))
		for plate in town.get_node("UpperCity").find_children("*", "Polygon2D", true, false):
			if not String(plate.get_parent().name).begins_with("House"):
				continue
			if plate.name == &"Facade":
				_paint(plate, primary_texture, 160, plate.color.lightened(0.25))
			elif plate.name == &"Roof":
				_paint(plate, secondary_texture, 110, Color(0.85, 0.84, 0.96))
	built = true
	queue_redraw()


func _paint(plate: Polygon2D, texture: Texture2D, tile_size: float, tint: Color) -> void:
	var bounds := Rect2(plate.polygon[0], Vector2.ZERO)
	for point in plate.polygon:
		bounds = bounds.expand(point)
	var uv := PackedVector2Array()
	for point in plate.polygon:
		uv.append((point - bounds.position) / tile_size * texture.get_size())
	plate.texture = texture
	plate.uv = uv
	plate.color = tint
	plate.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	painted.append(plate)


func _draw() -> void:
	for index in edges.size():
		if edge_bodies[index].has_node("TerrainEdgeArt"): continue
		var rect := edges[index]
		draw_line(rect.position + Vector2(0, 1), Vector2(rect.end.x, rect.position.y + 1), Color("a0c5c1"), 2)
