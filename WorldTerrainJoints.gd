extends Node2D
## Small painted deposits where a real wall meets a real floor; never fake solids.
const Placement := preload("res://RouteDressingPlacement.gd")
const Support := preload("res://WorldSupport.gd")
const Detail := preload("res://RouteDetail.gd")
const Edge := preload("res://TerrainEdgeArt.gd")
const LIMIT := 36
var details: Array[Node2D] = []
var signature: Array[Rect2] = []
var room_id := ""

static func install(room: Node2D,id: String,nodes: Array[Node]) -> Node2D:
	var layer := room.get_node_or_null("TerrainJoints")
	if layer == null:
		layer = new(); layer.name = "TerrainJoints"; room.add_child(layer)
		layer.room_id = id; layer.set_process(false); layer.set_physics_process(false)
	layer.refresh(nodes); return layer

func refresh(nodes: Array[Node]) -> void:
	var solids := Support.solids(nodes)
	if solids != signature:
		for detail in details: detail.free()
		details.clear(); signature = solids; _build(nodes)
	var reserved := Placement.reservations(nodes)
	for detail in details: detail.visible = Placement.clear(detail.footprint,reserved)

func _build(nodes: Array[Node]) -> void:
	var reserved := Placement.reservations(nodes)
	var occupied: Array[Rect2] = []
	for node in nodes:
		if not is_instance_valid(node) or is_ancestor_of(node): continue
		if node is Detail and node.kind=="floor" and node.visible: occupied.append(node.footprint)
	var palette := Placement.family(room_id)
	var floors := Placement.floors(nodes)
	for wall in signature:
		if wall.size.y<90 or wall.size.x>150 or wall.size.y<wall.size.x*1.4: continue
		for floor_rect in floors:
			if wall.position.y>floor_rect.position.y-30 or wall.end.y<floor_rect.position.y-2: continue
			for side in [-1,1]:
				if details.size()>=LIMIT: return
				var edge: float = wall.end.x if side>0 else wall.position.x
				if edge<floor_rect.position.x or edge>floor_rect.end.x: continue
				var seed_value := posmod(int(edge*.17+floor_rect.position.y*.13)+room_id.hash(),997)
				var prop := Detail.new(); add_child(prop)
				prop.name = "WallFoot%02d"%details.size()
				prop.configure(palette,"floor",seed_value%5,34+seed_value%17,12+seed_value%6,Vector2(edge,floor_rect.position.y+.65),floor_rect)
				# Move the actual drawn footprint, not an assumed source size, to
				# within one pixel of the wall's playable face.
				var dx: float = edge+1-prop.footprint.position.x if side>0 else edge-1-prop.footprint.end.x
				prop.global_position.x += dx; prop.footprint = prop.art.global_transform*prop.art.get_rect()
				var probe: Rect2 = prop.footprint
				probe.size.y = maxf(0,floor_rect.position.y-.25-probe.position.y)
				if prop.footprint.position.x<floor_rect.position.x+1 or prop.footprint.end.x>floor_rect.end.x-1 or not Placement.clear(probe,signature) or not Placement.clear(prop.footprint,reserved) or not Placement.clear(prop.footprint.grow(3),occupied):
					prop.free(); continue
				prop.set_meta("joint_wall",wall)
				prop.set_meta("joint_side",side)
				_backing(prop,wall,side,nodes)
				details.append(prop); occupied.append(prop.footprint.grow(8))

func _backing(prop: Node2D,wall: Rect2,side: int,nodes: Array[Node]) -> void:
	# Cliff paintings deliberately have an irregular inner contour. At a
	# physical floor junction that alpha fringe can leave a black slit. Carry
	# a short piece of the actual floor face INTO the existing solid wall.
	var floor_rect: Rect2 = prop.support
	if wall.end.y<floor_rect.end.y+4 or floor_rect.size.y<8: return
	var family := "basalt" if room_id.begins_with("ash_") else ("citadel" if room_id.begins_with("starfall_") else ("shale" if Placement.family(room_id)=="mine" else "moss"))
	var variant := 0
	for node in nodes:
		if not is_instance_valid(node) or not node is CollisionShape2D or not node.shape is RectangleShape2D: continue
		if (node.global_transform*Rect2(-node.shape.size/2,node.shape.size)).is_equal_approx(floor_rect):
			var art := node.get_parent().get_node_or_null("TerrainEdgeArt")
			if art!=null: family = art.family; variant = art.variant
			break
	var entry: Array = Edge.DATA[family][variant]
	var source: Rect2 = entry[0]; var contact: float = entry[1]
	var factor := (floor_rect.size.y+minf(5,floor_rect.size.y*.3))/(source.end.y-contact)
	var reach := minf(28,wall.size.x)
	var sheet: Texture2D = load("res://art/visual_slice/terrain_edge_%s_v1.png"%family)
	var ratio := sheet.get_size()/Edge.SOURCE_SIZE
	var atlas := AtlasTexture.new(); atlas.atlas = sheet; atlas.filter_clip = true
	# Use the painted outer cap, not a rectangular cut out of the tile centre.
	# Its natural alpha edge disappears into the cliff instead of making a
	# conspicuous square lip at the end of the floor.
	var source_width := minf((reach+6)/factor,source.size.x)
	var source_x := source.position.x if side>0 else source.end.x-source_width
	atlas.region = Rect2(Vector2(source_x,source.position.y)*ratio,Vector2(source_width,source.size.y)*ratio)
	var bridge := Sprite2D.new(); bridge.name = "InsetRockJoin"; bridge.texture = atlas; bridge.centered = false
	bridge.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bridge.z_index = -1; prop.add_child(bridge)
	var edge: float = wall.end.x if side>0 else wall.position.x
	bridge.global_transform = Transform2D(0,Vector2.ONE*factor/ratio,0,Vector2(edge-reach if side>0 else edge-6,floor_rect.position.y-(contact-source.position.y)*factor))
	bridge.modulate = Color("a7b4b6") if family in ["moss","shale"] else Color("b4ada6")
	prop.set_meta("joint_backing_bounds",bridge.global_transform*bridge.get_rect())
