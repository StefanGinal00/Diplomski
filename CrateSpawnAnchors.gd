extends RefCounted
## Reviewed exceptions to legacy generator positions. Coordinates are in each
## crate's parent space; support paths are relative to its mapped room.
## Apply only at the original anchor, including old streamed snapshots, so a
## reload cannot add another offset or overwrite an unrelated edited position.
const ANCHORS := {
	"ShaftHollow/ExpandedRoute/AuthoredDescent/DepthCrate1_1": [Vector2(2436.625, 659), Vector2(2476.625, 669), "ExpandedRoute/AuthoredDescent/Chamber1_Floor0"],
	"ShaftHollow/ExpandedRoute/AuthoredDescent/DepthCrate2_1": [Vector2(3668.875, 1019), Vector2(3692.875, 1029), "ExpandedRoute/AuthoredDescent/Chamber2_Floor0"],
	"ShaftHollow/ExpandedRoute/AuthoredDescent/DepthCrate3_1": [Vector2(4662.625, 1379), Vector2(4710.625, 1389), "ExpandedRoute/AuthoredDescent/Chamber3_Floor0"],
	"ShaftHollow/ExpandedRoute/AuthoredDescent/DepthCrate4_1": [Vector2(3483.375, 1019), Vector2(3163.375, 1029), "ExpandedRoute/AuthoredDescent/Chamber2_Floor0"],
	"ShaftHollow/ExpandedRoute/AuthoredDescent/BranchCrate1": [Vector2(2603.375, 483), Vector2(2667.375, 493.5), "ExpandedRoute/AuthoredDescent/Branch1_Chamber"],
	"ShaftHollow/ExpandedRoute/FieldDressing/Supply3_1": [Vector2(4664.94, 1383), Vector2(4760.939, 1389), "ExpandedRoute/AuthoredDescent/Chamber3_Floor0"],
	"ShaftDriftworks/FieldDressing/Supply6_0": [Vector2(3916.9, -147), Vector2(3868.898, -141), "MainRoom6Floor1"],
	"ShaftDriftworks/SupplyCrate13": [Vector2(3917.7, -151), Vector2(3917.703, -141), "MainRoom6Floor1"],
	"DrownedCrossing/ExpandedRoute/AuthoredDescent/DepthCrate1_0": [Vector2(1738.5, 689), Vector2(1698.5, 699), "ExpandedRoute/AuthoredDescent/Chamber1_Floor1"],
	"DrownedCrossing/ExpandedRoute/AuthoredDescent/DepthCrate1_1": [Vector2(2310.75, 689), Vector2(2342.75, 699), "ExpandedRoute/AuthoredDescent/Chamber1_Floor1"],
	"DrownedCrossing/ExpandedRoute/AuthoredDescent/DepthCrate2_1": [Vector2(1138.125, 1049), Vector2(826.125, 1059), "ExpandedRoute/AuthoredDescent/Chamber2_Floor0"],
	"DrownedCrossing/ExpandedRoute/AuthoredDescent/DepthCrate4_1": [Vector2(3649, 1049), Vector2(3665, 1059), "ExpandedRoute/AuthoredDescent/Chamber4_Floor1"],
	"DrownedCrossing/ExpandedRoute/AuthoredDescent/DepthCrate5_1": [Vector2(4682.5, 1769), Vector2(4730.5, 1779), "ExpandedRoute/AuthoredDescent/Chamber5_Floor0"],
	"DrownedCrossing/ExpandedRoute/AuthoredDescent/BranchCrate1": [Vector2(2464.25, 513), Vector2(2536.25, 523.5), "ExpandedRoute/AuthoredDescent/Branch1_Chamber"],
	"DrownedCrossing/ExpandedRoute/FieldDressing/Supply1_0": [Vector2(1748.64, 693), Vector2(2156.641, 699), "ExpandedRoute/AuthoredDescent/Chamber1_Floor1"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/DepthCrate0_0": [Vector2(440, 349), Vector2(472, 359), "Floor"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/DepthCrate1_1": [Vector2(2039.125, 709), Vector2(2103.125, 719), "ExpandedRoute/AuthoredDescent/Chamber1_Floor0"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/DepthCrate2_1": [Vector2(3244.875, 1069), Vector2(3268.875, 1079), "ExpandedRoute/AuthoredDescent/Chamber2_Floor1"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/DepthCrate3_1": [Vector2(4603, 1429), Vector2(4619, 1439), "ExpandedRoute/AuthoredDescent/Chamber3_Floor0"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/DepthCrate4_0": [Vector2(3143, 1069), Vector2(2759, 1079), "ExpandedRoute/AuthoredDescent/Chamber2_Floor0"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/DepthCrate4_1": [Vector2(3535, 1069), Vector2(3991, 1079), "ExpandedRoute/AuthoredDescent/Chamber4_Floor2"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/DepthCrate5_1": [Vector2(2290.875, 1789), Vector2(2346.875, 1799), "ExpandedRoute/AuthoredDescent/Chamber5_Floor0"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/BranchCrate1": [Vector2(2258.875, 533), Vector2(2298.875, 543.5), "ExpandedRoute/AuthoredDescent/Branch1_Chamber"],
	"FloodedGallery/ExpandedRoute/AuthoredDescent/BranchCrate3": [Vector2(3870, 1253), Vector2(3830, 1263.5), "ExpandedRoute/AuthoredDescent/Branch3_Chamber"],
	"FloodedGallery/ExpandedRoute/FieldDressing/Supply5_0": [Vector2(2145.5, 1793), Vector2(2089.5, 1799), "ExpandedRoute/AuthoredDescent/Chamber5_Floor0"],
	"FloodedGallery/ExpandedRoute/FieldDressing/Supply5_1": [Vector2(2300.5, 1793), Vector2(2300.5, 1799), "ExpandedRoute/AuthoredDescent/Chamber5_Floor0"],
	"FloodedGallery/GalleryCrate": [Vector2(426, 344), Vector2(426, 359), "Floor"],
	"BlackwaterCistern/ExpandedRoute/AuthoredDescent/DepthCrate2_1": [Vector2(4179, 1089), Vector2(4195, 1099), "ExpandedRoute/AuthoredDescent/Chamber2_Floor0"],
	"BlackwaterCistern/ExpandedRoute/AuthoredDescent/BranchCrate1": [Vector2(2861.75, 553), Vector2(2637.75, 563.5), "ExpandedRoute/AuthoredDescent/Branch1_Chamber"],
	"BlackwaterCistern/ExpandedRoute/AuthoredDescent/BranchCrate3": [Vector2(2770.25, 553), Vector2(2586.25, 563.5), "ExpandedRoute/AuthoredDescent/Branch1_Chamber"],
	"BlackwaterCistern/ExpandedRoute/FieldDressing/Supply2_0": [Vector2(4055.2, 1093), Vector2(4023.199, 1099), "ExpandedRoute/AuthoredDescent/Chamber2_Floor0"],
	"BlackwaterCistern/ExpandedRoute/FieldDressing/Supply5_0": [Vector2(2104.8, 1898), Vector2(2064.801, 1904), "ExpandedRoute/AuthoredDescent/Chamber5_Floor0"],
	"WardenApproach/ExpandedRoute/AuthoredDescent/DepthCrate0_0": [Vector2(493, 419), Vector2(445, 429), "ExpandedRoute/AuthoredDescent/Chamber0_Floor0"],
	"WardenApproach/ExpandedRoute/AuthoredDescent/DepthCrate1_1": [Vector2(2383.625, 779), Vector2(2423.625, 789), "ExpandedRoute/AuthoredDescent/Chamber1_Floor0"],
	"WardenApproach/ExpandedRoute/AuthoredDescent/DepthCrate2_1": [Vector2(3602.625, 1139), Vector2(3642.625, 1149), "ExpandedRoute/AuthoredDescent/Chamber2_Floor0"],
	"WardenApproach/ExpandedRoute/AuthoredDescent/DepthCrate3_1": [Vector2(4682.5, 779), Vector2(4730.5, 789), "ExpandedRoute/AuthoredDescent/Chamber3_Floor1"],
	"WardenApproach/ExpandedRoute/AuthoredDescent/DepthCrate4_1": [Vector2(3788.125, 1499), Vector2(3676.125, 1509), "ExpandedRoute/AuthoredDescent/Chamber4_Floor1"],
	"WardenApproach/ExpandedRoute/AuthoredDescent/BranchCrate1": [Vector2(2550.375, 603), Vector2(2614.375, 613.5), "ExpandedRoute/AuthoredDescent/Branch1_Chamber"],
	"EchoGallery/LongTraversal/FieldDressing/Supply4_0": [Vector2(3764, -1301), Vector2(3828, -1295), "LongTraversal/Chamber04Floor0"],
	"EchoGallery/LongTraversal/TraversalCrate04": [Vector2(3779, -1302), Vector2(3779, -1295), "LongTraversal/Chamber04Floor0"],
	"TideWell/LongTraversal/HiddenCrate03": [Vector2(2163.75, -430), Vector2(2107.75, -424), "LongTraversal/Tier03HiddenShelfB"],
	"TideWell/LongTraversal/HiddenCrate05": [Vector2(2153.75, -430), Vector2(1897.75, -424), "LongTraversal/Tier03HiddenShelfA"],
	"CrystalCauseway/LongTraversal/AlcoveCrate02": [Vector2(3418, -419), Vector2(3378, -412), "LongTraversal/Tier02SideAlcove"],
	"EchoNest/WildCrate0": [Vector2(365, 146), Vector2(429, 145), "Floor"],
	"BrokenCauseway/AshSwitchback/FieldDressing/Supply5_0": [Vector2(1771.1, -807), Vector2(1739.1, -801), "AshSwitchback/AshSolid_10"],
	"BrokenCauseway/AshSwitchback/AshRouteCrate4": [Vector2(1785, -813), Vector2(1689, -801), "AshSwitchback/AshSolid_10"],
	"CinderForge/AshSwitchback/AshRouteCrate3": [Vector2(2460, -213), Vector2(2412, -201), "AshSwitchback/AshSolid_05"],
	"CinderForge/AshSwitchback/AshNicheCacheCrate1": [Vector2(2060, -979), Vector2(2108, -966), "AshSwitchback/AshSolid_15"],
	"EmberBarracks/AshSwitchback/FieldDressing/Supply5_0": [Vector2(1687.1, -807), Vector2(1655.1, -801), "AshSwitchback/AshSolid_11"],
	"EmberBarracks/AshSwitchback/AshRouteCrate1": [Vector2(3318, -213), Vector2(3366, -201), "AshSwitchback/AshSolid_05"],
	"EmberBarracks/AshSwitchback/AshRouteCrate3": [Vector2(1134, -213), Vector2(1086, -201), "AshSwitchback/AshSolid_09"],
	"EmberBarracks/AshSwitchback/AshRouteCrate4": [Vector2(1701, -813), Vector2(1605, -801), "AshSwitchback/AshSolid_11"],
	"EmberBarracks/AshSwitchback/DrillTarget0": [Vector2(3318, -214), Vector2(3414, -201), "AshSwitchback/AshSolid_05"],
	"EmberBarracks/AshSwitchback/DrillTarget2": [Vector2(1134, -214), Vector2(1134, -201), "AshSwitchback/AshSolid_09"],
	"EmberBarracks/AshSwitchback/DrillTarget3": [Vector2(1831, -814), Vector2(1855, -801), "AshSwitchback/AshSolid_11"],
	"SlagReservoir/AshSwitchback/FieldDressing/Supply5_0": [Vector2(3582.56, -807), Vector2(3662.559, -801), "AshSwitchback/AshSolid_11"],
	"SlagReservoir/AshSwitchback/AshNicheCacheCrate1": [Vector2(3232, -979), Vector2(3192, -966), "AshSwitchback/AshSolid_15"],
	"AshChapel/AshSwitchback/FieldDressing/Supply2_1": [Vector2(2910, -207), Vector2(2806, -201), "AshSwitchback/AshSolid_05"],
	"AshChapel/AshSwitchback/FieldDressing/Supply5_0": [Vector2(1640.9, -807), Vector2(1608.898, -801), "AshSwitchback/AshSolid_10"],
	"AshChapel/AshSwitchback/AshRouteCrate4": [Vector2(1659, -813), Vector2(1563, -801), "AshSwitchback/AshSolid_10"],
	"AshChapel/AshSwitchback/AshNicheCacheCrate1": [Vector2(2179, -979), Vector2(2243, -966), "AshSwitchback/AshSolid_15"],
	"CinderHearthOutskirts/AshSwitchback/FieldDressing/Supply1_1": [Vector2(1450, 93), Vector2(1490, 99), "AshSwitchback/AshSolid_03"],
	"CinderHearthOutskirts/AshSwitchback/FieldDressing/Supply5_1": [Vector2(3607, -507), Vector2(3567, -501), "AshSwitchback/AshSolid_10"],
	"CinderHearthOutskirts/AshSwitchback/AshRouteCrate0": [Vector2(1440, 87), Vector2(1440, 99), "AshSwitchback/AshSolid_03"],
	"CinderHearthOutskirts/AshSwitchback/AshNicheCacheCrate1": [Vector2(2980, -679), Vector2(2892, -666), "AshSwitchback/AshSolid_14"],
	"CinderHearthOutskirts/AshSwitchback/SiegeSupply4": [Vector2(3615.556, -513), Vector2(3615.555, -501), "AshSwitchback/AshSolid_10"],
	"StarfallOutskirts/ExpandedRoute/StarfallDescent/DepthCrate0_0": [Vector2(703.75, 369), Vector2(663.75, 379), "ExpandedRoute/StarfallDescent/Chamber0_Floor0"],
	"StarfallOutskirts/ExpandedRoute/StarfallDescent/BranchCrate1": [Vector2(2587.5, 553), Vector2(2371.5, 563.5), "ExpandedRoute/StarfallDescent/Branch1_Chamber"],
	"StarfallOutskirts/ExpandedRoute/StarfallDescent/SiegeSupply2": [Vector2(4182.5, 1089), Vector2(4142.5, 1099), "ExpandedRoute/StarfallDescent/Chamber2_Floor0"],
	"StarfallOutskirts/ExpandedRoute/FieldDressing/Supply2_0": [Vector2(4187.4, 1093), Vector2(4187.4, 1099), "ExpandedRoute/StarfallDescent/Chamber2_Floor0"],
	"StarfallOutskirts/WildCrate0": [Vector2(715, 367), Vector2(715, 379), "ExpandedRoute/StarfallDescent/Chamber0_Floor0"],
	"StarfallRamparts/SupplyCrate2": [Vector2(2048.464, 1049), Vector2(2000.463, 1059), "MainRoom1Floor0"],
	"StarfallRamparts/SupplyCrate15": [Vector2(2051.155, 1049), Vector2(2051.154, 1059), "MainRoom1Floor0"],
	"StarfallSilentGate/ExpandedRoute/StarfallDescent/BranchCrate1": [Vector2(2693.125, 553), Vector2(2469.125, 563.5), "ExpandedRoute/StarfallDescent/Branch1_Chamber"],
	"StarfallMemoryVault/ExpandedRoute/StarfallDescent/BranchCrate1": [Vector2(2620, 553), Vector2(2436, 563.5), "ExpandedRoute/StarfallDescent/Branch1_Chamber"],
	"StarfallMemoryVault/ExpandedRoute/StarfallDescent/SealedRecord0": [Vector2(2515, 553), Vector2(2387, 563.5), "ExpandedRoute/StarfallDescent/Branch1_Chamber"],
	"StarfallRootedHall/ExpandedRoute/StarfallDescent/DepthCrate2_0": [Vector2(4351.875, 1089), Vector2(4303.875, 1099), "ExpandedRoute/StarfallDescent/Chamber2_Floor0"],
	"StarfallRootedHall/ExpandedRoute/StarfallDescent/DepthCrate2_1": [Vector2(5534.375, 1089), Vector2(5510.375, 1099), "ExpandedRoute/StarfallDescent/Chamber2_Floor1"],
	"StarfallRootedHall/ExpandedRoute/StarfallDescent/BranchCrate1": [Vector2(3066.875, 553), Vector2(2922.875, 563.5), "ExpandedRoute/StarfallDescent/Branch1_Chamber"],
	"StarfallRootedHall/ExpandedRoute/FieldDressing/Supply2_0": [Vector2(5555, 1093), Vector2(5555, 1099), "ExpandedRoute/StarfallDescent/Chamber2_Floor1"],
	"StarfallSoulCrucible/ExpandedRoute/StarfallDescent/BranchCrate1": [Vector2(3148.125, 593), Vector2(2988.125, 603.5), "ExpandedRoute/StarfallDescent/Branch1_Chamber"],
	"StarfallSunlessPassage/ExpandedRoute/StarfallDescent/DepthCrate5_0": [Vector2(5700, 1489), Vector2(5844, 1499), "ExpandedRoute/StarfallDescent/Chamber5_Floor2"],
	"StarfallSunlessPassage/ExpandedRoute/StarfallDescent/BranchCrate1": [Vector2(2733.75, 593), Vector2(2501.75, 603.5), "ExpandedRoute/StarfallDescent/Branch1_Chamber"],
	"StarfallSunlessPassage/ExpandedRoute/FieldDressing/Supply2_0": [Vector2(1265, 1133), Vector2(1217, 1139), "ExpandedRoute/StarfallDescent/Chamber2_Floor0"],
	"StarfallSunlessPassage/ExpandedRoute/FieldDressing/Supply5_0": [Vector2(5750, 1493), Vector2(5894, 1499), "ExpandedRoute/StarfallDescent/Chamber5_Floor2"],
}


static func apply(crate: StaticBody2D, room: Node2D) -> bool:
	var key := String(room.name) + "/" + String(room.get_path_to(crate))
	if not ANCHORS.has(key):
		return false
	var entry: Array = ANCHORS[key]
	if crate.position.distance_to(entry[0]) > 0.02:
		return false
	var floor_node := room.get_node_or_null(entry[2]) as StaticBody2D
	if floor_node == null or not floor_node.get_collision_layer_value(1):
		return false
	var shape := floor_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or shape.disabled or not shape.shape is RectangleShape2D:
		return false
	# These exceptions are for the current unscaled, axis-aligned 24 px crates.
	if not crate.global_transform.x.is_equal_approx(Vector2.RIGHT) or not crate.global_transform.y.is_equal_approx(Vector2.DOWN):
		return false
	var collider := crate.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider == null or collider.disabled or not collider.shape is RectangleShape2D or not collider.transform.is_equal_approx(Transform2D.IDENTITY) or collider.shape.size != Vector2(24, 24):
		return false
	if absf(shape.global_transform.x.y) > 0.0001 or absf(shape.global_transform.y.x) > 0.0001:
		return false
	var floor_rect: Rect2 = shape.global_transform * Rect2(-shape.shape.size * 0.5, shape.shape.size)
	var target: Vector2 = crate.get_parent().to_global(entry[1])
	if absf(target.y + 12 - floor_rect.position.y) > 0.05 or target.x - 12 < floor_rect.position.x or target.x + 12 > floor_rect.end.x:
		return false
	crate.position = entry[1]
	return true
