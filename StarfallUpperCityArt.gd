@tool
extends Node2D
## Static 2D facade/streetscape detail. Original gameplay nodes stay untouched.

const INK := Color("202736")
const TRIM := Color("8585a0")
const BRASS := Color("b99b69")
const GLASS := Color("dfc997")
const TIMBER := preload("res://art/visual_slice/echo_walk_timber_v1.png")
const CityPaint := preload("res://CityStreetAtlas.gd")
const FacadePaint := preload("res://FacadePropAtlas.gd")
const Architecture := preload("res://CityArchitectureAtlas.gd")
var windows: Array[Rect2] = []
var doors: Array[Rect2] = []
var lamps: Array[Rect2] = []
var gardens: Array[Rect2] = []
var awnings: Array[Rect2] = []
var houses: Array[Rect2] = []
var bells: Array[Rect2] = []
var telescope_points := PackedVector2Array()
var telescope_base := Vector2.ZERO
var replaced: Array[CanvasItem] = []
var lens_base := Vector2.ZERO
var built := false


func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	_build()


func _bounds(plate: Polygon2D) -> Rect2:
	var rect := Rect2(to_local(plate.to_global(plate.polygon[0])), Vector2.ZERO)
	for point in plate.polygon:
		rect = rect.expand(to_local(plate.to_global(point)))
	return rect


func _replace(plate: Polygon2D, collection: Array[Rect2]) -> void:
	collection.append(_bounds(plate))
	replaced.append(plate)
	plate.hide()


func _build() -> void:
	if built:
		return
	for data in get_parent().DISTRICTS:
		var district := get_parent().get_node(String(data[0]))
		for child in district.get_children():
			var named := String(child.name)
			if named.begins_with("House"):
				houses.append(_bounds(child.get_node("Facade")))
				_replace(child.get_node("Door"), doors)
				for plate in child.get_children():
					if String(plate.name).begins_with("Window"):
						_replace(plate, windows)
			elif named.begins_with("LampLight"):
				_replace(child, lamps)
			elif named.begins_with("LampPost"):
				replaced.append(child)
				child.hide()
			elif named.begins_with("Planter"):
				_replace(child, gardens)
			elif named.begins_with("WorkshopAwning"):
				_dress_awning(child)
			elif named.begins_with("GardenTree"):
				replaced.append(child)
				child.hide()
			elif named in ["Bell0", "Bell1", "Bell2"]:
				_replace(child, bells)
	var lens := get_parent().get_node("CrownObservatory/CelestialLens") as Line2D
	var pedestal := get_parent().get_node("CrownObservatory/LensPedestal") as Polygon2D
	var pedestal_bounds := _bounds(pedestal)
	lens_base = Vector2(pedestal_bounds.get_center().x,pedestal_bounds.end.y+1)
	for old in [lens,pedestal]:
		replaced.append(old)
		old.hide()
	var telescope := get_parent().get_node_or_null("Workplace3/Telescope") as Polygon2D
	if telescope != null:
		telescope_points = PackedVector2Array([to_local(telescope.to_global(Vector2(-47, -57))), to_local(telescope.to_global(Vector2(77, -114)))])
		replaced.append(telescope)
		telescope.hide()
		telescope_base = to_local(telescope.get_parent().global_position)+Vector2(-55,2)
		var tripod := telescope.get_parent().get_node("Tripod") as Polygon2D
		replaced.append(tripod)
		tripod.hide()
	built = true
	queue_redraw()


func _arch(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(rect.position.x, rect.end.y)])
	var radius := rect.size.x * 0.5
	var center := rect.position + Vector2(radius, radius)
	for i in range(13):
		var angle := PI + PI * i / 12.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	points.append(rect.end)
	return points


func _window(rect: Rect2) -> void:
	CityPaint.draw_window(self,rect,int(rect.position.x)%2)


func _door(rect: Rect2) -> void:
	# Decorative residential doors remain scenery, with no interaction icon.
	# Facade base is deck_y-10, collider top deck_y-7.
	FacadePaint.door(self,Rect2(Vector2(rect.get_center().x-17,rect.end.y+3-48),Vector2(34,48)),2,int(rect.get_center().x/100)%2)


func _lamp(rect: Rect2) -> void:
	# LampLight top is authored at deck_y-115. Actual deck is 14px thick;
	# use its top (deck_y-7), not the old floating post's deck_y-8 endpoint.
	CityPaint.draw_ground(self,2,Vector2(rect.get_center().x,rect.position.y+108),97)


func _garden(rect: Rect2, index: int) -> void:
	# Reuse the painted planter already used at street level, with its actual
	# stone foot on the deck. No angular tree silhouette or flat purple box.
	CityPaint.draw_ground(self, 3, Vector2(rect.get_center().x, rect.end.y + 1), 52 + (index % 3) * 3)


func _dress_awning(plate: Polygon2D) -> void:
	plate.texture = TIMBER
	plate.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	plate.color = Color("b3bcc7")
	var uv := PackedVector2Array()
	for point in plate.polygon:
		uv.append(point * TIMBER.get_width() / 180.0)
	plate.uv = uv
	awnings.append(_bounds(plate))


func _draw() -> void:
	for rect in houses:
		var variant := 1 if rect.position.x>3650 and rect.position.y>-1000 else (2 if rect.position.y<-1300 else 0)
		for side in [rect.position.x+2,rect.end.x-14]:
			Architecture.trim(self,variant,Rect2(side,rect.position.y+2,12,rect.size.y-2),Color("9da7b0"))
		Architecture.trim(self,variant+3,Rect2(rect.position-Vector2(2,3),Vector2(rect.size.x+4,9)),Color("b2b5bb"))
		Architecture.fit(self,2,4 if variant==1 else 5,Rect2(rect.get_center().x-10,rect.position.y+14,20,25),Color("a8adb4"))
	for rect in windows:
		_window(rect)
	for rect in doors:
		_door(rect)
	for rect in lamps:
		_lamp(rect)
	for i in range(gardens.size()):
		_garden(gardens[i], i)
	for rect in awnings:
		for x in [rect.position.x + 9, rect.end.x - 9]:
			draw_polyline(PackedVector2Array([Vector2(x, rect.end.y), Vector2(x + 8, rect.end.y + 12), Vector2(x + 8, rect.end.y)]), Color("384251"), 3, true)
	for rect in bells:
		_bell(rect)
	if telescope_points.size() == 2:
		FacadePaint.draw_at(self,1,4,telescope_base,56)
	Architecture.ground(self,0,lens_base,72)
	Architecture.ground(self,1,lens_base+Vector2(215,0),54)


func _bell(rect: Rect2) -> void:
	FacadePaint.draw_at(self,1,3,Vector2(rect.get_center().x,rect.position.y),58)
