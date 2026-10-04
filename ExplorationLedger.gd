extends RefCounted
## Optional routes, not new quest gates. Existing receipts are the only authority.
## room, prefix, region, title, first-visit clue, return clue, extra supply, count, dispatch
const ROUTES := [
	["shaft_hollow", "shaft_hollow", "sunken_shaft", "Surveyor's Shelter", "Ask Deren in the side shelter; climb to the guarded ore alcove.", "Search the lower cutting beyond the shelter.", "healing_herb", 1, "Deren marks the recovered seam for tools, not another sealed tribute."],
	["shaft_crossing", "shaft_crossing", "sunken_shaft", "Dry Aqueduct Camp", "Follow Nera's raised ledges to the sluice and guarded high alcove.", "Follow the sediment lights into the lower side cutting.", "iron_fragment", 1, "The aqueduct salvage can repair a road as readily as a weapon."],
	["shaft_gallery", "shaft_gallery", "sunken_shaft", "Pipe Tender's Rest", "Ask Pell about the pressure controls and the upper supply niche.", "Revisit the lower maintenance branch.", "ether_dust", 1, "The maintenance reserve was left for whoever returned to keep the pipes working."],
	["shaft_cistern", "shaft_cistern", "sunken_shaft", "Gauge Keeper's Refuge", "Read Sela's pump instructions; explore above the channels for guarded supplies.", "Inspect the overflow branch below the pumps.", "healing_herb", 1, "Sela's dry packets survived the flood; someone expected the next shift."],
	["shaft_approach", "shaft_approach", "sunken_shaft", "Watchman's Shelter", "Use Bram's cover and counterweight clues; search the high supply alcove.", "Take the lower watch branch instead of returning straight to the gate.", "ember_arrow", 2, "The watch reserve now protects travelers instead of keeping them out."],
	["echo_grotto", "echo_grotto", "echo_grotto", "The Lost Choir", "Listen at the hidden low, middle and high receivers in that order; clear nearby foes first.", "Return to the final side alcove for the answering choir.", "healing_herb", 1, "The last answering tone carries a shelter call, not a command."],
	["echo_gallery", "echo_gallery", "echo_grotto", "The Two Witnesses", "Find the western and eastern receivers on distant hidden shelves; hear both witnesses.", "Search the final side alcove for the whispers given form.", "iron_fragment", 1, "Two witnesses remember different journeys along the same open road."],
	["echo_archive", "echo_archive", "echo_grotto", "The Unindexed Record", "Read the hidden receivers in the order zenith, dawn, dusk.", "Revisit the final side alcove and confront the archive's reflection.", "ether_dust", 1, "A discarded index preserves the names the official shelves omitted."],
	["echo_tide_well", "echo_tide", "echo_grotto", "The Quiet Well", "Calm both current-bank stations in the side chambers.", "Find the returning tide in the final side alcove.", "healing_herb", 1, "The quiet well can be heard from the shelters again."],
	["echo_nest", "echo_nest", "echo_grotto", "The Outer Nurseries", "Clear both side nurseries rather than only the central nest.", "Revisit the final side alcove for the last hatch.", "ember_arrow", 2, "The recovered supplies were wrapped against the nursery's damp."],
	["echo_causeway", "echo_causeway", "echo_grotto", "The Steady Crossing", "Restore both bridge-anchor stations off the main crossing.", "Seek the fractured sentinels in the final side alcove.", "iron_fragment", 1, "Anchor fragments will hold a crossing together once more."],
	["echo_vault", "echo_vault", "echo_grotto", "The Dry Reserve", "Drain both side channels and open the original upper and far vault seals.", "Return to the reservoir watch in the final side alcove.", "ether_dust", 1, "The dry reserve was stocked for a flood, not for a throne."],
	["echo_depths", "echo_depths", "echo_grotto", "The Lost Expedition", "Record both distant signals in the exploration branches.", "Revisit the expedition's side chamber for its final echo.", "healing_herb", 1, "The expedition's last supplies were left on the route home."],
	["ash_hearth_outskirts", "ash_outskirts", "ashen_bastion", "The Outer Watch Reports", "Clear both side watches and collect both scout reports.", "Return to the field-trial branch after clearing the upper reserve guards.", "healing_herb", 1, "The scouts counted people who needed passage, not targets."],
	["ash_causeway", "ash_causeway", "ashen_bastion", "The Refuge Signals", "Light the foot, span and crown signals in order; clear nearby enemies first.", "Revisit the signal hunters' branch after clearing the upper reserve guards.", "ember_arrow", 2, "A signal once used to stop refugees can guide them across."],
	["ash_chapel", "ash_chapel", "ashen_bastion", "The Lost Votive Records", "Read both side-niche records and complete the original chapel bells.", "Return to the votive watch after clearing the upper reserve guards.", "healing_herb", 1, "The chapel's spare remedies were meant to be shared."],
	["ash_forge", "ash_forge", "ashen_bastion", "Furnace Service Hoist", "Repair the winch and gearbox, then start the cooling fan to restore the service hoist.", "Revisit the furnace trial branch after clearing the upper reserve guards.", "iron_fragment", 1, "A service stamp names the workers who kept the furnace safe."],
	["ash_barracks", "ash_barracks", "ashen_bastion", "Quartermaster's Inspection", "Break all four marked drill targets and complete the original beacon waves.", "Return for the last inspection after clearing the upper reserve guards.", "ember_arrow", 2, "The quartermaster's last issue lists escorts and relief crews."],
	["ash_reservoir", "ash_reservoir", "ashen_bastion", "Pressure Calibration", "Open both coolant valves; calibrate return, intake, then exhaust.", "Revisit the pressure watch after clearing the upper reserve guards.", "iron_fragment", 1, "The reserve keeps a repaired pressure line from becoming another ruin."],
	["starfall_outskirts", "starfall_outskirts", "starfall", "Caravan Repairs", "Repair both side winches to raise caravan cover, then seek the upper reserve guardians.", "Revisit the final gallery for the last siege.", "healing_herb", 1, "The caravan packing list leaves room for passengers, not royal cargo."],
	["starfall_ramparts", "starfall_ramparts", "starfall", "The Signal Plates", "Clear both watches, recover their plates and deliver them to the high archive desk; search the deep guarded reserve.", "Return to the western gate for the last signal watch.", "ember_arrow", 2, "The last signal points outward: the road is open."],
	["starfall_silent_gate", "starfall_silent_gate", "starfall", "Ward Circuit Inspection", "Power the original high and low relays, inspect both side terminals and clear the upper reserve guardians.", "Revisit the final gallery for the hushed watch.", "ether_dust", 1, "The ward circuit now records arrivals without sealing the gate."],
	["starfall_memory_vault", "starfall_memory_vault", "starfall", "The Scattered Records", "Break the three marked record cases in the side branches; clear the upper reserve guardians.", "Seek the archive remnant in the final gallery.", "ether_dust", 1, "The scattered records belong beside the names the court rejected."],
	["starfall_rooted_hall", "starfall_rooted_hall", "starfall", "The Dormant Gardens", "Restore the original root channel and both side seedbeds; clear the upper reserve guardians.", "Return to the final gallery for the thorn watch.", "healing_herb", 1, "The garden's reserve holds enough to begin another bed."],
	["starfall_soul_crucible", "starfall_soul_crucible", "starfall", "Containment Chambers", "Stabilize the original channels, clear both side containment fights and the upper reserve guardians.", "Confront the unbound remnant in the final gallery.", "iron_fragment", 1, "The containment fittings can be remade without binding another soul."],
	["starfall_sunless_passage", "starfall_sunless_passage", "starfall", "The Procession Lights", "Light the first, middle and last beacons in order; clear the upper reserve guardians. The dawn anchor still controls the bridge.", "Return for the night procession in the final gallery.", "healing_herb", 1, "The procession's supplies were carried for those who would walk home."],
]
const REGIONS := {
	"sunken_shaft": ["SUNKEN SHAFT", "the Warden"],
	"echo_grotto": ["ECHO", "the Matriarch"],
	"ashen_bastion": ["ASHEN BASTION", "the Castellan"],
	"starfall": ["STARFALL", "the Hollow Sovereign"],
}


static func cache_id(route: Array) -> String:
	return str(route[1]) + ("_trial_reserve" if route[2] == "sunken_shaft" else "_field_return_reserve")


static func completion_id(route: Array) -> String:
	return str(route[1]) + ("_return_trial_cleared" if route[2] == "sunken_shaft" else "_field_return_complete")


static func route_for_cache(id: String) -> Array:
	for route in ROUTES:
		if cache_id(route) == id:
			return route
	return []


static func bonus(id: String) -> Dictionary:
	var route := route_for_cache(id)
	return {} if route.is_empty() else {str(route[6]): int(route[7])}


static func return_status(state: Node, route: Array) -> String:
	if bool(state.opened_caches.get(cache_id(route), false)):
		return "CLAIMED"
	if bool(state.unlocked_shortcuts.get(completion_id(route), false)):
		return "COLLECT RESERVE"
	var region := str(route[2])
	var awake: bool = bool(state.defeated_bosses.get("hollow_sovereign", false)) if region == "starfall" else state.get_zone_tier(region) >= 1
	if not awake:
		return "AFTER " + str(REGIONS[region][1]).to_upper()
	var prefix := str(route[1])
	if region != "sunken_shaft" and not bool(state.unlocked_shortcuts.get(prefix + "_field_complete", false)):
		return "FINISH LOCAL TASK"
	var guard_id := prefix + ("_guarded_niche_cleared" if region == "ashen_bastion" else "_niche_cleared")
	if region in ["ashen_bastion", "starfall"] and not bool(state.unlocked_shortcuts.get(guard_id, false)):
		return "CLEAR RESERVE GUARDS"
	return "RETURN ENCOUNTER READY"


static func supply_text(state: Node, route: Array) -> String:
	return "%s x%d" % [str(state.get_item_definition(str(route[6])).get("name", route[6])), int(route[7])]


static func journal(state: Node) -> String:
	if state == null:
		return ""
	var lines: Array[String] = []
	var current: Array = []
	for region in REGIONS:
		var rows: Array[String] = []
		for route in ROUTES:
			if route[2] != region or not bool(state.discovered_rooms.get(route[0], false)):
				continue
			rows.append("%s - %s" % [route[3], return_status(state, route)])
			if bool(state.opened_caches.get(cache_id(route), false)):
				rows.append("RECOVERED DISPATCH: " + str(route[8]))
			if route[0] == state.current_room_id:
				current = route
		if not rows.is_empty():
			lines.append(str(REGIONS[region][0]) + "\n" + "\n".join(rows))
	if lines.is_empty():
		return ""
	var detail := ""
	if not current.is_empty():
		detail = "\n\nHERE: %s\nFIRST VISIT: %s\nRETURN: %s\nEXTRA SUPPLIES: %s, alongside the reserve's gold, item and weapon supply." % [current[3], current[4], current[5], supply_text(state, current)]
	return "\n\nEXPLORATION - OPTIONAL ROUTES\nOnly visited routes are listed; return status does not block the main story." + detail + "\n\n" + "\n\n".join(lines)
