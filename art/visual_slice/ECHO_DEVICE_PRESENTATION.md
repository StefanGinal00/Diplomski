# Echo device presentation

Implemented 2026-09-28. This pass changes presentation, not route geometry or
interaction/reward authority.

## Scope

`EchoDeviceArt.gd` gives 18 existing devices five native 2D silhouettes:
two crystal resonators, two flow handwheels, two chain anchors, two drain
grates and ten acoustic receivers. Active devices use both a color change
and a check mark. Recording receivers show a gold arc. The four compact
station styles fit under low shelves while retaining their original foot
anchor; only artwork is transformed, never the interaction area.

Art has no idle processing, colliders or gameplay children. Repeated status
updates do not redraw unchanged state. Only explicitly dressed controllers
stop their obsolete glow animation; receiver timing, threat interruption,
sequence resets and room-exit cancellation continue unchanged.

Ten local field-operation signs now show a short instruction or completion
state, progress and the save reminder. Five entry signs retain full cache
directions and return-trial instructions. Other discovery signs are unchanged.

## Verification

Seven unique targeted smoke tests passed: echo_device_art,
echo_field_operations, echo_field_discoveries, tide_well, crystal_causeway,
world_routes and starfall_task_art. Exact reports are recorded in
`tests/LATEST_SMOKE_RESULTS.md`.

The new art test visits streamed rooms before auditing all 18 devices. It
checks static/idempotent installation, unchanged physics/flags, original
foot anchoring, compact vertical extent, hidden legacy leaves, resonator
pair rewards, duplicate activation rejection, partial station completion,
receiver recording/reset states and 10 compact/5 full signs.

Seven D3D12 captures completed and were visually inspected: the labelled
gallery plus resonator, valve inactive/active, anchor, drain and receiver
contexts. See `art/characters/preview_echo_devices.png` and the adjacent
`preview_echo_device_*.png` files. Log: `.tmp-echo-devices-final.log`, exit 0;
known Windows certificate-store warning only, no script/shader errors.

## Limits and remaining work

This is not a full-suite run, manual traversal or editor acceptance. Dynamic
field devices are created on room entry; runtime captures do not guarantee
the editor overview shows them. Large primitive Echo scenery, older labels,
some creature placeholders and devices outside this explicit Echo scope
remain to be refined. Resonator placement itself was not changed. No new
raster assets were generated and this does not mark map art complete.
