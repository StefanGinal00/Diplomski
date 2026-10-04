extends RefCounted
## Two authored low ceiling pockets, attached below intact Pump Hall floor.
## Shaft mouths at -1675 and -1175 stay completely open. Floor below y=656.
const POCKETS := [Rect2(-2420,312,245,208), Rect2(-1515,312,175,190)]

static func install(expansion: Node2D) -> void:
	if expansion.has_node("LowerGalleryVaults"): return
	var group:=Node2D.new()
	group.name="LowerGalleryVaults"
	expansion.add_child(group)
	for i in POCKETS.size():
		var r: Rect2=POCKETS[i]
		var body:=StaticBody2D.new()
		body.name="RockCeiling%d"%i
		body.position=r.position
		group.add_child(body)
		var w:=r.size.x
		var h:=r.size.y
		var outline:=PackedVector2Array([Vector2.ZERO,Vector2(w,0),Vector2(w,h-50),Vector2(w-28,h-15),Vector2(w-65,h),Vector2(60,h-7),Vector2(24,h-22),Vector2(0,h-65)])
		var collision:=CollisionPolygon2D.new()
		collision.polygon=outline
		body.add_child(collision)
		var face:=Polygon2D.new()
		face.name="VaultRock"
		# Stop the dark inner fill well INSIDE the painted caps. It must never
		# become the visible, straight-sided lower silhouette of the ceiling.
		face.polygon=PackedVector2Array([Vector2.ZERO,Vector2(w,0),Vector2(w,h-88),Vector2(w-34,h-64),Vector2(34,h-64),Vector2(0,h-92)])
		face.z_index=-4
		body.add_child(face)
		preload("res://RoomArtFinish.gd")._material(face,preload("res://art/visual_slice/echo_path_stone_v1.png"),Color("142426"))
		# Rounded layered rock undersides conceal the structural polygon, not
		# the walking floor. Painted fringe is at most 9 units past the solid.
		for index in 3:
			var art:=preload("res://CorridorAtlas.gd").sprite("corridor_cave_overhangs_v1",2+index%2,w*0.56)
			art.name="VaultUnderside%d"%index
			art.z_index=-3
			body.add_child(art)
			var height: float=art.texture.get_height()*art.scale.y
			art.position=Vector2(w*(0.24+index*0.26),h-height*0.5-6-absf(index-1)*12)
			art.modulate=Color(0.52,0.65,0.66)
		body.set_meta("vault_profile",r)
