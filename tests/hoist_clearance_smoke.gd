extends "res://tests/boss_combat_presentation_smoke.gd"

const Support := preload("res://WorldSupport.gd")
const Art := preload("res://LiftMechanismArt.gd")

func _solid(parent: Node2D, at: Vector2, size: Vector2) -> CollisionShape2D:
	var body := StaticBody2D.new(); parent.add_child(body); body.position = at
	var shape := CollisionShape2D.new(); shape.shape = RectangleShape2D.new(); shape.shape.size = size
	body.add_child(shape)
	return shape

func _assert_clear(lift: Node2D, nodes: Array[Node], floor_rect: Rect2) -> void:
	var rig := lift.get_node("LiftGantry")
	var plan: Dictionary = rig.get_meta("clearance_plan")
	var head: Sprite2D = rig.get_node("WinchHead")
	_check(head.visible == (plan.mode == "gantry"),"Impossible gantry was drawn")
	if not head.visible: return
	var head_bounds: Rect2 = head.global_transform*head.get_rect()
	_check(head_bounds.size.x <= 69.1 and head_bounds.size.y <= 35,"Scaled room enlarged the winch")
	_check(is_equal_approx(head.global_scale.x,head.global_scale.y),"Winch stretched during fitting")
	for solid in Support.solids(nodes):
		_check(not plan.volume.intersects(solid),"Hoist travel volume clips terrain")
		_check(not head_bounds.grow(-0.1).intersects(solid),"Painted winch clips terrain")
	for named in ["LoadPostLeft","LoadPostRight"]:
		var post: Polygon2D = rig.get_node(named)
		for index in [0,3]:
			var foot: Vector2 = post.to_global(post.polygon[index])
			_check(foot.x >= floor_rect.position.x-0.05 and foot.x <= floor_rect.end.x+0.05 and absf(foot.y-floor_rect.position.y)<0.05,"Fitted post floats or overhangs")
	var deck: Sprite2D = lift.get_node("FinishedDevice")
	_check((deck.global_transform*deck.get_rect()).size.x <= 48.1,"Parent scale enlarged native lift deck artwork")
	var contact := deck.to_global(Vector2(0,-deck.texture.get_height()*0.5+float(deck.get_meta("contact_row"))))
	_check(absf(contact.y-floor_rect.position.y)<0.01,"Fitted deck floats")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hoist_clearance.json"; state.start_new_game("normal")
	var stage := Node2D.new(); root.add_child(stage)
	stage.position = Vector2(410,-360); stage.scale = Vector2(1.5,1.5)
	var ground := _solid(stage,Vector2(150,110),Vector2(300,20))
	var lift: Node2D = load("res://ShaftLift.tscn").instantiate()
	lift.target_marker_group = &"clearance_fixture_destination"
	stage.add_child(lift); lift.position = Vector2(150,86)
	var deck := Sprite2D.new(); deck.name = "FinishedDevice"; lift.add_child(deck)
	var native: CollisionShape2D = lift.get_node("CollisionShape2D")
	var native_transform := lift.transform
	var native_shape := native.shape
	var native_hitbox := native.transform
	var nodes: Array[Node] = [ground]
	var floors := Support.floors(nodes)
	var floor_rect := floors[0]
	Art.install(lift,floor_rect,"sunken_shaft",floors,nodes)
	var open_rig := lift.get_node("LiftGantry")
	_check(open_rig.get_meta("clearance_plan").head == Vector2(0,-62),"Open hoist unnecessarily shortened")
	_assert_clear(lift,nodes,floor_rect)
	Art.install(lift,floor_rect,"sunken_shaft",floors,nodes)
	_check(lift.get_node("LiftGantry") == open_rig,"Unchanged hoist duplicated its construction")
	# The Tide Well has two overlapping landing segments one world pixel
	# apart. This is legitimate footing, not an impossible overhead obstacle.
	var adjacent := _solid(stage,Vector2(125,209.333333),Vector2(36,20))
	nodes.append(adjacent); floors = Support.floors(nodes)
	Art.install(lift,floor_rect,"sunken_shaft",floors,nodes)
	_check(lift.get_node("LiftGantry").get_meta("clearance_plan").mode == "gantry" and lift.get_node("LiftGantry").get_meta("clearance_plan").head == Vector2(0,-62),"One-pixel shared footing erased an otherwise clear hoist")
	_assert_clear(lift,nodes,floor_rect)
	nodes.erase(adjacent); adjacent.get_parent().free()
	var ceiling := _solid(stage,Vector2(150,66),Vector2(300,8))
	nodes.append(ceiling); floors = Support.floors(nodes)
	Art.install(lift,floor_rect,"sunken_shaft",floors,nodes)
	var low_rig := lift.get_node("LiftGantry")
	_check(low_rig.get_meta("clearance_plan").head.y > -62,"Late low ceiling did not invalidate hoist art cache")
	_assert_clear(lift,nodes,floor_rect)
	Art.install(lift,floor_rect,"sunken_shaft",floors,nodes)
	_check(lift.get_node("LiftGantry") == low_rig,"Stable low-ceiling rig rebuilt")
	ceiling.get_parent().position.y = -100; floors = Support.floors(nodes)
	Art.install(lift,floor_rect,"sunken_shaft",floors,nodes)
	_check(lift.get_node("LiftGantry").get_meta("clearance_plan").head == Vector2(0,-62),"Raised ceiling kept cramped gantry")
	_assert_clear(lift,nodes,floor_rect)
	# 15 world pixels above the deck cannot contain even the smallest head.
	ceiling.get_parent().position.y = 94; floors = Support.floors(nodes)
	Art.install(lift,floor_rect,"sunken_shaft",floors,nodes)
	_check(lift.get_node("LiftGantry").get_meta("clearance_plan").mode == "deck_only","Impossible ceiling manufactured a clipped head")
	_assert_clear(lift,nodes,floor_rect)
	ceiling.disabled = true
	var west := _solid(stage,Vector2(128,55),Vector2(8,110))
	var east := _solid(stage,Vector2(172,55),Vector2(8,110))
	nodes.append_array([west,east]); floors = Support.floors(nodes)
	Art.install(lift,floor_rect,"starfall_citadel",floors,nodes)
	_check(lift.get_node("LiftGantry").get_meta("clearance_plan").width < 69,"Side walls ignored by hoist width fitting")
	_assert_clear(lift,nodes,floor_rect)
	_check(lift.transform == native_transform and native.transform == native_hitbox and native.shape == native_shape and lift.target_marker_group == &"clearance_fixture_destination","Art fitting changed native lift/navigation")
	stage.free(); state.delete_save()
	print("HOIST CLEARANCE TEST PASSED" if failures.is_empty() else "HOIST CLEARANCE TEST FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
