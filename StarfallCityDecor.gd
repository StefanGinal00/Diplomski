@tool
extends Node2D

const FIELD_OFFICE := preload("res://StarfallFieldOffice.gd")
const UPPER_CITY := preload("res://StarfallUpperCity.gd")

var lantern_glows: Array[Polygon2D] = []
var lantern_base_colors: Array[Color] = []
var dawn_rays: Array[Polygon2D] = []
var victory_active: bool = false
var animation_time: float = 0.0


func _ready() -> void:
	var upper := Node2D.new()
	upper.name = "UpperCity"
	upper.set_script(UPPER_CITY)
	add_child(upper)
	_build_city_depth()
	_build_district_life()
	for house in [
		[610.0, [575.0, 685.0], 272.0],
		[1370.0, [1300.0, 1440.0], 263.0],
		[1860.0, [1785.0, 1925.0], 275.0],
		[2420.0, [2355.0, 2540.0], 260.0],
		[3020.0, [2910.0, 3110.0], 255.0],
		[3500.0, [3370.0, 3660.0, 3780.0], 270.0],
		[4130.0, [4000.0, 4230.0], 270.0],
		[4560.0, [4450.0, 4700.0], 255.0],
		[5710.0, [5600.0, 5850.0], 240.0],
	]:
		_add_door(float(house[0]))
		for window_x in house[1]:
			_add_window(float(window_x), float(house[2]))
	for window_x in [3370.0, 3480.0, 3700.0, 3810.0]:
		_add_window(window_x, 155.0, true)
	for window_x in [5610.0, 5730.0, 5850.0]:
		_add_window(window_x, 155.0, true)
	for lamp_x in [770.0, 1420.0, 2200.0, 2760.0, 3150.0, 3690.0, 4270.0, 4820.0, 5530.0, 6050.0]:
		_add_street_lamp(lamp_x)
	for plant_x in [4400.0, 4780.0, 4890.0, 5030.0, 5160.0, 5320.0, 5480.0, 5940.0]:
		_add_planter(plant_x)
	for bench_x in [2740.0, 4330.0, 5240.0, 6000.0]:
		_add_bench(bench_x)
	_add_banner(3440.0, 116.0, Color(0.84, 0.47, 0.62, 0.9))
	_add_banner(3760.0, 116.0, Color(0.54, 0.72, 0.75, 0.9))
	_add_banner(5660.0, 104.0, Color(0.68, 0.65, 0.86, 0.9))
	_add_star_chart()
	for center_x in [950.0, 3595.0, 5500.0]:
		var ray := _polygon(_points([center_x - 18.0, 0.0, center_x + 18.0, 0.0, center_x + 145.0, 390.0, center_x - 145.0, 390.0]), Color(0.65, 0.9, 1.0, 0.12), -8)
		ray.hide()
		dawn_rays.append(ray)
	for glow in lantern_glows:
		lantern_base_colors.append(glow.color)
	if Engine.is_editor_hint():
		# Architecture is useful in the combined-world preview, while animated
		# light state and GameState signals belong only to the running game.
		set_process(false)
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.boss_progress_changed.connect(_on_boss_progress_changed)
		game_state.mode_changed.connect(_on_mode_changed)
	_refresh_victory_lights()
	if get_parent() == null or get_parent().get_node_or_null("RoomActivityDirector") == null:
		call_deferred("activate_room_population")


func activate_room_population() -> void:
	if Engine.is_editor_hint() or has_node("FieldOffice"):
		return
	var office := Node2D.new()
	office.name = "FieldOffice"
	office.position = Vector2(2890, 400)
	office.set_script(FIELD_OFFICE)
	add_child(office)


func _build_city_depth() -> void:
	# Three skyline layers and district bridges make the connected safe city
	# feel deeper than one street. These are scenery only; the existing stairs,
	# promenades and rooftop platforms remain the readable playable routes.
	var rear := _polygon(_points([
		0.0, 390.0, 0.0, 245.0, 260.0, 245.0, 260.0, 188.0, 470.0, 188.0,
		470.0, 260.0, 760.0, 260.0, 760.0, 145.0, 1040.0, 145.0, 1040.0, 238.0,
		1320.0, 238.0, 1320.0, 106.0, 1600.0, 106.0, 1600.0, 218.0, 1940.0, 218.0,
		1940.0, 156.0, 2250.0, 156.0, 2250.0, 244.0, 2550.0, 244.0, 2550.0, 118.0,
		2890.0, 118.0, 2890.0, 220.0, 3260.0, 220.0, 3260.0, 72.0, 3660.0, 72.0,
		3660.0, 206.0, 4010.0, 206.0, 4010.0, 132.0, 4350.0, 132.0, 4350.0, 226.0,
		4700.0, 226.0, 4700.0, 94.0, 5080.0, 94.0, 5080.0, 215.0, 5420.0, 215.0,
		5420.0, 62.0, 5810.0, 62.0, 5810.0, 198.0, 6250.0, 198.0, 6250.0, 390.0,
	]), Color(0.095, 0.12, 0.21, 0.94), -8)
	rear.name = "LayeredRearDistricts"
	for tower_data in [
		[1080.0, 390.0, 245.0, 300.0],
		[2730.0, 390.0, 315.0, 365.0],
		[3595.0, 390.0, 390.0, 430.0],
		[4920.0, 390.0, 300.0, 350.0],
		[5750.0, 390.0, 350.0, 410.0],
	]:
		var x := float(tower_data[0])
		var base_y := float(tower_data[1])
		var width := float(tower_data[2])
		var height := float(tower_data[3])
		var tower := _polygon(_points([
			x - width * 0.5, base_y, x - width * 0.43, base_y - height + 58.0,
			x - width * 0.18, base_y - height + 28.0, x, base_y - height - 46.0,
			x + width * 0.18, base_y - height + 28.0, x + width * 0.43, base_y - height + 58.0,
			x + width * 0.5, base_y,
		]), Color(0.15, 0.17, 0.29, 0.93), -7)
		tower.name = "SkyTower%d" % int(x)
		for row in range(3):
			var window_y := base_y - 92.0 - float(row) * 68.0
			for side in [-1.0, 1.0]:
				var window := _rect(x + side * 54.0 - 13.0, window_y, 26.0, 31.0, Color(0.78, 0.69, 0.57, 0.38), -6)
				window.name = "TowerWindow%d_%d_%d" % [int(x), row, int(side)]
	for bridge_data in [[1220.0, 2350.0, 116.0], [2860.0, 4320.0, 86.0], [4550.0, 5960.0, 126.0]]:
		var left := float(bridge_data[0])
		var right := float(bridge_data[1])
		var y := float(bridge_data[2])
		var bridge := _rect(left, y, right - left, 13.0, Color(0.46, 0.46, 0.61, 0.78), -5)
		bridge.name = "DistantSkybridge%d" % int(left)
		for support in range(5):
			var support_x := lerpf(left + 55.0, right - 55.0, float(support) / 4.0)
			var cable := _polygon(_points([support_x - 3.0, y, support_x + 3.0, y, support_x + 15.0, y + 92.0, support_x - 15.0, y + 92.0]), Color(0.28, 0.29, 0.43, 0.52), -6)
			cable.name = "BridgeSupport%d_%d" % [int(left), support]


func _build_district_life() -> void:
	# Starfall is one continuous city, but each stretch should still read as a
	# different neighbourhood at a glance. These lightweight props keep the
	# long safe street inhabited without adding more AI or blocking movement.
	var details := Node2D.new()
	details.name = "CityDistrictDetails"
	details.set_meta("district_count", 4)
	add_child(details)
	_build_civic_square(details)
	_build_market_details(details)
	_build_garden_details(details)
	_build_observatory_details(details)


func _build_civic_square(parent: Node2D) -> void:
	var district := Node2D.new()
	district.name = "CivicSquareDetails"
	district.set_meta("district_identity", "civic_crossroads")
	parent.add_child(district)
	# A low star fountain marks the otherwise quiet connection between the Ward
	# and Market and gives the player a landmark visible from both levels.
	_detail_polygon(district, "StarFountainBasin", _points([2450, 375, 2490, 348, 2625, 348, 2665, 375, 2638, 390, 2477, 390]), Color(0.38, 0.43, 0.55, 1), -1)
	_detail_polygon(district, "StarFountainCore", _star_points(Vector2(2557.0, 327.0), 30.0, 13.0, 8), Color(0.70, 0.79, 0.88, 0.82), -1)
	for stream in range(3):
		var offset := float(stream - 1) * 23.0
		_detail_line(district, "FountainStream%d" % stream, PackedVector2Array([Vector2(2557, 347), Vector2(2557 + offset, 314), Vector2(2557 + offset * 1.4, 348)]), Color(0.50, 0.84, 0.92, 0.54), 3.0, -1)
	_detail_rect(district, "NoticeBoard", 2715, 301, 116, 67, Color(0.43, 0.35, 0.42, 1), -1)
	_detail_rect(district, "NoticePostLeft", 2724, 365, 6, 26, Color(0.34, 0.29, 0.37, 1), -1)
	_detail_rect(district, "NoticePostRight", 2816, 365, 6, 26, Color(0.34, 0.29, 0.37, 1), -1)
	for note in range(5):
		var note_x := 2726.0 + float(note % 3) * 32.0
		var note_y := 310.0 + float(note / 3) * 28.0
		_detail_rect(district, "Notice%d" % note, note_x, note_y, 22.0, 17.0, Color(0.83, 0.78 - float(note % 2) * 0.08, 0.63, 0.86), 0)


func _build_market_details(parent: Node2D) -> void:
	var district := Node2D.new()
	district.name = "MarketLifeDetails"
	district.set_meta("district_identity", "covered_market")
	parent.add_child(district)
	var cloths := [Color(0.80, 0.43, 0.58, 0.92), Color(0.43, 0.66, 0.67, 0.92), Color(0.74, 0.57, 0.38, 0.92)]
	for stall in range(5):
		var x := 3090.0 + float(stall) * 238.0
		var cloth: Color = cloths[stall % cloths.size()]
		_detail_polygon(district, "Canopy%d" % stall, _points([x - 74, 307, x + 74, 307, x + 58, 334, x - 58, 334]), cloth, -1)
		_detail_rect(district, "Counter%d" % stall, x - 58.0, 348.0, 116.0, 11.0, Color(0.42, 0.31, 0.34, 1), -1)
		for post_offset in [-54.0, 50.0]:
			_detail_rect(district, "Post%d_%s" % [stall, "L" if post_offset < 0.0 else "R"], x + post_offset, 332.0, 4.0, 58.0, Color(0.35, 0.29, 0.34, 1), -1)
		for goods in range(4):
			var goods_x := x - 42.0 + float(goods) * 28.0
			_detail_polygon(district, "Goods%d_%d" % [stall, goods], _star_points(Vector2(goods_x, 343.0), 7.0, 4.0, 6), cloth.lightened(0.18), 0)
	# Hanging cloth and a delivery cart make the balcony and street feel like
	# one working market rather than two unrelated platform strips.
	_detail_line(district, "MarketClothesline", PackedVector2Array([Vector2(3330, 151), Vector2(3480, 168), Vector2(3640, 150), Vector2(3800, 166)]), Color(0.78, 0.70, 0.69, 0.64), 2.0, -1)
	for cloth in range(6):
		var x := 3370.0 + float(cloth) * 72.0
		_detail_polygon(district, "HangingCloth%d" % cloth, _points([x - 15, 157, x + 15, 160, x + 10, 195, x - 12, 191]), cloths[cloth % cloths.size()].darkened(0.05), -1)
	_detail_rect(district, "DeliveryCart", 3995, 351, 145, 31, Color(0.37, 0.29, 0.33, 1), -1)
	for wheel_x in [4022.0, 4114.0]:
		_detail_polygon(district, "CartWheel%d" % int(wheel_x), _circle_points(Vector2(wheel_x, 383), 15.0, 12), Color(0.25, 0.24, 0.30, 1), 0)


func _build_garden_details(parent: Node2D) -> void:
	var district := Node2D.new()
	district.name = "CelestialGardenDetails"
	district.set_meta("district_identity", "library_garden")
	parent.add_child(district)
	for bed in range(6):
		var x := 4385.0 + float(bed) * 190.0
		_detail_polygon(district, "GardenBed%d" % bed, _points([x - 69, 374, x + 69, 374, x + 55, 390, x - 55, 390]), Color(0.25, 0.43, 0.39, 1), -1)
		for plant in range(7):
			var plant_x := x - 51.0 + float(plant) * 17.0
			var height := 16.0 + float((bed * 7 + plant * 11) % 22)
			_detail_polygon(district, "Plant%d_%d" % [bed, plant], _points([plant_x - 6, 374, plant_x, 374 - height, plant_x + 6, 374]), Color(0.37 + float(plant % 2) * 0.06, 0.72, 0.56 + float(bed % 3) * 0.05, 0.92), 0)
	for arch in range(3):
		var x := 4865.0 + float(arch) * 185.0
		_detail_line(district, "VineTrellis%d" % arch, PackedVector2Array([Vector2(x - 67, 365), Vector2(x - 67, 291), Vector2(x, 261), Vector2(x + 67, 291), Vector2(x + 67, 365)]), Color(0.48, 0.69, 0.58, 0.77), 7.0, -1)
	# The small celestial dial is a quiet visual reward on the upper garden path.
	_detail_polygon(district, "CelestialDial", _circle_points(Vector2(5305, 139), 38.0, 20), Color(0.26, 0.38, 0.47, 0.94), -1)
	_detail_line(district, "CelestialNeedle", PackedVector2Array([Vector2(5305, 139), Vector2(5332, 105)]), Color(0.87, 0.84, 0.66, 0.92), 4.0, 0)


func _build_observatory_details(parent: Node2D) -> void:
	var district := Node2D.new()
	district.name = "ObservatoryDetails"
	district.set_meta("district_identity", "star_observatory")
	parent.add_child(district)
	# Armillary rings and a roof telescope give the last safe district a unique
	# silhouette before the player reaches the Outer Watch gate.
	for ring in range(3):
		var radius := 35.0 + float(ring) * 15.0
		var points := _circle_points(Vector2(5750, 105), radius, 26)
		points.append(points[0])
		var line := _detail_line(district, "ArmillaryRing%d" % ring, points, Color(0.66, 0.72, 0.88, 0.55 + float(ring) * 0.10), 3.0, -1)
		line.scale.y = 0.43 + float(ring) * 0.14
		line.rotation = -0.4 + float(ring) * 0.4
	_detail_line(district, "TelescopeTube", PackedVector2Array([Vector2(5840, 84), Vector2(5935, 37)]), Color(0.62, 0.65, 0.79, 0.92), 12.0, -1)
	_detail_line(district, "TelescopeLegLeft", PackedVector2Array([Vector2(5890, 61), Vector2(5860, 135)]), Color(0.43, 0.46, 0.60, 0.9), 6.0, -1)
	_detail_line(district, "TelescopeLegRight", PackedVector2Array([Vector2(5890, 61), Vector2(5920, 135)]), Color(0.43, 0.46, 0.60, 0.9), 6.0, -1)
	for crate in range(3):
		_detail_rect(district, "ChartCase%d" % crate, 5680.0 + float(crate) * 54.0, 348.0 - float(crate % 2) * 17.0, 44.0, 42.0 + float(crate % 2) * 17.0, Color(0.35, 0.34, 0.46, 1), -1)


func _detail_rect(parent: Node, node_name: String, x: float, y: float, width: float, height: float, color: Color, layer: int) -> Polygon2D:
	return _detail_polygon(parent, node_name, _points([x, y, x + width, y, x + width, y + height, x, y + height]), color, layer)


func _detail_polygon(parent: Node, node_name: String, points: PackedVector2Array, color: Color, layer: int) -> Polygon2D:
	var shape := Polygon2D.new()
	shape.name = node_name
	shape.polygon = points
	shape.color = color
	shape.z_index = layer
	parent.add_child(shape)
	return shape


func _detail_line(parent: Node, node_name: String, points: PackedVector2Array, color: Color, width: float, layer: int) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	line.z_index = layer
	parent.add_child(line)
	return line


func _circle_points(center: Vector2, radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _star_points(center: Vector2, outer_radius: float, inner_radius: float, points_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(points_count * 2):
		var angle := -PI * 0.5 + PI * float(index) / float(points_count)
		var radius := outer_radius if index % 2 == 0 else inner_radius
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _process(delta: float) -> void:
	animation_time += delta
	for index in range(lantern_glows.size()):
		lantern_glows[index].modulate.a = 0.7 + 0.2 * sin(animation_time * 2.0 + float(index) * 1.7)


func _on_boss_progress_changed(boss_id: String) -> void:
	if boss_id == "hollow_sovereign":
		_refresh_victory_lights()


func _on_mode_changed(_mode: String) -> void:
	_refresh_victory_lights()


func _refresh_victory_lights() -> void:
	var game_state := get_node_or_null("/root/GameState")
	victory_active = game_state != null and bool(game_state.defeated_bosses.get("hollow_sovereign", false))
	for index in range(lantern_glows.size()):
		var base_color := lantern_base_colors[index]
		lantern_glows[index].color = base_color.lerp(Color(0.68, 0.97, 1.0, base_color.a), 0.55) if victory_active else base_color
	for ray in dawn_rays:
		ray.visible = victory_active


func _add_door(center_x: float) -> void:
	if has_node("VisualStyleSlice") and center_x >= 2860 and center_x <= 4290:
		return # The market pilot supplies its own recessed facade doors.
	_rect(center_x - 24.0, 332.0, 48.0, 59.0, Color(0.15, 0.19, 0.28, 1), -2)
	_rect(center_x - 17.0, 340.0, 34.0, 51.0, Color(0.23, 0.27, 0.35, 1), -1)
	_rect(center_x + 10.0, 363.0, 3.0, 3.0, Color(1, 0.81, 0.52, 1), -1)
	_polygon(_points([center_x - 30.0, 333.0, center_x, 316.0, center_x + 30.0, 333.0]), Color(0.6, 0.55, 0.63, 1), -1)


func _add_window(center_x: float, top_y: float, upper: bool = false) -> void:
	if has_node("VisualStyleSlice") and center_x >= 2860 and center_x <= 4290:
		return # Avoid layering the old rectangular glass over the new arches.
	var width := 33.0 if upper else 40.0
	_rect(center_x - width * 0.5 - 3.0, top_y - 3.0, width + 6.0, 36.0, Color(0.16, 0.22, 0.3, 1), -2)
	var glass := _rect(center_x - width * 0.5, top_y, width, 27.0, Color(0.94, 0.75, 0.45, 0.68), -1)
	lantern_glows.append(glass)
	_rect(center_x - 2.0, top_y, 4.0, 27.0, Color(0.3, 0.32, 0.43, 1), 0)
	_rect(center_x - width * 0.5, top_y + 12.0, width, 3.0, Color(0.3, 0.32, 0.43, 1), 0)


func _add_street_lamp(center_x: float) -> void:
	_rect(center_x - 2.0, 299.0, 4.0, 92.0, Color(0.66, 0.64, 0.7, 1), -2)
	_rect(center_x - 11.0, 294.0, 22.0, 5.0, Color(0.67, 0.65, 0.72, 1), -1)
	var lamp := _polygon(_points([center_x - 10.0, 300.0, center_x + 10.0, 300.0, center_x + 7.0, 320.0, center_x - 7.0, 320.0]), Color(1, 0.82, 0.48, 0.85), -1)
	lantern_glows.append(lamp)
	_rect(center_x - 7.0, 321.0, 14.0, 3.0, Color(0.7, 0.68, 0.72, 1), -1)


func _add_planter(center_x: float) -> void:
	_polygon(_points([center_x - 18.0, 365.0, center_x + 18.0, 365.0, center_x + 12.0, 390.0, center_x - 12.0, 390.0]), Color(0.44, 0.42, 0.51, 1), -1)
	for offset_x in [-12.0, 0.0, 12.0]:
		_polygon(_points([center_x + offset_x - 13.0, 367.0, center_x + offset_x, 338.0 - absf(offset_x) * 0.4, center_x + offset_x + 13.0, 367.0]), Color(0.37, 0.7, 0.57, 0.9), -2)


func _add_bench(center_x: float) -> void:
	_rect(center_x - 35.0, 364.0, 70.0, 7.0, Color(0.59, 0.5, 0.54, 1), -1)
	_rect(center_x - 29.0, 370.0, 4.0, 21.0, Color(0.5, 0.44, 0.51, 1), -1)
	_rect(center_x + 25.0, 370.0, 4.0, 21.0, Color(0.5, 0.44, 0.51, 1), -1)


func _add_banner(center_x: float, top_y: float, cloth_color: Color) -> void:
	_polygon(_points([center_x - 20.0, top_y, center_x + 20.0, top_y, center_x + 17.0, top_y + 47.0, center_x, top_y + 36.0, center_x - 17.0, top_y + 47.0]), cloth_color, -2)


func _add_star_chart() -> void:
	var center := Vector2(5750.0, 189.0)
	var points := PackedVector2Array()
	for index in range(17):
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle), sin(angle)) * 48.0)
	_polygon(points, Color(0.17, 0.27, 0.39, 1), -2)
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var star := center + Vector2(cos(angle), sin(angle)) * 31.0
		_rect(star.x - 2.0, star.y - 2.0, 4.0, 4.0, Color(0.91, 0.86, 0.63, 0.9), -1)


func _rect(x: float, y: float, width: float, height: float, color: Color, layer: int) -> Polygon2D:
	return _polygon(_points([x, y, x + width, y, x + width, y + height, x, y + height]), color, layer)


func _points(values: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(0, values.size(), 2):
		points.append(Vector2(float(values[index]), float(values[index + 1])))
	return points


func _polygon(points: PackedVector2Array, color: Color, layer: int) -> Polygon2D:
	var shape := Polygon2D.new()
	shape.polygon = points
	shape.color = color
	shape.z_index = layer
	add_child(shape)
	return shape
