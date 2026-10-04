extends "res://tests/audit_repair_assets.gd"
## Offline read-only source-alpha registration; never edits generated PNGs.
func _initialize() -> void:
	var files: Array = []
	for family in ["cave","ash","star"]:
		files.append(["art/visual_slice/foreground_%s_breeze_v1.png" % family,4,3])
		files.append(["art/visual_slice/terrain_segments_%s_v1.png" % family,3,2])
	for kind in ["treasure","material"]: files.append(["art/visual_slice/pickup_%s_cycle_v1.png" % kind,4,3])
	for id in ["void_sentinel","abyss_warden","echo_matriarch","ash_castellan","ember_marshal","starfall_guardian","hollow_sovereign"]:
		for version in [3,4,5]: files.append(["art/visual_slice/boss_%s_attack_v%d.png" % [id,version],4,2])
		files.append(["art/visual_slice/boss_%s_motion_v6.png"%id,4,2])
	for family in ["cave","ash","star"]: files.append(["art/visual_slice/resident_gestures_%s_v1.png"%family,4,2])
	for id in ["enemy","fiend","root","sentry"]: files.append(["art/visual_slice/mob_attack_%s_v1.png"%id,4,2])
	var report := []
	for spec in files:
		if not FileAccess.file_exists("res://"+spec[0]): continue
		var picture := Image.load_from_file("res://"+spec[0])
		picture.convert(Image.FORMAT_RGBA8)
		var bytes := picture.get_data()
		var width := picture.get_width()
		var height := picture.get_height()
		var frames := []
		for index in spec[1]*spec[2]:
			var x0 := int((index%spec[1])*width/float(spec[1]))
			var y0 := int((index/spec[1])*height/float(spec[2]))
			var x1 := int((index%spec[1]+1)*width/float(spec[1]))
			var y1 := int((index/spec[1]+1)*height/float(spec[2]))
			var left := x1
			var right := x0
			var top := y1
			var bottom := y0
			var count := 0
			for y in range(y0,y1):
				for x in range(x0,x1):
					if bytes[(y*width+x)*4+3] < 96: continue
					count += 1
					left=mini(left,x);right=maxi(right,x);top=mini(top,y);bottom=maxi(bottom,y)
			# Torso/root registration, rather than the varying reach of a hand/leaf.
			var pivot_left := right
			var pivot_right := left
			var scan_top := top+int((bottom-top)*0.35)
			var scan_end := top+int((bottom-top)*0.48)
			for y in range(scan_top,scan_end):
				for x in range(left,right+1):
					if bytes[(y*width+x)*4+3]>165:
						pivot_left=mini(pivot_left,x);pivot_right=maxi(pivot_right,x)
			frames.append({"rect":[maxi(x0,left-2),maxi(y0,top-2),mini(x1,right+3)-maxi(x0,left-2),mini(y1,bottom+3)-maxi(y0,top-2)],"foot":bottom,"pivot":(pivot_left+pivot_right)*0.5,"opaque":count,"cell":[x0,y0,x1-x0,y1-y0]})
		var components := _components(picture)
		components.sort_custom(func(a,b):
			var row_a:=int((a[1]+a[3]*0.5)/(float(height)/spec[2]))
			var row_b:=int((b[1]+b[3]*0.5)/(float(height)/spec[2]))
			return a[0]<b[0] if row_a==row_b else row_a<row_b)
		for component in components:
			var sum_x := 0.0
			var total := 0
			for y in range(component[1]+int(component[3]*0.86),component[1]+component[3]):
				for x in range(component[0],component[0]+component[2]):
					if bytes[(y*width+x)*4+3] > 165: sum_x += x; total += 1
			component.append(sum_x/maxi(1,total)-component[0])
		report.append({"path":spec[0],"size":[width,height],"corner_alpha":bytes[3],"frames":frames,"components":components})
	print("LIVING_ATLAS_AUDIT ",JSON.stringify(report))
	quit()
