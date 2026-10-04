extends RefCounted
const Atlas := preload("res://LivingSpriteAtlas.gd")
const TREASURE := "pickup_treasure_cycle_v1"
const MATERIAL := "pickup_material_cycle_v1"

static func configure(visual: Node2D, item: String) -> void:
	var definition: Array
	if item == "gold": definition=[TREASURE,0,12.0,273.0,6.0]
	elif item == "xp": definition=[TREASURE,4,15.0,271.0,6.0]
	elif "iron" in item or item.ends_with("_ore"): definition=[TREASURE,8,12.0,250.0,3.0]
	elif item == "healing_herb": definition=[MATERIAL,0,14.0,289.0,3.0]
	elif "ether" in item or "fragment" in item: definition=[MATERIAL,4,14.0,302.0,5.0]
	elif "sigil" in item or "crest" in item or "seal" in item:
		# Keep the authored quest token, not a misleading generic resource bag.
		preload("res://PickupMaterialArt.gd").item(visual,item)
		visual.remove_meta("pickup_cycle")
		return
	else: definition=[MATERIAL,8,13.0,246.0,4.0]
	var art := visual.get_node_or_null("PaintedPickup") as Sprite2D
	if art == null:
		art=Sprite2D.new();art.name="PaintedPickup";visual.add_child(art)
	visual.set_meta("pickup_cycle",definition)
	art.set_meta("atlas_frame",-1)
	preload("res://PickupMaterialArt.gd").retire_shapes(visual)
	animate(visual,0)

static func animate(visual: Node2D, age: float) -> void:
	if not visual.has_meta("pickup_cycle"): return
	var definition: Array=visual.get_meta("pickup_cycle")
	var frame: int=definition[1]+int(age*definition[4])%4
	var art: Sprite2D=visual.get_node("PaintedPickup")
	if art.get_meta("atlas_frame",-1)==frame: return
	Atlas.show(art,definition[0],frame,definition[2],5.0,1.0,definition[3])
	# Loot deliberately bobs, falls and scales in. Its root is not a static
	# world floor registration (unlike a lamp or a grounded resident).
	art.remove_meta("contact_floor")
