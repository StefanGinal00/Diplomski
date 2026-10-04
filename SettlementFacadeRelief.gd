extends Node2D
## Wall-bound details and grounded REAR piers, never collision or new paths.
## One static draw list per settlement. No image readbacks or per-prop ticks.
const Art := preload("res://FacadeReliefAtlas.gd")
const Support := preload("res://WorldSupport.gd")
const Facades := preload("res://FacadePropAtlas.gd")
var painter: Node2D
var floors: Array[Rect2] = []
var entries: Array[Dictionary] = []
var piers: Array[Dictionary] = []
var pieces: Array[Dictionary] = []
var rear: Node2D
var built := false
var family := 0

static func install(room: Node, building_painter: Node2D) -> Node2D:
	if building_painter.has_node("FacadeRelief"): return building_painter.get_node("FacadeRelief")
	var relief := new()
	relief.name = "FacadeRelief"
	relief.painter = building_painter
	relief.family = 1 if building_painter.theme == "cinder" else 0
	building_painter.add_child(relief)
	return relief

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")

func _build() -> void:
	if built: return
	floors = painter.floors
	var reserves: Array[Rect2] = []
	for window in painter.window_art: reserves.append(window.rect.grow(4))
	var facade := painter.get_parent().get_node_or_null("ResidentialFacadeDetails")
	if facade != null:
		for entry in facade.entries:
			if entry.kind != "door": continue
			var index: int = facade.family + (3 if entry.index % 2 else 0)
			var rect := Facades.contact_rect(0, index, entry.at, entry.height, entry.width)
			reserves.append(global_transform.affine_inverse() * facade.global_transform * rect.grow(3))
	for home in painter.painted:
		if home.texture != painter.wall_texture or home.polygon.size() < 4: continue
		var points := PackedVector2Array()
		for point in home.polygon: points.append(to_local(home.to_global(point)))
		var bounds := Rect2(points[0], Vector2.ZERO)
		for point in points: bounds = bounds.expand(point)
		if bounds.size.x < 70 or bounds.size.y < 60: continue # Not chimneys.
		var seed_value := absi(String(home.name).hash())
		var index: int = [0,1,2,3][seed_value % 4] if family == 0 else [1,4,5][seed_value % 3]
		for side in [-1,1]:
			for inset in [14,27,40]:
				var x: float = bounds.position.x + inset if side < 0 else bounds.end.x - inset
				var placed := false
				for drop in [16,25,34,44,54]:
					var rect := Rect2(x-6, bounds.position.y+drop, 12, bounds.size.y-drop-2)
					if rect.size.y < 35 or not _clear(rect, points, reserves): continue
					entries.append({"kind":"pilaster", "index":index, "rect":rect, "home":home})
					reserves.append(rect.grow(2))
					_column(pieces, rect, index, Color(0.72,0.77,0.77))
					placed = true
					break
				if placed: break
		# A small patch attaches to a real joint, never a free-floating object.
		var growth_index: int = [0,1,2,5][seed_value % 4] if family == 0 else [3,4][seed_value % 2]
		var image := Art.texture_for(1, growth_index)
		var growth_placed := false
		for factor in [1.0,0.75,0.6]:
			var size: Vector2 = image.get_size() * (minf(39,bounds.size.y*0.37)*float(factor)/image.get_height())
			for y in [bounds.position.y+38,bounds.end.y-size.y-8]:
				for inset in [29,7,46]:
					for side in [-1,1]:
						var rect := Rect2(Vector2(bounds.position.x+inset if side<0 else bounds.end.x-size.x-inset,y),size)
						if not _clear(rect, points, reserves): continue
						entries.append({"kind":"ivy", "index":growth_index, "rect":rect, "home":home})
						pieces.append({"texture":image,"rect":rect,"source":Rect2(Vector2.ZERO,image.get_size()),"tint":Color(0.83,0.85,0.79)})
						reserves.append(rect.grow(2))
						growth_placed = true
						break
					if growth_placed: break
				if growth_placed: break
			if growth_placed: break
		_add_piers(bounds, index)
	rear = Node2D.new()
	rear.name = "GroundedRearPiers"
	rear.z_as_relative = false
	rear.z_index = -3 # Behind facade, native floors and every actor.
	rear.texture_filter = texture_filter
	add_child(rear)
	rear.draw.connect(_draw_rear)
	built = true
	queue_redraw(); rear.queue_redraw()

func _clear(rect: Rect2, points: PackedVector2Array, reserves: Array[Rect2]) -> bool:
	for corner in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		if not Geometry2D.is_point_in_polygon(corner, points): return false
	for obstacle in reserves:
		if rect.intersects(obstacle): return false
	var world: Rect2 = global_transform * rect
	for floor_rect in floors:
		if world.intersects(floor_rect.grow(1)): return false
	return true

func _add_piers(bounds: Rect2, index: int) -> void:
	for x in [bounds.position.x+20,bounds.end.x-20]:
		var foot := to_global(Vector2(x,bounds.end.y))
		var top := Support.below(foot-Vector2(0,10),floors,22)
		if not top.has_area() or foot.x-7<top.position.x or foot.x+7>top.end.x: continue
		var bottom := Support.below(Vector2(foot.x,top.end.y+4),floors,245)
		if not bottom.has_area() or bottom.position.y-top.end.y<35 or foot.x-7<bottom.position.x or foot.x+7>bottom.end.x: continue
		var rect: Rect2 = global_transform.affine_inverse() * Rect2(Vector2(foot.x-7,top.end.y-2),Vector2(14,bottom.position.y-top.end.y+2))
		var duplicate := false
		for pier in piers:
			if rect.grow(4).intersects(pier.rect): duplicate=true;break
		if duplicate: continue
		var segments: Array[Dictionary] = []
		_column(segments,rect,index,Color(0.48,0.58,0.6))
		piers.append({"rect":rect,"top":top,"bottom":bottom,"pieces":segments})

func _column(target: Array[Dictionary], rect: Rect2, index: int, tint: Color) -> void:
	var image := Art.texture_for(0,index)
	var scale_value := rect.size.x/image.get_width()
	var cap := minf(110*Art.SHEETS[0].get_height()/1024.0*scale_value,rect.size.y*0.28)
	var foot := minf(80*Art.SHEETS[0].get_height()/1024.0*scale_value,rect.size.y*0.22)
	var unit := image.get_height()*scale_value-cap-foot
	var cap_source := cap/scale_value
	var foot_source := foot/scale_value
	target.append({"texture":image,"rect":Rect2(rect.position,Vector2(rect.size.x,cap)),"source":Rect2(0,0,image.get_width(),cap_source),"tint":tint})
	var y := rect.position.y+cap
	while y<rect.end.y-foot-0.001:
		var height := minf(unit,rect.end.y-foot-y)
		target.append({"texture":image,"rect":Rect2(rect.position.x,y,rect.size.x,height),"source":Rect2(0,cap_source,image.get_width(),height/scale_value),"tint":tint})
		y += height
	target.append({"texture":image,"rect":Rect2(rect.position.x,rect.end.y-foot,rect.size.x,foot),"source":Rect2(0,image.get_height()-foot_source,image.get_width(),foot_source),"tint":tint})

func _draw() -> void:
	_draw_pieces(self,pieces)

func _draw_rear() -> void:
	for pier in piers: _draw_pieces(rear,pier.pieces)

func _draw_pieces(canvas: CanvasItem, list: Array[Dictionary]) -> void:
	for piece in list:
		canvas.draw_texture_rect_region(piece.texture,piece.rect,piece.source,piece.tint,false,true)
