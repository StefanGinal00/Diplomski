# Checkpoint write-failure safety

Implemented 2026-09-29. This pass hardens existing lamp saves and fast-travel
autosaves; it does not change the save schema or require a new game.

## Write contract

GameState stages checkpoint position/name, discovered-lamp entries and timestamp
in the candidate JSON. It publishes these fields and success/discovery signals
only after the file replacement succeeds. Player/quest capture buffers are
restored on failure; actual live inventory, defeated enemies, destroyed props and
quest progress are not rolled back merely because disk writing failed.

The temporary file is flushed and checked for write errors/readable JSON before
the previous primary can be replaced. A valid existing primary must first be
copied to backup successfully. Backup copying uses its own staging file, retaining
the old backup until replacement. Both replacements rename over the destination;
neither deletes the working destination first. Rejected writes/copies/renames
return false with diagnostic warnings and no save-completed signal.

If the first primary save succeeds but creating its initial backup fails, the
save is successful (with a warning): the readable primary genuinely exists.
Reentrant saves from rest/discovery/completion listeners are rejected while the
current save operation is in progress. Subsequent normal retries are allowed.
Deletion of a save also cleans that save's staging files.

This verifies normal Windows replacement and handled I/O failure paths, not
power-loss durability, failing-disk hardware or cross-platform release support.

## Player-visible behavior

Lamps update the player's respawn position, light and activation notification only
after success. Failed timed rests still finish and release the player's rest lock.
Their existing error message is retained.

Fast travel and saving are distinct outcomes. If travel completes but its save
fails, the player remains at the destination and receives an explicit SAVE FAILED
message. The previous checkpoint/respawn stays in effect. Dying and reloading uses
that previous disk save, not the unsaved destination.

Rest-related quest progress and cosmetic cleanup still happen on an attempted
rest. A failed save leaves that progress unsaved in the live session, like other
unsaved actions; it does not falsely discover a lamp or advertise a new save.

## Automated evidence

tests/save_failure_smoke.gd uses isolated temporary saves. It tests a real
temporary-path open failure, injected copy/backup-replacement/primary-replacement
failures through narrow filesystem wrappers, rejected first save, successful
retry, reentrant rest callback, and valid first primary without initial backup.

Native Game.tscn coverage checks lamp state, capture buffers, unchanged primary
and backup bytes, timed-rest cleanup, actual fast-travel UI messaging and native
death/reload at the prior checkpoint. Existing lamp travel, campaign/story,
enemy/prop checkpoint and quest tests provide regression coverage. Final reports
are recorded in tests/LATEST_SMOKE_RESULTS.md.
