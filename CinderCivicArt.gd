@tool
extends Node2D
const FacadePaint := preload("res://FacadePropAtlas.gd")
const Wares := preload("res://WorkplaceAtlas.gd")
## Readable civic landmarks, drawn behind gameplay; no new entrances/physics.

const ROLES := {
	"BellFoundry": "foundry", "CaravanInn": "inn", "KilnSchool": "school",
	"ArchiveHall": "archive", "CopperLibrary": "library", "GateBarracks": "barracks",
}
var landmarks: Array[Dictionary] = []
var built := false


func _ready() -> void:
	z_index = -2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")


func _build() -> void:
	if built:
		return
	var district := get_parent().get_node("EasternDistricts")
	for named in ROLES:
		var home := district.get_node(named) as Polygon2D
		var bounds := Rect2(to_local(home.to_global(home.polygon[0])), Vector2.ZERO)
		for point in home.polygon:
			bounds = bounds.expand(to_local(home.to_global(point)))
		landmarks.append({"name": named, "role": ROLES[named], "bounds": bounds})
	built = true
	queue_redraw()


func _draw() -> void:
	var trim := preload("res://CityArchitectureAtlas.gd")
	var relief := preload("res://CivicGuardAtlas.gd")
	for entry in landmarks:
		var rect: Rect2=entry.bounds
		draw_set_transform(Vector2(rect.get_center().x,rect.end.y))
		var half:=rect.size.x*0.5
		var eave:=-rect.size.y+41.0
		for side in [-1.0,1.0]:
			trim.trim(self,1,Rect2(side*(half-9)-6,eave+9,12,-eave-9),Color("b2a094"))
		match entry.role:
			"foundry":
				FacadePaint.draw_at(self,1,5,Vector2(half-34,eave+2),66,44)
				relief.fit(self,2,5,Rect2(-43,eave+9,86,84),Color("bcb1a0"))
			"inn":
				# Timber is a material surface, not wide flat-colour strokes.
				for x in [-half+26,0.0,half-26]:
					draw_texture_rect(preload("res://art/visual_slice/echo_walk_timber_v1.png"),Rect2(x-3,eave+5,6,maxf(8,-85-eave-5)),true,Color("9b8072"))
				trim.trim(self,4,Rect2(-half+17,eave+42,rect.size.x-34,7))
				_arch_window(Vector2(0,eave+30),16,23)
				var awning:=Wares.texture_for(4)
				var size:=awning.get_size()*(115.0/awning.get_width())
				draw_texture_rect(awning,Rect2(Vector2(-size.x/2,-115),size),false)
			"school":
				trim.trim(self,4,Rect2(-half+10,eave+2,rect.size.x-20,8))
				relief.fit(self,2,2,Rect2(-32,-139,64,59))
			"archive":
				for side in [-1.0,1.0]:
					trim.trim(self,1,Rect2(side*(half-32)-10,eave+16,20,-eave-16))
				trim.trim(self,4,Rect2(-half+13,eave+10,rect.size.x-26,10))
				relief.fit(self,2,0,Rect2(-31,eave+35,62,60),Color("cbbcab"))
			"library":
				relief.fit(self,2,3,Rect2(-40,eave+27,80,80),Color("c4b8a3"))
				relief.fit(self,2,1,Rect2(-29,eave+115,58,39),Color("c4b8a3"))
				for side in [-1.0,1.0]:
					_arch_window(Vector2(side*(half-48),eave+85),13,34)
			"barracks":
				relief.fit(self,1,0,Rect2(-half+3,eave-22,rect.size.x-6,37),Color("b1a394"))
				relief.fit(self,2,4,Rect2(-22,eave+23,44,51),Color("b1a394"))
	draw_set_transform(Vector2.ZERO)

func _arch_window(at: Vector2,half: float,height: float) -> void:
	var picture:=preload("res://SettlementWindowAtlas.gd").texture_for(3)
	var size:=picture.get_size()*((height+half+4)/picture.get_height())
	draw_texture_rect(picture,Rect2(Vector2(at.x-size.x/2,at.y-half),size),false)
