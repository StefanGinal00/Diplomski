@tool
extends Node2D
## The metal rod stays fixed; only the child cloth gently shears from its top.
## WorldAmbience handles distance, room state and the mobile animation budget.
const Atlas := preload("res://CivicGuardAtlas.gd")
var art: Sprite2D
var rod: Sprite2D
var phase := 0.0
var attachment := Vector2.ZERO

func configure(index: int,anchor: Vector2,height: float) -> void:
	global_position=anchor
	attachment=anchor
	set_process(false)
	var source:=Atlas.texture_for(3,index)
	var ratio:=source.atlas.get_size()/Atlas.SIZE
	var split:=76.0*ratio.y
	var top:=AtlasTexture.new()
	top.atlas=source.atlas; top.region=Rect2(source.region.position,Vector2(source.region.size.x,split)); top.filter_clip=true
	rod=Sprite2D.new(); rod.name="FixedRod"; rod.texture=top
	rod.scale=Vector2.ONE*height/source.get_height()
	rod.position.y=(split*0.5-37*ratio.y)*rod.scale.y
	rod.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(rod)
	var cloth:=AtlasTexture.new()
	cloth.atlas=source.atlas; cloth.region=Rect2(source.region.position+Vector2(0,split),source.region.size-Vector2(0,split)); cloth.filter_clip=true
	art=Sprite2D.new(); art.name="Cloth"; art.texture=cloth
	art.centered=false; art.offset=Vector2(-cloth.get_width()*0.5,0)
	art.scale=rod.scale; art.position.y=(split-37*ratio.y)*art.scale.y
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(art)
	phase=fposmod(anchor.x*0.043+index,TAU)
	set_meta("ambient_motion",true)

func animate(time: float) -> void:
	art.skew=sin(time*1.3+phase)*0.011+sin(time*2.1+phase)*0.003

func rest() -> void:
	art.skew=0
