# World structure (working plan)

The game is a connected 2D world, not a level-select sequence. A **zone** is a large region with a shared visual identity, enemy family and boss. A **room** is a smaller place connected by doors, shafts or shortcuts. Players can revisit every unlocked room; defeating a boss opens the next zone but does not close the previous one.

The Training Passage and Void Sentinel are the prologue. The five main zones below are the target for the finished game. Room names beyond the currently playable route are working names, not claims that the content already exists.

| Zone | Planned rooms (7-8 each) | Boss | Unlocks next zone |
| --- | --- | --- | --- |
| Sunken Shaft | Upper Shaft, Lift Chamber, Drowned Crossing, Wisp Hollow, Flooded Gallery, Blackwater Cistern, Warden Approach, Warden Arena | Abyss Warden | Warden Seal + boss defeat opens Echo Grotto |
| Echo Grotto | Echo Grotto, Whispering Gallery, Prism Archive, Tide Well, Echo Nest, Crystal Causeway, Undertow Vault, Resonance Sanctum | Echo Matriarch | Matriarch defeat opens Ashen Bastion |
| Ashen Bastion | Broken Causeway, Cinder Forge, Ember Barracks, Charred Market, Furnace Descent, Ashen Chapel, Smelter Vault, Castellan Throne | Ash Castellan | Castellan defeat opens Starfall Citadel |
| Starfall Citadel | Fallen Observatory, Glass Walk, Astral Library, Shattered Orrery, Moon Bridge, Celestial Garden, Guardian Spire | Starfall Guardian | Guardian defeat opens the final zone |
| Hollow Throne | Silent Gate, Memory Vault, Rooted Hall, Empty Court, Soul Crucible, Sunless Passage, Hollow Throne | Hollow Sovereign (final boss) | Ending |

## Route rules

- Boss kills and unique keys are persistent **only after saving at a lamp**. On death, Normal mode restores the last lamp snapshot; Hardcore keeps its existing one-run rule.
- Forward gates may require boss defeats, key items and specific world events together. Return doors never require a boss a second time. Shortcuts should create loops, not one-way traps.
- The final boss gate is intended to require the four prior main bosses **and three Memory Sigils** found in optional branches of earlier zones. The sigils provide a reason to revisit old areas; their exact locations will be chosen as those rooms are built.
- Each zone should grow toward seven or eight distinct rooms, with at least one hub, one optional branch, one traversal challenge, a lamp before its boss, and a return shortcut. The count is not a reason to make eight identical corridors.
- Pacing target for the expanded game: a player's **first meaningful visit** to each room should last roughly 5-10 minutes, excluding menus and idle time. Traversal, an encounter or puzzle, optional discovery and a clear return route should provide that time; the current compact rooms are prototypes and do not yet meet this target. Revisit and fast-travel routes should be quicker.
- Save Lamps share one fast-travel network. A lamp becomes a destination after resting and saving there; previously discovered lamps remain lit and usable after loading. Travel starts at a discovered lamp with [T], while [M] only views the map when away from a lamp. Arriving at a lamp saves and makes it the new respawn point.
- The next playable milestone is to broaden the still-compact Sunken Shaft and Echo Grotto layouts and extend the new Ashen Bastion opening into a full third zone. Do not place forward doors to unbuilt destinations in the release build.

## Currently playable

- Training Passage → Sunken Shaft → Echo Grotto → Ashen Bastion opening. The Shaft currently has Wisp Hollow between its upper and lower levels, Drowned Crossing off the lower level, Flooded Gallery above the Crossing, Blackwater Cistern linking Crossing back to Gallery, and Warden Approach between the Gallery shortcut and boss arena. The Hollow relay connects Crossing and Hollow; the Gallery controls open the Approach route. The original lower Shaft route to the Warden remains open. Echo branches into Whispering Gallery → Prism Archive and Tide Well → Echo Nest → Resonance Sanctum. Crystal Causeway links the Gallery to the upper Well after its anchor is stabilized. Undertow Vault branches from the lower Well after the Tide Core is recovered. The Matriarch's seal and defeat open Broken Causeway → Cinder Forge, with both Ashen rooms reversible.
- The Warden gate checks both boss defeat and the Warden Seal.
- Wisp Hollow branches from the upper Shaft. Two guardian wisps protect a relay; activating it opens the lower Hollow-to-Shaft passage in both directions. A small spike pit can be crossed above on platforms. The relay follows lamp-save and death rollback rules.
- Drowned Crossing branches from the lower Shaft. Its telegraphed surge can be timed on the floor or bypassed via higher ledges. The far valve permanently drains the surge for this saved run; a one-time supply cache and a Save Lamp reward exploration. The relay-locked far door loops back to Wisp Hollow. An awakened cache and variable-position wisp appear on return. Valve, caches and lamp follow normal save/rollback rules.
- Flooded Gallery branches from the Crossing's upper ledge. A lower control guarded by a crawler and an upper control reached by climbing open a two-way shortcut near the Warden. Both controls persist only after lamp saving. Its upper cache rewards exploring beyond the second control; its awakened tier adds another cache and a variable-position wisp.
- Blackwater Cistern branches from the Crossing's far ledge. Its near, high and far pressure dials must be turned in order; a wrong dial resets only the unfinished sequence. Starting the pump calms the lower surge, unlocks a one-time upper supply cache and opens a two-way loop to Flooded Gallery. The room has its own Save Lamp. The completed pump, cache and discovered lamp persist after saving; an unfinished dial sequence does not. An awakened cache and variable-position wisp reward return visits.
- Warden Approach extends the Gallery's two-control shortcut instead of teleporting directly to the arena. A chain of upper platforms crosses the collapsed gantry, while a lower pit with recovery ledges and spikes catches missed jumps without trapping the player. The far counterweight permanently lowers a direct bridge for return visits. A high cache rewards climbing, a Save Lamp sits safely before the arena, and the awakened tier adds another cache and roaming wisp. Both doors permit backtracking; only the Gallery and arena entrances to this route require the original two-control shortcut.
- The Grotto's two resonators award the Echo Charm and open the gallery.
- The Gallery Prism is a unique pickup. It unlocks the far gallery shortcut back to the Grotto and the Prism Archive.
- The Gallery Prism also reveals Crystal Causeway. Two staggered crystal bridges blink before becoming intangible; a lower recovery route prevents a failed jump from trapping the player. The far anchor opens a two-way loop to the upper Tide Well. A first-visit supply cache, awakened cache and variable-position wisp reward crossing and returning.
- The Prism Archive's Root → Star → Echo mirror sequence awards the first Memory Sigil and opens another loop back to the Grotto.
- The Tide Well is a vertical route with a timed current. Its unique Tide Core will be required for the Echo Matriarch, while a lift activated at the bottom makes later visits quicker.
- Undertow Vault has two independently attuned seals: one up a climbing route and one beyond a tide surge. Together they open the one-time Tideguard Reliquary and its Tideguard Mantle. The Mantle is exclusive with other defense gear and negates tide-surge damage, not enemy hits. Its Save Lamp joins the shared travel network. The awakened Vault has another cache and wisp encounter.
- The Tide Core opens the Echo Nest. Defeating its brood permanently removes the veil after a lamp save; the Nest Crest opens a shortcut to the top of the Well and is intended for the Matriarch's sanctuary.
- The Tide Core and Nest Crest open Resonance Sanctum. Defeating the Echo Matriarch awards her seal, upgrades Echo-zone enemies on later visits, opens a loop back to the Grotto, and unlocks the Ashen Bastion gate. Broken Causeway has warning-before-damage heat vents, an upper bypass and its own Save Lamp. Cinder Forge has Demon and Construct encounters, a high cooling fan that permanently disables the opening rooms' vents after saving, a one-time resource cache and another Save Lamp. Its far door leads to Ember Barracks: a two-wave trial, one-time Barracks Insignia and currency/XP, cache, lamp, and a two-way high-route loop back to Broken Causeway. The Barracks upper door then leads to Cinder Coliseum, a four-wave arena ending with the Ember Marshal and two Demon guards. The Marshal telegraphs a charge, fires bolts, and gains a wider volley at half health. Winning gives a one-time Marshal Emblem, 100 Gold and 7 XP and unlocks a high cache. The entrance lamp and return door stay available. Both challenges reset if abandoned; their enemies have no individual drops so unfinished waves cannot farm rewards. The cleared Coliseum opens Slag Reservoir. Its lower and upper coolant valves independently quiet heat vents; both open a two-way loop to the Forge and a cache with the unique Crucible Core. Each room has a Save Lamp. Clears, valves and items persist only after lamp saving. These five rooms are an opening slice, not the completed Ashen Bastion or its main boss route.

## Return-visit loop now playable

- Training Passage remains a safe starting route, but defeating the Warden upgrades it and reveals a one-time return cache. Eldric's third optional mission asks for the Awakened Warden after his first two missions.
- Sunken Shaft gains seven one-time awakened caches (including Wisp Hollow, Drowned Crossing, Flooded Gallery, Blackwater Cistern and Warden Approach), plus first-visit supply caches in the Crossing, Gallery, Cistern and Approach and variable-position wisps on its upgraded tier. On returning after the first Warden defeat, the Awakened Warden has 25 HP, faster charges and wider volleys. His one-time Heart reward adds 1 maximum HP; the Echo gate stays unlocked throughout.
- Echo Grotto, Whispering Gallery, Prism Archive, Tide Well, Echo Nest, Crystal Causeway and Undertow Vault each gain a one-time cache and one variable-position upgraded enemy. The Tide Well and Vault surges plus Causeway's phase bridges cycle faster at tier 1. The existing resonator, mirror, lift, brood and shortcut rules remain persistent.
- Resonance Sanctum contains the 34-HP Awakened Matriarch after the first victory. Her rematch adds a seven-projectile third phase. Winning gives one permanent maximum mana and reveals the Sanctum cache. The boss will not respawn after that rematch is cleared.
- Caches give fixed gold and one room-specific resource plus a small bonus matching the currently equipped weapon style. Each cache and rematch can pay out only once per saved character. Normal-mode death rolls them back to the last lamp snapshot; Hardcore death still deletes the run.
- Upgraded enemies change behavior without requiring a scene reload: Shaft Sentries telegraph a three-way volley, Shaft Crawlers can chain a second warned charge, Echo Shades can chain a second warned dash, Broodlings can leap up to higher platforms, and wisps dive faster. The map records visited rooms and shows Echo-room, cache and rematch progress beside the lamp list.

These rooms are deliberately compact while the core travel, combat and save loops are being tested. Art, animation, sound and larger room layouts remain a later expansion pass, not a claim of finished production content.

## Forge and build economy

- Orin's shop now has Buy and Forge tabs. Iron Fragments can be purchased as a fallback or found in caches, crates and occasional Shaft Crawler drops; Ether Dust remains available from wisps, caches and the shop.
- The Basic Sword, Spiritglass Blade, Hunter Bow, Thorn Bow, Runed Staff and Sunder Staff each have five permanent forge ranks. +1, +3 and +5 each add 1 damage to that weapon's attacks, including special arrows or both staff spells. +2 shortens attack cooldown by 12%; +4 brings the total reduction to 18%. +5 also gives the equipped weapon a pulsing radiance. Each rank consumes gold and weapon-appropriate materials; Orin's earned discount applies to the gold portion.
- +4 and +5 need Resonance Shards from the awakened Echo Grotto. The first Matriarch victory, her rematch and two upgraded-room caches provide them; Orin sells more after the first victory so upgrading several weapons never depends on a finite drop.
- Upgrade ranks are stored separately from inventory, so changing the equipped weapon does not erase a build. As with other progression, a lamp save is needed before a Normal-mode death, and Hardcore death deletes the run.
- The defense slot now has two mutually exclusive shop choices: Guardian Band reduces hits of at least 2 damage by 1 (never below 1), while Wind Cloak shortens Dash cooldown by 25%. Buying either equips it; the inventory can switch or unequip them. Owned defense gear and the active choice follow the same lamp-save rules as weapons.

## Enemy families and weapon identity

- Current enemies carry one family tag: Spirit (wisps, shades, Matriarch), Demon (passage fiends, Warden), Beast (crawlers, broodlings) or Construct (sentries, passage guardian). Boss is a separate additive tag. These assignments are gameplay scaffolding and can be refined alongside the final creature designs.
- After the Abyss Warden falls, Orin sells three specialized alternatives. Spiritglass Blade reaches farther but swings more slowly than the Basic Sword and deals +1 to Spirits. Thorn Bow fires faster but has less range than Hunter Bow and deals +1 to Beasts. Sunder Staff has heavier, slower, shorter-range spells than Runed Staff and deals +1 to Constructs. A matching boss receives the family bonus because Boss is an additional tag.
- Bow and staff projectile damage and travel distance now come from the equipped weapon's stats. Ember Arrows and Frost Orb retain their own ammo/spell behavior, and family bonuses apply on impact. Class skills, ammunition and spell controls work with either weapon of that class. All six weapons have independent forge ranks and follow the same lamp-save rules.

## Weapon skill branches

- Each weapon class has a second skill costing 1 Skill Point and requiring its first Mastery. Long Reach extends sword hitbox range by 16. Piercing Shot lets basic arrows hit two distinct enemies, while Ember Arrows remain single-target. Mana Flow gives 50% faster mana regeneration while any staff is the active weapon.
- These passives require no extra combat controls. The skill panel groups each second skill below its prerequisite, and inventory/HUD labels reflect the relevant bonuses. Unlocks are included in lamp saves and roll back on Normal-mode death if not saved.

## Further weapon identity and enchantments (planned, not implemented yet)

- Expand beyond the first alternative in each class with built-in effects beyond family damage, such as different resource use or attack behavior. Class skills remain useful across weapons, while individual weapon effects are independent of the skill tree.
- Expand the tagged roster so each zone visibly concentrates its own enemy family, making specialized equipment a meaningful choice. Boss remains an additional tag, never a replacement for the creature's family.
- Enchantments or socketed items can later add or modify an effect on one weapon and be changed between runs. Start with one slot per weapon and clear stacking rules so bonuses do not make bosses trivial. The user asked to postpone this system until the core game is further developed.
- The equipment screen must show base stats, built-in effect, enchantment and relevant enemy tags before purchase or equipping. Enchants should be obtainable through exploration, quests, drops or crafting rather than only by buying them. Their ownership and weapon assignment must follow the existing lamp-save and Hardcore rules.
- Implement and balance this after the basic weapon roster and enemy families are defined. Keep the five forge ranks, one-slot enchantments and class skill tree as separate progression layers; +5 radiance is a visible milestone, not an enchant slot or a substitute for a weapon's own identity. Do not silently turn every new weapon into a reskinned Basic Sword.

## Echo Survey side quest

- Lyra, a surveyor beside the Echo Grotto lamp, offers an optional three-room scavenger mission. Cyan traces are on the Gallery's first ledge, the Archive's first step and the Tide Well's fourth step. Traces may be found before accepting the mission.
- The Quest menu shows the three locations and collection progress. Returning to Lyra after all three gives 1 Skill Point, 3 XP, 80 Gold and 2 Ether Dust once. Collected traces, the quest phase and its reward are part of the lamp save snapshot.

## Awakened return quests

- The first Abyss Warden victory upgrades Sunken Shaft and triggers an on-screen **SUNKEN SHAFT AWAKENED** warning. Its one-time Shaft Vigil return quest asks for 3 upgraded enemy defeats and 1 Shaft cache, then automatically awards 2 XP, 70 Gold and 2 Iron Fragments.
- The first Echo Matriarch victory similarly upgrades the entire Echo Grotto and triggers **ECHO GROTTO AWAKENED**. Resonance Sweep asks for 4 upgraded enemy defeats and 2 distinct Echo caches, awarding 3 XP, 100 Gold and 2 Ether Dust.
- On later entry, the zone title warns that enemies are stronger. Active return quests and reward details are in the scrollable Quest menu; completed quests leave the active list. Enemy progress, opened caches and one-time payouts are preserved by lamp saves. A Normal-mode death restores the last saved snapshot.

## Development roadmap (ordered)

1. Playtest and improve the existing route first: expand the compact Sunken Shaft into distinct connected rooms, give Echo rooms more vertical paths, shortcuts and recognizable landmarks, and tune the first two bosses and six current weapons so one build does not dominate. Fix navigation, quest and save issues found during manual runs.
2. Build Ashen Bastion as the third full zone: seven or eight non-identical rooms, its own Demon/Construct encounters, traversal gimmick, lamp, optional branch, quest, prerequisite item, Ash Castellan boss, return shortcut and stronger revisit state. Connect the Matriarch gate only when the entry route works.
3. After the third zone is playable, build a mobile vertical slice: touch movement, jump, attack, Dash, interact and menu controls; safe-area-aware responsive HUD; readable inventory/shop/map; Android export and performance checks on a real phone. Keep desktop controls for development. Do not implement phone controls before this milestone, per the user's request.
4. Build Starfall Citadel and Hollow Throne with the same complete-room checklist, distinct families and boss conditions. Place the remaining Memory Sigils in optional branches of earlier zones and make the final gate verify all four prior bosses plus three sigils without blocking backtracking.
5. Extend build variety after the zone foundations: further weapon-specific abilities, roughly 10-15 worthwhile skills across general and class branches, quest rewards, materials and economy. Defer enchantment sockets until the gear roster and balance are stable, as requested.
6. Finish narrative, character and environment art, animation, enemy readability, ambient music and combat audio in coordinated passes; then balance Normal and Hardcore, test save migration, complete Android QA and prepare thesis screenshots and design documentation.
