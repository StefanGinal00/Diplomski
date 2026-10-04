extends Sprite2D
## Six locomotion in-betweens and eight attack beats, observing native timers.
## Owns no AI, damage, collider, cooldown, save state or reward.
const Atlas:=preload("res://LivingSpriteAtlas.gd")
var attack_id:=""
var motion_id:=""
var height:=80.0
var previous_frame:=-1
var previous_library:=""

func configure(id: String,display_height: float) -> void:
	attack_id="boss_%s_attack_v%d"%[id,3 if id=="ember_marshal" else 5]
	motion_id="boss_%s_motion_v%d"%[id,6 if id=="echo_matriarch" else 7]
	height=display_height
	set_process(false)
	hide()

func sample(owner_art: Sprite2D,force_release:=false) -> bool:
	if not Atlas.DATA.has(attack_id): hide();return false
	var sequence: RefCounted=owner_art.frame_sequence
	if sequence==null: hide();return false
	var windup: float=owner_art.presentation.sample_windup() if owner_art.presentation!=null else 0
	var recovery: float=owner_art._read("recovery_remaining",0)
	var charging: bool=float(owner_art._read("charge_remaining",0))>0
	var library:=attack_id
	var index:=0
	if force_release or charging or sequence.release_age<0.07:
		index=4
	elif windup>0:
		var progress:=1.0-windup/maxf(sequence.windup_peak,windup)
		index=clampi(int(progress*4),0,3)
	elif recovery>0:
		var progress:=1.0-recovery/maxf(sequence.recovery_peak,recovery)
		index=5+mini(2,int(progress*3))
	elif sequence.release_age<0.28:
		index=5+mini(2,int((sequence.release_age-0.07)/0.21*3))
	else:
		if not Atlas.DATA.has(motion_id): hide();return false
		library=motion_id
		if owner_art.hurt_remaining>0: index=7
		elif owner_art.pose_index==1:
			index=1+(int(sequence.hover_clock*8)%6 if owner_art.boss_id=="echo_matriarch" else int(owner_art.stride_distance/7)%6)
		else: index=0
	var reference: float=Atlas.DATA[library].boxes[0][3]
	var facing: float=-1 if owner_art.flip_h else 1
	Atlas.show(self,library,index,height/maxf(owner_art.base_scale,0.001),0,facing,reference,"root")
	remove_meta("contact_floor")
	set_meta("contact_floor_local",0.0)
	# The moth's articulated wing is not its anchor. Keep the thorax steady.
	if owner_art.boss_id=="echo_matriarch":
		var box: Array=Atlas.DATA[library].boxes[index]
		var ratio: Vector2=texture.atlas.get_size()/Vector2(Atlas.DATA[library].size[0],Atlas.DATA[library].size[1])
		position.y=(-height*0.48/owner_art.base_scale)+(texture.get_height()*0.5-(float(box[3])*0.58+2)*ratio.y)*scale.y
		remove_meta("contact_floor_local")
	previous_frame=index
	previous_library=library
	show()
	return true
