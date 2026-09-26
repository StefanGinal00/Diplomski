extends RefCounted

# Room instances live in one Game scene. The old close-packed origins cannot
# contain multi-level rooms; keep both sets here so version 9 saves can migrate.
const ROOM_ORIGINS := {
	"sunken_shaft": [Vector2(1500, 0), Vector2(10000, -22000)],
	"shaft_hollow": [Vector2(1500, -600), Vector2(20000, -22000)],
	"shaft_crossing": [Vector2(2500, -600), Vector2(30000, -22000)],
	"shaft_gallery": [Vector2(2500, -1200), Vector2(40000, -22000)],
	"shaft_cistern": [Vector2(3500, -600), Vector2(50000, -22000)],
	"shaft_approach": [Vector2(3500, -1200), Vector2(60000, -22000)],
	"shaft_drift": [Vector2(1500, -2300), Vector2(70000, -22000)],
	"echo_grotto": [Vector2(2600, 500), Vector2(10000, -15000)],
	"echo_gallery": [Vector2(3700, 500), Vector2(20000, -15000)],
	"echo_archive": [Vector2(4700, 350), Vector2(30000, -15000)],
	"echo_tide_well": [Vector2(2600, 850), Vector2(40000, -15000)],
	"echo_causeway": [Vector2(3700, 1900), Vector2(50000, -15000)],
	"echo_vault": [Vector2(2200, 1900), Vector2(60000, -15000)],
	"echo_nest": [Vector2(3300, 1350), Vector2(70000, -15000)],
	"echo_depths": [Vector2(3600, 3200), Vector2(80000, -15000)],
	"echo_sanctum": [Vector2(4400, 1350), Vector2(10000, -9000)],
	"echo_haven": [Vector2(6000, 500), Vector2(20000, -9000)],
	"echo_haven_outskirts": [Vector2(7600, 500), Vector2(30000, -9000)],
	"ash_causeway": [Vector2(5500, 1350), Vector2(10000, -3000)],
	"ash_forge": [Vector2(6800, 1350), Vector2(20000, -3000)],
	"ash_barracks": [Vector2(7900, 1350), Vector2(30000, -3000)],
	"ash_arena": [Vector2(9400, 1350), Vector2(40000, -3000)],
	"ash_reservoir": [Vector2(11000, 1350), Vector2(50000, -3000)],
	"ash_chapel": [Vector2(11000, 650), Vector2(60000, -3000)],
	"ash_throne": [Vector2(12200, 650), Vector2(70000, -3000)],
	"ash_emberspine": [Vector2(6800, 2700), Vector2(80000, -3000)],
	"ash_hearth": [Vector2(12500, 1350), Vector2(10000, 3000)],
	"ash_hearth_outskirts": [Vector2(14000, 1350), Vector2(20000, 3000)],
	"starfall_citadel": [Vector2(13600, 650), Vector2(10000, 10000)],
	"starfall_outskirts": [Vector2(20200, 650), Vector2(20000, 10000)],
	"starfall_silent_gate": [Vector2(22000, 650), Vector2(30000, 10000)],
	"starfall_memory_vault": [Vector2(24000, 650), Vector2(40000, 10000)],
	"starfall_rooted_hall": [Vector2(26000, 650), Vector2(50000, 10000)],
	"starfall_empty_court": [Vector2(28000, 650), Vector2(60000, 10000)],
	"starfall_soul_crucible": [Vector2(30000, 650), Vector2(70000, 10000)],
	"starfall_sunless_passage": [Vector2(32000, 650), Vector2(80000, 10000)],
	"starfall_hollow_throne": [Vector2(34300, 650), Vector2(10000, 16000)],
	"starfall_ramparts": [Vector2(22000, 1900), Vector2(20000, 16000)],
}

# Compact, topology-oriented positions used only while Game.tscn is open in
# the editor. Runtime rooms remain isolated at ROOM_ORIGINS so their physics
# can never overlap. This view groups each biome and shows optional branches.
const EDITOR_ORIGINS := {
	"sunken_shaft": Vector2(7000, -17000),
	"shaft_hollow": Vector2(14000, -17000),
	"shaft_drift": Vector2(20500, -20500),
	"shaft_crossing": Vector2(21000, -16500),
	"shaft_gallery": Vector2(28000, -16500),
	"shaft_cistern": Vector2(35000, -16500),
	"shaft_approach": Vector2(42000, -13500),
	"echo_grotto": Vector2(7000, -8500),
	"echo_gallery": Vector2(14000, -8500),
	"echo_depths": Vector2(20500, -12000),
	"echo_archive": Vector2(21000, -8000),
	"echo_tide_well": Vector2(28000, -8000),
	"echo_causeway": Vector2(35000, -8000),
	"echo_vault": Vector2(35000, -4000),
	"echo_nest": Vector2(28000, -4000),
	"echo_sanctum": Vector2(42000, -4000),
	"echo_haven": Vector2(49000, -4000),
	"echo_haven_outskirts": Vector2(55500, -4000),
	"ash_causeway": Vector2(7000, 3500),
	"ash_emberspine": Vector2(13500, 7000),
	"ash_forge": Vector2(14000, 3000),
	"ash_barracks": Vector2(21000, 3000),
	"ash_arena": Vector2(28000, 3000),
	"ash_reservoir": Vector2(35000, 3000),
	"ash_chapel": Vector2(35000, -500),
	"ash_throne": Vector2(42000, -500),
	"ash_hearth": Vector2(42000, 3500),
	"ash_hearth_outskirts": Vector2(49000, 3500),
	"starfall_citadel": Vector2(7000, 12500),
	"starfall_outskirts": Vector2(14000, 12500),
	"starfall_ramparts": Vector2(20500, 16000),
	"starfall_silent_gate": Vector2(21000, 12000),
	"starfall_memory_vault": Vector2(28000, 12000),
	"starfall_rooted_hall": Vector2(35000, 12000),
	"starfall_empty_court": Vector2(42000, 12000),
	"starfall_soul_crucible": Vector2(49000, 12000),
	"starfall_sunless_passage": Vector2(56000, 12000),
	"starfall_hollow_throne": Vector2(63000, 12000),
}

const ROOM_NODES := {
	"sunken_shaft": "VerticalChamber", "shaft_hollow": "ShaftHollow", "shaft_drift": "ShaftDriftworks",
	"shaft_crossing": "DrownedCrossing", "shaft_gallery": "FloodedGallery", "shaft_cistern": "BlackwaterCistern", "shaft_approach": "WardenApproach",
	"echo_grotto": "EchoGrotto", "echo_gallery": "EchoGallery", "echo_depths": "EchoDepths", "echo_archive": "PrismArchive",
	"echo_tide_well": "TideWell", "echo_causeway": "CrystalCauseway", "echo_vault": "UndertowVault", "echo_nest": "EchoNest",
	"echo_sanctum": "ResonanceSanctum", "echo_haven": "EchoHaven", "echo_haven_outskirts": "EchoHavenOutskirts",
	"ash_causeway": "BrokenCauseway", "ash_emberspine": "AshEmberspine", "ash_forge": "CinderForge", "ash_barracks": "EmberBarracks",
	"ash_arena": "AshArena", "ash_reservoir": "SlagReservoir", "ash_chapel": "AshChapel", "ash_throne": "CastellanThrone",
	"ash_hearth": "CinderHearth", "ash_hearth_outskirts": "CinderHearthOutskirts",
	"starfall_citadel": "StarfallCitadel", "starfall_outskirts": "StarfallOutskirts", "starfall_ramparts": "StarfallRamparts",
	"starfall_silent_gate": "StarfallSilentGate", "starfall_memory_vault": "StarfallMemoryVault", "starfall_rooted_hall": "StarfallRootedHall",
	"starfall_empty_court": "StarfallEmptyCourt", "starfall_soul_crucible": "StarfallSoulCrucible",
	"starfall_sunless_passage": "StarfallSunlessPassage", "starfall_hollow_throne": "StarfallHollowThrone",
}

# A few lamps also changed position *within* their room.
const LAMP_LOCAL_OFFSETS := {
	"blackwater_cistern_lamp": Vector2(-405, 1525),
	"warden_approach_lamp": Vector2(-590, 1525),
}


static func migrate_position(room_id: String, lamp_id: String, old_position: Vector2) -> Vector2:
	if not ROOM_ORIGINS.has(room_id):
		return old_position
	var origins: Array = ROOM_ORIGINS[room_id]
	return old_position + origins[1] - origins[0] + LAMP_LOCAL_OFFSETS.get(lamp_id, Vector2.ZERO)
