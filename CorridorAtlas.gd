extends RefCounted
## Read-only alpha registration; original generated PNGs remain unmodified.
const DATA := {"corridor_ash_clusters_v1":{"boxes":[[26,136,479,332],[529,206,478,254],[1032,177,484,288],[20,687,484,231],[530,657,475,268],[1030,594,485,326]],"corner_alpha":0,"size":[1536,1024]},"corridor_ash_overhangs_v1":{"boxes":[[18,157,733,355],[790,150,727,362],[59,512,678,411],[820,512,661,426]],"corner_alpha":0,"size":[1536,1024]},"corridor_cave_clusters_v1":{"boxes":[[11,171,501,307],[512,208,493,276],[1029,179,483,311],[13,618,499,311],[512,655,508,238],[1043,727,484,177]],"corner_alpha":0,"size":[1536,1024]},"corridor_cave_overhangs_v1":{"boxes":[[26,81,721,313],[774,100,740,322],[49,523,690,411],[820,528,670,453]],"corner_alpha":0,"size":[1536,1024]},"corridor_star_clusters_v1":{"boxes":[[12,115,483,356],[521,184,484,284],[1030,199,501,271],[13,640,487,299],[521,618,492,318],[1032,641,490,295]],"corner_alpha":0,"size":[1536,1024]},"corridor_star_overhangs_v1":{"boxes":[[41,171,714,246],[788,161,708,254],[68,562,643,394],[823,551,654,390]],"corner_alpha":0,"size":[1536,1024]}}

static func sprite(id: String, index: int, width: float) -> Sprite2D:
	var entry: Dictionary=DATA[id]
	var b: Array=entry.boxes[index]
	var texture: Texture2D=load("res://art/visual_slice/%s.png"%id)
	var ratio:=texture.get_size()/Vector2(entry.size[0],entry.size[1])
	var atlas:=AtlasTexture.new()
	atlas.atlas=texture
	atlas.region=Rect2(Vector2(b[0],b[1])*ratio,Vector2(b[2],b[3])*ratio)
	atlas.filter_clip=true
	var art:=Sprite2D.new()
	art.texture=atlas
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.scale=Vector2.ONE*width/atlas.region.size.x
	if id.ends_with("clusters_v1"):
		var contacts: Array = {"corridor_cave_clusters_v1":[305,274,309,293,235,169],"corridor_ash_clusters_v1":[330,252,287,229,266,324],"corridor_star_clusters_v1":[353,282,269,297,316,293]}[id]
		art.set_meta("contact_row",float(contacts[index])*ratio.y)
	return art
