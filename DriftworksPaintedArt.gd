@tool
extends "res://RampartPaintedArt.gd"
## Reuse graph masking/terrain treatment with a mine-specific palette and props.

var carts: Array[Sprite2D] = []
var cart_anchors: Array[Vector2] = []
var cart_foot_y := 0


func _style() -> Dictionary:
	return {"region": "shaft", "background": "driftworks_depth_v1", "surface": "drift_iron_v1", "tint": Color("8bafb4"), "haze": Color("17363d"), "rim": Color("87bac4"), "retire": ["PumpRib", "PipeCap"]}


func _build_props() -> void:
	var texture := load("res://art/visual_slice/drift_ore_cart_v1.png") as Texture2D
	if texture == null:
		return
	var bitmap := texture.get_image()
	var used := bitmap.get_used_rect()
	cart_foot_y = used.end.y
	for row in range(used.end.y - 1, used.position.y - 1, -1):
		var solid_pixels := 0
		for column in range(used.position.x, used.end.x):
			if bitmap.get_pixel(column, row).a >= 0.5:
				solid_pixels += 1
		if solid_pixels >= 3:
			cart_foot_y = row + 1
			break
	var wing := get_parent()
	# Keep carts separate from field boards and their interactive supplies.
	var placements := {0: 0.42, 3: 0.83, 5: 0.53, 7: 0.40}
	for index in placements:
		var chamber: Rect2 = wing._main_rect(index)
		var anchor: Vector2 = wing._supported_point(index, false, chamber.position.x + chamber.size.x * placements[index], 9, 100)
		var fit: float = (58.0 + (index % 3) * 4.0) / used.size.x
		var sprite := Sprite2D.new()
		sprite.name = "OreCart%d" % index
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.centered = false
		sprite.scale = Vector2.ONE * fit
		sprite.position = anchor - Vector2(used.position.x + used.size.x * 0.5, cart_foot_y) * fit
		sprite.z_index = -7
		sprite.modulate = Color("aac1c1")
		add_child(sprite)
		carts.append(sprite)
		cart_anchors.append(anchor)
