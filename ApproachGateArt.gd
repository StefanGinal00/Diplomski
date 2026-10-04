@tool
extends Node2D
## Explicit gate replacements, never changes a collider, actor or arrival.
const Atlas := preload("res://GateDressingAtlas.gd")
const Support := preload("res://WorldSupport.gd")
var retired: Array[CanvasItem] = []
var pieces: Array[Sprite2D] = []
var plants: Array[Node2D] = []
var built := false

static func install(room: Node2D,floors: Array[Rect2]) -> Node2D:
	var existing := room.get_node_or_null("ApproachGateArt")
	if existing!=null: return existing
	if String(room.name) not in ["EchoHaven","EchoHavenOutskirts"]: return null
	var art := preload("res://ApproachGateArt.gd").new()
	art.name="ApproachGateArt"
	room.add_child(art)
	art._build(floors)
	return art

func _ready() -> void:
	z_index=-2
	set_process(false)

func _build(floors: Array[Rect2]) -> void:
	if built: return
	var room := get_parent() as Node2D
	var outside := room.name==&"EchoHavenOutskirts"
	var route := room.get_node("GateApproach" if outside else "NewDistricts")
	# The original entry arch and the expansion's tower occupied the same spot.
	# A single open gateway now spans the transition square, before the houses.
	var gate_x := 1005 if outside else 1250
	var gate_width := 246 if outside else 160
	var gate := _place(2 if outside else 0,0,room.to_global(Vector2(gate_x,156)),gate_width,floors,"LowerGate")
	if gate!=null:
		for named in ["QuarterGateTowerL","QuarterGateTowerR","QuarterGateArch"]: _retire(route.get_node_or_null(named))
		if outside:
			for named in ["GateLeftPillar","GateRightPillar","GateLintel","GateGlow"]: _retire(room.get_node_or_null(named))
		for side in [-1,1]:
			_place(3,3 if side<0 else 4,room.to_global(Vector2(gate_x+side*(gate_width*0.5+10),156)),34,floors,"GateRubble"+str(side))
	# The ward has a real RoomDoor. Its approach arch stays behind that facade.
	if outside:
		var door := room.get_node("GateDoor") as Node2D
		if _place(1,0,door.global_position-Vector2(30,0),194,floors,"WardArch")!=null:
			for named in ["GrandGateLeft","GrandGateRight","GrandGateLintel"]: _retire(route.get_node_or_null(named))
		var broken := room.get_node_or_null("BrokenPillar") as Polygon2D
		if broken!=null and _place(3,1,room.to_global(Vector2(223,156)),30,floors,"RoadPier")!=null: _retire(broken)
		# These decorative garden wedges had no painter in the outer district.
		# Keep vegetation only where a real terrace supports it, not over gaps.
		for old in route.get_children():
			if not old is Polygon2D or not String(old.name).begins_with("Garden"): continue
			var bounds := Rect2(old.to_global(old.polygon[0]),Vector2.ZERO)
			for point in old.polygon: bounds=bounds.expand(old.to_global(point))
			var support := Support.below(Vector2(bounds.get_center().x,bounds.end.y-35),floors,90)
			if support.has_area() and support.size.x>=40:
				var plant := preload("res://AmbientSetpiece.gd").new()
				plant.name="WardGrowth%02d"%plants.size()
				add_child(plant)
				plant.configure(0,1,Vector2(clampf(bounds.get_center().x,support.position.x+14,support.end.x-14),support.position.y),16+plants.size()%6,support,"floor")
				plants.append(plant)
			_retire(old)
	else:
		# Small grounded buttresses relate the older court to the repaired gate.
		_place(3,0,room.to_global(Vector2(1150,156)),18,floors,"CourtPier")
		_place(3,2,room.to_global(Vector2(1340,156)),18,floors,"QuarterPier")
		_place(3,5,room.to_global(Vector2(1140,156)),30,floors,"QuarterRubble")
	built=true

func _place(sheet: int,index: int,at: Vector2,width: float,floors: Array[Rect2],named: String) -> Sprite2D:
	var support := Support.below(at-Vector2(0,2),floors,80)
	if not support.has_area(): return null
	# Both visible feet must be supported, including coplanar bridge joins.
	for x in [at.x-width*0.43,at.x+width*0.43]:
		var foot := Support.below(Vector2(x,support.position.y),floors,3)
		if not foot.has_area() or absf(foot.position.y-support.position.y)>0.1: return null
	var art := Atlas.grounded(self,named,sheet,index,Vector2(at.x,support.position.y),width)
	art.modulate=Color("929d99")
	art.set_meta("support_rect",support)
	pieces.append(art)
	return art

func _retire(node: Node) -> void:
	if node is CanvasItem:
		node.hide()
		retired.append(node)
