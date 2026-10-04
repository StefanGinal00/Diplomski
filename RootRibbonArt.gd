extends RefCounted
## Cosmetic curved bark ribbons; no collision or per-frame processing.
const BARK:=preload("res://art/visual_slice/ancient_root_bark_v1.png")
static func paint(line: Line2D, width: float=6.0, smooth: bool=true) -> void:
	if smooth:
		var curve:=Curve2D.new()
		curve.bake_interval=7
		for index in line.points.size():
			var before:=line.points[maxi(0,index-1)]
			var after:=line.points[mini(line.points.size()-1,index+1)]
			var tangent:=(after-before)*0.17
			curve.add_point(line.points[index],-tangent,tangent)
		line.points=curve.get_baked_points()
	line.texture=BARK
	line.texture_mode=Line2D.LINE_TEXTURE_TILE
	line.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	line.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	line.width=width
	line.default_color=Color("667770")
	line.joint_mode=Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode=Line2D.LINE_CAP_ROUND
	line.end_cap_mode=Line2D.LINE_CAP_ROUND
	var taper:=Curve.new()
	taper.add_point(Vector2(0,0.65))
	taper.add_point(Vector2(0.3,1))
	taper.add_point(Vector2(0.7,0.8))
	taper.add_point(Vector2(1,0.16))
	line.width_curve=taper
	line.set_meta("painted_root_ribbon",true)
