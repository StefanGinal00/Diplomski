# Localized encounter population lifecycle

Implemented 2026-09-29. Ordinary optional ambushes now participate in the existing
room population unload/activation path. This is a runtime optimization and state
continuity pass, not a new enemy roster, map expansion or visual redesign.

## Scope

`LocalizedEncounter.gd` retains the lightweight trigger, requirement flags,
remaining foe indices and small value-only snapshots. `WorldPopulation.gd` calls
its suspend hook when the room's existing 10-second grace expires. A quick return
cancels that pending unload. `RoomActivityDirector` already invokes activation
hooks when entering a room, and now restores suspended encounter survivors too.

Only living enemies are restored, with current HP, position and patrol anchors /
direction. They instantiate their normal scene and painted appearance; tier and
encounter-health bonuses are applied once. In-progress attack state is deliberately
not restored: surviving enemies restart their normal preparation/cooldown state.
Owned projectiles are retired, so an unloaded attack cannot reappear on return.
Old enemy nodes are disabled immediately, freed, and disconnected from the
encounter completion callback. No death signal or reward is emitted by unloading.

Quick reentry combat safety now also covers the 10-second window before unloading:
`RoomActivityDirector` calls `suspend_room_combat()` on supported ordinary mobs
when their active room is hidden. Crawlers/Broodlings recover, Wisps return to
hover, Shades cancel their dash/followup, Root Stalkers disable the strike area,
and both sentry families cancel the windup/fan warning. Attack momentum is cleared
and a short cooldown precedes fresh native preparation. HP, position, tier and
population identity are preserved. Repeated activation of the same visible room
does not interrupt a new attack. Bosses retain their own encounter lifecycle.

Explicit population unloads also retire hostile projectiles by room ancestry or
source ownership, including projectiles parented outside their source room.
They become spent immediately, before deferred deletion, and cannot damage a
player through a late contact callback. Unrelated rooms' projectiles are untouched.

An already-cleared foe is not recreated. Repeated activation/defeat callbacks do
not duplicate the wave or completion event. A deferred initial spawn is cancelled
if a door transition has already moved the player into another room; off-room and
dead-player triggers are ignored. Existing boss, mechanism and tier requirements,
reward amounts, first-clear/return placements and Nest objective exclusion remain.

## Persistence boundary

Living-enemy HP/position snapshots remain session-local. Enemy defeats now also
have a checkpoint ledger in `GameState.defeated_enemies`, serialized with quests,
rewards and world progress. This covers static placements, curated patrols and
generated hostiles in every biome, including unloaded rooms. Loading replaces
the ledger (never merges it), so kills after the checkpoint roll back normally.

Optional ambushes use the stable trigger path plus foe slot, not auto-renamed
sibling node names. A saved partial wave respawns only its surviving slots and
can still complete/unseal its reward. Saved completed trials remain cleared.
Restoring a defeated placement silently removes it: no death signal, loot, XP or
quest credit is replayed. Objective gates ignore queued/dead actors.

Bosses keep their existing victory/rematch persistence. Restartable Barracks and
Coliseum wave challenges explicitly opt out of per-enemy persistence: an aborted
challenge restarts, while a saved completed challenge stays complete. Neutral
fauna disk persistence remains outside this scope.

Destructible crates now use a separate `GameState.destroyed_props` checkpoint
ledger with the same stable placement paths. Breaking a crate before saving
persists its absence, even when its room has unloaded; breaking it after saving
rolls back on death. Restoring absence does not call destruction, create a break
effect or reroll loot. Existing cache receipts and crate RNG/drop rates are
unchanged. Uncollected loose loot and partial crate damage are not disk-persisted.
Old saves without this field load an empty prop ledger; only subsequent breaks
and saves are tracked. Backup loads replace it and new games clear it.

Gold, item and XP pickups now latch accepted collection before reward signals,
preventing same-frame/reentrant contacts from awarding twice. Dead/non-player
contacts and invalid rewards leave the pickup available. A delayed activation
callback cannot reenable a claimed pickup. Owned unique items remain single-use.

This is an additive save field, not an autosave or a world-layout migration.
Old saves load with an empty enemy ledger; historical ordinary kills cannot be
reconstructed because those saves never recorded them. New games clear it.
Placement paths and authored encounter slot order must remain stable across
future content updates, or receive an explicit save-key migration.

## Automated evidence

`tests/encounter_streaming_smoke.gd` exercises three authored ambushes (Shaft
Hollow, Broken Causeway, Starfall Outskirts) plus a gated Echo return-trial fixture.
It checks deferred/off-room guards, invalid/duplicate defeat protection, a wounded
survivor, grace cancellation and deterministic deadline expiry, actual node release,
restored HP/position, single start/completion, tier/health-bonus stability, projectile
cleanup and exclusion of optional Broodlings from the Nest objective.

Existing population and Ash/Starfall/Echo field-operation regressions cover
native first-clear/return rewards and saved completion. This is not a manual
combat playthrough or a measured whole-game RAM/FPS benchmark.

`tests/enemy_checkpoint_smoke.gd` adds native death/UI restart and scene reload:
kill enemies across four generators and authored/curated placements, unload
their rooms, save elsewhere, make an unsaved kill, die, revisit. It also checks
partial ambush/Nest completion, passage-gate counting, backup rollback, legacy
saves and new-game reset, using an isolated temporary save.

`tests/prop_checkpoint_smoke.gd` covers 82 static/authored/curated/generated crates
across the passage and four biomes, a collected real drop, native death/reload,
repeat streaming, unsaved rollback, backup/legacy/new-game behavior.
`tests/pickup_claim_smoke.gd` exercises native body-entry signals and reward-signal
reentry for all three pickup types, same-frame repeat calls, dead/non-player and
invalid-value rejection, late activation and already-owned unique items.

`tests/mob_room_reentry_smoke.gd` covers 28 preparation/release interruptions
across seven mob scenes and two tiers through native room-change listeners.
It checks the same living instance/HP/position on quick return, cancelled fan and
followup attacks, deferred root-hitbox shutdown, no same-room reset, scoped
explicit projectile unload and health retention through full population unload.
