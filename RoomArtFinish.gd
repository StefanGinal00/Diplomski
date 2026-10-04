@tool
extends RefCounted
## Explicit background retirement and collision-preserving terrain material pass.
const ENTRY_SCENERY := {
	"BlackwaterCistern": ["Masonry"],
	"StarfallOutskirts": ["FarSpire", "BrokenWall", "DustGlow"],
	"StarfallMemoryVault": ["VaultRibs"],
	"StarfallRootedHall": ["RootChamber"],
	"StarfallSilentGate": ["DeadTowers"],
	"StarfallSoulCrucible": ["VaultSilhouette"],
	"StarfallSunlessPassage": ["Ridge"],
	"PrismArchive": ["VaultArch"],
	"VerticalChamber": ["ShaftStrata"],
	"ShaftHollow": ["DeepStone"],
	"DrownedCrossing": ["BrokenAqueduct"],
	"FloodedGallery": ["AqueductArches"],
	"WardenApproach": ["BrokenGantry"],
	"EchoGallery": ["CavernRibs", "BackgroundCrystals"],
	"TideWell": ["RockFace"],
	"EchoNest": ["NestWalls"],
	"CrystalCauseway": ["CrystalFault"],
	"UndertowVault": ["VaultRibs"],
	"ResonanceSanctum": ["Vault", "RearRibs"],
	"BrokenCauseway": ["CinderSpine"],
	"EmberBarracks": ["StoneRanks"],
	"SlagReservoir": ["CoolingBasin"],
	"AshChapel": ["StainedWall"],
	"EchoHavenOutskirts": ["DistantCrystals"],
	"CinderHearthOutskirts": ["DistantRampart"],
	"StarfallCitadel": ["FarCity"],
}


static func apply(room: Node2D, family: String) -> Dictionary:
	var report := {"retired": [], "surfaces": [], "equipment": []}
	for named in ENTRY_SCENERY.get(String(room.name), []):
		var node := room.get_node_or_null(NodePath(named)) as Polygon2D
		if node != null and node.get_child_count() == 0 and node.z_index < 0:
			node.hide()
			report.retired.append(node)
	for route_name in ["AuthoredDescent", "StarfallDescent"]:
		for route in room.find_children(route_name, "Node2D", true, false):
			for node in route.get_children():
				if node is Polygon2D and String(node.name).begins_with("Pier") and node.get_child_count() == 0 and node.z_index < 0:
					node.hide()
					report.retired.append(node)
	var filename := "echo_path_stone_v1"
	var tint := Color("86a4a9")
	if family == "starfall":
		filename = "starfall_masonry_v1"
		tint = Color("a7a3b5")
	elif family == "ash":
		filename = "cinder_masonry_v1"
		tint = Color("b3a098")
	var texture := load("res://art/visual_slice/%s.png" % filename) as Texture2D
	if room.name == "StarfallCitadel":
		for path in ["GateDistrict/Backdrop", "GateDistrict/DistantSpire", "WardDistrict/Backdrop", "WardDistrict/DistantTerraces"]:
			var old := room.get_node_or_null(path) as Polygon2D
			if old != null and old.get_child_count() == 0:
				old.hide()
				report.retired.append(old)
		var roof := load("res://art/visual_slice/starfall_roof_tiles_v1.png") as Texture2D
		for path in ["GateDistrict/GateArch", "GateDistrict/WatchHouse", "WardDistrict/HouseWest", "WardDistrict/HouseEast"]:
			var house := room.get_node_or_null(path) as Polygon2D
			if house != null:
				_material(house, texture, Color("a09eb0"))
				report.equipment.append(house)
		for path in ["GateDistrict/WatchRoof", "WardDistrict/WestRoof", "WardDistrict/EastRoof"]:
			var house := room.get_node_or_null(path) as Polygon2D
			if house != null:
				_material(house, roof, Color("999eaf"))
				report.equipment.append(house)
		for skyline in room.find_children("*", "Polygon2D", true, false):
			var named := String(skyline.name)
			if named == "LayeredRearDistricts" and skyline.get_child_count() == 0:
				skyline.hide()
				report.retired.append(skyline)
			elif named.begins_with("SkyTower") or (named == "SteppedSilhouette" and String(skyline.get_parent().name).begins_with("UpperSkyline")):
				_material(skyline, texture, Color("394151"))
				report.equipment.append(skyline)
	for body in room.find_children("*", "StaticBody2D", true, false):
		if body.is_in_group("breakable"):
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var visual := body.get_node_or_null("Visual") as Polygon2D
		if visual == null:
			visual = body.get_node_or_null("Stone") as Polygon2D
		if collision == null or visual == null or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = collision.shape.size
		if size.y > 32 or size.x < 40 or size.x <= size.y or visual.texture != null or not visual.visible:
			continue
		_material(visual, texture, tint)
		report.surfaces.append(visual)
		# A narrow top seam keeps the actual collision edge readable.
		var rim := Line2D.new()
		rim.name = "MaterialRim"
		rim.points = PackedVector2Array([Vector2(-size.x / 2, -size.y / 2 + 1), Vector2(size.x / 2, -size.y / 2 + 1)])
		rim.width = 1.3
		rim.default_color = tint.lightened(0.12)
		visual.add_child(rim)
	if room.name == "BlackwaterCistern":
		var metal := load("res://art/visual_slice/drift_iron_v1.png") as Texture2D
		for tank in room.find_children("CisternPressureCell*", "Polygon2D", true, false):
			if tank.texture != null:
				continue
			_material(tank, metal, Color("71939a"))
			var outline := Line2D.new()
			outline.name = "RivetedSeam"
			outline.points = tank.polygon.duplicate()
			outline.add_point(tank.polygon[0])
			outline.width = 3
			outline.default_color = Color("799397")
			tank.add_child(outline)
			for point in tank.polygon:
				var bolt := Polygon2D.new()
				bolt.name = "Rivet"
				bolt.position = point.lerp(_center(tank.polygon), 0.07)
				bolt.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(2, -3), Vector2(3, 2), Vector2(-2, 3)])
				bolt.color = Color("b5b6a2")
				tank.add_child(bolt)
			report.equipment.append(tank)
		for gauge in room.find_children("CisternGauge*", "Polygon2D", true, false):
			if gauge.has_node("GaugeRim"):
				continue
			gauge.color = Color("263a40")
			var ring := Line2D.new()
			ring.name = "GaugeRim"
			ring.points = gauge.polygon.duplicate()
			ring.add_point(gauge.polygon[0])
			ring.width = 3
			ring.default_color = Color("a0afa7")
			gauge.add_child(ring)
			var needle := Line2D.new()
			needle.name = "PressureNeedle"
			var center := _center(gauge.polygon)
			needle.points = PackedVector2Array([center + Vector2(-5, 6), center, center + Vector2(7, -11)])
			needle.width = 2
			needle.default_color = Color("d4c096")
			gauge.add_child(needle)
	return report


static func _center(points: PackedVector2Array) -> Vector2:
	var result := Vector2.ZERO
	for point in points:
		result += point
	return result / points.size()


static func _material(visual: Polygon2D, texture: Texture2D, tint: Color) -> void:
	visual.texture = texture
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	visual.color = tint
	var uv := PackedVector2Array()
	for point in visual.polygon:
		uv.append(point * 3.0)
	visual.uv = uv
