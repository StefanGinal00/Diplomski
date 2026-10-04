@tool
extends Node2D
## Top-ring pivot; WorldAmbience alone drives this, never an individual timer.
const Atlas := preload("res://SettlementDetailAtlas.gd")
var art: Sprite2D
var variant := 0
var phase := 0.0
var attachment := Vector2.ZERO
var attachment_kind := "rope"

func configure(index: int, anchor: Vector2, height: float, kind: String) -> void:
	variant = index
	global_position = anchor
	attachment = anchor
	attachment_kind = kind
	phase = fposmod(anchor.x*0.073+anchor.y*0.023,TAU)
	z_index = 0 # Parent dressing layer is already behind actors at -1.
	set_process(false)
	art = Sprite2D.new()
	art.name = "Cloth" if index>=3 else "Lantern"
	art.texture = Atlas.texture_for(1,index)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.scale = Vector2.ONE*height/art.texture.get_height()
	art.position.y = (art.texture.get_height()*0.5-Atlas.contact(1,index))*art.scale.y
	add_child(art)
	set_meta("ambient_motion",true)

func animate(time: float) -> void:
	var gust := 0.6+0.4*sin(time*0.27+phase)
	rotation = (sin(time*1.15+phase)*0.017+sin(time*2.2+phase)*0.004)*gust
	# Gentle fabric shear about the fixed top ring; solid lantern stays rigid.
	skew = sin(time*1.7+phase)*0.009*gust if variant>=3 else 0.0

func rest() -> void:
	rotation = 0
	skew = 0
