extends SceneTree

## Read-only inspection: never rewrites or cuts up the generated asset.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass a sprite-sheet PNG path after --")
		quit(1)
		return
	var pixels := Image.load_from_file(args[0])
	if pixels == null or pixels.is_empty():
		quit(1)
		return
	print("SHEET size=", pixels.get_size(), " format=", pixels.get_format(), " alpha=", pixels.detect_alpha())
	var cell := pixels.get_size() / 2
	for index in range(4):
		var origin := Vector2i(index % 2, index / 2) * cell
		var minimum := cell
		var maximum := Vector2i.ZERO
		var opaque := 0
		var clear := 0
		for y in range(cell.y):
			for x in range(cell.x):
				var alpha := pixels.get_pixelv(origin + Vector2i(x, y)).a
				if alpha > 0.5:
					opaque += 1
					minimum = minimum.min(Vector2i(x, y))
					maximum = maximum.max(Vector2i(x, y))
				elif alpha == 0:
					clear += 1
		print("CELL ", index, " min=", minimum, " max=", maximum, " solid=", opaque, " transparent=", clear)
	quit(0)
